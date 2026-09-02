# ADR-0111: Per-mod backup restore (advanced tool)

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Data safety
- **Related:** ADR-0045, ADR-0112

## Decision
Backups are already structured per prefix/KV scope, so `modcraft restore --mod kelsi:housing --from <backup>` is mostly a filter. It is flagged clearly ("may create inconsistency if mods share data via events/tags"), logged as a world event, and exposed in the web console's operations tab. Whole-world restore remains the blunt, always-safe path.
