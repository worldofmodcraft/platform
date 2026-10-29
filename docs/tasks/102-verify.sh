#!/usr/bin/env bash
# Task 102 verification (MANAGER.md section 2c). Run from a FRESH CLONE of the task branch, foreground, on a QUIET machine.
#   docs/tasks/102-verify.sh
# Proves that docs/tasks/096-verify.sh, as fixed by this task, stays green on platform main and after any later commit, and that the
# unfixed blob (at the merge M of task 096) does not. Every own-change check reads FIXED SHAs only (Ludwig 2026-10-29: "fixed SHAs only";
# REVIEW-CHECKLIST item 12). Nothing here reads the moving HEAD except to find the repository; no network, no credentials, no env overrides.
# Fixtures are throw-away local clones built from PIN_MAIN (platform main when task 102 was written), never from HEAD.
# PIN_FIX is the 096 fix commit; "PENDING" fails every dependent cell, it never skips.
set -u
export PYTHONDONTWRITEBYTECODE=1 LC_ALL=C.UTF-8
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$HERE" || exit 2

PIN_SPEC="ce82920542ed9af6f9f5234f920395eb790cf40a"   # task 102 spec commit == base of this task's own changes
PIN_MAIN="47c993870a364241b14ae0324f3d0dddd8fbe74d"   # platform main when task 102 started (contains M)
PIN_M="885e1f01d1f0ba63d705c87ceef9e949cbecab1e"      # merge of task 096 (platform PR #94)
PIN_M1="5653515816fb5d028ad0a6d68aa1af944b2ac4b3"     # M^1
PIN_M2="b8970a3f194ff960c6fe68088fa53077749acc98"     # M^2 == 096's FINAL
PIN_BASE="3562c8f519a8f957d1c3b2649dc7f774105dbfd8"   # merge-base(M^1, M^2) == 096's BASE
OLD_BLOB="f0241ac6493c2b47cafa6b264b878170c9a85352"   # 096-verify.sh blob at M (the unfixed script)
PIN_FIX="PENDING"                                     # commit that fixes 096-verify.sh (set in the pin-recording commit)
V=docs/tasks/096-verify.sh; ME=docs/tasks/102-verify.sh; LOGF=docs/tasks/102-repin-096-verify.md
RB=docs/runbooks/site-v1-manual-steps.md
BR=task/096-runbook-m9-m11-done
GITID=(-c user.name=qa -c user.email=qa@example.invalid -c commit.gpgsign=false)

fails=0
ok()  { echo "  ok   $*"; }
bad() { echo "  FAIL $*"; fails=$((fails + 1)); }
TMP="$(mktemp -d "${TMPDIR:-/tmp}/wom102-XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

echo "== quiet machine (AC6)"
others="$(ps -eo pid=,args= | grep -E '[0-9]{3}[a-z]?-verify\.sh' | grep -v grep | grep -v '102-verify.sh' || true)"
if [ -n "$others" ]; then bad "machine not quiet (another *-verify.sh is running); run is not evidence"; echo "$others" | cut -c1-160; else ok "no other *-verify.sh running"; fi

echo "== pins reachable (never skip)"
for k in PIN_SPEC PIN_MAIN PIN_M PIN_M1 PIN_M2 PIN_BASE; do
  git rev-parse --verify -q "${!k}^{commit}" >/dev/null && ok "$k resolves" || bad "$k ${!k} unreachable (fetch the full history)"
done
if [ "$PIN_FIX" = "PENDING" ]; then bad "PIN_FIX not recorded (PENDING)"; FIXOK=0
elif git rev-parse --verify -q "$PIN_FIX^{commit}" >/dev/null; then ok "PIN_FIX resolves"; FIXOK=1
else bad "PIN_FIX $PIN_FIX unreachable"; FIXOK=0; fi

