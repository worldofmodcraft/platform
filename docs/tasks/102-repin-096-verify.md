# Task 102: re-pin `096-verify.sh` so it stays green on platform main after its merge

- **Mission:** SITE-V1 (verification integrity) — **Status:** spec-approved 2026-10-29 (manager, session 14; Ludwig's decision "A: fixed SHAs only", 2026-10-29)
- **Agent / model:** qa-engineer — **Budget:** small
- **Branch / worktree:** `task/102-repin-096-verify` / `~/wt/task-102`, from platform main

## Objective
`docs/tasks/096-verify.sh` was written for pre-merge use (its own F5 note): its range check is empty after merge and FAILs "vacuous". Re-pin every own-change
check to 096's merged range (merge `885e1f0`, platform PR #94; BASE = merge-base of M^1 M^2, FINAL = M^2 — re-derive as full SHAs and record) so it is green on
main and after any later commit. Reference: task 090 (`docs/tasks/090-verify.sh` on main, AC7: fixed FINAL..PIN_TIP) and registry task 089e.

## File scope
`docs/tasks/096-verify.sh` (range/scope checks and pins only), `docs/tasks/102-verify.sh` (new), this file. Anything else = stop.

## Acceptance criteria (in `102-verify.sh`, which itself uses fixed SHAs only)
1. Red first: the unfixed 096-verify.sh (blob at M) FAILs on platform main and on a later synthetic commit; the fixed one passes both.
2. Pins re-derived and asserted. 3. `deadbee` pin FAILs, never skips. 4. Its existing mutation checks still redden. 5. Item-12: fixed 096-verify.sh exits 0 on
main and on main + a later commit touching the runbook outside M9-M11. 6. Quiet machine. 7. Scope = the three files; other 096 checks byte-identical.

---
# Task 102 log
- 2026-10-29 manager (session 14): created on Ludwig's decision A; dispatched write-only first (machine held by task 101).
