# Vault projection (`tools/vault/wom_vault.py`)

Writes a fixed set of English notes from the repository's git objects into the Obsidian vault
directory `WOM_VAULT`. Every note is regenerable from git; the tool never edits a hand-written note.
Built by task 051 (`docs/tasks/051-vault-projection.md`), extended by task 053 (decision and journal notes,
amendments A1-A3); verified by `docs/tasks/051-verify.sh` and `docs/tasks/053-verify.sh`.
It is one edge, repo to vault, outside SITE-V1's dependency graph, and this document is its contract
(ADR-0117).

## Contract

**Source:** git objects of a named ref, never the working tree. Notes are UTF-8 with LF line endings.
Every note starts with this frontmatter:

```
---
generated: true
source_ref: <main | task/NNN-...>
source_commit: <full sha>
source_path: <repo path(s)>
updated: <committer date of source_commit, ISO 8601>
---
```

- **Single-source notes** (`Gotchas.md`, `Commands.md`, `Mission Log.md`, main-owned `Tasks/NNN.md`):
  `source_commit` is the last commit that touched the source path on the ref, so a merge that did not
  change a source leaves its note untouched.
- **Aggregate notes** (`Status.md`, `Tasks.md`): derived from the ref's files plus the list of local
  `task/*` branches. `source_commit` is the ref's HEAD, so these two are rewritten on every new commit.
  They are the only notes with that churn.

### Mode `main`: `write --ref main`

| Note | Derived from |
|---|---|
| `Status.md` | the last `## SESSION...` section of `docs/tasks/MISSION-worldofmodcraft-site-v1-log.md`, verbatim; every later top-level `## ` section whose heading contains `For Ludwig`, verbatim; a table of open tasks with `[[Tasks/NNN]]` links |
| `Tasks.md` | every `docs/tasks/NNN-*.md` and `docs/tasks/done/NNN-*.md`: id, title (first `# ` line), status word, link; plus a table of open local task branches |
| `Gotchas.md` | `docs/manager/OPERATIONS.md`, verbatim |
| `Commands.md` | `docs/manager/COMMANDS.md`, verbatim |
| `Mission Log.md` | the mission log, verbatim |
| `Tasks/NNN.md` | only for ids owned by main: id, title, status word, task file path |
| `Decisions.md` | `docs/decisions/INDEX.json`: one row per ADR with id, title and a `[[ADR/<file stem>]]` link; `source_commit` is the last commit touching INDEX.json |
| `ADR/<file>.md` | `docs/decisions/NNNN-*.md`, body verbatim under the generated frontmatter; `source_commit` is the last commit touching that file |
| `Journal/YYYY-MM-DD.md` | every commit reachable from the ref, merges included, grouped by committer date in `Europe/Stockholm` (`zoneinfo`); one line per commit, newest first: 7-character sha, subject; `source_commit` is the newest commit of that day |

**Decisions and journal (task 053).** ADRs carry no YAML frontmatter. An ADR whose text starts with `---`
(after an optional BOM) fails validation, so two frontmatter blocks are never merged. The ADR set must equal the
set listed in INDEX.json (a listed file that is missing, an unlisted ADR file, a filename listed twice, a number
that does not match its filename prefix, or an unparsable index is an error, nothing written). A ref with no
`docs/decisions/` at all writes no decision notes and the summary says `decisions_absent=1`; ADR files without an
INDEX.json are an error. Each Journal day is re-rendered on every run and written only if its bytes changed, so a
new commit rewrites only its own day. The first live run writes about 130 notes in one LiveSync burst (accepted
as a one-off); later runs write only what changed. Commit subjects and ADR text go through the secret scan like
every other note.

Headings inside code fences are not section boundaries. A missing source file, or a mission log with no
`## SESSION` heading, is an error (nothing written), never an empty note.

The **status word** is the capture of `\*\*Status:\*\*\s*\**([a-z-]+)`. A task is open unless the word is
`done` or `stopped` or the file lives in `done/`. A file without a match is listed as `status unparsed`
and counted in the run summary (`status_unparsed=N`); that is not an error.

### Mode `task`: `write --ref HEAD`, inside a worktree on `task/NNN-*`

Writes only `Tasks/NNN.md`: branch, status word, the last line starting with `- ` after the first
`# Task NNN log` / `## Log` style heading, and `git log --oneline main..HEAD`. With no heading or no
bullet the note says `no log entry` and the summary counts it (`no_log_entry=1`). On any other branch,
on a branch already merged into main, or with `--note` naming any other note: non-zero exit, nothing written.

### One writer per file
- The key is the three-digit id only (file slugs and branch slugs differ).
- `Tasks/NNN.md` belongs to a local branch `task/NNN-*` while that branch exists and is not an ancestor of
  `main` (`git merge-base --is-ancestor`); otherwise to main. A branch deleted without merging hands the
  note to main. A squash-merged branch stays branch-owned until it is deleted, because it is never an
  ancestor.
- **Duplicate ids (A1).** If more than one unmerged local branch matches `task/NNN-*` for the same id, mode
  `main` writes nothing for `Tasks/NNN.md` and `Status.md` gains a `## Task id conflicts` section naming the
  branches; mode `task` refuses (non-zero exit, `id conflict`, nothing written). The run summary counts these as
  `id_conflicts=N`. The conflict ends when one of the branches is merged or deleted.
