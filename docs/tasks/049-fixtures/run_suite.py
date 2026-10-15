#!/usr/bin/env python3
"""Task 049 check runner.  Pipes JSON fixtures into the hook scripts of a TREE (a repo checkout or a scratch copy)
and prints one line per check:  'ok: GROUP desc'  or  'FAIL: GROUP desc (detail)'.  Never executes a fixture command:
the fixtures are only ever text inside JSON.  Temp repos live under a temp dir and the builder refuses any other path.
Usage: run_suite.py --tree DIR   (exit 0 only if every check is green)"""
import argparse, concurrent.futures as cf, datetime, json, os, shutil, stat, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
os.environ["PYTHONDONTWRITEBYTECODE"] = "1"
results = []  # (group, ok, desc, detail)


def rec(group, ok, desc, detail=""):
    results.append((group, bool(ok), desc, detail))


def guard_tmp():
    t = os.path.realpath(os.environ.get("TMPDIR") or "/tmp")
    if t == "/mnt" or t.startswith("/mnt/") or not os.path.isabs(t):
        sys.exit("refusing to run: TMPDIR is under /mnt or not absolute")
    return t


def run(argv, stdin=b"", env=None, cwd=None, timeout=30):
    try:
        p = subprocess.run(argv, input=stdin, env=env, cwd=cwd, capture_output=True, timeout=timeout)
        return p.returncode, p.stdout.decode("utf-8", "replace"), p.stderr.decode("utf-8", "replace")
    except subprocess.TimeoutExpired:
        return 124, "", "timeout"
    except OSError as exc:
        return 126, "", "cannot run: %s" % exc


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True)
    tree = os.path.realpath(ap.parse_args().tree)
    base = guard_tmp()
    tmp = os.path.realpath(tempfile.mkdtemp(prefix="wom049-", dir=base))
    try:
        suite(tree, tmp)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    bad = sorted({g for g, ok, _, _ in results if not ok})
    for g, ok, d, det in results:
        print("%s: %s %s%s" % ("ok" if ok else "FAIL", g, d, (" (%s)" % det) if det and not ok else ""))
    print("TOTAL %d checks, %d red" % (len(results), sum(1 for r in results if not r[1])))
    print("RED-GROUPS: " + ",".join(bad))
    return 1 if bad else 0


GITENV = {}


def git(tmp, *a, cwd):
    real = os.path.realpath(cwd)
    if not (real + os.sep).startswith(tmp + os.sep):  # the builder refuses any git dir outside the temp dir
        raise SystemExit("builder refuses %s: not under %s" % (real, tmp))
    p = subprocess.run(["git", *a], cwd=cwd, env=GITENV, capture_output=True)
    if p.returncode:
        raise SystemExit("git %s failed: %s" % (a, p.stderr.decode()))


def build_repos(tmp):
    r = {}
    for name, branch in (("main", None), ("task", "task/049-x"), ("detached", "DETACH")):
        d = os.path.join(tmp, "repos", name)
        os.makedirs(d)
        git(tmp, "init", "-q", "-b", "main", d, cwd=d)
        open(os.path.join(d, "f"), "w").write("x\n")
        git(tmp, "add", "f", cwd=d)
        git(tmp, "commit", "-q", "-m", "seed", cwd=d)
        if branch == "DETACH":
            git(tmp, "checkout", "-q", "--detach", cwd=d)
        elif branch:
            git(tmp, "checkout", "-q", "-b", branch, cwd=d)
        r[name] = d
    r["other"] = os.path.join(tmp, "not-a-repo")
    os.makedirs(r["other"])
    return r


def make_home(tmp, name, kind, vault):
    h = os.path.join(tmp, "homes", name)
    os.makedirs(os.path.join(h, ".config"), exist_ok=True)
    if kind in ("plain", "drive"):
        os.makedirs(os.path.join(h, ".config", "wom"), exist_ok=True)
        with open(os.path.join(h, ".config", "wom", "vault-path"), "w") as f:
            f.write((vault if kind == "plain" else "/mnt/d/WomVault") + "\n")
    return h


