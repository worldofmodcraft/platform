# Task 008c: Pipeline write-back — `apply_write_back`, the `source_archive` URL, and the write-back view of the result

- **Mission:** SITE-V1, deliverable **D2** (the part of 008a that depends on contracts not yet written; umbrella `docs/tasks/008-build-pipeline.md`) — **Status:** draft — updated 2026-10-26 (session 12) for task 092's URL contract; independent spec review next. (Split out of 008a on spec review, 2026-10-14, task 054.) 057, 058 and 008a are merged; **not dispatchable until task 092 (registry PR #25, the `artifact-naming.md` amendment) has merged.** Touches the shape of the registry's append-only record; independent review required.
- **Agent / model:** implementer / sonnet
- **Budget:** small (≤ 2 agent-sessions)
- **Branch / worktree:** `task/008c-pipeline-write-back` / `~/wt/registry-task-008c` — **registry** repo

## Why this is its own task
008a was written to build and sign a tarball from nothing but a git repository, a commit and a key. Three of its parts were not independent of that: they need the `pending → published` shape that task 057 defines (decision Q-B, Ludwig 2026-10-14) and the project-owned `source_archive` URL whose shape task 058 must discover (decision Q-G). Keeping them in 008a made the core wait for contract work it does not use. They are separated here; 008a (core) can proceed without 057 or 058.

## Objective
Given 008a's `result.json` and an `entry.json` containing a `pending` version, pure functions produce (a) the five write-back values `source_archive`, `source_sha256`, `signature`, `key_id`, `published_at`, (b) the project-owned `source_archive` URL, and (c) the new `entry.json` in which that version has gone `pending → published` — changing **exactly** what task 057's contract permits and nothing else — and each function is demonstrated against 057's fixture corpus.

