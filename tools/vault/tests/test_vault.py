"""Black-box tests for tools/vault/wom_vault.py (task 051).  Run via docs/tasks/051-verify.sh.

Every test builds its own temporary git repo and vault under WOM051_TMP (or a fresh mkdtemp
prefixed wom051-).  Nothing here touches a real vault, /mnt or ~/.config/wom: the child's HOME is
a temp dir and WOM_VAULT_TEST=1 is set (except in the cases that prove the refusal of non-test use).
Secret-shaped strings are assembled at runtime and never committed.
"""
import fcntl
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.environ.get("WOM_VAULT_SCRIPT") or os.path.join(os.path.dirname(HERE), "wom_vault.py")
AUDIT = os.path.join(HERE, "audit_run.py")
REPO_ROOT = subprocess.run(["git", "-C", HERE, "rev-parse", "--show-toplevel"], capture_output=True,
                           text=True, check=True).stdout.strip()
PINNED = "3e2b6ef"


def safe_root():
    """AC12: the temp root must be under the temp dir, not under /mnt and not under the real $HOME."""
    root = os.environ.get("WOM051_TMP") or tempfile.mkdtemp(prefix="wom051-")
    real = os.path.realpath(root)
    tmpdir = os.path.realpath(tempfile.gettempdir())
    home = os.path.realpath(os.path.expanduser("~"))
    if not real.startswith(tmpdir + os.sep) or real.startswith("/mnt/") or real == home or real.startswith(home + os.sep):
        raise SystemExit("refusing to run: test root %s is not safely under the temp dir" % real)
    return real


ROOT = safe_root()
_clock = [0]


def git_env(home):
    _clock[0] += 1
    d = "2026-10-14T12:%02d:%02d+02:00" % divmod(_clock[0], 60)
    return {"PATH": os.environ["PATH"], "HOME": home, "GIT_CONFIG_GLOBAL": "/dev/null",
            "GIT_CONFIG_SYSTEM": "/dev/null", "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@example.invalid",
            "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@example.invalid",
            "GIT_AUTHOR_DATE": d, "GIT_COMMITTER_DATE": d, "LC_ALL": "C.UTF-8"}


class Repo:
    def __init__(self, path, home):
        self.path, self.home = path, home

    def git(self, *a, cwd=None):
        p = subprocess.run(["git"] + list(a), cwd=cwd or self.path, env=git_env(self.home),
                           capture_output=True, text=True)
        if p.returncode:
            raise AssertionError("git %s failed: %s" % (a, p.stderr))
        return p.stdout.strip()

    def put(self, rel, text, cwd=None):
        p = os.path.join(cwd or self.path, rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "w", encoding="utf-8", newline="") as fh:
            fh.write(text)

    def commit(self, msg, cwd=None):
        self.git("add", "-A", cwd=cwd)
        self.git("commit", "-q", "-m", msg, cwd=cwd)
        return self.git("rev-parse", "HEAD", cwd=cwd)


MISSION = """# Mission log
## For Ludwig — early (must not appear)
early question
## SESSION 1 — old
old body
## SESSION 2 — newest
new body
```
## SESSION 99 fake heading inside a fence
```
more of session 2
## Other section
other
## For Ludwig — late (must appear)
late question
"""


def task_file(tid, slug, status_line, extra=""):
    return "# Task %s: %s\n\n- **Mission:** x — %s\n%s" % (tid, slug, status_line, extra)


def build_repo(base, ops="ops v1\n"):
    home = os.path.join(base, "home")
    os.makedirs(home)
    path = os.path.join(base, "repo")
    os.makedirs(path)
    r = Repo(path, home)
    r.git("init", "-q", "-b", "main")
    r.put("docs/manager/OPERATIONS.md", ops)
    r.put("docs/manager/COMMANDS.md", "commands v1\n")
    r.put("docs/tasks/MISSION-worldofmodcraft-site-v1-log.md", MISSION)
    r.put("docs/tasks/done/001-old.md", task_file("001", "Old", "**Status:** review"))
    r.put("docs/tasks/060-alpha.md", task_file("060", "Alpha | pipe", "**Status:** spec-approved (Ludwig)"))
    r.put("docs/tasks/061-beta.md", task_file("061", "Beta", "**Status:** spec-approved"))
    r.put("docs/tasks/062-gamma.md", task_file("062", "Gamma", "**Status:** draft"))
    r.put("docs/tasks/063-delta.md", task_file("063", "Delta", "**Status:** done"))
    r.put("docs/tasks/064-eps.md", "# Task 064: Eps\n\nno status here\n")
    r.commit("c1")
    return r


