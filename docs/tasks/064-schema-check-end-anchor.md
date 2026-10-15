# Task 064: `schema_check.py` matches `pattern` with ECMA-262 end-of-input semantics

- **Mission:** SITE-V1 (D1/D2 verification integrity) — **Status:** draft (booked 2026-10-15, session 9)
- **Repo:** registry. **Agent / model:** qa-engineer / sonnet (a test-validator change is its own reviewed task, MANAGER.md §3.5)
- **Budget:** small
- **Branch / worktree:** `task/064-schema-check-end-anchor` / `~/wt/registry-task-064`

## Objective
`tests/contracts/schema_check.py` stops accepting strings whose `pattern` match relies on Python's `$` matching before
a final `"\n"`. Found by task 007a's independent review (finding F1, 2026-10-15): the validator calls `re.search`, so
`"a"*40 + "\n"` satisfies `^[0-9a-f]{40}$`, while every ECMA-262 JSON Schema validator (and the site's Ajv) rejects it.
Task 007a closes the hole inside its own checkers; this task fixes the shared root, which the 006 and 057 contract
suites also rely on.

## Acceptance criteria (to be completed at the spec gate)
1. Red first: a fixture per affected contract pattern with a trailing `"\n"`, shown accepted by the current validator.
2. Fixed validator rejects them; unanchored patterns keep search semantics; all existing contract suites stay green.
3. Agreement with Ajv on the new fixtures (reuse 057's Ajv comparison, V1).
4. `docs/tasks/064-verify.sh` with a mutation restoring `re.search` semantics.

## Dependencies
After 007a merges (007a's own guard can then be checked against the fixed validator; neither removes the other).
