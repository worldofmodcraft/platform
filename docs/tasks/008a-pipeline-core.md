# Task 008a: Pipeline core — clone, validate, scan, archive, hash, sign (offline)

- **Mission:** SITE-V1, deliverable **D2** (first half; umbrella `docs/tasks/008-build-pipeline.md`) — **Status:** draft (spec written 2026-10-14 under task 054). **Not dispatchable until umbrella questions Q1 and Q2 are answered and the contract-amendment task has landed.** Touches signing: merge requires Ludwig (MANAGER.md §7).
- **Agent / model:** implementer / sonnet (the signing and verifier parts get an independent reviewer at the same tier or higher with full tools — OPERATIONS.md, "The reviewer agent cannot run this project's verify artefacts")
- **Budget:** large (≤ 6 agent-sessions)
- **Branch / worktree:** `task/008a-pipeline-core` / `~/wt/registry-task-008a` — **registry** repo (`worldofmodcraft/registry`)

## Objective
A command-line tool exists in the registry repo that, given a version to build, produces — from
nothing but a git repository, a 40-hex commit, and a key *file* — the exact artefacts the
contracts describe: a deterministic `.tar.gz` of that commit with a single rooted directory
(`archive-layout.md`), its SHA-256, a minisign detached signature whose trusted comment follows
`signature-format.md`, the release tag and two asset names from `artifact-naming.md`, and a result
object holding the six write-back values. Every rejection the mission requires (§7.1) is produced
by this tool for the pipeline half (non-OSI licence, wrong-extension Blizzard payload, GLB with a
disallowed embedded payload) and is demonstrated against hostile fixtures. Nothing here touches the
network, GitHub, or a real key.

## Context to load (exhaustive)
- ADRs: 0041 (integrity chain, archiving), 0058 §1-§3, 0059 §1, 0030 (manifest fields), 0103,
  0117, 0119 (reserved namespaces), 0120 (content whitelist), 0099 (CI gates), 0049 (licence, via
  `manifest.schema.json`). ADR selection: INDEX.json lookups on "pipeline", "signing", "archive",
  "manifest".
- Contracts (registry `origin/main`): `signature-format.md` (all of it, esp. "Deriving `key_id`"
  and the eleven verifier rejections), `artifact-naming.md` (all of it, incl. Windows reserved
  names and the `.` join), `archive-layout.md` (root convention, path-escape rule, malformed
  archives), `manifest.schema.json`, `entry.schema.json` (as amended by the contract task),
  `validation-report.schema.json`, `append-only.rules.md`.
- Code to reuse, not reimplement: `tools/validation/scan_assets.py` (takes a **directory**; exit 0
  accept, 1 reject, 2 usage error — a 2 is never a rejection), `tools/validation/magic.py`,
  `tests/contracts/schema_check.py` (`validate(instance, schema)` raises; `NotImplementedError` on
  unsupported keywords), `reserved-namespaces.json`.
- Docs: `docs/validation/asset-scanner.md`, `docs/architecture/key-management.md` (public key,
  `key_id` `6E5B30596A7A8CC4`, **no private key anywhere in this task**).
- Doctrine: MANAGER.md §2c, §3.6b, §3.6c, §3.7, §3.10; CLAUDE.md rules 5, 11.
- Graph: nodes **N5**, **N4** (the manifest half is new), **N6** (names only); edges E1, E5/E6, E7,
  E8 (the computed object), E9.