class Base(unittest.TestCase):
    def setUp(self):
        self.base = tempfile.mkdtemp(prefix="t-", dir=ROOT)
        self.addCleanup(shutil.rmtree, self.base, True)
        self.vault = os.path.join(self.base, "vault")
        os.makedirs(self.vault)
        self.home = os.path.join(self.base, "home-run")
        os.makedirs(self.home)

    def repo(self, **kw):
        self.n = getattr(self, "n", 0) + 1
        return build_repo(self.mk("r%d" % self.n), **kw)

    def mk(self, name):
        p = os.path.join(self.base, name)
        os.makedirs(p, exist_ok=True)
        return p

    def run_tool(self, args, cwd, vault="default", test_mode=True, tmpdir=None, audit=False, extra_env=None, home=None):
        env = {"PATH": os.environ["PATH"], "HOME": home or self.home, "LC_ALL": "C.UTF-8",
               "TMPDIR": tmpdir or ROOT, "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_SYSTEM": "/dev/null"}
        v = self.vault if vault == "default" else vault
        if v is not None:
            env["WOM_VAULT"] = v
        if test_mode:
            env["WOM_VAULT_TEST"] = "1"
        cmd = ["python3", "-I"]
        log = os.path.join(self.base, "audit.json")
        if audit:
            env["WOM051_AUDIT_LOG"] = log
            cmd.append(AUDIT)
        cmd += [SCRIPT] + args
        env.update(extra_env or {})
        p = subprocess.run(cmd, cwd=cwd, env=env, capture_output=True, text=True, timeout=120)
        events = json.load(open(log)) if audit else None
        return p.returncode, p.stdout, p.stderr, events

    def write(self, repo, ref="main", **kw):
        return self.run_tool(["write", "--ref", ref], cwd=repo.path, **kw)

    @staticmethod
    def files(vault):
        out = {}
        for d, dirs, fs in os.walk(vault):
            for f in fs:
                p = os.path.join(d, f)
                st = os.lstat(p)
                out[os.path.relpath(p, vault)] = (open(p, "rb").read(), st.st_mtime_ns)
        return out

    @staticmethod
    def dirs(vault):
        return sorted(os.path.relpath(os.path.join(d, x), vault) for d, ds, _ in os.walk(vault) for x in ds)

    @staticmethod
    def fm(text):
        m = re.match(r"---\n(.*?)\n---\n", text, re.S)
        return dict(l.split(": ", 1) for l in m.group(1).split("\n"))

    def assert_nothing_opened_in(self, events, vault):
        bad = [e for e in events if e[1].startswith(vault) or e[1].startswith(os.path.realpath(vault))]
        self.assertEqual(bad, [], "the vault must not be touched")