## Context to load (exhaustive)
- Task 057 (`docs/tasks/057-version-lifecycle-contract.md`) **as merged**: `contracts/entry.schema.json` and `contracts/append-only.rules.md` (T1: `pending → published`, the exact key sets), and `docs/tasks/057-transition-fixtures.json` — the shared corpus.
- `contracts/artifact-naming.md` section "The archived-source URL (`source_archive`)" **as merged by task 092**: the formula, the host constant, the two worked examples, path safety and injectivity, and the consumer rules (which bind 008b, not this task). Background only: task 058's report `docs/research/archive-url-probe.md` (platform repo).
- 008a as merged: `result.json` (`artifact.{source_sha256, signature, key_id}`, `built_at`, `tag`, `assets`), `release_asset_url`.
- `contracts/artifact-naming.md` (tag and asset names), `contracts/signature-format.md` ("What `entry.json`'s `signature` field holds").
- ADRs: 0041, 0058 §1-§2 (and whichever ADR resolves 057's blocker B1), 0103. Doctrine: MANAGER.md §2c, §3.6b, §3.6c, §3.7; CLAUDE.md rules 5, 11.
- Graph: nodes **N5**, **N2**; edge **E8** (the write-back fields). No new edge.

## Design (decisions made in this spec)
1. `write_back_values(result, source_archive)` → `{source_archive, source_sha256, signature, key_id, published_at}`; `published_at` is `result.built_at` (RFC 3339 UTC; the pipeline's own clock, recorded once).
2. `source_archive_url(namespace, name, version)` → the project-owned URL (decision Q-G; shape fixed by task 092):
   `"https://archive.worldofmodcraft.com/" + tag + "/" + tag + ".tar.gz"`, where `tag` is 008a's naming-scheme tag (`ns.nm-v`,
   computed by 008a's `naming` module, imported, never re-implemented). The host is one named constant whose value is taken from
   the contract; no percent-encoding (`+` is written literally; `%2B` is a different string); invalid triples are refused by the
   same 008a naming checks (including the reserved-device-name rule). A version with build metadata (`+`) still yields its URL
   here — holding such versions back from publication is 008b's (092 decision Q10), not this function's. The redirect target
   and every consumer rule (hops, cap, hash-and-signature-before-use) are out of scope here.
3. `apply_write_back(entry, version, values)` is pure: it returns a new entry and never mutates its input; it refuses (raises a named error) when the target version is absent, is `published` or `removed`, when `values` has a missing or extra key, when a value fails its `entry.schema.json` pattern, or when `values` belong to a different mod or version (the `result.json` carries `id` and `version`; they are compared, not assumed).
4. Authority is not decided here: this task changes no workflow and no ownership rule. Who may *commit* the output is 008b plus the ownership carve-out.

## Acceptance criteria
All command-based; demonstrated by `docs/tasks/008c-verify.sh`.
1. **Exactly the permitted transition.** For a fixture entry with one `pending` version, `apply_write_back` returns an entry that (a) validates against `entry.schema.json` as merged by 057, (b) differs from the input in precisely the five added keys and the `status` change — shown by a field-level diff the test computes independently (a generic recursive diff, not the function's own logic), and (c) is classified **accept** by 057's reference oracle when run as `(old=input, new=output)`.
2. **Refusals.** Each named refusal of design 3 is a separate fixture and each raises the specific error: absent version, `published`, `removed`, missing key, extra key, bad `source_sha256` length, `http://` `source_archive`, `published_at` not RFC 3339, values from another mod, values from another version. The input object is byte-identical after every call (no mutation).
3. **Shared corpus.** Every `accept` row of 057's `057-transition-fixtures.json` that is a T1 is reproduced by `apply_write_back` from its `old` plus the values; and for every T1 `reject` row that is constructible through the API (for example extra changed field) the function either cannot produce it or refuses — the test asserts which. A fixture file that has changed since this task started is re-read, not cached.
4. **Mutation.** Make `apply_write_back` also copy `commit` from the values, drop the status change, mutate its input, accept a `published` target, skip the mod/version comparison: each reddens a named check. Restored byte-identically.
5. **`source_archive_url`**: output equals, byte for byte, the contract's two worked examples, typed literally in the test
   (`https://archive.worldofmodcraft.com/mc.hello-world-1.0.0/mc.hello-world-1.0.0.tar.gz` for `mc`, `hello-world`, `1.0.0`;
   `https://archive.worldofmodcraft.com/a.b-1.0.0-rc.1+build.5/a.b-1.0.0-rc.1+build.5.tar.gz` for `a`, `b`, `1.0.0-rc.1+build.5`);
   every generated URL matches `^https://archive\.worldofmodcraft\.com/[0-9A-Za-z._+-]+/[0-9A-Za-z._+-]+\.tar\.gz$` and contains
   no `%`, `..`, `//` after the scheme, `?` or `#`; two different `(namespace, name, version)` triples never produce the same URL
   (property test over a generated set, including the Windows-reserved-name rejections inherited from 008a); the hostname comes
   from one named constant, and a test asserts no other module under `tools/` hard-codes it. The test cites the contract section
   with task 092's merge commit.
6. **No secret, no network:** the module imports neither `subprocess` nor a network library (grep, with a positive control file); the canary test of 008a criterion 11 is extended to `write_back_values`'s output.
7. `docs/tasks/008c-verify.sh` exists, is executable, mutation-tested (criteria 1, 2, 4), run in a fresh clone; output pasted in the log. `docs/pipeline/build-pipeline.md` gains the write-back section (what is computed, what is refused); the file also records, as `[unverified]`, that nothing here checks a hash against a tarball (that is the E9 verifiers').

## Explicitly OUT of scope
- Opening, committing or merging the write-back PR; the workflow; the ownership carve-out (008b and sibling contract work).
- Changing any contract, `entry.json`, or 057's fixtures (a needed change is a stop-and-report to 057).
- The archive tool itself (008a).

## File scope (declared; anything else = stop and report)
In the **registry** repo: `tools/pipeline/write_back.py` (new), `tests/pipeline/test_write_back.py` and fixtures (new), `docs/pipeline/build-pipeline.md` (the write-back section only), `docs/tasks/008c-pipeline-write-back.md` (log), `docs/tasks/008c-verify.sh` (new, executable). 008a's files are read-only here, except importing them.

## Forbidden here (beyond MANAGER.md §3.7)
- Writing the `source_archive` hostname or path anywhere but the one constant, or deriving it from anything but the merged contract.
- Deriving the test's expected output from the function under test (the project's recurring signature failure).
- Weakening a 057 fixture, or skipping the shared corpus because it is inconvenient.
- Any real key, token or `gh` credential command (CLAUDE.md rule 11).

## Dependencies and sequencing
`032` → `045` → `057` merged; `058` merged (platform #79); `008a` merged; **`092` merged (registry #25)** → **008c** → 008b (the workflow calls these functions). 007's append-only checker, when merged, must also accept the output; criterion 1(c) uses the 057 oracle until then. File overlap with 008a: none (`write_back.py` is new; 008a is read-only here).

## Verification artefact (MANAGER.md §2c)
Declared: `docs/tasks/008c-verify.sh`; every criterion is command-based.

## Deliverables
Module, tests, docs section, verify script, this file's log current.

## Questions  (agent-maintained; see MANAGER.md 8b)
- ~~Blocked on 058 for the URL shape (decision Q-G).~~ Resolved: 058 probed (option C, Ludwig 2026-10-26), 092 fixed the shape in the contract (session 12 update). Q-J is decided (ADR-0121, 2026-10-15): `rejected` is a fourth state reached by T3. `apply_write_back` must refuse a non-`pending` version, including a `rejected` one; building the T3 diff (`reason`, `build_log_url`) is 008b's, using 057's oracle shape, not this task's.

---
# Task 008c log  (append-only, updated continuously by the executing agent)
- 2026-10-14 split out of 008a on spec review; nothing started.

## Decision recorded 2026-10-15 (Ludwig, in session: "Kör på A")
**Build logs live in `worldofmodcraft/archive` at `logs/<namespace>.<name>/<version>.log`**, committed by the
pipeline. `build_log_url` is that file's permanent https URL in a repo the project owns (ADR-0041: nothing
unpublished). The Actions run log is not used as the permanent reference (retention believed ~90 days,
[unverified]). Depends on M7 (archive repo exists).
- 2026-10-26 manager (session 12): spec updated for task 092 (URL formula, host constant from the contract, AC5 pinned to the
  contract's two worked examples, dependencies 057/058/008a merged, 092 must merge first, Q10 noted as 008b's). Out of scope and
  booked elsewhere: CI equality of `source_archive` against the derived URL (092 decision Q2). Next: independent spec review.
