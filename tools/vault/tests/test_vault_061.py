"""Black-box tests for the 061 additions to tools/vault/wom_vault.py (Runbooks/ notes).  Run via docs/tasks/061-verify.sh.

Reuses the fixtures of test_vault.py and test_vault_053.py.  Nothing here touches a real vault, /mnt or ~/.config/wom.
Secret-shaped strings are assembled at runtime.
"""
import os
import re
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # python3 -I does not add the script dir
import test_vault as tv  # noqa: E402
import test_vault_053 as t53  # noqa: E402

RB_A = "# Runbook A\n\n1. do the thing\n\nA rule follows:\n\n---\n\nend\n"
RB_B = "# Runbook B\n\nno trailing newline here"


class Base061(t53.Base053):
    def rb_repo(self, a=RB_A, b=RB_B, extra=None):
        r = self.repo()
        r.put("docs/runbooks/alpha-steps.md", a)
        r.put("docs/runbooks/beta.md", b)
        for k, v in (extra or {}).items():
            r.put(k, v)
        t53.commit_at(r, "add runbooks", "2026-10-14T10:00:00+00:00")
        return r

    def runbook_notes(self, vault=None):
        return {n for n in self.files(vault or self.vault) if n.startswith("Runbooks/")}


class TestAC1Notes(Base061):
    def test_ac1_exactly_the_two_notes_verbatim_with_last_commit(self):
        r = self.rb_repo()
        # a later commit touching only beta: alpha's source_commit must stay on its own last commit
        r.put("docs/runbooks/beta.md", RB_B + "\nedited\n")
        t53.commit_at(r, "edit beta", "2026-10-15T10:00:00+00:00")
        r.put("unrelated.txt", "u\n")
        t53.commit_at(r, "unrelated", "2026-10-16T10:00:00+00:00")
        rc, out, err, _ = self.write(r)
        self.assertEqual(rc, 0, err)
        files = self.files(self.vault)
        self.assertEqual(self.runbook_notes(), {"Runbooks/alpha-steps.md", "Runbooks/beta.md"})
        for stem, src in (("alpha-steps", RB_A), ("beta", RB_B + "\nedited\n")):
            path = "docs/runbooks/%s.md" % stem
            note = files["Runbooks/%s.md" % stem][0].decode()
            fm = self.fm(note)
            self.assertEqual(fm["generated"], "true")
            self.assertEqual(fm["source_ref"], "main")
            self.assertEqual(fm["source_path"], path)
            self.assertEqual(fm["source_commit"], r.git("log", "-1", "--format=%H", "main", "--", path))
            self.assertEqual(fm["updated"], r.git("log", "-1", "--format=%cI", fm["source_commit"]))
            self.assertEqual(t53.body_of(note), src)  # verbatim: no trailing-newline fixing, inner '---' kept
        self.assertNotEqual(self.fm(files["Runbooks/alpha-steps.md"][0].decode())["source_commit"], r.git("rev-parse", "main"))

    def test_ac1_status_has_a_runbooks_line_linking_each_note(self):
        r = self.rb_repo()
        self.assertEqual(self.write(r)[0], 0)
        status = self.files(self.vault)["Status.md"][0].decode()
        lines = [l for l in status.split("\n") if l.startswith("Runbooks:")]
        self.assertEqual(lines, ["Runbooks: [[Runbooks/alpha-steps]], [[Runbooks/beta]]"])

    def test_ac1_non_runbook_files_are_not_notes(self):
        r = self.rb_repo(extra={"docs/runbooks/sub/deep.txt": "x\n", "docs/runbooks/notes.txt": "x\n"})
        self.assertEqual(self.write(r)[0], 0)
        self.assertEqual(self.runbook_notes(), {"Runbooks/alpha-steps.md", "Runbooks/beta.md"})


class TestAC2Frontmatter(Base061):
    def test_ac2_runbook_with_own_frontmatter_fails_and_writes_nothing(self):
        for label, text in (("frontmatter", "---\ntitle: x\n---\n# RB\n"), ("bare rule", "---\n# RB\n"),
                            ("bom", "﻿---\ntitle: x\n---\n")):
            with self.subTest(label):
                r = self.rb_repo(a=text)
                vault = self.mk("v-" + label.replace(" ", "-"))
                rc, out, err, _ = self.write(r, vault=vault)
                self.assertNotEqual(rc, 0)
                self.assertIn("starts with '---'", err)
                self.assertIn("alpha-steps.md", err)
                self.assertNotIn("Traceback", err)
                self.assertEqual(os.listdir(vault), [], "nothing written, not even the valid notes")


class TestAC3Secrets(Base061):
    def test_ac3_secret_in_a_runbook_blocks_the_run_and_is_never_printed(self):
        for pname, secret in tv.secrets().items():
            with self.subTest(pattern=pname):
                r = self.rb_repo(a="# RB\n\nleaked %s here\n" % secret)
                vault = self.mk("v-" + pname)
                rc, out, err, _ = self.write(r, vault=vault)
                self.assertNotEqual(rc, 0)
                self.assertIn(pname, err)
                self.assertIn("Runbooks/alpha-steps.md line", err)
                self.assertNotIn(secret, out + err)
                self.assertNotIn("Traceback", err)
                self.assertEqual(os.listdir(vault), [])


