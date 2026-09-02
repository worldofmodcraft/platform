# ADR-0027: Blizzard client supported for debugging only

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Compatibility
- **Related:** ADR-0007, ADR-0016, ADR-0057

## Decision
`modcraft export-dbc` plus documented manual MPQ packaging allow comparing behaviour against the reference client. Nothing in the launcher, no promise, no compatibility matrix. The server logs "unsupported client build — behaviour undefined" when a Blizzard client connects instead of silently desyncing. The registry does nothing to prevent a community mod that exports MPQs from the overlay; we simply do not build it. Refusing the build outright is rejected because it closes the debugging path.
