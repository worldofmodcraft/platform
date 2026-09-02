# ADR-0068: The task ledger is files in the repo; GitHub Issues are a future inbox only

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Process
- **Related:** ADR-0054, ADR-0070

## Decision
`docs/tasks/` in the repo is the **only truth** for work items (as the manager doctrine already requires): specs and logs version with the code, agents read them without API calls, a branch carries its own spec and log in the same diff. GitHub Issues are not used until external contributors exist; then Issues become an **inbox** the manager converts to task files (ADR-0070). Dual bookkeeping is rejected as sync-rot. Overview is a generated `docs/tasks/BOARD.md`; any future kanban tool (e.g. Aperant) is an *interface* over these files, never a second truth.
