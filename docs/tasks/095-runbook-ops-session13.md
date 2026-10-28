# Task 095: runbook M9 records Ludwig's "Require approvals" choice; OPERATIONS.md gains session 13's gotchas

- **Mission:** SITE-V1 (runbook and operations hygiene) — **Status:** spec-approved 2026-10-28 (manager, solo: small doc-only task)
- **Agent / model:** doc-writer (model per frontmatter) — **Budget:** small
- **Branch / worktree:** `task/095-runbook-ops-session13` / `~/wt/task-095` — **platform** repo, from main `465835a`

## Why
(1) Ludwig chose on 2026-10-28 (mission log, "Ludwig, 2026-10-28 (verbatim)") to leave **Require approvals** unticked under "Require a
pull request before merging" (choice A of For Ludwig item 2); runbook M9 step 7 still says "stop and tell the manager". (2) Session 13
paid for four operational lessons that the next manager must not re-learn.

## Acceptance criteria (doc-only; evidence = commands pasted in the log)
1. Runbook M9 step 7: if **Require approvals** is ticked, untick it (decided, Ludwig 2026-10-28, cite the mission log heading); describe
   where it sits (directly under "Require a pull request before merging", indented, with a number list beside it showing 1) and mark that
   placement `[unverified]` (from the manager's memory of GitHub's classic branch-protection page; Ludwig confirms when he does M9). Keep
   "if the page looks different (e.g. it is called Rulesets), stop and tell the manager". The reason sentence stays.
2. `docs/manager/OPERATIONS.md` gains a section "Four things session 13 paid for (2026-10-28)", appended after the last section, with:
   (a) the manager must not use `EnterWorktree`: the harness then refuses git and shell commands outside that worktree for the manager
   and its agents (registry clones, `~/wt/*`); use a plain `git worktree add ~/wt/session-NN` instead;
   (b) `SendMessage` to a finished subagent **resumes** it: never message a stopped agent whose task was re-dispatched (two writers in
   one worktree, 008c);
   (c) the registry gate's schema step reports only the first schema error of a file (L3, registry PR #26);
   (d) `gh pr merge` chained with other commands was denied again (see "`gh pr merge` must be run as a BARE command"): re-learned, run it bare.
   Each item cites where it was observed (mission log, session 13).
3. `git diff --name-only origin/main...HEAD` = the runbook, OPERATIONS.md and this task file; the runbook hunks are inside M9 only.
4. No verify script is run by the agent (another task owns the machine); the manager runs `068-verify.sh` (runbook markers) later on a quiet machine.

## File scope
`docs/runbooks/site-v1-manual-steps.md` (M9 step 7 only), `docs/manager/OPERATIONS.md` (one appended section), this file.

---
# Task 095 log  (append-only)
- 2026-10-28 manager (session 13): drafted and spec-approved.
