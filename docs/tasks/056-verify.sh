#!/usr/bin/env bash
# Task 056 verification: docs/architecture/system-overview.md
#
# WHAT THIS PROVES: the note is complete (required sections; every node and edge id from
# depgraph.json, plus edge ids only in depgraph.md), tagged (State column), honest (required and
# forbidden strings), resolvable (cited paths exist), free of secret material, and that its
# "hosts nothing" table has no row on an owner's machine. WHAT IT CANNOT PROVE: that the prose is
# true. Criterion 9 (a human review) is separate and recorded in the task log.
#
# Usage: 056-verify.sh [--note FILE] [--skip-controls] [--no-fetch]
# Env:   REGISTRY_REPO (default ~/registry), SITE_REPO (default ~/site): local clones whose
#        origin/main is read with `git show`. Unless --no-fetch is given the script first runs a
#        read-only `git fetch origin` in each and prints the sha it then reads; a failed fetch is
#        a failure of the run. DEPGRAPH_MD and TASKLOG override the depgraph.md and task-log paths
#        (used by the controls).
# Citation rule (criterion 4): an unqualified `contracts/...` path is resolved in the registry
#        only; an unqualified `docs/...` or `.github/...` path in THIS repository only; a path in
#        another repository must be written `site:<path>` or `registry:<path>`; `branch:path`
#        (branch not site/registry) is checked in this repository with git cat-file.
# State rule (criterion 3): a `built` row/step must cite an observation `obs L<n>` that is defined
#        as a line `- L<n> ...` in the task log, and must not carry an unverified marker.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
NOTE="$ROOT/docs/architecture/system-overview.md"
CONTROLS=1; FETCH=1
while [ $# -gt 0 ]; do
  case "$1" in
    --note) NOTE="$2"; shift 2;;
    --skip-controls) CONTROLS=0; shift;;
    --no-fetch) FETCH=0; shift;;
    *) echo "unknown argument $1" >&2; exit 2;;
  esac
done
export REGISTRY_REPO="${REGISTRY_REPO:-$HOME/registry}" SITE_REPO="${SITE_REPO:-$HOME/site}"
export DEPGRAPH_MD="${DEPGRAPH_MD:-$ROOT/docs/architecture/depgraph.md}" TASKLOG="${TASKLOG:-$ROOT/docs/tasks/056-architecture-note.md}"
if [ $FETCH = 1 ]; then
  for r in "$REGISTRY_REPO" "$SITE_REPO"; do
    git -C "$r" fetch -q origin || { echo "FAIL fetch of $r failed (offline? use --no-fetch to read the existing origin/main)"; exit 2; }
    echo "fetched $r origin/main=$(git -C "$r" rev-parse --short origin/main)"
  done
fi

