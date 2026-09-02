# ADR-0020: Kernel API in three rings; one IDL as single source of truth

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Architecture / API
- **Related:** ADR-0012, ADR-0014, ADR-0015, ADR-0053
- **Amended by:** ADR-0115 (guarded DB layer; namespaced loader; kernel-owned event semantics)

## Decision
The API is organised in three rings:
- **Ring 1 — Foundation:** mod runtime & lifecycle, capability detection (`kernel.has(...)`), config, records & compiler, events (emit/on/priority/cancel/filters/wildcards), scheduling (timers, tick with budget, coroutines, job system), persistence (per-mod KV in world/account/character scope; migrated tables; transactions), RPC (channels, chunking, versioned messages, server-side validation hook), logging & observability, commands.
- **Ring 2 — Game surface (server & client):** players, entities, spells/auras, items, quests, world & **instancing**, combat & stats, economy, chat, loot & spawns, movement; client UI framework, input, camera, world read access, audio, assets.
- **Ring 3 — Extension (mostly plugins):** custom components & entity types, custom spell effects/aura types, custom record field types & compiler outputs, custom packets, render passes & materials, UI widget types, AI behaviours, objective types, editor extensions.

Stability: Ring 1 is locked as stable early; Ring 2 per area once a real mod has exercised it; Ring 3 is experimental until at least two independent mods use a primitive.

All of it is defined in **one IDL**, which generates: Lua bindings, Lua type annotations, the C ABI header, documentation (with one runnable, CI-tested example per function), `llms.txt`, and the static analysis used by `validate` to check `declares`.

Every call in rings 2 and 3 passes through the same instrumentation (ADR-0034).
