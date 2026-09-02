#!/usr/bin/env python3
"""Generate and verify docs/decisions/INDEX.json from the ADR header lines.

World of Modcraft, task 003 (docs/tasks/003-adr-index-generator.md).

Design (see docs/tools/adr-index.md for the full write-up):

- Runtime: Python 3 standard library only. No third-party dependencies, so
  the tool runs the same way in every environment without an install step
  (ADR-0103: prefer the boring, restartable solution). Node was considered
  but is not installed in this development environment.
- The ADR header is read defensively: the log has 119 files written by hand
  over several days, and header formatting varies (fields combined on one
  line with "." separators, fields on their own line, optional fields
  entirely absent). The parser never assumes a field is present except
  Status and Date, which are required to build a usable index entry
  (ADR-0113: "the generator refuses rather than lies" -- a malformed header
  is reported by filename and line, never silently skipped, never a
  Python traceback).
- Two independently-useful validations share one code path (`analyze()`):
  fatal header problems (missing Status, unparseable Date, a title/filename
  number mismatch, a duplicate ADR number) and the two corpus-wide
  invariants from tasks 001 and 005 (README index completeness, the
  Amends/Amended-by back-reference protocol). Both `--write` and `--check`
  run the same analysis and refuse on any of those violations -- writing an
  INDEX.json on top of a README that is known to disagree with the files
  would itself be a generator that lies. `--check` additionally diffs the
  freshly generated content against the committed INDEX.json.
- Touches coverage (how many ADRs lack a `Touches:` header line) is reported
  every run but is never fatal -- criterion 5 of the task spec requires
  `--check` to keep passing while the log is still mostly untagged; making
  it fatal would make the gate impossible to adopt.
"""

from __future__ import annotations

import argparse
import dataclasses
import datetime
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------

# Fixed key order for every generated entry -- this is what makes two
# consecutive `--write` runs byte-identical (criterion 7): Python dicts
# preserve insertion order, so as long as we always build the dict with the
# same field order, json.dumps(..., sort_keys=False) is deterministic.
ENTRY_FIELDS = (
    "number",
    "filename",
    "title",
    "status",
    "date",
    "area",
    "touches",
    "related",
    "amends",
    "amended_by",
)


@dataclasses.dataclass
class Adr:
    number: int
    filename: str
    title: str
    status: str
    date: str
    area: str
    touches: List[str]
    related: List[int]
    amends: List[int]
    amended_by: List[int]

    def to_entry(self) -> Dict:
        return {
            "number": self.number,
            "filename": self.filename,
            "title": self.title,
            "status": self.status,
            "date": self.date,
            "area": self.area,
            "touches": list(self.touches),
            "related": list(self.related),
            "amends": list(self.amends),
            "amended_by": list(self.amended_by),
        }


@dataclasses.dataclass
class FatalIssue:
    """A per-file parse problem that blocks generation. Never silent."""

    filename: str
    line: Optional[int]
    reason: str

    def format(self) -> str:
        loc = f"{self.filename}:{self.line}" if self.line else self.filename
        return f"{loc}: {self.reason}"


@dataclasses.dataclass
class AnalysisResult:
    adrs: List[Adr]
    fatal_issues: List[FatalIssue]
    skipped_files: List[Tuple[str, str]]  # (filename, reason)
    scanned_count: int
    completeness_issues: List[str]
    amend_issues: List[str]
    touches_missing: List[str]  # "ADR-NNNN filename" for each ADR lacking Touches

    @property
    def ok(self) -> bool:
        """True when the corpus is clean enough to write/trust an index.

        Touches coverage is deliberately excluded: it is a report, not a
        gate (task spec criterion 5).
        """
        return not (self.fatal_issues or self.completeness_issues or self.amend_issues)


# ---------------------------------------------------------------------------
# ADR file parsing
# ---------------------------------------------------------------------------

FILENAME_RE = re.compile(r"^(\d{4})-[a-z0-9][a-z0-9-]*\.md$")

