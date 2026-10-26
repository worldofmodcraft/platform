#!/usr/bin/env bash
# Task 049 verification artefact (MANAGER.md section 2c).  Pipes JSON fixtures into .claude/hooks/git-guard.sh and
# tools/manager/check-log-entry.sh of THIS tree.  It never runs a fixture command: the fixtures are text in JSON.
# Temp repos live under a temp dir; the real ~/.config/wom and the real vault are never read (HOME is a temp dir).
#   docs/tasks/049-verify.sh            AC1-AC7, AC10 file checks
#   docs/tasks/049-verify.sh --mutate   additionally break a scratch copy once per guard and require the named groups red (AC8)
# AC9 (live, with Ludwig) is human and is not covered here.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
FAIL=0
say() { printf '%s\n' "$*"; }
case "${TMPDIR:-/tmp}" in /mnt|/mnt/*) say "refusing to run: TMPDIR is under /mnt/"; exit 3;; /*) ;; *) say "refusing to run: TMPDIR is not absolute"; exit 3;; esac
command -v python3 >/dev/null || { say "python3 not found"; exit 3; }
export PYTHONDONTWRITEBYTECODE=1
say "== environment: tree $REPO, git $(git --version | cut -d' ' -f3), python $(python3 -I -c 'import sys;print(sys.version.split()[0])')"

say "== AC1-AC7: fixtures piped into the hook (one line per check)"
out="$(python3 -B "$HERE/049-fixtures/run_suite.py" --tree "$REPO")"; rc=$?
printf '%s\n' "$out"
[ "$rc" -eq 0 ] || FAIL=1

say "== hygiene and docs (AC10)"
if git -C "$REPO" ls-files -- .claude tools/manager docs/tasks | grep -E '__pycache__|\.pyc$' >/dev/null; then say "FAIL: bytecode is tracked"; FAIL=1; else say "ok: no bytecode is tracked in this task's scope"; fi
[ "$(git -C "$REPO" ls-files -s -- .claude/hooks/git-guard.sh | cut -c1-6)" = 100755 ] && say "ok: git-guard.sh is committed executable" || { say "FAIL: git-guard.sh is not committed with mode 100755"; FAIL=1; }
[ "$(git -C "$REPO" ls-files -s -- tools/manager/check-log-entry.sh | cut -c1-6)" = 100755 ] && say "ok: check-log-entry.sh is committed executable" || { say "FAIL: check-log-entry.sh is not committed with mode 100755"; FAIL=1; }
doc="$REPO/docs/tools/git-guard.md"
if [ -f "$doc" ]; then
  say "ok: docs/tools/git-guard.md exists"
  for rule in force-push reset-hard rm-rf commit-on-main branch-D vault "Known gaps" "Recovery"; do
    grep -qF -- "$rule" "$doc" && say "ok: git-guard.md names '$rule'" || { say "FAIL: git-guard.md does not name '$rule'"; FAIL=1; }
  done
  # every repo path the doc cites in backticks must exist (MANAGER.md 8b.5)
  python3 -I - "$doc" "$REPO" <<'PY' || FAIL=1
import os, re, sys
doc, repo = sys.argv[1:3]
paths = sorted(set(re.findall(r"`((?:docs|tools|\.claude)/[A-Za-z0-9_./-]+)`", open(doc).read())))
bad = [p for p in paths if not os.path.exists(os.path.join(repo, p.rstrip("/")))]
print("%s: git-guard.md cites %d repo paths, %d missing%s" % ("FAIL" if bad else "ok", len(paths), len(bad), (": " + ", ".join(bad)) if bad else ""))
sys.exit(1 if bad or not paths else 0)
PY
else say "FAIL: docs/tools/git-guard.md is missing"; FAIL=1; fi
grep -qF 'git-guard.log' "$REPO/docs/manager/OPERATIONS.md" && grep -qF 'check-log-entry.sh' "$REPO/docs/manager/OPERATIONS.md" \
  && say "ok: OPERATIONS.md has the git-guard.log and check-log-entry.sh sections" || { say "FAIL: OPERATIONS.md lacks the git-guard.log / check-log-entry.sh sections"; FAIL=1; }

if [ "${1:-}" = "--mutate" ]; then
  say "== AC8: mutation run (each mutant must turn exactly its expected groups red; a survivor fails the run)"
  python3 -B "$HERE/049-fixtures/mutate.py" --tree "$REPO" || FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then say "== 049-verify: ALL CHECKS PASSED"; else say "== 049-verify: FAILED"; exit 1; fi
