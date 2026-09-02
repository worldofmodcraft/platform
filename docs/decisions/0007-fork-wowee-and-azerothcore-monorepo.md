# ADR-0007: Fork WoWee (client) and AzerothCore (server); monorepo

- **Status:** Accepted
- **Date:** 2026-08-31
- **Area:** Architecture
- **Related:** ADR-0014, ADR-0027, ADR-0049

## Context
The Blizzard 3.3.5a client is a closed binary. WoWee (github.com/Kelsidavis/WoWee) is an MIT-licensed native C++/Vulkan client supporting 1.12, 2.4.3 and 3.3.5a, tested against AzerothCore. A modding platform where "a mod can change everything" needs source access on both ends.

## Options considered
- A. Blizzard client + runtime injection framework (the SKSE approach, cf. WarcraftXL).
- B. Fork WoWee as the primary client; fork AzerothCore as the server; one monorepo.
- C. Separate repositories per fork and for the kernel.

## Decision
**B**, in a monorepo. The fork point is *now*; upstream WoWee/AzerothCore changes are merged in when useful, and merging may stop entirely if divergence grows. The Blizzard client is supported for debugging only (ADR-0027).

## Consequences
- We own both ends: custom network packets, new client features (glTF loading, render passes), and server core changes are ordinary code.
- We carry the maintenance burden of two forks. Bug fixes we want upstreamed to WoWee are written under MIT first (ADR-0049).
- WoWee's current defects are tracked in `docs/survey/wowee-defects.md` with severity relative to our needs.
- WarcraftXL is documented as a related project taking a different path; it is not needed (ADR-0057).

## Interacts with
- ADR-0014 (kernel language), ADR-0016 (overlay), ADR-0049 (licensing).
