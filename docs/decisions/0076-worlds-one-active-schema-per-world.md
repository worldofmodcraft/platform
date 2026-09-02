# ADR-0076: Worlds — one active at a time; per-world schemas from day one; the process is the world

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Architecture / Launcher
- **Related:** ADR-0024, ADR-0025, ADR-0043, ADR-0045

## Decision
A "world" is a separate save file: own database schema prefix and data directory (a naming convention, nothing more — established from day one), opened by one worldserver process. **One world = one process**; the launcher starts the world you pick and stops the previous one. Launcher v1 shows a single world; "New world"/world picker is later UI needing no migration. Multi-tenant (several worlds in one process via realm mechanics) is buried: it buys nothing for single-player and costs isolation. Clock, pause, crash, backup and export map one-to-one onto the process/schema boundary. Instances (ADR-0024) are rooms *inside* a world and are unaffected. Characters are part of the world (ADR-0088).

**Survey bench:** what in AC assumes one realm per DB set; two processes sharing one MySQL instance with different schemas (expect yes; verify).
