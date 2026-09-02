"""Tests for tools/adr/build_index.py (task 003).

Runtime: Python's built-in `unittest` -- no third-party test runner is
installed in this environment (no pytest, no network guarantee to fetch
one), and stdlib-only keeps the tool and its tests equally boring and
restartable (ADR-0103). Run with:

    python3 -m unittest discover -s tests/adr -v

or, from the repo root:

    python3 -m unittest tests.adr.test_build_index -v
"""

from __future__ import annotations

import io
import json
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from tools.adr import build_index as bi  # noqa: E402


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


class ParseAdrFileTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def test_full_header_all_fields(self):
        write(
            self.dir / "0042-example.md",
            "# ADR-0042: Example decision\n\n"
            "- **Status:** Accepted\n"
            "- **Date:** 2026-09-02 · **Area:** Testing / Fixtures\n"
            "- **Touches:** kernel/persistence, registry\n"
            "- **Related:** ADR-0001, ADR-0002\n"
            "- **Amends:** ADR-0007\n"
            "- **Amended by:** ADR-0100 (first note)\n"
            "- **Amended by:** ADR-0101 (second note)\n\n"
            "## Context\nSome context.\n",
        )
        adr, issues = bi.parse_adr_file(self.dir / "0042-example.md")
        self.assertEqual(issues, [])
        self.assertEqual(adr.number, 42)
        self.assertEqual(adr.title, "Example decision")
        self.assertEqual(adr.status, "Accepted")
        self.assertEqual(adr.date, "2026-09-02")
        self.assertEqual(adr.area, "Testing / Fixtures")
        self.assertEqual(adr.touches, ["kernel/persistence", "registry"])
        self.assertEqual(adr.related, [1, 2])
        self.assertEqual(adr.amends, [7])
        # Two separate "Amended by" bullet lines must both be collected.
        self.assertEqual(adr.amended_by, [100, 101])

    def test_minimal_header_defaults_to_empty(self):
        write(
            self.dir / "0001-minimal.md",
            "# ADR-0001: Minimal\n\n- **Status:** Accepted\n- **Date:** 2026-09-02\n\n## Decision\nX.\n",
        )
        adr, issues = bi.parse_adr_file(self.dir / "0001-minimal.md")
        self.assertEqual(issues, [])
        self.assertEqual(adr.area, "")
        self.assertEqual(adr.touches, [])
        self.assertEqual(adr.related, [])
        self.assertEqual(adr.amends, [])
        self.assertEqual(adr.amended_by, [])

    def test_body_text_after_a_section_heading_is_not_a_header_field(self):
        # A "- **Statuses:** ..." bullet inside the body (like the real
        # ADR-0041) must not be mistaken for the header's Status field.
        write(
            self.dir / "0002-body.md",
            "# ADR-0002: Body test\n\n- **Status:** Accepted\n- **Date:** 2026-09-02\n\n"
            "## Decision\n- **Statuses:** mods may be marked deprecated or removed.\n",
        )
        adr, issues = bi.parse_adr_file(self.dir / "0002-body.md")
        self.assertEqual(issues, [])
        self.assertEqual(adr.status, "Accepted")

    def test_missing_status_is_fatal_and_named(self):
        write(
            self.dir / "0003-nostatus.md",
            "# ADR-0003: No status\n\n- **Date:** 2026-09-02\n\n## Decision\nX.\n",
        )
        adr, issues = bi.parse_adr_file(self.dir / "0003-nostatus.md")
        self.assertIsNone(adr)
        self.assertEqual(len(issues), 1)
        self.assertIn("0003-nostatus.md", issues[0].filename)
        self.assertIn("Status", issues[0].reason)

    def test_unparseable_date_is_fatal(self):
        write(
            self.dir / "0004-badate.md",
            "# ADR-0004: Bad date\n\n- **Status:** Accepted\n- **Date:** not-a-date\n\n## Decision\nX.\n",
        )
        adr, issues = bi.parse_adr_file(self.dir / "0004-badate.md")
        self.assertIsNone(adr)
        self.assertEqual(len(issues), 1)
        self.assertIn("date", issues[0].reason.lower())
        self.assertIsNotNone(issues[0].line)

    def test_impossible_calendar_date_is_fatal(self):
        write(
            self.dir / "0005-badcal.md",
            "# ADR-0005: Bad calendar date\n\n- **Status:** Accepted\n- **Date:** 2026-02-30\n\n## Decision\nX.\n",
        )
        adr, issues = bi.parse_adr_file(self.dir / "0005-badcal.md")
        self.assertIsNone(adr)
        self.assertEqual(len(issues), 1)

    def test_title_filename_number_mismatch_is_fatal(self):
        write(
            self.dir / "0006-mismatch.md",
            "# ADR-0007: Wrong number\n\n- **Status:** Accepted\n- **Date:** 2026-09-02\n\n## Decision\nX.\n",
        )
        adr, issues = bi.parse_adr_file(self.dir / "0006-mismatch.md")
        self.assertIsNone(adr)
        self.assertEqual(len(issues), 1)
        self.assertIn("0006", issues[0].reason)
        self.assertIn("0007", issues[0].reason)

    def test_no_traceback_on_malformed_input(self):
        # parse_adr_file must never raise for a structurally odd file --
        # it reports a fatal issue instead (criterion 8).
        write(self.dir / "0008-empty.md", "")
        try:
            adr, issues = bi.parse_adr_file(self.dir / "0008-empty.md")
        except Exception as exc:  # pragma: no cover - the point is that this never fires
            self.fail(f"parse_adr_file raised {exc!r} instead of reporting a fatal issue")
        self.assertIsNone(adr)
        self.assertEqual(len(issues), 1)


class AnalyzeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def _write_basic_corpus(self):
        write(
            self.dir / "0001-first.md",
            "# ADR-0001: First\n\n- **Status:** Accepted\n- **Date:** 2026-09-01\n\n## Decision\nX.\n",
        )
        write(
            self.dir / "0002-second.md",
            "# ADR-0002: Second\n\n- **Status:** Accepted\n- **Date:** 2026-09-02\n"
            "- **Touches:** registry\n\n## Decision\nY.\n",
        )
        write(
            self.dir / "README.md",
            "# Decisions\n\n## Index\n"
            "- [0001](0001-first.md) First\n"
            "- [0002](0002-second.md) Second\n",
        )

    def test_clean_corpus_is_ok(self):
        self._write_basic_corpus()
        result = bi.analyze(self.dir)
        self.assertTrue(result.ok)
        self.assertEqual(len(result.adrs), 2)
        self.assertEqual(result.fatal_issues, [])
        self.assertEqual(result.completeness_issues, [])
        self.assertEqual(result.amend_issues, [])

    def test_duplicate_number_detected_and_both_files_skipped(self):
        self._write_basic_corpus()
        write(
            self.dir / "0001-duplicate.md",
            "# ADR-0001: Duplicate\n\n- **Status:** Accepted\n- **Date:** 2026-09-03\n\n## Decision\nZ.\n",
        )
        result = bi.analyze(self.dir)
        self.assertFalse(result.ok)
        skipped_names = {name for name, _reason in result.skipped_files}
        self.assertIn("0001-first.md", skipped_names)
        self.assertIn("0001-duplicate.md", skipped_names)
        self.assertTrue(any("duplicate" in r.reason.lower() for r in result.fatal_issues))

    def test_index_completeness_missing_row(self):
        self._write_basic_corpus()
        readme = self.dir / "README.md"
        readme.write_text(
            readme.read_text(encoding="utf-8").replace("- [0002](0002-second.md) Second\n", ""),
            encoding="utf-8",
        )
        result = bi.analyze(self.dir)
        self.assertFalse(result.ok)
        self.assertTrue(any("ADR-0002" in issue for issue in result.completeness_issues))

    def test_index_completeness_dangling_row(self):
        self._write_basic_corpus()
        readme = self.dir / "README.md"
        readme.write_text(
            readme.read_text(encoding="utf-8") + "- [0099](0099-ghost.md) Ghost entry\n",
            encoding="utf-8",
        )
        result = bi.analyze(self.dir)
        self.assertFalse(result.ok)
        joined = "\n".join(result.completeness_issues)
        self.assertIn("0099", joined)

    def test_index_completeness_broken_link_target(self):
        self._write_basic_corpus()
        readme = self.dir / "README.md"
        readme.write_text(
            readme.read_text(encoding="utf-8").replace(
                "- [0002](0002-second.md) Second\n", "- [0002](0002-wrong-target.md) Second\n"
            ),
            encoding="utf-8",
        )
        result = bi.analyze(self.dir)
        self.assertFalse(result.ok)
        joined = "\n".join(result.completeness_issues)
        self.assertIn("0002-wrong-target.md", joined)

    def test_index_completeness_duplicate_row(self):
        self._write_basic_corpus()
        readme = self.dir / "README.md"
        readme.write_text(readme.read_text(encoding="utf-8") + "- [0001](0001-first.md) First again\n", encoding="utf-8")
        result = bi.analyze(self.dir)
        self.assertFalse(result.ok)
        joined = "\n".join(result.completeness_issues)
        self.assertIn("ADR-0001", joined)
        self.assertIn("2 times", joined)

    def test_amend_protocol_one_directional_amends_side_fails(self):
        write(
            self.dir / "0001-a.md",
            "# ADR-0001: A\n\n- **Status:** Accepted\n- **Date:** 2026-09-01\n"
            "- **Amends:** ADR-0002\n\n## Decision\nX.\n",
        )
        write(
            self.dir / "0002-b.md",
            "# ADR-0002: B\n\n- **Status:** Accepted\n- **Date:** 2026-09-02\n\n## Decision\nY.\n",
        )
        write(
            self.dir / "README.md",
            "# Decisions\n\n## Index\n- [0001](0001-a.md) A\n- [0002](0002-b.md) B\n",
        )
        result = bi.analyze(self.dir)
        self.assertFalse(result.ok)
        joined = "\n".join(result.amend_issues)
        self.assertIn("0001-a.md", joined)
        self.assertIn("0002-b.md", joined)

    def test_amend_protocol_one_directional_amended_by_side_fails(self):
        write(
            self.dir / "0001-a.md",
            "# ADR-0001: A\n\n- **Status:** Accepted\n- **Date:** 2026-09-01\n\n## Decision\nX.\n",
        )
        write(
            self.dir / "0002-b.md",
            "# ADR-0002: B\n\n- **Status:** Accepted\n- **Date:** 2026-09-02\n"
            "- **Amended by:** ADR-0001\n\n## Decision\nY.\n",
        )
        write(
            self.dir / "README.md",
            "# Decisions\n\n## Index\n- [0001](0001-a.md) A\n- [0002](0002-b.md) B\n",
        )
        result = bi.analyze(self.dir)
        self.assertFalse(result.ok)
        joined = "\n".join(result.amend_issues)
        self.assertIn("0001-a.md", joined)
        self.assertIn("0002-b.md", joined)

    def test_amend_protocol_bidirectional_is_ok(self):
        write(
            self.dir / "0001-a.md",
            "# ADR-0001: A\n\n- **Status:** Accepted\n- **Date:** 2026-09-01\n"
            "- **Amends:** ADR-0002\n\n## Decision\nX.\n",
        )
        write(
            self.dir / "0002-b.md",
            "# ADR-0002: B\n\n- **Status:** Accepted\n- **Date:** 2026-09-02\n"
            "- **Amended by:** ADR-0001\n\n## Decision\nY.\n",
        )
        write(
            self.dir / "README.md",
            "# Decisions\n\n## Index\n- [0001](0001-a.md) A\n- [0002](0002-b.md) B\n",
        )
        result = bi.analyze(self.dir)
        self.assertEqual(result.amend_issues, [])
        self.assertTrue(result.ok)

    def test_touches_missing_is_reported_but_not_fatal(self):
        self._write_basic_corpus()  # ADR-0001 has no Touches line
        result = bi.analyze(self.dir)
        self.assertTrue(result.ok)  # criterion 5: never fatal
        self.assertIn("ADR-0001 (0001-first.md)", result.touches_missing)
        self.assertNotIn("ADR-0002 (0002-second.md)", result.touches_missing)

    def test_malformed_filename_is_discovered_counted_and_fatal(self):
        # Regression test for task 003 review round 2, finding 1: a *.md
        # file that looks like an ADR but has a non-conforming filename
        # (here, a capital letter in the slug) used to be filtered out of
        # file discovery before parse_adr_file() ever saw it -- invisible
        # to scanned_count, skipped_files, fatal_issues and the
        # completeness check, all at once. It must now be scanned, counted,
        # named, and treated as fatal (per the reviewer's explicit
        # instruction: a mis-named ADR is invisible to the index the whole
        # spec gate depends on, so this is not merely a reported skip).
        self._write_basic_corpus()
        write(
            self.dir / "0003-Bad-Name.md",
            "# ADR-0003: Mis-named file\n\n- **Status:** Accepted\n- **Date:** 2026-09-03\n\n"
            "## Decision\nZ.\n",
        )
        result = bi.analyze(self.dir)

        # Discovered: counted in scanned_count, not silently dropped.
        self.assertEqual(result.scanned_count, 3)
        # Counted and named in skipped_files, with a reason.
        skipped_names = {name for name, _reason in result.skipped_files}
        self.assertIn("0003-Bad-Name.md", skipped_names)
        skipped_reason = dict(result.skipped_files)["0003-Bad-Name.md"]
        self.assertIn("filename", skipped_reason.lower())
        # Named in fatal_issues too.
        fatal_names = {issue.filename for issue in result.fatal_issues}
        self.assertIn("0003-Bad-Name.md", fatal_names)
        # Fatal: blocks --write/--check, not a mere report.
        self.assertFalse(result.ok)
        # The well-formed ADRs are unaffected.
        self.assertEqual({a.filename for a in result.adrs}, {"0001-first.md", "0002-second.md"})

    def test_malformed_filename_does_not_crash_completeness_check(self):
        # check_index_completeness() now receives every discovered filename,
        # including non-conforming ones, and must not raise trying to derive
        # an ADR number from a name FILENAME_RE cannot match.
        self._write_basic_corpus()
        write(
            self.dir / "0003-Bad-Name.md",
            "# ADR-0003: Mis-named file\n\n- **Status:** Accepted\n- **Date:** 2026-09-03\n\n"
            "## Decision\nZ.\n",
        )
        try:
            result = bi.analyze(self.dir)
        except Exception as exc:  # pragma: no cover - the point is this never fires
            self.fail(f"analyze() raised {exc!r} on a malformed filename instead of reporting it")
        self.assertFalse(result.ok)

    def test_readme_and_template_are_still_excluded_explicitly(self):
        # NON_ADR_FILENAMES must still keep the two real non-ADR files out
        # of discovery -- the fix must not turn them into "malformed ADRs".
        self._write_basic_corpus()
        write(self.dir / "TEMPLATE.md", "# ADR-NNNN: <template>\n\n- **Status:** Proposed\n")
        result = bi.analyze(self.dir)
        self.assertEqual(result.scanned_count, 2)
        self.assertEqual(result.fatal_issues, [])
        self.assertTrue(result.ok)


