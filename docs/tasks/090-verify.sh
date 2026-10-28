#!/usr/bin/env bash
# Task 090 verification (MANAGER.md section 2c). Run from a FRESH CLONE of the task branch, foreground, on a QUIET machine, clean tree.
#   docs/tasks/090-verify.sh             AC1-AC5 and AC7: red fixtures, controls, pins (everything mutating happens in throw-away clones)
#   docs/tasks/090-verify.sh --mutate    additionally breaks each check's subject (old scripts, a widened c4, a stub 079, a wrong scope pin)
#                                        and requires the matching check function to report FAIL (rule 2: the artefact must be able to fail)
#   docs/tasks/090-verify.sh --sweep     additionally AC6: every closed docs/tasks/*-verify.sh, one at a time, on HEAD and on the merge
#                                        (ps logged before each; refuses to count a run on a machine where another *-verify.sh is running)
# Flags combine. Own-change checks use FIXED SHAs (REVIEW-CHECKLIST item 12): BASE_SHA = platform origin/main before this task;
# PIN_FINAL = this task's content commit (the commit after it only records it and the log). No env overrides, no credentials.
# Every check function takes REV (the commit whose scripts are under test) so --mutate can run the SAME check on the OLD scripts
# (REV=BASE_SHA) and require red. Output is judged by its "  ok" / "  FAIL" lines.
set -u
export PYTHONDONTWRITEBYTECODE=1 LC_ALL=C.UTF-8
unset WOM085_NESTED
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$HERE" || exit 2

BASE_SHA="4321d079e4273d20bd448edadce72e36d56b5f24"
PIN_FINAL="46a20c84f8308cd2f4ac5243b70578e1859387ce"
M048="c323460b9898e44a7c487c310f0b3707f4bce2e8"        # merge of task 048 (PR #50)
P048_BASE="8a5f32dfcebfe6eda328066b43eb60204ef3a5ac"   # merge-base(M^1, M^2)
P048_FINAL="047bc41cac555cc125f2650d1b5cc3159f2f17a9"  # M^2
T=docs/tasks
V048=$T/048-verify.sh; V072=$T/072-verify.sh; V079=$T/079-verify.sh; V080=$T/080-verify.sh; V085=$T/085-verify.sh
RB=docs/runbooks/site-v1-manual-steps.md
SCOPE="$V048 $V072 $V079 $V080 $V085 $T/090-closed-verify-sweep-platform.md $T/090-verify.sh"

DO_MUTATE=0; DO_SWEEP=0
for a in "$@"; do case "$a" in --mutate) DO_MUTATE=1;; --sweep) DO_SWEEP=1;; *) echo "usage: $0 [--mutate] [--sweep]"; exit 2;; esac; done

ok()  { echo "  ok   $*"; }
bad() { echo "  FAIL $*"; }
TMP="$(mktemp -d "${TMPDIR:-/tmp}/wom090-XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT
GITID=(-c user.name=qa -c user.email=qa@example.invalid -c commit.gpgsign=false)
HEADSHA="$(git rev-parse HEAD)"
git diff --quiet HEAD -- . || { echo "FAIL: working tree is dirty; run from a clean (fresh) clone"; exit 2; }
for c in "$BASE_SHA" "$M048" "$P048_BASE" "$P048_FINAL"; do
  git rev-parse --verify -q "$c^{commit}" >/dev/null || { echo "FAIL: pinned commit $c unreachable (run: git fetch)"; exit 2; }
done

