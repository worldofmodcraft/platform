#!/usr/bin/env bash
# Task 059 verification artefact (MANAGER.md section 2c).  Runs ONLY against temporary directories.
#   docs/tasks/059-verify.sh            AC1 on the working tree; AC1, AC2, AC4 in a fresh clone of HEAD (AC5)
#   docs/tasks/059-verify.sh --mutate   additionally run AC3 in a second fresh clone: break the ignore rule,
#                                       then re-add one bytecode file; each mutant must turn its check red
# The clone is made from the committed HEAD only; uncommitted changes in the working tree are not tested.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
FAIL=0
say() { printf '%s\n' "$*"; }
red() { say "FAIL: $*"; FAIL=1; }

# Same temp-root guard as 051/053 (string checks first, so a forbidden location is never stat'ed).
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

case "${1:-}" in
  ""|--mutate) ;;
  *) say "usage: $0 [--mutate]"; exit 2;;
esac

TMP="$(mktemp -d "${TMPDIR:-/tmp}/wom059-XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT
say "== environment"
say "git: $(git --version)"
say "python: $(python3 -I -c 'import sys;print(sys.version.split()[0])')"
say "temp root: $TMP (guard passed)"

# Criteria. Each takes a repository directory, prints its reason on failure, and returns 0 only when it holds.
# Each is called inside `if`, so a failing check never aborts the script early.

# Criterion 1: no tracked bytecode in the index.
c1() {
  local hits
  hits="$(git -C "$1" ls-files | grep -E '(__pycache__/|\.pyc$)' || true)"
  if [ -n "$hits" ]; then
    say "  tracked bytecode:"; printf '%s\n' "$hits" | sed 's/^/    /'
    return 1
  fi
  return 0
}

# Criterion 2: a freshly created x/__pycache__/y.pyc is ignored.
c2() {
  mkdir -p "$1/x/__pycache__"
  : >"$1/x/__pycache__/y.pyc"
  local rc=0
  git -C "$1" check-ignore -q "x/__pycache__/y.pyc" || rc=$?
  rm -rf -- "$1/x"
  if [ "$rc" -ne 0 ]; then say "  x/__pycache__/y.pyc is not ignored (check-ignore rc=$rc)"; return 1; fi
  return 0
}

# Criterion 4: the ADR tool passes its own check without writing bytecode (-B).
c4() {
  if (cd "$1" && python3 -B tools/adr/build_index.py --check) >"$TMP/c4.out" 2>&1; then
    return 0
  fi
  say "  build_index.py --check failed; last lines:"; tail -5 "$TMP/c4.out" | sed 's/^/    /'
  return 1
}

run_checks() { # $1 = directory, $2 = label
  local rc=0 c
  for c in c1 c2 c4; do
    if "$c" "$1"; then say "ok: $c holds in $2"; else say "FAIL: $c in $2"; rc=1; fi
  done
  return "$rc"
}

say "== AC1: the index of the working tree ($REPO)"
if c1 "$REPO"; then say "ok: no tracked bytecode in the working tree"; else red "criterion 1 in the working tree"; fi

say "== AC1, AC2, AC4, AC5: fresh clone of committed HEAD"
SHA="$(git -C "$REPO" rev-parse HEAD)"
CLONE="$TMP/clone"
git clone -q "$REPO" "$CLONE"
git -C "$CLONE" checkout -q --detach "$SHA"
say "clone at $SHA"
if run_checks "$CLONE" "fresh clone"; then say "ok: criteria 1, 2, 4 hold in a fresh clone (criterion 5)"; else red "criteria 1, 2 or 4 fail in a fresh clone"; fi

if [ "${1:-}" = "--mutate" ]; then
  say "== AC3: mutation run (each mutant must turn its check red)"
  MUT="$TMP/mut"
  git clone -q "$REPO" "$MUT"
  git -C "$MUT" checkout -q --detach "$SHA"

  # Mutant A: remove both ignore rules from .gitignore; criterion 2 must go red.
  sed -i -e '/^__pycache__\/$/d' -e '/^\*\.pyc$/d' "$MUT/.gitignore"
  if grep -qE '__pycache__|\.pyc' "$MUT/.gitignore"; then
    red "mutant 'no ignore rule' could not be applied"
  elif c2 "$MUT" >"$TMP/mA.out" 2>&1; then
    red "MUTANT SURVIVED: no ignore rule, criterion 2 still green"
  else
    say "ok: mutant 'no ignore rule' killed -> criterion 2 red"; sed 's/^/    /' "$TMP/mA.out"
  fi
  git -C "$MUT" checkout -q -- .gitignore

  # Mutant B: re-add one bytecode file to the index; criterion 1 must go red.
  mkdir -p "$MUT/tools/adr/__pycache__"
  printf 'mutant' >"$MUT/tools/adr/__pycache__/build_index.cpython-314.pyc"
  git -C "$MUT" add -f tools/adr/__pycache__/build_index.cpython-314.pyc
  if c1 "$MUT" >"$TMP/mB.out" 2>&1; then red "MUTANT SURVIVED: re-added file, criterion 1 still green"
  else say "ok: mutant 're-added file' killed -> criterion 1 red"; sed 's/^/    /' "$TMP/mB.out"; fi
fi

if [ "$FAIL" -eq 0 ]; then say "== 059-verify: ALL CHECKS PASSED"; else say "== 059-verify: FAILED"; exit 1; fi
