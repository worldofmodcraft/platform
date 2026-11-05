#!/usr/bin/env bash
# Task 010b verification (MANAGER.md section 2c). Run from any directory, foreground, one script at a time.
#   docs/tasks/010b-verify.sh            criteria 1-6 (shape, fill commands, credentials, evidence rule, M4 text, scope)
#   docs/tasks/010b-verify.sh --mutate   criterion 6: every check must go red on a broken copy (never on this tree)
# Own-change checks (the runbook, the M4 text, the fixtures) read git blobs at the FIXED SHAs below, so they stay green after later
# tasks (010c) edit the runbook. Live guards (the fill script, the staging tree, the task log, this script's mode) read HEAD.
# Nothing here calls the network, a credential or `gh`.
set -u
export PYTHONDONTWRITEBYTECODE=1 LC_ALL=C.UTF-8
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$HERE" || exit 2
PIN_BASE="24d91411571e240c72d2b543714df04e6a919508"   # platform origin/main at dispatch (PR #108 merge)
PIN_FINAL="f78885565dfeb0e2d2a201762c7fcb68dc81ca25"                                 # the content commit: runbook, M4 text, checker, fixtures
RB=docs/runbooks/first-publish.md
M4F=docs/runbooks/site-v1-manual-steps.md
LOGF=docs/tasks/010b-first-publish-runbook.md
FIXD=docs/tasks/010b-fixtures
CHK=$FIXD/check_runbook.py
MODE=default; [ "${1:-}" = "--mutate" ] && MODE=mutate
fails=0
ok()  { echo "  ok   $*"; }
bad() { echo "  FAIL $*"; fails=$((fails + 1)); }
TMP="$(mktemp -d "${TMPDIR:-/tmp}/wom010b-XXXXXX")"
trap 'rm -r -- "$TMP"' EXIT

echo "== pins"
if [ "$PIN_FINAL" = "__FINAL__" ]; then echo "  FAIL PIN_FINAL not recorded"; exit 1; fi
for k in PIN_BASE PIN_FINAL; do
  v="${!k}"
  git cat-file -e "$v^{commit}" 2>/dev/null && ok "$k resolves" || { bad "$k $v unreachable (fetch the task branch)"; exit 1; }
done
git merge-base --is-ancestor "$PIN_BASE" "$PIN_FINAL" && ok "PIN_BASE is an ancestor of PIN_FINAL" || bad "PIN_BASE is not an ancestor of PIN_FINAL"

# material at the fixed SHAs
git show "$PIN_FINAL:$RB"  >"$TMP/rb.md"      || { echo "cannot read $RB at PIN_FINAL"; exit 2; }
git show "$PIN_FINAL:$M4F" >"$TMP/m4.md"      || exit 2
git show "$PIN_BASE:$M4F"  >"$TMP/m4base.md"  || exit 2
mkdir "$TMP/fx" && git archive "$PIN_FINAL" "$FIXD" | tar -x -C "$TMP/fx" || exit 2
FX="$TMP/fx/$FIXD"
cp "$LOGF" "$TMP/log.md"

# chk SUBCOMMAND ARGS... : run the checker; prints its lines; echoes nothing else; returns its exit code
chk() { python3 -I "$FX/check_runbook.py" "$@" >"$TMP/out" 2>&1; return $?; }
verdict() { # NAME RC : ok on 0, otherwise print why
  local name=$1 rc=$2
  if [ "$rc" = 0 ]; then ok "$name"; else bad "$name (exit $rc)"; head -8 "$TMP/out" | sed 's/^/       /'; fi
}

