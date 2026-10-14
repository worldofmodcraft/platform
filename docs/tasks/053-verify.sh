#!/usr/bin/env bash
# Task 053 verification artefact (MANAGER.md section 2c).  Runs ONLY against temporary directories.
#   docs/tasks/053-verify.sh            run every script-verified criterion (AC1-AC4, AC6-AC9) and re-run 051-verify.sh
#   docs/tasks/053-verify.sh --mutate   additionally break the tool in a temp copy, once per guard, and require
#                                       the matching tests to turn red (also runs 051-verify.sh --mutate)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
TESTS="$REPO/tools/vault/tests"
SCRIPT="$REPO/tools/vault/wom_vault.py"
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

TMP="$(mktemp -d "${TMPDIR:-/tmp}/wom053-XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT
export WOM051_TMP="$TMP"   # the 051 fixtures read this name; the directory is a wom053- one
say "== environment"
say "python: $(python3 -I -c 'import sys;print(sys.version.split()[0])')"
say "temp root: $TMP (guard passed)"

run_tests() { # $1 = script under test; rest = test ids (none = all). Output in $TMP/last.out
  local script="$1"; shift
  WOM_VAULT_SCRIPT="$script" python3 -I -W ignore::ResourceWarning "$TESTS/test_vault_053.py" -v "$@" >"$TMP/last.out" 2>&1
}

say "== AC1-AC4, AC7, AC8: tests against the real tool"
if run_tests "$SCRIPT"; then rc=0; else rc=$?; fi
grep -E '^(test_|Ran |OK|FAILED)|\.\.\. (ok|FAIL|ERROR)' "$TMP/last.out" || true
ran="$(sed -n 's/^Ran \([0-9]*\) tests.*/\1/p' "$TMP/last.out")"
if [ "$rc" -ne 0 ]; then red "053 tests failed"; tail -40 "$TMP/last.out"; fi
if [ -z "$ran" ] || [ "$ran" -lt 14 ]; then red "expected at least 14 tests, ran '${ran:-0}' (a run that finds nothing is a failure)"; fi

say "== AC9: a grep that exits 2 turns 051-verify.sh's committed-secret scan red"
mkdir "$TMP/shim"
REALGREP="$(command -v grep)"
cat >"$TMP/shim/grep" <<SHIM
#!/bin/bash
# Fixture: errors (exit 2) for the committed-secret scan only (-IEl); every other call is the real grep.
case " \$* " in *" -IEl "*) echo "grep: simulated I/O error" >&2; exit 2;; esac
exec "$REALGREP" "\$@"
SHIM
chmod +x "$TMP/shim/grep"
if PATH="$TMP/shim:$PATH" "$HERE/051-verify.sh" >"$TMP/ac9.out" 2>&1; then rc=0; else rc=$?; fi
if [ "$rc" -ne 0 ] && grep -qF "FAIL: secret scan: grep failed on" "$TMP/ac9.out"; then
  say "ok: with a failing grep 051-verify.sh exits $rc: $(grep -F 'FAIL: secret scan' "$TMP/ac9.out")"
else red "051-verify.sh stayed green (rc=$rc) with an erroring grep"; tail -5 "$TMP/ac9.out"; fi

say "== AC6: the whole 051 suite still passes"
if "$HERE/051-verify.sh" >"$TMP/v051.out" 2>&1; then say "ok: 051-verify.sh passed"; else red "051-verify.sh failed"; fi
grep -E '^(Ran |OK|FAILED)|^== 051-verify' "$TMP/v051.out" || true

say "== documentation present"
DOC="$REPO/docs/tools/vault-projection.md"
for needle in "Decisions.md" "Journal/YYYY-MM-DD.md" "ADR/" "Europe/Stockholm" "id_conflicts" "regular file" "053-verify.sh"; do
  if grep -qF -- "$needle" "$DOC"; then say "ok: doc has '$needle'"; else red "doc lacks '$needle'"; fi
done

if [ "${1:-}" = "--mutate" ]; then
  say "== AC5/AC7/AC8: mutation run (each mutant must turn its tests red; the unmutated copy must stay green)"
  mkdir "$TMP/mut"
  cp "$SCRIPT" "$TMP/mut/control.py"
  mapfile -t names < <(python3 -I "$TESTS/mutate053.py" list)
  [ "${#names[@]}" -ge 8 ] || red "mutation table has only ${#names[@]} entries"
  for n in "${names[@]}"; do
    tests="$(python3 -I "$TESTS/mutate053.py" apply "$n" "$SCRIPT" "$TMP/mut/$n.py")" || { red "mutation $n could not be applied"; continue; }
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
  say "== 051-verify.sh --mutate"
  if "$HERE/051-verify.sh" --mutate >"$TMP/v051m.out" 2>&1; then say "ok: 051 mutation run passed"; else red "051-verify.sh --mutate failed"; fi
  grep -E "^ok: mutant|MUTANT SURVIVED|^== 051-verify" "$TMP/v051m.out" || true
fi

if [ "$FAIL" -eq 0 ]; then say "== 053-verify: ALL CHECKS PASSED"; else say "== 053-verify: FAILED"; exit 1; fi
