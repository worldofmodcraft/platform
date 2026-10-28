#!/usr/bin/env bash
# Task 096 verification (MANAGER.md section 2c). Run from any directory, foreground, ONLY on a quiet machine (phase 2).
#   docs/tasks/096-verify.sh    AC1: M9/M10/M11 headings done at the pinned FINAL SHA, step-2 URL, scope = M9..M11 only.
# Own-change checks read git blobs at the fixed PIN_FINAL (REVIEW-CHECKLIST item 12), never the moving HEAD.
# It clones the repository fresh from GitHub (origin URL) into a temp dir and checks there; this tree is never written to.
# PIN_FINAL is set after the content commit exists (phase 2); "PENDING" fails, it never skips.
set -u
export PYTHONDONTWRITEBYTECODE=1 LC_ALL=C.UTF-8
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PIN_FINAL="PENDING"
BRANCH="task/096-runbook-m9-m11-done"
RB=docs/runbooks/site-v1-manual-steps.md
LOGF=docs/tasks/096-runbook-m9-m11-done.md
VER=docs/tasks/096-verify.sh
fails=0
ok()  { echo "  ok   $*"; }
bad() { echo "  FAIL $*"; fails=$((fails + 1)); }
TMP="$(mktemp -d "${TMPDIR:-/tmp}/wom096-XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

URL="$(git -C "$HERE" remote get-url origin 2>/dev/null)" || { echo "FAIL no origin remote"; exit 2; }
echo "== fresh clone of $URL (branch $BRANCH)"
git clone -q --no-hardlinks --branch "$BRANCH" "$URL" "$TMP/c" 2>"$TMP/clone.err" || { echo "FAIL fresh clone"; cat "$TMP/clone.err"; exit 2; }
C="$TMP/c"

echo "== pin"
if [ "$PIN_FINAL" = "PENDING" ]; then bad "PIN_FINAL not set (phase 2 pins it)"; fi
git -C "$C" cat-file -e "$PIN_FINAL^{commit}" 2>/dev/null && ok "PIN_FINAL resolves in the fresh clone" || bad "PIN_FINAL unreachable in the fresh clone"
git -C "$C" merge-base --is-ancestor "$PIN_FINAL" HEAD 2>/dev/null && ok "PIN_FINAL is an ancestor of the branch tip" || bad "PIN_FINAL not an ancestor of HEAD"

echo "== scope (merge-base with origin/main; absent = FAIL)"
BASE="$(git -C "$C" merge-base origin/main "$PIN_FINAL" 2>/dev/null)"
if [ -z "$BASE" ]; then bad "no merge-base with origin/main"; else
  ok "base = $(echo "$BASE" | cut -c1-7)"
  files="$(git -C "$C" diff --name-only "$BASE" "$PIN_FINAL")"
  [ -n "$files" ] && ok "range changes files" || bad "empty range (vacuous)"
  extra="$(echo "$files" | grep -vxF -e "$RB" -e "$LOGF" -e "$VER" || true)"
  [ -z "$extra" ] && ok "only the three declared files changed" || bad "files outside scope: $extra"
  echo "$files" | grep -qxF "$RB" && ok "runbook is changed" || bad "runbook not changed"
  # every hunk of the runbook must lie inside M9, M10 or M11 (old-file line numbers of the base)
  git -C "$C" show "$BASE:$RB" > "$TMP/base.md" 2>/dev/null || bad "cannot read base runbook"
  s=$(grep -n '^## .* M9 ' "$TMP/base.md" | head -1 | cut -d: -f1); e=$(grep -n '^## .* R11 ' "$TMP/base.md" | head -1 | cut -d: -f1)
  if [ -z "$s" ] || [ -z "$e" ]; then bad "cannot locate M9 / R11 headings in base"; else
    out=0
    while IFS= read -r h; do
      st=$(echo "$h" | sed -E 's/^@@ -([0-9]+)(,([0-9]+))? .*/\1/'); n=$(echo "$h" | sed -E 's/^@@ -([0-9]+)(,([0-9]+))? .*/\3/'); n=${n:-1}
      # a pure insertion (n=0) sits after line st
      first=$st; last=$((st + n - 1)); [ "$n" -eq 0 ] && { first=$((st + 1)); last=$st; }
      if [ "$first" -lt "$s" ] || [ "$last" -ge "$e" ]; then out=$((out + 1)); echo "    hunk outside M9..M11: $h"; fi
    done < <(git -C "$C" diff -U0 "$BASE" "$PIN_FINAL" -- "$RB" | grep '^@@')
    [ "$out" -eq 0 ] && ok "all runbook hunks inside M9..M11 (base lines $s..$((e - 1)))" || bad "$out hunk(s) outside M9..M11"
  fi
