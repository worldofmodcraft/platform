#!/bin/sh
# PreToolUse hook (task 052): blocks Write/Edit/MultiEdit/NotebookEdit calls aimed into the Obsidian vault.
# Exit 2 blocks the call.  A missing vault_guard.py must block, not pass: Claude Code treats a missing
# hook SCRIPT as a non-blocking error, so this wrapper fails closed for its own sibling.
dir=$(cd "$(dirname "$0")" && pwd) || exit 2
[ -f "$dir/vault_guard.py" ] || { echo "vault-guard: $dir/vault_guard.py is missing; blocking (fail closed)" >&2; exit 2; }
exec python3 -I "$dir/vault_guard.py"