if [ "$MODE" = default ]; then
  echo "== criterion 1: shape (three labelled parts per step; no unlabelled placeholder in a command block)"
  chk shape "$TMP/rb.md"; verdict "shape" $?
  echo "== criterion 2: the fill_placeholders.py lines are the C24 form and, run as written on a copy, leave no token"
  chk fill "$TMP/rb.md" "$HERE"; rc=$?; verdict "fill commands" $rc; grep '^info:' "$TMP/out" | sed 's/^/       /'
  echo "== criterion 3: no credential handling (and the positive control is caught)"
  chk cred "$TMP/rb.md"; verdict "no credential text in the runbook" $?
  chk cred "$FX/credential-positive-control.txt"; rc=$?
  if [ "$rc" = 1 ] && [ "$(grep -c '^FAIL' "$TMP/out")" -ge 2 ]; then ok "positive control: the fixture is caught ($(grep -c '^FAIL' "$TMP/out") hits)"; else bad "positive control not caught (exit $rc)"; fi
  chk switch "$TMP/rb.md"; verdict "every switch to mbmludric is followed by a switch back to womcraft" $?
  chk stop "$TMP/rb.md"; verdict "inside a switched section every stop line gives the switch-back command" $?
  echo "== criterion 4: evidence rule"
  chk evidence "$TMP/rb.md" "$TMP/log.md"; verdict "UNVERIFIED markers equal the log list, step by step; gh steps are NOT REHEARSED; write-back steps name 008b-3b" $?
  chk observed "$TMP/rb.md" "$FX"; verdict "observed 'You should see' lines are found in the rehearsal transcripts" $?
  echo "== criterion 5: M4 text"
  chk m4 "$TMP/m4.md" "$TMP/m4base.md"; verdict "M4 names wom-test-hello-world, points at first-publish.md, keeps the unchecked key; nothing else changed" $?
  echo "== live guards on HEAD"
  [ -x "docs/tasks/010b-verify.sh" ] && ok "this script is executable" || bad "not executable"
  [ "$(git ls-files -s docs/tasks/010b-verify.sh | cut -c1-6)" = 100755 ] && ok "recorded as mode 100755 in git" || bad "not mode 100755 in git"
  python3 -I tools/test-mod/fill_placeholders.py mod --account x --file /nonexistent >/dev/null 2>&1; rc=$?
  [ "$rc" = 2 ] && ok "fill_placeholders.py still refuses a missing file with exit 2" || bad "fill_placeholders.py exit $rc, expected 2"
  grep -q "OWNER-PLACEHOLDER" docs/test-mod/hello-world/mod.lua && ok "staging tree still carries the placeholder the runbook fills" || bad "staging tree has no placeholder"
  echo "== own change on the fixed range $PIN_BASE..$PIN_FINAL"
  files="$(git diff --name-only "$PIN_BASE" "$PIN_FINAL")"
  [ -n "$files" ] && ok "the range changes files" || bad "empty range (vacuous)"
  extra="$(echo "$files" | grep -v -E "^(docs/runbooks/first-publish\.md|docs/runbooks/site-v1-manual-steps\.md|docs/tasks/010b-first-publish-runbook\.md|docs/tasks/010b-verify\.sh|docs/tasks/010b-fixtures/.+)$" || true)"
  [ -z "$extra" ] && ok "only declared files changed" || bad "files outside scope: $extra"
  echo "$files" | grep -q -E '__pycache__|\.pyc$|\.(key|pub|minisig)$' && bad "bytecode or key-like file in the change" || ok "no bytecode, key or signature file in the change"
  git diff --quiet "$PIN_BASE" "$PIN_FINAL" -- docs/test-mod tools/test-mod CLAUDE.md docs/manager docs/decisions && ok "mod tree, fill script, manager docs and decisions untouched" || bad "protected files changed"
  if git grep -I -n -e "PRIVATE KEY" -e "ghp_" -e "github_pat_" "$PIN_FINAL" -- "$RB" "$M4F" >/dev/null; then bad "secret-shaped string in the change"; else ok "no secret-shaped string in the runbook or the M4 text"; fi
  echo; [ "$fails" -eq 0 ] && { echo "010b-verify: ALL OK"; exit 0; } || { echo "010b-verify: $fails FAIL"; exit 1; }
fi

