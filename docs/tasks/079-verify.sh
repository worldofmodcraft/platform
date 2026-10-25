#!/usr/bin/env bash
# Task 079 verification (MANAGER.md section 2c). Run from the worktree root, foreground.
#   docs/tasks/079-verify.sh    AC1 live check on HEAD, AC2 mutations, AC4 pinned own-change scope check
# AC3 (every docs/tasks/*-verify.sh green on HEAD, one at a time) is run by hand and logged, not scripted here.
# Mutations happen only on copies under $TMPDIR; this tree is never written to.
set -u
export PYTHONDONTWRITEBYTECODE=1 LC_ALL=C.UTF-8
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$HERE" || exit 2
PIN_BASE="8004828"
PIN_FINAL="bd6d0a63b4999fd53f246a58754017b3d2de4bd3"
SCOPE="docs/manager/rule0.reference.md tools/manager/check-rule0.sh docs/tasks/079-rule0-live-guard.md docs/tasks/079-verify.sh"
CHK=tools/manager/check-rule0.sh
fails=0
ok()  { echo "  ok   $*"; }
bad() { echo "  FAIL $*"; fails=$((fails + 1)); }
TMP="$(mktemp -d "${TMPDIR:-/tmp}/wom079-XXXXXX")"; trap 'rm -rf -- "$TMP"' EXIT
# want RC NAME CLAUDE REF : run the check on the given files, compare the exit code
want() { local w=$1 n=$2 rc; bash "$CHK" "$3" "$4" >"$TMP/out" 2>&1; rc=$?; if [ "$rc" = "$w" ]; then ok "$n -> exit $rc"; else bad "$n -> exit $rc, expected $w"; head -5 "$TMP/out" | cut -c1-160; fi; }

echo "== AC1 live: HEAD"
bash "$CHK" >"$TMP/out" 2>&1; rc=$?; [ "$rc" = 0 ] && ok "check-rule0.sh on HEAD -> exit 0" || { bad "HEAD -> exit $rc"; head -5 "$TMP/out"; }

echo "== AC2 mutations"
C=CLAUDE.md; R=docs/manager/rule0.reference.md
s=$(grep -n '^0\. \*\*THE TOKEN GUARD' $C | cut -d: -f1); e=$(grep -n '^1\. \*\*English everywhere' $C | cut -d: -f1)
m=$(grep -n -x -F '<!-- RULE0-REFERENCE-BEGIN -->' $R | cut -d: -f1)
sus=$(grep -n 'SUSPENDED by Ludwig' $C | cut -d: -f1)
[ -n "$s" ] && [ -n "$e" ] && [ -n "$m" ] && [ -n "$sus" ] || { echo "  FAIL cannot locate anchors"; exit 1; }
want 0 "unmutated copies" $C $R
sed "$((s + 5))s/Stop at 90/Stop at 91/" $C >"$TMP/c1"; cmp -s $C "$TMP/c1" && bad "one-char mutation did not change the file"
want 1 "one character changed inside rule 0" "$TMP/c1" $R
sed "${sus}d" $C >"$TMP/c2"; want 1 "suspension paragraph deleted" "$TMP/c2" $R
sed "${s}d" $C >"$TMP/c3"; want 2 "rule 0 heading removed" "$TMP/c3" $R
want 2 "reference file removed" $C "$TMP/does-not-exist.md"
{ sed -n "1,$((e - 1))p" $C; sed -n "${s},$((e - 1))p" $C; sed -n "${e},\$p" $C; } >"$TMP/c4"; want 2 "duplicated rule-0 block" "$TMP/c4" $R
sed "$((e + 1))s/Ludwig may/Ludwig might/" $C >"$TMP/c5"; cmp -s $C "$TMP/c5" && bad "outside mutation did not change the file"
want 0 "change outside rule 0 (rule 1 text)" "$TMP/c5" $R
sed "$((s + 5))s/Stop at 90/Stop at 91/" $C >"$TMP/c6"; sed "$((m + 6))s/Stop at 90/Stop at 91/" $R >"$TMP/r6"
cmp -s $R "$TMP/r6" && bad "reference mutation did not change the file"
want 0 "rule 0 and reference changed identically" "$TMP/c6" "$TMP/r6"
sed "${m}d" $R >"$TMP/r7"; want 2 "reference marker removed" $C "$TMP/r7"
{ sed -n "1,${m}p" $R; } >"$TMP/r8"; want 2 "reference empty after marker" $C "$TMP/r8"
sed "${s}s/^0\. /0.  /" $C >"$TMP/c10"; want 2 "heading reworded so it no longer matches" "$TMP/c10" $R
sed "$((s + 5))s/\$/ /" $C >"$TMP/c11"; want 1 "trailing space added (byte-exact, no normalising)" "$TMP/c11" $R

echo "== AC4 own-change scope $PIN_BASE..$PIN_FINAL"
if [ "$PIN_FINAL" = "__FIN""AL__" ]; then bad "PIN_FINAL not recorded"; else
  extra=$(git diff --name-only "$PIN_BASE" "$PIN_FINAL" | grep -v -x -F -f <(printf '%s\n' $SCOPE))
  [ -z "$extra" ] && ok "only in-scope files changed" || bad "out-of-scope files: $extra"
  git diff --quiet "$PIN_BASE" "$PIN_FINAL" -- CLAUDE.md docs/manager/MANAGER.md && ok "CLAUDE.md and MANAGER.md untouched" || bad "CLAUDE.md or MANAGER.md changed"
fi
echo; [ "$fails" -eq 0 ] && { echo "079-verify: ALL OK"; exit 0; } || { echo "079-verify: $fails FAIL"; exit 1; }
