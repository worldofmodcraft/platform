#!/usr/bin/env bash
# Task 078 verification (MANAGER.md section 2c). Run from the worktree root, foreground, on a quiet machine.
#   docs/tasks/078-verify.sh    AC1 red-first, AC2 later branch, AC3 mutations, AC5 pinned own-change scope check
# AC4 (every closed verify script green on HEAD, one at a time) is run by hand, script by script; it is logged, not scripted here.
# Everything that mutates happens in throw-away clones under $TMPDIR; this tree is never written to.
# Own-change checks use FIXED SHAs (REVIEW-CHECKLIST item 12 as proposed in task 076): RED_SHA is platform origin/main before the
# task; PIN_BASE/PIN_FINAL are the task's own range (FINAL is the content commit; the commit after it only records it and the log).
set -u
export PYTHONDONTWRITEBYTECODE=1 LC_ALL=C.UTF-8
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$HERE" || exit 2
RED_SHA="6f90d524570d1b518a2d7c294420786bf12666ec"
PIN_BASE="6f90d524570d1b518a2d7c294420786bf12666ec"
PIN_FINAL="__FINAL__"
SCRIPTS="docs/tasks/048-verify.sh docs/tasks/056-verify.sh docs/tasks/063-verify.sh docs/tasks/078-verify.sh docs/tasks/078-closed-verify-repin-048-051-063.md"
SCOPE="$SCRIPTS"
fails=0
ok()  { echo "  ok   $*"; }
bad() { echo "  FAIL $*"; fails=$((fails + 1)); }
TMP="$(mktemp -d "${TMPDIR:-/tmp}/wom078-XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

# run NAME DIR SCRIPT [ARGS..] : run a script in a clone, output to $TMP/NAME.out, echo its exit code
run() { local name=$1 dir=$2 script=$3; shift 3; ( cd "$dir" && bash "$script" "$@" ) >"$TMP/$name.out" 2>&1; echo $?; }
expect_red()   { local rc; rc=$(run "$@"); if [ "$rc" -ne 0 ]; then ok "$1 -> exit $rc (red, as required)"; else bad "$1 -> exit 0 but must be red"; fi; }
expect_rc()    { local want=$1 rc; shift; rc=$(run "$@"); if [ "$rc" = "$want" ]; then ok "$1 -> exit $rc"; else bad "$1 -> exit $rc, expected $want"; tail -5 "$TMP/$1.out" | cut -c1-200; fi; }
expect_green() { expect_rc 0 "$@"; }

# mkclone DIR SHA : clone of this repo detached at SHA, origin/main pinned to RED_SHA (what the old scripts compared against)
mkclone() {
  git clone -q --no-hardlinks "$HERE" "$1" && git -C "$1" checkout -q --detach "$2" || { echo "clone failed" >&2; exit 2; }
  git -C "$1" update-ref refs/remotes/origin/main "$RED_SHA"
}
GITID=(-c user.name=qa -c user.email=qa@example.invalid -c commit.gpgsign=false)
# overlay DIR : copy the working-tree versions of the files under test into the clone and commit them (so a dirty tree is verified)
overlay() { local f; for f in $SCRIPTS; do [ -f "$HERE/$f" ] && cp "$HERE/$f" "$1/$f"; done; git -C "$1" add -A; git -C "$1" "${GITID[@]}" commit -q --allow-empty -m "overlay"; }

echo "== AC1 red first: the three scripts as committed on platform origin/main $(echo "$RED_SHA" | cut -c1-7)"
mkclone "$TMP/red" "$RED_SHA"
expect_red r048 "$TMP/red" docs/tasks/048-verify.sh
expect_red r051 "$TMP/red" docs/tasks/051-verify.sh
expect_red r063 "$TMP/red" docs/tasks/063-verify.sh
grep -q 'secret-shaped string committed' "$TMP/r051.out" && ok "051 is red for the secret scan (AC4) as the spec says" || bad "051 red for another reason"
echo "== AC1 green after the fix: the fixed scripts on this tree (HEAD + working files)"
mkclone "$TMP/green" "$(git rev-parse HEAD)"; overlay "$TMP/green"
expect_green g048 "$TMP/green" docs/tasks/048-verify.sh
expect_green g051 "$TMP/green" docs/tasks/051-verify.sh
expect_green g056 "$TMP/green" docs/tasks/056-verify.sh --no-fetch
expect_green g063 "$TMP/green" docs/tasks/063-verify.sh
if (cd "$TMP/green" && git grep -n 'untrusted comment: minisign encrypted secret key' -- docs/tasks/056-verify.sh) >/dev/null; then bad "056-verify.sh still contains the literal header"; else ok "056-verify.sh no longer contains the literal header"; fi

echo "== AC2 later branch: legitimate later edits to the guarded files"
mkclone "$TMP/later" "$(git rev-parse HEAD)"; overlay "$TMP/later"
( cd "$TMP/later" \
  && sed -i '/^## 7\. /a\
\
Later-task note appended under section 7 (throw-away).' docs/manager/MANAGER.md \
  && printf '\nLater-task note outside rule 0 (throw-away).\n' >> CLAUDE.md \
  && git add -A && git "${GITID[@]}" commit -q -m "later task: edit MANAGER.md section 7 and CLAUDE.md outside rule 0" ) || { echo "later-branch setup failed"; exit 2; }
