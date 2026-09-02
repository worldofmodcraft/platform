# ADR-0079: Contract-first backend

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Architecture / Backend
- **Related:** ADR-0036, ADR-0059, ADR-0078

## Decision
**Every backend feature is a published, versioned contract in the repo before the service exists; the kernel implements its half immediately behind a config flag; the backend implements the other half when phase 3 arrives.** Already practised twice (telemetry summaries built and viewable locally before any endpoint; `page.json` defined before the portal); the server-directory heartbeat is third — kernel can build and log the payload from day one behind `server.public = false`, so "connecting" the backend is a URL in config, never feature work. Contracts live in `docs/api-contracts/` (or an IDL branch): heartbeat, telemetry submission, deletion by installation id, aggregate JSON for the static site, directory queries — semver-versioned. The backend is an implementation of published contracts: AGPL, containerised on the same frozen-toolchain principle, built under the same doctrine, and forkable by anyone (openness reaches the backend too). Ludwig hosts it as a hobby service when phase 3 arrives; expected scale is SITE-V1-sized, not kernel-sized.
