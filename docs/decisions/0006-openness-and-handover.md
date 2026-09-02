# ADR-0006: Openness is the defining trait; designed for handover

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Governance
- **Related:** ADR-0040, ADR-0047, ADR-0056

## Context
The project is run by one person as a hobby. The bus factor is 1. The owner intends to lead "until I no longer want to", after which the community should be able to take over.

## Decision
- All platform code, infrastructure (registry, build pipeline, site generator, launcher), and decisions live in public repositories under the organisation.
- The **only secret** is the signing key; it has a written rotation procedure and a `key_id` in the signature format so rotation never breaks old installs.
- All source for published mods is open (ADR-0040).
- The platform's own infrastructure is treated like a mod: documented, reproducible, forkable.
- A written "if the project dies" plan states how a successor forks the platform.

## Consequences
- No decisions live only in chat or in someone's head; this decision log exists for that reason.
- Everything user-facing and everything in this repository is in **English** (ADR-0056).
