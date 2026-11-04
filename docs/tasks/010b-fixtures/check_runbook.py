#!/usr/bin/env python3
"""Checks for task 010b on docs/runbooks/first-publish.md. Python standard library only.

    check_runbook.py shape    RUNBOOK
    check_runbook.py cred     RUNBOOK
    check_runbook.py switch   RUNBOOK
    check_runbook.py evidence RUNBOOK LOG
    check_runbook.py observed RUNBOOK FIXTURE_DIR
    check_runbook.py fill     RUNBOOK PLATFORM_ROOT
    check_runbook.py m4       NEW_MANUAL_STEPS BASE_MANUAL_STEPS

Exit 0: the check holds. Exit 1: it does not (one or more lines "FAIL reason" on stdout).
Exit 2: usage error or could not decide. 2 is never a verdict.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

STEP_RE = re.compile(r"^### Step (\d+\.\d+) — ")
FAILS = []


def fail(msg):
    FAILS.append(msg)
    print("FAIL " + msg)


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def steps(text):
    """[(id, [lines])] for every '### Step N.N' section; a section ends at the next ## or ### heading or a rule line."""
    out, cur = [], None
    for line in text.split("\n"):
        m = STEP_RE.match(line)
        if m:
            cur = (m.group(1), [])
            out.append(cur)
            continue
        if cur is not None and (line.startswith("## ") or line.startswith("### ") or line == "---"):
            cur = None
            continue
        if cur is not None:
            cur[1].append(line)
    return out


def fenced(lines):
    """list of fenced blocks (each a list of lines)."""
    blocks, cur = [], None
    for line in lines:
        if line.startswith("```"):
            if cur is None:
                cur = []
            else:
                blocks.append(cur)
                cur = None
        elif cur is not None:
            cur.append(line)
    if cur is not None:
        blocks.append(cur + ["<<UNCLOSED FENCE>>"])
    return blocks


def section(lines, start_re, end_re):
    out, on = [], False
    for line in lines:
        if re.match(start_re, line):
            on = True
            continue
        if on and re.match(end_re, line):
            break
        if on:
            out.append(line)
    return out


def check_shape(rb):
    st = steps(read(rb))
    if len(st) < 20:
        fail(f"only {len(st)} numbered steps found; the search is broken or the runbook is truncated")
    for sid, lines in st:
        idx = {}
        for label in ("Do", "You should see", "This proves"):
            hits = [i for i, l in enumerate(lines) if l.startswith(f"**{label}**")]
            if len(hits) != 1:
                fail(f"step {sid}: expected exactly one '**{label}**' part, found {len(hits)}")
            else:
                idx[label] = hits[0]
        if len(idx) == 3 and not (idx["Do"] < idx["You should see"] < idx["This proves"]):
            fail(f"step {sid}: parts are not in the order Do, You should see, This proves")
        for b in fenced(lines):
            for l in b:
                if l == "<<UNCLOSED FENCE>>":
                    fail(f"step {sid}: a fenced block is not closed")
                elif re.search(r"<[A-Za-z][^<>]*>", l):
                    fail(f"step {sid}: placeholder-like text in a command block: {l.strip()[:80]}")


CRED = [r"gh auth token", r"--show-token", r"GH_TOKEN", r"GITHUB_TOKEN", r"\bghp_[A-Za-z0-9]", r"github_pat_",
        r"BEGIN [A-Z ]*PRIVATE KEY", r"hosts\.yml", r"\.config/gh", r"\.claude/"]


def check_cred(path):
    text = read(path)
    for pat in CRED:
        for n, line in enumerate(text.split("\n"), 1):
            if re.search(pat, line):
                fail(f"line {n}: credential-handling text matches {pat!r}")


def check_switch(rb):
    seq = []
    for n, line in enumerate(read(rb).split("\n"), 1):
        m = re.match(r"^gh auth switch --user (\S+)\s*$", line)
        if m:
            seq.append((n, m.group(1)))
    if len([s for s in seq if s[1] == "mbmludric"]) < 2 or len([s for s in seq if s[1] == "womcraft"]) < 2:
        fail(f"too few account switches found ({seq}); the search is broken or the runbook is truncated")
    state = "womcraft"
    for n, who in seq:
        if who not in ("mbmludric", "womcraft"):
            fail(f"line {n}: switch to unknown account {who}")
        if who == "mbmludric" and state == "mbmludric":
            fail(f"line {n}: second switch to mbmludric before switching back to womcraft")
        state = who
    if state != "womcraft":
        fail("the last switch in the runbook is not back to womcraft")
    if not any(l.startswith("gh auth status") for l in read(rb).split("\n")):
        fail("no 'gh auth status' check line found")


