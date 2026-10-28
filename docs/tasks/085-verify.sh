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
PIN_FINAL="eb59f8906c359064e29cc7c09ba7f0be2c8bdbd8"
RB=docs/runbooks/site-v1-manual-steps.md
V068=docs/tasks/068-verify.sh
SCOPE="$V068 $RB docs/tasks/085-runbook-m6-done.md docs/tasks/085-verify.sh"
fails=0
ok()  { echo "  ok   $*"; }
bad() { echo "  FAIL $*"; fails=$((fails + 1)); }
TMP="$(mktemp -d "${TMPDIR:-/tmp}/wom085-XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

run() { local name=$1 dir=$2 script=$3; shift 3; ( cd "$dir" && WOM085_NESTED=1 bash "$script" "$@" ) >"$TMP/$name.out" 2>&1; echo $?; }
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

echo "== AC1/AC3 own change, read at the pinned FINAL ${PIN_FINAL:0:7} (never HEAD: item 12): M6 flipped, evidence wording, nothing else changed"
# PINRB is the runbook blob at FINAL; every check below reads it, so a later task ticking M4 or moving "Last reviewed" cannot redden 085.
PINRB="$TMP/pinned-runbook.md"
if git show "$PIN_FINAL:$RB" >"$PINRB" 2>/dev/null; then
grep -q '^## ☑ M6 ' "$PINRB" && ok "M6 heading is ☑ at FINAL" || bad "M6 heading is not ☑"
grep -q '^## ☐ M6 ' "$PINRB" && bad "a ☐ M6 heading remains"
m6="$(awk '/^## / && /M6 /{on=1} on && /^---$/ {exit} on' "$PINRB")"
st="$(awk '/^\*\*Status/ {on=1} on && /^$/ {exit} on' <<<"$m6")"
for pat in 'Status: done' 'Ludwig' '2026-10-26' 'not externally verified' 'HTTP 403' 'rate limit' 'Base permissions = **Read**' 'screenshot'; do
  grep -qF -- "$pat" <<<"$st" && ok "M6 status mentions '$pat'" || bad "M6 status lacks '$pat'"
done
grep -qE 'not done|\[unverified\]' <<<"$st" && bad "M6 status still says not done / [unverified]"
# all other lines of the runbook are byte-identical to RED_SHA: delete the M6 heading line and the status paragraph from both and compare
strip() { awk '/^## .* M6 /{next} /^\*\*Why:\*\* `test` is a reserved/{print; next} /^\*\*Status/ {skip=1} skip && /^$/ {skip=0} skip{next} {print}' ; }
if [ "$(git show "$RED_SHA:$RB" | strip | wc -l)" -gt 0 ] && diff <(git show "$RED_SHA:$RB" | strip) <(strip <"$PINRB") >"$TMP/rbdiff.out"; then
  ok "runbook outside M6's heading + status is unchanged vs $(echo "$RED_SHA" | cut -c1-7)"
else bad "runbook changed outside M6 heading + status"; head -20 "$TMP/rbdiff.out"; fi
for m in M3 M4 M5 M7 M8 Q-H; do
  a="$(git show "$RED_SHA:$RB" | grep -E "^## .* $m " | head -1)"; b="$(grep -E "^## .* $m " "$PINRB" | head -1)"
  [ "$a" = "$b" ] && ok "$m heading unchanged" || bad "$m heading changed: '$a' -> '$b'"
done
else bad "cannot read $RB at pinned FINAL $PIN_FINAL (unreachable pin fails, never skips)"; fi

echo "== AC3 LIVE guard: the re-pinned 068 on this tree (HEAD)"
expect_green t068 "$HERE" "$V068"

echo "== pinned own-change scope: files changed by the task's range $(echo "$PIN_BASE" | cut -c1-7)..$(echo "$PIN_FINAL" | cut -c1-7)"
if ! git rev-parse --verify -q "$PIN_BASE^{commit}" >/dev/null || ! git rev-parse --verify -q "$PIN_FINAL^{commit}" >/dev/null; then
  bad "a pinned commit is unreachable ($PIN_FINAL): FINAL must be recorded after the content commit"