fi

echo "== own-change: runbook blob at PIN_FINAL"
git -C "$C" show "$PIN_FINAL:$RB" > "$TMP/final.md" 2>/dev/null || bad "cannot read runbook at PIN_FINAL"
for m in M9 M10 M11; do
  grep -q "^## ☑ $m " "$TMP/final.md" && ok "$m heading is ☑" || bad "$m heading is not ☑"
  grep -q "^## ☐ $m " "$TMP/final.md" && bad "$m still has a ☐ heading"
  # the Status paragraph must sit between this heading and the next '## '
  sec="$(awk -v m="$m" '$0 ~ "^## .* "m" "{f=1;next} f&&/^## /{exit} f' "$TMP/final.md")"
  echo "$sec" | grep -qF 'Status: done (Ludwig, 2026-10-28).' && ok "$m has 'Status: done (Ludwig, 2026-10-28).'" || bad "$m lacks the done status"
done
grep -q '^## ⏸ R11 ' "$TMP/final.md" && ok "R11 heading unchanged (⏸)" || bad "R11 heading changed"
m9="$(awk '/^## .* M9 /{f=1;next} f&&/^## /{exit} f' "$TMP/final.md")"
echo "$m9" | grep -qF 'https://github.com/worldofmodcraft/registry/settings/branches' && ok "M9 step 2 gives the direct URL" || bad "M9 step 2 URL missing"
echo "$m9" | grep -qE '^2\. Open `https://github.com/worldofmodcraft/registry/settings/branches`' && ok "URL is step 2's first thing" || bad "URL not first in step 2"
echo "$m9" | grep -qF 'under "Code, planning, and automation": **Branches**' && bad "old sidebar path still asserted" || ok "old sidebar path no longer asserted"
echo "$m9" | grep -qF '`[unverified]`' && ok "sidebar naming marked [unverified]" || bad "no [unverified] mark in M9"
m11="$(awk '/^## .* M11 /{f=1;next} f&&/^## /{exit} f' "$TMP/final.md")"
echo "$m11" | grep -q 'delete the pipeline App' && ok "M11 records the key-hygiene item" || bad "M11 hygiene item missing"
echo "$m11" | grep -q 'Q-H' && echo "$m11" | grep -qi 'unconfirmed' && ok "M11 records Q-H backup unconfirmed" || bad "M11 Q-H wording missing"
echo "$m11" | grep -qF 'worldofmodcraft-pipeline.2026-10-27.private-key.pem' && ok "M11 cites Ludwig's file name" || bad "M11 file name missing"
echo "== no secret-looking value in the final runbook"
grep -qE 'RWQ[A-Za-z0-9+/]{40,}|BEGIN [A-Z ]*PRIVATE KEY|gh[pousr]_[A-Za-z0-9]{30,}' "$TMP/final.md" && bad "secret-looking value" || ok "none"

echo
if [ "$fails" -eq 0 ]; then echo "096-verify: ALL CHECKS PASSED"; exit 0; else echo "096-verify: $fails FAILED"; exit 1; fi
