# Task 063: MANAGER.md §5 describes check-log-entry.sh as it exists, not as a future script

- **Mission:** SITE-V1 (doctrine upkeep) — **Status:** review (awaiting Ludwig's merge approval); spec-approved by the manager 2026-10-15; **merge needs Ludwig's
  written approval** (doctrine, MANAGER.md §7)
- **Agent / model:** the manager writes the doctrine text in session with Ludwig, as for task 048 (the auto-mode
  classifier denied agent edits to doctrine on 2026-10-14; that denial is not worked around). Independent review:
  reviewer agent, read-only.
- **Budget:** small
- **Branch / worktree:** `task/063-doctrine-log-entry-check` / `~/wt/task-063`
- **Graph:** no node or edge. Doctrine only.

## Objective
`docs/manager/MANAGER.md` §5's bullet "Log-entry check after every subagent" no longer says the script "is built in
task 049 and does not exist until 049 merges" or prescribes the hand-count fallback. It states the two commands the
manager actually runs (`count` before delegating, `check … BASELINE` after the report-back) and points to
`OPERATIONS.md` for the exit codes. Nothing else in the doctrine changes.

## Context to load
- `docs/manager/MANAGER.md` §5 (the bullet); `docs/manager/OPERATIONS.md`, "git-guard.log and check-log-entry.sh
  (task 049)"; `tools/manager/check-log-entry.sh` (usage header); `docs/tasks/049-safety-hooks.md` (merged, PR #51).
- Source of the finding: mission log, "SESSION STATUS / HANDOVER — 2026-10-15 (session 8, day part)", item 3.

## The exact change
Old (one bullet, MANAGER.md §5):
> - **Log-entry check after every subagent** (task 048; Ludwig's decision Q6, 2026-10-14). After every subagent
>   run the manager runs `tools/manager/check-log-entry.sh`; a non-zero exit means the run is not accepted until
>   the agent, or a fresh one, writes the entry. **That script is built in task 049 and does not exist until 049
>   merges**; until then the manager counts the dated entries in the task log before and after the run by hand and
>   logs both counts. No separate handover file is introduced: the task log stays the single handover (§5).

New:
> - **Log-entry check after every subagent** (task 048; Ludwig's decision Q6, 2026-10-14; script built by task 049).
>   Before delegating, the manager runs `tools/manager/check-log-entry.sh count docs/tasks/NNN-slug.md` and writes
>   the number in the task log; after the report-back it runs
>   `tools/manager/check-log-entry.sh check docs/tasks/NNN-slug.md BASELINE`. A non-zero exit means the run is not
>   accepted until the agent, or a fresh one, writes the entry (exit codes: `OPERATIONS.md`, "git-guard.log and
>   check-log-entry.sh"). No separate handover file is introduced: the task log stays the single handover (§5).

## File scope
`docs/manager/MANAGER.md` (that bullet only); this task file as the log; `docs/tasks/063-verify.sh` (new).

## Acceptance criteria — `docs/tasks/063-verify.sh`
1. `git diff origin/main -- docs/manager/MANAGER.md` changes only the lines of that bullet (hunk count 1, inside §5).
2. `grep -c "does not exist until 049" docs/manager/MANAGER.md` prints 0; `grep -c "by hand and" …` prints 0
   (positive control: both print 1 on `origin/main`'s blob).
3. Both commands quoted in the new text match the usage line of `tools/manager/check-log-entry.sh` (the script's
   `count` and `check` modes are grepped from its header, not retyped).
4. The changed-file set is a subset of the file scope.
5. Mutation: restoring the old sentence reddens AC2; changing `count` to `counts` in the doctrine reddens AC3.
6. Ludwig approves the merge in writing (human criterion, not script-verified).

## Forbidden here
Any other doctrine edit; touching CLAUDE.md, the checklists or OPERATIONS.md; an agent writing the doctrine text.

## Dependencies
None. Independent of 062 and 007.

---
# Task 063 log
- 2026-10-15 manager: spec written (session 9) from the session-8 handover item 3.
- 2026-10-15 verify agent: wrote and committed `docs/tasks/063-verify.sh` (3b7197f). Run in a fresh clone of the branch with `./docs/tasks/063-verify.sh --mutate`; its first block is exactly what the plain run `docs/tasks/063-verify.sh` prints (the plain run in the worktree was also run and is green). Output pasted from the script, rc=0. Notes: (a) the doctrine quotes the OPERATIONS.md section name across a line break, so the script joins lines before searching; (b) the AC1 mutation "edit outside the bullet" merges into the bullet's hunk because the edited heading is adjacent, so it is caught by the inside-bullet check, not the hunk count; (c) AC6 (Ludwig approves the merge) is human and not script-verified.

```
base: ac407bf311995c11adf1a845c639b0c3fc886852 (Merge pull request #54 from worldofmodcraft/session/8-manual-steps)
== AC1-AC4 on /home/ludwig/.claude/jobs/05479e5e/tmp/fresh.Ff5BzF/c ==
  PASS AC1 exactly one hunk (hunks=1, expected 1)
  PASS AC1 bullet located in §5 (before '## 6.') (range='163 169')
  PASS AC1 hunk lies inside bullet lines 163-169 (hunks seen=1 outside=0)
  PASS AC2 positive control: 'does not exist until 049' on base blob (count=1, expected 1)
  PASS AC2 'does not exist until 049' absent from doctrine (count=0, expected 0)
  PASS AC2 positive control: 'by hand and' on base blob (count=1, expected 1)
  PASS AC2 'by hand and' absent from doctrine (count=0, expected 0)
  PASS AC3 header lists both modes (count, check) (modes=count check)
  PASS AC3 doctrine quotes 'count' with 1 args as in header (matches=1)
  PASS AC3 doctrine quotes 'check' with 2 args as in header (matches=1)
  PASS AC3 OPERATIONS.md section cited by the doctrine exists (count=1)
  PASS AC3 doctrine cites that section (count=1)
  PASS AC3 'count' runs and prints an integer (rc=0 out=1)
  PASS AC3 'check' with baseline count-1 exits 0 (rc=0)
  PASS AC3 'check' with baseline=count exits 1 (rc=1)
  PASS AC4 changed files (docs/manager/MANAGER.md docs/tasks/063-doctrine-log-entry-check.md docs/tasks/063-verify.sh) subset of scope (offenders='')
  PASS AC4 control: out-of-scope path rejected (rc=1)
  PASS AC4 control: empty change set rejected (rc=1)
result: GREEN
== AC5 mutations (temporary clone, this tree untouched) ==
-- mutation: restore old sentence
  before: ac2 failing=0 (expected 0)
    FAIL AC2 'does not exist until 049' absent from doctrine (count=1, expected 0)
    FAIL AC2 'by hand and' absent from doctrine (count=1, expected 0)
  mutated: ac2 failing=2 (expected >0)
  restored: ac2 failing=0 (expected 0)
-- mutation: count -> counts
  before: ac3 failing=0 (expected 0)
    FAIL AC3 doctrine quotes 'count' with 1 args as in header (matches=0)
  mutated: ac3 failing=1 (expected >0)
  restored: ac3 failing=0 (expected 0)
-- mutation: edit outside the bullet (AC1)
  before: ac1 failing=0 (expected 0)
    FAIL AC1 hunk lies inside bullet lines 163-169 (hunks seen=1 outside=1)
  mutated: ac1 failing=1 (expected >0)
  restored: ac1 failing=0 (expected 0)
-- mutation: stray changed file (AC4)
    FAIL AC4 changed files (docs/manager/MANAGER.md docs/manager/OPERATIONS.md docs/tasks/063-doctrine-log-entry-check.md docs/tasks/063-verify.sh) subset of scope (offenders='docs/manager/OPERATIONS.md')
  mutated: ac4 failing=1 (expected >0)
  restored: ac4 failing=0 (expected 0)
result (mutations): ALL CAUGHT, ALL RESTORED
OVERALL: GREEN
```
- 2026-10-15 manager: Ludwig approves the merge in session: "★ på alla" (his answer to the session-9 list "Godkänna merge (★ jag rekommenderar ja på alla)", covering platform #55, registry #10, registry #9 and platform #56).
