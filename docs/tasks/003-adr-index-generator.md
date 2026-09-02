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

---
## Review round 2 — fixes (2026-09-02)

Independent review returned two blocking findings on the commit above (`bdb3db5`). Both fixed
on this branch, in place, without touching any declared-out-of-scope file.

### Finding 1 (blocking) — hollow skip in file discovery

**Reviewer's report:** `analyze()` filtered `docs/decisions/*.md` by `FILENAME_RE` *before*
calling `parse_adr_file()` (`tools/adr/build_index.py:399-401` in the reviewed commit). A
`.md` file that looked like an ADR but had a non-conforming name (capital letter, 3-digit
number, trailing space, ...) was excluded from `paths` before anything ever inspected it — so
it never appeared in `scanned_count`, `skipped_files`, or `fatal_issues`, and
`check_index_completeness()` (fed the same pre-filtered list) could not flag it as a dangling
row or a missing README entry either. It was invisible to every invariant simultaneously.
Reproduced by the reviewer: two ADR-shaped files, one mis-named, gave "Scanned 1... Skipped
(fatal): 0" and exit 0 — `--check` printing CHECK OK while a real ADR sat entirely unindexed.
This is the exact failure class the tool exists to prevent, and violated criterion 8 ("never
skipped silently, every skipped file counted with its reason") and ADR-0115 §1.

**Root cause:** `FILENAME_RE` was doing two unrelated jobs at once — (a) excluding the two
real non-ADR files (`README.md`, `TEMPLATE.md`), and (b) validating that a filename has the
right shape. Using the same regex for both meant a typo in an ADR's filename was
indistinguishable, at the discovery stage, from "this isn't an ADR at all" — it silently fell
into case (a).

**Fix:**
- Added `NON_ADR_FILENAMES = {"README.md", "TEMPLATE.md"}`, an explicit, closed, two-item set
  — not a regex, not derived from `FILENAME_RE` (`tools/adr/build_index.py`, near
  `FILENAME_RE`'s definition).
- `analyze()`'s discovery now excludes only `NON_ADR_FILENAMES`: `p for p in
  decisions_dir.glob("*.md") if p.name not in NON_ADR_FILENAMES`. Every other `*.md` file is
  discovered and handed to `parse_adr_file()`.
- `parse_adr_file()` already had a `FILENAME_RE` check as its very first step, reporting a
  `FatalIssue` for a non-conforming name — that path simply used to be unreachable for real
  files because discovery filtered them out first. It is reachable now. Strengthened the
  message ("filename does not match the required 'NNNN-slug.md' pattern (4-digit number,
  lowercase slug) -- this file cannot be indexed") and the surrounding comment explaining why
  this is the *only* place a bad filename is caught.
- `check_index_completeness()` used to do `int(FILENAME_RE.match(fn).group(1))` for every
  filename handed to it, which would now raise `AttributeError` on a non-conforming name
  (`match()` returns `None`). Fixed to skip filenames `FILENAME_RE` cannot match when building
  `file_numbers` (using a walrus-guarded comprehension) — such a name has no derivable ADR
  number to check for a README row, and is already reported, fatally, by `parse_adr_file()`.
  Confirmed this does not silently downgrade anything: the malformed file is still fatal via
  the `parse_adr_file()` path; this function just no longer crashes trying to double-count it.

**Fatal, not a reported skip — per the coordinator's explicit instruction.** A mis-named ADR
is invisible to the index the whole spec gate depends on, so `--write` and `--check` both
refuse (exit non-zero) rather than merely logging it. This was already the existing behaviour
of the `FatalIssue` path once reachable — no new "is this fatal?" branch was needed, only
making the existing fatal path actually run. I agree with the instruction: unlike missing
`Touches:` (criterion 5, deliberately non-fatal because 116/119 ADRs are untagged *by design*
pending task 004), a filename `NNNN-slug.md` violation on an otherwise well-formed ADR has no
legitimate "not yet done" reading — it is always a mistake, and every existing ADR in the
corpus already conforms (verified again below), so making it fatal cannot regress the clean
tree.

**Re-demonstrated, criterion 8, with the malformed-filename case added:**
```
$ python3 tools/adr/build_index.py --write --decisions-dir /tmp/decisions_test2 --out /tmp/decisions_test2/INDEX.json
Scanned 121 ADR file(s) in /tmp/decisions_test2.
Parsed OK: 116.
Skipped (fatal): 5.
...
Fatal header problems (5):
  - 0002-target-audience.md:1: missing Status field in header
  - 0004-own-assets-only.md:4: unparseable date '31st of August 2026' (expected YYYY-MM-DD)
  - 0006-Bad-Capital-Name.md: filename does not match the required 'NNNN-slug.md' pattern (4-digit number, lowercase slug) -- this file cannot be indexed
  - 0007-duplicate-test.md: duplicate ADR number 0007, also used by: 0007-fork-wowee-and-azerothcore-monorepo.md
  - 0007-fork-wowee-and-azerothcore-monorepo.md: duplicate ADR number 0007, also used by: 0007-duplicate-test.md

Refusing to write INDEX.json: the corpus has unresolved violations above.
```
Exit code 1; `grep -c Traceback` on the full output → 0. All four fatal categories (missing
Status, unparseable date, malformed filename, duplicate number) now reported together, by
name, with the malformed-filename case sitting alongside the three that were already covered.
The temporary fixture lived under `/tmp/decisions_test2`, never inside the worktree; deleted
after the run.

Also reproduced the reviewer's literal repro (two files, one mis-named, nothing else broken)
directly against `/tmp` fixtures with both `--check` and `--write`:
```
$ python3 tools/adr/build_index.py --check --decisions-dir /tmp/repro_finding1 --out /tmp/repro_finding1/INDEX.json
Scanned 2 ADR file(s) in /tmp/repro_finding1.
Parsed OK: 1.
Skipped (fatal): 1.
  - 0002-Bad-Name.md: filename does not match the required 'NNNN-slug.md' pattern (4-digit number, lowercase slug) -- this file cannot be indexed
...
exit=1
```
`CHECK OK` was not printed; exit code 1 in both `--write` and `--check`.

**Regression tests added** to `tests/adr/test_build_index.py` (none of criterion 8's original
28 tests exercised a malformed filename, which is how this survived review round 1):
- `AnalyzeTests::test_malformed_filename_is_discovered_counted_and_fatal` — asserts the file
  is counted in `scanned_count`, named in `skipped_files` and `fatal_issues`, `result.ok` is
  `False`, and the well-formed ADRs are unaffected.
- `AnalyzeTests::test_malformed_filename_does_not_crash_completeness_check` — asserts
  `analyze()` does not raise.
- `AnalyzeTests::test_readme_and_template_are_still_excluded_explicitly` — asserts
  `NON_ADR_FILENAMES` still keeps `README.md`/`TEMPLATE.md` out of discovery and does not
  turn them into "malformed ADRs".
- `CliIntegrationTests::test_check_fails_on_a_malformed_filename_not_check_ok` — the
  reviewer's exact reproduction, at the CLI level: exit code 1, `Scanned 3`, `Skipped (fatal):
  1`, the bad filename named in the output, `CHECK OK` never printed, `CHECK FAILED` printed.

`python3 -m unittest discover -s tests/adr -v` → **32 tests, all pass** (28 original + 4 new),
run 2026-09-02 after the fix.

### Finding 2 (minor, factual) — stale sentence in docs/tools/adr-index.md

**Reviewer's report:** `docs/tools/adr-index.md`'s "Known limitation" section claimed the
workflow "runs the same two commands documented above (`--write` then `git diff --exit-code`
on `INDEX.json`, and `--check`)". The actual `.github/workflows/adr-index.yml` has only two
steps: the `unittest` run and `python3 tools/adr/build_index.py --check`. There is no
`--write` step and no `git diff --exit-code` step. The task log already described the
workflow correctly; only this doc sentence was wrong.

**Fix:** per the coordinator's instruction, made the doc match the artifact — did **not** add
steps to the workflow. Rewrote the "Known limitation: CI is unproven" section in
`docs/tools/adr-index.md` to name the workflow's actual two steps (`unittest discover` and
`--check`) and explicitly note there is no separate `--write`/`git diff --exit-code` step,
because `--check` already performs that staleness comparison internally (regenerates the
index in memory, diffs against the committed file — as the "Commands" section above already
explains). Grepped the rest of the doc for `git diff --exit-code` and `--write.*then` to
confirm this was the only stale sentence; it was.

### Re-verification after both fixes
- `python3 -m unittest discover -s tests/adr -v` → 32/32 pass.
- `python3 tools/adr/build_index.py --check` (real repo, unmodified) → exit 0, `CHECK OK`,
  still 119 entries, still 116/119 missing Touches (unchanged by this fix, as expected — no
  real ADR filename is malformed).
- `python3 tools/adr/build_index.py --write` run twice on the real repo → `diff` on the two
  `INDEX.json` outputs → identical; `git diff --stat -- docs/decisions/INDEX.json` against the
  committed copy → empty (the fix did not change the generated index for the real, clean
  corpus, only its behaviour on a corpus that has a problem).
- `git status --short` / `git diff --stat -- docs/decisions` → only `tools/adr/build_index.py`,
  `tests/adr/test_build_index.py` and `docs/tools/adr-index.md` modified; no ADR body or
  header touched; `docs/decisions/INDEX.json` unmodified (byte-identical regeneration).
- Both workflow commands (`python3 -m unittest discover -s tests/adr -v`;
  `python3 tools/adr/build_index.py --check`) re-run locally after the fix → both pass, as
  above. Still unproven in actual GitHub Actions (no remote) — TODO row above stands unchanged.

## Status (updated)
Both review round 2 findings fixed and re-demonstrated on branch `task/003-adr-index-generator`
in `/home/ludwig/wt/task-003`. All 8 acceptance criteria still hold, with criterion 8 now also
covering the malformed-filename case end to end. 32/32 tests pass. No ADR body or header
touched at any point across either review round. Ready for review again.
