# ADR-0013: Namespaced IDs with registry-assigned numeric ranges

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Architecture / Registry
- **Related:** ADR-0008, ADR-0030, ADR-0042

## Context
Records use namespaced string IDs (`kelsi:door`). DBC and SQL need global 32-bit integers, and a spell ID can exist only once. Forge allocates per world, which forces per-server client compilation and mapping tables in world exports.

## Options considered
- A. Per-world allocation with persistent mapping (Forge model).
- B. The registry reserves a numeric **range** per mod at publish time; deterministic across all worlds.

## Decision
**B.** Ranges are assigned in blocks (e.g. 10 000) and a mod may request more. A fixed **dev range** (e.g. ≥ 2 000 000 000) is reserved for unpublished mods; `modcraft publish` rewrites dev IDs into the assigned range automatically. When two dev mods collide locally, the kernel reports it and offers a local reassignment (falling back to A's behaviour exactly where needed). The kernel keeps the string↔number mapping in the world database so removed mods leave "unknown record" references, not crashes.

## Consequences
- Client-side compiled data can be cached per mod version, not per server.
- World export needs no ID mapping table.
- Logs from different players are directly comparable.