git -C "$TMP/later" diff --quiet HEAD~1 HEAD -- docs/manager/MANAGER.md && bad "later branch did not change MANAGER.md"
expect_green l048 "$TMP/later" docs/tasks/048-verify.sh
expect_green l063 "$TMP/later" docs/tasks/063-verify.sh
# a later commit that deletes a line of rule 0 is NOT 048's concern (its range is the task's own PR); show that, so the log can state it
( cd "$TMP/later" && sed -i '0,/Stop at 90 %/{/Stop at 90 %/d}' CLAUDE.md && git add -A && git "${GITID[@]}" commit -q -m "later: delete a rule-0 line" ) || echo "rule-0 deletion setup failed"
if git -C "$TMP/later" show HEAD:CLAUDE.md | grep -q 'Stop at 90 %'; then bad "rule-0 deletion did not apply"; else ok "rule-0 line deleted in a new commit (throw-away)"; fi
expect_green l048b "$TMP/later" docs/tasks/048-verify.sh
echo "  note: no script in this repo guards rule 0's text live; booked as Question 1 in the task log"

echo "== AC3 mutations"
LATER_HEAD="$(git -C "$TMP/later" rev-parse HEAD)"
# widen each re-pinned FINAL back to HEAD (of the later branch, whose edits must now count against the task)
sed -i "s/^PIN_FINAL=\"[0-9a-f]*\"/PIN_FINAL=\"$LATER_HEAD\"/" "$TMP/later/docs/tasks/048-verify.sh"
sed -i "s/^FINAL=\"[0-9a-f]*\"/FINAL=\"$LATER_HEAD\"/" "$TMP/later/docs/tasks/063-verify.sh"
git -C "$TMP/later" diff --quiet -- docs/tasks/048-verify.sh && bad "048 pin widening was a no-op"
git -C "$TMP/later" diff --quiet -- docs/tasks/063-verify.sh && bad "063 pin widening was a no-op"
expect_red w048 "$TMP/later" docs/tasks/048-verify.sh
expect_red w063 "$TMP/later" docs/tasks/063-verify.sh
git -C "$TMP/later" checkout -q -- docs/tasks/048-verify.sh docs/tasks/063-verify.sh
# unreachable pins fail with exit 2, never skip (BASE, then FINAL)
for s in 048 063; do
  for var in BASE FINAL; do
    mkclone "$TMP/u" "$(git rev-parse HEAD)"; overlay "$TMP/u"
    if [ "$s" = 048 ]; then v=PIN_$var; else v=$var; fi
    sed -i "s/^$v=\"[0-9a-f]*\"/$v=\"0123456789abcdef0123456789abcdef01234567\"/" "$TMP/u/docs/tasks/$s-verify.sh"
    git -C "$TMP/u" diff --quiet -- "docs/tasks/$s-verify.sh" && bad "$s $v unreachable-pin mutation was a no-op"
    expect_rc 2 "u$s$var" "$TMP/u" "docs/tasks/$s-verify.sh"
    rm -rf "$TMP/u"
  done
done
# 056: the planted header removed -> its own control for the secret-header check must redden
mkclone "$TMP/m056" "$(git rev-parse HEAD)"; overlay "$TMP/m056"
sed -i "s/echo 'untrusted comment: minisign encrypted '\"sec\"\"ret key\"/echo 'nothing planted'/" "$TMP/m056/docs/tasks/056-verify.sh"
git -C "$TMP/m056" diff --quiet -- docs/tasks/056-verify.sh && bad "056 plant removal was a no-op"
expect_red m056 "$TMP/m056" docs/tasks/056-verify.sh --no-fetch
grep -q "secret header" "$TMP/m056.out" && ok "056 names the 'secret header' control as the red one" || bad "056 red for another reason"
# 051: a real secret-shaped string (built at runtime, never written in this script) planted in a tracked file -> red
mkclone "$TMP/m051" "$(git rev-parse HEAD)"; overlay "$TMP/m051"
printf 'x %s%s y\n' 'gh''p_' 'aB3dE5gH7jK9mN1pQ3sT5vX7zA9cD1fG3hJ5' >> "$TMP/m051/docs/tasks/076-doctrine-removal-and-pinning.md"
expect_red m051 "$TMP/m051" docs/tasks/051-verify.sh
grep -q 'secret-shaped string committed' "$TMP/m051.out" && ok "051 reddens on the planted secret-shaped string" || bad "051 red for another reason"
# 051: the OLD 056 literal reintroduced (built at runtime) -> red: the fix is what turned it green
mkclone "$TMP/m051b" "$(git rev-parse HEAD)"; overlay "$TMP/m051b"
printf 'untrusted comment: minisign encrypted %s\n' 'secret key' >> "$TMP/m051b/docs/tasks/056-verify.sh"
expect_red m051b "$TMP/m051b" docs/tasks/051-verify.sh

echo "== AC5 pinned own-change scope: files changed by the task's range $(echo "$PIN_BASE" | cut -c1-7)..$(echo "$PIN_FINAL" | cut -c1-7)"
if ! git rev-parse --verify -q "$PIN_BASE^{commit}" >/dev/null || ! git rev-parse --verify -q "$PIN_FINAL^{commit}" >/dev/null; then
  bad "a pinned commit is unreachable ($PIN_FINAL): FINAL must be recorded after the content commit"
else
  files="$(git diff --name-only "$PIN_BASE" "$PIN_FINAL")"; off=0
  [ -n "$files" ] || { bad "empty change set"; off=1; }
  for f in $files; do printf '%s\n' $SCOPE | grep -qxF -- "$f" || { bad "out of scope: $f"; off=1; }; done
  [ "$off" = 0 ] && ok "changed files all in file scope: $(echo $files)"
fi

echo "== 078-verify: $([ "$fails" = 0 ] && echo 'ALL CHECKS PASSED' || echo "$fails FAILED")"
[ "$fails" = 0 ]
