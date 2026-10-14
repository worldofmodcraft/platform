#!/usr/bin/env bash
# Task 051 verification artefact (MANAGER.md section 2c).  Runs ONLY against temporary directories.
#   docs/tasks/051-verify.sh            run every script-verified criterion
#   docs/tasks/051-verify.sh --mutate   additionally break the tool in a temp copy, once per guard,
#                                       and require the matching tests to turn red
# AC14 (first live run with Ludwig) is human and is not covered here.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
TESTS="$REPO/tools/vault/tests"
SCRIPT="$REPO/tools/vault/wom_vault.py"
FAIL=0
say() { printf '%s\n' "$*"; }
red() { say "FAIL: $*"; FAIL=1; }

# ---- AC12: refuse unless the temp root is under the temp dir, not under /mnt/, not under real $HOME.
# String checks come first so that a forbidden location is never even stat'ed.
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

TMP="$(mktemp -d "${TMPDIR:-/tmp}/wom051-XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT
export WOM051_TMP="$TMP"
say "== environment"
say "python: $(python3 -I -c 'import sys;print(sys.version.split()[0])')"
if command -v strace >/dev/null 2>&1; then say "strace: available"; else
  say "strace: not installed; AC3 'no open' is proven with a Python audit hook (tools/vault/tests/audit_run.py), which records every open()/os.open()/scandir/listdir of the interpreter running the tool"; fi
say "temp root: $TMP (under ${TMPDIR:-/tmp}, AC12 guard passed)"

run_tests() { # $1 = script under test; rest = test ids (none = all). Output in $TMP/last.out
  local script="$1"; shift
  WOM_VAULT_SCRIPT="$script" python3 -I -W ignore::ResourceWarning "$TESTS/test_vault.py" -v "$@" >"$TMP/last.out" 2>&1
}

say "== AC12 guard can fail (the guard function refuses these without touching them)"
for bad in "/mnt/x" "$HOME/x" "relative"; do
  if ( guard_tmpdir "$bad" ) >/dev/null; then red "guard accepted '$bad'"; else say "ok: guard refuses '$bad'"; fi
done

say "== AC1-AC9: unit tests against the real tool"
if run_tests "$SCRIPT"; then rc=0; else rc=$?; fi
grep -E '^(test_|Ran |OK|FAILED)|\.\.\. (ok|FAIL|ERROR)' "$TMP/last.out" || true
ran="$(sed -n 's/^Ran \([0-9]*\) tests.*/\1/p' "$TMP/last.out")"
if [ "$rc" -ne 0 ]; then red "unit tests failed"; tail -40 "$TMP/last.out"; fi
if [ -z "$ran" ] || [ "$ran" -lt 30 ]; then red "expected at least 30 tests, ran '${ran:-0}' (a run that finds nothing is a failure)"; fi

say "== AC4: no secret-shaped string is committed (and the search can match)"
SECRET_RX='gh[pousr]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{82}|-----BEGIN [A-Z ]*PRIVATE KEY-----|untrusted comment: minisign encrypted secret key|sk-ant-[A-Za-z0-9_-]{32,}|(AKIA|ASIA)[A-Z0-9]{16}'
planted="$TMP/planted.txt"; printf 'x %s%s y\n' 'gh''p_' 'aB3dE5gH7jK9mN1pQ3sT5vX7zA9cD1fG3hJ5' >"$planted"
if grep -Eq "$SECRET_RX" "$planted"; then say "ok: control search matches a runtime-built secret"; else red "control search found nothing"; fi
nfiles="$(git -C "$REPO" ls-files | wc -l)"
[ "$nfiles" -gt 10 ] || red "git ls-files returned only $nfiles files"
if (cd "$REPO" && git ls-files -z -- . ':!docs/tasks/051-vault-projection.md' | xargs -0 grep -IEl "$SECRET_RX" 2>/dev/null); then red "secret-shaped string committed (files above)"; else say "ok: no secret-shaped string in $nfiles tracked files (the spec file is excluded: it quotes the minisign comment as a pattern definition)"; fi

say "== the real vault path is not committed"
if (cd "$REPO" && git grep -nE '/mnt/[a-z]/' -- tools/vault docs/tools/vault-projection.md docs/manager/COMMANDS.md); then red "a drive-mount path is committed"; else say "ok: none"; fi

say "== AC13: documentation present and cites task 050"
DOC="$REPO/docs/tools/vault-projection.md"
if [ -s "$DOC" ]; then
  for needle in "## Contract" "## Setup" "## Commands" "050-vault-sync-probe" "source_commit" "WOM_VAULT_TEST"; do
    if grep -qF -- "$needle" "$DOC"; then say "ok: doc has '$needle'"; else red "doc lacks '$needle'"; fi
  done
else red "$DOC missing or empty"; fi
grep -qF "wom_vault.py write --ref main" "$REPO/docs/manager/COMMANDS.md" && say "ok: COMMANDS.md lists the projection commands" || red "COMMANDS.md lacks projection commands"
grep -qF "vault" "$REPO/docs/manager/OPERATIONS.md" && say "ok: OPERATIONS.md has a vault entry" || red "OPERATIONS.md lacks the vault entry"

if [ "${1:-}" = "--mutate" ]; then
  say "== AC10: mutation run (each mutant must turn its tests red; the unmutated copy must stay green)"
  mkdir "$TMP/mut"
  cp "$SCRIPT" "$TMP/mut/control.py"
  if [ "$(cmp -s "$SCRIPT" "$TMP/mut/control.py"; echo $?)" != 0 ]; then red "copy differs"; fi
  mapfile -t names < <(python3 -I "$TESTS/mutate.py" list)
  [ "${#names[@]}" -ge 10 ] || red "mutation table has only ${#names[@]} entries"
  for n in "${names[@]}"; do
    tests="$(python3 -I "$TESTS/mutate.py" apply "$n" "$SCRIPT" "$TMP/mut/$n.py")" || { red "mutation $n could not be applied"; continue; }
    if cmp -s "$SCRIPT" "$TMP/mut/$n.py"; then red "mutation $n left the file identical"; continue; fi
    # shellcheck disable=SC2086
    if run_tests "$TMP/mut/control.py" $tests; then say "control green for $n: $tests"; else red "control (unmutated copy) is red for $n"; tail -15 "$TMP/last.out"; fi
    # shellcheck disable=SC2086
    if run_tests "$TMP/mut/$n.py" $tests; then
      red "MUTANT SURVIVED: $n (tests stayed green: $tests)"
    else
      say "ok: mutant '$n' killed -> $(grep -E '^(FAIL|ERROR):' "$TMP/last.out" | sed 's/ (.*//' | sort -u | tr '\n' ' ')"
    fi
  done
fi

if [ "$FAIL" -eq 0 ]; then say "== 051-verify: ALL CHECKS PASSED"; else say "== 051-verify: FAILED"; exit 1; fi
