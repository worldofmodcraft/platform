# ADR-0114: API gap review (2026-09-02) — surfaces that must exist

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** API / Ring 2–3
- **Related:** ADR-0020, ADR-0024, ADR-0050, ADR-0080, ADR-0083, ADR-0096, ADR-0103, ADR-0112, ADR-0113

## Context
A walkthrough of the full API surface against the three driver mods (roguelike, housing, arcade) and a server admin's checklist found gaps — three of them blockers for mods we have already committed to. This ADR decides that these surfaces exist; implementation arrives the ring way (pulled by real mods), but all of them enter the IDL's day-one declarations (ADR-0050) so no design forgets them.

## Governing principle
**"If the inspector can show it, a server mod can read it."** The world's observable state is API-readable for server mods: entities, spawns, players, instances, world states, weather, clock, group composition, auction state. Reading is safe in our trust model (no sandbox; server mods are owner-chosen). Explicitly *outside* the read surface: other mods' internal KV data (goes via their public APIs/capability tags — direct reads would freeze every mod's internal format), and the kernel's own bookkeeping except through defined surfaces (integrity, metrics). This is a completeness rule the survey and IDL work test every surface against.

## The gaps

**Blockers (driver mods cannot be built without these):**
1. **Placement/world-picking API (client, ring 3):** cursor→world raycast, ghost preview following the cursor, rotate/snap, confirm→RPC. Housing's single largest client need.
2. **Spatial queries (server, ring 2):** `world.query(shape)` — entities/players within radius/area — plus mod-defined trigger zones (`zone.on_enter`/`on_leave`). Needed per tick by all three driver mods. AC has internal grid search; expose it.
3. **Character lifecycle (ring 2):** programmatic create/reset/rename/delete. The roguelike's core loop ("new run = new/reset character") cannot start without it. *Survey bench:* how tightly character creation is coupled to the login flow in AC.

**Major gaps:**
4. **Group management (ring 2):** create/invite/move/disband — arcade forms teams; `instance:admit` (Q17) presumes it.
5. **Phasing / per-player visibility (ring 2):** 3.3.5a has phasing built in — the cheap sibling of instancing (open-world housing visible only to owner/guests; per-player world changes). Nearly free to expose.
6. **Mail API (ring 2):** send item/gold/letter programmatically. Small, expected, forgotten.
7. **Chat links + tooltip extension for custom content (client fork):** custom items must be linkable in chat and their overlay fields visible in tooltips — same "facade over the merged store" move as ADR-0096. *Survey bench:* where link parsing lives.
8. **World/server lifecycle events (ring 1):** `world.loaded`, `world.saving`, `server.pre_restart` (restart queue ADR-0103 gives mods a civilised wind-down — arcade aborts a match cleanly), `player.logout` with reason.

**Quality/daily-life:**
9. **Mod-Lua standard library (ring 1):** `kernel.json` (kernel.http is half-done without it), deep copy, string utils, class helper, and *the* defined async pattern (one answer, documented early — ADR-0113's gate forces the decision anyway).
10. **Minimap/map markers** explicitly under the overlay ADR (0083) — same need, different surface.
11. **Factions/reputation as a record type** — new factions are DBC-via-overlay; confirm as a supported record type.

**Server-admin surfaces (console additions, ADR-0112):**
12. **Automations:** trigger (schedule / kernel event / manual button) + optional predicates (`players_online == 0`, `memory_pct > 85`) + steps that are **registered commands only** (announce, save, pause, restart queue, backup, mod enable/disable, throttle, teleport, mods' own commands, `wait(t)`). Runs as the creating role; every step logged with automation attribution; GM steps visible to integrity (ADR-0089). Stored as config (schema-validated, world-exported, backup-included, **deliverable by modpacks** — e.g. roguelike ships "daily seed rotation + nightly backup"). Console edits them with the declarative panel schema; `modcraft automation run/list/test` for headless admins. **No embedded code — logic lives in mods, which expose commands automations call.** Event triggers make monitoring actionable (`mod.error_spike` → announce + raise log level).
13. **Access modes:** maintenance mode (admins only — distinct from pause), account whitelist, max players. Partly AC config exposed via ADR-0029 — verify coverage, give console buttons.
14. **Spawn-state surface (ring 2):** `world.spawn(id):status()` → alive/dead/respawn_at, plus `spawn.spawned`/`spawn.killed` events — "is boss X up" as three lines instead of a per-tick grid scan (the lazy path made easiest, ADR-0080). *Survey bench:* AC's respawn bookkeeping and whether it survives the clock hook (ADR-0025) cleanly.

**Deliberately absent (checked, not forgotten):** localisation (ADR-0056/0075), cross-world characters (0088), listening sockets for mods (0109), free HTML in panels (0112).

## Consequences
Points 1–8 and 14 enter the IDL day-one stubs; 9 folds into the ADR-0113 work; 12–13 extend the web console's surface. The read principle becomes a review question for every future ring-2 area: "what does a mod need to *read* here, and is it exposed?"