# ---------------------------------------------------------------------------------------------------------- helpers
sc() { git show "$1:$2"; }   # sc REV PATH : file content at REV
# mkclone DIR REV : throw-away clone at REV, shaped like a fresh clone (local branch only the checked-out one; origin/main present)
mkclone() {
  git clone -q --no-hardlinks --no-checkout "$HERE" "$1" \
    && git -C "$1" fetch -q "$HERE" HEAD \
    && { git -C "$1" fetch -q "$HERE" '+refs/remotes/origin/*:refs/remotes/origin/*' 2>/dev/null || true; } \
    && { git -C "$1" rev-parse -q --verify refs/remotes/origin/main >/dev/null || git -C "$1" update-ref refs/remotes/origin/main "$BASE_SHA"; } \
    && git -C "$1" checkout -q --detach "$2" || { echo "clone failed ($1 at $2)" >&2; exit 2; }
}
commit_all() { git -C "$1" add -A && git -C "$1" "${GITID[@]}" commit -q --allow-empty -m "$2"; }
# overlay DIR REV PATH... : write the scripts as they are at REV into the clone and commit them
overlay() { local d=$1 r=$2 p; shift 2; for p in "$@"; do sc "$r" "$p" >"$d/$p"; chmod +x "$d/$p"; done; commit_all "$d" "overlay $r"; }
# revoke DIR : the throw-away "later task": Ludwig revokes the suspension (the marker text disappears from both files)
revoke() {
  ( cd "$1" && sed -i 's/SUSPENDED by Ludwig 2026-10-14/REVOKED by Ludwig 2026-11-01/' CLAUDE.md docs/manager/MANAGER.md ) || return 1
  grep -q 'SUSPENDED by Ludwig 2026-10-14' "$1/CLAUDE.md" "$1/docs/manager/MANAGER.md" && { bad "revoke fixture did not apply"; return 1; }
  grep -q 'REVOKED by Ludwig 2026-11-01' "$1/CLAUDE.md" && grep -q 'REVOKED by Ludwig 2026-11-01' "$1/docs/manager/MANAGER.md" || { bad "revoke fixture did not apply to both files"; return 1; }
  commit_all "$1" "throw-away: revoke suspension"
}
# runbook_edit DIR : the throw-away "later task": M4 done, Last reviewed moved
runbook_edit() {
  ( cd "$1" && sed -i -e 's/^## ☐ M4 /## ☑ M4 /' -e 's/^\*\*Last reviewed: 2026-10-15 (task 068)\./**Last reviewed: 2026-11-01 (task 999)./' "$RB" ) || return 1
  grep -q '^## ☑ M4 ' "$1/$RB" && grep -qF 'Last reviewed: 2026-11-01 (task 999)' "$1/$RB" || { bad "runbook fixture did not apply"; return 1; }
  commit_all "$1" "throw-away: M4 done, Last reviewed moved"
}
# run DIR NAME CMD... : run CMD in DIR, output to $TMP/NAME.out, print the exit code
run() { local d=$1 n=$2; shift 2; ( cd "$d" && "$@" ) >"$TMP/$n.out" 2>&1; echo $?; }
expect_rc() { # want DIR NAME CMD...
  local want=$1 d=$2 n=$3 rc; shift 3; rc=$(run "$d" "$n" "$@")
  if [ "$rc" = "$want" ]; then ok "$n -> exit $rc"; else bad "$n -> exit $rc, expected $want"; tail -6 "$TMP/$n.out" | cut -c1-200; fi
}
expect_red() { # DIR NAME CMD...   (any non-zero exit)
  local d=$1 n=$2 rc; shift 2; rc=$(run "$d" "$n" "$@")
  if [ "$rc" != 0 ]; then ok "$n -> exit $rc (red, as required)"; else bad "$n -> exit 0 but must be red"; fi
}
has() { grep -qF -- "$2" "$TMP/$1.out" && ok "$1 output names '$2'" || { bad "$1 output lacks '$2'"; tail -4 "$TMP/$1.out" | cut -c1-200; }; }

# merge_clone DIR REV : DIR = HEAD merged with a later synthetic branch (cut from BASE_SHA) that revokes the suspension, ticks M4 and
# moves Last reviewed; then the scripts as at REV are laid over it (REV=HEAD leaves them as they are)
merge_clone() {
  mkclone "$1" "$BASE_SHA"
  git -C "$1" checkout -q -b later \
    && revoke "$1" >/dev/null && runbook_edit "$1" >/dev/null \
    && git -C "$1" checkout -q --detach "$HEADSHA" \
    && git -C "$1" "${GITID[@]}" merge -q --no-edit later >/dev/null || { echo "merge setup failed" >&2; exit 2; }
  grep -q 'REVOKED by Ludwig 2026-11-01' "$1/CLAUDE.md" && grep -q '^## ☑ M4 ' "$1/$RB" && [ "$(git -C "$1" rev-list --parents -n1 HEAD | wc -w)" = 3 ] \
    || { echo "merge fixture check failed" >&2; exit 2; }
  [ "$2" = "$HEADSHA" ] || overlay "$1" "$2" "$V048" "$V072" "$V080" "$V085"
}

