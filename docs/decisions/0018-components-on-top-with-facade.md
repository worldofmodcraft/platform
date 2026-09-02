# ADR-0018: Components on top of WoW objects, behind a facade; full ECS designed for, not built

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Architecture / Entities
- **Related:** ADR-0023, ADR-0031

## Context
AzerothCore uses a class hierarchy (`Unit` → `Player`/`Creature`, `GameObject`) with fixed fields baked into C++. Mods need arbitrary persistent data on entities (housing: `owner`, `rotation`). A full ECS rewrite of AzerothCore's object model (and WoWee's, and the protocol) would be years of work.

## Decision
The kernel keeps a **side table**: entity id → mod components. A **facade** hides the boundary: `entity:get("health")` (core field) and `entity:get("kelsi:owner")` (mod component) use the same syntax, inspector and logging. Mods never see where data lives. A future migration to full ECS must not require mod changes.

## Consequences
- Documented limits: core fields have engine behaviour we do not control (setting `health` to 0 kills; sync timing differs from mod fields); core components cannot be removed (an "immortal decorative creature" is a mod field plus a damage hook).
- Discipline rule for us: kernel code never bypasses the facade to touch AzerothCore objects "just this once".
- Placed housing objects, instance state etc. are components, KV-persisted (ADR-0023).