echo "== mutations: each broken copy must make the checker exit 1 AND print a FAIL reason; a crash (exit 2 or a traceback) is not red"
n=0
# mut NAME SUBCOMMAND EDIT : copy the pinned material to $TMP/mN, run EDIT there (files rb.md m4.md log.md), then run the checker
mut() {
  local name=$1 sub=$2 edit=$3 d rc reason
  n=$((n + 1)); d="$TMP/m$n"; mkdir "$d"
  cp "$TMP/rb.md" "$TMP/m4.md" "$TMP/m4base.md" "$TMP/log.md" "$d/"; cp -r "$FX" "$d/fx"
  mkdir -p "$d/plat"; cp -r tools "$d/plat/tools"; mkdir -p "$d/plat/docs"; cp -r docs/test-mod "$d/plat/docs/test-mod"
  ( cd "$d" && eval "$edit" ) >/dev/null 2>&1
  if diff -rq "$TMP/rb.md" "$d/rb.md" >/dev/null && diff -rq "$TMP/m4.md" "$d/m4.md" >/dev/null && diff -q "$TMP/log.md" "$d/log.md" >/dev/null \
     && diff -rq "$FX" "$d/fx" >/dev/null && diff -rq tools "$d/plat/tools" >/dev/null; then bad "$name: the mutation changed nothing"; return; fi
  case $sub in
    shape|cred|switch|stop) python3 -I "$FX/check_runbook.py" "$sub" "$d/rb.md" >"$TMP/out" 2>&1; rc=$? ;;
    evidence)          python3 -I "$FX/check_runbook.py" evidence "$d/rb.md" "$d/log.md" >"$TMP/out" 2>&1; rc=$? ;;
    observed)          python3 -I "$FX/check_runbook.py" observed "$d/rb.md" "$d/fx" >"$TMP/out" 2>&1; rc=$? ;;
    fill)              python3 -I "$FX/check_runbook.py" fill "$d/rb.md" "$d/plat" >"$TMP/out" 2>&1; rc=$? ;;
    m4)                python3 -I "$FX/check_runbook.py" m4 "$d/m4.md" "$d/m4base.md" >"$TMP/out" 2>&1; rc=$? ;;
  esac
  reason=$(grep -m1 '^FAIL ' "$TMP/out" | cut -c6-110)
  if [ "$rc" = 1 ] && [ -n "${reason// /}" ] && ! grep -q 'Traceback' "$TMP/out"; then ok "$name -> exit 1 ($reason)"
  else bad "$name -> exit $rc, reason '${reason}' (need exit 1, a FAIL reason, no traceback)"; tail -3 "$TMP/out" | cut -c1-160; fi
}
echo " -- criterion 1"
mut "1 one 'This proves' part deleted"        shape "sed -i '0,/^\\*\\*This proves\\*\\*/{//d}' rb.md"
mut "1 one 'Do' label deleted"                shape "sed -i '0,/^\\*\\*Do\\*\\*\$/{//d}' rb.md"
mut "1 one 'You should see' label deleted"    shape "sed -i '0,/^\\*\\*You should see\\*\\*\$/{//d}' rb.md"
mut "1 stray <...> in a command block"        shape "sed -i 's|^git -C ~/wom fetch origin\$|git -C ~/wom fetch <origin>|' rb.md"
mut "1 a fence left open"                     shape "awk '/^\`\`\`/{c++; if(c==2) next} {print}' rb.md > t.md && mv t.md rb.md"
echo " -- criterion 2"
mut "2 entry fill without --commit"           fill  "sed -i 's| --commit \"\$(git -C [^)]*)\"||' rb.md"
mut "2 positional account (not the C24 form)" fill  "sed -i 's|fill_placeholders.py mod --account mbmludric|fill_placeholders.py mod mbmludric|' rb.md"
mut "2 the entry invocation removed"          fill  "sed -i '/fill_placeholders.py entry/d' rb.md"
mut "2 fill script mutant leaves the commit token" fill "sed -i -e 's/out = out.replace(COMMIT_TOKEN, check_commit(commit))/pass/' -e 's/raise Refused(f\"token {tok!r} is still present after filling\")/pass/' plat/tools/test-mod/fill_placeholders.py"
echo " -- criterion 3"
mut "3 'gh auth token' added"                 cred  "echo 'gh auth token' >> rb.md"
mut "3 '--show-token' added to a status line" cred  "sed -i '0,/^gh auth status\$/s//gh auth status --show-token/' rb.md"
mut "3 a switch back to womcraft deleted"     switch "sed -i '0,/^gh auth switch --user womcraft\$/{//d}' rb.md"
mut "3 a stop line without the switch-back command" stop "sed -i '0,/^If what you see is different, \\*\\*stop\\*\\*: run .* first, then/s//If what you see is different, **stop**: then/' rb.md"
mut "3 a switched step with no stop line"     stop "python3 -I -c \"t=open('rb.md').read(); i=t.index('If what you see is different'); j=t.index('\\n\\n',i); open('rb.md','w').write(t[:i]+t[j+2:])\""
mut "3 a second switch to mbmludric without switching back" switch "sed -i '0,/^gh auth switch --user mbmludric\$/s//gh auth switch --user mbmludric\ngh auth switch --user mbmludric/' rb.md"
echo " -- criterion 4"
mut "4 one extra UNVERIFIED marker"           evidence "sed -i '0,/^(Observed 2026-11-04\\. /s//[UNVERIFIED — expected, not observed] (Observed 2026-11-04. /' rb.md"
mut "4 one listed marker removed from the log" evidence "sed -i '/^  - U7 step 2.2\$/d' log.md"
mut "4 a marker moved to another step in the log" evidence "sed -i 's/^  - U7 step 2.2\$/  - U7 step 1.2/' log.md"
mut "4 marker text not the exact words"       evidence "sed -i '0,/\\[UNVERIFIED — expected, not observed\\]/s//[UNVERIFIED — probably]/' rb.md"
mut "4 NOT REHEARSED removed from a gh step"  evidence "sed -i '/^\\[NOT REHEARSED\\] This creates a real repository\\.\$/s/^\\[NOT REHEARSED\\] //' rb.md"
mut "4 008b-3b removed from a write-back step" evidence "sed -i '0,/^\\[NOT REHEARSED\\] Write-back is task 008b-3b\\.\$/s//[NOT REHEARSED] Write-back is later./' rb.md"
mut "4 a fabricated observed line"            observed "sed -i 's/6 files changed, 83 insertions(+)/6 files changed, 99 insertions(+)/' rb.md"
mut "4 observation transcripts emptied"       observed "for f in fx/rehearsal-*-observed.txt; do : > \$f; done"
echo " -- criterion 5"
mut "5 M4 no longer points at first-publish.md" m4 "python3 -I -c \"t=open('m4.md').read(); a=t.index('## ☐ M4'); b=t.index('## ☑ M5'); open('m4.md','w').write(t[:a]+t[a:b].replace('first-publish.md','something.md')+t[b:])\""
mut "5 M4 name back to hello-world only"      m4 "python3 -I -c \"t=open('m4.md').read(); a=t.index('## ☐ M4'); b=t.index('## ☑ M5'); open('m4.md','w').write(t[:a]+t[a:b].replace('wom-test-hello-world','hello-world')+t[b:])\""
mut "5 M4 marked done"                        m4 "sed -i 's/^## ☐ M4/## ☑ M4/' m4.md"
mut "5 the old name returns outside a 404 note" m4 "sed -i 's/^\\*M4 section last reviewed.*\$/Create mbmludric\\/hello-world now./' m4.md"
mut "5 another M section edited"              m4 "sed -i 's/^## ☑ M5 /## ☐ M5 /' m4.md"
echo
[ "$fails" -eq 0 ] && { echo "010b-verify --mutate: ALL OK ($n mutations, each red with a reason)"; exit 0; } || { echo "010b-verify --mutate: $fails FAIL"; exit 1; }
