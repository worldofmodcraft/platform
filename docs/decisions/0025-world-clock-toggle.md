# ADR-0025: Per-world clock mode — wall time or world time — plus pause

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Ring 1 / World
- **Related:** ADR-0002, ADR-0044, ADR-0045

## Context
AzerothCore has no clock of its own: it reads OS time everywhere and stores future events as absolute timestamps. After downtime, everything has respawned, buffs expired, mod deadlines ("rent paid until Tuesday") passed — correct for a 24/7 MMO, wrong for a save file.

## Decision
A world setting, chosen at world creation:
- **`clock = "wall"`** — MMO mode; the system clock, as WoW has always worked.
- **`clock = "world"`** — save-file mode; the single function AzerothCore reads time from returns OS time **minus accumulated downtime** (server off or paused). Respawns, buffs, events and any mod using `now()` freeze automatically.

Defaults: local world → `world`; dedicated server → `wall`. Changing `world`→`wall` after the fact is allowed with a loud warning (all timestamps jump at once) and is logged as a world event. The downtime counter is always recorded in both modes. `time.os()` exposes the wall clock explicitly for calendar-bound features.

**Pause** (launcher button / `.pause`): in `world` mode time stops, the world loop halts, players are disconnected with "Server paused by owner" and logins refused; in `wall` mode only the lockout happens. Paused state is the safe moment for reloads and mod changes.

Optional per-world setting: day/night cycle follows world time or wall time.