# ------------------------------------------------------------------------------------------------------------ AC1
ac1_pins() {
  echo "== AC1 pins re-derived from merge ${M048:0:7}"
  local p1 p2 mb
  p1=$(git rev-parse "$M048^1"); p2=$(git rev-parse "$M048^2"); mb=$(git merge-base "$p1" "$p2")
  echo "  derived: M^1=$p1 M^2=$p2 merge-base=$mb"
  [ "$mb" = "$P048_BASE" ] && ok "PIN_BASE $P048_BASE == merge-base(M^1, M^2)" || bad "PIN_BASE differs from derived $mb"
  [ "$p2" = "$P048_FINAL" ] && ok "PIN_FINAL $P048_FINAL == M^2" || bad "PIN_FINAL differs from derived $p2"
  local f
  for f in CLAUDE.md docs/manager/MANAGER.md; do   # positive control: the marker c4 reads exists at the pin
    git show "$P048_FINAL:$f" | grep -q 'SUSPENDED by Ludwig 2026-10-14' && ok "marker present in $f at the pin" || bad "marker absent in $f at the pin"
  done
  grep -q "^PIN_BASE=\"$P048_BASE\"" "$V048" && grep -q "^PIN_FINAL=\"$P048_FINAL\"" "$V048" && ok "048-verify.sh carries exactly these pins" || bad "048-verify.sh pins differ from the derived ones"
}
# ac1_fn REV : 048 at REV is green before and after the revocation; the unreachable pin is red (exit 2), never skip
ac1_fn() {
  local REV=$1 C="$TMP/a1-$1"
  echo "== AC1 048-verify.sh@${REV:0:7} on a later branch that revokes the suspension (c4 reads the pinned FINAL)"
  mkclone "$C" "$BASE_SHA"
  if [ "$REV" = "$BASE_SHA" ] || [ -n "${AC1_REDFIRST:-}" ]; then
    expect_rc 0 "$C" "a1-old-before" bash "$V048"      # old script, unrevoked tree: green (control)
    revoke "$C" >/dev/null || return
    expect_red "$C" "a1-old-after" bash "$V048"        # old script, revoked tree: RED (the defect)
    has a1-old-after "FAIL c4: CLAUDE.md has no SUSPENDED marker"
  else
    revoke "$C" >/dev/null || return
  fi
  overlay "$C" "$REV" "$V048"
  expect_rc 0 "$C" "a1-after-$REV" bash "$V048"        # script under test, revoked tree: must be green
  local k v
  for k in PIN_BASE PIN_FINAL; do                      # unreachable pin: red, exit 2, never skip
    sed "s/^$k=.*/$k=\"deadbee\"/" "$C/$V048" >"$C/$T/048-dead.sh"
    cmp -s "$C/$V048" "$C/$T/048-dead.sh" && bad "$k deadbee mutation was a no-op"
    expect_rc 2 "$C" "a1-dead-$k" bash "$T/048-dead.sh"
    has "a1-dead-$k" "FAIL: pinned commit deadbee not found"
  done
}
# ac1_widen : the c4 reads moved back to HEAD ($T instead of $T1) must redden on the revoked tree (the mutation AC1 names)
ac1_widen() {
  echo "== AC1 mutation: c4 widened to HEAD reddens on the revoked branch"
  local C="$TMP/a1-wide"
  mkclone "$C" "$BASE_SHA"; revoke "$C" >/dev/null || return; overlay "$C" "$HEADSHA" "$V048"
  sed -i -e '/grep -n .SUSPENDED by Ludwig 2026-10-14/s#"\$T1/\$f"#"$T/$f"#' -e "/grep -n \"Ludwig's Claude Max subscription is shared\"/s#\"\$T1/\$f\"#\"\$T/\$f\"#" "$C/$V048"
  [ "$(grep -c 'ln[12]=.*"\$T/\$f"' "$C/$V048")" = 2 ] && ok "both c4 reads widened to \$T" || bad "widening mutation did not apply to both c4 lines"
  expect_red "$C" a1-wide bash "$V048"
  has a1-wide "FAIL c4: CLAUDE.md has no SUSPENDED marker"
}

