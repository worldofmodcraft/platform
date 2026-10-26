# Task 085: runbook — mark M6 (personal account joins the organisation) done

- **Mission:** SITE-V1 — **Status:** spec-approved (manager, solo gate, 2026-10-26; the 071/084 shape)
- **Repo:** platform. **Agent / model:** qa-engineer (§3.5). **Budget:** small (≤ 1 agent-session)
- **Branch / worktree:** `task/085-runbook-m6` / `~/wt/task-085`, cut from platform `origin/main`

## Source
Ludwig, 2026-10-26: "Ja det är klart" (invited `mbmludric` from the owner account and joined the organisation), and his
screenshot of Organisation → Settings → Member privileges showing **Base permissions: Read**.

## Objective
`docs/runbooks/site-v1-manual-steps.md`: M6's heading ☐ → ☑ and its status sentence records what was done, on whose word,
and the Base permissions value. Nothing else in the runbook changes (068-verify pins the other markers).

## Acceptance criteria
1. Evidence: Ludwig's word (membership); the manager's unauthenticated check of public members returned HTTP 403 (rate
   limit), so membership is **not externally verified** — recorded as such. Base permissions = Read (Ludwig's screenshot).
2. **Re-pin first (red first):** `068-verify.sh`'s marker checks (e.g. line ~21 "M6 heading stays ☐", and every other
   heading-state check) read the runbook at HEAD — own-change checks on a moving frame (REVIEW-CHECKLIST item 12). Pin them to
   068's merged PR range (068 merged as platform PR #58: BASE = `git merge-base M^1 M^2`, FINAL = `M^2`, M found with
   `git log --merges --grep`), the 071/084 pattern; classify every check own-change vs live in the log. Show the old script red
   on a throw-away commit that flips M6, then green after the re-pin. Mutations: range widened to HEAD → red; unreachable pins
   fail, never skip.
3. Then flip M6 ☐ → ☑ with the status sentence above; every `docs/tasks/*-verify.sh` exits 0, one at a time, foreground,
   `PYTHONDONTWRITEBYTECODE=1`; `085-verify.sh` own-change checks on fixed SHAs; passes in a fresh clone.

## File scope
`docs/tasks/068-verify.sh` (marker checks only), `docs/runbooks/site-v1-manual-steps.md` (M6 heading + status only),
`docs/tasks/085-runbook-m6-done.md` (log), `docs/tasks/085-verify.sh` (new).

---
# Task 085 log
- 2026-10-26 manager: written from Ludwig's report.
- 2026-10-26 qa-engineer (task 085, `task/085-runbook-m6`): done, PR pending merge. Content commit (FINAL) = `eb59f89`, base = platform
  `origin/main` `3ca6fbf`. Pinned range for the 085 own-change scope check: `3ca6fbf..eb59f89`.
  - **Red first:** on a throw-away commit flipping M6 (cut from `3ca6fbf`), the OLD `068-verify.sh` exits 1 (`FAIL  M6 heading stays ☐`);
    the re-pinned one exits 0 on the same commit (also `--mutate` exit 0). Shown by `085-verify.sh` section "AC2".
  - **068 pins (item 12):** M = `9b86898` "Merge pull request #58 from worldofmodcraft/task/068-runbook-markers" (found with
    `git log --merges --grep=068`); BASE = `git merge-base M^1 M^2` = `3f25f0344071803916dc52801fddb78a126cd695`,
    FINAL = `M^2` = `6d4b61e48ef54970dcda0451aa36599f7509f11e`. Both resolve; unreachable pin exits 2 (never skips).
  - **Classification of every 068 check:** OWN-CHANGE (read the runbook blob at FINAL): M3/M5/M7/Q-H heading is ☑ (4), M3/M5/M7/Q-H
    evidence note (4), M4 stays ☐, M6 stays ☐ (these record what 068 left open), M5 and M7 no "not done"/"returns 404" (2),
    "Last reviewed 2026-10-15 (task 068)" (1); plus a new positive control "pinned range changes the runbook" (an empty range would
    make all of them vacuous). LIVE (current working-tree runbook): "no secret-looking value" only (a property that must hold on any
    version). The old `RUNBOOK` env override was removed (no env override on pins); the `--mutate` mode now mutates the pinned blob,
    and the secret mutation mutates the live file.
  - **Mutations (085-verify.sh, throw-away clones):** range widened (FINAL := later HEAD) -> exit 1, red for `M6 heading stays`;
    unreachable BASE -> exit 2; unreachable FINAL -> exit 2; planted secret-shaped line in the live runbook -> red for the live check;
    a later branch that also flips M4 and moves "Last reviewed" -> re-pinned 068 still green. 068's own `--mutate`: 12 mutations red.
  - **Flip:** `site-v1-manual-steps.md` M6 `☐` -> `☑`; status = "done (Ludwig, 2026-10-26)", Ludwig's word for membership, **not
    externally verified** (manager's unauthenticated public-members check returned HTTP 403, rate limit), Base permissions = **Read**
    (Ludwig's screenshot). Everything else in the runbook is byte-identical to `3ca6fbf` (checked by `085-verify.sh`).
  - **Every `docs/tasks/*-verify.sh`, one at a time, foreground, `PYTHONDONTWRITEBYTECODE=1`, from the worktree root, stale `__pycache__`
    cleared first, on the content commit:** 010a, 048, 049, 051, 052, 053, 056, 059, 061, 063, 068, 072, 078, 079, 080 all exit 0;
    076 exited 124 under my 280 s guard-timeout (it runs 049/051/052/063/072/078/079 internally) and exit 0 when re-run alone with a 580 s
    guard. Machine was NOT quiet: `ps` showed other agents' `039a/064/069/007a-verify.sh` running from other worktrees (not this tree).
  - **Found, out of scope, not changed:** `OPERATIONS.md` still documents `mbmludric` as a non-member (the M6 old status cited it); with
    Ludwig's report that statement is now stale, and the M4/M6 "When" ordering text is unchanged. Booked for the manager: update OPERATIONS.md
    (separate task) once membership is verified authenticated.
