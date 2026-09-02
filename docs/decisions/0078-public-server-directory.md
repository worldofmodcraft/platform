# ADR-0078: Public server directory (phase 3)

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Site / Backend
- **Related:** ADR-0002, ADR-0042, ADR-0046, ADR-0060, ADR-0079

## Decision
An opt-in server list à la classic multiplayer browsers: `server.public = true` plus name/description in the standard settings schema; the server heartbeats (name, player count, modpack, platform-package version) to a backend endpoint; missing heartbeats drop the listing. Because servers advertise their mod list, the directory can show *what experience* a server runs, and Join enters the existing profile flow (show mod list → approve → fetch → play). Requires the phase-3 backend (same small service as telemetry). The launcher warns plainly that publishing exposes the server address (recommend VPS, not home connections); per ADR-0002 public servers own their operations and security — the directory is discovery, not protection. Names/descriptions fall under the content rules. Ships after the stable-release threshold (ADR-0060) as a launch feature.
