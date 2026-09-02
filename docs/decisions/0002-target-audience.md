# ADR-0002: Target audience is self-hosted, single-player and small groups

- **Status:** Accepted
- **Date:** 2026-08-31
- **Area:** Vision
- **Related:** ADR-0010, ADR-0025, ADR-0037

## Context
The scale of the audience determines almost every trade-off: trust in the client, anti-cheat, sandboxing, hosting, and distribution.

## Options considered
- A. General MMO platform including large public servers.
- B. Self-hosted servers used mostly single-player or with a few friends; large servers may use the platform but must solve their own operational and security design.

## Decision
**B.** The default assumptions are: the client is trusted, the server owner is the player, downtime is normal, and uptime is not.

## Consequences
- The client may be trusted (ADR-0010: no sandbox); anti-cheat is out of scope.
- The world must behave like a save file, not like a live service (ADR-0025: world clock).
- Large public servers are explicitly "on their own"; the platform must not prevent them but does not design for them.

## Interacts with
- ADR-0010, ADR-0025, ADR-0037, ADR-0038.