echo "== AC2 pins re-derived from M"
d1="$(git rev-parse "$PIN_M^1" 2>/dev/null)"; d2="$(git rev-parse "$PIN_M^2" 2>/dev/null)"
db="$(git merge-base "$d1" "$d2" 2>/dev/null)"
[ "$d1" = "$PIN_M1" ] && ok "M^1 == PIN_M1" || bad "M^1 is '$d1', expected $PIN_M1"
[ "$d2" = "$PIN_M2" ] && ok "M^2 == PIN_M2 (096 FINAL)" || bad "M^2 is '$d2', expected $PIN_M2"
[ "$db" = "$PIN_BASE" ] && ok "merge-base(M^1,M^2) == PIN_BASE (096 BASE)" || bad "merge-base is '$db', expected $PIN_BASE"
git merge-base --is-ancestor "$PIN_M" "$PIN_MAIN" 2>/dev/null && ok "M is an ancestor of PIN_MAIN" || bad "M not an ancestor of PIN_MAIN"
[ "$(git rev-parse "$PIN_M:$V" 2>/dev/null)" = "$OLD_BLOB" ] && ok "096-verify.sh blob at M == OLD_BLOB" || bad "blob at M differs from OLD_BLOB"
git diff --name-only "$PIN_BASE" "$PIN_M2" 2>/dev/null | sort | tr '\n' ' ' | grep -qxF "docs/runbooks/site-v1-manual-steps.md docs/tasks/096-runbook-m9-m11-done.md docs/tasks/096-verify.sh " \
  && ok "096 range BASE..FINAL changes exactly the three declared files" || bad "096 range BASE..FINAL file set differs"

# Fixture helpers -----------------------------------------------------------------------------------------------
# mkorigin DIR [branch] [synth-outside|synth-inside] : local stand-in for GitHub: main at PIN_MAIN (+ one later commit), optionally the 096 branch at M^2
mkorigin() {
  local d=$1; shift; local mode
  git clone -q --no-hardlinks --no-checkout "$HERE" "$d" 2>/dev/null && git -C "$d" checkout -q -B main "$PIN_MAIN" || { bad "setup: origin clone failed ($d)"; return 1; }
  for mode in "$@"; do case "$mode" in
    branch) git -C "$d" branch "$BR" "$PIN_M2" ;;
    synth-outside) sed -i '1s/$/ (synthetic later edit)/' "$d/$RB" && echo "later synthetic line" >>"$d/$RB"
                   git -C "$d" "${GITID[@]}" commit -q -am "synthetic later commit touching the runbook outside M9-M11" ;;
    synth-inside)  sed -i '/^## .* M9 /a synthetic later line inside M9' "$d/$RB"
                   git -C "$d" "${GITID[@]}" commit -q -am "synthetic later commit touching the runbook inside M9" ;;
  esac; done
  [ "$(git -C "$d" rev-parse --abbrev-ref HEAD)" = main ] || { bad "setup: $d not on main"; return 1; }
}
# runv ORIGIN SCRIPTFILE TAG : work clone of ORIGIN (as a fresh clone would be), SCRIPTFILE laid at docs/tasks/096-verify.sh, run it; sets OUT, RC
runv() {
  local o=$1 s=$2 w="$TMP/w-$3"
  git clone -q --no-hardlinks "$o" "$w" 2>/dev/null || { bad "setup: work clone failed ($3)"; OUT=""; RC=99; return 1; }
  mkdir -p "$w/docs/tasks"; cp "$s" "$w/$V"
  OUT="$(cd "$TMP" && bash "$w/$V" 2>&1)"; RC=$?
  printf '%s\n' "$OUT" >"$TMP/out-$3.txt"
}
git show "$PIN_M:$V" >"$TMP/old.sh" 2>/dev/null || bad "cannot read the unfixed script at M"
if [ "$FIXOK" = 1 ]; then git show "$PIN_FIX:$V" >"$TMP/new.sh" 2>/dev/null || { bad "cannot read the fixed script at PIN_FIX"; FIXOK=0; }; fi