class DeterminismAndSerializationTests(unittest.TestCase):
    def test_two_writes_are_byte_identical(self):
        tmp = tempfile.TemporaryDirectory()
        try:
            d = Path(tmp.name)
            write(
                d / "0001-a.md",
                "# ADR-0001: A\n\n- **Status:** Accepted\n- **Date:** 2026-09-01\n\n## Decision\nX.\n",
            )
            write(d / "README.md", "# Decisions\n\n## Index\n- [0001](0001-a.md) A\n")
            out = d / "INDEX.json"

            rc1 = bi.cmd_write(d, out)
            first = out.read_bytes()
            rc2 = bi.cmd_write(d, out)
            second = out.read_bytes()

            self.assertEqual(rc1, 0)
            self.assertEqual(rc2, 0)
            self.assertEqual(first, second)
        finally:
            tmp.cleanup()

    def test_entry_key_order_is_fixed(self):
        adr = bi.Adr(1, "0001-a.md", "A", "Accepted", "2026-09-01", "Vision", [], [], [], [])
        entry = adr.to_entry()
        self.assertEqual(list(entry.keys()), list(bi.ENTRY_FIELDS))


class CliIntegrationTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)
        write(
            self.dir / "0001-a.md",
            "# ADR-0001: A\n\n- **Status:** Accepted\n- **Date:** 2026-09-01\n"
            "- **Touches:** registry\n\n## Decision\nX.\n",
        )
        write(
            self.dir / "0002-b.md",
            "# ADR-0002: B\n\n- **Status:** Accepted\n- **Date:** 2026-09-02\n\n## Decision\nY.\n",
        )
        write(
            self.dir / "README.md",
            "# Decisions\n\n## Index\n- [0001](0001-a.md) A\n- [0002](0002-b.md) B\n",
        )
        self.out = self.dir / "INDEX.json"

    def tearDown(self):
        self.tmp.cleanup()

    def _run(self, *args):
        buf = io.StringIO()
        with redirect_stdout(buf):
            rc = bi.main(["--decisions-dir", str(self.dir), "--out", str(self.out), *args])
        return rc, buf.getvalue()

    def test_write_then_check_passes(self):
        rc, _ = self._run("--write")
        self.assertEqual(rc, 0)
        rc, out = self._run("--check")
        self.assertEqual(rc, 0)
        self.assertIn("CHECK OK", out)

    def test_check_without_index_fails_clearly(self):
        rc, out = self._run("--check")
        self.assertEqual(rc, 1)
        self.assertIn("run --write first", out)

    def test_check_detects_stale_index_and_names_the_adr(self):
        self._run("--write")
        adr_path = self.dir / "0002-b.md"
        adr_path.write_text(
            adr_path.read_text(encoding="utf-8").replace("# ADR-0002: B", "# ADR-0002: B (mutated)"),
            encoding="utf-8",
        )
        rc, out = self._run("--check")
        self.assertEqual(rc, 1)
        self.assertIn("ADR-0002", out)
        self.assertIn("title", out)

    def test_lookup_finds_matching_adr(self):
        self._run("--write")
        rc, out = self._run("--lookup", "registry")
        self.assertEqual(rc, 0)
        self.assertIn("ADR-0001", out)
        self.assertNotIn("ADR-0002", out)

    def test_lookup_no_match(self):
        self._run("--write")
        rc, out = self._run("--lookup", "nonexistent-topic")
        self.assertEqual(rc, 0)
        self.assertIn("0 match(es)", out)

    def test_check_fails_on_a_malformed_filename_not_check_ok(self):
        # This is the reviewer's exact reproduction for finding 1: "a
        # directory with two ADR-shaped files, one mis-named, reports
        # 'Scanned 1... Skipped (fatal): 0' and exits 0." It must now scan
        # both, skip and name the bad one, and fail the gate -- CHECK OK
        # must never be printed while a file is invisible to the index.
        self._run("--write")  # INDEX.json for the two well-formed ADRs first
        write(
            self.dir / "0099-Mis-Named.md",
            "# ADR-0099: Mis-named\n\n- **Status:** Accepted\n- **Date:** 2026-09-02\n\n"
            "## Decision\nZ.\n",
        )
        rc, out = self._run("--check")
        self.assertEqual(rc, 1)
        self.assertIn("Scanned 3 ADR file(s)", out)
        self.assertIn("Skipped (fatal): 1", out)
        self.assertIn("0099-Mis-Named.md", out)
        self.assertNotIn("CHECK OK", out)
        self.assertIn("CHECK FAILED", out)


