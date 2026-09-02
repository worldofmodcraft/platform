# ADR-0012: Native plugins via a C ABI in two tiers (stable / unsafe)

- **Status:** Accepted
- **Date:** 2026-08-31
- **Area:** Architecture / Plugins
- **Related:** ADR-0008, ADR-0010, ADR-0014, ADR-0041, ADR-0049

## Context
C++ cannot be hot-loaded like Java; Skyrim mods are data+script only, with SKSE as the escape hatch. We want the widest possible modding power without turning every C++ need into platform work.

## Options considered
- A. Skyrim way: Lua API broad enough that C++ is rarely needed; gaps become platform issues.
- B. Native plugins: kernel exposes a C ABI; mods ship `.dll/.so/.dylib` loaded at start.
- C. Source mods: mods ship C++ patches applied at build time.

## Decision
**B, layered on A.** Plugins add *primitives* (new entity types, aura types, packet types, render passes, UI widgets, record field types, compiler outputs); records and Lua then use them. Two tiers:
- **stable** — uses only the versioned, generated C ABI; the platform promises backward compatibility.
- **unsafe** — also includes AzerothCore/WoWee internal headers; may break on any core refactor; must be AGPL-compatible (ADR-0049).

The tier is **determined by the build** (which headers are included), never declared by the mod. Plugins may be server-side, client-side, or both; the user never sees the distinction. Stable-tier plugins must allocate via the kernel allocator (`k_alloc`/`k_free`); direct `malloc`/`new` imports are rejected by symbol check so memory is attributable per mod.

## Consequences
- C is rejected.
- The C header is generated from the IDL (ADR-0020), never hand-written.
- A plugin template repository with CI for three OSes lowers the entry barrier (ADR-0052).
- Plugins participate in the same load order and dependency graph as records.
