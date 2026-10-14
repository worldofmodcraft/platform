# Task 051: A generator that projects the repository's notes into the Obsidian vault

- **Mission:** tooling (task 047, part C, step 2) — **Status:** draft (manager's spec gate run 2026-10-14; independent spec review pending; Ludwig's approval pending)
- **Agent / model:** implementer / per agent frontmatter (ROUTING.md)
- **Budget:** medium (≤ 3 agent-sessions)
- **Branch / worktree:** task/051-vault-projection / ~/wt/task-051
- **Blocked by:** task 050 passing AC1–AC3; Ludwig's answers Q-C2 (source of `Commands.md`) and Q-P (what may be committed).

## Objective
`tools/vault/wom_vault.py` exists. Run against a directory named by `WOM_VAULT`, it writes a fixed
set of English notes, all regenerable from git, and it never touches anything else. The script either
writes every planned note or none. A second run with no repository change writes nothing. A
hand-written note cannot be overwritten. A note containing a secret pattern is never written. Its
behaviour is proven by `docs/tasks/051-verify.sh`, which runs only against temporary directories and
never against the real vault.

## Context to load (exhaustive)
- `docs/tasks/047-arcane-practices.md`, `docs/tasks/050-vault-sync-probe.md` (including its log results)
- `docs/manager/MANAGER.md` §2c (verification artefact rules 1–5), §3.6, §3.7, §3.10
- `docs/manager/OPERATIONS.md` (it is also the source for `Gotchas.md`)
- ADRs: 0056 (English), 0103 (boring and restartable), 0115 (measure outcomes), 0117 (contracts)
- Reference only, never copied verbatim: `~/wom/docs/tasks/inbox/arcane-reference/hooks/vault-guard.ps1`
  and `hooks/common.ps1` (untracked; read in place)

## Contract (the repo → vault edge)
Source = git objects of a named commit, **never the working tree**. Notes are UTF-8 with LF line
endings. Each note starts with this frontmatter:
```
---
generated: true
source_ref: <main | task/NNN-slug>
source_commit: <full sha>
source_path: <repo path, or a list of paths>
updated: <committer date of source_commit, ISO 8601>
---
```
`updated` comes from git, never from the wall clock, so output is deterministic.

### Mode `main` (`wom_vault.py write --ref main`), source = local ref `main`
| Note | Derived from |
|---|---|
| `Status.md` (open first) | Mission log: the latest top-level `## ` section whose heading starts with `SESSION`, every heading inside it containing `For Ludwig`, and the open tasks (task files on main whose Status is not done/stopped) with a link to `Tasks/<NNN>-<slug>` for each open `task/*` branch |
| `Tasks.md` | Every `docs/tasks/[0-9]*.md` and `docs/tasks/done/[0-9]*.md` on main: id, title, Status line, link |
| `Decisions.md` + `ADR/<file>.md` | `docs/decisions/INDEX.json` + each `docs/decisions/NNNN-*.md`, body verbatim |
| `Commands.md` | **Pending Q-C2.** Assumed for planning: a new hand-maintained `docs/manager/COMMANDS.md`, projected verbatim |
| `Gotchas.md` | `docs/manager/OPERATIONS.md`, verbatim |
| `Mission Log.md` | `docs/tasks/MISSION-worldofmodcraft-site-v1-log.md`, verbatim |
| `Journal/YYYY-MM-DD.md` | Every commit reachable from main, grouped by committer date in Europe/Stockholm. One line per commit: short sha, subject |
| `Tasks/<NNN>-<slug>.md` | Only for tasks that are **not** owned by an open branch (ownership rule below) |

### Mode `task` (`wom_vault.py write --ref HEAD`, run inside a task worktree on `task/NNN-slug`)
Writes only `Tasks/<NNN>-<slug>.md`: branch, the Status line of that branch's task file, its last
log entry, and `git log --oneline main..HEAD`. Refuses (non-zero exit, nothing written) to write any
other note, or to run on a branch that does not match `task/NNN-*`.

### One writer per file
- A `Tasks/` note is owned by branch `task/NNN-*` while that local branch exists and is not merged into
  main; otherwise it is owned by `main`. Both modes compute this from refs and skip what they do not own.
- Every run holds an exclusive `flock` on a lock file in `$(git rev-parse --git-common-dir)` for its
  whole duration. The lock is shared by all worktrees and never lives in the vault.

### Write rules
1. Two phases. First render and validate every planned note. Then write. Any validation failure means
   **nothing is written** and the exit code is non-zero.
2. Validation fails when: `WOM_VAULT` is unset, empty, relative, nonexistent, a symlink, or resolves to
   something else; a target path resolves outside `WOM_VAULT`; a target exists without `generated: true`
   in its frontmatter (a hand-written note); a secret pattern matches (rule 4).
3. Writes are atomic: a dot-prefixed temp file in the target's directory (or outside the vault if 050's
   AC3 failed), then fsync, then `os.replace`. A target with byte-identical content is not rewritten.
