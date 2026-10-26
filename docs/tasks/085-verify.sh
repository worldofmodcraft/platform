#!/usr/bin/env bash
# Task 085 verification (MANAGER.md section 2c). Run from the worktree root, foreground, on a quiet machine.
#   docs/tasks/085-verify.sh    AC1 evidence wording, AC2 red first + re-pin + mutations, AC3 M6 flip, pinned own-change scope
# The "every docs/tasks/*-verify.sh exits 0, one at a time" run (AC3) is done by hand, script by script; it is logged, not scripted here.
# Everything that mutates happens in throw-away clones under $TMPDIR; this tree is never written to.
# Own-change checks use FIXED SHAs (REVIEW-CHECKLIST item 12): RED_SHA is platform origin/main before the task;
# PIN_BASE/PIN_FINAL are the task's own range (FINAL is the content commit; the commit after it only records it and the log).
set -u
export PYTHONDONTWRITEBYTECODE=1 LC_ALL=C.UTF-8
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$HERE" || exit 2
RED_SHA="3ca6fbfd873ba38f6c9ebbb12f757e5ca40365f6"
PIN_BASE="3ca6fbfd873ba38f6c9ebbb12f757e5ca40365f6"
PIN_FINAL="FINAL_PLACEHOLDER"
RB=docs/runbooks/site-v1-manual-steps.md
V068=docs/tasks/068-verify.sh
SCOPE="$V068 $RB docs/tasks/085-runbook-m6-done.md docs/tasks/085-verify.sh"
fails=0
ok()  { echo "  ok   $*"; }
bad() { echo "  FAIL $*"; fails=$((fails + 1)); }
TMP="$(mktemp -d "${TMPDIR:-/tmp}/wom085-XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

run() { local name=$1 dir=$2 script=$3; shift 3; ( cd "$dir" && bash "$script" "$@" ) >"$TMP/$name.out" 2>&1; echo $?; }
expect_red()   { local rc; rc=$(run "$@"); if [ "$rc" -ne 0 ]; then ok "$1 -> exit $rc (red, as required)"; else bad "$1 -> exit 0 but must be red"; fi; }
expect_rc()    { local want=$1 rc; shift; rc=$(run "$@"); if [ "$rc" = "$want" ]; then ok "$1 -> exit $rc"; else bad "$1 -> exit $rc, expected $want"; tail -5 "$TMP/$1.out" | cut -c1-200; fi; }
expect_green() { expect_rc 0 "$@"; }
GITID=(-c user.name=qa -c user.email=qa@example.invalid -c commit.gpgsign=false)
mkclone() { git clone -q --no-hardlinks "$HERE" "$1" && git -C "$1" checkout -q --detach "$2" || { echo "clone failed" >&2; exit 2; }; }
# overlay DIR : copy the working-tree 068-verify.sh into the clone and commit it (so a dirty tree is verified)
overlay() { cp "$HERE/$V068" "$1/$V068"; git -C "$1" add -A; git -C "$1" "${GITID[@]}" commit -q --allow-empty -m "overlay"; }
# flipm6 DIR : the throw-away "later task" commit: flip M6 to done (heading and status) exactly as this task does
flipm6() {
  ( cd "$1" && sed -i -e 's/^## ☐ M6 /## ☑ M6 /' -e 's/^\*\*Status:\*\* not done — `mbmludric` is documented/**Status: done (Ludwig, 2026-10-26).** (was: `mbmludric` documented/' "$RB" \
    && git add -A && git "${GITID[@]}" commit -q -m "throw-away: flip M6" ) || { echo "flip setup failed"; exit 2; }
  git -C "$1" diff --quiet HEAD~1 HEAD -- "$RB" && bad "throw-away flip did not change the runbook"
}

echo "== AC2 red first: the old 068-verify.sh on a throw-away commit that flips M6 (base $(echo "$RED_SHA" | cut -c1-7))"
mkclone "$TMP/red" "$RED_SHA"
expect_green r0 "$TMP/red" "$V068"
flipm6 "$TMP/red"
expect_red r068 "$TMP/red" "$V068"
grep -q 'FAIL  M6 heading stays' "$TMP/r068.out" && ok "old 068 is red for 'M6 heading stays'" || bad "old 068 red for another reason"
echo "== AC2 green after the re-pin: the re-pinned 068 on the same throw-away commit"
overlay "$TMP/red"
expect_green g068 "$TMP/red" "$V068"
expect_green g068m "$TMP/red" "$V068" --mutate

echo "== AC2 later branch: more legitimate later edits to the runbook do not redden the re-pinned 068"
mkclone "$TMP/later" "$RED_SHA"; flipm6 "$TMP/later"; overlay "$TMP/later"
( cd "$TMP/later" && sed -i -e 's/^## ☐ M4 /## ☑ M4 /' -e 's/^\*\*Last reviewed: 2026-10-15 (task 068)\./**Last reviewed: 2026-11-01 (task 999)./' "$RB" \
  && git add -A && git "${GITID[@]}" commit -q -m "throw-away: M4 done, Last reviewed moved" ) || { echo "later setup failed"; exit 2; }
