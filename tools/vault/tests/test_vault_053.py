"""Black-box tests for the 053 additions to tools/vault/wom_vault.py.  Run via docs/tasks/053-verify.sh.

Covers: Decisions.md / ADR notes / Journal days (AC1-AC4) and amendments A1 (duplicate task ids),
A2 (non-regular targets) as AC7 and AC8.  Reuses the fixtures of test_vault.py (task 051); nothing here
touches a real vault, /mnt or ~/.config/wom.  Secret-shaped strings are assembled at runtime.
"""
import json
import os
import re
import subprocess
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # python3 -I does not add the script dir
import test_vault as tv  # noqa: E402

ADR1 = "# ADR-0001: First\n\n- Status: Accepted\n\nBody one, with a --- rule below.\n\n---\n\nend\n"
ADR2 = "# ADR-0002: Second | pipe\n\nBody two.\n"


def index_json(rows):
    return json.dumps({"count": len(rows), "adrs": [
        {"number": n, "filename": fn, "title": t, "status": "Accepted"} for n, fn, t in rows]}, indent=2) + "\n"


ROWS = [(1, "0001-first.md", "First decision"), (2, "0002-second.md", "Second | pipe")]


def commit_at(r, msg, date):
    r.git("add", "-A")
    env = tv.git_env(r.home)
    env.update(GIT_AUTHOR_DATE=date, GIT_COMMITTER_DATE=date)
    p = subprocess.run(["git", "commit", "-q", "--allow-empty", "-m", msg], cwd=r.path, env=env, capture_output=True, text=True)
    if p.returncode:
        raise AssertionError(p.stderr)
    return r.git("rev-parse", "HEAD")


def expected_journal(r, ref="main"):
    """{day: [(full, short, subject)]} from git's own timezone handling, independent of the tool."""
    env = dict(tv.git_env(r.home), TZ="Europe/Stockholm")
    out = subprocess.run(["git", "log", ref, "--date=format-local:%Y-%m-%d", "--format=%cd%x09%H%x09%h%x09%s"],
                         cwd=r.path, env=env, capture_output=True, text=True, check=True).stdout
    days = {}
    for line in out.splitlines():
        day, full, short, subject = line.split("\t", 3)
        days.setdefault(day, []).append((full, short, subject))
    return days


def body_of(text):
    return text.split("\n---\n\n", 1)[1]