# The only two *.md files under docs/decisions/ that are not ADRs. This is a
# closed, explicit exclusion list -- deliberately NOT "any *.md file whose
# name FILENAME_RE fails to match". Filtering file discovery by FILENAME_RE
# used to be exactly how these two were excluded, which meant a typo'd ADR
# filename (a capital letter, a 3-digit number, a trailing space) was
# silently dropped before anything ever looked at it: invisible to
# scanned_count, skipped_files, fatal_issues and the completeness check, all
# at once (task 003 review round 2, finding 1). Every other *.md file is
# discovered and handed to parse_adr_file(), whose own FILENAME_RE check
# reports a non-conforming name as a fatal, named issue instead.
NON_ADR_FILENAMES = {"README.md", "TEMPLATE.md"}

TITLE_RE = re.compile(r"^#\s*ADR-(\d{4}):\s*(.+?)\s*$")
SECTION_RE = re.compile(r"^##\s")
BULLET_RE = re.compile(r"^-\s+(.*)$")
FIELD_RE = re.compile(r"\*\*([A-Za-z][A-Za-z ]*?):\*\*\s*(.*)$")
ADR_NUM_RE = re.compile(r"ADR-(\d{3,4})")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")

LIST_KEYS = {"touches", "related", "amends", "amended by"}
SCALAR_KEYS = {"status", "date", "area"}
KNOWN_KEYS = LIST_KEYS | SCALAR_KEYS


def _split_header_fields(line: str) -> List[Tuple[str, str]]:
    """Split one header bullet line into (key, value) pairs.

    A single bullet line may carry several fields separated by a middle
    dot, e.g. ``- **Date:** 2026-09-02 . **Area:** Registry``. Unrecognised
    bold segments are ignored rather than rejected -- the header block can
    contain free text (this task must not assume every field is present or
    that only known fields appear).
    """
    m = BULLET_RE.match(line)
    if not m:
        return []
    rest = m.group(1)
    # Segments are separated by a middle dot (U+00B7), optionally spaced.
    segments = re.split(r"\s*·\s*", rest)
    pairs = []
    for seg in segments:
        fm = FIELD_RE.match(seg.strip())
        if fm:
            key = fm.group(1).strip().lower()
            value = fm.group(2).strip()
            pairs.append((key, value))
    return pairs