def hook_env(home, extra=None, path=None):
    e = {"PATH": path if path is not None else os.environ["PATH"], "HOME": home, "LC_ALL": "C.UTF-8",
         "PYTHONDONTWRITEBYTECODE": "1"}
    e.update(extra or {})
    return e


def suite(tree, tmp):
    GITENV.update({"PATH": os.environ["PATH"], "HOME": tmp, "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_SYSTEM": "/dev/null",
                   "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@example.invalid", "GIT_COMMITTER_NAME": "t",
                   "GIT_COMMITTER_EMAIL": "t@example.invalid"})
    hook = os.path.join(tree, ".claude", "hooks", "git-guard.sh")
    repos = build_repos(tmp)
    vault = os.path.join(tmp, "vault-plain")
    sub = {"@MAIN@": repos["main"], "@TASK@": repos["task"], "@DETACHED@": repos["detached"], "@OTHER@": repos["other"],
           "@VAULT@": vault, "@VAULT_UP@": vault.upper(), "@VAULTENV@": os.path.join(tmp, "vault-env")}

    def expand(s):
        for k, v in sub.items():
            s = s.replace(k, v)
        return s

    cases = [json.loads(l) for l in open(os.path.join(HERE, "cases.jsonl")) if l.strip()]

    def one(c):
        home = make_home(tmp, c["id"], c["home"], vault)
        payload = {"session_id": "s", "hook_event_name": "PreToolUse", "tool_name": "Bash",
                   "tool_input": {"command": expand(c["command"])}, "cwd": expand(c["cwd"])}
        if "agent_type" in c:
            payload["agent_type"] = c["agent_type"]
        env = hook_env(home, {k: expand(v) for k, v in c.get("env", {}).items()})
        rc, out, err = run([hook], json.dumps(payload).encode(), env)
        ok, why = rc == c["want"], []
        if not ok:
            why.append("exit %s, wanted %s: %s" % (rc, c["want"], err.strip()[:160]))
        if ok and c.get("stderr") and c["stderr"] not in err:
            ok = False
            why.append("stderr lacks %r: %s" % (c["stderr"], err.strip()[:160]))
        logp = os.path.join(home, ".config", "wom", "git-guard.log")
        log = open(logp).read() if os.path.exists(logp) else ""
        if ok and c.get("log_has") and c["log_has"] not in log:
            ok = False
            why.append("log lacks %r" % c["log_has"])
        logged = bool(log.strip()) and (" block " in log if c["want"] == 2 else " allow " in log or " skip " in log)
        return c, ok, "; ".join(why), logged

    with cf.ThreadPoolExecutor(8) as ex:
        outs = list(ex.map(one, cases))
    for c, ok, why, _ in outs:
        rec(c["group"], ok, "%s %r%s" % (c["id"], c["command"][:60], " [agent_type=%r]" % c["agent_type"] if "agent_type" in c else ""), why)
    unlogged = [c["id"] for c, _, _, lg in outs if not lg]
    rec("LOG-lines", not unlogged, "every decision (%d fixtures) left a block/allow line in git-guard.log" % len(outs),
        "no log line for %s" % unlogged[:5])
    ac5(tree, tmp, hook)
    ac6(tree, tmp, hook, repos)
    ac7(tree, tmp)
    bytecode = [os.path.join(dp, f) for dp, _, fs in os.walk(tree) for f in fs if f.endswith(".pyc")]
    rec("HYGIENE-pyc", not bytecode, "no .pyc file in the tree under test", str(bytecode[:3]))


def payload(cmd, **kw):
    d = {"tool_name": "Bash", "tool_input": {"command": cmd}, "cwd": "/"}
    d.update(kw)
    return json.dumps(d).encode()


