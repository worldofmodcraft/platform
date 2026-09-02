# ADR-0050: Build order — walking skeleton plus one vertical slice

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Process
- **Related:** ADR-0001, ADR-0012, ADR-0016, ADR-0054

## Context
We know the shape of the framework; we do not know the insides of WoWee (8 000+ commits) or AzerothCore (15 years). Building everything before one end-to-end test would deliver all integration failures at once. A hobby project also dies when nothing runs for months.

## Decision
**The whole skeleton, one full vertical.**
- Day one: the complete repository structure and every layer/directory exists.
- The **entire API (all three rings) is defined in the IDL from the start**; generators produce bindings, headers and docs for everything; unimplemented functions raise `NotImplemented: <name> — tracked in #N`. The framework's *shape* is complete; depth is filled in.
- **Step 0 — smoke test:** one mod, one record changing one field of an existing spell, compiled to overlay data (ADR-0016) and world-DB delta, loaded by our server, visible in our client, one RPC round-trip, full attributed logging. No gameplay value; proves every layer.
- **Then:** the native plugin loader (deferred out of step 0 to isolate risk; 2–4 evenings).
- **Step 1 — first real roguelike feature:** "on level-up, three upgrade cards are offered": a new record type, a server hook, RPC, a client panel, persistence, observability.
- **Start clean** with the forks; the existing roguelike M0 server remains as reference and fallback, not as the sandbox.

## Estimate (for orientation only; fun matters more than time)
Roughly 20–35 evenings to step 1 at 2–3 evenings/week; step 0 around evening 12–20; hobby estimates miss by 2× more often than not.

## Full sequence
1. Read the existing roguelike guides → write the constitution (`CLAUDE.md`) and the manager guide.
2. Build WoWee (natively on Windows; Vulkan in WSL is unreliable) and connect it to the existing server.
3. Codebase survey of AzerothCore and WoWee by subagents → `docs/survey/*` → design adjustments.
4. Monorepo + IDL + skeleton.
5. Step 0. 6. Plugin loader. 7. Step 1. 8. Breadth, driven by the roguelike.