else
  files="$(git diff --name-only "$PIN_BASE" "$PIN_FINAL")"; off=0
  [ -n "$files" ] || { bad "empty change set"; off=1; }
  for f in $files; do printf '%s\n' $SCOPE | grep -qxF -- "$f" || { bad "out of scope: $f"; off=1; }; done
  [ "$off" = 0 ] && ok "changed files all in file scope: $(echo $files)"
fi

if [ -z "${WOM085_NESTED:-}" ]; then   # the nested runs below must not recurse
echo "== item 12: a later change to the live runbook does not redden 085; a change to the PINNED content does"
mkclone "$TMP/n" "$(git rev-parse HEAD)"; cp "$HERE/docs/tasks/085-verify.sh" "$TMP/n/docs/tasks/085-verify.sh"
( cd "$TMP/n" && sed -i -e 's/^## ☐ M4 /## ☑ M4 /' -e 's/^\*\*Last reviewed: 2026-10-15 (task 068)\./**Last reviewed: 2026-11-01 (task 999)./' "$RB" \
  && git add -A && git "${GITID[@]}" commit -q -m "throw-away later task: M4 done, Last reviewed moved" ) || { echo "nested setup failed"; exit 2; }
grep -q '^## ☑ M4 ' "$TMP/n/$RB" && ok "later commit on top of HEAD ticked M4 and moved Last reviewed (throw-away)" || bad "nested later setup did not apply"
grep -qF 'Last reviewed: 2026-10-15 (task 068)' "$TMP/n/$RB" && bad "nested: Last reviewed substitution applied (old string still present)" || { grep -qF 'Last reviewed: 2026-11-01 (task 999)' "$TMP/n/$RB" && ok "nested: Last reviewed substitution applied" || bad "nested: Last reviewed substitution applied (new string absent)"; }
expect_green nested "$TMP/n" docs/tasks/085-verify.sh
# mutate the pinned content: a commit that reverts M6 and ticks nothing else back; PIN_FINAL of the copy points at it
mkclone "$TMP/m" "$(git rev-parse HEAD)"; cp "$HERE/docs/tasks/085-verify.sh" "$TMP/m/docs/tasks/085-verify.sh"
( cd "$TMP/m" && sed -i -e 's/^## ☑ M6 /## ☐ M6 /' -e 's/^## ☑ M5 /## ☐ M5 /' "$RB" && git add -A && git "${GITID[@]}" commit -q -m "throw-away: M6 and M5 reverted" ) || { echo "mutation setup failed"; exit 2; }
sed -i "s/^PIN_FINAL=\"[0-9a-f]*\"/PIN_FINAL=\"$(git -C "$TMP/m" rev-parse HEAD)\"/" "$TMP/m/docs/tasks/085-verify.sh"
git -C "$TMP/m" diff --quiet -- docs/tasks/085-verify.sh && bad "pinned-content mutation was a no-op"
expect_red pinmut "$TMP/m" docs/tasks/085-verify.sh
grep -q 'FAIL M6 heading is not' "$TMP/pinmut.out" && grep -q 'FAIL M5 heading changed' "$TMP/pinmut.out" && ok "red for the M6 and M5 changes in the pinned content" || bad "pinned-content mutation red for another reason"
# unreachable FINAL pin fails, never skips
sed -i "s/^PIN_FINAL=\"[0-9a-f]*\"/PIN_FINAL=\"0123456789abcdef0123456789abcdef01234567\"/" "$TMP/m/docs/tasks/085-verify.sh"
expect_red pinunr "$TMP/m" docs/tasks/085-verify.sh
grep -q 'cannot read' "$TMP/pinunr.out" && ok "unreachable FINAL named as such" || bad "unreachable FINAL red for another reason"
fi

echo "== 085-verify: $([ "$fails" = 0 ] && echo 'ALL CHECKS PASSED' || echo "$fails FAILED")"
[ "$fails" = 0 ]
