# Task 093: runbook M9 step 7 records Ludwig's S5 choice

- **Mission:** SITE-V1 (runbook hygiene) — **Status:** spec-approved 2026-10-28 (manager, solo: small doc-only task; SPEC-CHECKLIST items checked in session)
- **Agent / model:** doc-writer (model per its frontmatter) — **Budget:** small (1 agent-session)
- **Branch / worktree:** `task/093-runbook-m9-s5` / `~/wt/task-093` — **platform** repo

## Why
`docs/runbooks/site-v1-manual-steps.md` M9 step 7 still calls security review S5 an "open choice". Ludwig decided it on
2026-10-27 (mission log, "Ludwig, 2026-10-27 ~15:00 (verbatim): 1. Kör på stjärna", recorded as: **tick "Require a pull request
before merging"; leave "Do not allow bypassing the above settings" unticked** — emergency path kept). Ludwig is about to perform
M9, so the step must say exactly what to tick.

## Acceptance criteria (doc-only; checked by reading + the commands shown in the log)
1. M9 step 7 tells Ludwig to tick **Require a pull request before merging** (and to leave its sub-options at their defaults unless
   the step names one), and to leave **Do not allow bypassing the above settings** unticked; it cites the decision (date, mission log).
2. The "Open choice, Ludwig decides" wording and the "Tell the manager which way you chose" requests (step 7 and the final
   "Emergency path" paragraph) are replaced by the recorded decision; the costs paragraph stays as the reason.
3. Step 8 still names L1/L3's PR: add that the manager's open L3 pull request (invalid schema, `gate` red) is the one to look at, and
   that its merge button must be blocked (live check L4).
4. Every GitHub UI label written is either already in the runbook or marked `[unverified]` (MANAGER.md §3.6b).
5. `git diff --name-only origin/main...HEAD` = this task file + the runbook only; nothing outside M9 changes in the runbook
   (`git diff -U0` shows hunks only inside the M9 section).

## File scope
`docs/runbooks/site-v1-manual-steps.md` (M9 section only), `docs/tasks/093-runbook-m9-s5-choice.md` (log).

## Out of scope
Any other runbook step; M10/M11 text; the vault copy (refreshed by `tools/vault/refresh-main.sh` after merge).

---
# Task 093 log  (append-only)
- 2026-10-28 manager (session 13): drafted and spec-approved; booked follow-up from session 12's handover (item 6).
