# ADR-0011: Load order is computed from dependencies; install order does not exist

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Mod format / Launcher
- **Related:** ADR-0009, ADR-0020, ADR-0031

## Context
Skyrim's load-order chaos came from mods being copied into the game folder, making install order equal load order. Mod Organizer 2 solved it with a virtual file system.

## Decision
- A mod is a folder in `mods/`; the kernel rebuilds the world from these folders at each start. **Installation order has no meaning.**
- Load order is computed in three steps: (1) a dependency graph from `depends`, `extends` and `load_after` is topologically sorted, yielding a partial order; (2) the user's manual ordering fills the remaining freedom (locked mods move with their dependencies; an invalid order cannot be created by dragging); (3) the kernel validates at start — missing dependency, version-bound conflict, or cycle produce clear errors and the launcher offers fixes.
- A mod that requires another cannot be enabled until the dependency is installed, in the correct order; the launcher flags this at install time.
- The site may publish recommended ordering rules derived from telemetry (cf. LOOT).

## Consequences
- The only user-visible effect of load order is field-conflict resolution (ADR-0009).
- `conflicts` are **version-bound** (`["bob:hardmode"] = "<2.0"`) and symmetric.
- Site-level conflict notes (discovered by telemetry, outside any manifest) are read by the launcher alongside manifests (ADR-0038).
