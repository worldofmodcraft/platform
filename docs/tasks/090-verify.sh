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
PIN_FINAL="2f71ac9f39691b4917ef23bba1245d7fcbdd142f"
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
TMP="$(mktemp -d "${TMPDIR:-/tmp}/wom090-XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT
# bad also appends to a file (BADFILE, default $TMP/fails.txt) that the final gate reads, so a FAIL can never be lost to a pipe or a subshell;
# --mutate points BADFILE elsewhere while it runs a deliberately broken subject, so expected failures do not count against the run
bad() { echo "  FAIL $*"; echo "$*" >>"${BADFILE:-$TMP/fails.txt}"; }
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
    && git -C "$1" checkout -q --detach "$2" || { bad "setup: clone failed ($1 at $2)"; return 1; }
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
  mkclone "$1" "$BASE_SHA" || return 1
  git -C "$1" checkout -q -b later || { bad "setup: cannot create branch 'later' in $1"; return 1; }
  revoke "$1" || { bad "setup: revoke commit failed in $1"; return 1; }
  runbook_edit "$1" || { bad "setup: runbook commit failed in $1"; return 1; }
  git -C "$1" checkout -q --detach "$HEADSHA" || { bad "setup: cannot check out HEAD $HEADSHA in $1"; return 1; }
  git -C "$1" "${GITID[@]}" merge -q --no-edit later >"$TMP/merge.err" 2>&1 || { bad "setup: merge of the later branch failed (conflict?): $(head -3 "$TMP/merge.err" | tr '\n' ' ')"; return 1; }
  grep -q 'REVOKED by Ludwig 2026-11-01' "$1/CLAUDE.md" && grep -q '^## ☑ M4 ' "$1/$RB" && [ "$(git -C "$1" rev-list --parents -n1 HEAD | wc -w)" = 3 ] \
    || { bad "setup: merge fixture check failed in $1"; return 1; }
  [ "$2" = "$HEADSHA" ] || overlay "$1" "$2" "$V048" "$V072" "$V080" "$V085" || { bad "setup: overlay failed in $1"; return 1; }
  return 0
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
  return 0
}
# ac1_fn REV : 048 at REV is green before and after the revocation; the unreachable pin is red (exit 2), never skip
ac1_fn() {
  local REV=$1 C="$TMP/a1-$1"
  echo "== AC1 048-verify.sh@${REV:0:7} on a later branch that revokes the suspension (c4 reads the pinned FINAL)"
  mkclone "$C" "$BASE_SHA" || return 1
  if [ "$REV" = "$BASE_SHA" ] || [ -n "${AC1_REDFIRST:-}" ]; then
    expect_rc 0 "$C" "a1-old-before" bash "$V048"      # old script, unrevoked tree: green (control)
    revoke "$C" || return 1
    expect_red "$C" "a1-old-after" bash "$V048"        # old script, revoked tree: RED (the defect)
    has a1-old-after "FAIL c4: CLAUDE.md has no SUSPENDED marker"
  else
    revoke "$C" || return 1
  fi
  overlay "$C" "$REV" "$V048" || return 1
  expect_rc 0 "$C" "a1-after-$REV" bash "$V048"        # script under test, revoked tree: must be green
  local k v
  for k in PIN_BASE PIN_FINAL; do                      # unreachable pin: red, exit 2, never skip
    sed "s/^$k=.*/$k=\"deadbee\"/" "$C/$V048" >"$C/$T/048-dead.sh"
    cmp -s "$C/$V048" "$C/$T/048-dead.sh" && bad "$k deadbee mutation was a no-op"
    expect_rc 2 "$C" "a1-dead-$k" bash "$T/048-dead.sh"
    has "a1-dead-$k" "FAIL: pinned commit deadbee not found"
  done
  return 0
}
# ac1_widen : the c4 reads moved back to HEAD ($T instead of $T1) must redden on the revoked tree (the mutation AC1 names)
ac1_widen() {
  echo "== AC1 mutation: c4 widened to HEAD reddens on the revoked branch"
  local C="$TMP/a1-wide"
  mkclone "$C" "$BASE_SHA" || return 1; revoke "$C" || return 1; overlay "$C" "$HEADSHA" "$V048" || return 1
  sed -i -e '/grep -n .SUSPENDED by Ludwig 2026-10-14/s#"\$T1/\$f"#"$T/$f"#' -e "/grep -n \"Ludwig's Claude Max subscription is shared\"/s#\"\$T1/\$f\"#\"\$T/\$f\"#" "$C/$V048"
  [ "$(grep -c 'ln[12]=.*"\$T/\$f"' "$C/$V048")" = 2 ] && ok "both c4 reads widened to \$T" || bad "widening mutation did not apply to both c4 lines"
  expect_red "$C" a1-wide bash "$V048"
  has a1-wide "FAIL c4: CLAUDE.md has no SUSPENDED marker"
  return 0
}

