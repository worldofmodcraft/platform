# Task 105: ADR tooling tests derive the real-corpus counts instead of pinning 119 / 116

- **Mission:** none (CI repair) — **Status:** spec-approved 2026-11-03 (manager, session 14; small, solo §2b; blocks task 104 / ADR-0123's merge)
- **Agent / model:** qa-engineer (tests are qa-owned) — **Budget:** small
- **Branch / worktree:** `task/105-adr-test-derived-counts` / `~/wt/task-105` (platform)

## Objective
Platform main's "ADR index" CI has failed on every run since 2026-09-02: `tests/adr/test_build_index.py::RealRepoTests.test_real_corpus_has_119_adrs_and_is_clean`
asserts exactly 119 ADRs (main has 122; task 104 adds the 123rd). `test_real_corpus_touches_coverage_matches_task_004_input` asserts exactly 116 untagged ADRs and
passes only by coincidence. Both are time-bound snapshots of task 003's corpus. Make them derive the expected numbers independently of `build_index`: the count of
`docs/decisions/[0-9][0-9][0-9][0-9]-*.md` files, and the count of those files without a `- **Touches:**` header line (read with plain Python, not via `bi`).
Keep every other assertion (clean, no fatal/completeness/amend issues, `ok`); keep `test_real_lookup_registry_...` unchanged. Rename the first test to drop "119".
No change to `tools/adr/build_index.py` or any ADR.

## Acceptance criteria
1. Red first: on platform main the unittest file fails `test_real_corpus_has_119_adrs_and_is_clean` (`AssertionError: 122 != 119`) — paste it.
2. After the change: `python3 -m unittest discover -s tests/adr` passes on this branch, and also with ADR-0123 added (merge `origin/task/104-accept-adr-0123` into a
   throw-away clone of this branch and run it there; paste).
3. The new counts are derived independently: a temp copy of the corpus with one extra synthetic ADR file still passes (counts follow), and a corpus whose INDEX
   analysis is made to miss a file (e.g. a file the derived glob sees but `bi` does not) fails.
4. Scope: `tests/adr/test_build_index.py` and this file only.

---
# Task 105 log
- 2026-11-03 manager (session 14): created; main's ADR index CI red since 2026-09-02 (runs 69395ca success, cf38587 onward failure).