class TestAC1Projection(Base):
    def test_ac1_note_set_and_frontmatter(self):
        r = self.repo()
        vault = os.path.join(self.base, "välv ö ünï")
        os.makedirs(vault)
        rc, out, err, _ = self.write(r, vault=vault)
        self.assertEqual(rc, 0, err)
        files = self.files(vault)
        want = {"Status.md", "Tasks.md", "Gotchas.md", "Commands.md", "Mission Log.md"} | {
            "Tasks/%s.md" % i for i in ("001", "060", "061", "062", "063", "064")}
        self.assertEqual(set(files), want)
        head = r.git("rev-parse", "main")
        single = {"Gotchas.md": "docs/manager/OPERATIONS.md", "Commands.md": "docs/manager/COMMANDS.md",
                  "Mission Log.md": "docs/tasks/MISSION-worldofmodcraft-site-v1-log.md",
                  "Tasks/060.md": "docs/tasks/060-alpha.md", "Tasks/001.md": "docs/tasks/done/001-old.md"}
        for name, src in single.items():
            text = files[name][0].decode("utf-8")
            fm = self.fm(text)
            self.assertEqual(fm["generated"], "true")
            self.assertEqual(fm["source_ref"], "main")
            self.assertEqual(fm["source_path"], src)
            self.assertEqual(fm["source_commit"], r.git("log", "-1", "--format=%H", "main", "--", src))
            self.assertEqual(fm["updated"], r.git("log", "-1", "--format=%cI", fm["source_commit"]))
            self.assertNotIn("\r", text)
        for name in ("Status.md", "Tasks.md"):
            self.assertEqual(self.fm(files[name][0].decode())["source_commit"], head)
        self.assertEqual(files["Gotchas.md"][0].decode().split("---\n\n", 1)[1], "ops v1\n")

    def test_ac1_status_content(self):
        r = self.repo()
        self.assertEqual(self.write(r)[0], 0)
        st = self.files(self.vault)["Status.md"][0].decode()
        self.assertIn("## SESSION 2 — newest", st)
        self.assertIn("## SESSION 99 fake heading inside a fence", st)  # inside session 2, verbatim
        self.assertIn("more of session 2", st)
        self.assertNotIn("SESSION 1", st)
        self.assertNotIn("early question", st)
        self.assertIn("late question", st)
        self.assertNotIn("other\n", st.split("## Open tasks")[0])
        table = st.split("## Open tasks")[1]
        for tid in ("060", "061", "062", "064"):
            self.assertIn("[[Tasks/%s]]" % tid, table)
        for tid in ("001", "063"):
            self.assertNotIn("[[Tasks/%s]]" % tid, table)
        self.assertIn("Alpha \\| pipe", table)
        tk = self.files(self.vault)["Tasks.md"][0].decode()
        self.assertIn("| 064 | Task 064: Eps | status unparsed | [[Tasks/064]] |", tk)

    def test_ac1_summary_counts_unparsed(self):
        r = self.repo()
        rc, out, err, _ = self.write(r)
        self.assertIn("status_unparsed=1", out)


class TestAC2Idempotence(Base):
    def test_ac2_second_run_writes_nothing_and_minimal_rewrite(self):
        r = self.repo()
        self.assertEqual(self.write(r)[0], 0)
        before = self.files(self.vault)
        rc, out, err, _ = self.write(r)
        self.assertEqual(rc, 0)
        self.assertIn("written=0", out)
        self.assertEqual(self.files(self.vault), before)  # bytes and mtime_ns
        r.put("docs/manager/OPERATIONS.md", "ops v2\n")
        r.commit("ops change")
        rc, out, err, _ = self.write(r)
        after = self.files(self.vault)
        changed = {n for n in after if after[n] != before[n]}
        self.assertIn("Gotchas.md", changed)
        self.assertTrue(changed <= {"Gotchas.md", "Status.md", "Tasks.md"}, changed)
        for n in ("Commands.md", "Mission Log.md", "Tasks/060.md", "Tasks/001.md"):
            self.assertEqual(after[n][1], before[n][1], n + " must keep its mtime_ns")


