# Task 072: ledger hygiene — true statuses, OPERATIONS.md gotchas from session 11, merged worktrees removed

- **Mission:** SITE-V1 (ledger integrity) — **Status:** done (merged as platform PR #71, `4de1218`, 2026-10-25)
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
- 2026-10-25 doc-writer (task 072): Objective 1 done. 34 task files set to `done`, each with a merged PR/commit named in its own log line and checked on the matching origin/main by `072-verify.sh` AC1 (registry via `git -C /home/ludwig/registry`). Caveats kept in the status line: 048 (AC9 live check open), 052 (AC7 live check open), 056 (first version only, second pass due).
- 2026-10-25 doc-writer (task 072): left unchanged, not mergeable on the evidence: 007 (umbrella), 008, 008b, 008c, 010, 039, 040, 055 (draft/spec-approved, no merge); 031, 043 (043's rule is not in MANAGER.md on main; 031 blocked); 047 (umbrella, draft; split into 048-053, mission log does not say stopped); 058 (task/058 unmerged); 065 (not dispatched); 041 (done in the **site** repository per the mission log, "site PR #2", which this task's evidence rules do not cover: uncertain); 049, 060, 061, 073 already `done`. `stopped` applied to none (mission log stops none).
- 2026-10-25 doc-writer (task 072): Objective 2 done: OPERATIONS.md section "What session 11 paid for" with (a)-(g), one contiguous addition, no line changed.
- 2026-10-25 doc-writer (task 072): `072-verify.sh` (pinned BASE `d9d48de`, FINAL `7df8a50979cc834918871ba948aa9ed7e9eb4352`): ALL CHECKS PASSED, exit 0; with FINAL=BASE it exits 1 (control). AC4, run serially, foreground, `PYTHONDONTWRITEBYTECODE=1`, from the worktree root, no other verify running: 048 049 051 052 053 056 059 061 063 068 072 076 078 079 080 all `exit=0` (15 scripts).
- 2026-10-25 doc-writer (task 072): Objective 3, after the PR was pushed (#71). Each removal used plain `git worktree remove` (no --force), no branch deleted. Checks per worktree: (i) `git status --porcelain` empty, (ii) tip an ancestor of the matching origin/main, (iii) PR merged (`gh pr list --head <branch> --state merged`). All three passed for the 16 removed:
  - removed /home/ludwig/wt/task-056 (task/056-architecture-note @ 1042234): i empty, ii ancestor, iii merged PR #43 
  - removed /home/ludwig/wt/task-068 (task/068-runbook-markers @ 6d4b61e): i empty, ii ancestor, iii merged PR #58 
  - removed /home/ludwig/wt/task-074 (task/074-adr-removal-policy @ f905136): i empty, ii ancestor, iii merged PR #61 
  - removed /home/ludwig/wt/task-076 (task/076-doctrine-removal-and-pinning @ 38603b0): i empty, ii ancestor, iii merged PR #66 
  - removed /home/ludwig/wt/task-077 (task/077-runbook-archive-protection @ cc4da92): i empty, ii ancestor, iii merged PR #63 
  - removed /home/ludwig/wt/task-078 (task/078-closed-verify-repin @ 2334426): i empty, ii ancestor, iii merged PR #67 
  - removed /home/ludwig/wt/task-079 (task/079-rule0-live-guard @ d95fc81): i empty, ii ancestor, iii merged PR #68 
  - removed /home/ludwig/wt/task-080 (task/080-adr0121-cite @ fe050ab): i empty, ii ancestor, iii merged PR #69 
  - removed /home/ludwig/wom/.claude/worktrees/session-11 (worktree-session-11 @ d2ef827): i empty, ii ancestor, iii merged PR #64 
  - removed /home/ludwig/wt/registry-task-064 (task/064-schema-check-end-anchor @ 5002b46): i empty, ii ancestor, iii merged PR #13 
  - removed /home/ludwig/wt/registry-task-066 (task/066-registry-dev-tools-ajv @ 4ad31a7): i empty, ii ancestor, iii merged PR #14 
  - removed /home/ludwig/wt/registry-task-069 (task/069-closed-verify-maintenance @ cf69734): i empty, ii ancestor, iii merged PR #15 
  - removed /home/ludwig/wt/registry-task-071 (task/071-repin-007b-verify @ fad9b96): i empty, ii ancestor, iii merged PR #17 
  - removed /home/ludwig/wt/registry-task-007b (task/007b-registry-checker-ownership @ 17555d9): i empty, ii ancestor, iii merged PR #12 
  - removed /home/ludwig/wt/registry-task-075 (task/075-takedown-only-removal @ 7d91a3d): i empty, ii ancestor, iii merged PR #18 
  - removed /home/ludwig/wt/registry-task-070 (DETACHED @ 0228006): i empty, ii ancestor, iii merged PR #n/a(detached)
  - registry-task-070 was a detached HEAD: (iii) checked by PR instead: registry PR #16 (task/070-closed-verify-head-audit) is MERGED and its head 0228006 equals the worktree tip.
  - kept: ~/wt/task-058 (branch task/058-archive-url-probe @ c5340aa not an ancestor of origin/main, no merged PR; spec says leave if unmerged); ~/wt/session-11b (session/11b @ 750ced9 not an ancestor of origin/main; holds unmerged manager commits; told to keep). Not touched: task-023, .claude/worktrees/session-10, session-9-specs, task-072 (this task).
- 2026-10-25 manager: status corrected to done after Ludwig's "merga PR71" (platform PR #71, `4de1218`).
