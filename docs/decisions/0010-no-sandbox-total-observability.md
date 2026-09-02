# ADR-0010: No sandbox; total observability instead

- **Status:** Accepted
- **Date:** 2026-08-31
- **Area:** Security / Observability
- **Related:** ADR-0002, ADR-0012, ADR-0028, ADR-0034

## Context
Community mods and native plugins run in-process on users' machines. Enforcing a real sandbox for C/C++ plugins is infeasible; for Lua it is possible but limits what mods can do.

## Decision
The platform does **not** sandbox mods. Running a mod is the user's responsibility; users should only install mods from developers they trust. In exchange, the platform makes *everything a mod does visible*: every hook, RPC, query, state change and resource allocation goes through the kernel and is measured and logged per mod (ADR-0034). Crashes have no safety net but a detailed post-mortem.

## Consequences
- Instrumentation lives in the API, not in mods; a mod author cannot forget to log.
- "Permissions" exist for **transparency**, not enforcement (ADR-0028), with one asymmetry for mods installed via a server profile.
- Rolling backups (ADR-0045) are the practical safety net compatible with this stance.
