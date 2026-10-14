#!/bin/sh
# PreToolUse hook (task 052): blocks Write/Edit/MultiEdit/NotebookEdit calls aimed into the Obsidian vault.
# In Claude Code ONLY exit 2 blocks; any other status (crash 1, command-not-found 127, ...) lets the call through.
# So this wrapper never uses exec: it maps every status other than 0 and 2 to 2, and it fails closed when its
# python half or python3 itself is missing.
dir=$(cd "$(dirname "$0")" 2>/dev/null && pwd) || { echo "vault-guard: cannot locate the hook directory; blocking (fail closed)" >&2; exit 2; }
[ -f "$dir/vault_guard.py" ] || { echo "vault-guard: $dir/vault_guard.py is missing; blocking (fail closed)" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "vault-guard: python3 not found on PATH; blocking (fail closed)" >&2; exit 2; } # CHECK:no-python
python3 -I "$dir/vault_guard.py" # CHECK:no-exec
rc=$?
case "$rc" in
  0|2) exit "$rc";;
  *) echo "vault-guard: guard exited with unexpected status $rc; blocking (fail closed)" >&2; exit 2;;
esac