# ------------------------------------------------------------------------------------------------------------ AC2
# ac2_fn SCRIPT_REV : 079 stays live; clean clone green; marker removed from HEAD's files -> red. SCRIPT_REV=STUB runs an "exit 0" stand-in.
ac2_fn() {
  local R=$1 C="$TMP/a2-$1" rc
  echo "== AC2 079-verify.sh stays a live guard of the suspension marker"
  mkclone "$C" "$HEADSHA" || return 1
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
  has a2-claude "cannot locate anchors"   # 079 line 30: the live anchor `sus` is gone, named reason, not just any non-zero exit
  ( cd "$C" && sed -i '/SUSPENDED by Ludwig 2026-10-14/d' docs/manager/MANAGER.md ) && ! grep -q 'SUSPENDED by Ludwig 2026-10-14' "$C/docs/manager/MANAGER.md" || bad "MANAGER.md marker removal did not apply"
  commit_all "$C" "marker removed (both)"
  expect_red "$C" a2-both bash "$V079"
  has a2-both "cannot locate anchors"
  echo "  named: $(grep -m2 -E 'FAIL|cannot locate' "$TMP/a2-both.out" | tr '\n' '|' | cut -c1-200)"
  return 0
}

# ------------------------------------------------------------------------------------------------------------ AC3
# ac3_fn REV : no T072_(BASE|FINAL)/T080_ in the scripts at REV; the old names have no effect; unreachable pins and a bad REG are red
ac3_fn() {
  local REV=$1 C="$TMP/a3-$1" n rc0 rc1
  echo "== AC3 072/080 pins cannot be overridden (scripts@${REV:0:7})"
  n=$( { sc "$REV" "$V072"; sc "$REV" "$V080"; } | grep -cE 'T072_(BASE|FINAL)|T080_' )
  [ "$n" = 0 ] && ok "grep T072_(BASE|FINAL)|T080_ -> 0 lines" || bad "grep T072_(BASE|FINAL)|T080_ -> $n lines (override still present)"
  mkclone "$C" "$HEADSHA" || return 1; overlay "$C" "$REV" "$V072" "$V080" || return 1
  local s v
  for s in 072 080; do
    if [ "$s" = 072 ]; then v=T072_BASE; else v=T080_BASE; fi
    rc0=$(run "$C" "a3-$s-unset" bash "$T/$s-verify.sh")
    rc1=$(run "$C" "a3-$s-env" env "$v=deadbee" bash "$T/$s-verify.sh")
    [ "$rc0" = 0 ] && ok "$s unset -> exit 0" || bad "$s unset -> exit $rc0, expected 0"
    [ "$rc0" = "$rc1" ] && ok "$s with $v=deadbee -> exit $rc1 (unchanged)" || bad "$s with $v=deadbee -> exit $rc1, unset gave $rc0 (override has effect)"
    # compare only the sorted PASS/FAIL verdict lines (080 reads the network; other lines may vary), and require that there are some
    grep -E '^(PASS|FAIL)' "$TMP/a3-$s-unset.out" | sort >"$TMP/a3-$s-unset.v"; grep -E '^(PASS|FAIL)' "$TMP/a3-$s-env.out" | sort >"$TMP/a3-$s-env.v"
    [ -s "$TMP/a3-$s-unset.v" ] && cmp -s "$TMP/a3-$s-unset.v" "$TMP/a3-$s-env.v" && ok "$s PASS/FAIL lines identical with and without $v ($(wc -l <"$TMP/a3-$s-unset.v") lines)" || bad "$s PASS/FAIL lines differ with $v set (or none found)"
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
  return 0
}
ac3_positive() {  # the grep matches in the OLD scripts (positive control: 4 override lines)
  local n; n=$( { sc "$BASE_SHA" "$V072"; sc "$BASE_SHA" "$V080"; } | grep -cE 'T072_(BASE|FINAL)|T080_' )
  [ "$n" = 4 ] && ok "AC3 positive control: the same grep matches $n lines in the old 072/080" || bad "AC3 positive control: expected 4 matches in old scripts, got $n"
  return 0
}

