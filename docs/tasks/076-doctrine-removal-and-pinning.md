# Task 076: doctrine — MANAGER.md §7 takedown wording per ADR-0122; REVIEW-CHECKLIST item on verify-script pinning

- **Mission:** SITE-V1 (doctrine housekeeping) — **Status:** spec-approved (manager, solo gate, 2026-10-25)
- **Repo:** platform. **Agent / model:** doc-writer (ROUTING.md). **Budget:** small (≤ 1 agent-session)
- **Branch / worktree:** `task/076-doctrine-removal-and-pinning` / `~/wt/task-076`, cut from platform `origin/main`
  (`0aac566` or later, which contains ADR-0122 Accepted)
- **Graph:** doctrine only; no component edges.
- **Merge:** Ludwig's written approval (doctrine, §7). Edits under `docs/manager/` may be refused by the auto-mode
  classifier; a refusal is an answer — stop and report, never work around it.

## Sources
- Ludwig, 2026-10-17, removal policy "Option A for all", item 7 (mission log, "Removal policy — brainstorm and Ludwig's
  decision"): correct MANAGER.md §7's "legal grounds only" and "the single in-place change".
- ADR-0122 (Accepted 2026-10-17): takedown grounds are legal grounds (ADR-0041) **or** known malicious code / illegal
  content as ADR-0046 defines them narrowly; owners cannot remove published versions (also enforced by registry
  `contracts/ownership.md` R11 since task 075, registry `4356583`).
- Ludwig, 2026-10-17, answer 3 ("Ok"): add to REVIEW-CHECKLIST — the task's verify script measures its own change on its
  pinned range and its live guards on HEAD, checked before merge, because the task becomes closed at merge.

## Objective
1. **MANAGER.md §7, the takedown paragraph** ("Takedowns are never merged on the manager's own authority"): replace the
   clause that calls a takedown "the single in-place change `contracts/append-only.rules.md` permits, mandated by
   ADR-0041 for legal grounds only" with wording that (a) names the grounds per ADR-0122 (legal grounds per ADR-0041, or
   known malicious code / illegal content as ADR-0046 defines them narrowly), (b) describes the takedown as one of the
   in-place mutations `append-only.rules.md` permits — verify the exact list in the registry's
   `contracts/append-only.rules.md` ("The permitted in-place mutations"; ADR-0121 added the pipeline write-back) and
   phrase it accurately rather than guessing, (c) says owners cannot remove a published version (ADR-0041:15,
   ADR-0122 item 0, enforced by `ownership.md` R11). The rest of the paragraph (the `womcraft` account problem, Ludwig's
   written approval per takedown PR, the absolute stop condition, the phase-3 replacement) stays unchanged in meaning.
2. **Other doctrine mentions:** grep `docs/manager/` and `CLAUDE.md` for "legal grounds only", "single in-place change"
   and equivalents; fix any in `docs/manager/` the same way. `CLAUDE.md` is out of scope: list any hit there as a
   Question, do not edit it.
3. **REVIEW-CHECKLIST.md:** add item 12, matching the existing items' style, approximately: "**Verify-script pinning
   (closed at merge):** the task's `NNN-verify.sh` measures the task's *own* change (file scope, red-commit ancestry,
   own-file diffs) on a fixed commit range recorded in the script — never `HEAD` or `origin/main` — and its *live*
   guards (tests green, other closed scripts green) on `HEAD`. Checked before merge, because the task becomes a closed
   task at merge and a moving frame then reddens it the first time a later task touches the same files (OPERATIONS.md,
   'What session 10 paid for')." Cite the source (Ludwig, 2026-10-17) the way the file cites others, if it does.

