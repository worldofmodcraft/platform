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
- 2026-10-28 doc-writer: verified the decision in the mission log ("### Ludwig, 2026-10-27 ~15:00 (verbatim)": "1. Kör på stjärna", S5 = tick
  "Require a pull request before merging", leave "Do not allow bypassing" unticked). Edited M9 only: step 7 (decision + cited, costs kept as
  reason), step 8 (added (b) the open L3 PR, merge button must be blocked, live check L4), final "Emergency path" paragraph (now records the
  decision). New UI labels: none; "bypass option" for an administrator in step 8 is marked `[unverified]`; "merge button" is descriptive, not a
  quoted label. Sub-options of "Require a pull request before merging": "leave at defaults", none named. Criterion 5 (run after commit, below).
- 2026-10-28 doc-writer: criterion 5 commands and output (run on the committed branch):
  `git diff --name-only origin/main...HEAD` -> `docs/runbooks/site-v1-manual-steps.md`, `docs/tasks/093-runbook-m9-s5-choice.md`.
  `git diff -U0 origin/main...HEAD -- docs/runbooks/site-v1-manual-steps.md | grep '^@@'` -> hunks at old/new lines 322, 329->331, 332->336, 342->349;
  `grep -n '^## ☐ M9\|^## ☐ M10'` -> M9 starts line 303, M10 line 354; all hunks lie inside 303-353 (M9 only).
- 2026-10-28 doc-writer (fix round): F1-F5 done in M9 only. F1 step 7: sub-options now checked, stop-and-tell-manager if "Require approvals"/a number is shown, pre-tick and "no such account" marked `[unverified]`, one-sentence reason. F2 step 8(b): expected = ordinary merge button greyed/missing, `gate` failing and Required; administrator merge-anyway option (wording `[unverified]`) must NOT be clicked; clickable ordinary button = stop, M9 not done. F3: after L4, do not merge or close the L3 PR, tell manager "L4 blocked", manager closes it. F4: "administrator can merge past a red gate" marked `[unverified]` in step 7 and Emergency path. F5: step 8(a) wording changed (any open PR, L3/registry #26, none = tell manager); "You should see" mentions L3 blocked.
  Criterion 5 re-run on the committed branch: `git diff --name-only origin/main...HEAD` -> `docs/runbooks/site-v1-manual-steps.md`, `docs/tasks/093-runbook-m9-s5-choice.md`.
  `git diff -U0 origin/main...HEAD -- docs/runbooks/site-v1-manual-steps.md | grep '^@@'` -> new-side hunks start at lines 322, 335, 347, 354 (old 322, 329, 335, 342);
  `grep -n '^## ☐ M9\|^## ☐ M10'` -> M9 line 303, M10 line 359; all hunks inside 303-358 (M9 only).