class TestAC3Guards(Base):
    def test_ac3_unmarked_target_refused(self):
        r = self.repo()
        hand = b"# my own status\n"
        open(os.path.join(self.vault, "Status.md"), "wb").write(hand)
        before = self.files(self.vault)
        rc, out, err, _ = self.write(r)
        self.assertNotEqual(rc, 0)
        self.assertIn("generated: true", err)
        self.assertEqual(self.files(self.vault), before)
        self.assertEqual(self.dirs(self.vault), [])

    def test_ac3_generated_false_refused(self):
        r = self.repo()
        open(os.path.join(self.vault, "Gotchas.md"), "w").write("---\ngenerated: false\n---\nx\n")
        before = self.files(self.vault)
        self.assertNotEqual(self.write(r)[0], 0)
        self.assertEqual(self.files(self.vault), before)

    def test_ac3_two_phase_nothing_written_when_last_target_invalid(self):
        r = self.repo()
        os.makedirs(os.path.join(self.vault, "Tasks"))
        open(os.path.join(self.vault, "Tasks", "064.md"), "w").write("hand written\n")  # sorts last
        before = self.files(self.vault)
        rc, out, err, _ = self.write(r)
        self.assertNotEqual(rc, 0)
        self.assertEqual(self.files(self.vault), before, "earlier valid notes must not have been written")

    def test_ac3_forbidden_names_rejected_before_any_open(self):
        r = self.repo()
        names = ["Agent Session Handover Prompt.md", "MINISIGN.md", "Olika Sessioner.md"]
        for n in names:
            open(os.path.join(self.vault, n), "w").write("hand written %s\n" % n)
        before = self.files(self.vault)
        for n in names + [["Status.md", "x/" + names[1]][1], "minisign.MD"]:
            rc, out, err, ev = self.run_tool(["write", "--ref", "main", "--note", n], cwd=r.path, audit=True)
            self.assertNotEqual(rc, 0, n)
            self.assertIn("forbidden target name", err, n)
            self.assert_nothing_opened_in(ev, self.vault)
        rc, out, err, ev = self.run_tool(["write", "--ref", "main", "--note", "Status.md", "--note", names[0]],
                                         cwd=r.path, audit=True)
        self.assertNotEqual(rc, 0)
        self.assert_nothing_opened_in(ev, self.vault)
        self.assertEqual(self.files(self.vault), before)

    def test_ac3_audit_sees_opens_in_a_normal_run(self):
        """Control: the audit hook is not blind.  A successful run opens planned targets in the vault."""
        r = self.repo()
        rc, out, err, ev = self.write(r, audit=True)
        self.assertEqual(rc, 0, err)
        opened = [e[1] for e in ev if e[0] == "open" and e[1].startswith(self.vault)]
        self.assertTrue(any(p.endswith("Status.md.%d.wom-tmp" % 0) or ".wom-tmp" in p for p in opened), opened)
        for p in opened:
            self.assertTrue(os.path.basename(p).startswith(".") or os.path.relpath(p, self.vault) in
                            {"Status.md", "Tasks.md", "Gotchas.md", "Commands.md", "Mission Log.md"} or
                            re.match(r"Tasks/\d{3}\.md$", os.path.relpath(p, self.vault)), p)


def secrets():
    return {
        "github-token": "gh" + "p_" + "aB3dE5gH7jK9mN1pQ3sT5vX7zA9cD1fG3hJ5",
        "github-fine-grained-pat": "github" + "_pat_" + "a1B2c3D4e5" * 8 + "_x",
        "private-key-pem": "-----BEGIN " + "OPENSSH PRIVATE" + " KEY-----",
        "minisign-secret-key": "untrusted comment: " + "minisign encrypted" + " secret key",
        "anthropic-api-key": "sk-ant-" + "api03-" + "Zy9x" * 8,
        "aws-access-key": "AK" + "IA" + "ABCD1234EFGH5678",
    }


