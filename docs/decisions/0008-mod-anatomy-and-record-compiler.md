# ADR-0008: A mod is records + Lua + native plugins; the kernel compiles records

- **Status:** Accepted
- **Date:** 2026-08-31
- **Area:** Architecture / Mod format
- **Related:** ADR-0009, ADR-0011, ADR-0015, ADR-0016, ADR-0017

## Context
WoW content truth is spread across three stores: DBC (read by client and server at start), SQL world database, and C++ code. Skyrim's strength is a single record format (.esp) and a single loader. We need an equivalent that lands changes on both sides consistently and makes mods removable.

## Decision
A mod is a folder containing up to three layers:
1. **Records** — declarative data describing *what exists* (spells, items, upgrades, houses…). Authored in **Lua** (executed in a restricted declaration environment with no I/O and no server API; must return a plain table) or in **JSON**. Both are first-class and validated against per-type **schemas**.
2. **Lua behaviour** — server-side and client-side scripts describing *how things behave*.
3. **Native plugins** — new primitives the kernel lacks (ADR-0012).

The kernel's **compiler** reads all mods in load order, merges records field-by-field (ADR-0009), and emits the runtime representation for both sides (ADR-0016, ADR-0017). Mods *declare* content; they never edit SQL, DBC or client data directly. The merged world is dumped as JSON (`build/world/*.json`) with per-field provenance for tools.

Schemas define each record type and are the single source for validation, generated documentation, generated editor forms and the JSON dump.

## Consequences
- Two mods declaring the same spell merge; removing a mod removes exactly its contribution.
- Record files may compute (loops, helpers) but cannot have side effects.
- The compiler always goes records → internal model → output formats; new output formats are added as targets, never as a second path.

## Interacts with
- ADR-0009 (merge), ADR-0010 (ID ranges), ADR-0016 (overlay), ADR-0017 (world DB delta).