def parse_adr_file(path: Path) -> Tuple[Optional[Adr], List[FatalIssue]]:
    """Parse one ADR file. Returns (Adr or None, fatal issues).

    Adr is None exactly when a fatal issue made it impossible to build a
    usable entry; issues is empty exactly when parsing fully succeeded.
    """
    filename = path.name
    issues: List[FatalIssue] = []

    fm = FILENAME_RE.match(filename)
    if not fm:
        # This is the ONLY place a non-conforming ADR filename is caught --
        # analyze() hands every *.md file under docs/decisions/ except the
        # two names in NON_ADR_FILENAMES to this function, specifically so a
        # typo'd filename cannot be dropped before anything ever looks at
        # it. Fatal by design (per task 003 review round 2, finding 1): a
        # mis-named ADR is invisible to the index the whole spec gate
        # depends on, so it must block --write/--check, not merely be noted.
        issues.append(
            FatalIssue(
                filename,
                None,
                "filename does not match the required 'NNNN-slug.md' pattern "
                "(4-digit number, lowercase slug) -- this file cannot be indexed",
            )
        )
        return None, issues
    filename_number = int(fm.group(1))

    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        issues.append(FatalIssue(filename, None, f"could not read file: {exc}"))
        return None, issues

    lines = text.splitlines()

    # --- Title line -------------------------------------------------
    title_line_idx = None
    for i, raw in enumerate(lines):
        if raw.strip():
            title_line_idx = i
            break
    if title_line_idx is None:
        issues.append(FatalIssue(filename, None, "file is empty"))
        return None, issues

    tm = TITLE_RE.match(lines[title_line_idx])
    if not tm:
        issues.append(
            FatalIssue(
                filename,
                title_line_idx + 1,
                "missing or unparseable title line (expected '# ADR-NNNN: <title>')",
            )
        )
        return None, issues

    title_number = int(tm.group(1))
    title = tm.group(2)

    if title_number != filename_number:
        issues.append(
            FatalIssue(
                filename,
                title_line_idx + 1,
                f"title number ADR-{title_number:04d} does not match filename number "
                f"ADR-{filename_number:04d}",
            )
        )
        return None, issues

    # --- Header block: from after the title to the first '## ' section --
    fields: Dict[str, List[Tuple[str, int]]] = {}
    for i in range(title_line_idx + 1, len(lines)):
        raw = lines[i]
        if SECTION_RE.match(raw):
            break
        for key, value in _split_header_fields(raw):
            if key not in KNOWN_KEYS:
                continue
            fields.setdefault(key, []).append((value, i + 1))

    # --- Status (required) ------------------------------------------
    if "status" not in fields:
        issues.append(FatalIssue(filename, title_line_idx + 1, "missing Status field in header"))
        return None, issues
    status_value, _status_line = fields["status"][0]
    if not status_value:
        issues.append(FatalIssue(filename, fields["status"][0][1], "Status field is empty"))
        return None, issues
    status = status_value

    # --- Date (required, must parse as YYYY-MM-DD) -------------------
    if "date" not in fields:
        issues.append(FatalIssue(filename, title_line_idx + 1, "missing Date field in header"))
        return None, issues
    date_value, date_line = fields["date"][0]
    if not DATE_RE.match(date_value):
        issues.append(
            FatalIssue(filename, date_line, f"unparseable date {date_value!r} (expected YYYY-MM-DD)")
        )
        return None, issues
    try:
        datetime.date.fromisoformat(date_value)
    except ValueError:
        issues.append(
            FatalIssue(filename, date_line, f"unparseable date {date_value!r} (not a real calendar date)")
        )
        return None, issues
    date = date_value

    # --- Area (optional) ----------------------------------------------
    area = fields["area"][0][0] if "area" in fields else ""

    # --- Touches (optional, comma-separated list) ----------------------
    touches: List[str] = []
    for value, _line in fields.get("touches", []):
        for item in value.split(","):
            item = item.strip()
            if item and item != "—":  # em dash placeholder for "none"
                touches.append(item)

    # --- Related / Amends / Amended-by (optional, ADR-number lists) ----
    def collect_numbers(key: str) -> List[int]:
        nums: List[int] = []
        for value, _line in fields.get(key, []):
            for match in ADR_NUM_RE.finditer(value):
                n = int(match.group(1))
                if n not in nums:
                    nums.append(n)
        return sorted(nums)

    related = collect_numbers("related")
    amends = collect_numbers("amends")
    amended_by = collect_numbers("amended by")

    adr = Adr(
        number=filename_number,
        filename=filename,
        title=title,
        status=status,
        date=date,
        area=area,
        touches=touches,
        related=related,
        amends=amends,
        amended_by=amended_by,
    )
    return adr, []


# ---------------------------------------------------------------------------
# README index parsing (criterion 3 -- mechanises task 001)
# ---------------------------------------------------------------------------

README_ROW_RE = re.compile(r"^-\s*\[(\d{4})\]\(([^)]+)\)")


def parse_readme_index(readme_path: Path) -> List[Tuple[int, str, int]]:
    """Return (number, link_target, line_number) for every index row."""
    rows = []
    text = readme_path.read_text(encoding="utf-8")
    for i, line in enumerate(text.splitlines()):
        m = README_ROW_RE.match(line)
        if m:
            rows.append((int(m.group(1)), m.group(2), i + 1))
    return rows


