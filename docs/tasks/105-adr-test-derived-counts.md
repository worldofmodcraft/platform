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
- 2026-11-03 qa-engineer: executed (unit tests only; no *-verify.sh run).
  - Criterion 1, red first (base ac8e1d7, 122 ADRs): `python3 -B -m unittest discover -s tests/adr` ->
    `File ".../test_build_index.py", line 500, in test_real_corpus_has_119_adrs_and_is_clean` / `self.assertEqual(result.scanned_count, 119)` /
    `AssertionError: 122 != 119` / `Ran 32 tests in 0.052s` / `FAILED (failures=1)`.
  - Change (tests/adr/test_build_index.py only): helpers `_derive_expected` (glob `[0-9][0-9][0-9][0-9]-*.md`; untagged = no line starting `- **Touches:**`, plain Python, no `bi`),
    `_check_clean_counts`, `_check_touches_counts`. Tests renamed `test_real_corpus_counts_match_files_and_is_clean` and
    `test_real_corpus_touches_coverage_matches_files_without_touches_header`. All other assertions kept; lookup-registry test unchanged.
  - Criterion 2: this branch (122 ADRs): `Ran 32 tests in 0.069s` / `OK`. Throw-away clone with `task/104-accept-adr-0123` merged (123 ADR files): `Ran 32 tests in 0.098s` / `OK`.
  - Criterion 3 (temp corpus copies, helpers called against them): baseline copy clean PASS, touches PASS. Copy + one valid synthetic ADR 0950 (no Touches) with README row:
    derived (123, 117), clean PASS, touches PASS (counts follow). Synthetic ADR without README row: clean FAIL (`README.md index is missing a row for ADR-0950`), i.e. completeness check still bites.
    Copy + `0951-Bad_Name.md` (glob sees it, bi skips it as fatal): clean FAIL `122 != 123`; touches PASS (expected: the copy of 0119 carries a Touches line, so it adds no untagged file on either side).
  - Scope: tests/adr/test_build_index.py and this file only.
