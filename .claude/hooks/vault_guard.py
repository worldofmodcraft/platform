"""PreToolUse guard (task 052, docs/tools/vault-projection.md "Triggers and guard").

Reads the hook JSON on stdin.  Exit 0 allows the call; exit 2 blocks it (stderr is shown to the agent).
The vault is taken from WOM_VAULT and from ~/.config/wom/vault-path; a path inside EITHER blocks.
Python 3 standard library only.  Known gap: \\\\wsl$, //?/ and UNC prefixes, Windows trailing-dot/space stripping.
"""
import json
import os
import re
import sys
import time

PATH_KEYS = ("file_path", "notebook_path")
EDIT_TOOLS = ("Write", "Edit", "MultiEdit", "NotebookEdit")
DRIVE_RE = re.compile(r"^([A-Za-z]):[\\/](.*)$", re.S)


def fold(s):
    return s.casefold()  # CHECK:casefold


def mnt_root():
    """/mnt, except in test mode (WOM_VAULT_TEST=1) where a root under TMPDIR may be named, so that
    tests never have to look at a real drive mount."""
    alt = os.environ.get("WOM_GUARD_MNT_ROOT")
    if alt and os.environ.get("WOM_VAULT_TEST") == "1":
        tmp = os.path.realpath(os.environ.get("TMPDIR") or "/tmp")
        if os.path.realpath(alt).startswith(tmp + os.sep):
            return alt
    return "/mnt"


def normalise(path, cwd):
    """Lexical normalisation: D:\\x and d:/x become <mnt>/d/x; a relative path joins cwd."""
    m = DRIVE_RE.match(path)
    if m:
        path = "%s/%s/%s" % (mnt_root(), m.group(1).lower(), m.group(2).replace("\\", "/"))
    elif re.match(r"^[A-Za-z]:$", path):
        path = "%s/%s" % (mnt_root(), path[0].lower())
    if not os.path.isabs(path):
        path = os.path.join(cwd, path)
    return os.path.normpath(path)


def real(p):
    return os.path.realpath(p)  # CHECK:realpath


def inside(target, vault):
    t, v = fold(target), fold(vault)
    return t == v or t.startswith(v.rstrip("/") + "/")


def configured_vaults():
    """Return (vaults, broken).  `broken` lists config sources that exist but cannot be turned into a vault path
    (unreadable, not UTF-8, empty, or not exactly one line).  Such a source means "configured but broken", never
    "not configured": the vault location is unknown, so main() blocks every file-tool call."""
    out, broken = [], []
    env = os.environ.get("WOM_VAULT")
    if env:
        out.append(("WOM_VAULT", env.strip()))
    cfg = os.path.join(os.path.expanduser("~"), ".config", "wom", "vault-path")
    try:
        with open(cfg, encoding="utf-8") as fh:
            lines = fh.read().splitlines()
    except FileNotFoundError:
        return out, broken
    except (OSError, UnicodeDecodeError) as exc:
        broken.append("%s: %s" % (cfg, exc.__class__.__name__))
        return out, broken
    if len(lines) != 1 or not lines[0].strip():
        broken.append("%s: must hold exactly one non-empty line" % cfg)
    else:
        out.append((cfg, lines[0].strip()))
    return out, broken


RECOVERY = ("To disable the guard, Ludwig runs: rm -f ~/.config/wom/vault-path  (and unset WOM_VAULT if set); "
            "see docs/tools/vault-projection.md, \"Triggers and guard\".")


def count_skip(reason):
    log = os.path.join(os.path.expanduser("~"), ".config", "wom", "guard-skips.log")
    try:
        os.makedirs(os.path.dirname(log), exist_ok=True)
        with open(log, "a", encoding="utf-8") as fh:
            fh.write("%s %s\n" % (time.strftime("%Y-%m-%dT%H:%M:%S%z"), reason))
    except OSError as exc:
        print("vault-guard: cannot append to %s (%s)" % (log, exc.strerror), file=sys.stderr)


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError as exc:
        print("vault-guard: hook input is not valid JSON (%s); blocking" % exc, file=sys.stderr)
        return 2
    if not isinstance(data, dict) or not isinstance(data.get("tool_input", {}), dict):
        print("vault-guard: unexpected hook input shape; blocking", file=sys.stderr)
        return 2
    tool_input = data.get("tool_input") or {}
    cwd = data.get("cwd") if isinstance(data.get("cwd"), str) and data.get("cwd") else os.getcwd()
    paths = [tool_input[k] for k in PATH_KEYS if isinstance(tool_input.get(k), str) and tool_input[k]]
    if not paths:
        if data.get("tool_name") in EDIT_TOOLS:
            print("vault-guard: %s call without a file path; blocking" % data.get("tool_name"), file=sys.stderr)
            return 2
        return 0
    vaults, broken = configured_vaults()
    if broken:  # CHECK:broken-config
        print("vault-guard: the vault is configured but its config is broken (%s), so the vault location is unknown; "
              "blocking every file-tool call (fail closed). %s" % ("; ".join(broken), RECOVERY), file=sys.stderr)
        return 2
    if not vaults:
        count_skip("no vault configured (WOM_VAULT unset, no ~/.config/wom/vault-path); allowed %s" % paths[0][:200])
        return 0
    try:
        for raw in paths:
            lex = normalise(raw, cwd)
            rp = real(lex)
            for source, vraw in vaults:
                vlex = normalise(vraw, "/")
                if not os.path.isdir(vlex):  # CHECK:fail-closed
                    # Configured but unresolvable (for example D: not mounted): lexical comparison only.
                    if inside(lex, vlex) or inside(rp, vlex):  # CHECK:fail-closed-match
                        print("vault-guard: blocked %s: it is under the configured vault %s (vault not resolvable; "
                              "lexical match)" % (raw, vlex), file=sys.stderr)
                        return 2
                    continue
                rv = real(vlex)
                if inside(rp, rv) or inside(lex, vlex):
                    print("vault-guard: blocked %s: it resolves inside the vault (%s). Agents never write the vault; "
                          "tools/vault/wom_vault.py does." % (raw, rv), file=sys.stderr)
                    return 2
    except ValueError as exc:
        print("vault-guard: cannot normalise the path (%s); blocking" % exc, file=sys.stderr)
        return 2
    return 0


def guarded_main():
    try:
        return main()
    except BaseException as exc:  # CHECK:catch-all  (only exit 2 blocks; any crash must therefore be 2)
        print("vault-guard: unexpected %s: %s; blocking (fail closed)" % (exc.__class__.__name__, exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(guarded_main())
