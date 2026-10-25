#!/usr/bin/env python3
"""Checker behind docs/tasks/010a-verify.sh: criteria 1-4 of task 010a on a staging directory (task 010a).

    python3 -I check_tree.py --stage DIR --registry DIR --generator PATH --fill-script PATH [--only 1,1build,2,3,4]

DIR is a copy (or the real one) of docs/test-mod: it holds hello-world/ (the mod tree) and registry-pr/{entry,page}.json.
--registry is an extracted `git archive origin/main` of the registry repository (never its working tree).
Prints one 'ok'/'FAIL' line per check and exits 0 only if every selected check passed. Standard library only.
Keys: a throwaway minisign key is generated inside a temporary directory, never printed, and deleted on exit.
The verify script mutates copies of the staging tree and expects this checker to go red on each; it never mutates the real one.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import zlib

sys.dont_write_bytecode = True

MOD_ID = "test:hello-world"
EXPECTED_FILES = {
    "mod.lua", "README.md", "LICENSE",
    "assets/screenshots/welcome.png", "assets/screenshots/gallery.png", "assets/screenshots/spare.png",
}
LISTED = ["assets/screenshots/welcome.png", "assets/screenshots/gallery.png"]
SPARE = "assets/screenshots/spare.png"
PNG_MAGIC = bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
BLIZZARD_EXT = {".blp", ".dbc", ".db2", ".m2", ".wmo", ".mpq", ".adt", ".wdt", ".wdl", ".skin", ".anim", ".bls", ".mdx"}  # extracted game-asset kinds
OWNER_TOKEN = "OWNER-PLACEHOLDER"
ZERO_TOKEN = "0" * 40
TOKEN_LOCATIONS = {  # token -> {relative path under the stage dir: expected occurrences}
    OWNER_TOKEN: {"hello-world/mod.lua": 1, "registry-pr/entry.json": 1},
    ZERO_TOKEN: {"registry-pr/entry.json": 1},
}
SAMPLE_ACCOUNT = "sample-owner"
SAMPLE_COMMIT = "a" * 40
AUTHOR_ID = "37807560"  # the project owner's personal account id (ownership.md / 010a amendment 5)

fails = 0


def ok(msg):
    print(f"  ok   {msg}")


def bad(msg):
    global fails
    fails += 1
    print(f"  FAIL {msg}")


def check(cond, msg_ok, msg_bad=None):
    ok(msg_ok) if cond else bad(msg_bad or msg_ok)
    return cond


def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


def run(cmd, cwd=None, input_env=None):
    env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1"}
    env.update(input_env or {})
    return subprocess.run(cmd, cwd=cwd, env=env, stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=900)


def files_under(root):
    out = set()
    for d, _, fs in os.walk(root):
        for f in fs:
            out.add(os.path.relpath(os.path.join(d, f), root).replace(os.sep, "/"))
    return out


def png_problem(data):
    """None if `data` is a well-formed PNG (signature, CRC-checked chunks, IHDR first, IEND last and at the very end)."""
    if data[:8] != PNG_MAGIC:
        return "bad PNG signature"
    pos, kinds = 8, []
    while pos < len(data):
        if pos + 12 > len(data):
            return "truncated chunk header"
        (n,) = struct.unpack(">I", data[pos:pos + 4])
        kind = data[pos + 4:pos + 8]
        end = pos + 12 + n
        if end > len(data):
            return f"chunk {kind!r} runs past the end"
        (crc,) = struct.unpack(">I", data[end - 4:end])
        if zlib.crc32(data[pos + 4:end - 4]) & 0xFFFFFFFF != crc:
            return f"bad CRC in {kind!r}"
        kinds.append(kind)
        pos = end
        if kind == b"IEND":
            break
    if not kinds or kinds[0] != b"IHDR":
        return "IHDR is not the first chunk"
    if kinds[-1] != b"IEND":
        return "no IEND chunk"
    if pos != len(data):
        return "bytes after IEND"
    return None


class Ctx:
    def __init__(self, a):
        self.stage = os.path.abspath(a.stage)
        self.reg = os.path.abspath(a.registry)
        self.generator = os.path.abspath(a.generator)
        self.fill = os.path.abspath(a.fill_script)
        self.manifest = load_module("wom_manifest", os.path.join(self.reg, "tools", "validation", "manifest.py"))
        self.sc = load_module("wom_schema_check", os.path.join(self.reg, "tests", "contracts", "schema_check.py"))
        self.tmp = tempfile.mkdtemp(prefix="wom010a-")

    def schema(self, name):
        with open(os.path.join(self.reg, "contracts", name), encoding="utf-8") as f:
            return json.load(f)

    def cleanup(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def sub(self, name):
        return tempfile.mkdtemp(prefix=name + "-", dir=self.tmp)


def read_json(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def readme_checks(readme_text, tree):
    lines = readme_text.splitlines()
    check(any(re.match(r"#{1,6} \S", l) for l in lines), "README has a heading", "README has no heading")
    check(any(re.match(r"\s*([-*+]|\d+\.) \S", l) for l in lines), "README has a list", "README has no list")
    check(any(re.match(r"^\|?(\s*:?-{3,}:?\s*\|)+(\s*:?-{3,}:?\s*)?$", l.strip()) and "|" in l for l in lines),
          "README has a table", "README has no table")
    fences = [l for l in lines if l.lstrip().startswith("```")]
    check(len(fences) >= 2 and len(fences) % 2 == 0, "README has a closed fenced code block", f"README fences: {len(fences)} (need an even number >= 2)")
    check(re.search(r"(?<!!)\[[^\]]+\]\(https?://[^)\s]+\)", readme_text) is not None, "README has a link", "README has no link")
    imgs = re.findall(r"!\[[^\]]*\]\(([^)\s]+)\)", readme_text)
    good = [i for i in imgs if i in {"assets/screenshots/welcome.png", "assets/screenshots/gallery.png", SPARE}
            and os.path.isfile(os.path.join(tree, i))]
    check(bool(good), f"README has an image reference to one of the three PNGs ({good[0] if good else ''})",
          f"README has no image reference to one of the three PNGs (found {imgs})")
    check("permanent pipeline canary" in " ".join(readme_text.lower().split()), 'README says "permanent pipeline canary"',
          'README lacks the words "permanent pipeline canary"')


def crit1_static(c, hello, label):
    """Criterion 1 (and 010a amendment 7) on one mod tree."""
    print(f"-- criterion 1: mod tree validity [{label}]")
    scanner = os.path.join(c.reg, "tools", "validation", "scan_assets.py")
    cwd = c.sub("scan-cwd")
    r = run([sys.executable, scanner, hello], cwd=cwd)
    summary = {}
    try:
        summary = json.loads(r.stdout)["summary"]
    except (ValueError, KeyError):
        pass
    check(r.returncode == 0 and summary.get("files_accepted") == len(EXPECTED_FILES) and summary.get("files_rejected") == 0,
          f"scan_assets.py DIR -> exit 0, {summary.get('files_accepted')} files accepted, 0 rejected",
          f"scan_assets.py DIR -> exit {r.returncode}, summary {summary}; stderr: {r.stderr.strip()[:300]}")
    # positive control: the scanner really rejects a planted Blizzard-format file in a copy
    ctl = os.path.join(c.sub("scan-control"), "t")
    shutil.copytree(hello, ctl)
    with open(os.path.join(ctl, "planted.bin"), "wb") as f:
        f.write(b"WDBC" + bytes(60))
    r = run([sys.executable, scanner, ctl], cwd=cwd)
    check(r.returncode == 1, "positive control: a planted DBC-magic file makes the scanner exit 1",
          f"positive control: planted DBC file -> scanner exit {r.returncode}, expected 1")

    check(files_under(hello) == EXPECTED_FILES, "the tree holds exactly the six expected files",
          f"tree file set differs: extra {sorted(files_under(hello) - EXPECTED_FILES)}, missing {sorted(EXPECTED_FILES - files_under(hello))}")

    try:
        with open(os.path.join(hello, "mod.lua"), "rb") as f:
            mod = c.manifest.read_manifest(f.read())
    except (OSError, c.manifest.ManifestError) as exc:
        bad(f"mod.lua is not readable by the registry's static reader: {exc}")
        return None
    ok("mod.lua read by the registry's static reader (008a read_manifest)")
    try:
        c.sc.validate(mod, c.schema("manifest.schema.json"))
        ok("projected manifest validates against manifest.schema.json")
    except c.sc.SchemaValidationError as exc:
        bad(f"manifest.schema.json: {exc}")
    check(mod.get("license") == "MIT", "license is MIT", f"license is {mod.get('license')!r}, expected MIT")
    check(mod.get("id") == MOD_ID, f"id is {MOD_ID}", f"id is {mod.get('id')!r}")
    check(mod.get("version") == "1.0.0" and mod.get("type") == "mod", "version 1.0.0, type mod")
    check(mod.get("ai_assisted") is True, "ai_assisted is true (choice C2)", f"ai_assisted is {mod.get('ai_assisted')!r}")
    check(mod.get("screenshots") == LISTED, f"mod.lua screenshots are exactly {LISTED}", f"mod.lua screenshots are {mod.get('screenshots')}")
    for s in mod.get("screenshots", []):
        p = os.path.join(hello, s)
        if ".." in s.split("/") or s.startswith("/") or "://" in s or "\\" in s:
            bad(f"screenshot {s} is a traversal, absolute path or URL")
            continue
        if not os.path.isfile(p):
            bad(f"screenshot {s} does not exist")
            continue
        with open(p, "rb") as f:
            data = f.read()
        prob = png_problem(data)
        check(prob is None, f"{s}: PNG magic bytes, valid chunks, IEND at the end", f"{s}: {prob}")
    try:
        with open(os.path.join(hello, "LICENSE"), encoding="utf-8") as f:
            lic = f.read()
    except OSError as exc:
        lic = ""
        bad(f"LICENSE unreadable: {exc}")
    check(lic.startswith("MIT License") and "Copyright (c) 2026 World of Modcraft contributors" in lic,
          'LICENSE is the MIT text with the copyright line "World of Modcraft contributors"', "LICENSE lacks the MIT header or the copyright line")
    try:
        with open(os.path.join(hello, "README.md"), encoding="utf-8") as f:
            readme_checks(f.read(), hello)
    except OSError as exc:
        bad(f"README.md unreadable: {exc}")
    return mod


def git_env(extra=None):
    env = {"GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1", "GIT_TERMINAL_PROMPT": "0",
           "GIT_AUTHOR_NAME": "qa", "GIT_AUTHOR_EMAIL": "qa@example.invalid",
           "GIT_COMMITTER_NAME": "qa", "GIT_COMMITTER_EMAIL": "qa@example.invalid",
           "GIT_AUTHOR_DATE": "2026-01-01T00:00:00Z", "GIT_COMMITTER_DATE": "2026-01-01T00:00:00Z"}
    env.update(extra or {})
    return env


def crit1_build(c, stage, label):
    """010a amendment 6: git init + commit the tree, run build_version.py with a throwaway key; expect exit 0."""
    print(f"-- criterion 1 (build): pipeline build of the committed tree [{label}]")
    work = c.sub("build")
    repo = os.path.join(work, "repo")
    shutil.copytree(os.path.join(stage, "hello-world"), repo)
    # the committed tree carries the filled mod.lua, as the author would publish it
    for cmd in (["init", "-q", "-b", "main"], ["add", "-A"], ["-c", "commit.gpgsign=false", "commit", "-q", "-m", "hello-world 1.0.0"]):
        r = run(["git", "-C", repo] + cmd, input_env=git_env())
        if r.returncode != 0:
            bad(f"git {cmd[0]} failed: {r.stderr.strip()[:200]}")
            return
    commit = run(["git", "-C", repo, "rev-parse", "HEAD"], input_env=git_env()).stdout.strip()
    # fill a copy of the entry through the real fill script, then point source_url at the local repo
    entry = os.path.join(work, "entry.json")
    shutil.copy(os.path.join(stage, "registry-pr", "entry.json"), entry)
    if OWNER_TOKEN in open(entry, encoding="utf-8").read():  # an unfilled entry goes through the real fill script
        r = run([sys.executable, c.fill, "entry", "--account", SAMPLE_ACCOUNT, "--commit", commit, "--file", entry])
        if not check(r.returncode == 0, "fill_placeholders.py entry filled a copy of the entry with the real commit",
                     f"fill_placeholders.py entry exit {r.returncode}: {r.stderr.strip()[:200]}"):
            return
    e = read_json(entry)
    e["versions"][0]["commit"] = commit
    e["versions"][0]["source_url"] = "file://" + repo
    with open(entry, "w", encoding="utf-8") as f:
        json.dump(e, f)
    keys = c.sub("keys")
    pub, key = os.path.join(keys, "k.pub"), os.path.join(keys, "k.key")
    r = run(["minisign", "-G", "-W", "-f", "-p", pub, "-s", key])  # output (key id only, no secret) is not printed
    if not check(r.returncode == 0 and os.path.isfile(key), "throwaway minisign key generated in a temp dir (not printed)",
                 f"minisign -G failed (exit {r.returncode})"):
        return
    ws, out = c.sub("build-ws"), os.path.join(work, "out")
    r = run([sys.executable, os.path.join(c.reg, "tools", "pipeline", "build_version.py"), "--allow-local-source", "--entry", entry,
             "--version", "1.0.0", "--workdir", ws, "--key", key, "--pubkey", pub, "--out", out])
    if not check(r.returncode == 0, "build_version.py --allow-local-source ... --version 1.0.0 -> exit 0",
                 f"build_version.py -> exit {r.returncode}: {(r.stderr or r.stdout).strip()[:500]}"):
        return
    names = sorted(os.listdir(out))
    check(any(n.endswith(".tar.gz") for n in names) and any(n.endswith(".minisig") for n in names) and "result.json" in names,
          f"build output holds the tarball, its minisig and result.json ({', '.join(names)})", f"build output incomplete: {names}")
    res = read_json(os.path.join(out, "result.json"))
    sc = res.get("scan", {}).get("summary", {})
    check(res.get("id") == MOD_ID and sc.get("files_accepted") == len(EXPECTED_FILES) and sc.get("files_rejected") == 0,
          f"result.json: id {MOD_ID}, {sc.get('files_accepted')} files accepted by the pipeline's own scan",
          f"result.json id/scan unexpected: {res.get('id')} {sc}")


def crit2(c, stage):
    print("-- criterion 2: originality guardrail")
    shots = os.path.join(stage, "hello-world", "assets", "screenshots")
    r = run([sys.executable, c.generator, "--check", shots])
    check(r.returncode == 0, "make_screenshots.py --check: the committed PNGs decode to the generator's pixels (sha256 of raw rows)",
          f"make_screenshots.py --check -> exit {r.returncode}: {r.stderr.strip()[:400]}")
    a, b = c.sub("gen-a"), c.sub("gen-b")
    ra, rb = run([sys.executable, c.generator, "--out", a]), run([sys.executable, c.generator, "--out", b])
    same = ra.returncode == 0 == rb.returncode and all(
        open(os.path.join(a, n), "rb").read() == open(os.path.join(b, n), "rb").read()
        for n in ("welcome.png", "gallery.png", "spare.png"))
    check(same, "same-run double generation is byte-identical (3 files)", "two generator runs produced different bytes")
    hello = os.path.join(stage, "hello-world")
    names = files_under(hello)
    blizz = sorted(n for n in names if os.path.splitext(n)[1].lower() in BLIZZARD_EXT)
    check(not blizz, "no file is named like an extracted game asset (.blp .dbc .m2 .wmo .mpq ...)", f"asset-like file names: {blizz}")
    magics = {b"WDBC": "DBC", b"WDB2": "DB2", b"MPQ\x1a": "MPQ", b"MPQ\x1b": "MPQ", b"BLP1": "BLP", b"BLP2": "BLP", b"MD20": "M2", b"MD21": "M2", b"MVER": "WMO/ADT"}
    hits = []
    for n in names:
        with open(os.path.join(hello, n), "rb") as f:
            head = f.read(4)
        if head in magics:
            hits.append((n, magics[head]))
    check(not hits, "no file begins with a Blizzard-format magic (DBC DB2 MPQ BLP M2 WMO)", f"Blizzard magic found: {hits}")


def crit3(c, stage, label):
    print(f"-- criterion 3: registry-side files [{label}]")
    pr = os.path.join(stage, "registry-pr")
    try:
        entry, page = read_json(os.path.join(pr, "entry.json")), read_json(os.path.join(pr, "page.json"))
    except (OSError, ValueError) as exc:
        bad(f"cannot read the registry-pr JSON files: {exc}")
        return
    for name, doc, sch in (("page.json", page, "page.schema.json"), ("entry.json", entry, "entry.schema.json")):
        try:
            c.sc.validate(doc, c.schema(sch))
            ok(f"{name} validates against {sch} (schema_check.validate)")
        except c.sc.SchemaValidationError as exc:
            bad(f"{name} vs {sch}: {exc}")
    vs = entry.get("versions", [])
    check(len(vs) == 1 and sorted(vs[0]) == ["commit", "source_url", "status", "version"] and vs[0].get("status") == "pending",
          "entry has one pending version with exactly four keys: version, commit, source_url, status",
          f"entry version keys: {[sorted(v) for v in vs]}")
    check(entry.get("id") == MOD_ID, f"entry id is {MOD_ID}", f"entry id {entry.get('id')!r}")
    reserved = read_json(os.path.join(c.reg, "reserved-namespaces.json"))
    want = reserved["namespaces"]["test"]["owner"]
    check(entry.get("owner") == want, f"entry.owner equals reserved-namespaces.json test.owner, read from the file ({want})",
          f"entry.owner {entry.get('owner')} != reserved test.owner {want}")
    try:
        with open(os.path.join(stage, "hello-world", "mod.lua"), "rb") as f:
            mod = c.manifest.read_manifest(f.read())
    except (OSError, c.manifest.ManifestError) as exc:
        bad(f"mod.lua unreadable: {exc}")
        return
    pshots, mshots = page.get("screenshots", []), mod.get("screenshots", [])
    check(set(pshots) <= set(mshots) and pshots, f"page.json screenshots {pshots} are a subset of mod.lua's {mshots}",
          f"page.json screenshots {pshots} are not a non-empty subset of mod.lua's {mshots}")
    check(os.path.isfile(os.path.join(stage, "hello-world", SPARE)) and SPARE not in pshots and SPARE not in mshots,
          "spare.png is in the tree and in neither list", "spare.png missing from the tree or present in a list")
    check(entry.get("versions", [{}])[0].get("version") == mod.get("version"), "entry version equals mod.lua version")

    # stage as the registry PR would carry it and run the registry's own checkers
    work = c.sub("stage-pr")
    new, old = os.path.join(work, "new"), os.path.join(work, "old")
    os.makedirs(os.path.join(new, "mods", "test.hello-world"))
    os.makedirs(old)
    for n in ("entry.json", "page.json"):
        shutil.copy(os.path.join(pr, n), os.path.join(new, "mods", "test.hello-world", n))
    paths = ["mods/test.hello-world/entry.json", "mods/test.hello-world/page.json"]
    reg_res = os.path.join(c.reg, "reserved-namespaces.json")
    cli = [sys.executable, "-I", os.path.join(c.reg, "tools", "registry", "cli.py")]
    own = [sys.executable, "-I", os.path.join(c.reg, "tools", "registry", "ownership_cli.py")]
    r = run(cli + ["classify", "--reserved-file", reg_res] + paths)
    cls = None
    try:
        cls = json.loads(r.stdout).get("class")
    except ValueError:
        pass
    check(r.returncode == 0 and cls == "reserved-namespace", "cli.py classify -> exit 0, class reserved-namespace",
          f"cli.py classify -> exit {r.returncode}, class {cls}: {r.stderr.strip()[:300]}")
    r = run(cli + ["schema", "--root", new] + paths)
    check(r.returncode == 0, "cli.py schema -> exit 0", f"cli.py schema -> exit {r.returncode}: {r.stderr.strip()[:300]}")
    r = run(cli + ["append-only", "--old-root", old, "--new-root", new] + paths)
    check(r.returncode == 0, "cli.py append-only (empty old root) -> exit 0", f"cli.py append-only -> exit {r.returncode}: {r.stderr.strip()[:300]}")
    base = ["--author-provider", "github", "--author-id", AUTHOR_ID, "--old-root", old, "--new-root", new, "--reserved-file", reg_res]
    r = run(own + base + ["--membership-status", "204"] + paths)
    check(r.returncode == 0, f"ownership_cli.py --author-id {AUTHOR_ID} --membership-status 204 -> exit 0 (org member accepted)",
          f"ownership_cli.py 204 -> exit {r.returncode}: {r.stderr.strip()[:300]}")
    r = run(own + base + ["--membership-status", "404"] + paths)
    check(r.returncode == 1 and "R7" in r.stderr, "negative control: --membership-status 404 -> exit 1, rule R7",
          f"negative control 404 -> exit {r.returncode}, stderr {r.stderr.strip()[:200]}")


def token_counts(stage):
    out = {OWNER_TOKEN: {}, ZERO_TOKEN: {}}
    for rel in sorted(files_under(stage)):
        with open(os.path.join(stage, rel), "rb") as f:
            data = f.read()
        for tok in out:
            n = data.count(tok.encode())
            if n:
                out[tok][rel] = n
    return out


def crit4(c, stage):
    print("-- criterion 4: placeholders cannot leak")
    counts = token_counts(stage)
    for tok, want in TOKEN_LOCATIONS.items():
        shown = tok if tok == OWNER_TOKEN else "forty zeros"
        check(counts[tok] == want and sum(want.values()) > 0, f"token {shown} found exactly where intended: {counts[tok]}",
              f"token {shown}: found {counts[tok]}, intended {want}")
    # a copy filled with the sample account and commit must have no token left, and criteria 1 and 3 must still pass
    cp = os.path.join(c.sub("filled"), "test-mod")
    shutil.copytree(stage, cp)
    r1 = run([sys.executable, c.fill, "mod", "--account", SAMPLE_ACCOUNT, "--file", os.path.join(cp, "hello-world", "mod.lua")])
    r2 = run([sys.executable, c.fill, "entry", "--account", SAMPLE_ACCOUNT, "--commit", SAMPLE_COMMIT,
              "--file", os.path.join(cp, "registry-pr", "entry.json")])
    check(r1.returncode == 0 and r2.returncode == 0, "fill_placeholders.py mod and entry ran on the copy (sample-owner, forty 'a')",
          f"fill_placeholders.py exits {r1.returncode}/{r2.returncode}: {(r1.stderr + r2.stderr).strip()[:300]}")
    left = token_counts(cp)
    check(not left[OWNER_TOKEN] and not left[ZERO_TOKEN], "zero placeholder tokens remain in the filled copy",
          f"tokens remain after filling: {left}")
    with open(os.path.join(cp, "hello-world", "mod.lua"), encoding="utf-8") as f:
        check(f'source = "https://github.com/{SAMPLE_ACCOUNT}/wom-test-hello-world"' in f.read(), "filled mod.lua source is the sample URL",
              "filled mod.lua source is not the sample URL")
    check(SAMPLE_COMMIT in open(os.path.join(cp, "registry-pr", "entry.json"), encoding="utf-8").read(), "filled entry carries the sample commit")
    crit1_static(c, os.path.join(cp, "hello-world"), "filled copy")
    crit3(c, cp, "filled copy")
    crit1_build(c, cp, "filled copy")
    # the script's own refusals (negative controls)
    scratch = c.sub("refusals")
    ent = os.path.join(scratch, "entry.json")
    shutil.copy(os.path.join(stage, "registry-pr", "entry.json"), ent)
    for what, args in (("an all-zero commit", ["--account", "x", "--commit", ZERO_TOKEN]),
                       ("a non-hex commit", ["--account", "x", "--commit", "z" * 40]),
                       ("the placeholder as account", ["--account", OWNER_TOKEN, "--commit", SAMPLE_COMMIT])):
        r = run([sys.executable, c.fill, "entry"] + args + ["--file", ent])
        check(r.returncode == 2 and open(ent, "rb").read() == open(os.path.join(stage, "registry-pr", "entry.json"), "rb").read(),
              f"fill_placeholders.py refuses {what} (exit 2, file untouched)", f"fill_placeholders.py on {what}: exit {r.returncode} or file changed")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--stage", required=True)
    ap.add_argument("--registry", required=True)
    ap.add_argument("--generator", required=True)
    ap.add_argument("--fill-script", required=True)
    ap.add_argument("--only", default="1,1build,2,3,4")
    a = ap.parse_args(argv)
    only = set(a.only.split(","))
    c = Ctx(a)
    try:
        hello = os.path.join(c.stage, "hello-world")
        if "1" in only:
            crit1_static(c, hello, "staging tree")
        if "1build" in only:
            # the build runs on a filled copy of the staging tree so the committed mod.lua is what an author would publish
            cp = os.path.join(c.sub("buildcopy"), "test-mod")
            shutil.copytree(c.stage, cp)
            r = run([sys.executable, c.fill, "mod", "--account", SAMPLE_ACCOUNT, "--file", os.path.join(cp, "hello-world", "mod.lua")])
            if r.returncode != 0:
                bad(f"cannot fill a copy of mod.lua for the build: {r.stderr.strip()[:200]}")
            else:
                crit1_build(c, cp, "staging tree, filled copy")
        if "2" in only:
            crit2(c, c.stage)
        if "3" in only:
            crit3(c, c.stage, "staging tree")
        if "4" in only:
            crit4(c, c.stage)
    finally:
        c.cleanup()
    print(f"check_tree: {'ALL OK' if not fails else str(fails) + ' FAIL'}")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
