# ADR-0109: `kernel.http` — sanctioned outbound HTTP for mods

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Ring 2 / Network
- **Related:** ADR-0028, ADR-0034, ADR-0073

## Decision
A simple fetch/post API gated by the `net.outbound` permission, with per-mod rate limits and full logging (URL, size, frequency per mod). Outbound HTTP(S) **only** — never listening sockets (the server's HTTP surface is the kernel's, not mods'). Rationale: without a sanctioned path, unsafe plugins build their own sockets outside all measurement; this channels the need (weather data, Discord webhooks — "the raid boss died!" is a legitimate small-server want, leaderboard sync) through the measurable.