class Base053(tv.Base):
    def decisions_repo(self, adr1=ADR1, subject_extra=""):
        r = self.repo()
        r.put("docs/decisions/0001-first.md", adr1)
        r.put("docs/decisions/0002-second.md", ADR2)
        r.put("docs/decisions/INDEX.json", index_json(ROWS))
        r.put("docs/decisions/README.md", "not an ADR\n")
        commit_at(r, "add decisions" + subject_extra, "2026-10-14T21:59:59+00:00")
        return r

    def run_timed(self, args, cwd, timeout=20, audit=False):
        env = {"PATH": os.environ["PATH"], "HOME": self.home, "LC_ALL": "C.UTF-8", "TMPDIR": tv.ROOT,
               "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_SYSTEM": "/dev/null",
               "WOM_VAULT": self.vault, "WOM_VAULT_TEST": "1"}
        cmd = ["python3", "-I"]
        log = os.path.join(self.base, "audit.json")
        if audit:
            env["WOM051_AUDIT_LOG"] = log
            cmd.append(tv.AUDIT)
        cmd += [tv.SCRIPT] + args
        p = subprocess.run(cmd, cwd=cwd, env=env, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout, p.stderr, (json.load(open(log)) if audit else None)


class TestAC1Notes(Base053):
    def test_ac1_decisions_adr_and_journal_exact(self):
        r = self.decisions_repo()
        commit_at(r, "later day", "2026-10-16T09:00:00+02:00")
        rc, out, err, _ = self.write(r)
        self.assertEqual(rc, 0, err)
        files = self.files(self.vault)
        days = expected_journal(r)
        self.assertEqual(set(days), {"2026-10-14", "2026-10-16"})
        want = {"Status.md", "Tasks.md", "Gotchas.md", "Commands.md", "Mission Log.md", "Decisions.md",
                "ADR/0001-first.md", "ADR/0002-second.md"}
        want |= {"Tasks/%s.md" % i for i in ("001", "060", "061", "062", "063", "064")}
        want |= {"Journal/%s.md" % d for d in days}
        self.assertEqual(set(files), want)  # README.md is not an ADR note
        dec = files["Decisions.md"][0].decode()
        fm = self.fm(dec)
        self.assertEqual(fm["source_path"], "docs/decisions/INDEX.json")
        self.assertEqual(fm["source_commit"], r.git("log", "-1", "--format=%H", "main", "--", "docs/decisions/INDEX.json"))
        self.assertEqual(body_of(dec), "# Decisions\n\n| Id | Title | Note |\n|---|---|---|\n"
                         "| 0001 | First decision | [[ADR/0001-first]] |\n"
                         "| 0002 | Second \\| pipe | [[ADR/0002-second]] |\n")
        for stem, src in (("0001-first", ADR1), ("0002-second", ADR2)):
            path = "docs/decisions/%s.md" % stem
            note = files["ADR/%s.md" % stem][0].decode()
            fm = self.fm(note)
            self.assertEqual(fm["generated"], "true")
            self.assertEqual(fm["source_path"], path)
            self.assertEqual(fm["source_commit"], r.git("log", "-1", "--format=%H", "main", "--", path))
            self.assertEqual(fm["updated"], r.git("log", "-1", "--format=%cI", fm["source_commit"]))
            self.assertEqual(body_of(note), src)  # verbatim, a '---' rule inside the body included
        for day, commits in days.items():
            note = files["Journal/%s.md" % day][0].decode()
            fm = self.fm(note)
            self.assertEqual(fm["source_commit"], commits[0][0], "newest commit of the day")
            self.assertEqual(fm["updated"], r.git("log", "-1", "--format=%cI", commits[0][0]))
            self.assertEqual(body_of(note), "# Journal %s\n\n" % day + "".join(
                "- %s %s\n" % (short, subject) for _, short, subject in commits))
        self.assertEqual(sum(len(c) for c in days.values()), int(r.git("rev-list", "--count", "main")))

    def test_ac1_merge_commits_are_listed(self):
        r = self.decisions_repo()
        r.git("checkout", "-q", "-b", "side")
        r.put("side.txt", "x\n")
        commit_at(r, "side work", "2026-10-15T10:00:00+02:00")
        r.git("checkout", "-q", "main")
        r.put("main.txt", "y\n")
        commit_at(r, "main work", "2026-10-15T11:00:00+02:00")
        env = tv.git_env(r.home)
        env.update(GIT_COMMITTER_DATE="2026-10-15T12:00:00+02:00", GIT_AUTHOR_DATE="2026-10-15T12:00:00+02:00")
        subprocess.run(["git", "merge", "-q", "--no-ff", "-m", "merge side", "side"], cwd=r.path, env=env,
                       check=True, capture_output=True)
        rc, out, err, _ = self.write(r)
        self.assertEqual(rc, 0, err)
        note = self.files(self.vault)["Journal/2026-10-15.md"][0].decode()
        lines = [l for l in body_of(note).splitlines() if l.startswith("- ")]
        self.assertEqual([l.split(" ", 2)[2] for l in lines], ["merge side", "main work", "side work"])
        self.assertEqual(len(lines), len(expected_journal(r)["2026-10-15"]))

    def test_ac1_repo_without_decisions_still_gets_journal(self):
        r = self.repo()
        rc, out, err, _ = self.write(r)
        self.assertEqual(rc, 0, err)
        files = self.files(self.vault)
        self.assertNotIn("Decisions.md", files)
        self.assertEqual({n for n in files if n.startswith("ADR/")}, set())
        self.assertEqual({n for n in files if n.startswith("Journal/")}, {"Journal/2026-10-14.md"})
        self.assertIn("decisions_absent=1", out)

    def test_ac1_inconsistent_index_is_an_error(self):
        for label, rows, extra in (
                ("index lists a missing file", ROWS + [(3, "0003-ghost.md", "Ghost")], None),
                ("ADR not in index", ROWS[:1], None),
                ("number mismatches filename", [(5, "0001-first.md", "x"), ROWS[1]], None)):
            with self.subTest(label):
                r = self.decisions_repo()
                r.put("docs/decisions/INDEX.json", index_json(rows))
                commit_at(r, "break index", "2026-10-15T10:00:00+02:00")
                vault = self.mk("v-" + label.replace(" ", "-"))
                rc, out, err, _ = self.write(r, vault=vault)
                self.assertNotEqual(rc, 0)
                self.assertNotIn("Traceback", err)
                self.assertEqual(os.listdir(vault), [])
        r = self.decisions_repo()
        r.put("docs/decisions/INDEX.json", "{not json")
        commit_at(r, "bad json", "2026-10-15T10:00:00+02:00")
        vault = self.mk("v-json")
        rc, out, err, _ = self.write(r, vault=vault)
        self.assertNotEqual(rc, 0)
        self.assertIn("not a valid ADR index", err)
        self.assertEqual(os.listdir(vault), [])


class TestAC2Days(Base053):
    DAYS = (
        ("2026-10-14T21:59:59+00:00", "2026-10-14"),   # 23:59:59 Stockholm
        ("2026-10-14T22:00:00+00:00", "2026-10-15"),   # 00:00:00 Stockholm, still 10-14 in UTC
        ("2026-10-14T22:30:00-08:00", "2026-10-15"),   # 06:30Z on the 15th; the offset's own date is the 14th
        ("2026-12-31T23:30:00+00:00", "2027-01-01"),   # winter time, +01:00
    )

    def test_ac2_stockholm_day_boundaries(self):
        r = self.repo()
        for i, (date, _) in enumerate(self.DAYS):
            r.put("f%d.txt" % i, "x\n")
            commit_at(r, "boundary %d" % i, date)
        rc, out, err, _ = self.write(r)
        self.assertEqual(rc, 0, err)
        files = self.files(self.vault)
        for i, (_, day) in enumerate(self.DAYS):
            self.assertIn("boundary %d" % i, files["Journal/%s.md" % day][0].decode(), self.DAYS[i])
        self.assertNotIn("boundary 1", files["Journal/2026-10-14.md"][0].decode())
        self.assertNotIn("boundary 2", files["Journal/2026-10-14.md"][0].decode())
        self.assertEqual({n for n in files if n.startswith("Journal/")},
                         {"Journal/%s.md" % d for d in expected_journal(r)})

    def test_ac2_only_the_affected_notes_are_rewritten(self):
        r = self.decisions_repo()
        self.assertEqual(self.write(r)[0], 0)
        v0 = self.files(self.vault)
        # a commit on a new day: new day file + the two aggregates, nothing else
        r.put("other.txt", "o\n")
        commit_at(r, "new day", "2026-10-17T09:00:00+02:00")
        rc, out, err, _ = self.write(r)
        self.assertEqual(rc, 0, err)
        v1 = self.files(self.vault)
        changed = {n for n in v1 if n not in v0 or v1[n] != v0[n]}
        self.assertEqual(changed, {"Status.md", "Tasks.md", "Journal/2026-10-17.md"})
        # an edit to one ADR on that same day: that ADR note + its day + aggregates
        r.put("docs/decisions/0002-second.md", ADR2 + "edited\n")
        commit_at(r, "edit adr 2", "2026-10-17T10:00:00+02:00")
        self.assertEqual(self.write(r)[0], 0)
        v2 = self.files(self.vault)
        changed = {n for n in v2 if v2[n] != v1[n]}
        self.assertEqual(changed, {"Status.md", "Tasks.md", "Journal/2026-10-17.md", "ADR/0002-second.md"})
        # an index edit: Decisions.md, not the ADR notes
        r.put("docs/decisions/INDEX.json", index_json([ROWS[0], (2, "0002-second.md", "Renamed")]))
        commit_at(r, "edit index", "2026-10-17T11:00:00+02:00")
        self.assertEqual(self.write(r)[0], 0)
        v3 = self.files(self.vault)
        changed = {n for n in v3 if v3[n] != v2[n]}
        self.assertEqual(changed, {"Status.md", "Tasks.md", "Journal/2026-10-17.md", "Decisions.md"})
        # a rerun with nothing new writes nothing
        rc, out, err, _ = self.write(r)
        self.assertIn("written=0", out)
        self.assertEqual(self.files(self.vault), v3)


class TestAC3AdrFrontmatter(Base053):
    def test_ac3_adr_starting_with_dashes_fails_validation_and_writes_nothing(self):
        for label, text in (("frontmatter", "---\ntitle: x\n---\n# ADR\n"), ("bare rule", "---\n# ADR\n"),
                            ("bom", "﻿---\ntitle: x\n---\n")):
            with self.subTest(label):
                r = self.decisions_repo(adr1=text)
                vault = self.mk("v-" + label.replace(" ", "-"))
                rc, out, err, _ = self.write(r, vault=vault)
                self.assertNotEqual(rc, 0)
                self.assertIn("starts with '---'", err)
                self.assertIn("0001-first.md", err)
                self.assertEqual(os.listdir(vault), [], "nothing written, not even the valid notes")

    def test_ac3_dashes_later_in_the_file_are_fine(self):
        r = self.decisions_repo(adr1="# T\n\n---\n\nrule\n")
        self.assertEqual(self.write(r)[0], 0)


class TestAC4Secrets(Base053):
    def test_ac4_secret_in_adr_or_commit_subject_blocks_the_run(self):
        for pname, secret in tv.secrets().items():
            for where in ("adr", "subject"):
                with self.subTest(pattern=pname, where=where):
                    if where == "adr":
                        r = self.decisions_repo(adr1="# ADR\n\nleaked %s here\n" % secret)
                        note = "ADR/0001-first.md line"
                    else:
                        r = self.decisions_repo(subject_extra=" %s" % secret)
                        note = "Journal/2026-10-14.md line"
                    vault = self.mk("v-%s-%s" % (pname, where))
                    rc, out, err, _ = self.write(r, vault=vault)
                    self.assertNotEqual(rc, 0)
                    self.assertIn(pname, err)
                    self.assertIn(note, err)
                    self.assertNotIn(secret, out + err)
                    self.assertNotIn("Traceback", err)
                    self.assertEqual(os.listdir(vault), [], "the whole run is blocked")


class WorktreeMixin:
    def two_branches(self, r, tid="061"):
        paths = []
        for slug in ("a", "b"):
            path = os.path.join(self.mk("wt-" + slug), tid)
            r.git("worktree", "add", "-q", "-b", "task/%s-%s" % (tid, slug), path, "main")
            r.put("work-%s.txt" % slug, "w\n", cwd=path)
            r.commit("work %s" % slug, cwd=path)
            paths.append(path)
        return paths


class TestAC7DuplicateIds(Base053, WorktreeMixin):
    def test_ac7_main_skips_names_the_conflict_and_task_mode_refuses(self):
        r = self.repo()
        pa, pb = self.two_branches(r)
        # a previous generated note must be left alone
        self.assertEqual(self.write(r, ref="main")[0], 0)
        self.assertNotIn("Tasks/061.md", self.files(self.vault))
        rc, out, err, _ = self.write(r)
        self.assertEqual(rc, 0, err)
        self.assertIn("id_conflicts=1", out)
        self.assertIn("skipped_branch_owned=0", out)
        files = self.files(self.vault)
        self.assertNotIn("Tasks/061.md", files)
        self.assertIn("Tasks/060.md", files)
        status = files["Status.md"][0].decode()
        self.assertIn("## Task id conflicts", status)
        self.assertIn("task/061-a", status.split("## Task id conflicts")[1])
        self.assertIn("task/061-b", status.split("## Task id conflicts")[1])
        # task mode on either branch: non-zero, nothing written
        for path in (pa, pb):
            v = self.mk("v-" + os.path.basename(os.path.dirname(path)))
            rc, out, err, _ = self.run_tool(["write", "--ref", "HEAD"], cwd=path, vault=v)
            self.assertNotEqual(rc, 0)
            self.assertIn("id conflict", err)
            self.assertEqual(os.listdir(v), [])

    def test_ac7_main_leaves_an_existing_note_untouched_and_conflict_clears(self):
        r = self.repo()
        pa, pb = self.two_branches(r)
        self.assertEqual(self.write(r)[0], 0)
        self.assertEqual(self.run_tool(["write", "--ref", "HEAD"], cwd=pa, vault=self.mk("vx"))[0] != 0, True)
        os.makedirs(os.path.join(self.vault, "Tasks"), exist_ok=True)
        keep = b"---\ngenerated: true\n---\nold generated note\n"
        open(os.path.join(self.vault, "Tasks", "061.md"), "wb").write(keep)
        self.assertEqual(self.write(r)[0], 0)
        self.assertEqual(open(os.path.join(self.vault, "Tasks", "061.md"), "rb").read(), keep)
        # one branch deleted: the id has a single owner again, task mode works on the survivor
        r.git("worktree", "remove", "--force", pb)
        r.git("branch", "-D", "task/061-b")
        rc, out, err, _ = self.run_tool(["write", "--ref", "HEAD"], cwd=pa, vault=self.mk("vy"))
        self.assertEqual(rc, 0, err)
        rc, out, err, _ = self.write(r)
        self.assertIn("id_conflicts=0", out)
        self.assertIn("skipped_branch_owned=1", out)


class TestAC8NonRegular(Base053):
    def snapshot(self):
        return sorted((os.path.relpath(os.path.join(d, n), self.vault), os.lstat(os.path.join(d, n)).st_mode)
                      for d, ds, fs in os.walk(self.vault) for n in ds + fs)

    def test_ac8_symlink_target_is_refused_without_opening_it(self):
        for label, content in (("hand", b"# hand written\n"), ("generated", b"---\ngenerated: true\n---\nkeep\n")):
            with self.subTest(label):
                r = self.repo()
                vault = self.mk("v-" + label)
                self.vault = vault
                hand = os.path.join(vault, "hand.md")
                open(hand, "wb").write(content)
                os.symlink(hand, os.path.join(vault, "Status.md"))
                before = self.snapshot()
                rc, out, err, ev = self.run_tool(["write", "--ref", "main"], cwd=r.path, vault=vault, audit=True)
                self.assertNotEqual(rc, 0)
                self.assertIn("not a regular file", err)
                self.assertEqual(self.snapshot(), before)
                self.assertEqual(open(hand, "rb").read(), content)
                self.assert_nothing_opened_in(ev, vault)

    def test_ac8_fifo_directory_and_dangling_link(self):
        for label in ("fifo", "dir", "dangling", "journal-fifo"):
            with self.subTest(label):
                r = self.repo()
                vault = self.mk("v-" + label)
                self.vault = vault
                if label == "fifo":
                    os.mkfifo(os.path.join(vault, "Gotchas.md"))
                elif label == "dir":
                    os.mkdir(os.path.join(vault, "Commands.md"))
                elif label == "dangling":
                    os.symlink(os.path.join(vault, "nowhere.md"), os.path.join(vault, "Tasks.md"))
                else:
                    os.mkdir(os.path.join(vault, "Journal"))
                    os.mkfifo(os.path.join(vault, "Journal", "2026-10-14.md"))
                before = self.snapshot()
                rc, out, err, ev = self.run_timed(["write", "--ref", "main"], cwd=r.path, audit=True)
                self.assertNotEqual(rc, 0, label)
                self.assertIn("not a regular file", err)
                self.assertEqual(self.snapshot(), before, "zero files written")
                self.assertEqual([e for e in ev if e[0] == "open" and e[1].startswith(vault)], [])


class TestStatic053(unittest.TestCase):
    def test_no_secret_shaped_strings_in_053_tests(self):
        src = open(os.path.abspath(__file__), encoding="utf-8").read()
        self.assertIn("tv.secrets()", src)
        for rx in (r"gh[pousr]_[A-Za-z0-9]{36}", r"github_pat_[A-Za-z0-9_]{82}", r"-----BEGIN [A-Z ]*PRIVATE KEY-----",
                   r"untrusted comment: " + r"minisign encrypted secret key", r"sk-ant-[A-Za-z0-9_-]{32,}",
                   r"(AKIA|ASIA)[A-Z0-9]{16}"):
            self.assertIsNone(re.search(rx, src), rx)


if __name__ == "__main__":
    unittest.main()