# ------------------------------------------------------------------------------------------------------------ AC4
# ac4_fn REV : 085 at REV with the nested-control sed broken: must FAIL at "nested: Last reviewed substitution applied"; unbroken must pass
ac4_fn() {
  local REV=$1 C="$TMP/a4-$1" line
  echo "== AC4 085-verify.sh@${REV:0:7}: nested control asserts the Last reviewed substitution"
  mkclone "$C" "$HEADSHA" || return 1; overlay "$C" "$REV" "$V085" || return 1
  expect_rc 0 "$C" "a4-unbroken-$REV" bash "$V085"                        # unbroken script: green (positive control)
  line=$(grep -n 'cd "\$TMP/n" && sed -i' "$C/$V085" | head -1 | cut -d: -f1)
  [ -n "$line" ] || { bad "cannot find the nested-control sed line in 085@$REV"; return 1; }
  sed -i "${line}s/(task 068)/(task 069)/" "$C/$V085"                    # break: the substitution can no longer match
  git -C "$C" diff --quiet -- "$V085" && { bad "sed-break mutation was a no-op"; return 1; }
  expect_red "$C" "a4-broken-$REV" bash "$V085"
  has "a4-broken-$REV" "FAIL nested: Last reviewed substitution applied"
  return 0
}
# ac4_gap : the OLD 085 with the same break still passes (the gap that existed)
ac4_gap() {
  echo "== AC4 red first: the OLD 085 with the broken nested sed passes (the gap)"
  local C="$TMP/a4-gap" line
  mkclone "$C" "$BASE_SHA" || return 1
  line=$(grep -n 'cd "\$TMP/n" && sed -i' "$C/$V085" | head -1 | cut -d: -f1)
  sed -i "${line}s/(task 068)/(task 069)/" "$C/$V085"
  git -C "$C" diff --quiet -- "$V085" && { bad "gap mutation was a no-op"; return 1; }
  expect_rc 0 "$C" a4-old-broken bash "$V085"
  return 0
}

# ------------------------------------------------------------------------------------------------------------ AC5
# ac5_fn REV : every touched script is green on HEAD and on HEAD-merged-with-a-later-branch; 079 (live by design, Q1) is green on HEAD, red on the merge
ac5_fn() {
  local REV=$1 H="$TMP/a5h-$1" MG="$TMP/a5m-$1" s
  echo "== AC5 item 12: touched scripts@${REV:0:7} on HEAD and on the merge with a later branch"
  mkclone "$H" "$HEADSHA" || return 1; overlay "$H" "$REV" "$V048" "$V072" "$V080" "$V085" || return 1
  merge_clone "$MG" "$REV" || return 1
  for s in 048 072 080 085; do
    expect_rc 0 "$H"  "a5-head-$s-$REV"  bash "$T/$s-verify.sh"
    expect_rc 0 "$MG" "a5-merge-$s-$REV" bash "$T/$s-verify.sh"
  done
  expect_rc 0 "$H" "a5-head-079-$REV" bash "$V079"
  expect_red "$MG" "a5-merge-079-$REV" bash "$V079"   # live guard reddens when the marker is revoked: intended (AC2 / Q1)
  return 0
}
ac5_positive() {  # the unfixed 048 is red on the same merge
  echo "== AC5 positive control: the OLD 048 on the same merge"
  local MG="$TMP/a5m-old"
  merge_clone "$MG" "$BASE_SHA" || return 1
  expect_red "$MG" a5-merge-048-old bash "$V048"
  has a5-merge-048-old "FAIL c4: CLAUDE.md has no SUSPENDED marker"
  return 0
}
# AC5 idempotence cell (task 090 scope amendment, 085 nested fixture): 085 on a tree that ALREADY carries the M4 / Last reviewed edits
ac5_idem_old() {  # red first: the OLD 085 aborts at its own nested setup (sed changes nothing, nothing to commit)
  echo "== AC5 idempotence red first: the OLD 085 on a tree that already carries the M4 / Last reviewed edits"
  merge_clone "$TMP/a5i-old" "$BASE_SHA" || return 1
  expect_rc 2 "$TMP/a5i-old" a5i-old-085 bash "$V085"
  has a5i-old-085 "nested setup failed"
  return 0
}
ac5_idem_fn() {  # 085@REV must be green on that tree
  echo "== AC5 idempotence: 085@${1:0:7} on a tree that already carries the M4 / Last reviewed edits"
  merge_clone "$TMP/a5i-$1" "$1" || return 1
  expect_rc 0 "$TMP/a5i-$1" "a5i-085-$1" bash "$V085"
  return 0
}

