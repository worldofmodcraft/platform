# ADR-0083: World-anchored overlay rendering (ring 3)

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Ring 3 / Client
- **Related:** ADR-0016, ADR-0020, ADR-0029

## Decision
A kernel primitive for client-rendered elements anchored in the world: lines, areas, text, icons at positions — sent via RPC, drawn by our client in a dedicated pass. Server is truth about *where*; client about *how it looks*. Needed immediately by all three driver mods (housing plot borders, arcade zones/countdowns, roguelike danger areas) and impossible without owning the client — one of the features that justifies the WoWee fork. Guardrails: per-mod client-side toggle (player can mute a mod's overlays; client-scope config) and budgets in the observability layer.

**Survey bench:** WoWee's render architecture — how foreign is an extra world-anchored 2D/3D pass?