def list_markers(log):
    """per-step list from the 010b log: the block opened by a line containing 'UNVERIFIED-LIST 010b'."""
    lines = read(log).split("\n")
    start = [i for i, l in enumerate(lines) if "UNVERIFIED-LIST 010b" in l]
    if len(start) != 1:
        fail(f"expected exactly one 'UNVERIFIED-LIST 010b' line in the log, found {len(start)}")
        return None
    items = []
    for l in lines[start[0] + 1:]:
        m = re.match(r"^\s+- U\d+ step (\d+\.\d+)\s*$", l)
        if not m:
            break
        items.append(m.group(1))
    return items


def check_evidence(rb, log):
    text = read(rb)
    st = steps(text)
    marks = {}
    for sid, lines in st:
        body = "\n".join(lines)
        marks[sid] = body.count("[UNVERIFIED")
        for m in re.finditer(r"\[UNVERIFIED[^\]]*\]", body):
            if m.group(0) != "[UNVERIFIED — expected, not observed]":
                fail(f"step {sid}: marker is not the exact text: {m.group(0)}")
        gh = any(re.search(r"^(gh |git push)", l) for b in fenced(lines) for l in b)
        if gh and "[NOT REHEARSED]" not in body:
            fail(f"step {sid}: runs gh or git push but carries no [NOT REHEARSED]")
        if sid.startswith("3.") and ("[NOT REHEARSED]" not in body or "008b-3b" not in body):
            fail(f"step {sid}: a write-back step must carry [NOT REHEARSED] and name 008b-3b")
        see = section(lines, r"^\*\*You should see\*\*", r"^\*\*This proves\*\*")
        if not any(l.strip() for l in see):
            fail(f"step {sid}: 'You should see' is empty")
    total = text.count("[UNVERIFIED")
    if total != sum(marks.values()):
        fail(f"{total} [UNVERIFIED markers in the file but {sum(marks.values())} inside numbered steps")
    if total < 10:
        fail(f"only {total} [UNVERIFIED markers; the search is broken")
    listed = list_markers(log)
    if listed is None:
        return
    if len(listed) != total:
        fail(f"runbook has {total} [UNVERIFIED markers, the log lists {len(listed)}")
    for sid in sorted(set(listed) | {s for s, c in marks.items() if c}):
        if listed.count(sid) != marks.get(sid, 0):
            fail(f"step {sid}: runbook has {marks.get(sid, 0)} marker(s), the log lists {listed.count(sid)}")


OBSERVED = ["1.3", "1.4", "1.5", "1.6", "1.7", "1.8", "1.9", "1.10", "1.13", "1.14", "1.15", "2.3", "2.4", "4.2", "5.1"]


def norm(line):
    line = re.sub(r"\b[0-9a-f]{40}\b", "H40", line)
    line = re.sub(r"\b[0-9a-f]{7}\b", "H7", line)
    line = re.sub(r"Initialized empty Git repository in \S+", "Initialized empty Git repository in PATH", line)
    return re.sub(r"\s+", " ", line).strip()


def check_observed(rb, fixdir):
    obs = set()
    n_files = 0
    for name in sorted(os.listdir(fixdir)):
        if name.startswith("rehearsal-") and name.endswith("-observed.txt"):
            n_files += 1
            for l in read(os.path.join(fixdir, name)).split("\n"):
                obs.add(norm(l))
    if n_files < 4:
        fail(f"only {n_files} observation files in {fixdir}")
    st = dict(steps(read(rb)))
    checked = 0
    for sid in OBSERVED:
        if sid not in st:
            fail(f"step {sid} is expected to carry observed text but does not exist")
            continue
        see = section(st[sid], r"^\*\*You should see\*\*", r"^\*\*This proves\*\*")
        for b in fenced(see):
            for l in b:
                if not l.strip():
                    continue
                checked += 1
                if norm(l) not in obs:
                    fail(f"step {sid}: line not found in any observation file: {l.strip()[:90]}")
    if checked < 30:
        fail(f"only {checked} observed lines were compared; the check is vacuous")


def sandbox_run(cmd, home):
    env = {"PATH": os.environ["PATH"], "HOME": home, "LC_ALL": "C.UTF-8", "GIT_CONFIG_GLOBAL": "/dev/null",
           "GIT_CONFIG_SYSTEM": "/dev/null"}
    return subprocess.run(["bash", "-c", cmd], env=env, capture_output=True, text=True, timeout=60)