def check_index_completeness(readme_path: Path, adr_filenames: List[str]) -> List[str]:
    """Mechanises task 001: every ADR file listed exactly once, no dangling rows.

    adr_filenames may include names that do not match FILENAME_RE (analyze()
    now passes every discovered *.md file, not just the well-formed ones --
    see NON_ADR_FILENAMES). Such a name cannot be resolved to an ADR number
    at all, so it is skipped here; it is still reported, fatally, by
    parse_adr_file()'s own filename check -- this function must not crash on
    it, and must not silently treat it as complete either.
    """
    issues: List[str] = []
    rows = parse_readme_index(readme_path)

    file_numbers = {
        int(m.group(1)) for fn in adr_filenames if (m := FILENAME_RE.match(fn))
    }
    row_numbers = [n for n, _target, _line in rows]

    # Every file appears exactly once.
    from collections import Counter

    counts = Counter(row_numbers)
    missing = sorted(file_numbers - set(row_numbers))
    duplicated = sorted(n for n, c in counts.items() if c > 1 and n in file_numbers)

    for n in missing:
        issues.append(f"README.md index is missing a row for ADR-{n:04d}")
    for n in duplicated:
        issues.append(f"README.md index lists ADR-{n:04d} {counts[n]} times (expected exactly once)")

    # No dangling rows: every row number must correspond to a real file,
    # and every row's link target must exist on disk.
    for n, target, line in rows:
        if n not in file_numbers:
            issues.append(f"README.md:{line}: row for ADR-{n:04d} does not match any docs/decisions file")
        target_path = readme_path.parent / target
        if not target_path.exists():
            issues.append(f"README.md:{line}: link target '{target}' does not exist")

    return issues


# ---------------------------------------------------------------------------
# Amend-protocol invariant (criterion 4 -- mechanises task 005)
# ---------------------------------------------------------------------------


def check_amend_protocol(adrs: List[Adr]) -> List[str]:
    by_number = {a.number: a for a in adrs}
    issues: List[str] = []

    forward_pairs = {(a.number, y) for a in adrs for y in a.amends}
    backward_pairs = {(x, a.number) for a in adrs for x in a.amended_by}

    def fname(n: int) -> str:
        adr = by_number.get(n)
        return adr.filename if adr else f"ADR-{n:04d} (unknown)"

    for x, y in sorted(forward_pairs - backward_pairs):
        issues.append(
            f"{fname(x)} lists 'Amends: ADR-{y:04d}' but {fname(y)} has no matching "
            f"'Amended by: ADR-{x:04d}'"
        )
    for x, y in sorted(backward_pairs - forward_pairs):
        issues.append(
            f"{fname(y)} lists 'Amended by: ADR-{x:04d}' but {fname(x)} has no matching "
            f"'Amends: ADR-{y:04d}'"
        )

    return issues


# ---------------------------------------------------------------------------
# Orchestration
# ---------------------------------------------------------------------------


