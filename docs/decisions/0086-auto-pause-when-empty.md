# ADR-0086: Auto-pause when empty (world setting)

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** World / Settings
- **Related:** ADR-0025, ADR-0029

## Decision
`auto_pause_when_empty = true` (default on for local worlds, off otherwise): in world-clock mode, when the last player logs out — or presses a pause button in the client — the server pauses automatically under ADR-0025's existing pause mechanics. A server setting like any other; **mods have no access to pause or clock control** and only ever observe that `now()` did not move. Dinner never goes cold because a boss respawned.
