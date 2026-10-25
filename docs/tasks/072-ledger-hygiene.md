# Task 072: ledger hygiene — true statuses, OPERATIONS.md gotchas from session 11, merged worktrees removed

- **Mission:** SITE-V1 (ledger integrity) — **Status:** spec-approved (manager, solo gate, 2026-10-25)
- **Repo:** platform (ledger + OPERATIONS.md); local worktree cleanup for platform and registry.
  **Agent / model:** doc-writer (ROUTING.md). **Budget:** small (≤ 1 agent-session)
- **Branch / worktree:** `task/072-ledger-hygiene` / `~/wt/task-072`, cut from platform `origin/main` (`d9d48de` or later)
- **Graph:** ledger and docs only.

## Source
Booked since session 10 (mission log, "Next session starts here" items). Measured 2026-10-25: most task files in
`docs/tasks/` carry stale statuses (e.g. 064-080 merged but still `spec-approved`); task files are cited by path from
verify scripts (e.g. `051-verify.sh:68` accepts `docs/tasks/` or `docs/tasks/done/`), so **moving** files can redden
closed scripts — moves are out of scope here (Question for Ludwig, below).

## Objective
1. **Statuses (platform `docs/tasks/*.md`, not `done/`):** set each task file's status line to its true state, from
   evidence only: `done` when its work is merged on a `main` (platform or registry; cite the merge commit or PR number in
   a short log line in that task file's log, marked "status corrected by task 072"), `stopped` only if the mission log
   says so, otherwise leave it. Never mark done without a merged PR or merge commit you can name (`gh pr list --state
   merged --search`, `git log --merges --grep`). Edit only the status line and append one log line per file.
2. **OPERATIONS.md:** add a dated section "What session 11 paid for" with these gotchas, each 2-4 lines, from the
   mission log's session 11 entries: (a) the manager's EnterWorktree pins the session and its agents — don't use it when
   agents must work in other repos' worktrees; (b) stale ignored `__pycache__` reddens 049 — run verify scripts with
   `PYTHONDONTWRITEBYTECODE=1`; (c) add/add conflicts on task files between the session branch and a task PR — main's
   copy is the superset, check before taking it; (d) verify scripts must pass in a fresh clone from GitHub, not only in
   worktrees (a cite to a local-only branch broke 056/076/078); (e) a fresh registry worktree has no
   `tools/dev/node_modules` — 062 needs `WOM_NODE_MODULES` or `npm ci`; (f) verify scripts run one at a time — overlapping
   runs falsely redden 062/067; (g) the permission classifier refused a self-granted permission rule and an
   unreviewed-looking merge — both were taken to Ludwig, never worked around.
3. **Worktree removal (local, no repository change):** for each of these, remove it with `git worktree remove <path>`
   (never `--force`) **only if** (i) `git status --porcelain` in it is empty, (ii) its branch tip is an ancestor of the
   matching `origin/main` (`git merge-base --is-ancestor`), (iii) the PR is merged: platform `~/wt/task-{056,058,068,
   074,076,077,078,079,080}`, `~/wom/.claude/worktrees/session-11`, `~/wt/session-11b`; registry
   `~/wt/registry-task-{064,066,069,070,071,007b,075}`. Any failing condition → leave it and list it with the reason.
   Log every removal with the three checks' results. Do not delete branches. Do not touch `~/wt/task-023`, `task-058` if
   unmerged, `.claude/worktrees/session-10`, `session-9-specs`, or anything not listed.

## Acceptance criteria — `docs/tasks/072-verify.sh`, whose output the log pastes
1. Every status changed to `done` names a merge commit or PR in the file's log, and that commit exists on the matching
   `origin/main` (script checks with `git cat-file -e` / `git merge-base --is-ancestor`; registry via
   `git -C /home/ludwig/registry`).
2. `git diff` of each task file touches only the status line plus appended log lines.
3. OPERATIONS.md: the new section exists with items (a)-(g); nothing else in the file changed.
4. Every `docs/tasks/*-verify.sh` exits 0, one at a time, foreground, `PYTHONDONTWRITEBYTECODE=1`, from the worktree root.
   Own-change checks on fixed SHAs (REVIEW-CHECKLIST item 12).

## File scope
`docs/tasks/*.md` (status line + one log line each; not `done/`, not the mission log, not the mission spec),
`docs/manager/OPERATIONS.md` (new section only), `docs/tasks/072-ledger-hygiene.md` (log), `docs/tasks/072-verify.sh`.

## Forbidden
Moving or renaming task files; editing spec bodies; `git worktree remove --force`; deleting branches; marking anything
done without a nameable merge.

## Questions (for Ludwig, via the manager)
- Moving finished task files to `docs/tasks/done/` breaks verify scripts that cite them by path. A ★ leave them in
  place (status line is the truth); B move them and update every citing script (a larger task).

---
# Task 072 log
- 2026-10-25 manager (session 11): written and approved (solo gate). Narrowed from session 10's plan: no file moves.
