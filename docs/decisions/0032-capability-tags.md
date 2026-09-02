# ADR-0032: Capability tags for inter-mod discovery

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Mod format / API
- **Related:** ADR-0011, ADR-0020

## Decision
A mod may `provides = { "currency" }` and another `wants = { "currency" }`. A tag is a **contract** — an interface type in the IDL with defined functions — so `validate` can verify a provider implements it. The kernel matches at load; absent a provider, the wanting mod falls back (e.g. to gold). Two providers → user picks in the launcher, else load order. The kernel ships a small canonical list (`currency`, `placeable`, `xp_source`, `quest_objective`, …); the community registers new tags via the site.
