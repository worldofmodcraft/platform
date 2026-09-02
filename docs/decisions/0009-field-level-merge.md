# ADR-0009: Field-level merge instead of rule-of-one

- **Status:** Accepted
- **Date:** 2026-08-31
- **Area:** Architecture / Mod format
- **Related:** ADR-0008, ADR-0011

## Context
Skyrim's "rule of one" (last plugin to touch a record wins the whole record) is the root of most mod conflicts; the community fixes it after the fact with tools like Bashed Patch.

## Decision
Records merge **per field**. Two mods changing different fields of the same record do not conflict. A conflict exists only when two mods write the *same* field; then the later mod in load order wins and the compiler emits a conflict report listing every such field with both values and both owners.

## Consequences
- The launcher shows field conflicts as the *only* thing load order decides ("hardmode overrides roguelike on `spell:frost_nova.damage`, 12 fields total").
- Provenance is recorded per field and surfaced by the in-game inspector.