def ac5(tree, tmp, hook):
    home = make_home(tmp, "ac5", "none", "")
    env = hook_env(home)
    for desc, data, grp in (("invalid JSON text", b"this is not json", "AC5-json"), ("truncated JSON", b'{"tool_name": "Bash"', "AC5-json"),
                            ("empty stdin", b"", "AC5-empty"), ("whitespace-only stdin", b"  \n", "AC5-empty"),
                            ("Bash call with no command", b'{"tool_name":"Bash","tool_input":{}}', "AC5-no-command"),
                            ("no tool_input at all", b'{"tool_name":"Bash"}', "AC5-no-command"),
                            ("command is not a string", b'{"tool_name":"Bash","tool_input":{"command":5}}', "AC5-no-command"),
                            ("JSON that is not an object", b"[]", "AC5-no-command")):
        rc, _, err = run([hook], data, env)
        rec(grp, rc == 2, "%s -> exit 2" % desc, "exit %s: %s" % (rc, err.strip()[:100]))
    # unwritable log: ~/.config is a regular file, so the log directory cannot be created
    h = os.path.join(tmp, "homes", "nolog"); os.makedirs(h)
    open(os.path.join(h, ".config"), "w").write("not a directory")
    rc, _, err = run([hook], payload("git reset --hard"), hook_env(h))
    rec("AC5-log", rc == 2 and "reset-hard" in err, "an unwritable log does not turn a block into an allow", "exit %s: %s" % (rc, err.strip()[:100]))
    rc, _, err = run([hook], payload("git status"), hook_env(h))
    rec("AC5-log", rc == 0 and "cannot append" in err, "an unwritable log is reported on stderr (and an allow stays an allow)", "exit %s: %s" % (rc, err.strip()[:100]))
    # wrapper fixtures
    wsrc = open(hook).read()
    cases = [("crash", "import sys\nsys.exit(1)\n", 0o755), ("traceback", "raise RuntimeError('boom')\n", 0o755),
             ("signal", "import os, signal\nos.kill(os.getpid(), signal.SIGKILL)\n", 0o755),
             ("missing", None, 0), ("nonexec", "import sys\nsys.exit(0)\n", 0o644), ("nopython", "import sys\nsys.exit(0)\n", 0o755)]
    for name, body, mode in cases:
        d = os.path.join(tmp, "wrap-" + name); os.makedirs(d)
        w = os.path.join(d, "git-guard.sh")
        shutil.copy(hook, w); os.chmod(w, 0o755)
        if body is not None:
            p = os.path.join(d, "git_guard.py")
            open(p, "w").write(body); os.chmod(p, mode)
        path = None
        if name == "nopython":
            empty = os.path.join(tmp, "empty-path"); os.makedirs(empty, exist_ok=True); path = empty
        rc, _, err = run([w], b"{}", hook_env(home, path=path))
        rec("AC5-wrapper-" + name, rc == 2, "wrapper maps the %s case to exit 2" % name, "exit %s: %s" % (rc, err.strip()[:100]))
    for name, code in (("pass0", 0), ("pass2", 2)):
        d = os.path.join(tmp, "wrap-" + name); os.makedirs(d)
        w = os.path.join(d, "git-guard.sh"); shutil.copy(hook, w); os.chmod(w, 0o755)
        p = os.path.join(d, "git_guard.py"); open(p, "w").write("import sys\nsys.exit(%d)\n" % code); os.chmod(p, 0o755)
        rc, _, err = run([w], b"{}", hook_env(home))
        rec("AC5-wrapper-pass", rc == code, "wrapper lets a clean %d through" % code, "exit %s" % rc)


def ac6(tree, tmp, hook, repos):
    sp = os.path.join(tree, ".claude", "settings.json")
    try:
        d = json.load(open(sp))
        rec("AC6-json", True, "settings.json is valid JSON")
    except (OSError, ValueError) as exc:
        rec("AC6-json", False, "settings.json is valid JSON", str(exc)); return
    pre = d.get("hooks", {}).get("PreToolUse", [])
    bash = [e for e in pre if "Bash" in e.get("matcher", "").split("|")]
    rec("AC6-matcher", len(bash) >= 1, "a PreToolUse entry has the matcher Bash", str([e.get("matcher") for e in pre]))
    cmds = [h["command"] for e in bash for h in e.get("hooks", []) if h.get("type") == "command" and "git-guard" in h.get("command", "")]
    rec("AC6-matcher", len(cmds) == 1, "...and names exactly one git-guard command", str(cmds))
    cmd = cmds[0] if cmds else "false"
    p = cmd.replace('"', "").replace("$CLAUDE_PROJECT_DIR", tree)
    rec("AC6-exists", os.path.isfile(p), "the command path exists", p)
    rec("AC6-exists", os.access(p, os.X_OK), "...and is executable", p)
    home = make_home(tmp, "ac6", "none", "")
    env = hook_env(home, {"CLAUDE_PROJECT_DIR": tree})
    rc, _, err = run(["sh", "-c", cmd], payload("git push --force"), env)
    rec("AC6-run", rc == 2, "the exact settings command string blocks git push --force (exit 2)", "exit %s: %s" % (rc, err.strip()[:100]))
    rc, _, err = run(["sh", "-c", cmd], payload("git status"), env)
    rec("AC6-run", rc == 0, "...and allows git status (exit 0)", "exit %s: %s" % (rc, err.strip()[:100]))
    vg = [h["command"] for e in pre for h in e.get("hooks", []) if "vault-guard" in h.get("command", "")]
    rec("AC6-others", bool(vg) and any("Write" in e.get("matcher", "") for e in pre), "task 052's vault-guard entry is still present", str(vg))
    rec("AC6-others", "CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH" in d.get("env", {}), "task 048's env entry is still present")


