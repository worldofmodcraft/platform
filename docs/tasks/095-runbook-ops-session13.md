# Task 095: runbook M9 records Ludwig's "Require approvals" choice; OPERATIONS.md gains session 13's gotchas

- **Mission:** SITE-V1 (runbook and operations hygiene) — **Status:** done 2026-10-28 (spec-approved same day, manager solo; reviewed)
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
- 2026-10-28 manager (session 13): criterion 2 written by the manager itself (OPERATIONS.md gotchas are a manager handover duty, MANAGER.md §5.4b; agents' doctrine edits are classifier-denied, OPERATIONS.md 2026-10-14). Criterion 1 delegated to doc-writer.
- 2026-10-28 doc-writer: criterion 1 done. M9 step 7 rewritten: untick "Require approvals" if ticked (decided, Ludwig 2026-10-28, mission log "Ludwig, 2026-10-28 (verbatim)", verified present at line 2655 of the session-13 mission log); placement (directly under the tick box, indented, number list showing 1) marked [unverified]; "page looks different (e.g. Rulesets) -> stop and tell the manager" added to step 7 (it was not in the step before); reason sentence kept; the old "stop and tell the manager" on approvals and the "change nothing if no number is shown" duplicate were folded in. No verify script run.
- 2026-10-28 doc-writer: criterion 3 evidence (before commit, working-tree diff of the runbook; M9 heading at the line and M10 heading at the line below): 303:## ☐ M9 — Make `gate` a required;362:## ☐ M10 — The membership-read A; runbook hunks: @@ -322,3 +322,7 @@ pull request yourself. @@ -326,2 +330 @@ pull request yourself. . Name-only diff is pasted in the next entry after commit.
- 2026-10-28 doc-writer: criterion 3 evidence, after commit. `git diff --name-only origin/main...HEAD` = docs/manager/OPERATIONS.md, docs/runbooks/site-v1-manual-steps.md, docs/tasks/095-runbook-ops-session13.md. `git diff -U0 origin/main...HEAD -- docs/runbooks/site-v1-manual-steps.md | grep '^@@'` = `@@ -322,3 +322,7 @@` and `@@ -326,2 +330 @@`. M9 heading is line 303, M10 heading is line 362, so both hunks (new lines 322-335) are inside M9.
- 2026-10-28 manager (session 13): independent review PASS-WITH-AMENDMENTS (2 MEDIUM, both in the manager's OPERATIONS text: an uncited `versions` detail -> now cites the PR #26 probe file; "Not a defect" -> "observation, not yet classified"; MINOR: "decided" -> "Ludwig's choice A", overlong runbook line split, "number list" -> "box or drop-down", (a) and (b) toned to the log, (d) no reconstructed separators, citations added to (b)-(d)). Applied verbatim from the reviewer's proposed text by the manager (mechanical). Status: done; PR next.
