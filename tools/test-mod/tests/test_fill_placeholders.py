"""Tests for tools/test-mod/fill_placeholders.py (task 010a)."""
import contextlib
import importlib.util
import io
import os
import shutil
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
STAGE = os.path.join(ROOT, "docs", "test-mod")


def _load():
    spec = importlib.util.spec_from_file_location("fill_placeholders", os.path.join(os.path.dirname(HERE), "fill_placeholders.py"))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


fp = _load()
GOOD = "a" * 40


def run(argv):
    err = io.StringIO()
    with contextlib.redirect_stderr(err), contextlib.redirect_stdout(io.StringIO()):
        rc = fp.main(argv)
    return rc, err.getvalue()


class FillTests(unittest.TestCase):
    def setUp(self):
        self.d = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.d)
        self.mod = os.path.join(self.d, "mod.lua")
        self.entry = os.path.join(self.d, "entry.json")
        shutil.copy(os.path.join(STAGE, "hello-world", "mod.lua"), self.mod)
        shutil.copy(os.path.join(STAGE, "registry-pr", "entry.json"), self.entry)

    def read(self, p):
        with open(p, encoding="utf-8") as f:
            return f.read()

    def test_mod_fill(self):
        self.assertEqual(run(["mod", "--account", "sample-owner", "--file", self.mod])[0], 0)
        t = self.read(self.mod)
        self.assertIn('source = "https://github.com/sample-owner/wom-test-hello-world"', t)
        self.assertNotIn(fp.OWNER_TOKEN, t)

    def test_entry_fill(self):
        self.assertEqual(run(["entry", "--account", "sample-owner", "--commit", GOOD, "--file", self.entry])[0], 0)
        t = self.read(self.entry)
        self.assertIn(GOOD, t)
        self.assertNotIn(fp.OWNER_TOKEN, t)
        self.assertNotIn(fp.COMMIT_TOKEN, t)

    def test_refusals_write_nothing(self):
        before = self.read(self.entry)
        for commit in ("0" * 40, "a" * 39, "A" * 40, "g" * 40, "a" * 41, ""):
            rc, err = run(["entry", "--account", "sample-owner", "--commit", commit, "--file", self.entry])
            self.assertEqual(rc, 2, commit)
            self.assertIn("REFUSED", err)
            self.assertEqual(self.read(self.entry), before, "file changed by a refused call: " + commit)

    def test_bad_accounts_refused(self):
        before = self.read(self.mod)
        for acct in ("", "OWNER-PLACEHOLDER", "-x", "x-", "a--b", "has space", "a/b", "x" * 40, "a\nb"):
            self.assertEqual(run(["mod", "--account=" + acct, "--file", self.mod])[0], 2, repr(acct))
            self.assertEqual(self.read(self.mod), before)

    def test_already_filled_file_is_refused(self):
        self.assertEqual(run(["mod", "--account", "sample-owner", "--file", self.mod])[0], 0)
        rc, err = run(["mod", "--account", "other", "--file", self.mod])
        self.assertEqual(rc, 2)
        self.assertIn("does not contain the token", err)

    def test_missing_file_refused(self):
        self.assertEqual(run(["mod", "--account", "x", "--file", os.path.join(self.d, "nope")])[0], 2)


if __name__ == "__main__":
    unittest.main()