def analyze(decisions_dir: Path) -> AnalysisResult:
    readme_path = decisions_dir / "README.md"

    # Discover every *.md file except the two known non-ADRs -- NOT every
    # *.md file whose name happens to match FILENAME_RE. A file that looks
    # like it belongs here but has a malformed name (capital letter, 3-digit
    # number, trailing space, ...) must still be scanned and reported, not
    # silently excluded before parse_adr_file() ever sees it (see
    # NON_ADR_FILENAMES above; task 003 review round 2, finding 1).
    paths = sorted(
        p for p in decisions_dir.glob("*.md") if p.name not in NON_ADR_FILENAMES
    )

    fatal_issues: List[FatalIssue] = []
    skipped_files: List[Tuple[str, str]] = []
    by_number: Dict[int, List[Adr]] = {}
    adrs: List[Adr] = []

    for path in paths:
        adr, issues = parse_adr_file(path)
        if issues:
            fatal_issues.extend(issues)
            skipped_files.append((path.name, issues[-1].reason))
            continue
        by_number.setdefault(adr.number, []).append(adr)

    # Duplicate ADR numbers (two files claiming the same number).
    for number, group in sorted(by_number.items()):
        if len(group) > 1:
            names = ", ".join(a.filename for a in group)
            for a in group:
                fatal_issues.append(
                    FatalIssue(
                        a.filename,
                        None,
                        f"duplicate ADR number {number:04d}, also used by: "
                        + ", ".join(x.filename for x in group if x.filename != a.filename),
                    )
                )
                skipped_files.append((a.filename, f"duplicate ADR number {number:04d} ({names})"))
        else:
            adrs.append(group[0])

    adrs.sort(key=lambda a: a.number)

    completeness_issues: List[str] = []
    amend_issues: List[str] = []
    touches_missing: List[str] = []

    if readme_path.exists():
        completeness_issues = check_index_completeness(readme_path, [p.name for p in paths])

    # Only meaningful to run the amend-protocol check over ADRs that parsed
    # successfully; a fatal parse failure elsewhere does not corrupt this.
    amend_issues = check_amend_protocol(adrs)

    for a in adrs:
        if not a.touches:
            touches_missing.append(f"ADR-{a.number:04d} ({a.filename})")

    return AnalysisResult(
        adrs=adrs,
        fatal_issues=fatal_issues,
        skipped_files=skipped_files,
        scanned_count=len(paths),
        completeness_issues=completeness_issues,
        amend_issues=amend_issues,
        touches_missing=touches_missing,
    )


def build_index_document(adrs: List[Adr]) -> Dict:
    return {
        "count": len(adrs),
        "adrs": [a.to_entry() for a in adrs],
    }


def serialize(document: Dict) -> str:
    # sort_keys=False: key order is fixed by dict insertion order (see
    # ENTRY_FIELDS / to_entry / build_index_document), which is what makes
    # repeated runs byte-identical (criterion 7). ensure_ascii=False keeps
    # the em dashes and other Unicode punctuation used in ADR titles
    # readable instead of escaped.
    return json.dumps(document, indent=2, ensure_ascii=False, sort_keys=False) + "\n"


def print_report(result: AnalysisResult, decisions_dir: Path) -> None:
    print(f"Scanned {result.scanned_count} ADR file(s) in {decisions_dir}.")
    print(f"Parsed OK: {len(result.adrs)}.")
    print(f"Skipped (fatal): {len(result.skipped_files)}.")
    for fn, reason in result.skipped_files:
        print(f"  - {fn}: {reason}")

    total = len(result.adrs)
    missing = len(result.touches_missing)
    print(f"Touches coverage: {total - missing}/{total} ADRs have a Touches: line "
          f"({missing} missing).")
    if result.touches_missing:
        print("Missing Touches:")
        for entry in result.touches_missing:
            print(f"  - {entry}")

    if result.completeness_issues:
        print(f"Index completeness violations ({len(result.completeness_issues)}):")
        for issue in result.completeness_issues:
            print(f"  - {issue}")

    if result.amend_issues:
        print(f"Amend-protocol violations ({len(result.amend_issues)}):")
        for issue in result.amend_issues:
            print(f"  - {issue}")

    if result.fatal_issues:
        print(f"Fatal header problems ({len(result.fatal_issues)}):")
        for issue in result.fatal_issues:
            print(f"  - {issue.format()}")