grep -q '^## ☑ M4 ' "$TMP/later/$RB" && ! grep -q 'task 068)\.' "$TMP/later/$RB" && ok "later branch: M4 flipped and Last reviewed moved (throw-away)" || bad "later setup did not apply"
expect_green l068 "$TMP/later" "$V068"
echo "== AC2 mutations"
LATER_HEAD="$(git -C "$TMP/later" rev-parse HEAD)"
# live check stays live: a secret-looking line planted in the CURRENT runbook reddens it
mkclone "$TMP/sec" "$RED_SHA"; overlay "$TMP/sec"
sed -i '1a RWQ0123456789abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ' "$TMP/sec/$RB"
expect_red msec "$TMP/sec" "$V068"
grep -q 'FAIL  no secret-looking value' "$TMP/msec.out" && ok "live secret check reddened by a planted value" || bad "secret plant red for another reason"
# range widened: FINAL moved to the later branch's HEAD -> the own-change checks now see the flipped M6 and the moved marker
sed -i "s/^FINAL=\"[0-9a-f]*\"/FINAL=\"$LATER_HEAD\"/" "$TMP/later/$V068"
git -C "$TMP/later" diff --quiet -- "$V068" && bad "range-widening mutation was a no-op"
expect_red wide "$TMP/later" "$V068"
grep -q 'FAIL  M6 heading stays' "$TMP/wide.out" && ok "widened range is red for 'M6 heading stays' (the later flip is now counted)" || bad "widened range red for another reason"
git -C "$TMP/later" checkout -q -- "$V068"
# unreachable pins fail with exit 2, never skip (BASE, then FINAL)
for var in BASE FINAL; do
  mkclone "$TMP/u" "$RED_SHA"; overlay "$TMP/u"
  sed -i "s/^$var=\"[0-9a-f]*\"/$var=\"0123456789abcdef0123456789abcdef01234567\"/" "$TMP/u/$V068"
  git -C "$TMP/u" diff --quiet -- "$V068" && bad "$var unreachable-pin mutation was a no-op"
  expect_rc 2 "u$var" "$TMP/u" "$V068"
  rm -rf "$TMP/u"
done

echo "== AC1/AC3 this tree: M6 flipped, evidence wording, nothing else in the runbook changed"
grep -q '^## ☑ M6 ' "$RB" && ok "M6 heading is ☑" || bad "M6 heading is not ☑"
grep -q '^## ☐ M6 ' "$RB" && bad "a ☐ M6 heading remains"
m6="$(awk '/^## / && /M6 /{on=1} on && /^---$/ {exit} on' "$RB")"
st="$(awk '/^\*\*Status/ {on=1} on && /^$/ {exit} on' <<<"$m6")"
for pat in 'Status: done' 'Ludwig' '2026-10-26' 'not externally verified' 'HTTP 403' 'rate limit' 'Base permissions = **Read**' 'screenshot'; do
  grep -qF -- "$pat" <<<"$st" && ok "M6 status mentions '$pat'" || bad "M6 status lacks '$pat'"
done
grep -qE 'not done|\[unverified\]' <<<"$st" && bad "M6 status still says not done / [unverified]"
# all other lines of the runbook are byte-identical to RED_SHA: delete the M6 heading line and the status paragraph from both and compare
strip() { awk '/^## .* M6 /{next} /^\*\*Why:\*\* `test` is a reserved/{print; next} /^\*\*Status/ {skip=1} skip && /^$/ {skip=0} skip{next} {print}' ; }
if [ "$(git show "$RED_SHA:$RB" | strip | wc -l)" -gt 0 ] && diff <(git show "$RED_SHA:$RB" | strip) <(strip <"$RB") >"$TMP/rbdiff.out"; then
  ok "runbook outside M6's heading + status is unchanged vs $(echo "$RED_SHA" | cut -c1-7)"
else bad "runbook changed outside M6 heading + status"; head -20 "$TMP/rbdiff.out"; fi
for m in M3 M4 M5 M7 M8 Q-H; do
  a="$(git show "$RED_SHA:$RB" | grep -E "^## .* $m " | head -1)"; b="$(grep -E "^## .* $m " "$RB" | head -1)"
  [ "$a" = "$b" ] && ok "$m heading unchanged" || bad "$m heading changed: '$a' -> '$b'"
done
echo "== AC3 re-pinned 068 on this tree"
expect_green t068 "$HERE" "$V068"

echo "== pinned own-change scope: files changed by the task's range $(echo "$PIN_BASE" | cut -c1-7)..$(echo "$PIN_FINAL" | cut -c1-7)"
if ! git rev-parse --verify -q "$PIN_BASE^{commit}" >/dev/null || ! git rev-parse --verify -q "$PIN_FINAL^{commit}" >/dev/null; then
  bad "a pinned commit is unreachable ($PIN_FINAL): FINAL must be recorded after the content commit"
else
  files="$(git diff --name-only "$PIN_BASE" "$PIN_FINAL")"; off=0
  [ -n "$files" ] || { bad "empty change set"; off=1; }
  for f in $files; do printf '%s\n' $SCOPE | grep -qxF -- "$f" || { bad "out of scope: $f"; off=1; }; done
  [ "$off" = 0 ] && ok "changed files all in file scope: $(echo $files)"
  # at FINAL: M6 done, and the pinned runbook there is what 068 now asserts nothing about (it pins 6d4b61e)
  git show "$PIN_FINAL:$RB" | grep -q '^## ☑ M6 ' && ok "M6 is ☑ at FINAL" || bad "M6 not ☑ at FINAL"
fi

echo "== 085-verify: $([ "$fails" = 0 ] && echo 'ALL CHECKS PASSED' || echo "$fails FAILED")"
[ "$fails" = 0 ]