class RealRepoTests(unittest.TestCase):
    """Integration checks against the actual docs/decisions corpus.

    These exercise the real data, not fixtures -- they are the automated
    form of the acceptance-criteria demonstrations recorded in the task
    log. They read the real files but never write to them.
    """

    def setUp(self):
        self.decisions_dir = REPO_ROOT / "docs" / "decisions"
        if not self.decisions_dir.is_dir():
            self.skipTest("docs/decisions not found -- not running inside the World of Modcraft repo")

    def test_real_corpus_has_119_adrs_and_is_clean(self):
        result = bi.analyze(self.decisions_dir)
        self.assertEqual(result.scanned_count, 119)
        self.assertEqual(len(result.adrs), 119)
        self.assertEqual(result.fatal_issues, [])
        self.assertEqual(result.completeness_issues, [])
        self.assertEqual(result.amend_issues, [])
        self.assertTrue(result.ok)

    def test_real_corpus_touches_coverage_matches_task_004_input(self):
        # Snapshot of the corpus as of task 003 (docs/tasks/003-adr-index-generator.md
        # criterion 5): 116 of 119 ADRs lack a Touches: line. This number is
        # expected to change once task 004 tags the remaining ADRs -- when it
        # does, update this assertion as part of that task.
        result = bi.analyze(self.decisions_dir)
        self.assertEqual(len(result.touches_missing), 116)

    def test_real_lookup_registry_matches_adr_0116_section_4_example(self):
        # ADR-0116 section 4's worked example: a task touching a topic looks
        # up the matching ADR numbers from INDEX.json. On the real corpus,
        # "registry" currently matches ADR-0119 (the only tagged ADR whose
        # Touches list contains it).
        result = bi.analyze(self.decisions_dir)
        by_number = {a.number: a for a in result.adrs}
        matches = [a.number for a in result.adrs if "registry" in {t.lower() for t in a.touches}]
        self.assertIn(119, matches)
        for n in matches:
            self.assertIn("registry", [t.lower() for t in by_number[n].touches])


if __name__ == "__main__":
    unittest.main()