def diff_documents(old: Dict, new: Dict) -> List[str]:
    """Return human-readable differences between two INDEX.json documents,
    naming the offending ADR for each one (criterion 2)."""
    diffs: List[str] = []
    old_by_num = {e["number"]: e for e in old.get("adrs", [])}
    new_by_num = {e["number"]: e for e in new.get("adrs", [])}

    for n in sorted(set(old_by_num) - set(new_by_num)):
        diffs.append(f"ADR-{n:04d}: present in committed INDEX.json but not regenerated (file removed?)")
    for n in sorted(set(new_by_num) - set(old_by_num)):
        diffs.append(f"ADR-{n:04d}: present after regeneration but missing from committed INDEX.json (new file?)")
    for n in sorted(set(old_by_num) & set(new_by_num)):
        old_entry, new_entry = old_by_num[n], new_by_num[n]
        if old_entry != new_entry:
            changed_fields = [k for k in ENTRY_FIELDS if old_entry.get(k) != new_entry.get(k)]
            diffs.append(
                f"ADR-{n:04d}: committed INDEX.json is stale, field(s) changed: "
                + ", ".join(changed_fields)
            )
            for k in changed_fields:
                diffs.append(f"    {k}: {old_entry.get(k)!r} -> {new_entry.get(k)!r}")

    if old.get("count") != new.get("count"):
        diffs.append(f"count: committed={old.get('count')} regenerated={new.get('count')}")

    return diffs


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def default_decisions_dir() -> Path:
    # tools/adr/build_index.py -> repo root is two levels up.
    return Path(__file__).resolve().parents[2] / "docs" / "decisions"


def cmd_write(decisions_dir: Path, out_path: Path) -> int:
    result = analyze(decisions_dir)
    print_report(result, decisions_dir)

    if not result.ok:
        print("\nRefusing to write INDEX.json: the corpus has unresolved violations above.")
        return 1

    document = build_index_document(result.adrs)
    out_path.write_text(serialize(document), encoding="utf-8")
    print(f"\nWrote {out_path} ({len(result.adrs)} entries).")
    return 0


def cmd_check(decisions_dir: Path, out_path: Path) -> int:
    result = analyze(decisions_dir)
    print_report(result, decisions_dir)

    problems = not result.ok

    if not out_path.exists():
        print(f"\n{out_path} does not exist -- run --write first.")
        return 1

    try:
        committed = json.loads(out_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        print(f"\n{out_path} is not valid JSON: {exc}")
        return 1

    if result.ok:
        document = build_index_document(result.adrs)
        diffs = diff_documents(committed, document)
        if diffs:
            problems = True
            print(f"\n{out_path} is out of date ({len(diffs)} difference(s)):")
            for d in diffs:
                print(f"  - {d}")

    if problems:
        print("\nCHECK FAILED.")
        return 1

    print("\nCHECK OK: INDEX.json matches the ADR files and both invariants hold.")
    return 0


def cmd_lookup(decisions_dir: Path, out_path: Path, topic: str) -> int:
    if not out_path.exists():
        print(f"{out_path} does not exist -- run --write first.")
        return 1
    document = json.loads(out_path.read_text(encoding="utf-8"))
    topic_norm = topic.strip().lower()
    matches = [
        e for e in document.get("adrs", [])
        if topic_norm in {t.strip().lower() for t in e.get("touches", [])}
    ]
    print(f"Lookup '{topic}': {len(matches)} match(es).")
    for e in matches:
        print(f"  ADR-{e['number']:04d} ({e['filename']}): {e['title']}")
    return 0


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--write", action="store_true", help="Generate INDEX.json.")
    group.add_argument("--check", action="store_true", help="Verify INDEX.json is up to date.")
    group.add_argument("--lookup", metavar="TOPIC", help="Print ADRs whose Touches list contains TOPIC.")
    parser.add_argument(
        "--decisions-dir",
        type=Path,
        default=None,
        help="Override docs/decisions directory (default: resolved from this script's location).",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=None,
        help="Override INDEX.json path (default: <decisions-dir>/INDEX.json).",
    )
    return parser


def main(argv: Optional[List[str]] = None) -> int:
    args = build_arg_parser().parse_args(argv)

    decisions_dir = args.decisions_dir or default_decisions_dir()
    out_path = args.out or (decisions_dir / "INDEX.json")

    if not decisions_dir.is_dir():
        print(f"error: decisions directory not found: {decisions_dir}", file=sys.stderr)
        return 2

    if args.write:
        return cmd_write(decisions_dir, out_path)
    if args.check:
        return cmd_check(decisions_dir, out_path)
    return cmd_lookup(decisions_dir, out_path, args.lookup)


if __name__ == "__main__":
    sys.exit(main())