def ac7(tree, tmp):
    sh = os.path.join(tree, "tools", "manager", "check-log-entry.sh")
    fx = os.path.join(HERE, "log-fixture.md")
    today = datetime.date.today().isoformat()
    env = {"PATH": os.environ["PATH"], "LC_ALL": "C.UTF-8"}

    def cl(*a):
        return run([sh, *a], env=env)

    def scratch(name, extra="", src=fx):
        p = os.path.join(tmp, "log-" + name + ".md")
        shutil.copy(src, p)
        if extra:
            open(p, "a").write(extra)
        return p
    rc, out, err = cl("count", fx)
    rec("AC7-count", rc == 0 and out.strip() == "3", "count on the fixture log prints 3 (the dated line before the section and the continuation line are not entries)", "exit %s out %r" % (rc, out))
    real = os.path.join(REPO, "docs", "tasks", "048-doctrine-arcane.md")
    rc, out, err = cl("count", real)
    rec("AC7-count", rc == 0 and out.strip().isdigit() and int(out) > 0, "count works on a real task file (the title line mentioning 'log' is not taken as the section)", "exit %s out %r" % (rc, out))
    for grp, desc, extra, want in (
            ("AC7-new", "an entry dated today was appended: check exits 0", "- %s new entry\n" % today, 0),
            ("AC7-baseline", "nothing appended: check exits 1", "", 1),
            ("AC7-undated", "only an undated line appended: check exits 1", "- an undated bullet\n", 1),
            ("AC7-future", "an entry dated in the future: check exits 1", "- 2999-01-01 from the future\n", 1),
            ("AC7-baddate", "an entry with an impossible date: check exits 1", "- 2026-02-30 not a day\n", 1)):
        rc, out, err = cl("check", scratch(grp, extra), "3")
        rec(grp, rc == want, desc, "exit %s: %s" % (rc, err.strip()[:100]))
    rc, _, err = cl("check", scratch("base5", "- %s one more\n" % today), "5")
    rec("AC7-baseline", rc == 1, "count 4 against baseline 5: check exits 1", "exit %s" % rc)
    nosec = os.path.join(tmp, "nosection.md"); open(nosec, "w").write("# Task 998: no log here\n\n- 2026-10-01 a bullet\n")
    for a in (("count", nosec), ("check", nosec, "0")):
        rc, _, err = cl(*a)
        rec("AC7-no-section", rc == 2, "%s on a task file with no log section exits 2" % a[0], "exit %s" % rc)
    for a in (("count", os.path.join(tmp, "nope.md")), ("check", os.path.join(tmp, "nope.md"), "0")):
        rc, _, err = cl(*a)
        rec("AC7-missing-file", rc == 2, "%s on a missing file exits 2" % a[0], "exit %s" % rc)
    for a, d in (((), "no arguments"), (("frobnicate", fx), "unknown mode"), (("check", fx), "check without a baseline"), (("check", fx, "abc"), "non-numeric baseline")):
        rc, _, err = cl(*a)
        rec("AC7-usage", rc == 2, "usage error (%s) exits 2" % d, "exit %s" % rc)


if __name__ == "__main__":
    sys.exit(main())
