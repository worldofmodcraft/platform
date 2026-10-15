#!/bin/sh
# PreToolUse hook (task 049, matcher Bash): refuses force pushes, commits on main, reset --hard and rm -rf, and an
# agent's mention of the vault.  In Claude Code ONLY exit 2 blocks; any other status (crash 1, command-not-found 127,
# a signal 137, ...) lets the call through.  So this wrapper never uses exec and never passes a status through
# unchecked: a clean 0 or a clean 2 from the python half is returned, everything else becomes 2 (fail closed).
case "$0" in */*) dir=${0%/*};; *) dir=.;; esac
dir=$(cd "$dir" 2>/dev/null && pwd) || { echo "git-guard: cannot locate the hook directory; blocking (fail closed)" >&2; exit 2; }
[ -f "$dir/git_guard.py" ] || { echo "git-guard: $dir/git_guard.py is missing; blocking (fail closed)" >&2; exit 2; } # CHECK:w-missing
[ -x "$dir/git_guard.py" ] || { echo "git-guard: $dir/git_guard.py is not executable; blocking (fail closed)" >&2; exit 2; } # CHECK:w-nonexec
command -v python3 >/dev/null 2>&1 || { echo "git-guard: python3 not found on PATH; blocking (fail closed)" >&2; exit 2; } # CHECK:w-nopython
python3 -I "$dir/git_guard.py"
rc=$?
case "$rc" in
  0|2) exit "$rc";;
  *) echo "git-guard: guard exited with unexpected status $rc; blocking (fail closed)" >&2; exit 2;; # CHECK:w-passthrough
esac