class TestAC4Secrets(Base):
    def test_ac4_each_pattern_blocks_everything(self):
        for pname, secret in secrets().items():
            with self.subTest(pattern=pname):
                self.assertEqual(len(secret) >= 20, True)
                r = self.repo(ops="before %s after\n" % secret)
                os.remove(os.path.join(r.path, "docs/manager/OPERATIONS.md"))  # working tree must not matter
                vault = self.mk("v-" + pname)
                rc, out, err, _ = self.write(r, vault=vault)
                self.assertNotEqual(rc, 0)
                self.assertIn(pname, err)
                self.assertIn("Gotchas.md line", err)
                self.assertEqual(os.listdir(vault), [])
                for d, _, fs in os.walk(self.base):
                    for f in fs:
                        self.assertNotIn(secret.encode(), open(os.path.join(d, f), "rb").read(), f)
                self.assertNotIn(secret, out + err)
                self.assertNotIn("Traceback", err)

    def test_ac4_bare_prefix_in_prose_is_not_a_hit(self):
        r = self.repo(ops="mentions github" + "_pat_ and ghp" + "_ and sk-ant" + "- as prefixes only\n")
        rc, out, err, _ = self.write(r)
        self.assertEqual(rc, 0, err)

    def test_ac4_positive_control_pinned_commit(self):
        have = subprocess.run(["git", "-C", REPO_ROOT, "cat-file", "-t", PINNED], capture_output=True, text=True)
        self.assertEqual(have.stdout.strip(), "commit", "pinned commit %s must exist in this clone" % PINNED)
        clone = os.path.join(self.mk("ctrl"), "c")
        env = git_env(self.home)
        subprocess.run(["git", "clone", "-q", REPO_ROOT, clone], env=env, check=True, capture_output=True)
        r = Repo(clone, self.home)
        r.git("checkout", "-q", "-B", "main", PINNED)
        commands = subprocess.run(["git", "-C", REPO_ROOT, "show", "HEAD:docs/manager/COMMANDS.md"],
                                  capture_output=True, text=True, check=True).stdout
        r.put("docs/manager/COMMANDS.md", commands)  # absent at the pin; sources are otherwise the pin's
        r.commit("control: add COMMANDS.md")
        rc, out, err, _ = self.write(r)
        self.assertEqual(rc, 0, err)
        files = self.files(self.vault)
        self.assertGreater(len(files), 30)
        blob = b"".join(v[0] for v in files.values())
        self.assertIn(b"github_pat_", blob, "control must exercise the bare-prefix prose")


class TestAC5Vaults(Base):
    def assert_refused(self, vault, snapshot_roots=(), **kw):
        r = self.repo()
        before = sorted(os.path.join(d, x) for d, ds, fs in os.walk(self.base) for x in ds + fs
                        if not os.path.join(d, x).startswith(r.path))
        rc, out, err, _ = self.write(r, vault=vault, **kw)
        after = sorted(os.path.join(d, x) for d, ds, fs in os.walk(self.base) for x in ds + fs
                       if not os.path.join(d, x).startswith(r.path))
        self.assertNotEqual(rc, 0, out)
        self.assertEqual(before, after, "nothing may be created")
        return err

    def test_ac5_unresolvable_no_env_no_config(self):
        self.assert_refused(None, test_mode=False)

    def test_ac5_relative(self):
        self.assert_refused("relative/vault")

    def test_ac5_missing(self):
        self.assert_refused(os.path.join(self.base, "nope"))

    def test_ac5_not_a_directory(self):
        f = os.path.join(self.base, "afile")
        open(f, "w").write("x")
        self.assert_refused(f)

    def test_ac5_vault_symlink(self):
        link = os.path.join(self.base, "vlink")
        os.symlink(self.vault, link)
        err = self.assert_refused(link)
        self.assertIn("symlink", err)

    def test_ac5_testmode_requires_env_and_ignores_config(self):
        cfgdir = os.path.join(self.home, ".config", "wom")
        os.makedirs(cfgdir)
        open(os.path.join(cfgdir, "vault-path"), "w").write(self.vault + "\n")
        err = self.assert_refused(None)
        self.assertIn("requires WOM_VAULT", err)
        self.assertEqual(os.listdir(self.vault), [])

    def test_ac5_testmode_vault_outside_tmpdir(self):
        tmpdir = self.mk("tmpdir")
        err = self.assert_refused(self.vault, tmpdir=tmpdir)
        self.assertIn("outside the temporary directory", err)

    def test_ac5_nontest_refuses_tmp(self):
        err = self.assert_refused(self.vault, test_mode=False)
        self.assertIn("only allowed in test mode", err)

    def test_ac5_containment_symlinked_subdir(self):
        r = self.repo()
        outside = self.mk("outside")
        os.symlink(outside, os.path.join(self.vault, "Tasks"))
        rc, out, err, _ = self.write(r)
        self.assertNotEqual(rc, 0)
        self.assertIn("outside the vault", err)
        self.assertEqual(os.listdir(outside), [])
        self.assertEqual(os.listdir(self.vault), ["Tasks"])

    def test_ac5_containment_symlinked_target(self):
        r = self.repo()
        outside = self.mk("outside")
        victim = os.path.join(outside, "victim.md")
        open(victim, "w").write("---\ngenerated: true\n---\nkeep\n")
        os.symlink(victim, os.path.join(self.vault, "Status.md"))
        rc, out, err, _ = self.write(r)
        self.assertNotEqual(rc, 0)
        self.assertEqual(open(victim).read(), "---\ngenerated: true\n---\nkeep\n")
        self.assertEqual(os.listdir(self.vault), ["Status.md"])


