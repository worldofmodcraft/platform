# Task 096: runbook — mark M9, M10 and M11 done; correct M9 step 2's sidebar path

- **Mission:** SITE-V1 — **Status:** spec-approved (manager, solo gate, 2026-10-28; the 085 shape)
- **Repo:** platform. **Agent / model:** qa-engineer (§3.5). **Budget:** small (≤ 1 agent-session, in two phases)
- **Branch / worktree:** `task/096-runbook-m9-m11-done` / `~/wt/task-096`, cut from platform `origin/main` `3562c8f`

## Source (all in the mission log, session 13, 2026-10-28; quote from there)
- M9: Ludwig "Klart för M9 med gate"; manager's API read of `branches/main/protection` (required `gate`, strict, PR required, 0 approvals,
  enforce_admins false); L4 (registry PR #26 `BLOCKED` after update-branch, closed unmerged).
- M9 step 2: Ludwig "\"Code planning and automation\" finns inte i sidebaren"; the manager gave him the direct URL
  `https://github.com/worldofmodcraft/registry/settings/branches`; which route Ludwig took is `[unverified]` (his reply "Klart för M9 med gate" does not say). Fix round 1, F1.
- M10: Ludwig "M10 klar, appen heter worldofmodcraft-membership"; secret names listed; live check registry PR #28 `MEMBERSHIP_STATUS: 204`.
- M11: Ludwig "M11 done …"; manager's API read of both environments (`branch:main` policy, one secret each, timestamps) and of the repository
  secrets (only the two `REGISTRY_MEMBERSHIP_…` left); the `.pem` is a pipeline-App key from 2026-10-27 (Ludwig's file name).

## Objective
`docs/runbooks/site-v1-manual-steps.md`: M9, M10, M11 headings ☐ -> ☑, each with a **Status: done (Ludwig, 2026-10-28).** paragraph in the
085 shape (what was done, on whose word, what the manager verified and how, what stays unverified). M9 step 2 gives the direct URL first and
says the sidebar heading varies (`[unverified]` naming; Ludwig did not see "Code, planning, and automation"). M11's status records the open
hygiene item (delete the pipeline App's unused keys after 008b-3b's first live run) and that the minisign offline backup (Q-H) is unconfirmed.
Nothing else in the runbook changes.

## Acceptance criteria
1. Content as in Objective; every claim cites its source above; nothing outside M9, M10, M11 changes (`git diff -U0` hunks inside those three
   sections only).
2. **Phase 2 (only when the manager releases the machine):** `068-verify.sh` and `085-verify.sh` (pinned) exit 0 on the branch; if any
   marker check reads HEAD and reddens on these flips, re-pin it red-first as in 085 (and add that script to File scope in the log, stop and
   report first). `096-verify.sh` (new): scope check (merge-base with origin/main, absent = FAIL), the three headings ☑ at the branch FINAL
   pinned SHA, the step-2 URL present; runs in a fresh GitHub clone; output pasted.
3. **Phase 1 (now):** no `*-verify.sh` is run (task 089b's multi-hour chain owns the machine; its quiet-wait counts verify processes).

## File scope
`docs/runbooks/site-v1-manual-steps.md` (M9, M10, M11 only), `docs/tasks/096-runbook-m9-m11-done.md` (log), `docs/tasks/096-verify.sh` (new).

---
# Task 096 log  (append-only)
- 2026-10-28 manager (session 13): written from the mission log's session 13 entries; phase 1 dispatched.
- 2026-10-28 qa-engineer: phase 1 done (no `*-verify.sh` run, per criterion 3; `bash -n` only). Content commit = `60a7ef6459eb92fbe201f1ec2fda5893c4d3c212`
  (base = platform `origin/main` `3562c8f`). M9, M10, M11 headings flipped ☐ -> ☑, each with a "Status: done (Ludwig, 2026-10-28)." paragraph
  quoting the mission log (session 13); M9 step 2 now gives `https://github.com/worldofmodcraft/registry/settings/branches` first and marks the
  sidebar heading naming `[unverified]`; M11 records the pipeline-App key hygiene item and Q-H backup unconfirmed. `096-verify.sh` written,
  executable, `PIN_FINAL="PENDING"` (fails until pinned in phase 2).
  `git diff --name-only origin/main...HEAD` (at the content commit):
  ```
  docs/runbooks/site-v1-manual-steps.md
  docs/tasks/096-runbook-m9-m11-done.md
  docs/tasks/096-verify.sh
  ```
  `git diff -U0 origin/main...HEAD -- docs/runbooks/site-v1-manual-steps.md | grep '^@@'` (hunk counts only):
  ```
  @@ -303 +303 @@   @@ -307,0 +308,7 @@   @@ -313 +320,5 @@   @@ -363 +374 @@   @@ -370,0 +382,7 @@   @@ -406 +424 @@   @@ -413,0 +432,11 @@
  ```
  Headings now: M9 line 303, M10 line 374, M11 line 424, R11 line 481 (R11 was 452 in the base; all hunks lie in base lines 303-413, i.e. M9-M11).
  Out-of-scope observation: the other `## ` headings are untouched; no marker check in 068/085-verify.sh mentions M9-M11 (grep), so a re-pin is not
  expected, but that is unproven until they run.
  **Phase 2 remaining** (only when the manager releases the machine; from `~/wt/task-096`, foreground, one at a time):
  1. `PYTHONDONTWRITEBYTECODE=1 bash docs/tasks/068-verify.sh` (expect exit 0)
  2. `PYTHONDONTWRITEBYTECODE=1 bash docs/tasks/085-verify.sh` (expect exit 0; if a marker check reddens on these flips, stop and report before re-pinning)
  3. set `PIN_FINAL` in `docs/tasks/096-verify.sh` to the final content commit (`git rev-parse HEAD` of the commit before the pin commit; here `60a7ef6`
     unless the runbook changes again), commit, `git push origin task/096-runbook-m9-m11-done`
  4. `PYTHONDONTWRITEBYTECODE=1 bash docs/tasks/096-verify.sh` (fresh clone of origin; needs the branch pushed); paste the output in this log
  5. mutation checks for 096-verify (throw-away clones under $TMPDIR): range widened, unreachable pin -> exit non-zero, a runbook hunk outside M9-M11 -> red.
- 2026-10-28 qa-engineer: fix round 1 (static review PASS-WITH-AMENDMENTS). Still PHASE 1: no `*-verify.sh` run, `bash -n` only (the check
  functions were exercised in isolation on temp copies, not the script). Finding -> commit:
  - F1 (MED) -> `5be2a0c`: runbook M9 step 2 now says "the manager gave Ludwig this direct URL on 2026-10-28; which route Ludwig then took is
    `[unverified]`" (the mission log shows only that the manager gave the URL; his reply "Klart för M9 med gate" names no route). The Source line
    of this file is corrected the same way.
  - F2, F3 (MED, LOW-MED) -> `3b2cb89` (mutation fixtures FIRST, MANAGER.md §2c rule 5) then `354b3cb` (tightened). `3b2cb89` refactors the two
    checks into functions of a file and adds a "== mutation" section: a temp copy with the step-2 sentence "which route Ludwig then took is
    `[unverified]`" removed, and one with M11's "**Still unconfirmed:** ... (Q-H) ..." sentence removed; each expects the check RED. At `3b2cb89`
    the OLD checks pass both mutations (the gap; shown in isolation: both exit 0), so a phase-2 run of `3b2cb89` would print two `GAP:` FAILs.
    `354b3cb` restricts the step-2 check to the text from `^2\. ` to `^3\. ` inside M9 and requires the exact new sentence (the step also carries a
    second `[unverified]`, so a bare token grep would still be too loose); the M11 check reads only the `**Status: done` paragraph (to its first
    blank line) and requires the exact sentence. Isolated result at `354b3cb`: unmutated runbook step2=0 m11=0; step-2 mutation -> step2=1;
    M11 mutation -> m11=1 (red where required).
  - PIN_FINAL re-pinned to `354b3cb00656ee979d890ed06decbc5c9500fbec` (the content commit; the next commit only records the pin and this log).
  - F4 (MED) expectation recorded, no re-pin expected: `068-verify.sh` reads the runbook only as the blob at its pinned FINAL (header lines 5-8;
    `git show "$FINAL:$RBPATH"` at line 20; only the secret scan is live, on the working-tree file); `085-verify.sh` reads the runbook blob at
    `PIN_FINAL` into `PINRB` (lines 78-81) and every marker check at lines 82-99 reads `PINRB` or `RED_SHA`, never HEAD (its HEAD uses at lines 36,
    57, 101-103, 116, 122-124 are throw-away clones and the live 068 guard). So the M9-M11 flips should not redden either. ANY redden = STOP and report to
    the manager before touching anything; do not re-pin.
  - F5 (LOW) note: after this branch merges, `git diff --name-only origin/main...HEAD` (the pre-merge range check) is EMPTY by construction
    (merge-base becomes the tip). Do not read an empty result on a post-merge rerun as a defect or as passing; `096-verify.sh` uses the pinned
    BASE..PIN_FINAL range and reports an empty range as FAIL "vacuous", which is meant for pre-merge use.
  **Phase 2 list (revised; machine released by the manager only; from `~/wt/task-096`, foreground, one at a time):**
  1. `PYTHONDONTWRITEBYTECODE=1 bash docs/tasks/068-verify.sh`; PASTE the actual exit code (expect 0). Any non-zero: stop and report.
  2. `PYTHONDONTWRITEBYTECODE=1 bash docs/tasks/085-verify.sh`; PASTE the actual exit code (expect 0). Any non-zero: stop and report, no re-pin.
  3. PIN_FINAL is already set (`354b3cb`); push is done in fix round 1. Do not re-pin unless the runbook changes again.
  4. Show the gap: check out `3b2cb89` in a throw-away clone, run its `096-verify.sh` (expect the two `GAP:` FAILs), paste; then
     `PYTHONDONTWRITEBYTECODE=1 bash docs/tasks/096-verify.sh` at the branch tip (fresh clone of origin; expect ALL CHECKS PASSED incl. the two
     mutation lines "red when ... removed"); paste the output and exit codes. Use pre-merge only (F5).
  5. mutation checks for 096-verify as before: range widened, unreachable pin -> exit non-zero, a runbook hunk outside M9-M11 -> red.
