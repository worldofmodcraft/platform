# ADR-0088: Characters are bound to their world

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Data / Product
- **Related:** ADR-0043, ADR-0048, ADR-0076

## Decision
A character is part of the save file, like all world state. Cross-world character transfer does not exist as a feature: worlds have different mod lists, and a character full of `kelsi:` items in a world without the mod is placeholder soup. Friend servers already use separate per-server accounts (invite codes). If the need ever materialises, an export function is buildable later on the same world-export mechanics — nothing in the schema forbids it.
