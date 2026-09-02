# ADR-0019: The kernel API is client-agnostic

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Architecture
- **Related:** ADR-0007, ADR-0057

## Decision
The kernel API and RPC layer never expose WoWee internal types. "The client" is a backend behind the client ABI. This is hygiene, not a plan to support other clients; a WarcraftXL-style backend for the Blizzard client is *possible* for someone else to write but is not designed for, not built, and not in the compatibility matrix.