# ------------------------------------------------------------------------------------------------------------ AC2
# ac2_fn SCRIPT_REV : 079 stays live; clean clone green; marker removed from HEAD's files -> red. SCRIPT_REV=STUB runs an "exit 0" stand-in.
ac2_fn() {
  local R=$1 C="$TMP/a2-$1" rc
  echo "== AC2 079-verify.sh stays a live guard of the suspension marker"
  mkclone "$C" "$HEADSHA"
  [ "$R" = STUB ] && { printf '#!/usr/bin/env bash\nexit 0\n' >"$C/$V079"; commit_all "$C" stub; }
  expect_rc 0 "$C" a2-clean bash "$V079"
  grep -q 'LIVE GUARD (task 090' "$C/$V079" && ok "079 carries the live-guard comment" || bad "079 lacks the live-guard comment"
  local added removed
  added=$(git diff -U0 "$BASE_SHA" "$HEADSHA" -- "$V079" | grep -c '^+[^+]'); removed=$(git diff -U0 "$BASE_SHA" "$HEADSHA" -- "$V079" | grep -c '^-[^-]')
  [ "$removed" = 0 ] && [ "$added" = 1 ] && ok "079 diff vs base: 1 comment line added, 0 removed" || bad "079 diff vs base is +$added/-$removed, expected +1/-0"
  # marker removed from CLAUDE.md only, then from both files
  ( cd "$C" && sed -i '/SUSPENDED by Ludwig 2026-10-14/d' CLAUDE.md ) && ! grep -q 'SUSPENDED by Ludwig 2026-10-14' "$C/CLAUDE.md" || bad "CLAUDE.md marker removal did not apply"
  commit_all "$C" "marker removed (CLAUDE.md)"
  expect_red "$C" a2-claude bash "$V079"
  ( cd "$C" && sed -i '/SUSPENDED by Ludwig 2026-10-14/d' docs/manager/MANAGER.md ) && ! grep -q 'SUSPENDED by Ludwig 2026-10-14' "$C/docs/manager/MANAGER.md" || bad "MANAGER.md marker removal did not apply"
  commit_all "$C" "marker removed (both)"
  expect_red "$C" a2-both bash "$V079"
  echo "  named: $(grep -m2 -E 'FAIL|cannot locate' "$TMP/a2-both.out" | tr '\n' '|' | cut -c1-200)"
}