class TestAC6Ownership(Base):
    def wt(self, r, tid, slug, status=None, log=True):
        path = os.path.join(self.mk("wt"), tid)
        r.git("worktree", "add", "-q", "-b", "task/%s-%s" % (tid, slug), path, "main")
        f = [x for x in os.listdir(os.path.join(path, "docs/tasks")) if x.startswith(tid + "-")][0]
        rel = "docs/tasks/" + f
        text = open(os.path.join(path, rel)).read()
        if status:
            text = re.sub(r"\*\*Status:\*\* \S+", "**Status:** " + status, text)
        if log:
            text += "\n---\n# Task %s log\n- first entry\n  continuation\n- second entry\n" % tid
        text += "\nbranch work\n"
        r.put(rel, text, cwd=path)
        r.commit("work on %s" % tid, cwd=path)
        return path

    def test_ac6_task_mode_and_ownership_lifecycle(self):
        r = self.repo()
        path = self.wt(r, "061", "beta-impl", status="in-progress")
        rc, out, err, _ = self.write(r)
        self.assertEqual(rc, 0, err)
        self.assertNotIn("Tasks/061.md", self.files(self.vault))
        self.assertIn("skipped_branch_owned=1", out)
        self.assertIn("task/061-beta-impl", self.files(self.vault)["Tasks.md"][0].decode())
        before_main = self.files(self.vault)
        # task mode: only Tasks/061.md
        vault2 = self.mk("vault2")
        rc, out, err, _ = self.run_tool(["write", "--ref", "HEAD"], cwd=path, vault=vault2)
        self.assertEqual(rc, 0, err)
        self.assertEqual(set(self.files(vault2)), {"Tasks/061.md"})
        note = self.files(vault2)["Tasks/061.md"][0].decode()
        self.assertIn("task/061-beta-impl", note)
        self.assertIn("Status: in-progress", note)
        self.assertIn("- second entry", note)
        self.assertNotIn("continuation", note)
        self.assertIn("work on 061", note)
        self.assertEqual(self.fm(note)["source_ref"], "task/061-beta-impl")
        # same vault: main run skips it and leaves it alone
        shutil.copytree(vault2, self.vault, dirs_exist_ok=True)
        t_before = self.files(self.vault)["Tasks/061.md"]
        self.assertEqual(self.write(r)[0], 0)
        self.assertEqual(self.files(self.vault)["Tasks/061.md"], t_before)
        # merge: main owns it
        r.git("merge", "-q", "--no-ff", "-m", "merge 061", "task/061-beta-impl")
        rc, out, err, _ = self.write(r)
        self.assertEqual(rc, 0, err)
        merged = self.files(self.vault)["Tasks/061.md"][0].decode()
        self.assertEqual(self.fm(merged)["source_ref"], "main")
        self.assertIn("Status: in-progress", merged)
        self.assertNotIn("Branch:", merged)
        # task mode on the merged branch is refused
        rc, out, err, _ = self.run_tool(["write", "--ref", "HEAD"], cwd=path, vault=self.mk("vault3"))
        self.assertNotEqual(rc, 0)
        self.assertIn("main owns", err)

    def test_ac6_deleted_unmerged_branch_hands_over(self):
        r = self.repo()
        path = self.wt(r, "062", "gamma-x", status="in-progress")
        self.assertEqual(self.write(r)[0], 0)
        self.assertNotIn("Tasks/062.md", self.files(self.vault))
        r.git("worktree", "remove", "--force", path)
        r.git("branch", "-D", "task/062-gamma-x")
        self.assertEqual(self.write(r)[0], 0)
        note = self.files(self.vault)["Tasks/062.md"][0].decode()
        self.assertEqual(self.fm(note)["source_ref"], "main")
        self.assertIn("Status: draft", note)

    def test_ac6_task_mode_refuses_other_notes_and_other_branches(self):
        r = self.repo()
        path = self.wt(r, "060", "alpha-x", log=False)
        v = self.mk("v")
        rc, out, err, _ = self.run_tool(["write", "--ref", "HEAD", "--note", "Status.md"], cwd=path, vault=v)
        self.assertNotEqual(rc, 0)
        self.assertEqual(os.listdir(v), [])
        rc, out, err, _ = self.run_tool(["write", "--ref", "HEAD"], cwd=r.path, vault=v)  # on main
        self.assertNotEqual(rc, 0)
        self.assertIn("task/NNN", err)
        self.assertEqual(os.listdir(v), [])
        rc, out, err, _ = self.run_tool(["write", "--ref", "HEAD"], cwd=path, vault=v)
        self.assertEqual(rc, 0, err)
        self.assertIn("no log entry", open(os.path.join(v, "Tasks", "060.md")).read())
        self.assertIn("no_log_entry=1", out)


