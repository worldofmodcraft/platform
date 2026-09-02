# ADR-0015: Lua 5.4 everywhere; legacy FrameXML addons isolated in a 5.1 sandbox

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Architecture / Scripting
- **Related:** ADR-0008, ADR-0024, ADR-0026

## Context
WoW addon Lua is 5.1 semantics (emulated by WoWee's FrameXML layer); mod-ale uses a newer Lua on the server. Records, server Lua and client Lua in different dialects would be a trap for mod authors and for AI tooling.

## Decision
One dialect — **Lua 5.4** — for records, server behaviour and the kernel's client-side Lua. Legacy FrameXML addons keep running in their own 5.1 sandbox, untouched. A small bridge publishes kernel events into FrameXML as prefixed events (`MODCRAFT_*`).

Each mod gets its **own Lua state** with its own allocator, giving exact per-mod memory accounting and per-mod GC; mods communicate via kernel events/RPC, never shared tables.

## Consequences
- Performance: hot loops belong in the kernel or plugins, not Lua; Lua orchestrates. The roguelike's damage hooks are the test — if Lua cannot keep up, a stat-modifier pipeline becomes a kernel primitive in C.
- Switching VM (e.g. to LuaJIT) later would be a swap behind the same API; kernel examples avoid 5.4-only syntax until performance is measured.
- Generated type annotations (LuaLS/EmmyLua format) serve editors and AI tools (ADR-0053).
