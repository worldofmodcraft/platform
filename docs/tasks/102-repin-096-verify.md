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
- 2026-10-29 qa-engineer: PHASE 1 (write only; task 101 held the machine, so NO *-verify.sh was run, only `bash -n`).
  Commits: `33b725be` part 1 red first (102-verify.sh; PIN_FIX=PENDING so every fixed-script cell FAILs by design; the unfixed-blob cells are the
  red demonstration, to be shown in phase 2); `ac038b622c49f544b79afe617f857f670daf68c9` part 2 fix (096-verify.sh); pin-recording commit sets PIN_FIX=`ac038b622c49f544b79afe617f857f670daf68c9` in 102-verify.sh.
  Pins re-derived from the merge with `git rev-parse` / `git merge-base` (full SHAs): M `885e1f01d1f0ba63d705c87ceef9e949cbecab1e`;
  M^1 `5653515816fb5d028ad0a6d68aa1af944b2ac4b3`; M^2 = FINAL `b8970a3f194ff960c6fe68088fa53077749acc98` (= branch tip on origin);
  BASE = merge-base(M^1,M^2) = `3562c8f519a8f957d1c3b2649dc7f774105dbfd8`. Runbook blob is identical at the old pin 354b3cb and at M^2
  (`git diff 354b3cb M^2` touches only the 096 task file and 096-verify.sh), so own-change content assertions are unchanged in meaning.
  Fixture pin PIN_MAIN = `47c993870a364241b14ae0324f3d0dddd8fbe74d` (platform main at task start, contains M).
  096-verify.sh change, old -> new (everything else byte-identical; 102-verify.sh asserts the marker-check block and the whole own-change/mutation/secret tail are):
  - `PIN_FINAL=354b3cb` -> `PIN_MERGE`, `PIN_BASE`, `PIN_FINAL=M^2` (three fixed pins).
  - clone `--branch task/096-...` (branch may be deleted after merge) -> clone of the default branch; `BRANCH` variable removed.
  - pin block: PENDING/resolve/ancestor of the branch tip -> same for each of the three pins, plus PIN_FINAL == PIN_MERGE^2 and PIN_BASE ==
    merge-base(PIN_MERGE^1, PIN_MERGE^2) derived in the clone; ancestor check now against the cloned main tip. Unreachable pin: named FAIL, never skip.
  - scope: `BASE = merge-base origin/main PIN_FINAL` (empty after merge: "empty range (vacuous)") -> `BASE = PIN_BASE` (fixed); the vacuous-range FAIL,
    the three-file scope, runbook-changed and M9..M11 hunk assertions are kept as written. Header comment updated (F5 now resolved by this task).
  - Not changed: the optional LOW (stale label near line 80 of the 096 task file) is outside this task's file scope.
  102-verify.sh cells: quiet-machine ps check; pins reachable and re-derived; unfixed blob (== f0241ac at M) red on a main+096-branch origin and on main+later
  commit with reason "empty range (vacuous)"; fixed script exit 0 / ALL CHECKS PASSED / no FAIL lines on main, main+commit outside M9-M11 (runbook line 1 edit),
  main+commit inside M9 (no 096 branch present); pins carried exactly, no moving ref; deadbee on each of the three pins -> non-zero + named "unreachable" FAIL;
  wrong-but-reachable PIN_FINAL/PIN_BASE -> non-zero; 096's two mutation lines present, no GAP; SPEC..FIX scope = three files; unchanged sections byte-identical.
  Fixtures are local clones of the fresh clone (no network, no credentials, no env switch).
  **Phase 2 commands (machine released by the manager only; quiet; foreground, one at a time; nothing else running, check `ps -eo pid,etime,args | grep -E '[0-9]{3}[a-z]?-verify\.sh'` first):**
  1. `D=$(mktemp -d) && git clone https://github.com/worldofmodcraft/platform "$D/p" && cd "$D/p" && git checkout -q task/102-repin-096-verify && git rev-parse HEAD` (must be this branch's head; check `git status` is clean).
  2. Red first, from the same clone: `git stash` is not needed; show the red state by running the part-1 version: `git show 33b725be7f00ef0d95e1716c119935c6bad82e19:docs/tasks/102-verify.sh > "$D/102-red.sh"`, copy it to docs/tasks/102-verify.sh of a throw-away second clone checked out at 33b725be, run it: expect the unfixed-blob cells ok and exit 1 with "PIN_FIX not recorded". Paste.
  3. `PYTHONDONTWRITEBYTECODE=1 bash docs/tasks/102-verify.sh; echo "exit=$?"` at the branch head: expect "102-verify: ALL CHECKS PASSED", exit 0. Paste whole output.
  4. `PYTHONDONTWRITEBYTECODE=1 bash docs/tasks/096-verify.sh; echo "exit=$?"` at the branch head (this is the real GitHub main clone): expect ALL CHECKS PASSED incl. both "red when ... removed" lines, exit 0. Paste.
  5. Item-12 on real main plus a later commit: covered by the f-out and f-in cells of step 3 (local stand-ins for main + commit); if a literal run is wanted, in a clone: `git checkout -q 47c9938 && git commit --allow-empty -m x`, then run 096-verify.sh from the branch against that clone's path as origin (the cells do exactly this).
  6. Any red in step 3 or 4: stop, report file:line, expected vs actual; do not edit a test or pin to pass.
