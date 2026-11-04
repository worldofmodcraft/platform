#!/usr/bin/env bash
# Task 108 verification artefact (MANAGER.md section 2c).  Runs ONLY against temporary directories.
#   docs/tasks/108-verify.sh            run every script-verified criterion (AC1) and re-run the 051, 053, 061 and 052 verifiers
#   docs/tasks/108-verify.sh --mutate   additionally break the tool in a temp copy, once per guard, and require
#                                       the matching tests to turn red (also runs 051, 053 and 061 --mutate)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
TESTS="$REPO/tools/vault/tests"
SCRIPT="$REPO/tools/vault/wom_vault.py"
BASE=001418f7f9d7c2eb152581202e965ccbc23c5e7e   # main before task 108
FAIL=0
say() { printf '%s\n' "$*"; }
red() { say "FAIL: $*"; FAIL=1; }

# Same temp-root guard as 051 (string checks first, so a forbidden location is never stat'ed).
guard_tmpdir() {
  local d="$1" home_raw="${HOME:-/nonexistent-home}"
  case "$d" in /*) ;; *) say "refusing to run: TMPDIR '$d' is not absolute"; return 1;; esac
  case "$d" in /mnt|/mnt/*) say "refusing to run: TMPDIR '$d' is under /mnt/"; return 1;; esac
  case "$d/" in "$home_raw"/*) say "refusing to run: TMPDIR '$d' is under HOME"; return 1;; esac
  local real; real="$(realpath -m -- "$d")"
  case "$real" in /mnt|/mnt/*) say "refusing to run: TMPDIR resolves under /mnt/"; return 1;; esac
  local home_real; home_real="$(realpath -m -- "$home_raw")"
  case "$real/" in "$home_real"/*) say "refusing to run: TMPDIR resolves under the real HOME"; return 1;; esac
  return 0
}
guard_tmpdir "${TMPDIR:-/tmp}" || exit 3

TMP="$(mktemp -d "${TMPDIR:-/tmp}/wom108-XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT
export WOM051_TMP="$TMP"   # the 051 fixtures read this name; the directory is a wom108- one
say "== environment"
say "python: $(python3 -I -B -c 'import sys;print(sys.version.split()[0])')"
say "temp root: $TMP (guard passed)"

run_tests() { # $1 = script under test; rest = test ids (none = all). Output in $TMP/last.out
  local script="$1"; shift
  WOM_VAULT_SCRIPT="$script" python3 -I -B -W ignore::ResourceWarning "$TESTS/test_vault_108.py" -v "$@" >"$TMP/last.out" 2>&1
}

say "== AC1: tests against the real tool"
if run_tests "$SCRIPT"; then rc=0; else rc=$?; fi
grep -E '^(test_|Ran |OK|FAILED)|\.\.\. (ok|FAIL|ERROR)' "$TMP/last.out" || true
ran="$(sed -n 's/^Ran \([0-9]*\) tests.*/\1/p' "$TMP/last.out")"
if [ "$rc" -ne 0 ]; then red "108 tests failed"; tail -40 "$TMP/last.out"; fi
if [ -z "$ran" ] || [ "$ran" -lt 28 ]; then red "expected at least 28 tests, ran '${ran:-0}' (a run that finds nothing is a failure)"; fi

# 053- and 061-verify.sh run Python with -I and no -B, so they write bytecode next to the tests they import (book: follow-up
# for those two scripts).  The nested verifiers therefore run from a throw-away copy of the tree, never from this one.
cp -a "$REPO" "$TMP/copy"
CP="$TMP/copy/docs/tasks"
say "== AC2: 051, 053, 061 and 052 verifiers still pass"
for v in 051 053 061 052; do
  if "$CP/$v-verify.sh" >"$TMP/v$v.out" 2>&1; then say "ok: $v-verify.sh passed"; else red "$v-verify.sh failed"; tail -15 "$TMP/v$v.out"; fi
  grep -E '^(Ran |OK|FAILED)|^== 0[0-9]+-verify' "$TMP/v$v.out" || true
done

say "== AC2 red-first: the tool before task 108 (commit $BASE) writes no design note, so the new tests fail on it"
git -C "$REPO" cat-file -e "$BASE^{commit}" || red "base commit $BASE not found"
mkdir "$TMP/old"
git -C "$REPO" show "$BASE:tools/vault/wom_vault.py" >"$TMP/old/wom_vault.py"
if run_tests "$TMP/old/wom_vault.py"; then red "new tests are GREEN on the pre-108 tool (they test nothing)"; else
  say "ok: new tests red on the old tool -> $(grep -cE '^(FAIL|ERROR):' "$TMP/last.out") failing"; fi

say "== no bytecode tracked in this task's scope (tools/vault)"
if git -C "$REPO" ls-files -- tools/vault docs/tasks/108-verify.sh | grep -E '__pycache__|\.pyc$' >/dev/null; then red "bytecode is tracked"; else say "ok: no bytecode tracked"; fi

say "== documentation present"
DOC="$REPO/docs/tools/vault-projection.md"
for needle in "Design docs (task 108)" "docs/design" "108-verify.sh" "<stem>.md"; do
  if grep -qF -- "$needle" "$DOC"; then say "ok: doc has '$needle'"; else red "doc lacks '$needle'"; fi
done

if [ "${1:-}" = "--mutate" ]; then
  say "== AC2: mutation run (each mutant must turn its tests red; the unmutated copy must stay green)"
  mkdir "$TMP/mut"
  cp "$SCRIPT" "$TMP/mut/control.py"
  mapfile -t names < <(python3 -I -B "$TESTS/mutate108.py" list)
  [ "${#names[@]}" -ge 10 ] || red "mutation table has only ${#names[@]} entries"
  for n in "${names[@]}"; do
    tests="$(python3 -I -B "$TESTS/mutate108.py" apply "$n" "$SCRIPT" "$TMP/mut/$n.py")" || { red "mutation $n could not be applied"; continue; }
    if cmp -s "$SCRIPT" "$TMP/mut/$n.py"; then red "mutation $n left the file identical"; continue; fi
    # shellcheck disable=SC2086
    if run_tests "$TMP/mut/control.py" $tests; then say "control green for $n"; else red "control (unmutated copy) is red for $n"; tail -15 "$TMP/last.out"; fi
    # shellcheck disable=SC2086
    if run_tests "$TMP/mut/$n.py" $tests; then
      red "MUTANT SURVIVED: $n (tests stayed green: $tests)"
    else
      say "ok: mutant '$n' killed -> $(grep -E '^(FAIL|ERROR):' "$TMP/last.out" | sed 's/ (.*//' | sort -u | tr '\n' ' ')"
    fi
  done
  for v in 051 053 061; do
    say "== $v-verify.sh --mutate"
    if "$CP/$v-verify.sh" --mutate >"$TMP/v${v}m.out" 2>&1; then say "ok: $v mutation run passed"; else red "$v-verify.sh --mutate failed"; fi
    grep -E "^ok: mutant|MUTANT SURVIVED|^== 0[0-9]+-verify" "$TMP/v${v}m.out" || true
  done
fi

say "== hygiene: this run left no bytecode in the tree under test (049-verify.sh fails on stray .pyc)"
stray="$(find "$REPO" -path "$REPO/.git" -prune -o \( -name __pycache__ -o -name '*.pyc' \) -print)"
if [ -n "$stray" ]; then red "bytecode left in the tree: $(printf '%s' "$stray" | tr '\n' ' ')"; else say "ok: no __pycache__ or .pyc under $REPO"; fi

if [ "$FAIL" -eq 0 ]; then say "== 108-verify: ALL CHECKS PASSED"; else say "== 108-verify: FAILED"; exit 1; fi
