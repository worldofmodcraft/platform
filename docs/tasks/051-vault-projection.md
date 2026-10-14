# Task 051: A core generator that projects the repository's notes into the Obsidian vault

- **Mission:** tooling (task 047, part C, step 2) — **Status:** draft (spec v2 after the independent spec review, 2026-10-14; second review pending; Ludwig's approval pending)
- **Agent / model:** implementer / per agent frontmatter (ROUTING.md)
- **Budget:** medium (≤ 3 agent-sessions). ADR and Journal notes were split out to task 053 to keep this inside budget.
- **Branch / worktree:** task/051-vault-projection / ~/wt/task-051
- **Unblocked by:** task 050 PASS (2026-10-14: WSL writes appear live on Windows and the phone; rename-over works; dotfiles do not sync), Q-C2 = A, Q-P = A (Ludwig, 2026-10-14).

## Objective
`tools/vault/wom_vault.py` exists. Run against the directory `WOM_VAULT`, it writes a fixed set of
English notes, all regenerable from git. It writes every planned note or none. A run with no relevant
repository change writes nothing. It cannot overwrite a hand-written note, never opens one, and never
writes a note containing a secret. All of this is proven by `docs/tasks/051-verify.sh`, which runs only
against temporary directories.

## Context to load (exhaustive)
- `docs/tasks/047-arcane-practices.md`, `docs/tasks/050-vault-sync-probe.md` (including its log)
- `docs/manager/MANAGER.md` §2c rules 1–5, §3.6–3.6c, §3.7, §3.10
- `docs/manager/OPERATIONS.md` (it is also the source for `Gotchas.md`)
- ADRs (INDEX.json lookup done 2026-10-14 on the keys documentation, tooling, English, boring, outcomes, contracts):
  0056 English, 0103 boring and restartable, 0115 measure outcomes, 0117 contracts, plus the
  "Documentation as a product" ADR (look its number up in `docs/tools/adr-index.md`)
- Reference only, never copied: `~/wom/docs/tasks/inbox/arcane-reference/hooks/vault-guard.ps1` (untracked; read in place)

## Contract (the repo → vault edge). Written into `docs/tools/vault-projection.md`
**Source:** git objects of a named ref, **never the working tree**. Notes are UTF-8 with LF line endings.
Frontmatter:
```
---
generated: true
source_ref: <main | task/NNN-…>
source_commit: <full sha>
source_path: <repo path(s)>
updated: <committer date of source_commit, ISO 8601>
---
```
- **Single-source notes:** `source_commit` = `git log -1 --format=%H <ref> -- <paths>` (the last commit
  that touched the source). A merge therefore leaves notes whose sources did not change untouched.
- **Aggregate notes** (`Status.md`, `Tasks.md`) are derived from main's files **plus the list of local
  `task/*` branches** (used for ownership and for the `[[Tasks/NNN]]` links of open branches). For them
  `source_commit` is the ref's HEAD, and they are rewritten only when their bytes change (write rule 3).
  Churn is limited to these two.
- **`Tasks/NNN.md`:** `source_path` = the task file's path. `source_commit` = the owning ref's HEAD
  (main, or the task branch).

### Mode `main`: `wom_vault.py write --ref main`
| Note | Derived from, exactly |
|---|---|
| `Status.md` | (a) The **last in file order** section of `docs/tasks/MISSION-worldofmodcraft-site-v1-log.md` whose heading matches `^## SESSION`, verbatim. (b) Every later top-level `## ` section whose heading contains `For Ludwig`, verbatim. (c) A table of open tasks with a `[[Tasks/NNN]]` link each. |
| `Tasks.md` | Every `docs/tasks/[0-9][0-9][0-9]-*.md` and `docs/tasks/done/[0-9][0-9][0-9]-*.md` on the ref: id, title (first `# ` line), status word, `[[Tasks/NNN]]` |
| `Gotchas.md` | `docs/manager/OPERATIONS.md`, verbatim |
| `Commands.md` | `docs/manager/COMMANDS.md`, verbatim (Q-C2 = A; created by this task) |
| `Mission Log.md` | `docs/tasks/MISSION-worldofmodcraft-site-v1-log.md`, verbatim |
| `Tasks/NNN.md` | Only for ids **owned by main**: id, title, status word, task file path |

**Status word** = the capture of `\*\*Status:\*\*\s*\**([a-z-]+)`. A task is **open** unless its status
word is `done` or `stopped`, or its file lives in `done/`. A file without a match is listed as `status
unparsed` and counted in the run summary. That is not an error.

### Mode `task`: `wom_vault.py write --ref HEAD`, inside a worktree on branch `task/NNN-*`
Writes only `Tasks/NNN.md`: branch name, status word, the last line starting with `- ` after the
task file's log heading, and `git log --oneline main..HEAD`. The log heading is the first line matching
`^#{1,2} (Task [0-9]{3} log|Log)\s*$`; both forms occur in the ledger, checked 2026-10-14. With no
heading or no bullet, the note says `no log entry` and the run summary counts it. On any other branch, or when asked to write any other note:
non-zero exit, nothing written.

### One writer per file
- **Key = the three-digit id `NNN` only.** File and branch slugs differ (`052-vault-triggers-and-guard.md` versus `task/052-vault-triggers`).
- `Tasks/NNN.md` is owned by a local branch matching `task/NNN-*` while that branch exists and is not an
  ancestor of `main` (`git merge-base --is-ancestor`). Otherwise it is owned by main. A branch deleted
  without merging means main owns the note. WoM merges are merge commits. A squash-merged branch would
  stay branch-owned until deleted, and the docs say so.
- Every run holds an exclusive `flock` on `$(git rev-parse --git-common-dir)/wom-vault.lock`, waiting at
  most 30 s. On timeout it exits non-zero with `lock timeout`, and nothing is written.

### Write rules
1. Two phases: render and validate everything, then write. Any validation failure → **nothing written**, non-zero exit.
2. Validation fails when: `WOM_VAULT` cannot be resolved, is relative, is missing, is not a directory, or is
   itself a symlink; a target's `realpath` falls outside `realpath(WOM_VAULT)`; a planned target exists
   without `generated: true` in its frontmatter; a target name is on the forbidden list (rule 6); a
   secret pattern matches (rule 4).
3. Atomic writes, **as proven by task 050**: a dot-prefixed temp file in the target's own directory, fsync,
   `os.replace`. A target with identical bytes is not rewritten.
4. **Secret scan** over every rendered note, using length- and charset-bounded regexes, so prose that
   names a prefix does not match:
   `gh[pousr]_[A-Za-z0-9]{36}`, `github_pat_[A-Za-z0-9_]{82}`, `-----BEGIN [A-Z ]*PRIVATE KEY-----`,
   `untrusted comment: minisign encrypted secret key`, `sk-ant-[A-Za-z0-9_-]{32,}`, `(AKIA|ASIA)[A-Z0-9]{16}`.
   A hit reports note, line number and **pattern name**. It never reports the matched text.
   (Manager check, 2026-10-14, main `3e2b6ef`: the only prefix present in the note sources is one bare
   `github_pat_` in prose. The bounded form does not match it.)
5. The script never deletes anything. Subdirectories (`Tasks/`) are created only in the write phase,
   only inside the validated vault, and never the vault itself.
6. **Vault reads are limited** to planned targets (frontmatter and bytes). Nothing else is ever opened.
   The hand-written names `Agent Session Handover Prompt.md`, `MINISIGN.md` and `Olika Sessioner.md` are
   hard-coded as forbidden target names, so validation fails before any read.
7. `WOM_VAULT` is resolved from the environment first, then from `~/.config/wom/vault-path` (one line,
   exists on Ludwig's machine since 2026-10-14). Neither the path nor the file is committed (Q-P = A).
8. **Test mode.** With `WOM_VAULT_TEST=1`, the script **ignores `~/.config/wom/vault-path` entirely**,
   requires `WOM_VAULT` in the environment, and refuses any vault whose `realpath` is not under
   `realpath(${TMPDIR:-/tmp})`. Without test mode, the script refuses any vault under `/tmp`.
9. Python 3 stdlib only, run as `python3 -I` (Python 3.14.4 and tzdata are present on this machine).

### Subcommand `check` (stat only)
`check --save-baseline F` / `check --baseline F` record (name, size, mtime_ns) via `stat` for every file
under `WOM_VAULT` whose name is **not** a planned generated name. Later the command reports any changed,
added or removed entry and exits non-zero on a difference. It never opens a file in the vault.

## File scope (declared)
`tools/vault/wom_vault.py`, `tools/vault/tests/**`, `docs/tools/vault-projection.md`,
`docs/manager/COMMANDS.md` (new; first content: the commands Ludwig uses most, including the projection
commands themselves), `docs/manager/OPERATIONS.md` (one entry), `docs/tasks/051-verify.sh`, this file's log.

## Acceptance criteria
Script-verified by `051-verify.sh` (output pasted in the log) unless marked **human**.
1. In a temp git repo fixture, with a vault path containing a space and a non-ASCII character, mode `main`
   produces exactly the note set above with correct frontmatter. Each single-source note's
   `source_commit` equals `git log -1 --format=%H main -- <source_path>`.
2. A second run writes zero files. A new commit touching only `OPERATIONS.md` rewrites only `Gotchas.md`,
   plus `Status.md`/`Tasks.md` only if their bytes change (checked via mtime_ns).
3. A fixture `Status.md` without `generated: true` gives a non-zero exit with zero files written. Fixture
   files with the three forbidden names are rejected as targets **before any open**. Demonstrated with
   `strace -f -e trace=openat` if available. Otherwise the implementer states the method used and why it
   proves no open.
4. One fixture per secret pattern gives a non-zero exit, zero files written, and output naming the pattern.
   **Fixtures build secret strings at runtime; none are committed.** The test asserts the string appears
   nowhere in stdout, stderr, tracebacks or the temp tree. Positive control: the repository at pinned
   commit `3e2b6ef` renders with no hit.
5. Each invalid-vault case in rule 2, plus both test-mode refusals in rule 8, exits non-zero, writes nothing
   and creates no directory.
6. Mode `task` with main plus an open `task/NNN-x` branch writes only `Tasks/NNN.md`. A main run skips it.
   After the merge, a main run writes it with main's status word. A deleted unmerged branch hands ownership
   to main. Mode `task` refuses any other note.
7. Two concurrent runs serialize, and no temp files remain. The result equals a single run. A lock held
   past 30 s gives `lock timeout` and nothing written.
8. A stale generated note outside the planned set stays byte- and mtime-identical.
9. `check` detects a changed, added or removed non-generated fixture file, and passes when nothing changed.
10. **`051-verify.sh --mutate`** re-runnably mutates a temp copy of the script and shows the matching check
    turn red for: the `generated: true` check, the secret scan, two-phase writing, path containment, the
    symlink check, the forbidden-names rule, the ownership rule, the lock, skip-identical, and the test-mode refusal.
11. `051-verify.sh` passes in a fresh clone of the task branch (§2c rule 4).
12. `051-verify.sh` refuses to run unless the resolved test vault is under the temp dir, and neither under
    `/mnt/` nor under the real `$HOME`.
13. `docs/tools/vault-projection.md` documents the contract, setup and commands. Its Obsidian/LiveSync
    claims cite task 050's log.
14. **Human, after merge, Ludwig present:** the first live run (`check --save-baseline`, `write --ref main`,
    `check`). The notes appear on Windows and the phone, and `check` stays green.

## Forbidden here
- Anything against the real vault before AC14. Committing secret-shaped strings. Printing a matched secret.
- Opening any non-planned file in any vault, real or fixture (rule 6).
- Committing inside the task worktree as part of a test; tests build their own temp repos.
- The vault path in any committed file or in the task log.
- Network access, non-stdlib dependencies, catch-and-ignore around writes (§3.7).
- Touching `.claude/`, `.git/hooks`, MANAGER.md or CLAUDE.md.

## Dependency graph
Creates the tooling node `vault-projection`, outside SITE-V1's graph. It has one edge, repo → vault, whose
contract is `docs/tools/vault-projection.md`. There are no edges to SITE-V1 nodes. Sequencing:
051 → 053 (same script) → 052 (installs the script).

## Questions (agent-maintained; MANAGER.md §8b)

---
# Task 051 log
- 2026-10-14 manager: spec v1 written and gate run.
- 2026-10-14 independent spec review (reviewer agent): NOT PASS, 11 findings. Spec v2 addresses all of
  them that concern 051. Before acting, the manager re-checked two (§3.6c). Finding 2 is confirmed: in a
  temp repo, `fetch main:main` fires no `post-merge`, while `pull` does. Finding 4's premise was
  overstated: no `ghp_`, `sk-ant-` or PEM header exists on main, only one bare `github_pat_` in prose.
  Its fix (bounded regexes, pinned control) is adopted anyway. ADR and Journal notes were split into 053.
- 2026-10-14 second independent spec review: NOT PASS, 2 blocking (both in 052) and 5 smaller. Fixed in
  spec v3: 052 refresh-main.sh (handles main checked out or not), the pinned copy taken from the `main`
  ref with a stale warning, and the guard no longer blocks repo edits when the vault is unmounted.
  051 got the log-heading regex (both ledger forms), frontmatter for `Tasks/NNN.md`, the mkdir rule, and
  test mode ignoring the config file. 053 records the all-ADR scan (0 of 120 start with `---`) and the
  accepted first-run burst (~130 notes). Previous findings 2–6 and 8–11 were closed by the reviewer.
  The manager judges spec v3 ready for Ludwig without a third round: every remaining finding was
  concrete and has a concrete fix in the text.
