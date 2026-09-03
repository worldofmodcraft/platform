# Task 020: Operational notes that survive a context handover

- **Mission:** SITE-V1 (cross-cutting) — **Status:** done (2026-09-03)
- **Agent / model:** manager (direct — doctrine-adjacent documentation, approved by Ludwig)
- **Budget:** small · **Branch:** task/020-operations-notes

## Objective
`docs/manager/OPERATIONS.md` holds the facts this project learned by getting them wrong, so a
compaction or a fresh session does not pay for them twice.

## Acceptance criteria
1. Records repo/worktree layout, identities and key id, and the PR-under-protection workflow.
2. Records the tool interfaces that have actually caused errors — above all that `scan_assets.py`
   takes a directory and that exit 2 is a usage error, which once produced a false verification.
3. Records the four mistake patterns already paid for, as patterns rather than anecdotes.
4. Contains no secrets. Demonstrated: the private key is referenced by location only.

## Log
- 2026-09-03 written and merged by PR. Ludwig approved option A after asking what happens when the
  context window fills.