# ------------------------------------------------------------------------------------------------------------ AC3
# ac3_fn REV : no T072_(BASE|FINAL)/T080_ in the scripts at REV; the old names have no effect; unreachable pins and a bad REG are red
ac3_fn() {
  local REV=$1 C="$TMP/a3-$1" n rc0 rc1
  echo "== AC3 072/080 pins cannot be overridden (scripts@${REV:0:7})"
  n=$( { sc "$REV" "$V072"; sc "$REV" "$V080"; } | grep -cE 'T072_(BASE|FINAL)|T080_' )
  [ "$n" = 0 ] && ok "grep T072_(BASE|FINAL)|T080_ -> 0 lines" || bad "grep T072_(BASE|FINAL)|T080_ -> $n lines (override still present)"
  mkclone "$C" "$HEADSHA"; overlay "$C" "$REV" "$V072" "$V080"
  local s v
  for s in 072 080; do
    if [ "$s" = 072 ]; then v=T072_BASE; else v=T080_BASE; fi
    rc0=$(run "$C" "a3-$s-unset" bash "$T/$s-verify.sh")
    rc1=$(run "$C" "a3-$s-env" env "$v=deadbee" bash "$T/$s-verify.sh")
    [ "$rc0" = 0 ] && ok "$s unset -> exit 0" || bad "$s unset -> exit $rc0, expected 0"
    [ "$rc0" = "$rc1" ] && ok "$s with $v=deadbee -> exit $rc1 (unchanged)" || bad "$s with $v=deadbee -> exit $rc1, unset gave $rc0 (override has effect)"
    cmp -s "$TMP/a3-$s-unset.out" "$TMP/a3-$s-env.out" && ok "$s output byte-identical with and without $v" || bad "$s output differs with $v set"
    for k in BASE FINAL; do   # the script's own pin replaced by deadbee: red, never skip
      sed "s/^$k=.*/$k=deadbee/" "$C/$T/$s-verify.sh" >"$C/$T/$s-dead.sh"
      cmp -s "$C/$T/$s-verify.sh" "$C/$T/$s-dead.sh" && bad "$s $k deadbee mutation was a no-op"
      expect_red "$C" "a3-$s-dead-$k" bash "$T/$s-dead.sh"
      has "a3-$s-dead-$k" "FAIL pin deadbee unreachable"
    done
  done
  # REG assertion (072): not a repo, a subdirectory of another repo, a repo without origin/main -> red with a named reason
  mkdir -p "$TMP/notrepo" "$TMP/norigin"; git init -q "$TMP/norigin"
  expect_red "$C" a3-reg-nonrepo env "T072_REGISTRY=$TMP/notrepo" bash "$T/072-verify.sh"
  has a3-reg-nonrepo "is not a git repository"
  expect_red "$C" a3-reg-subdir env "T072_REGISTRY=$C/docs" bash "$T/072-verify.sh"
  has a3-reg-subdir "is not a git repository"
  expect_red "$C" a3-reg-noorigin env "T072_REGISTRY=$TMP/norigin" bash "$T/072-verify.sh"
  has a3-reg-noorigin "origin/main does not resolve"
}
ac3_positive() {  # the grep matches in the OLD scripts (positive control: 4 override lines)
  local n; n=$( { sc "$BASE_SHA" "$V072"; sc "$BASE_SHA" "$V080"; } | grep -cE 'T072_(BASE|FINAL)|T080_' )
  [ "$n" = 4 ] && ok "AC3 positive control: the same grep matches $n lines in the old 072/080" || bad "AC3 positive control: expected 4 matches in old scripts, got $n"
}

# ------------------------------------------------------------------------------------------------------------ AC4
# ac4_fn REV : 085 at REV with the nested-control sed broken: must FAIL at "nested: Last reviewed substitution applied"; unbroken must pass
ac4_fn() {
  local REV=$1 C="$TMP/a4-$1" line
  echo "== AC4 085-verify.sh@${REV:0:7}: nested control asserts the Last reviewed substitution"
  mkclone "$C" "$HEADSHA"; overlay "$C" "$REV" "$V085"
  expect_rc 0 "$C" "a4-unbroken-$REV" bash "$V085"                        # unbroken script: green (positive control)
  line=$(grep -n 'cd "\$TMP/n" && sed -i' "$C/$V085" | head -1 | cut -d: -f1)
  [ -n "$line" ] || { bad "cannot find the nested-control sed line in 085@$REV"; return; }
  sed -i "${line}s/(task 068)/(task 069)/" "$C/$V085"                    # break: the substitution can no longer match
  git -C "$C" diff --quiet -- "$V085" && { bad "sed-break mutation was a no-op"; return; }
  expect_red "$C" "a4-broken-$REV" bash "$V085"
  has "a4-broken-$REV" "FAIL nested: Last reviewed substitution applied"
}
# ac4_gap : the OLD 085 with the same break still passes (the gap that existed)
ac4_gap() {
  echo "== AC4 red first: the OLD 085 with the broken nested sed passes (the gap)"
  local C="$TMP/a4-gap" line
  mkclone "$C" "$BASE_SHA"
  line=$(grep -n 'cd "\$TMP/n" && sed -i' "$C/$V085" | head -1 | cut -d: -f1)
  sed -i "${line}s/(task 068)/(task 069)/" "$C/$V085"
  git -C "$C" diff --quiet -- "$V085" && { bad "gap mutation was a no-op"; return; }
  expect_rc 0 "$C" a4-old-broken bash "$V085"
}