echo "== AC1 red first: the UNFIXED script (blob at M) is red after its merge"
mkorigin "$TMP/o-main" branch || true
mkorigin "$TMP/o-later" branch synth-outside || true
runv "$TMP/o-main" "$TMP/old.sh" old-main
[ "$RC" -ne 0 ] && ok "unfixed on main: exit $RC (non-zero)" || bad "unfixed on main exits 0 (expected red)"
echo "$OUT" | grep -qF "FAIL empty range (vacuous)" && ok "unfixed on main: reason is the vacuous range" || bad "unfixed on main: no 'empty range (vacuous)' FAIL"
runv "$TMP/o-later" "$TMP/old.sh" old-later
[ "$RC" -ne 0 ] && ok "unfixed on main + later commit: exit $RC (non-zero)" || bad "unfixed on main + later commit exits 0 (expected red)"
echo "$OUT" | grep -qF "FAIL empty range (vacuous)" && ok "unfixed on later commit: reason is the vacuous range" || bad "unfixed on later commit: no 'empty range (vacuous)' FAIL"

echo "== AC1/AC5 the FIXED script is green on main and on main + a later commit (no 096 branch needed)"
if [ "$FIXOK" != 1 ]; then bad "fixed-script cells cannot run: PIN_FIX not usable"; else
  mkorigin "$TMP/f-main" || true
  mkorigin "$TMP/f-out" synth-outside || true
  mkorigin "$TMP/f-in" synth-inside || true
  for t in main out in; do
    runv "$TMP/f-$t" "$TMP/new.sh" "new-$t"
    [ "$RC" -eq 0 ] && ok "fixed on $t: exit 0" || bad "fixed on $t: exit $RC"
    echo "$OUT" | grep -qF "096-verify: ALL CHECKS PASSED" && ok "fixed on $t: ALL CHECKS PASSED" || bad "fixed on $t: no ALL CHECKS PASSED line"
    echo "$OUT" | grep -q '^  FAIL' && bad "fixed on $t: contains FAIL lines" || ok "fixed on $t: no FAIL lines"
    echo "$OUT" | grep -qF "  ok   range changes files" && ok "fixed on $t: non-empty range asserted" || bad "fixed on $t: range assertion missing"
    echo "$OUT" | grep -q '  ok   all runbook hunks inside M9..M11' && ok "fixed on $t: hunk scope asserted" || bad "fixed on $t: hunk-scope assertion missing"
  done
  echo "== AC2 the fixed script carries exactly the re-derived pins and no moving reference"
  for kv in "PIN_MERGE=$PIN_M" "PIN_BASE=$PIN_BASE" "PIN_FINAL=$PIN_M2"; do
    grep -qxF "${kv%%=*}=\"${kv#*=}\"" "$TMP/new.sh" && ok "fixed script pins ${kv%%=*}" || bad "fixed script lacks ${kv%%=*}=\"${kv#*=}\""
  done
  grep -q '354b3cb' "$TMP/new.sh" && bad "fixed script still mentions the old pin 354b3cb" || ok "old pin 354b3cb gone"
  grep -qE 'merge-base origin/main|--branch|origin/main\.\.\.HEAD' "$TMP/new.sh" && bad "fixed script still reads a moving ref (merge-base origin/main / --branch)" || ok "no moving ref in the fixed script"

  echo "== AC3 an unreachable pin (deadbee) is a FAIL, never a skip"
  for k in PIN_MERGE PIN_BASE PIN_FINAL; do
    sed "s/^$k=.*/$k=\"deadbee\"/" "$TMP/new.sh" >"$TMP/dead-$k.sh"
    cmp -s "$TMP/new.sh" "$TMP/dead-$k.sh" && { bad "$k deadbee mutation was a no-op"; continue; }
    runv "$TMP/f-main" "$TMP/dead-$k.sh" "dead-$k"
    [ "$RC" -ne 0 ] && ok "$k=deadbee: exit $RC (non-zero)" || bad "$k=deadbee: exit 0 (skipped?)"
    echo "$OUT" | grep -q "^  FAIL.*$k.*unreachable" && ok "$k=deadbee: named FAIL (unreachable)" || bad "$k=deadbee: no 'FAIL ... $k ... unreachable' line"
    echo "$OUT" | grep -qF "ALL CHECKS PASSED" && bad "$k=deadbee: still says ALL CHECKS PASSED" || ok "$k=deadbee: no pass banner"
  done
  echo "== AC3b a wrong but reachable pin is red (derivation mismatch)"
  for k in PIN_FINAL PIN_BASE; do
    sed "s/^$k=.*/$k=\"$PIN_M1\"/" "$TMP/new.sh" >"$TMP/wrong-$k.sh"
    cmp -s "$TMP/new.sh" "$TMP/wrong-$k.sh" && { bad "$k wrong-pin mutation was a no-op"; continue; }
    runv "$TMP/f-main" "$TMP/wrong-$k.sh" "wrong-$k"
    [ "$RC" -ne 0 ] && ok "$k=M^1: exit $RC (non-zero)" || bad "$k=M^1: exit 0"
  done

  echo "== AC4 096's own mutation checks still redden (and the gap fixtures are not weakened)"
  runv "$TMP/f-main" "$TMP/new.sh" "new-mut"
  echo "$OUT" | grep -qF "  ok   step-2 marker check red when the marker is removed" && ok "step-2 marker mutation reddens" || bad "step-2 mutation line missing"
  echo "$OUT" | grep -qF "  ok   M11 Q-H check red when the status sentence is removed" && ok "M11 Q-H mutation reddens" || bad "M11 Q-H mutation line missing"
  echo "$OUT" | grep -q 'GAP:' && bad "a GAP: line appeared" || ok "no GAP: line"

  echo "== AC7 scope: SPEC..PIN_FIX touches only the three declared files; every other 096 check is byte-identical"
  extra="$(git diff --name-only "$PIN_SPEC" "$PIN_FIX" | grep -vxF -e "$V" -e "$ME" -e "$LOGF" || true)"
  [ -z "$extra" ] && ok "files changed SPEC..FIX are within {096-verify.sh, 102-verify.sh, 102 task file}" || bad "files outside scope: $extra"
  git diff --name-only "$PIN_SPEC" "$PIN_FIX" | grep -qxF "$V" && ok "096-verify.sh is changed" || bad "096-verify.sh not changed"
  sect() { awk -v a="$2" -v b="$3" 'index($0,a)==1{f=1} f&&b!=""&&index($0,b)==1{exit} f' "$1"; }  # lines from the line starting with a up to (excluding) the one starting with b
  for pair in '# Marker checks|URL=' 'echo "== own-change|__EOF__'; do
    a="${pair%%|*}"; b="${pair#*|}"; [ "$b" = "__EOF__" ] && b=""
    sect "$TMP/old.sh" "$a" "$b" >"$TMP/s-old.txt"; sect "$TMP/new.sh" "$a" "$b" >"$TMP/s-new.txt"
    n=$(wc -l <"$TMP/s-old.txt")
    if [ "$n" -lt 10 ]; then bad "section '$a' not found in the unfixed script (n=$n): comparison would be vacuous"
    elif cmp -s "$TMP/s-old.txt" "$TMP/s-new.txt"; then ok "section from '$a' ($n lines) byte-identical to the unfixed script"
    else bad "section from '$a' differs from the unfixed script"; diff "$TMP/s-old.txt" "$TMP/s-new.txt" | head -10 | sed 's/^/    /'; fi
  done
fi

echo
if [ "$fails" -eq 0 ]; then echo "102-verify: ALL CHECKS PASSED"; exit 0; else echo "102-verify: $fails FAILED"; exit 1; fi
