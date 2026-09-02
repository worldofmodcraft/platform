# ADR-0105: Configuration precedence

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Configuration
- **Related:** ADR-0029, ADR-0044

## Decision
`mod defaults < modpack config < server owner's config < player's client-scope config` — later wins, client scope only ever covering client-scope settings. Written down so nobody invents a different order.