# ------------------------------------------------------------------------------------------------------------ AC5
# ac5_fn REV : every touched script is green on HEAD and on HEAD-merged-with-a-later-branch; 079 (live by design, Q1) is green on HEAD, red on the merge
ac5_fn() {
  local REV=$1 H="$TMP/a5h-$1" MG="$TMP/a5m-$1" s
  echo "== AC5 item 12: touched scripts@${REV:0:7} on HEAD and on the merge with a later branch"
  mkclone "$H" "$HEADSHA"; overlay "$H" "$REV" "$V048" "$V072" "$V080" "$V085"
  merge_clone "$MG" "$REV"
  for s in 048 072 080 085; do
    expect_rc 0 "$H"  "a5-head-$s-$REV"  bash "$T/$s-verify.sh"
    expect_rc 0 "$MG" "a5-merge-$s-$REV" bash "$T/$s-verify.sh"
  done
  expect_rc 0 "$H" "a5-head-079-$REV" bash "$V079"
  expect_red "$MG" "a5-merge-079-$REV" bash "$V079"   # live guard reddens when the marker is revoked: intended (AC2 / Q1)
}
ac5_positive() {  # the unfixed 048 is red on the same merge
  echo "== AC5 positive control: the OLD 048 on the same merge"
  local MG="$TMP/a5m-old"
  merge_clone "$MG" "$BASE_SHA"
  expect_red "$MG" a5-merge-048-old bash "$V048"
  has a5-merge-048-old "FAIL c4: CLAUDE.md has no SUSPENDED marker"
}

