# Operations — the things that are expensive to rediscover

- **Purpose:** facts a session learns by getting them wrong. Context is lost at compaction or
  handover; this file is not. If you catch yourself deducing one of these from scratch, it belongs here.
- **Last reviewed:** 2026-09-03
- **This is a living document.** Every session that learns a new gotcha appends it here before
  handing over. Adding to it is part of the handover procedure (MANAGER.md §5), not optional.

## Repositories and what lives where
| Repo | Holds | Local clone |
|---|---|---|
| `worldofmodcraft/platform` | ADRs, doctrine, dependency graph, task ledger, mission logs, `tools/adr/` | `~/wom` |
| `worldofmodcraft/registry` | contracts, `tools/validation/`, CI and pipeline (later), the mod data | `~/registry` |
| `worldofmodcraft/site` | Astro site (task 009) | `~/site` — seeded and protected (task 022) |

Task worktrees live at `~/wt/<name>`. Task files travel with the work (in the repo where the work
happens); the ledger entry and mission log stay in `platform`.

## Identities and keys
- `gh` is authenticated as **`womcraft`** (numeric id **324089373**) — the platform identity.
- Organisation `worldofmodcraft` = **324218296**. Ludwig's older personal account `mbmludric` =
  **37807560**, which has **no** write access to the org (this caused the first push failure).
- Git identity in the platform and registry clones: `womcraft <womcraft@snabbpost.com>`.
- Signing key id **`6E5B30596A7A8CC4`** (minisign, Ed25519). Public key and rotation procedure in
  `docs/architecture/key-management.md`. The private key is only an Actions secret plus Ludwig's
  offline backup — it must never appear in a repo, a log, or a chat.

## Branch protection changes the workflow
`main` on **all three** repos requires a pull request, blocks force-push and deletion, and includes
administrators. Zero required approvals, so the manager merges its own PR under §7 authority.
A direct push is refused with `GH006: Protected branch update failed`.

The loop, every time:
```bash
git checkout -b <branch> && ...edits... && git commit && git push -u origin <branch>
PR=$(gh pr create --repo worldofmodcraft/<repo> --base main --head <branch> --title ... --body ...)
gh pr merge "$PR" --repo worldofmodcraft/<repo> --merge --delete-branch
git checkout main && git fetch --prune origin && git reset --hard origin/main
```
**If protection ever genuinely blocks work, lift it temporarily and loudly — never grant a quiet
exemption** (Ludwig, 2026-09-03).

## Tool interfaces that are easy to get wrong
- **`tools/validation/scan_assets.py <DIRECTORY>`** — takes a **directory**, never a file. A file
  path returns **exit 2 meaning "not a directory"**, which is a *usage error*, not a rejection.
  Reading exit 2 as "rejected" once produced a completely false verification. Exit 0 = all accepted,
  1 = something rejected, 2 = usage error.
- **`tests/contracts/schema_check.py`** — `validate(instance, schema)`, in that order. It **raises**
  `SchemaValidationError`; it does not return a list. It raises `NotImplementedError` on any JSON
  Schema keyword it does not support, deliberately, so an unsupported rule can never be silently
  ignored.
- **`tools/adr/build_index.py`** — `--write` regenerates `docs/decisions/INDEX.json`, `--check` is
  the gate (non-zero on drift), `--lookup <topic>` returns matching ADRs. **Accepting an ADR or
  editing any header changes its INDEX entry**, so regenerate and commit the index in the same PR
  or `--check` fails on merge.
- **`~/.claude/token-guard-check.sh`** — prints the binding usage window; UNKNOWN if the snapshot is
  missing or older than 10 minutes, which the guard counts as above 90 %.

## Consequences of branch protection that bite later
- **The publishing pipeline cannot push its write-back to `main`.** Task 008 must run on a branch of
  the *same* repository — where repository secrets are available, unlike a fork PR — push
  `pipeline/<ns>.<name>-<version>`, open a PR, and let it merge when its own checks pass. Two PRs
  per publish. This is a direct consequence of task 013 and is easy to rediscover the hard way.
- **Accepting an ADR is a two-file change.** `INDEX.json` records each ADR's status, so flipping a
  status without regenerating the index makes `--check` fail on merge.

## Ludwig's manual steps: blocked versus merely pending
Not the same thing, and conflating them wastes his time.
- **Blocked (cannot be done yet, do not ask):** enabling GitHub Pages — `worldofmodcraft/site` now
  holds only a licence, a README and an ignore file (task 022), which is not a site. Returns to him
  the moment task 009 pushes a real build.
- **Pending (he can do any time):** `M3` — add the minisign private key as `MINISIGN_SECRET_KEY` on
  the registry repo. Needed by task 008, not before.
- **Pending, later:** `M4` — create `test/hello-world` and push what task 010 prepares.
- **Done and verified:** the org, both repos, Actions permissions, DNS (four A records + `www`
  CNAME, all unproxied), the signing keypair.

## Environment
- Node is at `/home/ludwig/.local/node/bin/node` (userland install; on PATH via `~/.bashrc`, but use
  the absolute path in scripts that may run in a non-login shell).
- Project tooling is **Python 3 standard library only** — no pytest, no jsonschema, no PIL. Tests
  run with `python3 -m unittest discover -s <dir>`.
- Usage figures come from the HUD's `display.externalUsageWritePath` →
  `~/.claude/usage-snapshot.json`. Claude Code passes usage on **stdin** to the statusline; there is
  no other local source.

## Mistakes this project has already made (do not re-run the experiment)
1. **A test that can only confirm what its author believes.** Three instances: a gate that skipped
   files before counting them; a fixture that derived its expected bytes from the code under test;
   and a verification that read usage errors as rejections. When a check passes, ask what it would
   look like if the thing being checked were broken.
2. **Assuming git state instead of checking it.** A command chain assumed it was on a branch when it
   was on `main`, committed there, and the next `reset --hard` discarded the work (recovered from
   the reflog). Check `git rev-parse --abbrev-ref HEAD` before a commit chain.
3. **Citing a path without saying which branch it is on.** Under §3.2 most work is invisible on
   `main`. Cite unmerged work as `branch:path` and give the command to view it.
4. **Spec wording that sounds sufficient.** "Identify by magic bytes" and "a well-formed instance of
   a whitelisted format" were each satisfied by a file carrying a byte-for-byte Blizzard payload.
   State the guarantee, then try to satisfy it maliciously before delegating.