4. Secret scan over every rendered note. At minimum: GitHub tokens (`ghp_`, `gho_`, `ghu_`, `ghs_`,
   `ghr_`, `github_pat_`), PEM private-key headers, minisign secret-key comment lines, `sk-ant-`, AWS
   access key ids. On a hit the script reports note, line number and pattern **name**. It never prints
   the matched text.
5. The script never deletes anything. A stale generated note stays where it is (deletion is a later task
   if Ludwig wants it).
6. The script reads from the vault only two things: a target's frontmatter (to check `generated: true`)
   and its bytes (to compare before writing). The vault is never a source of content.
7. `WOM_VAULT` is resolved from the environment first, then from `~/.config/wom/vault-path` (one line).
   Neither the path nor the config file is committed.
8. The script is Python 3 stdlib only and is run with `python3 -I`.

### Subcommand `check`
`wom_vault.py check --baseline <file>` / `--save-baseline <file>`: records (name, size, mtime) of every
file under `WOM_VAULT` without `generated: true` (metadata plus frontmatter only), and later verifies
that none changed. This guards the hand-written notes on every live run.

## File scope (declared)
`tools/vault/wom_vault.py`, `tools/vault/tests/**` (fixtures and test runner), `docs/tools/vault-projection.md`
(the contract above, setup and running), `docs/manager/COMMANDS.md` (only if Q-C2 = A),
`docs/manager/OPERATIONS.md` (one entry: how to run it), `docs/tasks/051-verify.sh`, this file's log.

## Acceptance criteria (all script-verified through `051-verify.sh` unless marked)
1. In a temporary git repo fixture with a vault path containing spaces and a non-ASCII character,
   mode `main` produces exactly the specified note set with correct frontmatter, and `source_commit`
   equals `git rev-parse main`.
2. An immediate second run writes zero files (every mtime unchanged).
3. A hand-written fixture note (no `generated: true`) named like a generated one (`Status.md`) causes a
   non-zero exit with **zero files written**. Fixtures with the three real hand-written notes' **names**
   (`Agent Session Handover Prompt.md`, `MINISIGN.md`, `Olika Sessioner.md`, dummy content) stay
   byte- and mtime-identical.
4. One fixture per secret-pattern class produces a non-zero exit, zero files written, and output that
   names the pattern. The test asserts that the fixture's secret string appears **nowhere** in stdout or stderr.
   Positive control: the real repository's current main renders with no hit.
5. Each invalid `WOM_VAULT` case in write rule 2 exits non-zero, writes nothing, and creates no directory.
6. Mode `task` in a fixture with main plus an open task branch writes only that task's note. A main run
   skips that note. After the branch is merged, a main run writes it with the Status line from main.
   Mode `task` refuses to write a main-derived note.
7. Two concurrent runs serialize on the lock. No temp files remain, and the final content equals a
   single run's output.
8. A stale generated note that is not in the current set is left untouched.
9. `check` detects a changed, added or removed hand-written fixture note and passes when nothing changed.
10. **Mutation proof (§2c rule 2):** the log shows each of these checks turning red when its guard is
    removed: the `generated: true` check, the secret scan, two-phase writing, the ownership rule, the
    lock, and skip-identical.
11. `051-verify.sh` passes in a fresh clone of the task branch (§2c rule 4).
12. `docs/tools/vault-projection.md` documents the contract, setup (`~/.config/wom/vault-path`) and
    commands. Its claims about Obsidian/LiveSync behaviour cite task 050's results.
13. **Human, after merge, with Ludwig present:** the first live run (`check --save-baseline`, `write --ref main`,
    `check`) shows the notes on Windows and on the phone, and `check` stays green. This is recorded in
    the log as Ludwig's confirmation.

## Forbidden here
- **Running anything against the real vault before AC13.** `051-verify.sh` and every test must set
  `WOM_VAULT` to a `mktemp -d` path **and** `HOME` to a temp dir, so the config-file fallback cannot
  reach the real vault. The script refuses to run if either is unset.
- Committing in the task worktree as part of a test. Tests build their own temp repos. (Task 052 will
  install git hooks shared by all worktrees.)
- Reading the content of anything in the real vault, ever. The task log never contains the vault path.
- Any network access, any dependency outside the Python stdlib, any Obsidian install.
- Printing a matched secret. Catch-and-ignore around a write (§3.7).
- Writing to `.claude/`, `.git/hooks` or any other doctrine file (that is task 052 and 048).

## Dependency graph
Creates tooling node `vault-projection` (outside SITE-V1's graph; Ludwig's direct request). It has one
edge, repo → vault, whose contract is `docs/tools/vault-projection.md`. There are no edges to SITE-V1
nodes.

## Deliverables
Code, tests, `051-verify.sh` (output pasted in the log), docs, and the log current.

## Questions (agent-maintained; MANAGER.md §8b)

---
# Task 051 log
- 2026-10-14 manager: spec written. Gate items 1–8 checked by the manager. This task writes outside the
  repo and contains a secret scan, so it is security-touching: an independent spec review by the reviewer
  is required before delegation (§2b).
