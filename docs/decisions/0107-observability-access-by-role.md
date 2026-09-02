# ADR-0107: Observability access on multiplayer servers is layered by role

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Observability / Privacy
- **Related:** ADR-0031, ADR-0034, ADR-0112

## Decision
On your own world: everything is yours. As a player on someone's server: you see your own client's data plus what the inspector shows about things visible in the world (record provenance — "defined by kelsi:housing" — is harmless and pedagogical); server logs, per-mod resource statistics and other players' state changes require an admin role. The owner can open more (configurable like everything). Rationale: transparency about the *system* must not become surveillance of *people* — logs contain other players' behaviour. Default protects fellow players; the owner decides the rest. Console tabs simply render only what the token's role may see.
