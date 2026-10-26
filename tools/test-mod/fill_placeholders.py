#!/usr/bin/env python3
"""Fill the two placeholders of the test:hello-world staging files (task 010a). Python standard library only.

    python3 fill_placeholders.py mod   --account ACCOUNT [--file PATH]
    python3 fill_placeholders.py entry --account ACCOUNT --commit HEX40 [--file PATH]

`mod` rewrites the repository URL token in mod.lua's `source` (default file: ./mod.lua).
`entry` rewrites the same URL token and the commit token in the registry entry.json (default file: ./entry.json);
the entry needs --account as well because its source_url carries the same URL token as mod.lua.

The tokens are valid values for their schema fields on purpose, so an unfilled file still validates:
    OWNER-PLACEHOLDER                          inside https://github.com/OWNER-PLACEHOLDER/wom-test-hello-world
    0000000000000000000000000000000000000000   (forty '0' characters) as the commit

The script refuses an account that is not a GitHub account name, a commit that is not 40 lowercase hex characters
or is all zeros, and a file that does not hold each token to replace. It computes the result in memory, asserts that
zero tokens remain, and only then writes the file (atomically, via a temporary file in the same directory).
Exit codes: 0 filled, 2 refused (nothing written).
"""

from __future__ import annotations

import argparse
import os
import re
import sys
import tempfile

OWNER_TOKEN = "OWNER-PLACEHOLDER"
COMMIT_TOKEN = "0" * 40
_ACCOUNT_RE = re.compile(r"[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}")  # GitHub: 1-39, no leading/trailing/double '-'
_COMMIT_RE = re.compile(r"[0-9a-f]{40}")


class Refused(Exception):
    pass


def check_account(account):
    if account == OWNER_TOKEN or not _ACCOUNT_RE.fullmatch(account):
        raise Refused(f"account {account!r} is not a GitHub account name (1-39 letters, digits and single hyphens; "
                      f"not {OWNER_TOKEN})")
    return account


def check_commit(commit):
    if not _COMMIT_RE.fullmatch(commit):
        raise Refused(f"commit {commit!r} is not 40 lowercase hex characters")
    if set(commit) == {"0"}:
        raise Refused("commit is all zeros: that is the placeholder, not a commit")
    return commit


def fill_text(text, kind, account, commit=None):
    """Return text with the tokens of `kind` replaced; Refused if a token is absent beforehand or any remains afterwards."""
    tokens = [OWNER_TOKEN] + ([COMMIT_TOKEN] if kind == "entry" else [])
    for tok in tokens:
        if tok not in text:
            raise Refused(f"the file does not contain the token {tok!r}; wrong file, or it was already filled")
    out = text.replace(OWNER_TOKEN, check_account(account))
    if kind == "entry":
        out = out.replace(COMMIT_TOKEN, check_commit(commit))
    for tok in tokens:
        if tok in out:
            raise Refused(f"token {tok!r} is still present after filling")
    return out


def fill_file(path, kind, account, commit=None):
    try:
        with open(path, "r", encoding="utf-8", newline="") as f:
            text = f.read()
    except OSError as exc:
        raise Refused(f"cannot read {path}: {exc}")
    out = fill_text(text, kind, account, commit)
    d = os.path.dirname(os.path.abspath(path))
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".fill-")
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as f:
            f.write(out)
        os.replace(tmp, path)
    except BaseException:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="kind", required=True)
    m = sub.add_parser("mod")
    m.add_argument("--account", required=True)
    m.add_argument("--file", default="mod.lua")
    e = sub.add_parser("entry")
    e.add_argument("--account", required=True)
    e.add_argument("--commit", required=True)
    e.add_argument("--file", default="entry.json")
    a = ap.parse_args(argv)
    try:
        fill_file(a.file, a.kind, a.account, getattr(a, "commit", None))
    except Refused as exc:
        print(f"REFUSED: {exc}", file=sys.stderr)
        return 2
    print(f"filled {a.file}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
