# ADR index generator (`tools/adr/build_index.py`)

Generates and verifies `docs/decisions/INDEX.json` from the ADR header lines under
`docs/decisions/*.md`. This is the mechanical layer ADR-0116 (layer 4) describes: a
machine-readable index so task creation and review can do a lookup instead of a human
re-reading 119 files. See `docs/tasks/003-adr-index-generator.md` for the task that built it
and its log for the full acceptance-criteria demonstration.

## Why Python, stdlib only

Node is not installed in this development environment; Python 3 is. The tool uses only the
standard library (`json`, `re`, `argparse`, `dataclasses`, `pathlib`, `datetime`) so it runs
identically in any environment with a Python 3 interpreter, with no install step and nothing
to pin (ADR-0103: prefer the boring, restartable solution).

## Commands

Run from anywhere; the script resolves `docs/decisions` relative to its own location unless
overridden.

```
python3 tools/adr/build_index.py --write
python3 tools/adr/build_index.py --check
python3 tools/adr/build_index.py --lookup <topic>
```

- `--write` parses every `docs/decisions/NNNN-*.md`, validates the corpus (see "What is
  validated" below), and — only if validation is clean — writes `docs/decisions/INDEX.json`.
  It refuses to write on any fatal problem, printing what and where.
- `--check` runs the same parse and validation, then additionally diffs the freshly
  regenerated content against the committed `INDEX.json`, naming every ADR whose entry is
  stale. Exits non-zero on any problem (parse, index-completeness, amend-protocol, or a stale
  `INDEX.json`). This is the CI gate — see `.github/workflows/adr-index.yml`.
- `--lookup TOPIC` reads the committed `INDEX.json` (run `--write` first if it doesn't exist)
  and prints every ADR whose `Touches:` list contains `TOPIC` (case-insensitive, exact token
  match). This is the ADR-0116 §4 worked example made runnable: "a task touching `registry` →
  the index yields the matching ADR numbers."

Both `--write` and `--check` accept `--decisions-dir PATH` and `--out PATH` to point at a
different corpus (used by the test suite to run against isolated fixtures instead of the real
decision log).

## INDEX.json shape

```json
{
  "count": 119,
  "adrs": [
    {
      "number": 1,
      "filename": "0001-platform-is-the-goal.md",
      "title": "The platform is the goal; the roguelike is the first mod",
      "status": "Accepted",
      "date": "2026-08-31",
      "area": "Vision",
      "touches": [],
      "related": [2, 44, 50],
      "amends": [],
      "amended_by": []
    }
  ]
}
```

- `touches` is `[]` when the ADR's header has no `Touches:` line — absence means empty, never
  invented (the task's Forbidden list is explicit about this).
- `related`, `amends`, `amended_by` are lists of ADR numbers (ints), extracted from the
  header's `ADR-NNNN` references; any prose in parentheses after the numbers is dropped.
- Key order within each entry, and the sort order of the `adrs` array (by number), are fixed —
  this is what makes two consecutive `--write` runs byte-identical. No wall-clock timestamp is
  embedded in the document for the same reason.

## What is validated, and what is only reported

Three things are **fatal** — they block both `--write` and `--check`, and are printed with the
offending filename (and line number, where one applies) rather than silently skipped:

1. **Malformed headers**: a missing `Status:` line, a `Date:` that doesn't parse as a real
   `YYYY-MM-DD` calendar date, or a title line whose `ADR-NNNN` number disagrees with the
   filename's number.
2. **Duplicate ADR numbers**: two files claiming the same number.
3. **Index-completeness violations** (mechanises task 001 / `docs/tasks/001-adr-index-completeness.md`):
   every `docs/decisions/NNNN-*.md` must appear in `README.md`'s index exactly once, every row's
   link target must exist on disk, and every row's number must correspond to a real file.
4. **Amend-protocol violations** (mechanises task 005 /
   `docs/tasks/005-decisions-metadata-and-reserved-namespaces.md`): if ADR X's header lists
   `Amends: ADR-000Y`, ADR Y's header must list `Amended by: ADR-000X`, and vice versa. A
   one-directional reference is reported naming both files.

One thing is **reported but never fatal**: how many ADRs lack a `Touches:` header line, and
which ones. As of task 003 that is 116 of 119 — tagging them is task 004's job. Making this
fatal would make `--check` permanently red until task 004 lands, so it cannot be a gate;
criterion 5 of the task spec is explicit about this. The count and the full list are printed
on every run.

Everything else about a header is read defensively: `Area:`, `Touches:`, `Related:`,
`Amends:` and `Amended by:` may each be entirely absent (empty string / empty list results),
fields may share one bullet line separated by `·` or each sit on their own line, and a `**Key:**`
looking bullet inside the ADR's body (after the first `## ` heading) is never mistaken for a
header field — the header block is bounded by the first section heading. The log has 119 files
written by hand over several days; the parser does not assume uniform formatting.

## Design choice: both modes share one validation path

`--write`'s job is generation (criterion 1); `--check`'s job is being a gate (criterion 2). It
would be possible to make `--write` generate unconditionally and only have `--check` enforce
the index-completeness and amend-protocol invariants. This tool instead has both modes run the
same `analyze()` and both refuse when a fatal or invariant violation is found (touches-coverage
excepted, per above). Rationale: writing an `INDEX.json` on top of a README or amend-graph that
is already known to be inconsistent would itself be "a generator that lies" (ADR-0113) — the
inconsistency would simply not show up until the next `--check`. Refusing at `--write` time
surfaces it immediately, at the point the corpus was actually broken.

## Known limitation: CI is unproven

This repository has no git remote yet, so `.github/workflows/adr-index.yml` cannot be shown
running on GitHub Actions. The workflow runs the same two commands documented above
(`--write` then `git diff --exit-code` on `INDEX.json`, and `--check`); both were run locally
against this repository as part of task 003 and pass (see the task log for the exact commands
and output). The workflow itself is built but unproven until the repository is pushed to a
remote — this is recorded as an explicit TODO in the task log, not claimed as working CI
(ADR-0115 §10).

## Tests

`tests/adr/test_build_index.py`, run with the standard library's `unittest` (no `pytest` is
installed in this environment):

```
python3 -m unittest discover -s tests/adr -v
```
