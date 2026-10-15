# Task 063: MANAGER.md §5 describes check-log-entry.sh as it exists, not as a future script

- **Mission:** SITE-V1 (doctrine upkeep) — **Status:** spec-approved (manager, 2026-10-15); **merge needs Ludwig's
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