- Every run holds an exclusive `flock` on `$(git rev-parse --git-common-dir)/wom-vault.lock`, waiting at
  most 30 s; then it exits non-zero with `lock timeout` and writes nothing.

### Write rules
1. Two phases: render and validate everything, then write. Any validation failure writes nothing.
2. Validation fails when `WOM_VAULT` cannot be resolved, is relative, is missing, is not a directory or is
   itself a symlink; a target's `realpath` is outside `realpath(WOM_VAULT)`; a planned target exists but is not
   a regular file (a symlink, FIFO, directory or device, checked with `lstat` for every target before any file is
   opened, A2); a planned target exists without `generated: true` in its frontmatter; a target name is forbidden; or a secret pattern matches.
3. Atomic writes: a dot-prefixed temp file in the target's own directory, `fsync`, `os.replace`. A target
   with identical bytes is not rewritten. A crash can leave a hidden `.NAME.pid.ns.wom-tmp`; the tool
   never deletes anything, so such a file is removed by hand (it does not sync, see task 050 log).
4. **Secret scan** over every rendered note with length- and charset-bounded patterns: `gh[pousr]_` plus 36
   characters, `github_pat_` plus 82, a PEM private-key header, the minisign secret-key comment,
   `sk-ant-` plus 32 or more, `AKIA`/`ASIA` plus 16. A hit names the note, line number and **pattern
   name**, never the matched text. Prose that only names a prefix does not match.
5. The tool never deletes. `Tasks/`, `ADR/` and `Journal/` are created only in the write phase, only inside the validated vault.
6. Only planned targets are ever opened in the vault. The names `Agent Session Handover Prompt.md`,
   `MINISIGN.md` and `Olika Sessioner.md` are hard-coded as forbidden target names (case- and
   Unicode-normalisation-insensitive), checked before any read. `--note NAME` exists so that a request
   for such a name can be refused.
7. `WOM_VAULT` comes from the environment, then from `~/.config/wom/vault-path` (one line; neither the path
   nor the file is committed).
8. **Test mode.** `WOM_VAULT_TEST=1` ignores the config file, requires `WOM_VAULT` in the environment and
   refuses any vault whose `realpath` is not under `realpath(${TMPDIR:-/tmp})`. Without test mode, any
   vault under `/tmp` is refused.
9. Python 3 standard library only, run as `python3 -I`.

### Subcommand `check` (stat only)
`check --save-baseline FILE` records (size, `mtime_ns`) via `stat` for every file under `WOM_VAULT` whose
path is not a planned generated name (`Status.md`, `Tasks.md`, `Gotchas.md`, `Commands.md`, `Mission
Log.md`, `Tasks/NNN.md`, `Decisions.md`, `ADR/NNNN-*.md`, `Journal/YYYY-MM-DD.md`). `check --baseline FILE` reports every changed, added or removed entry and exits
non-zero on a difference. It never opens a file in the vault. Note: `.obsidian/` is included, and
Obsidian rewrites files there while it runs; see the open question in task 051.

## Setup
1. The vault folder path lives outside git: `~/.config/wom/vault-path`, one line, absolute. Or export
   `WOM_VAULT` for one shell.
2. Python 3 and `git` are the only requirements. Run from any worktree of the repository (the repository
   is the current directory, or pass `--repo PATH`).

## Commands
```
python3 -I tools/vault/wom_vault.py check --save-baseline "$HOME/wom-vault-baseline.json"
python3 -I tools/vault/wom_vault.py write --ref main
python3 -I tools/vault/wom_vault.py check --baseline "$HOME/wom-vault-baseline.json"
python3 -I tools/vault/wom_vault.py write --ref HEAD      # inside a task/NNN-* worktree
docs/tasks/051-verify.sh [--mutate]                       # self-test, temp dirs only
docs/tasks/053-verify.sh [--mutate]                       # 053 additions, A1-A3; re-runs 051-verify.sh
```
Exit status 0 means success; 1 means a refusal (reason on stderr, nothing written); 2 is a usage error.

## Why these claims hold (Obsidian and LiveSync)
Task 050's log (`docs/tasks/050-vault-sync-probe.md`, "Task 050 log") records the observations the design
rests on, 2026-10-14: a file written from WSL appears in Windows Obsidian without a restart and on the phone
through LiveSync (AC1a, AC1b); renaming a temp file over an existing note updates both (AC2a, AC2b); a
dot-prefixed file does not appear on either (AC3); the three hand-written notes were not disturbed (AC4).
That is why the tool writes a dot-prefixed temp file in the same directory and renames it over the target.

## Verification
`docs/tasks/053-verify.sh` runs `tools/vault/tests/test_vault_053.py` (decisions, journal, A1, A2), proves with a
`grep` that exits 2 that `051-verify.sh`'s committed-secret scan turns red (A3: an erroring scan is a failure,
never "none found"), and re-runs `051-verify.sh`; `--mutate` uses `tools/vault/tests/mutate053.py`.
`docs/tasks/051-verify.sh` runs `tools/vault/tests/test_vault.py` against temporary repos and vaults only.
`--mutate` breaks a temp copy of the tool once per guard (`tools/vault/tests/mutate.py`) and requires the
matching tests to turn red. The strace-free proof that rejected runs never open vault files is
`tools/vault/tests/audit_run.py`.