class TestAC4NonRegular(Base061):
    def snapshot(self):
        return sorted((os.path.relpath(os.path.join(d, n), self.vault), os.lstat(os.path.join(d, n)).st_mode)
                      for d, ds, fs in os.walk(self.vault) for n in ds + fs)

    def test_ac4_symlink_fifo_dir_and_dangling_are_refused_before_any_open(self):
        for label in ("symlink", "fifo", "dir", "dangling"):
            with self.subTest(label):
                r = self.rb_repo()
                vault = self.mk("v-" + label)
                self.vault = vault
                os.mkdir(os.path.join(vault, "Runbooks"))
                target = os.path.join(vault, "Runbooks", "beta.md")
                hand = os.path.join(vault, "hand.md")
                open(hand, "wb").write(b"# hand written\n")
                if label == "symlink":
                    os.symlink(hand, target)
                elif label == "fifo":
                    os.mkfifo(target)
                elif label == "dir":
                    os.mkdir(target)
                else:
                    os.symlink(os.path.join(vault, "nowhere.md"), target)
                before = self.snapshot()
                rc, out, err, ev = self.run_timed(["write", "--ref", "main"], cwd=r.path, audit=True)
                self.assertNotEqual(rc, 0, label)
                self.assertIn("not a regular file", err)
                self.assertIn("Runbooks/beta.md", err)
                self.assertEqual(self.snapshot(), before, "zero files written")
                self.assertEqual(open(hand, "rb").read(), b"# hand written\n")
                self.assertEqual([e for e in ev if e[0] == "open" and e[1].startswith(vault)], [])


class TestAC5Idempotence(Base061):
    def test_ac5_second_run_writes_nothing_and_one_edit_rewrites_one_note(self):
        r = self.rb_repo()
        self.assertEqual(self.write(r)[0], 0)
        v0 = self.files(self.vault)
        rc, out, err, _ = self.write(r)
        self.assertEqual(rc, 0, err)
        self.assertIn("written=0", out)
        self.assertEqual(self.files(self.vault), v0, "bytes and mtimes identical")
        # a commit touching one runbook: that note, plus the aggregates and its journal day
        r.put("docs/runbooks/beta.md", RB_B + "\nmore\n")
        t53.commit_at(r, "edit beta", "2026-10-14T11:00:00+00:00")
        self.assertEqual(self.write(r)[0], 0)
        v1 = self.files(self.vault)
        changed = {n for n in v1 if v1[n] != v0.get(n)}
        self.assertEqual(changed, {"Runbooks/beta.md", "Status.md", "Tasks.md", "Journal/2026-10-14.md"})
        self.assertEqual(v1["Runbooks/alpha-steps.md"], v0["Runbooks/alpha-steps.md"])
        # a commit touching no runbook: no Runbooks note rewritten
        r.put("unrelated.txt", "u\n")
        t53.commit_at(r, "unrelated", "2026-10-14T12:00:00+00:00")
        self.assertEqual(self.write(r)[0], 0)
        v2 = self.files(self.vault)
        self.assertEqual({n for n in v2 if n.startswith("Runbooks/") and v2[n] != v1[n]}, set())


class TestAC6NoRunbooks(Base061):
    def test_ac6_repo_without_runbooks_writes_none_and_status_has_no_line(self):
        r = self.repo()
        rc, out, err, _ = self.write(r)
        self.assertEqual(rc, 0, err)
        self.assertEqual(self.runbook_notes(), set())
        self.assertFalse(os.path.exists(os.path.join(self.vault, "Runbooks")))
        self.assertNotIn("Runbooks", self.files(self.vault)["Status.md"][0].decode())

    def test_ac6_runbooks_dir_with_only_non_markdown_is_fine(self):
        r = self.repo()
        r.put("docs/runbooks/readme.txt", "x\n")
        t53.commit_at(r, "txt only", "2026-10-14T10:00:00+00:00")
        self.assertEqual(self.write(r)[0], 0)
        self.assertEqual(self.runbook_notes(), set())


class TestExtras(Base061):
    def test_check_ignores_runbook_notes(self):
        r = self.rb_repo()
        base = os.path.join(self.base, "baseline.json")
        self.assertEqual(self.write(r)[0], 0)
        rc, out, err, _ = self.run_tool(["check", "--save-baseline", base], cwd=r.path)
        self.assertEqual(rc, 0, err)
        self.assertNotIn("Runbooks", open(base).read())

    def test_unsafe_runbook_name_is_an_error_not_a_silent_skip(self):
        r = self.rb_repo(extra={"docs/runbooks/.hidden.md": "x\n"})
        rc, out, err, _ = self.write(r)
        self.assertNotEqual(rc, 0)
        self.assertIn(".hidden.md", err)
        self.assertNotIn("Traceback", err)

    def test_forbidden_name_as_runbook_is_refused(self):
        r = self.rb_repo(extra={"docs/runbooks/MINISIGN.md": "x\n"})
        vault = self.mk("v-forbid")
        rc, out, err, _ = self.write(r, vault=vault)
        self.assertNotEqual(rc, 0)
        self.assertIn("forbidden", err)
        self.assertEqual(os.listdir(vault), [])


class TestStatic061(unittest.TestCase):
    def test_no_secret_shaped_strings_in_061_tests(self):
        src = open(os.path.abspath(__file__), encoding="utf-8").read()
        self.assertIn("tv.secrets()", src)
        for rx in (r"gh[pousr]_[A-Za-z0-9]{36}", r"github_pat_[A-Za-z0-9_]{82}", r"-----BEGIN [A-Z ]*PRIVATE KEY-----",
                   r"untrusted comment: " + r"minisign encrypted secret key", r"sk-ant-[A-Za-z0-9_-]{32,}",
                   r"(AKIA|ASIA)[A-Z0-9]{16}"):
            self.assertIsNone(re.search(rx, src), rx)


if __name__ == "__main__":
    unittest.main()
