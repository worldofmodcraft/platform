"""Run a script under a Python audit hook and record which paths it opens (task 051, AC3).

usage: python3 -I audit_run.py SCRIPT [ARGS...]     log path in env WOM051_AUDIT_LOG
strace is not installed here; the audit hook sees every open() / os.open() / scandir / listdir
made by the interpreter running the script.  Child processes (git) are not traced, and they never
receive the vault path, so they cannot open vault files.
"""
import json
import os
import runpy
import sys

events = []
active = [True]


def hook(event, args):
    if not active[0]:
        return
    if event in ("open", "os.scandir", "os.listdir", "os.mkdir", "os.rename", "os.replace"):
        first = args[0] if args else None
        if isinstance(first, bytes):
            first = os.fsdecode(first)
        if isinstance(first, str):
            events.append([event, first])


log = os.environ["WOM051_AUDIT_LOG"]
script = sys.argv[1]
sys.argv = [script] + sys.argv[2:]
sys.addaudithook(hook)
code = 0
try:
    runpy.run_path(script, run_name="__main__")
except SystemExit as exc:
    code = exc.code if isinstance(exc.code, int) else (0 if exc.code is None else 1)
finally:
    active[0] = False
    with open(log, "w", encoding="utf-8") as fh:
        json.dump(events, fh)
sys.exit(code)
