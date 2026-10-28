# Task 099: move the 098 ADR proposal out of `docs/tasks/` (it broke the vault projection's task-id uniqueness)

- **Mission:** none (repair of task 098's file placement) — **Status:** spec-approved 2026-10-28 (manager, session 14; small, solo §2b)
- **Agent / model:** manager (a file move and two reference edits in documentation; no production code) — **Budget:** small
- **Branch / worktree:** `task/099-move-098-proposal` / `~/wt/task-099` (platform)

## Objective
`tools/vault/refresh-main.sh` after merging #91 failed: "two task files share the id 098: docs/tasks/098-adr-first-mod-party-board.md and
docs/tasks/098-proposed-adr.md" (the projection reads every `docs/tasks/NNN-*.md` as a task file). Move the proposal to
`docs/design/party-board-mod-proposed-adr.md` with `git mv` and update the live references in `docs/design/party-board-mod.md`; the 098 task file's
spec and log lines are history and stay, with a log note here.

## Acceptance criteria
1. `git diff --name-status origin/main...HEAD` shows the rename (R) plus `docs/design/party-board-mod.md` and this file only.
2. `grep -rn '098-proposed-adr' docs/design` returns 0 lines; `grep -c 'party-board-mod-proposed-adr.md' docs/design/party-board-mod.md` >= 2.
3. `python3 -I tools/vault/wom_vault.py` run against this branch in write-free mode (or the post-merge `refresh-main.sh`) no longer reports the id clash; output pasted.

---
# Task 099 log
