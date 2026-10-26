# Closed-verify sweep inventory (task 088, 2026-10-26)

Read-only survey by a surveyor agent; registry read at origin/main `4268735`, platform at `3ca6fbf`. Recorded by the manager
from the surveyor's report. 34 closed scripts (18 registry + 16 platform). Own-change checks on a moving frame: 24 found;
3 fixed by registry #24 (087), 7 by platform #80 (085); **14 remain** for 089 (registry, 13) and 090 (platform, 1).

## Registry own-change findings (for task 089) — `file:line` — reads — task merge — pin
1. `007a-verify.sh:117` — README "tools/registry" AND "task 039", worktree — 007a `3c94cf2` — `e009ef0..aaf4260`. HIGH (time-bound).
2. `007a-verify.sh:118` — README lacks "task 007$"/"task 007 +builds", worktree — `3c94cf2` — `e009ef0..aaf4260`.
3. `007b-verify.sh:100` — README names "ownership" AND "task 039", worktree — 007b `70cedca` — `fb76ee5..17555d9`. HIGH.
4. `007b-verify.sh:101` — README "ownership checker (task 007b" not "still to come", worktree — `70cedca` — `fb76ee5..17555d9`.
5. `008a-verify.sh:74` — README mentions build-pipeline.md, worktree — 008a `a50daac` — `4d4a204..9ccb3ec`. LOW.
6. `057-textchecks.py:179-180` — README names "task 057" via default `--readme` (called from `057-verify.sh:35`) — 057 `e009ef0`
   — `a50daac..3ab8f43` (pass `--readme` from a `git show` blob). LOW.
7. `tests/registry/test_hardening.py:153` — README contains "--no-renames", worktree — 007a fix round `ed9cb67` / merge `3c94cf2`
   — read the blob at `aaf4260` or drop it (the CLI-help half at :152 stays live).
8. `065-verify.sh:208-218` (AC3.5) — `tests/registry/test_hardening.py` in the HEAD clone — 065 `208c6d1` — `4356583..e87498b`.
9. `075-verify.sh:100-135` (AC4) — `contracts/ownership.md` R11/R3/R7/Attempt 8-9 sentences in the HEAD clone — 075 `4356583` —
   `79d5377..7d91a3d`. HIGH (008b's ownership carve-out will edit them).
10. `039a-verify.sh:149-150` — `HEAD:config/r11-identity.json` must be null — 039a `4268735` — `4356583..ceb0458`. HIGH (reddens
    when Ludwig configures R11).
11. `tests/registry/test_ci_gate.py:1018-1021` (AC9ProductionR11Unconfigured) — `config/r11-identity.json` at worktree — as 10;
    blob at FINAL or move into 039a-verify.
12. `039a-verify.sh:111-148` — exact per-class test counts of `test_ci_gate.py` in the HEAD clone — `4268735` — `4356583..ceb0458`.
    MEDIUM (inference).
13. `tests/registry/test_classify.py:132-134` — `reserved-namespaces.json` names == {mc, test}, worktree — 007a `3c94cf2`. LOW.
Already fixed by registry #24 (087): `032-verify.sh` N5/N5b, `067-verify.sh` AC2.5. Suggested order: 1-3, 9, 10 first.

## Platform (task 090)
- P1 `068-verify.sh` runbook markers — fixed by #80 (085).
- P2 `048-verify.sh:90-98` (c4) — the `SUSPENDED by Ludwig 2026-10-14` marker in CLAUDE.md/MANAGER.md at HEAD (also anchored by
  `079-verify.sh:28-29`) — 048 `c323460` — `8a5f32d..047bc41`. Reddens the day Ludwig revokes the token-guard suspension; a
  manager decision whether to pin (078 classed c2-c7 as live).
- 078 classed 048 c3 (exactly 10 agents) and c6 (5b caps) as live; both are time-bound (roster or cap change reddens them).

## Side findings (not item-12, but defects to fix in 089/090)
- `070-verify.sh --mutate` AC4.m1 goes stale when #24 merges (087 is fixing it in scope).
- `069-verify.sh:204-209` reads `origin/task/064-schema-check-end-anchor`; when that branch is deleted AC5.3 prints "not
  evaluated" and does not fail — a **silent skip**.
- `057-verify.sh:30` reads local `main` of `/home/ludwig/wom` (hard-coded path, not origin/main) for ADR-0121's status.
- Platform `072-verify.sh:8-9` and `080-verify.sh:20-21` allow env overrides of their pins (078/085 forbid that).
- Platform `063` AC3 reads its task file by a fixed path (breaks if moved to `docs/tasks/done/`; Ludwig chose to keep files in
  place, so low risk).

## Live reads that correctly stay on HEAD (summary)
Suites and closed scripts green at HEAD; contract prose/schema text pinned on purpose (006, 032, 034, 057-textchecks, 065 AC5.1 —
changes go through 062's retire-with-successor process); two-files-agree checks; tool/CLI help and hygiene (no .pyc, no key,
modes); mutation-runner preconditions; platform behaviour tests (010a, 049, 052, 053, 061, 079 AC1/2); external-by-design
(010a, 056, 080, 072); stable doc-presence needles.