run_checks() {  # $1 = note file ; prints FAIL lines; exit 1 if any
python3 -I - "$1" "$ROOT" <<'PY'
import json, os, re, subprocess, sys
note_path, root = sys.argv[1], sys.argv[2]
REG, SITE = os.environ["REGISTRY_REPO"], os.environ["SITE_REPO"]
fails = []
def fail(c, m): fails.append(f"FAIL [{c}] {m}")
try: text = open(note_path, encoding="utf-8").read()
except OSError as e:
    print(f"FAIL [1] cannot read note: {e}"); sys.exit(1)
lines = text.split("\n")

# ---- sections (criterion 1)
REQ = ["What runs where","What is stored where","The owner's machines host nothing",
       "Moving off GitHub","If a piece disappears","State of this document"]
heads = {}  # name -> (start,end) line idx of body
h2 = [(i, l[3:].strip()) for i, l in enumerate(lines) if l.startswith("## ")]
for k, (i, name) in enumerate(h2):
    end = h2[k+1][0] if k+1 < len(h2) else len(lines)
    heads[name] = (i+1, end)
found = [r for r in REQ if r in heads]
if not found: fail(1, "zero required headings found")
for r in REQ:
    if r not in heads: fail(1, f"missing heading '## {r}'")
def section(name):
    if name not in heads: return []
    a, b = heads[name]; return lines[a:b]
def body_outside_state():
    a = heads.get("State of this document")
    return "\n".join(lines[:a[0]-1] if a else lines)

# ---- tables
def tables(ls):
    out, cur = [], []
    for l in ls + [""]:
        if l.startswith("|"): cur.append(l)
        else:
            if cur: out.append(cur); cur = []
    res = []
    for t in out:
        if len(t) < 2: continue
        hdr = [c.strip() for c in t[0].strip().strip("|").split("|")]
        rows = [[c.strip() for c in r.strip().strip("|").split("|")] for r in t[2:]]
        res.append((hdr, rows, t))
    return res
alltabs = tables(lines)

# ---- criterion 2: ids
g = json.load(open(os.path.join(root, "docs/architecture/depgraph.json")))
node_ids = [n["id"] for n in g["nodes"]]; edge_ids = [e["id"] for e in g["edges"]]
md = open(os.environ["DEPGRAPH_MD"], encoding="utf-8").read()
md_edges = re.findall(r"^\|\s*(E\d+)\s*\|", md, re.M)
drift = [e for e in md_edges if e not in edge_ids]
if not node_ids or not edge_ids: fail(2, "read zero node or edge ids from depgraph.json")
tabrows = [l for t in alltabs for l in t[2]]
first_cells = [ (l.strip().strip('|').split('|')[0].strip()) for l in tabrows]
for i in node_ids + edge_ids + drift:
    if not any(re.fullmatch(r"`?%s`?" % re.escape(i), c) for c in first_cells):
        fail(2, f"id {i} has no table row in the note")
state_text = "\n".join(section("State of this document"))
for e in drift:
    if not (e in state_text and re.search(r"drift", state_text, re.I)):
        fail(2, f"edge {e} is in depgraph.md only; State of this document must name it and the drift")
print(f"info: nodes={node_ids} edges={len(edge_ids)} md-only={drift}")

# ---- criterion 3: tags
TAGS = {"built","specified","not built"}
checked = 0
for hdr, rows, raw in alltabs:
    if "State" not in hdr: continue
    ci = hdr.index("State")
    for r in rows:
        checked += 1
        cell = r[ci].strip("`").strip() if len(r) > ci else ""
        if len(r) != len(hdr) or r[ci] != f"`{cell}`" or cell not in TAGS:
            fail(3, f"row without exactly one tag: {r[0] if r else raw}  (State cell: {r[ci] if len(r)>ci else 'MISSING'})")
if checked == 0: fail(3, "no table with a State column found")
body = body_outside_state()
n_body = body.count("[unverified")
m = re.search(r"Unverified markers in body:\*{0,2}\s*(\d+)", state_text)
if not m: fail(3, "State of this document does not state 'Unverified markers in body: N'")
elif int(m.group(1)) != n_body: fail(3, f"stated unverified count {m.group(1)} != body count {n_body}")
print(f"info: tagged rows={checked} unverified-in-body={n_body}")

# ---- criterion 3b: every `built` row/step cites an observation defined in the log, no unverified marker
try: logtxt = open(os.environ["TASKLOG"], encoding="utf-8").read()
except OSError as e: logtxt = ""; fail(3, f"cannot read task log: {e}")
defined = set(re.findall(r"^- L(\d+)\b", logtxt, re.M))
if not defined: fail(3, "task log defines no observations (lines '- L<n> ...')")
CLAIMS = {"protect": "protect"}  # claim word in a built row -> must appear in each cited observation line, which must not say NOT observed
obsline = {m.group(1): m.group(2) for m in re.finditer(r"^- L(\d+)\b(.*)$", logtxt, re.M)}
def built_ok(label, rowtext):
    for w in CLAIMS:
        if re.search(w, rowtext, re.I):
            ids2 = [x for r in re.findall(r"obs ((?:L\d+(?:, )?)+)", rowtext) for x in re.findall(r"L(\d+)", r)]
            if not any(i in obsline and re.search(CLAIMS[w], obsline[i], re.I) and "NOT observed" not in obsline[i] for i in ids2):
                fail(3, f"`built` item claims '{w}' but no cited observation shows it: {label}")
    if "[unverified" in rowtext: fail(3, f"`built` item carries an unverified marker: {label}")
    refs = re.findall(r"obs ((?:L\d+(?:, )?)+)", rowtext)
    ids = [x for r in refs for x in re.findall(r"L(\d+)", r)]
    if not ids: fail(3, f"`built` item cites no observation (obs L<n>): {label}")
    for i in ids:
        if i not in defined: fail(3, f"`built` item cites L{i}, not defined in the task log: {label}")
nbuilt = 0
for hdr, rows, raw in alltabs:
    if "State" not in hdr: continue
    ci = hdr.index("State")
    for r in rows:
        if len(r) > ci and r[ci] == "`built`":
            nbuilt += 1; built_ok(r[0], " | ".join(r))
steps = re.split(r"\n(?=\d+\. )", "\n".join(section("Moving off GitHub")))
for st in steps:
    if not re.match(r"\d+\. ", st): continue
    tg = re.findall(r"State:\s+`(built|specified|not built)`", st)
    if len(tg) != 1: fail(3, f"exit step without exactly one State tag: {st[:40]!r}")
    elif tg[0] == "built": nbuilt += 1; built_ok(st[:30], st)
print(f"info: built items checked for observations={nbuilt}; defined observations={len(defined)}")

# ---- criterion 4: cited paths
def git_show(repo, path):
    return subprocess.run(["git","-C",repo,"cat-file","-e",f"origin/main:{path}"],
        capture_output=True).returncode == 0
cites = re.findall(r"`([^`\n]+)`", text)
PFX = r"(?:docs|contracts|\.github)/\S+"
paths = [c for c in cites if re.match(r"^(?:[\w./-]+:)?" + PFX + "$", c)]
if not paths: fail(4, "note cites zero paths")
def cat(repo, ref, path):
    return subprocess.run(["git","-C",repo,"cat-file","-e",f"{ref}:{path}"], capture_output=True).returncode == 0
seen = set()
for c in paths:
    if c in seen: continue
    seen.add(c)
    q, _, p = c.partition(":") if re.match(r"^[\w./-]+:", c) else ("", "", c)
    if not q: p = c
    if q == "": 
        ok = cat(REG, "origin/main", p) if p.startswith("contracts/") else (os.path.exists(os.path.join(root, p)))
        where = "registry" if p.startswith("contracts/") else "this repository"
    elif q == "site": ok, where = cat(SITE, "origin/main", p), "site"
    elif q == "registry": ok, where = cat(REG, "origin/main", p), "registry"
    else: ok, where = cat(root, q, p) or cat(root, "origin/" + q, p), "branch " + q
    if not ok: fail(4, f"cited path does not resolve in {where}: {c}")
print(f"info: distinct cited paths={len(seen)}")

# ---- criterion 5: hosts-nothing table
sec = section("The owner's machines host nothing")
rt = [t for t in tables(sec) if "Runs on" in t[0]]
BAD = re.compile(r"WSL|self-hosted|\bVPS\b|owner'?s? (machine|laptop|pc|computer)|\blocalhost\b|\bLudwig\b|\bhome (server|machine)", re.I)
if not rt: fail(5, "no table with a 'Runs on' column in 'The owner's machines host nothing'")
for hdr, rows, raw in rt:
    ri, ki = hdr.index("Runs on"), (hdr.index("Kind") if "Kind" in hdr else None)
    if ki is None: fail(5, "runtime table has no Kind column"); continue
    if not rows: fail(5, "runtime table has zero rows")
    for r in rows:
        if BAD.search(r[ri]): fail(5, f"row runs on an owner/self-hosted machine: {r[0]} -> {r[ri]}")
        if r[ki] == "job" and "GitHub-hosted runner" not in r[ri]:
            fail(5, f"job row does not name the GitHub-hosted runner: {r[0]}")
        if r[ki] not in ("job","service"): fail(5, f"row Kind must be job or service: {r[0]}")

# ---- criterion 6: honesty
mo = "\n".join(section("Moving off GitHub"))
for s in ("source_archive","append-only"):
    if s not in mo: fail(6, f"'{s}' not in 'Moving off GitHub'")
for s in ("phase 1.5","ADR-0077"):
    if s not in text: fail(6, f"'{s}' absent from note")
for s in ("fully provider-neutral","vendor-neutral","no lock-in"):
    if re.search(re.escape(s), text, re.I): fail(6, f"forbidden phrase present: '{s}'")

# ---- criterion 7: secrets
km = open(os.path.join(root,"docs/architecture/key-management.md"), encoding="utf-8").read()
for pat, what in ((r"minisign encrypted secret key","minisign secret-key header"),
                  (r"ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}","GitHub token"),
                  (r"wom-keys","private key path")):
    for i, l in enumerate(lines, 1):
        if re.search(pat, l): fail(7, f"line {i}: {what}")
for k in re.findall(r"RW[A-Za-z0-9+/]{50,}", text):
    if k not in km: fail(7, "public key text differs from key-management.md")
for k in re.findall(r"\b[0-9A-F]{16}\b", text):
    if k not in km: fail(7, f"16-hex id {k} not in key-management.md")

# ---- criterion 8: index and stamp
dg = "\n".join(md.split("\n")[:12])
if "system-overview.md" not in dg: fail(8, "depgraph.md header does not link system-overview.md")
lr = re.search(r"\*\*Last reviewed:\*\*\s*(\d{4}-\d{2}-\d{2})", "\n".join(lines[:12]))
if not lr: fail(8, "no 'Last reviewed' date in note header")
dates = []
import glob
for f in glob.glob(os.path.join(root,"docs/tasks/05[6-8]-*.md")):
    for d in re.findall(r"spec-approved \(manager, (\d{4}-\d{2}-\d{2})", open(f,encoding="utf-8").read()): dates.append(d)
if not dates: fail(8, "found no spec-approval dates of dependent tasks")
elif lr and lr.group(1) < max(dates): fail(8, f"last reviewed {lr.group(1)} < newest dependency {max(dates)}")

for f in fails: print(f)
sys.exit(1 if fails else 0)
PY
}

