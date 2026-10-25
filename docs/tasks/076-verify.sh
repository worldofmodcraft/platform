#!/usr/bin/env bash
# Task 076 verification. Deterministic, no network.
# Own-change checks use the fixed range BASE..TIP below (never HEAD / origin/main).
# Live guards (existing verify scripts that read docs/manager/) run on the current tree.
set -u
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" || exit 2
BASE=0aac56647bf4d7f5e3ca7f1a2ff95c33a53d71f6
TIP=a2419badc0519c1ab18e1840f1117b9fd1e4e712
M=docs/manager/MANAGER.md; R=docs/manager/REVIEW-CHECKLIST.md
fails=0
chk() { if [ "$2" -eq 0 ]; then echo "  PASS $1"; else echo "  FAIL $1"; fails=$((fails+1)); fi; }
sec7() { git show "$TIP:$M" | sed -n '/^\*\*Takedowns are never merged/,/^This restores the human gate/p'; }
S=$(sec7)
echo "AC1"
[ -n "$S" ]; chk "section 7 takedown paragraph located" $?
! printf '%s' "$S" | grep -q "legal grounds only"; chk "no 'legal grounds only'" $?
! git show "$TIP:$M" | grep -q "single in-place change"; chk "no 'single in-place change'" $?
printf '%s' "$S" | grep -q "ADR-0122"; chk "names ADR-0122" $?
printf '%s' "$S" | grep -q "ADR-0046"; chk "names ADR-0046" $?
printf '%s' "$S" | grep -q "R11"; chk "names ownership.md R11" $?
printf '%s' "$S" | grep -q "explicit written approval"; chk "written approval kept" $?
printf '%s' "$S" | grep -q "absolute stop condition under §8, not a judgement"; chk "absolute-stop sentence kept" $?
echo "AC2"
git show "$TIP:$R" | grep -E '^12\. ' | grep -q "fixed commit range"; chk "item 12 has 'fixed commit range'" $?
git show "$TIP:$R" | grep -E '^12\. ' | grep -q "HEAD"; chk "item 12 has HEAD" $?
[ "$(git diff "$BASE" "$TIP" -- "$R" | grep -c '^-[^-]')" -eq 0 ]; chk "checklist diff has no removed lines" $?
[ "$(git diff "$BASE" "$TIP" -- "$R" | grep -c '^+[^+]')" -eq 1 ]; chk "checklist diff adds exactly one line" $?
echo "AC3"
SC="docs/manager/MANAGER.md
docs/manager/REVIEW-CHECKLIST.md
docs/tasks/076-doctrine-removal-and-pinning.md
docs/tasks/076-verify.sh"
bad=$(git diff --name-only "$BASE" HEAD | grep -vxF "$SC"); [ -z "$bad" ]; chk "BASE..HEAD touches only File scope ${bad:+($bad)}" $?
echo "AC4 (live guards on HEAD)"
for f in $(grep -l "docs/manager" docs/tasks/*-verify.sh | grep -v 076-verify.sh); do
  bash "$f" >/dev/null 2>&1; rc=$?; chk "$f exit $rc" $rc
done
[ "$fails" -eq 0 ] && echo "076 verify: PASS" || echo "076 verify: $fails FAIL"
exit $([ "$fails" -eq 0 ] && echo 0 || echo 1)