## Environmental facts this spec relies on (verified here, 2026-10-14; commands shown)
```
$ which minisign && minisign -v          →  /home/ludwig/.local/bin/minisign   minisign 0.12
$ D=$(mktemp -d); cd $D; minisign -G -W -p k.pub -s k.key      # throwaway key, exit 0
$ minisign -S -s k.key -m f.tar.gz -t "format=1;id=test:hello-world;version=1.0.0;sha256=<hex>" -x f.tar.gz.minisig   # exit 0, no prompt
$ minisign -V -p k.pub -m f.tar.gz -x f.tar.gz.minisig        # exit 0: "Signature and comment signature verified"
$ echo x >> f.tar.gz; minisign -V …                           # exit 1: "Signature verification failed"
```
- Line 2 of the produced `.minisig` base64-decodes to **74 bytes** starting `ED` (the prehashed
  variant is minisign 0.12's default for `-S`); line 4 decodes to **64 bytes**; the 8 key-id bytes
  of line 2, **reversed** and upper-cased, equal the 16 hex characters in `k.pub`'s comment line
  (`C20EF6F59D3AB182` in that run). This confirms `signature-format.md` against the real tool for
  `ED`; the `Ed` legacy variant (`-l`) was not exercised here.
- `minisign -S -s <(cat k.key) …` (key via process substitution, no key file argument on disk)
  exits 0 in that run: the secret can reach minisign without being written to a file by the caller.
  Whether the same works under the CI runner's shell is unverified (008b).
- `git archive --format=tar --prefix=src/ HEAD | gzip -n` run twice, two seconds apart, gave
  byte-identical output (sha256 `ec33042e…` both). So `gzip -n` plus a fixed `--prefix` is
  deterministic for a fixed commit. Plain `git archive` without `--prefix` has no root
  (`archive-layout.md` shows this too).
- Node 24 and Python 3 stdlib are present; Lua is **not** (`which lua lua5.4 luajit` prints nothing).
- **Not verified, so every dependent criterion carries it:** that minisign can be installed on a
  GitHub-hosted runner (the only known-good route is the pinned static binary Ludwig used in M3 —
  `docs/runbooks/site-v1-manual-steps.md` — with its checksum checked; apt availability untested);
  and that `git archive` honours `export-ignore`/`export-subst` from the archived tree's own
  `.gitattributes` (documented git behaviour; test it, criterion 4).

## Design (decisions made in this spec)
1. **Fetch:** `git clone --no-checkout <source_url> <dir>`, then `git cat-file -e <commit>^{commit}`,
   then `git archive` straight from the object database. **No working tree is ever checked out**:
   no smudge/clean filters, no LFS, no hooks (hooks are not cloned) run on attacker content.
   Submodules are not followed. Any host, no GitHub API (mission D2 step 1).
2. **Tarball:** `git archive --format=tar --prefix=<root>/ <commit> | gzip -n`, `<root>` a fixed
   literal chosen once: `src/` (archive-layout.md leaves the value open; ADR-0103 says one fixed
   boring literal). Deterministic, so a re-run yields the same SHA-256.
3. **Scan the tarball, not the clone.** The asset scan and manifest validation run on the contents
   *extracted from the produced tarball* into a fresh directory, because that is what users and the
   site receive. `.gitattributes` `export-ignore` could otherwise hide a file from the tarball but
   not from a scan of the clone, or the reverse.
4. **Extraction is hostile-input safe:** the tool inspects every tar entry before extracting
   (`archive-layout.md` path-escape rule: `..` segment, absolute path, symlink target escaping the
   root → reject the whole archive).
5. **Manifest:** read `<root>/mod.lua` with the Q2 reader; project the eleven schema fields;
   validate against `manifest.schema.json`; check `manifest.id == entry id` and
   `manifest.version == version` (both cross-checks are named in the schema's descriptions as
   "pipeline logic"). Licence validity is the schema's SPDX-OSI enum (task 006); `LicenseRef-*`
   and `NOASSERTION` are rejected by it, which the existing invalid examples already show.
6. **Key handling:** the signing step takes a **path** to a key file (`--key`), never key bytes on
   the command line or in an argument, and never logs it. In CI the path is a process substitution
   or a 0600 file under a temp directory removed on exit (008b chooses).
7. **Name safety:** the namespace is checked against the Windows reserved device names
   (case-insensitive, `CON PRN AUX NUL COM0-9 LPT0-9`) **before** any tag or filename is built
   (`artifact-naming.md`). The exact matching behaviour is stated there as unverified against a
   Windows machine; the rule is enforced regardless.

## CLI and result shape
`python3 tools/pipeline/build_version.py --entry <path to entry.json> --version <semver>
--workdir <empty dir> --key <path> --pubkey <path> --out <dir>`
Exit codes: **0** built; **1** rejected (the version is bad — message names the rule/contract
clause and the remedy); **2** usage/internal error (including scanner exit 2, missing tool, clone
failure) — distinct, documented, and never conflated (OPERATIONS.md).
Outputs in `--out`: `<tag>.tar.gz`, `<tag>.tar.gz.minisig` (names per `artifact-naming.md`),
`result.json` (below), `build.log` (the full log; the thing 008b posts as a PR comment).
`result.json`: `{ "id", "version", "tag", "assets": {"tarball", "signature"}, "write_back":
{"source_sha256", "signature", "key_id", "published_at"}, "scan": <validation-report object> }`.
`source_archive` is **not** computed here: the URL depends on where 008b uploads (Q4); 008b fills it
from the tag and asset name by a pure function this task provides (`release_url(owner, repo, tag, asset)`)
whose output is pinned by a test.

## Acceptance criteria
All command-based; all demonstrated by `docs/tasks/008a-verify.sh` unless marked.
1. **Standalone CLI with three distinct exits** as above, each shown: a clean build (0), a rejected
   fixture (1), and a usage error such as a missing `--key` (2). Reading 2 as 1 is the recorded
   failure mode.
2. **Exact-commit fetch.** Against a local fixture repo (created by the test, `file://`-style path):
   the tool builds from a given 40-hex commit even when the branch has moved on (`HEAD` ≠ commit),
   and the tarball contains the *older* tree. A commit absent from the repo → exit 1 naming it; a
   non-40-hex or uppercase `--version`/commit input → exit 1 before any clone.
3. **Determinism.** Two builds of the same commit, at different wall-clock times, yield
   byte-identical tarballs and equal SHA-256; the recorded `source_sha256` equals `sha256sum` of the
   file (cross-checked against the OS tool, not against the tool's own code).
4. **Archive layout.** Every entry has the single root `src/`; a fixture repo with a **symlink**
   whose target is absolute or `..`-escaping is rejected whole (exit 1, `archive-layout.md`
   cited); a `.gitattributes` fixture using `export-ignore` on `mod.lua` is rejected as "manifest
   missing in the produced archive" (proves scanning is of the tarball); a fixture using
   `export-subst` records what happened in the log and is accepted or rejected per the test's
   stated expectation — the test asserts the observed behaviour, whichever it is, so the doc states it.
5. **Manifest (Q2 assumed A).** The reader accepts a literal table with comments and nested tables
   and rejects, with a named message: a function call, string concatenation, `require`, a
   `dofile`, an unterminated string, and a file that does not `return` a table. `mod.lua` carrying
   kernel-only keys (`depends`, `permissions`, …) is accepted (they are ignored by projection);
   a missing required field, `id` ≠ entry id, and `version` ≠ version are each rejected separately.
6. **Licence (mission §7.1, "a non-OSI licence").** A manifest with `LicenseRef-Proprietary`, one
   with `NOASSERTION`, and one with an invented identifier are each rejected; `MIT` and
   `Apache-2.0` are accepted — the positive controls sit beside the hostile cases.
7. **Asset scan (mission §7.1, both Blizzard cases).** Over the *extracted tarball*: a file with
   DBC/MPQ/BLP/M2 magic bytes named `innocent.png` → exit 1 naming the format; a `.glb` whose
   embedded buffer carries a disallowed payload → exit 1. Built with
   `tests/validation/fixture_builder.py` where it supports the case. A clean mod (PNG, OGG, GLB,
   text) → accepted. The scanner's own exit 2 (e.g. pointed at a file) surfaces as this tool's
   exit 2.
8. **Reserved device names.** Namespace `com1` (and `AUX`, `Nul`) → exit 1 *before any output file
   exists* (asserted: the `--out` directory is empty afterwards); `comet` and `console` are accepted
   (positive controls: the rule is the whole name before the first `.`, not a prefix match).
9. **Signature, byte-exact against the contract and against the real tool.** With a throwaway key
   generated by the test (`minisign -G -W`): the produced `.minisig` has four lines; line 2 decodes
   to 74 bytes, line 4 to 64; the trusted comment equals exactly
   `format=1;id=<id>;version=<version>;sha256=<hex>`; `minisign -V` accepts it; and an
   **independent reference verifier written in this task** (stdlib only, implementing
   `signature-format.md` rejections 1-3, 5-11 and the `key_id` reversal; rejection 4's Ed25519
   check delegated to `minisign -V`) also accepts it. `key_id` in `result.json` equals the
   uppercase-hex, reversed form read from the public key's comment line — compared against the
   pubkey file, not recomputed from the same bytes by the same function.
10. **The verifier can fail (each its own check, §2c rule 3):** (a) one byte appended to the
    tarball; (b) trusted comment edited; (c) line 2's key-id bytes edited; (d) a **copied
    signature for a different `id`** (the contract's "signature reuse across identities" attack:
    valid signature, `evil:not-hello-world`); (e) trusted-comment `sha256` ≠ entry `source_sha256`;
    (f) a wrong pubkey. Each is rejected by the reference verifier with the rule number it violates.
    Ordering of fixes: the fixtures are written and shown failing *against a deliberately naive
    verifier* first (one that checks only "signature verifies the bytes"), and the naive verifier
    must accept (d) — proving the fixture catches what rule 11 exists for.
11. **No secret in any output.** The test puts a canary string in the environment variable the key
    would come from and as the content of the throwaway key's *comment*, and asserts the canary
    appears in none of: stdout, stderr, `build.log`, `result.json`, the tarball. Mutation: make the
    tool log its `--key` path's contents; the check must redden.
12. **Write-back values** `{source_sha256, signature, key_id, published_at}` are computed and
    returned; `signature` is the four-line file verbatim with newlines preserved
    (`signature-format.md`, "What `entry.json`'s `signature` field holds"); `published_at` is
    RFC 3339 and passes `entry.schema.json`'s pattern. Applying them to an entry (the
    `pending → published` transition, Q1 assumed A) is a pure function `apply_write_back(entry,
    version, values)` that is tested to change **exactly** the permitted fields and to refuse any
    other shape (a version already `published`, a `removed` one, an absent one, a different mod's
    values) — and its output must pass the append-only checker from task 007 and the schema.
13. **Positive controls.** A clean first build, a clean second version of the same mod, and a mod
    carrying only text files all build and verify, beside the hostile cases.
14. **Mutation, fresh clone.** `008a-verify.sh` was mutation-tested (break the determinism flag
    `-n`, the `--prefix`, the reversal in `key_id`, the trusted-comment grammar, the symlink check;
    each reddens a named check) and run in a fresh clone; output pasted in the log.
15. **Docs move with code.** `docs/pipeline/build-pipeline.md` (new) states the CLI, exits, design
    decisions 1-7, and what is *not* verified (the not-verified list above); `docs/contracts/README.md`
    updated if the contract task left it stale. `docs/validation/` gains the manifest reader's
    description. [Read by the reviewer; not script-verified beyond a grep for each section heading.]

## Explicitly OUT of scope
- GitHub Actions, releases, uploads, the write-back PR, secrets, the ownership carve-out, E15 — 008b.
- The `page.json` screenshot scan — task 040 (needs the archive this tool makes).
- Software Heritage (umbrella Q5). Binary/plugin signing (mission §2).

## File scope (declared; anything else = stop and report)
In the **registry** repo:
- `tools/pipeline/` (new) — the CLI, `release_url`, `apply_write_back`, the reference verifier
- `tools/validation/manifest.py` (new) — the Q2 reader and projection; `tools/validation/` otherwise untouched
- `tests/pipeline/` (new) — suite and fixtures (all keys are throwaway, generated at test time)
- `docs/pipeline/build-pipeline.md` (new), `docs/validation/manifest-reader.md` (new), `docs/contracts/README.md` (only if stale)
- `docs/tasks/008a-pipeline-core.md` (this file as log), `docs/tasks/008a-verify.sh` (new, executable)
Reading `contracts/` is expected; **editing** a contract is not in scope — a needed change is a
stop-and-report (§3.3) and belongs to the contract task.

## Forbidden here (beyond MANAGER.md §3.7)
- Any real key, any use of `MINISIGN_SECRET_KEY`, reading `~/wom-keys`, `~/.config/gh`, or any
  credential file (CLAUDE.md rule 11). Throwaway keys exist only in a temp directory the test
  creates and removes. A denied access is not retried; it is logged.
- `git clone` followed by a checkout of attacker content; running any code from the mod.
- Extension-based file typing anywhere (mission §5.2); skipping the GLB-internal scan.
- Hand-rolling Ed25519 verification or the hash prehash (delegate to `minisign -V`).
- Treating scanner exit 2 as a rejection, or any non-zero as "rejected" without reading which.
- Inventing semantics the contracts do not state (e.g. version monotonicity — `append-only.rules.md` rule 5).
- A verifier test that derives its expected bytes from the code under test (the project's
  signature failure, six times now).
- Editing `contracts/`, `reserved-namespaces.json`, or any other task's file.

## Dependencies and sequencing
- Needs: tasks 002 (scanner) and 006/025 (contracts) merged — they are. Needs the **contract
  amendment task** (umbrella) and answers to **Q1, Q2**.
- Not blocked by 007/039; but criterion 12's output must pass 007's append-only checker, so
  007 must be merged first or 12's last clause waits.
- Blocks 008b. File overlap with 007: none (`tools/registry/` vs `tools/pipeline/`).

## Verification artefact (MANAGER.md §2c)
Declared: `docs/tasks/008a-verify.sh`; every criterion except 15's prose is command-based and
covered; the log pastes its output. Fix rounds, if any, add the found break as a fixture first.

## Deliverables
Code + tests + docs + verify script + this file's log section current.

## Questions  (agent-maintained; see MANAGER.md 8b)
- Q: root directory literal `src/` vs `<name>-<version>/` | options: A) `src/` / B) per-version
  name | assumed: A (ADR-0103; archive-layout says any non-empty value is valid) | built on: criterion 4.
- Q: umbrella Q1 (version-object pending shape) | assumed A | built on: criterion 12.
- Q: umbrella Q2 (mod.lua reader) | assumed A | built on: criteria 5, 6, `tools/validation/manifest.py`.

---
# Task 008a log  (append-only, updated continuously by the executing agent)
- 2026-10-14 spec written under task 054; nothing started.
