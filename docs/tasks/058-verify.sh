#!/usr/bin/env bash
# Task 058 verification artefact (MANAGER.md 2c): criteria 1, 2 and 8.  Loopback only, no network beyond 127.0.0.1.
#   docs/tasks/058-verify.sh            run the client matrix + filename checks; exit 0 iff all pass
#   docs/tasks/058-verify.sh --mutate   also break the probe three ways and require the named check to turn red
# Criteria 3-6 are live/human and are not scripted.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
M="$REPO/tools/probe/archive-url/matrix.py"
echo "== environment"; python3 -I --version; node --version; curl --version | head -1; wget --version | head -1
echo "== baseline (must be green)"
out="$(python3 -I "$M")"; rc=$?
printf '%s\n' "$out" | tail -n 25
if [ $rc -ne 0 ]; then echo "VERIFY FAIL: baseline red (rc=$rc)"; exit 1; fi
# --- own-change check (REVIEW-CHECKLIST item 12): fixed SHAs only, no moving ref ---------------------------
# BASE  = the main commit this branch merged (second parent of merge 96e1b5e), as a fixed SHA.
# FINAL = the last content commit of the task (the commit after it only records these pins and the log).
PIN_BASE=3ca6fbfd873ba38f6c9ebbb12f757e5ca40365f6
PIN_FINAL=557780ef631c77b9e1e8991b56d1583cc3bf3219
DECLARED="docs/research/archive-url-probe.md
docs/tasks/058-archive-url-probe.md
docs/tasks/058-verify.sh
tools/probe/archive-url/fixture_server.py
tools/probe/archive-url/live-captures-2026-10-26.txt
tools/probe/archive-url/live_client.mjs
tools/probe/archive-url/live_client.py
tools/probe/archive-url/matrix.py
tools/probe/archive-url/node_client.mjs
tools/probe/archive-url/pages-tree/404.html
tools/probe/archive-url/pages-tree/README.md
tools/probe/archive-url/pages-tree/_redirects
tools/probe/archive-url/pages-tree/a/index.html
tools/probe/archive-url/pages-tree/b.tar.gz
tools/probe/archive-url/pages-tree/c/index.html
tools/probe/archive-url/pages-tree/target.txt"
own_change() { # base final -> prints ok/FAIL lines, returns 0 iff the diff names exactly DECLARED
  local b="$1" f="$2" got want
  git -C "$REPO" cat-file -e "${b}^{commit}" 2>/dev/null || { echo "FAIL: own-change pin BASE $b is unreachable"; return 1; }
  git -C "$REPO" cat-file -e "${f}^{commit}" 2>/dev/null || { echo "FAIL: own-change pin FINAL $f is unreachable"; return 1; }
  got="$(git -C "$REPO" diff --name-only "$b" "$f" | LC_ALL=C sort)" || { echo "FAIL: git diff $b $f failed"; return 1; }
  want="$(printf '%s\n' "$DECLARED" | LC_ALL=C sort)"
  if [ "$got" = "$want" ]; then echo "ok: git diff --name-only ${b:0:9} ${f:0:9} == the declared set ($(printf '%s\n' "$got" | wc -l) files)"; return 0; fi
  echo "FAIL: own-change file set differs from the declared set (< declared only, > in range only)"; diff <(printf '%s\n' "$want") <(printf '%s\n' "$got") | sed 's/^/    /'; return 1
}
echo "== own-change check (pinned SHAs)"
own_change "$PIN_BASE" "$PIN_FINAL" || { echo "VERIFY FAIL: own-change"; exit 1; }
[ "${1:-}" = "--mutate" ] || { echo "VERIFY OK (baseline only)"; exit 0; }
FAIL=0
mut() { # name, env value, regex the RED lines must match
  local o rc
  o="$(WOM058_MUTATE="$2" python3 -I "$M")"; rc=$?
  echo "== mutation $1 (rc=$rc)"; printf '%s\n' "$o" | grep -E '^RED:|^RESULT:' | head -n 6
  if [ $rc -eq 0 ] || ! printf '%s\n' "$o" | grep -Eq "^RED: $3"; then echo "MUTATION NOT CAUGHT: $1"; FAIL=1; fi
}
mut "redirect status broken in server fixture (302/301 answer 200)" status "C1 positive control 302"
mut "SHA comparison dropped" sha "C3 meta-refresh is NOT followed"
mut "client errors swallowed" swallow "C6 "
# own-change mutations: a synthetic commit (plumbing only, no ref, no working-tree change) with one extra file; an unreachable pin
tmpidx="$(mktemp)"; trap 'rm -f "$tmpidx"' EXIT
export GIT_INDEX_FILE="$tmpidx"; git -C "$REPO" read-tree "$PIN_FINAL"
blob="$(printf 'extra\n' | git -C "$REPO" hash-object -w --stdin)"
git -C "$REPO" update-index --add --cacheinfo "100644,$blob,docs/extra-file-058.txt"
tree="$(git -C "$REPO" write-tree)"; unset GIT_INDEX_FILE
extra="$(git -C "$REPO" -c user.name=m -c user.email=m@m commit-tree "$tree" -p "$PIN_FINAL" -m mutation)"
o="$(own_change "$PIN_BASE" "$extra" 2>&1)"; rc=$?
echo "== mutation extra file in the range (rc=$rc)"; printf '%s\n' "$o" | head -n 4
if [ $rc -eq 0 ] || ! printf '%s\n' "$o" | grep -q 'docs/extra-file-058.txt'; then echo "MUTATION NOT CAUGHT: extra file in range"; FAIL=1; fi
o="$(own_change 0000000000000000000000000000000000000001 "$PIN_FINAL" 2>&1)"; rc=$?
echo "== mutation unreachable pin (rc=$rc)"; printf '%s\n' "$o" | head -n 2
if [ $rc -eq 0 ] || ! printf '%s\n' "$o" | grep -q 'unreachable'; then echo "MUTATION NOT CAUGHT: unreachable pin"; FAIL=1; fi
if [ $FAIL -eq 0 ]; then echo "VERIFY OK (baseline green; 5/5 mutations caught)"; else echo "VERIFY FAIL"; exit 1; fi
