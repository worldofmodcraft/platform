# Task 054: Write the missing SITE-V1 task specs

- **Mission:** SITE-V1 — **Status:** done (merged platform PR #42 `96ed6b0`) — was: in-progress (spec-approved by the manager, 2026-10-14; small, documentation only, §2b solo gate)
- **Agent / model:** doc-writer / per agent frontmatter
- **Budget:** small
- **Branch / worktree:** task/054-site-v1-remaining-specs / ~/wt/task-specs-site

## Objective
Task files exist, as status `draft`, for every piece of remaining SITE-V1 work that has none:
- 008 build pipeline
- 010 test mod and runbook
- 055 site on the live registry, plus the E12 trigger
- 056 D5 architecture note

041 is also completed to gate-ready. Every one of them is ready for the manager's spec gate.

## Origin
The surveyor's remaining-work map (2026-10-14, session 8) found D2, D4, E12 and D5 unbooked.

## Acceptance criteria
1. Each file follows TASK-TEMPLATE and has every SPEC-CHECKLIST item addressed (manager-verified at the gate).
2. Environmental claims are verified with the command shown, or caveated inline (§3.6b).
3. No file outside `docs/tasks/` is touched.
No verify script: these criteria are documentary and checked by the manager's gate, not by commands.

## Forbidden here
Code; credentials; edits to decisions, the mission spec or other task files.
- 2026-10-25 doc-writer (task 072): status corrected by task 072: done, merged as platform PR #42 (`96ed6b0`, on platform origin/main).