## Acceptance criteria — `docs/tasks/076-verify.sh`, whose output the log pastes
1. MANAGER.md §7 no longer contains "legal grounds only" nor "the single in-place change"; it names ADR-0122 and
   ADR-0046; it still contains "Ludwig's explicit written approval" (or the paragraph's existing equivalent) and the
   absolute-stop sentence unchanged.
2. REVIEW-CHECKLIST.md has item 12 containing "fixed commit range" (or the final wording's equivalent key phrase) and
   "HEAD"; items 1-11 unchanged (diff shows only an addition).
3. `git diff --stat origin/main...HEAD` lists only the files in File scope.
4. Every existing `docs/tasks/*-verify.sh` that reads `docs/manager/` (grep for it) exits 0, run one at a time from the
   worktree root; exit codes in the log. Own-change checks in 076-verify.sh use fixed SHAs (the new item 12 applied to
   itself).

## File scope
`docs/manager/MANAGER.md` (§7 paragraph, plus any same-wording hit from Objective 2 inside `docs/manager/`),
`docs/manager/REVIEW-CHECKLIST.md`, `docs/tasks/076-doctrine-removal-and-pinning.md` (log), `docs/tasks/076-verify.sh`.

## Forbidden
Changing the meaning of anything else in MANAGER.md (merge authority, stop conditions, waivers); editing CLAUDE.md or
ADRs; working around a refused edit.

---
# Task 076 log
- 2026-10-25 manager (session 11): written and approved (solo gate). Booked since 2026-10-17; waited for ADR-0122's
  acceptance, which landed today (platform `0aac566`).
- 2026-10-25 doc-writer: implemented. Content commit a2419ba (MANAGER.md §7 takedown paragraph; REVIEW-CHECKLIST item 12); no edit under docs/manager/ was refused.
  - §7 now: T2 is "one of the three in-place mutations append-only.rules.md permits" (T1 pending->published, T3 pending->rejected, per the registry's "The permitted in-place mutations"); grounds per ADR-0122 (ADR-0041 legal, or ADR-0046 malicious code / illegal content, narrowly); owners cannot remove a published version (ADR-0041, ADR-0122 item 0, ownership.md R11). Rest unchanged.
  - Objective 2: grep of docs/manager/ and CLAUDE.md for "legal grounds only" / "single in-place" found only the MANAGER.md §7 hit (fixed). CLAUDE.md: no hit.
  - 076-verify.sh output (AC1-AC3 all PASS; AC4 FAIL):
```
AC1
  PASS section 7 takedown paragraph located
  PASS no 'legal grounds only'
  PASS no 'single in-place change'
  PASS names ADR-0122
  PASS names ADR-0046
  PASS names ownership.md R11
  PASS written approval kept
  PASS absolute-stop sentence kept
AC2
  PASS item 12 has 'fixed commit range'
  PASS item 12 has HEAD
  PASS checklist diff has no removed lines
  PASS checklist diff adds exactly one line
AC3
  PASS BASE..HEAD touches only File scope 
AC4 (live guards on HEAD)
  FAIL docs/tasks/048-verify.sh exit 1
  PASS docs/tasks/049-verify.sh exit 0
  FAIL docs/tasks/051-verify.sh exit 1
  PASS docs/tasks/052-verify.sh exit 0
  FAIL docs/tasks/063-verify.sh exit 1
076 verify: 3 FAIL
```
  - AC4 is NOT met, and is not met for a reason outside this task: 048, 051 and 063 are already red on unchanged origin/main 0aac566 (checked in a detached worktree: 048 c1 "CLAUDE.md rule 0 block differs from base"; 063 AC1/AC2/AC4 measure their own change against a moving base; 051 AC4 "secret-shaped string committed" via docs/tasks/056-verify.sh). Also, with this change: 048 c1 flags 2 changed lines in MANAGER.md and 063 AC1 flags a hunk outside its bullet - the moving-frame defect item 12 describes. 049 and 052 exit 0. No script was edited or weakened. See Questions.
  - Questions for the manager/Ludwig: (1) AC4 as written cannot be met; repair 048/051/063 (pin their frames) in a separate task, or accept AC4 as "no new failure class beyond the moving frame"? (2) 051's secret-shaped-string failure points at 056-verify.sh and may be a real finding; needs a look.
- 2026-10-25 doc-writer (after task 078, main 80048281): merged origin/main into the branch (merge 8c5614e; add/add conflict on this file resolved by keeping the branch copy, which is the spec plus log). Stale tools/**/__pycache__ removed. All scripts run one at a time, foreground, from the worktree root, PYTHONDONTWRITEBYTECODE=1: 048, 049, 051, 052, 053, 056, 059, 061, 063, 068, 078 all exit 0. 076-verify.sh first exited 1 for two reasons of its own: (a) AC3 diffed BASE..HEAD, which after the merge includes 078's files - repinned to the fixed own-commit range BASE..11c091c (item 12 applied to itself); (b) 051 leaves __pycache__ that reddens 049 - the script now clears tools/**/__pycache__ before each live guard. Re-run: exit 0, AC1-AC4 PASS. This supersedes the AC4 FAIL and the Questions above (Q1 answered by manager: AC4 stands; Q2 was planted header text in 056-verify.sh, fixed by 078).