# ------------------------------------------------------------------------------------------------------------ AC7
ac7_fn() {
  local FINAL=$1 f r a expect
  echo "== AC7 scope: git diff --name-only ${BASE_SHA:0:7}..${FINAL:0:7} is a subset of File scope"
  if [ "$FINAL" = "__FIN""AL__" ]; then bad "PIN_FINAL not recorded"; return 1; fi
  git rev-parse --verify -q "$FINAL^{commit}" >/dev/null || { bad "PIN_FINAL $FINAL unreachable (never skip)"; return 1; }
  local files; files=$(git diff --name-only "$BASE_SHA" "$FINAL")
  [ -n "$files" ] || { bad "empty change set"; return 1; }
  for f in $files; do printf '%s\n' $SCOPE | grep -qxF -- "$f" && ok "in scope: $f" || bad "out of scope: $f"; done
  echo "  hunks (git diff -U0):"; git diff -U0 "$BASE_SHA" "$FINAL" -- "$V048" "$V072" "$V079" "$V080" "$V085" | grep -E '^(\+\+\+|@@)' | cut -c1-120 | sed 's/^/    /'
  # exact removed/added line counts per edited script; everything else is byte-identical by construction (diff -U0 shows only these hunks)
  for expect in "$V048:7:8" "$V072:2:5" "$V079:0:1" "$V080:2:3" "$V085:1:2"; do
    f=${expect%%:*}; r=${expect#*:}; a=${r#*:}; r=${r%%:*}
    local gr ga; gr=$(git diff -U0 "$BASE_SHA" "$FINAL" -- "$f" | grep -c '^-[^-]'); ga=$(git diff -U0 "$BASE_SHA" "$FINAL" -- "$f" | grep -c '^+[^+]')
    [ "$gr" = "$r" ] && [ "$ga" = "$a" ] && ok "$f: -$gr/+$ga lines as expected" || bad "$f: -$gr/+$ga lines, expected -$r/+$a"
  done
  # 048: the removed lines are only c4 and the c4 mutation harness (and its header comment); named, not counted
  local bad048; bad048=$(git diff -U0 "$BASE_SHA" "$FINAL" -- "$V048" | grep '^-[^-]' | grep -vE 'c4: token-guard marker|ln[12]=\$\(grep -n|a c1 mutation edits|\[ "\$tag" = c1 \]|checks AC1-AC7: c1' || true)
  [ -z "$bad048" ] && ok "048: every removed line belongs to c4, its mutation harness or the header comment" || bad "048: removed line outside c4: $bad048"
  # 048: the ADDED lines are exactly the c4 comment, the two c4 reads of "$T1/$f", the harness condition lines and the header line
  local a048; a048=$(git diff -U0 "$BASE_SHA" "$FINAL" -- "$V048" | grep '^+[^+]' | grep -vE 'c4: token-guard marker \(OWN-CHANGE|live guard of the marker|ln[12]=\$\(grep -n .*"\$T1/\$f"|a c1 or c4 mutation edits|\[ "\$tag" = c1 \] \|\| \[ "\$tag" = c4 \]|checks AC1-AC7: c1 and c4' || true)
  [ -z "$a048" ] && ok "048: every added line is a c4 / harness / header line" || bad "048: added line outside c4: $a048"
  [ "$(git diff -U0 "$BASE_SHA" "$FINAL" -- "$V048" | grep -cE '^\+ +ln[12]=.*"\$T1/\$f"')" = 2 ] && ok "048: exactly two added c4 reads of \"\$T1/\$f\"" || bad "048: the two c4 reads of \"\$T1/\$f\" are not exactly the added ln1=/ln2= lines"
  # 072/080: ADDED lines are exactly the fixed pins, the comment and (072) the REG assertions
  local ad; ad=$(git diff -U0 "$BASE_SHA" "$FINAL" -- "$V072" "$V080" | grep '^+[^+]' | grep -vE '^\+# Task 090: (BASE/FINAL are fixed pins|fixed pins)|^\+BASE=(d9d48de|29b3424fc97ba919f598531e9f4f154acc2a0619)$|^\+FINAL=(7df8a50979cc834918871ba948aa9ed7e9eb4352|f173739800707d44a32fe495e96a39022c0c84bb)$|^\+\[ -d "\$REG" \]|^\+git -C "\$REG" rev-parse --verify -q "origin/main' || true)
  [ -z "$ad" ] && ok "072/080: added lines are only the fixed pins, the comment and the REG assertions" || bad "072/080: added line outside the allowed set: $ad"
  # 085: exactly the nested-fixture block: removed = the old commit line; added = that line with --allow-empty and the new named check
  local r85 a85
  r85=$(git diff -U0 "$BASE_SHA" "$FINAL" -- "$V085" | grep '^-[^-]' | grep -vF 'commit -q -m "throw-away later task: M4 done, Last reviewed moved"' || true)
  a85=$(git diff -U0 "$BASE_SHA" "$FINAL" -- "$V085" | grep '^+[^+]' | grep -vF -e 'commit -q --allow-empty -m "throw-away later task: M4 done, Last reviewed moved"' -e "nested: Last reviewed substitution applied" || true)
  [ -z "$r85" ] && [ -z "$a85" ] && ok "085: changed lines are only the nested fixture commit line and the new named check" || bad "085: change outside the nested fixture block: $r85 $a85"
  # after FINAL only this task's own log and script may change (HEAD = FINAL + the recording commit)
  local late; late=$(git diff --name-only "$FINAL" "$HEADSHA" | grep -vxF -e "$T/090-closed-verify-sweep-platform.md" -e "$T/090-verify.sh" || true)
  [ -z "$late" ] && ok "FINAL..HEAD touches only the 090 task file and 090-verify.sh" || bad "later change out of scope: $late"
  # 072/080: removed lines are exactly the pin lines
  local b; b=$(git diff -U0 "$BASE_SHA" "$FINAL" -- "$V072" "$V080" | grep '^-[^-]' | grep -vE '^-(BASE|FINAL)=\$\{T0(72|80)_(BASE|FINAL):-' || true)
  [ -z "$b" ] && ok "072/080: removed lines are only the BASE/FINAL pin lines" || bad "072/080: removed line outside the pins: $b"
  return 0
}

# ------------------------------------------------------------------------------------------------------------ AC6 sweep
ac6_sweep() {
  local d name label s others rc
  echo "== AC6 sweep: every closed platform script, one at a time, on HEAD and on the merge"
  mkclone "$TMP/a6h" "$HEADSHA" || return 1; merge_clone "$TMP/a6m" "$HEADSHA" || return 1
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
  return 0
}

ALL="$TMP/all.out"; : >"$ALL"; : >"$TMP/fails.txt"
# section LABEL CMD... : run a check function, tee its output into $ALL, and print a sentinel only if it ran to its end (return 0).
# A function that aborts on a setup failure returns 1, which is recorded as a FAIL; the final gate also requires every sentinel.
section() {
  local lbl=$1 rc; shift
  { "$@"; echo $? >"$TMP/rc.$lbl"; } 2>&1 | tee -a "$ALL"
  rc=$(cat "$TMP/rc.$lbl" 2>/dev/null || echo missing)
  if [ "$rc" = 0 ]; then echo "  sentinel $lbl" | tee -a "$ALL"; else bad "section $lbl aborted (return code $rc)" | tee -a "$ALL"; fi
}
echo "== task 090 verify: HEAD ${HEADSHA:0:7}, base ${BASE_SHA:0:7}; mutate=$DO_MUTATE sweep=$DO_SWEEP"
EXPECT="ac1_pins ac1_fn ac2_fn ac3_positive ac3_fn ac4_gap ac4_fn ac5_fn ac5_positive ac5_idem_old ac5_idem_fn ac7_fn"
section ac1_pins ac1_pins
AC1_REDFIRST=1 section ac1_fn ac1_fn "$HEADSHA"
section ac2_fn ac2_fn HEAD
section ac3_positive ac3_positive
section ac3_fn ac3_fn "$HEADSHA"
section ac4_gap ac4_gap
section ac4_fn ac4_fn "$HEADSHA"
section ac5_fn ac5_fn "$HEADSHA"
section ac5_positive ac5_positive
section ac5_idem_old ac5_idem_old
section ac5_idem_fn ac5_idem_fn "$HEADSHA"
section ac7_fn ac7_fn "$PIN_FINAL"
if [ "$DO_SWEEP" = 1 ]; then EXPECT="$EXPECT ac6_sweep"; section ac6_sweep ac6_sweep; fi

if [ "$DO_MUTATE" = 1 ]; then
  echo "== mutations: each check function is run against a broken subject and must report a FAIL line that includes the required text"
  # mexpect NAME REQUIRED CMD... : the function's output must contain a FAIL line that includes the fixed string REQUIRED (not just any FAIL)
  mexpect() {
    local n=$1 req=$2; shift 2
    BADFILE="$TMP/m-$n.fails" "$@" >"$TMP/m-$n.out" 2>&1
    if grep '^  FAIL' "$TMP/m-$n.out" | grep -qF -- "$req"; then ok "mutation '$n' -> check red at '$req'"
    else bad "mutation '$n' did NOT turn its check red at '$req'"; grep -m3 '^  FAIL' "$TMP/m-$n.out" | cut -c1-160; fi
    return 0
  }
  EXPECT="$EXPECT m1 m_widen m3 m4 m5 m6 m7 m8"
  section m1 mexpect "old 048 (c4 on HEAD) vs AC1" "FAIL a1-after-$BASE_SHA -> exit" ac1_fn "$BASE_SHA"
  section m_widen ac1_widen
  section m3 mexpect "old 072/080 (env overrides) vs AC3" "override still present" ac3_fn "$BASE_SHA"
  section m4 mexpect "old 085 (no nested assertion) vs AC4" "a4-broken-$BASE_SHA output lacks 'FAIL nested: Last reviewed substitution applied'" ac4_fn "$BASE_SHA"
  section m5 mexpect "old 048 on the merge vs AC5" "FAIL a5-merge-048-$BASE_SHA -> exit" ac5_fn "$BASE_SHA"
  section m6 mexpect "079 that never reddens vs AC2" "a2-claude -> exit 0 but must be red" ac2_fn STUB
  section m8 mexpect "old 085 on an already-edited tree vs AC5 idempotence" "FAIL a5i-085-$BASE_SHA -> exit 2, expected 0" ac5_idem_fn "$BASE_SHA"
  section m7 mexpect "FINAL = an out-of-scope commit vs AC7" "FAIL out of scope:" ac7_fn "$(git rev-parse "$BASE_SHA^1")"
fi

# ---- final gate: no FAIL line in the output, none in the fail file, every expected section reached its end, and enough ok lines
NF=$(grep -c '^  FAIL' "$ALL" || true); NFF=$(wc -l <"$TMP/fails.txt"); NOK=$(grep -c '^  ok ' "$ALL" || true); MISSING=""
for e in $EXPECT; do grep -qx "  sentinel $e" "$ALL" || MISSING="$MISSING $e"; done
[ -z "$MISSING" ] || { bad "sections that did not run to their end:$MISSING" | tee -a "$ALL"; NF=$((NF + 1)); }
MINOK=60
[ "$NOK" -ge "$MINOK" ] || { bad "only $NOK ok lines, expected at least $MINOK (a section ran short)" | tee -a "$ALL"; NF=$((NF + 1)); }
echo "== 090-verify: ok lines $NOK, FAIL lines $NF, fail-file lines $NFF: $([ "$NF" = 0 ] && [ "$NFF" = 0 ] && echo 'ALL CHECKS PASSED' || echo FAILED)"
[ "$NF" = 0 ] && [ "$NFF" = 0 ]