class TestAC7Lock(Base):
    def lockfile(self, r):
        return os.path.join(r.path, ".git", "wom-vault.lock")

    def test_ac7_concurrent_runs_equal_single_run(self):
        r = self.repo()
        ref_vault = self.mk("refvault")
        self.assertEqual(self.write(r, vault=ref_vault)[0], 0)
        procs = []
        for i in range(5):
            env = {"PATH": os.environ["PATH"], "HOME": self.home, "TMPDIR": ROOT, "WOM_VAULT": self.vault,
                   "WOM_VAULT_TEST": "1", "LC_ALL": "C.UTF-8"}
            procs.append(subprocess.Popen(["python3", "-I", SCRIPT, "write", "--ref", "main"], cwd=r.path, env=env,
                                          stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True))
        for p in procs:
            out, err = p.communicate(timeout=60)
            self.assertEqual(p.returncode, 0, err)
        a = {k: v[0] for k, v in self.files(self.vault).items()}
        b = {k: v[0] for k, v in self.files(ref_vault).items()}
        self.assertEqual(a, b)
        self.assertEqual([k for k in a if os.path.basename(k).startswith(".")], [])

    def test_ac7_lock_serializes(self):
        r = self.repo()
        fd = os.open(self.lockfile(r), os.O_RDWR | os.O_CREAT, 0o644)
        fcntl.flock(fd, fcntl.LOCK_EX)
        env = {"PATH": os.environ["PATH"], "HOME": self.home, "TMPDIR": ROOT, "WOM_VAULT": self.vault,
               "WOM_VAULT_TEST": "1", "LC_ALL": "C.UTF-8"}
        p = subprocess.Popen(["python3", "-I", SCRIPT, "write", "--ref", "main"], cwd=r.path, env=env,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            time.sleep(2)
            self.assertIsNone(p.poll(), "the run must wait while the lock is held")
            self.assertEqual(os.listdir(self.vault), [])
        finally:
            fcntl.flock(fd, fcntl.LOCK_UN)
        out, err = p.communicate(timeout=60)
        os.close(fd)
        self.assertEqual(p.returncode, 0, err)
        self.assertIn("Status.md", os.listdir(self.vault))

    def test_ac7_lock_timeout_after_30s(self):
        r = self.repo()
        fd = os.open(self.lockfile(r), os.O_RDWR | os.O_CREAT, 0o644)
        fcntl.flock(fd, fcntl.LOCK_EX)
        try:
            t0 = time.monotonic()
            rc, out, err, _ = self.write(r)
            waited = time.monotonic() - t0
        finally:
            fcntl.flock(fd, fcntl.LOCK_UN)
            os.close(fd)
        self.assertNotEqual(rc, 0)
        self.assertIn("lock timeout", err)
        self.assertGreaterEqual(waited, 29)
        self.assertEqual(os.listdir(self.vault), [])


class TestAC8Stale(Base):
    def test_ac8_stale_generated_note_untouched(self):
        r = self.repo()
        stale = os.path.join(self.vault, "Old Planned Thing.md")
        open(stale, "w").write("---\ngenerated: true\n---\nstale\n")
        os.utime(stale, ns=(1_000_000_000_000_000_000, 1_000_000_000_000_000_000))
        before = (open(stale, "rb").read(), os.lstat(stale).st_mtime_ns)
        for _ in range(2):
            self.assertEqual(self.write(r)[0], 0)
        self.assertEqual((open(stale, "rb").read(), os.lstat(stale).st_mtime_ns), before)


class TestAC9Check(Base):
    def test_ac9_check_detects_changes(self):
        r = self.repo()
        os.makedirs(os.path.join(self.vault, ".obsidian"))
        for n in ("hand a.md", "hand b.md", ".obsidian/app.json"):
            open(os.path.join(self.vault, n), "w").write("one\n")
        bl = os.path.join(self.base, "bl.json")
        rc, out, err, ev = self.run_tool(["check", "--save-baseline", bl], cwd=r.path, audit=True)
        self.assertEqual(rc, 0, err)
        self.assert_nothing_opened_in([e for e in ev if e[0] == "open"], self.vault)
        base = json.load(open(bl))
        self.assertEqual(set(base), {"hand a.md", "hand b.md", ".obsidian/app.json"})
        self.assertEqual(self.run_tool(["check", "--baseline", bl], cwd=r.path, audit=True)[0], 0)
        # planned generated notes appearing is not a difference
        self.assertEqual(self.write(r)[0], 0)
        rc, out, err, ev = self.run_tool(["check", "--baseline", bl], cwd=r.path, audit=True)
        self.assertEqual(rc, 0, out)
        self.assert_nothing_opened_in([e for e in ev if e[0] == "open"], self.vault)
        p = os.path.join(self.vault, "hand a.md")
        open(p, "a").write("more\n")
        rc, out, err, _ = self.run_tool(["check", "--baseline", bl], cwd=r.path)
        self.assertNotEqual(rc, 0)
        self.assertIn("changed: hand a.md", out)
        self.run_tool(["check", "--save-baseline", bl], cwd=r.path)
        open(os.path.join(self.vault, "new.md"), "w").write("x")
        rc, out, err, _ = self.run_tool(["check", "--baseline", bl], cwd=r.path)
        self.assertNotEqual(rc, 0)
        self.assertIn("added: new.md", out)
        self.run_tool(["check", "--save-baseline", bl], cwd=r.path)
        os.remove(os.path.join(self.vault, "hand b.md"))
        rc, out, err, _ = self.run_tool(["check", "--baseline", bl], cwd=r.path)
        self.assertNotEqual(rc, 0)
        self.assertIn("removed: hand b.md", out)


class TestStatic(unittest.TestCase):
    def test_script_never_deletes(self):
        src = open(SCRIPT, encoding="utf-8").read()
        self.assertIn("def atomic_write", src, "control: the pattern search must be looking at the real script")
        bad = re.findall(r"os\.(?:unlink|remove|rmdir|removedirs)|shutil|rmtree|\.unlink\(", src)
        self.assertEqual(bad, [])

    def test_no_secret_shaped_strings_in_tests(self):
        src = open(os.path.join(HERE, "test_vault.py"), encoding="utf-8").read()
        self.assertIn("def secrets", src)
        for rx in (r"gh[pousr]_[A-Za-z0-9]{36}", r"github_pat_[A-Za-z0-9_]{82}", r"-----BEGIN [A-Z ]*PRIVATE KEY-----",
                   r"untrusted comment: " + r"minisign encrypted secret key", r"sk-ant-[A-Za-z0-9_-]{32,}",
                   r"(AKIA|ASIA)[A-Z0-9]{16}"):
            self.assertIsNone(re.search(rx, src), rx)


if __name__ == "__main__":
    unittest.main()
