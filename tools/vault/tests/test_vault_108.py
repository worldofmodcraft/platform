"""Black-box tests for the 108 additions to tools/vault/wom_vault.py (docs/design/*.md as notes at the vault root).
Run via docs/tasks/108-verify.sh.

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

DS_A = "# Vault design\n\nSome design.\n\nA rule follows:\n\n---\n\nend\n"
DS_B = "# Other design\n\nno trailing newline here"
BASELINE_ROOT = {"Status.md", "Tasks.md", "Gotchas.md", "Commands.md", "Mission Log.md"}


class Base108(t53.Base053):
    def ds_repo(self, a=DS_A, b=DS_B, extra=None):
        r = self.repo()
        r.put("docs/design/vault-design.md", a)
        r.put("docs/design/Other.md", b)
        for k, v in (extra or {}).items():
            r.put(k, v)
        t53.commit_at(r, "add design docs", "2026-11-03T10:00:00+00:00")
        return r

    def root_notes(self, vault=None):
        return {n for n in self.files(vault or self.vault) if "/" not in n}

    def design_notes(self, vault=None):
        return self.root_notes(vault) - BASELINE_ROOT - {"Decisions.md"}


class TestAC1Notes(Base108):
    def test_ac1_notes_at_the_root_verbatim_with_last_commit(self):
        r = self.ds_repo()
        r.put("docs/design/Other.md", DS_B + "\nedited\n")
        t53.commit_at(r, "edit other", "2026-11-04T10:00:00+00:00")
        r.put("unrelated.txt", "u\n")
        t53.commit_at(r, "unrelated", "2026-11-05T10:00:00+00:00")
        rc, out, err, _ = self.write(r)
        self.assertEqual(rc, 0, err)
        files = self.files(self.vault)
        self.assertEqual(self.design_notes(), {"vault-design.md", "Other.md"})
        for stem, src in (("vault-design", DS_A), ("Other", DS_B + "\nedited\n")):
            path = "docs/design/%s.md" % stem
            note = files["%s.md" % stem][0].decode()
            fm = self.fm(note)
            self.assertEqual(fm["generated"], "true")
            self.assertEqual(fm["source_ref"], "main")
            self.assertEqual(fm["source_path"], path)
            self.assertEqual(fm["source_commit"], r.git("log", "-1", "--format=%H", "main", "--", path))
            self.assertEqual(fm["updated"], r.git("log", "-1", "--format=%cI", fm["source_commit"]))
            self.assertEqual(t53.body_of(note), src)  # verbatim: no trailing-newline fixing, inner '---' kept
        self.assertNotEqual(self.fm(files["vault-design.md"][0].decode())["source_commit"], r.git("rev-parse", "main"))

    def test_ac1_non_design_files_are_not_notes(self):
        r = self.ds_repo(extra={"docs/design/sub/deep.md": "x\n", "docs/design/notes.txt": "x\n"})
        self.assertEqual(self.write(r)[0], 0)
        self.assertEqual(self.design_notes(), {"vault-design.md", "Other.md"})
        self.assertFalse(os.path.exists(os.path.join(self.vault, "sub")))


class TestAC2Names(Base108):
    def test_ac2_unaccepted_name_is_an_error_not_a_silent_skip(self):
        for bad in (".hidden.md", "-dash.md", "with space.md"):
            with self.subTest(bad):
                r = self.ds_repo(extra={"docs/design/" + bad: "x\n"})
                vault = self.mk("v-" + bad.replace(" ", "_"))
                rc, out, err, _ = self.write(r, vault=vault)
                self.assertNotEqual(rc, 0)
                self.assertIn(bad, err)
                self.assertNotIn("Traceback", err)
                self.assertEqual(os.listdir(vault), [])

    def test_ac2_forbidden_hand_written_name_is_refused(self):
        for name in ("MINISIGN.md", "minisign.md"):
            with self.subTest(name):
                r = self.ds_repo(extra={"docs/design/" + name: "x\n"})
                vault = self.mk("v-" + name)
                rc, out, err, _ = self.write(r, vault=vault)
                self.assertNotEqual(rc, 0)
                self.assertIn("forbidden", err)
                self.assertEqual(os.listdir(vault), [])

    def test_ac2_symlink_in_git_is_not_a_regular_file(self):
        r = self.ds_repo()
        os.symlink("vault-design.md", os.path.join(r.path, "docs/design/link.md"))
        t53.commit_at(r, "add symlink", "2026-11-03T11:00:00+00:00")
        vault = self.mk("v-link")
        rc, out, err, _ = self.write(r, vault=vault)
        self.assertNotEqual(rc, 0)
        self.assertIn("not a regular file", err)
        self.assertIn("link.md", err)
        self.assertEqual(os.listdir(vault), [])


class TestAC3Collision(Base108):
    def test_ac3_stem_equal_to_a_planned_root_name_is_an_error(self):
        for stem in ("Status", "Tasks", "Gotchas", "Commands", "Decisions", "status", "Mission Log"):
            with self.subTest(stem):
                r = self.ds_repo(extra={"docs/design/%s.md" % stem: "x\n"})
                vault = self.mk("v-" + stem.replace(" ", "_"))
                rc, out, err, _ = self.write(r, vault=vault)
                self.assertNotEqual(rc, 0, stem)
                self.assertIn("%s.md" % stem, err)
                self.assertNotIn("Traceback", err)
                self.assertEqual(os.listdir(vault), [], "nothing written, not even the valid notes")

    def test_ac3_collision_names_the_planned_note(self):
        r = self.ds_repo(extra={"docs/design/Status.md": "x\n"})
        rc, out, err, _ = self.write(r)
        self.assertIn("collides", err)


class TestAC4Frontmatter(Base108):
    def test_ac4_design_doc_with_own_frontmatter_fails_and_writes_nothing(self):
        for label, text in (("frontmatter", "---\ntitle: x\n---\n# D\n"), ("bare rule", "---\n# D\n"),
                            ("bom", "﻿---\ntitle: x\n---\n")):
            with self.subTest(label):
                r = self.ds_repo(a=text)
                vault = self.mk("v-" + label.replace(" ", "-"))
                rc, out, err, _ = self.write(r, vault=vault)
                self.assertNotEqual(rc, 0)
                self.assertIn("starts with '---'", err)
                self.assertIn("vault-design.md", err)
                self.assertNotIn("Traceback", err)
                self.assertEqual(os.listdir(vault), [])


class TestAC5Secrets(Base108):
    def test_ac5_secret_in_a_design_doc_blocks_the_run_and_is_never_printed(self):
        for pname, secret in tv.secrets().items():
            with self.subTest(pattern=pname):
                r = self.ds_repo(a="# D\n\nleaked %s here\n" % secret)
                vault = self.mk("v-" + pname)
                rc, out, err, _ = self.write(r, vault=vault)
                self.assertNotEqual(rc, 0)
                self.assertIn(pname, err)
                self.assertIn("vault-design.md line", err)
                self.assertNotIn(secret, out + err)
                self.assertNotIn("Traceback", err)
                self.assertEqual(os.listdir(vault), [])


class TestAC6Absent(Base108):
    def test_ac6_repo_without_docs_design_writes_only_the_usual_notes(self):
        r = self.repo()
        rc, out, err, _ = self.write(r)
        self.assertEqual(rc, 0, err)
        self.assertEqual(self.design_notes(), set())

    def test_ac6_design_dir_with_only_non_markdown_is_fine(self):
        r = self.repo()
        r.put("docs/design/readme.txt", "x\n")
        t53.commit_at(r, "txt only", "2026-11-03T10:00:00+00:00")
        self.assertEqual(self.write(r)[0], 0)
        self.assertEqual(self.design_notes(), set())


class TestAC7Vault(Base108):
    def test_ac7_hand_written_target_is_not_overwritten(self):
        r = self.ds_repo()
        hand = os.path.join(self.vault, "Other.md")
        open(hand, "wb").write(b"# hand written\n")
        rc, out, err, _ = self.write(r)
        self.assertNotEqual(rc, 0)
        self.assertIn("generated: true", err)
        self.assertEqual(open(hand, "rb").read(), b"# hand written\n")
        self.assertFalse(os.path.exists(os.path.join(self.vault, "vault-design.md")), "two-phase: nothing written")

    def test_ac7_idempotent_and_never_deletes(self):
        r = self.ds_repo()
        self.assertEqual(self.write(r)[0], 0)
        v0 = self.files(self.vault)
        rc, out, err, _ = self.write(r)
        self.assertEqual(rc, 0, err)
        self.assertIn("written=0", out)
        self.assertEqual(self.files(self.vault), v0, "bytes and mtimes identical")
        r.git("rm", "-q", "docs/design/Other.md")
        t53.commit_at(r, "remove other", "2026-11-03T12:00:00+00:00")
        self.assertEqual(self.write(r)[0], 0)
        self.assertTrue(os.path.exists(os.path.join(self.vault, "Other.md")), "the tool never deletes")

    def test_ac7_check_ignores_planned_design_notes(self):
        r = self.ds_repo()
        base = os.path.join(self.base, "baseline.json")
        self.assertEqual(self.write(r)[0], 0)
        rc, out, err, _ = self.run_tool(["check", "--save-baseline", base], cwd=r.path)
        self.assertEqual(rc, 0, err)
        text = open(base).read()
        self.assertNotIn("vault-design", text)
        self.assertNotIn("Other.md", text)
        # a hand-written root note is still tracked
        open(os.path.join(self.vault, "Hand.md"), "wb").write(b"hand\n")
        rc, out, err, _ = self.run_tool(["check", "--save-baseline", base], cwd=r.path)
        self.assertIn("Hand.md", open(base).read())

    def test_ac7_check_does_not_hide_an_unplanned_root_note(self):
        r = self.ds_repo()
        base = os.path.join(self.base, "baseline.json")
        self.assertEqual(self.write(r)[0], 0)
        self.assertEqual(self.run_tool(["check", "--save-baseline", base], cwd=r.path)[0], 0)
        open(os.path.join(self.vault, "Stray.md"), "wb").write(b"x\n")
        rc, out, err, _ = self.run_tool(["check", "--baseline", base], cwd=r.path)
        self.assertEqual(rc, 1)
        self.assertIn("added: Stray.md", out)


class TestStatic108(unittest.TestCase):
    def test_no_secret_shaped_strings_in_108_tests(self):
        src = open(os.path.abspath(__file__), encoding="utf-8").read()
        self.assertIn("tv.secrets()", src)
        for rx in (r"gh[pousr]_[A-Za-z0-9]{36}", r"github_pat_[A-Za-z0-9_]{82}", r"-----BEGIN [A-Z ]*PRIVATE KEY-----",
                   r"untrusted comment: " + r"minisign encrypted secret key", r"sk-ant-[A-Za-z0-9_-]{32,}",
                   r"(AKIA|ASIA)[A-Z0-9]{16}"):
            self.assertIsNone(re.search(rx, src), rx)


if __name__ == "__main__":
    unittest.main()