PASS=0; BAD=0
ok()   { echo "PASS  $1"; PASS=$((PASS+1)); }
bad()  { echo "FAIL  $1"; BAD=$((BAD+1)); }

echo "== main run: $NOTE"
if out=$(run_checks "$NOTE"); then echo "$out"; ok "all checks on the real note"; else echo "$out"; bad "real note failed (above)"; fi

[ $CONTROLS = 1 ] || { echo "== $PASS pass, $BAD fail"; [ $BAD = 0 ]; exit $?; }

echo "== mutation and positive controls (each must be CAUGHT, naming what we broke)"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
expect() {  # name, mutated-file, expected-substring
  if o=$(run_checks "$2" 2>&1); then bad "control '$1' NOT caught (checker passed a broken note)";
  elif echo "$o" | grep -qF -- "$3"; then ok "control '$1' caught: $(echo "$o" | grep -F -- "$3" | head -1)";
  else bad "control '$1' failed, but not naming '$3': $(echo "$o" | head -2)"; fi
}
N="$NOTE"
# 2: remove one edge row (E7) and one node row
grep -v '^| E7 |' "$N" > "$T/m2e.md";                 expect "remove row E7" "$T/m2e.md" "id E7 has no table row"
grep -v '^| N6 |' "$N" > "$T/m2n.md";                 expect "remove row N6" "$T/m2n.md" "id N6 has no table row"
grep -v '^| E16 |' "$N" > "$T/m2d.md";                expect "remove row E16 (md-only edge)" "$T/m2d.md" "id E16 has no table row"
# 1: heading removed
sed 's/^## Moving off GitHub$/## Elsewhere/' "$N" > "$T/m1.md"; expect "rename heading" "$T/m1.md" "missing heading '## Moving off GitHub'"
printf '# empty\n' > "$T/m1z.md";                     expect "no headings at all" "$T/m1z.md" "zero required headings"
# 3: untagged row, and wrong unverified count
sed '0,/^| N2 | .*`built` |$/s/`built` |$/ |/' "$N" > "$T/m3.md"; expect "strip a state tag" "$T/m3.md" "row without exactly one tag"
sed 's/^- \*\*Unverified markers in body:\*\* .*/- **Unverified markers in body:** 99/' "$N" > "$T/m3c.md"; expect "wrong unverified count" "$T/m3c.md" "stated unverified count 99"
# 4: bogus path, zero paths
{ cat "$N"; echo; echo 'See `docs/architecture/does-not-exist.md`.'; } > "$T/m4.md"; expect "cite a missing file" "$T/m4.md" "does not resolve in this repository: docs/architecture/does-not-exist.md"
sed 's/`\(docs\|contracts\|\.github\|proposal\|site:\.github\)\//`x\//g; s/:docs\//:x\//g' "$N" > "$T/m4z.md"; expect "cite zero paths" "$T/m4z.md" "cites zero paths"
# 5: positive control row on WSL, and a job not on the runner
sed '0,/^| Static site serving (N8) | service | GitHub Pages servers |/s//| Static site serving (N8) | service | a VPS under the owner'"'"'s desk |/' "$N" > "$T/m5.md"; expect "row on a VPS" "$T/m5.md" "owner/self-hosted machine"
sed '0,/^| Site build and deploy (N7) | job | GitHub-hosted runner (`ubuntu-latest`) |/s//| Site build and deploy (N7) | job | WSL on the owner machine |/' "$N" > "$T/m5b.md"; expect "job on WSL" "$T/m5b.md" "owner/self-hosted machine"
sed '0,/^| Site build and deploy (N7) | job | GitHub-hosted runner (`ubuntu-latest`) |/s//| Site build and deploy (N7) | job | some cloud |/' "$N" > "$T/m5c.md"; expect "job not on a GitHub-hosted runner" "$T/m5c.md" "does not name the GitHub-hosted runner"
# 6: honesty
{ cat "$N"; echo 'The design is fully provider-neutral.'; } > "$T/m6.md";  expect "forbidden phrase" "$T/m6.md" "forbidden phrase present: 'fully provider-neutral'"
{ cat "$N"; echo 'There is no lock-in.'; } > "$T/m6b.md";                  expect "forbidden phrase 2" "$T/m6b.md" "forbidden phrase present: 'no lock-in'"
sed 's/phase 1\.5/a later phase/g' "$N" > "$T/m6c.md";                    expect "drop 'phase 1.5'" "$T/m6c.md" "'phase 1.5' absent"
# 7: secrets
{ cat "$N"; echo 'untrusted comment: minisign encrypted '"sec""ret key"; } > "$T/m7.md"; expect "secret header" "$T/m7.md" "minisign secret-key header"
{ cat "$N"; echo 'cat ~/wom-keys/x'; } > "$T/m7b.md";                           expect "key path" "$T/m7b.md" "private key path"
{ cat "$N"; echo "token ghp_$(printf 'a%.0s' $(seq 1 36))"; } > "$T/m7c.md";    expect "token" "$T/m7c.md" "GitHub token"
# 8: stamp older than the dependency
sed 's/^- \*\*Last reviewed:\*\* .*/- **Last reviewed:** 2026-01-01/' "$N" > "$T/m8.md"; expect "stale review stamp" "$T/m8.md" "< newest dependency"
# fix round 1 controls
# fix round 2 control: re-add the unobserved protection claim to built rows
sed '/^| Contracts, `reserved-namespaces.json` |/s/reviewed pull request |/reviewed pull request; `main` is protected |/' "$N" > "$T/r2a.md"; expect "re-add 'main is protected' to a built row" "$T/r2a.md" "claims 'protect' but no cited observation shows it: Contracts"
sed '/^| Decisions, task ledger/s/pull request |/pull request; `main` is protected |/' "$N" > "$T/r2b.md"; expect "re-add 'main is protected' to second built row" "$T/r2b.md" "claims 'protect' but no cited observation shows it: Decisions"
sed '/^| N3 |/s/`specified` |$/`built` |/' "$N" > "$T/r1a.md";   expect "re-tag specified row N3 as built" "$T/r1a.md" "item cites no observation (obs L<n>): N3"
sed '/^| N2 |/s/obs L[0-9, L]*/obs L99/' "$N" > "$T/r1b.md";    expect "built row cites undefined observation" "$T/r1b.md" "cites L99, not defined"
sed '/^| N8 |/s/(obs [^)]*)/[unverified — x]/' "$N" > "$T/r1c.md"; expect "built row with unverified marker" "$T/r1c.md" "unverified marker: N8"
python3 -I - "$N" "$T/r1d.md" <<'PYE'
import sys
s=open(sys.argv[1]).read(); a="State:\n   `specified`; a statement"; assert a in s
open(sys.argv[2],'w').write(s.replace(a,"State:\n   `built`; a statement",1))
PYE
expect "exit step 9 re-tagged built" "$T/r1d.md" "item cites no observation" 
{ cat "$N"; echo 'See `docs/build.md` and `.github/workflows/deploy.yml`.'; } > "$T/r1e.md"; expect "cite a site-only path unqualified" "$T/r1e.md" "does not resolve in this repository: docs/build.md"
{ cat "$N"; echo 'See `contracts/nope.md`.'; } > "$T/r1f.md";      expect "cite a missing contract" "$T/r1f.md" "does not resolve in registry: contracts/nope.md"
grep -v 'system-overview.md' "$DEPGRAPH_MD" > "$T/dg.md";       DEPGRAPH_MD="$T/dg.md" expect "depgraph link removed" "$N" "does not link system-overview.md"
awk '/^## /{s=($0=="## Moving off GitHub")} s{gsub(/source_archive/,"src_url")} {print}' "$N" > "$T/r1g.md"; expect "no source_archive in Moving off GitHub" "$T/r1g.md" "'source_archive' not in 'Moving off GitHub'"
awk '/^## /{s=($0=="## Moving off GitHub")} s{gsub(/append-only/,"immutable")} {print}' "$N" > "$T/r1h.md"; expect "no append-only in Moving off GitHub" "$T/r1h.md" "'append-only' not in 'Moving off GitHub'"
echo "== $PASS pass, $BAD fail"
[ $BAD = 0 ]
