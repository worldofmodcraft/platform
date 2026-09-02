# ADR-0034: Observability contract — what is logged automatically, what mods must provide

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Observability
- **Related:** ADR-0010, ADR-0035, ADR-0036
- **Amended by:** ADR-0115 (measurement standard: outcome not intent, five rules)

## Decision
**Logged automatically by the kernel (not disable-able per mod):** session header (kernel/build versions, OS, hardware, full mod list with version/hash/tier/signature); lifecycle (load/enable/reload/disable, load-order position, dependency resolution, init time, exact reason a mod did not load); compiler (per-record provenance, conflicts, schema errors with file/line, ID allocation, generated row counts, hot/cold classification); hooks & events (registrations, invocations with time and errors, emit/receive order, who cancelled); Lua (errors with traceback and attribution — all calls are pcall-wrapped, memory/GC per state, coroutines, deprecated API use); plugins (ABI version, symbols, threads, time per callback, allocations, crash attribution with last ~200 events); RPC (mod, channel, direction, size, latency, serialization errors, unknown types, rate); database (per-mod queries, time, rows, slow queries, failures with SQL, migrations); **game-state changes attributed to the causing mod and hook**; entity ownership; client asset loads/failures, draw calls/meshes/textures per mod, UI frames per mod; resources (memory, CPU, timers, objects, handles, threads — snapshot and trend with leak flagging); effective configuration with source per value.

**Required of mods (signing requirement):** all logging via the kernel logger (`print`/`io.write`/`printf` rejected by symbol check); everything used is declared in the manifest; every `warn`/`error` is human-readable (what happened, what to do); records carry `description`; optional debug commands under the mod namespace.

**Resource attribution mechanics:** kernel allocator for stable plugins; own Lua state per mod; per-hook timers with warning budgets; queries tagged with mod id; per-channel byte counts; entity/timer/listener bookkeeping; 10-second metric snapshots with monotonic-growth leak detection.

**Crashes:** no safety net; a crash handler writes stack trace plus the last ~200 attributed events and "last active plugin before crash: X in hook Y".