def check_fill(rb, root):
    st = steps(read(rb))
    cmds = []  # (step, preceding cd line or None, fill line)
    for sid, lines in st:
        for b in fenced(lines):
            cd = None
            for l in b:
                if l.startswith("cd "):
                    cd = l
                if "fill_placeholders.py" in l and l.startswith("python3"):
                    cmds.append((sid, cd, l))
    kinds = set()
    for sid, cd, l in cmds:
        m = re.match(r'^python3 ~/wom-first-publish/fill_placeholders\.py (mod|entry) --account ([A-Za-z0-9-]+)'
                     r'( --commit ("\$\(.+\)"|[0-9a-f]{40}))?( --file \S+)?$', l)
        if not m:
            fail(f"step {sid}: not the C24 form: {l}")
            continue
        kinds.add(m.group(1))
        if m.group(1) == "entry" and not m.group(3):
            fail(f"step {sid}: entry without --commit")
        if m.group(1) == "mod" and m.group(3):
            fail(f"step {sid}: mod with --commit")
    if kinds != {"mod", "entry"}:
        fail(f"expected both a mod and an entry invocation, found {sorted(kinds)}")
    if FAILS:
        return
    tmp = tempfile.mkdtemp(prefix="wom010b-fill-")
    try:
        home = os.path.join(tmp, "home")
        w = os.path.join(home, "wom-first-publish")
        os.makedirs(w)
        shutil.copy(os.path.join(root, "tools/test-mod/fill_placeholders.py"), w)
        shutil.copytree(os.path.join(root, "docs/test-mod/hello-world"), os.path.join(w, "wom-test-hello-world"))
        reg = os.path.join(w, "registry", "mods", "test.hello-world")
        os.makedirs(reg)
        for f in ("entry.json", "page.json"):
            shutil.copy(os.path.join(root, "docs/test-mod/registry-pr", f), reg)
        git_env = ("GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid GIT_COMMITTER_NAME=t "
                   "GIT_COMMITTER_EMAIL=t@example.invalid")
        r = sandbox_run(f"cd ~/wom-first-publish/wom-test-hello-world && git init -q -b main && git add -A && "
                        f"{git_env} git commit -q -m sample", home)
        if r.returncode != 0:
            print("ERROR cannot build the sandbox repository: " + r.stderr)
            sys.exit(2)
        files = [os.path.join(w, "wom-test-hello-world/mod.lua"), os.path.join(reg, "entry.json")]
        toks = ("OWNER-PLACEHOLDER", "0" * 40)
        before = sum(open(f, encoding="utf-8").read().count(t) for f in files for t in toks)
        if before < 3:
            fail(f"expected at least 3 placeholder tokens before filling, found {before}")
        for sid, cd, l in cmds:
            line = (cd + " && " if cd else "") + l
            r = sandbox_run(line, home)
            if r.returncode != 0:
                fail(f"step {sid}: the exact command line failed (exit {r.returncode}): {r.stderr.strip()[:120]}")
        after = sum(open(f, encoding="utf-8").read().count(t) for f in files for t in toks)
        if after != 0:
            fail(f"{after} placeholder tokens remain after running the runbook's commands")
        e = read(files[1])
        if re.search(r'"commit": "0{40}"', e) or not re.search(r'"commit": "[0-9a-f]{40}"', e):
            fail("entry.json has no real 40-hex commit after filling")
        print(f"info: ran {len(cmds)} fill command line(s); tokens before {before}, after {after}")
    finally:
        shutil.rmtree(tmp)


def m4_section_split(text):
    m = re.search(r"^## .{0,3} ?M4 .*$", text, re.M)
    if not m:
        return None
    nxt = re.search(r"^## ", text[m.end():], re.M)
    end = m.end() + nxt.start() if nxt else len(text)
    return text[:m.start()], text[m.start():end], text[end:]


def check_m4(new_path, base_path):
    new, base = read(new_path), read(base_path)
    a, b = m4_section_split(new), m4_section_split(base)
    if not a or not b:
        fail("no M4 section found")
        return
    if not re.match(r"^## ☐ M4", a[1]):
        fail("the M4 heading is not '## ☐ M4' (status must stay not-done)")
    if "wom-test-hello-world" not in a[1]:
        fail("M4 does not name wom-test-hello-world")
    if "first-publish.md" not in a[1]:
        fail("M4 does not point at first-publish.md")
    for l in a[1].split("\n"):
        if "mbmludric/hello-world" in l and "404" not in l:
            fail(f"M4 still names mbmludric/hello-world outside the historical 404 note: {l.strip()[:80]}")
    if a[0] != b[0]:
        fail("text before the M4 section changed")
    if a[2] != b[2]:
        fail("text after the M4 section changed (another M section was edited)")
    if a[1] == b[1]:
        fail("the M4 section did not change at all")


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    cmd, args = argv[1], argv[2:]
    try:
        table = {"shape": (check_shape, 1), "cred": (check_cred, 1), "switch": (check_switch, 1),
                 "evidence": (check_evidence, 2), "observed": (check_observed, 2), "fill": (check_fill, 2),
                 "m4": (check_m4, 2)}
        fn, n = table[cmd]
        if len(args) != n:
            print(__doc__)
            return 2
        fn(*args)
    except (KeyError, OSError) as exc:
        print(f"ERROR (usage or unreadable input, not a verdict): {type(exc).__name__}: {exc}")
        return 2
    return 1 if FAILS else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