# ------------------------------------------------------------------------------------------------------------ AC7
ac7_fn() {
  local FINAL=$1 f r a expect
  echo "== AC7 scope: git diff --name-only ${BASE_SHA:0:7}..${FINAL:0:7} is a subset of File scope"
  if [ "$FINAL" = "__FIN""AL__" ]; then bad "PIN_FINAL not recorded"; return; fi
  git rev-parse --verify -q "$FINAL^{commit}" >/dev/null || { bad "PIN_FINAL $FINAL unreachable (never skip)"; return; }
  local files; files=$(git diff --name-only "$BASE_SHA" "$FINAL")
  [ -n "$files" ] || { bad "empty change set"; return; }
  for f in $files; do printf '%s\n' $SCOPE | grep -qxF -- "$f" && ok "in scope: $f" || bad "out of scope: $f"; done
  echo "  hunks (git diff -U0):"; git diff -U0 "$BASE_SHA" "$FINAL" -- "$V048" "$V072" "$V079" "$V080" "$V085" | grep -E '^(\+\+\+|@@)' | cut -c1-120 | sed 's/^/    /'
  # exact removed/added line counts per edited script; everything else is byte-identical by construction (diff -U0 shows only these hunks)
  for expect in "$V048:7:8" "$V072:2:5" "$V079:0:1" "$V080:2:3" "$V085:0:1"; do
    f=${expect%%:*}; r=${expect#*:}; a=${r#*:}; r=${r%%:*}
    local gr ga; gr=$(git diff -U0 "$BASE_SHA" "$FINAL" -- "$f" | grep -c '^-[^-]'); ga=$(git diff -U0 "$BASE_SHA" "$FINAL" -- "$f" | grep -c '^+[^+]')
    [ "$gr" = "$r" ] && [ "$ga" = "$a" ] && ok "$f: -$gr/+$ga lines as expected" || bad "$f: -$gr/+$ga lines, expected -$r/+$a"
  done
  # 048: the removed lines are only c4 and the c4 mutation harness (and its header comment); named, not counted
  local bad048; bad048=$(git diff -U0 "$BASE_SHA" "$FINAL" -- "$V048" | grep '^-[^-]' | grep -vE 'c4: token-guard marker|ln[12]=\$\(grep -n|a c1 mutation edits|\[ "\$tag" = c1 \]|checks AC1-AC7: c1' || true)
  [ -z "$bad048" ] && ok "048: every removed line belongs to c4, its mutation harness or the header comment" || bad "048: removed line outside c4: $bad048"
  # 072/080: removed lines are exactly the pin lines
  local b; b=$(git diff -U0 "$BASE_SHA" "$FINAL" -- "$V072" "$V080" | grep '^-[^-]' | grep -vE '^-(BASE|FINAL)=\$\{T0(72|80)_(BASE|FINAL):-' || true)
  [ -z "$b" ] && ok "072/080: removed lines are only the BASE/FINAL pin lines" || bad "072/080: removed line outside the pins: $b"
}

# ------------------------------------------------------------------------------------------------------------ AC6 sweep
ac6_sweep() {
  local d name label s others rc
  echo "== AC6 sweep: every closed platform script, one at a time, on HEAD and on the merge"
  mkclone "$TMP/a6h" "$HEADSHA"; merge_clone "$TMP/a6m" "$HEADSHA"
  for label in head merge; do
    if [ $label = head ]; then d="$TMP/a6h"; else d="$TMP/a6m"; fi
    for s in "$d"/$T/[0-9]*-verify.sh; do
      name=$(basename "$s"); [ "$name" = 090-verify.sh ] && continue
      others=$(ps -eo pid=,args= | grep -E '[0-9]{3}[a-z]?-verify\.sh' | grep -v 'grep' | grep -v '090-verify.sh' || true)
      if [ -n "$others" ]; then bad "machine not quiet before $label/$name (another *-verify.sh is running); run is not evidence"; echo "$others" | cut -c1-160; continue; fi
      echo "  ps: no other *-verify.sh process before $label/$name"
      rc=$(run "$d" "a6-$label-$name" bash "$T/$name")
      if [ "$rc" = 0 ]; then ok "$label $name -> exit 0"
      elif [ "$label" = merge ] && [ "$name" = 079-verify.sh ]; then ok "merge 079-verify.sh -> exit $rc (live guard, red by design on a revocation)"
      else bad "$label $name -> exit $rc"; tail -5 "$TMP/a6-$label-$name.out" | cut -c1-200; fi
    done
  done
}

# ------------------------------------------------------------------------------------------------------------ main
ALL="$TMP/all.out"; : >"$ALL"
section() { "$@" 2>&1 | tee -a "$ALL"; }
echo "== task 090 verify: HEAD ${HEADSHA:0:7}, base ${BASE_SHA:0:7}; mutate=$DO_MUTATE sweep=$DO_SWEEP"
section ac1_pins
AC1_REDFIRST=1 section ac1_fn "$HEADSHA"
section ac2_fn HEAD
section ac3_positive
section ac3_fn "$HEADSHA"
section ac4_gap
section ac4_fn "$HEADSHA"
section ac5_fn "$HEADSHA"
section ac5_positive
section ac7_fn "$PIN_FINAL"
[ "$DO_SWEEP" = 1 ] && section ac6_sweep

if [ "$DO_MUTATE" = 1 ]; then
  echo "== mutations: each check function is run against a broken subject and must report at least one FAIL line"
  MF=0
  # mexpect NAME CMD... : the function's output must contain a FAIL line
  mexpect() { local n=$1; shift; "$@" >"$TMP/m-$n.out" 2>&1; if grep -q '^  FAIL' "$TMP/m-$n.out"; then ok "mutation '$n' -> check red: $(grep -m1 '^  FAIL' "$TMP/m-$n.out" | cut -c1-110)"; else bad "mutation '$n' did NOT turn its check red"; fi; }
  section mexpect "old 048 (c4 on HEAD) vs AC1"        ac1_fn "$BASE_SHA"
  section ac1_widen
  section mexpect "old 072/080 (env overrides) vs AC3" ac3_fn "$BASE_SHA"
  section mexpect "old 085 (no nested assertion) vs AC4" ac4_fn "$BASE_SHA"
  section mexpect "old 048 on the merge vs AC5"        ac5_fn "$BASE_SHA"
  section mexpect "079 that never reddens vs AC2"      ac2_fn STUB
  section mexpect "FINAL = an out-of-scope commit vs AC7" ac7_fn "$(git rev-parse "$BASE_SHA^1")"
fi

NF=$(grep -c '^  FAIL' "$ALL" || true)
# the broken-subject FAIL lines inside mexpect go to $TMP/m-*.out, not to $ALL; only the verdict line mexpect prints (ok/FAIL) counts here
echo "== 090-verify: $([ "$NF" = 0 ] && echo 'ALL CHECKS PASSED' || echo "$NF FAILED")"
[ "$NF" = 0 ]
