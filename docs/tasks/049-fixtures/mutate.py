#!/usr/bin/env python3
"""Mutation driver for task 049 (MANAGER.md 2c rule 2).  For each mutation: copy the hook tree to a scratch dir, break
ONE thing, run run_suite.py against the copy, and require that the set of red check groups equals the expected set
exactly (a mutant that reddens nothing, or the wrong groups, fails).  The control (no mutation) must be green.
Usage: mutate.py --tree DIR [--observe]   (--observe prints observed red sets instead of comparing)
Each mutation names a '# CHECK:name' line (its code part, after the indentation, is replaced) or a raw substring."""
import argparse, concurrent.futures as cf, os, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
P, W, L, S = ".claude/hooks/git_guard.py", ".claude/hooks/git-guard.sh", "tools/manager/check-log-entry.sh", ".claude/settings.json"
RAW = "RAW:"


def c(path, name, new):
    return (path, name, new)


def raw(path, old, new):
    return (path, RAW + old, new)


# name -> (edits, expected red groups)
FORCE_DEPENDENTS = None  # filled in by the table below
M = {}


def m(name, edits, red):
    M[name] = (edits if isinstance(edits, list) else [edits], set(red.split()) if isinstance(red, str) else set(red))


exec(open(os.path.join(HERE, "mutations.py")).read())


def apply_edit(root, edit):
    path, name, new = edit
    f = os.path.join(root, path)
    text = open(f).read()
    if name.startswith(RAW):
        old = name[len(RAW):]
        if text.count(old) != 1:
            raise SystemExit("mutation anchor %r matches %d times in %s (must be exactly 1: a pattern that matches nothing is a failure)" % (old, text.count(old), path))
        out = text.replace(old, new)
    else:
        tag = "# CHECK:" + name
        idx = [i for i, l in enumerate(text.split("\n")) if l.rstrip().endswith(tag) or (tag + " ") in l]
        if len(idx) != 1:
            raise SystemExit("mutation line '%s' matches %d lines in %s (must be exactly 1)" % (tag, len(idx), path))
        lines = text.split("\n")
        old = lines[idx[0]]
        ind = old[:len(old) - len(old.lstrip())]
        lines[idx[0]] = "\n".join(ind + x for x in new.split("\n"))
        out = "\n".join(lines)
    if out == text:
        raise SystemExit("mutation on %s left the file identical" % path)
    open(f, "w").write(out)


def copy_tree(tree, dest):
    for rel in (".claude/hooks", ".claude/settings.json", "tools/manager"):
        s, d = os.path.join(tree, rel), os.path.join(dest, rel)
        os.makedirs(os.path.dirname(d), exist_ok=True)
        if os.path.isdir(s):
            shutil.copytree(s, d, ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
        else:
            shutil.copy2(s, d)


def red_groups(root):
    p = subprocess.run([sys.executable, "-B", os.path.join(HERE, "run_suite.py"), "--tree", root], capture_output=True, timeout=600)
    out = p.stdout.decode()
    for line in out.splitlines()[::-1]:
        if line.startswith("RED-GROUPS:"):
            return {g for g in line[len("RED-GROUPS:"):].strip().split(",") if g}, out
    return {"<runner crashed: %s>" % p.stderr.decode()[-200:]}, out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", required=True)
    ap.add_argument("--observe", action="store_true")
    a = ap.parse_args()
    tree = os.path.realpath(a.tree)
    scratch = tempfile.mkdtemp(prefix="wom049-mut-")
    bad = 0

    def one(item):
        name, (edits, want) = item
        root = os.path.join(scratch, name)
        copy_tree(tree, root)
        for e in edits:
            apply_edit(root, e)
        got, out = red_groups(root)
        return name, want, got

    try:
        croot = os.path.join(scratch, "control")
        copy_tree(tree, croot)
        got, out = red_groups(croot)
        if got:
            print("FAIL: control (unmutated copy) is red: %s" % sorted(got)); bad += 1
        else:
            print("ok: control (unmutated copy) is green")
        with cf.ThreadPoolExecutor(4) as ex:
            for name, want, got in ex.map(one, M.items()):
                if a.observe:
                    print("%s = %s" % (name, " ".join(sorted(got)) or "<survived>"))
                elif not got:
                    print("FAIL: MUTANT SURVIVED %s (every check stayed green)" % name); bad += 1
                elif got == want:
                    print("ok: mutant %-18s killed -> %s" % (name, " ".join(sorted(got))))
                else:
                    print("FAIL: mutant %s reddened %s, expected %s (missing %s, extra %s)" % (name, sorted(got), sorted(want), sorted(want - got), sorted(got - want))); bad += 1
    finally:
        shutil.rmtree(scratch, ignore_errors=True)
    print("== %d mutations, %d problems" % (len(M), bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
