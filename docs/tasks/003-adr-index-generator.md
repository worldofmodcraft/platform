# Task 003: Generate docs/decisions/INDEX.json and make the log's invariants mechanical

- **Mission:** SITE-V1 (prerequisite — unblocks the spec gate) — **Status:** spec-approved
- **Agent / model:** implementer / sonnet  (escalation: implementer-strong, two-strike rule only)
- **Budget:** medium (≤ 3 agent-sessions)
- **Branch / worktree:** task/003-adr-index-generator / ../wt/task-003 (based on task/005)
- **Graph:** no SITE-V1 node — this is repo infrastructure that the spec gate depends on.

## Objective
`docs/decisions/INDEX.json` exists, is generated from the ADR headers rather than hand-written,
and a `--check` mode fails when it disagrees with the files — so the index can never quietly go
stale. Three invariants that are currently verified by a human reading carefully become commands
that fail loudly instead. After this task, SPEC-CHECKLIST item 4 ("the INDEX.json lookup was
performed") and REVIEW-CHECKLIST item 4 (diff paths vs the index) are satisfiable for the first
time; today they are not, which strictly blocks approving any task spec.

## Context to load (exhaustive)
- ADRs: **0116** (this is layer 4, and layer 1's "every ADR that *can* become a gate *becomes*
  one" is the point of the check mode), **0113** (a generator that refuses rather than lies),
  **0103** (boring and restartable), **0115** §1 (counters must read reality), **0056** (English)
- Files: `docs/decisions/README.md` — the amend protocol and index format are specified there;
  `docs/decisions/TEMPLATE.md`; `docs/manager/SPEC-CHECKLIST.md` item 4;
  `docs/manager/REVIEW-CHECKLIST.md` item 4; `docs/tasks/001-adr-index-completeness.md` and
  `005-decisions-metadata-and-reserved-namespaces.md` (the two audits this task mechanises)
- Survey docs: none needed.

## File scope (declared)
- `tools/adr/build_index.py` (or `.mjs`; pick one runtime, state why in the log)
- `docs/decisions/INDEX.json` (generated output, committed)
- `tests/adr/**`
- `.github/workflows/adr-index.yml`
- `docs/tools/adr-index.md`
- `docs/tasks/003-adr-index-generator.md` (this file's log section)
Anything else — **including the body of any ADR** — is out of scope: stop and report.

## Acceptance criteria
Each demonstrated by a command whose real output goes in the log.

1. **Generation.** `build_index --write` produces `docs/decisions/INDEX.json` containing, per ADR:
   number, filename, title, status, date, area, `touches` (list, empty when the header lacks the
   line), `related`, `amends`, `amended_by`. Valid JSON; 119 entries.
2. **Check mode is a gate.** `build_index --check` exits 0 when the committed INDEX.json matches
   the files, and non-zero with a diff naming the offending ADR when it does not. Demonstrated
   both ways: run it clean, then edit one ADR title in the worktree, re-run, show the failure,
   revert.
3. **Index completeness invariant** (mechanises task 001): every `docs/decisions/NNNN-*.md`
   appears in `README.md`'s index exactly once; no dangling rows; every index link target exists.
   Fails non-zero with the specific numbers when violated. Demonstrated by temporarily deleting a
   README row and showing the failure.
4. **Amend-protocol invariant** (mechanises task 005): if ADR X's header lists `Amends: Y`, then
   Y's header must list `Amended by: X`, and vice versa. Any one-directional reference fails with
   both filenames named. Demonstrated by temporarily removing one back-reference.
5. **Touches coverage is reported, not silently tolerated.** The tool prints how many ADRs lack a
   `Touches:` line and lists them. On today's tree that is **116 of 119** — the input to task 004.
   This is a report, not a failure: `--check` must still pass, or the gate cannot be adopted until
   tagging is finished.
6. **A real lookup works end to end.** Show the ADR-0116 §4 worked example: given a task touching
   `registry`, the tool returns the matching ADR numbers from INDEX.json. Command + output in the log.
7. **Determinism.** Two consecutive `--write` runs produce byte-identical output (stable key order,
   stable sort). Demonstrated by diffing two runs.
8. **Malformed headers fail loudly.** An ADR with a missing Status, an unparseable date, or a
   duplicate number is reported by filename and line — never skipped silently, never a traceback.
   Every skipped file is counted with its reason (ADR-0115 §1).

## Forbidden here
Beyond MANAGER.md §3.7:
- **Editing any ADR body or header.** This task reads the log and writes an index; adding the
  missing `Touches:` lines is task 004's job, deliberately separated so a generator bug cannot
  corrupt 116 decision records in one commit.
- Inventing `touches` values where the header has none — absent means an empty list, and empty is
  reported by criterion 5.
- Hand-editing `INDEX.json` (it is generated output; criterion 2 is what proves that).
- Making `--check` pass by relaxing an invariant when the repo violates it — a violation is a
  finding for the manager, exactly as MANAGER.md §3.5 says about tests.
- Parsing the ADRs with a regex that assumes every header field is present; the log has 119 files
  written by hand over several days and they are not uniform. Read defensively, report what you find.

## Deliverables
Generator + INDEX.json + tests + `docs/tools/adr-index.md` + the workflow file + log current.

**Known limitation to record honestly** (ADR-0115 §10): this repo has **no git remote yet**, so
`.github/workflows/adr-index.yml` cannot be demonstrated running in CI. Write it, verify the same
commands pass locally, and put an explicit TODO row in the log saying the workflow is built but
unproven until the repo is pushed. Do not claim CI works.

## Questions  (agent-maintained)
- (none yet)

---
# Task 003 log  (append-only, by the executing agent)
- 2026-09-02 spec approved by the manager; worktree ../wt/task-003 created from task/005.

- 2026-09-02 Read, in order: this task file; `CLAUDE.md`; ADR-0116, ADR-0113, ADR-0103,
  ADR-0115 §1/§10, ADR-0056; `docs/decisions/README.md` (amend protocol + index format);
  `docs/decisions/TEMPLATE.md`; `docs/manager/SPEC-CHECKLIST.md` item 4; `docs/manager/
  REVIEW-CHECKLIST.md` item 4; task 001 and task 005 (the two audits this task mechanises).

- **Runtime choice: Python 3, standard library only.** Checked the environment: `python3
  --version` → 3.14.4, present; `node --version` → not found (exit 127). Per ADR-0103
  (boring, restartable) the tool must not depend on something that isn't there, so Python was
  chosen over Node. No third-party packages either — `python3 -c "import pytest"` fails (not
  installed, and no guarantee of network access to install it), so tests use the standard
  library's `unittest`, not pytest. This keeps the tool and its tests runnable with nothing
  beyond a stock Python 3 interpreter, in CI or anywhere else.

- **Header-parsing survey before writing code.** Read every real ADR header via targeted
  greps before designing the parser (not from assumptions): confirmed the header block ends
  at the first `## ` heading (ADR-0041 has a `- **Statuses:** ...` bullet *inside* its body
  that must not be mistaken for the header's `Status:` field — this shaped the parser's
  "read from title to first `## ` line only" rule); confirmed fields are sometimes combined
  on one bullet line separated by `·` (e.g. `- **Date:** 2026-09-02 · **Area:** ...`) and
  sometimes on separate lines; confirmed ADR-0038 (the reserved/superseded stub) has no
  `Area:` or `Related:` line at all, which is why those fields default to empty rather than
  being fatal; confirmed two ADRs (0030, 0039) each carry **two separate** `Amended by:`
  bullet lines (one per amending ADR) — the parser accumulates list-type fields (`Touches`,
  `Related`, `Amends`, `Amended by`) across every matching bullet line in the header rather
  than keeping only the last one. Verified with a corrected filename-vs-title-number check
  (my first bash attempt gave false positives on ADR-0038 by grabbing every `ADR-NNNN`
  substring from its title instead of just the title's own number) that no ADR in the repo
  currently has a title/filename number mismatch, so making that fatal does not break
  generation on the current tree.

- **Design decision: both `--write` and `--check` share one `analyze()` and both refuse to
  proceed on a fatal parse problem, an index-completeness violation, or an amend-protocol
  violation** (touches-coverage is the sole exception — reported, never fatal, per criterion
  5). Rationale recorded in `docs/tools/adr-index.md`: writing `INDEX.json` on top of a
  README or amend-graph already known to be inconsistent would itself be a generator that
  lies (ADR-0113). This was my call, not a blocking ambiguity — documented rather than
  booked as a question for Ludwig, since it does not touch decisions/security/data and is
  reversible by a later task if it proves wrong.

- Wrote `tools/adr/build_index.py` (parser + `analyze()` + `--write`/`--check`/`--lookup`),
  `tools/adr/__init__.py`, `tests/adr/test_build_index.py` (28 tests), `tests/adr/__init__.py`,
  `docs/tools/adr-index.md`, `.github/workflows/adr-index.yml`.

## Acceptance criteria — demonstrated

**1. Generation.** `python3 tools/adr/build_index.py --write` (run from the worktree root):
  ```
  Scanned 119 ADR file(s) in .../docs/decisions.
  Parsed OK: 119.
  Skipped (fatal): 0.
  Touches coverage: 3/119 ADRs have a Touches: line (116 missing).
  ...
  Wrote .../docs/decisions/INDEX.json (119 entries).
  ```
  Verified valid JSON with 119 entries and all required fields via
  `python3 -c "import json; d=json.load(open('docs/decisions/INDEX.json')); print(d['count'], len(d['adrs']))"`
  → `119 119`. Spot-checked entries for ADR-0001 (plain), ADR-0038 (no Area/Related — both
  default to `""`/`[]`, not fatal), ADR-0030/0039 (two `Amended by` lines each, both
  collected: `amended_by: [58, 119]`), ADR-0058 (`amends: [30, 39]`, parenthetical prose
  correctly dropped), ADR-0115 (`amends` with 9 numbers), ADR-0117/0118/0119 (the only three
  ADRs with a real `Touches:` line).

**2. Check mode is a gate.**
  - Clean: `python3 tools/adr/build_index.py --check` → exit 0, `CHECK OK: INDEX.json
    matches the ADR files and both invariants hold.`
  - Broken: mutated the first line of `docs/decisions/0001-platform-is-the-goal.md` to
    `# ADR-0001: The platform is the goal; MUTATED TITLE FOR TEST`, ran `--check` again →
    exit 1, output included:
    ```
    .../docs/decisions/INDEX.json is out of date (2 difference(s)):
      - ADR-0001: committed INDEX.json is stale, field(s) changed: title
      -     title: 'The platform is the goal; the roguelike is the first mod' -> 'The platform is the goal; MUTATED TITLE FOR TEST'
    CHECK FAILED.
    ```
  - Reverted the file from a pre-edit backup; re-ran `--check` → exit 0 again, clean.
  - No ADR files remain modified: `git status --short` and `git diff --stat -- docs/decisions`
    confirmed no tracked file changed, only the new `INDEX.json`.

**3. Index completeness invariant.**
  - Deleted the `[0001](0001-platform-is-the-goal.md)` row from `docs/decisions/README.md`
    (line 31), ran `--check` → exit 1:
    ```
    Index completeness violations (1):
      - README.md index is missing a row for ADR-0001
    CHECK FAILED.
    ```
  - Restored `README.md` from a pre-edit backup (`diff` confirmed byte-identical restore);
    re-ran `--check` → exit 0, clean.
  - Unit-tested separately (missing row, dangling row/number-with-no-file, broken link
    target, duplicate row) in `tests/adr/test_build_index.py::AnalyzeTests` against synthetic
    fixtures, all passing.

**4. Amend-protocol invariant.**
  - Removed the `- **Amended by:** ADR-0119 (...)` line (line 8) from
    `docs/decisions/0030-manifest.md`, ran `--check` → exit 1:
    ```
    Amend-protocol violations (1):
      - 0119-reserved-namespaces.md lists 'Amends: ADR-0030' but 0030-manifest.md has no matching 'Amended by: ADR-0119'
    CHECK FAILED.
    ```
    Both filenames named, as required.
  - Restored `0030-manifest.md` from a pre-edit backup (byte-identical); re-ran `--check` →
    exit 0, clean.

**5. Touches coverage is reported, not fatal.** On the unmodified tree, `--write` and
  `--check` both print `Touches coverage: 3/119 ADRs have a Touches: line (116 missing.)`
  followed by the full list of the 116 (ADR-0116 itself does **not** count — its "Touches"
  is prose inside the ADR body, not a header field, which the header-block-boundary parsing
  correctly excludes). `--check` exits 0 on the clean tree despite this, confirming criterion
  5 holds: the report never gates. Exact count: **116 of 119**, matching the spec's stated
  figure exactly — encoded as a regression assertion in
  `tests/adr/test_build_index.py::RealRepoTests::test_real_corpus_touches_coverage_matches_task_004_input`
  (with a comment noting it must be updated when task 004 tags the rest).

**6. Real lookup end to end.** `python3 tools/adr/build_index.py --lookup registry`:
  ```
  Lookup 'registry': 1 match(es).
    ADR-0119 (0119-reserved-namespaces.md): Reserved namespaces — a small platform-owned set, exempt from username binding
  ```
  This is the ADR-0116 §4 worked example, running against the real generated `INDEX.json`,
  not a hardcoded answer — ADR-0119 is the only currently-tagged ADR whose `Touches:` list
  contains the token `registry` (ADR-0117/0118 are tagged with other topics).

**7. Determinism.** Ran `--write` twice in succession on the real tree; `diff` between the
  two output files showed no difference (`IDENTICAL` printed). Also unit-tested
  (`DeterminismAndSerializationTests::test_two_writes_are_byte_identical`) against a fixture
  with `out.read_bytes()` compared byte-for-byte, and a fixed-key-order test on `Adr.to_entry()`.

**8. Malformed headers fail loudly.** Built a throwaway copy of `docs/decisions/` under
  `/tmp/decisions_test` (never touching the real worktree) and introduced three problems:
  removed the `Status:` line from ADR-0002, corrupted ADR-0004's date to `31st of August
  2026`, and duplicated ADR-0006 into a second file (`0006-duplicate-test.md`) also titled
  `# ADR-0006`. Ran `--write --decisions-dir /tmp/decisions_test --out
  /tmp/decisions_test/INDEX.json`:
  ```
  Skipped (fatal): 4.
    - 0002-target-audience.md: missing Status field in header
    - 0004-own-assets-only.md: unparseable date '31st of August 2026' (expected YYYY-MM-DD)
    - 0006-duplicate-test.md: duplicate ADR number 0006 (...)
    - 0006-openness-and-handover.md: duplicate ADR number 0006 (...)
  ...
  Fatal header problems (4):
    - 0002-target-audience.md:1: missing Status field in header
    - 0004-own-assets-only.md:4: unparseable date '31st of August 2026' (expected YYYY-MM-DD)
    - 0006-duplicate-test.md: duplicate ADR number 0006, also used by: 0006-openness-and-handover.md
    - 0006-openness-and-handover.md: duplicate ADR number 0006, also used by: 0006-duplicate-test.md
  Refusing to write INDEX.json: the corpus has unresolved violations above.
  ```
  Exit code 1; `grep -c Traceback` on the full log → 0 (no Python traceback). Re-ran the same
  fixture with `--check` → same fatal report, exit 1. Every skipped file is named with its
  reason and the "Skipped (fatal): 4" counter matches the four broken files exactly (the
  duplicate-number pair produces two entries, one per file, as intended — a reader auditing
  either file individually still gets told why it was skipped). Also covered as unit tests:
  `ParseAdrFileTests::test_missing_status_is_fatal_and_named`,
  `test_unparseable_date_is_fatal`, `test_impossible_calendar_date_is_fatal`,
  `test_title_filename_number_mismatch_is_fatal`, `test_no_traceback_on_malformed_input`,
  `AnalyzeTests::test_duplicate_number_detected_and_both_files_skipped`.

## Test suite
`python3 -m unittest discover -s tests/adr -v` → **28 tests, all pass** (0 failures, 0
errors), run 2026-09-02 in the worktree. Covers all 8 criteria via synthetic fixtures plus
three `RealRepoTests` that run against the actual `docs/decisions/` corpus (119 ADRs parsed
clean, 116 missing Touches, the ADR-0116 §4 `registry` lookup). `python3 -m py_compile` on
all four new `.py` files → clean.

## Repo-scope check
`git status --short` in the worktree, before committing, showed only new/untracked paths:
`.github/`, `docs/decisions/INDEX.json`, `docs/tasks/003-adr-index-generator.md` (this file),
`docs/tools/`, `tests/`, `tools/`. `git diff --stat -- docs/decisions` was empty — **no ADR
body or header was left modified**; every mutation used for criteria 2/3/4 above was made
from a backup copy and reverted before moving on, and independently checked with `diff`
against the backup. `__pycache__` directories created by running the tests were deleted
before committing (not part of the declared file scope, and not useful to track).

## Known limitation — TODO
| Item | Status |
| --- | --- |
| `.github/workflows/adr-index.yml` actually running on GitHub Actions | **Built but unproven.** This repository has no git remote (verified: no `origin` configured), so the workflow has never executed in Actions. The two commands it runs (`python3 -m unittest discover -s tests/adr -v` and `python3 tools/adr/build_index.py --check`) were both run locally in this worktree and pass, as shown above. Do not treat this workflow as verified CI until it has actually run once the repo is pushed to a remote. |

## Questions
None required Ludwig's input to proceed. Two implementation calls were made and documented
with rationale in `docs/tools/adr-index.md` rather than booked as open questions, since
neither touches decisions/security/data and both are cheaply revisited by a later task if
wrong: (a) Python/stdlib over Node (Node not installed in this environment); (b) `--write`
and `--check` share one validation path and both refuse on a fatal/invariant violation, not
just `--check`.

## Status
All 8 acceptance criteria demonstrated above with real commands and output. Deliverables
complete: generator, `docs/decisions/INDEX.json` (generated, committed), tests (28, passing),
`docs/tools/adr-index.md`, `.github/workflows/adr-index.yml` (unproven per TODO above), this
log. No ADR body or header touched. Ready for review.
