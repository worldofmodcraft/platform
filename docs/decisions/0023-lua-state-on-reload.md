# ADR-0023: Lua state on reload — "in the KV store or gone"

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Scripting / Persistence
- **Related:** ADR-0015, ADR-0051
- **Amended by:** ADR-0115 (kernel-enforced restore-before-save write barrier)

## Decision
Reloading a mod recreates its Lua state; anything not in the kernel **state/KV API** is lost. The kernel makes the KV store feel like a table (`mod.state.plots = {...}` via write-through metatables), memory-caches it with write-behind, and in dev mode warns when a reload discards non-trivial globals ("3 global tables with data were discarded — move to mod.state?"). `validate` flags large globals as probable state. The same rule applies to native plugins (`on_reload` must rebuild from KV).

## Consequences
- Reload is always safe and fast; dev mode may reload on every file save.
- Crashed mods can be restarted by recreating their Lua state.
