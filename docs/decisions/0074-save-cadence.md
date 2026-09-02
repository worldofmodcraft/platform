# ADR-0074: Save cadence — aggressive and configurable in world mode

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Data safety
- **Related:** ADR-0025, ADR-0029, ADR-0093

## Decision
In world-clock (save-file) mode the default save interval is short (30–60 s, tuned against the reference machine), plus save-always on pause/quit and on kernel events tagged "save now" (level-up, boss kill, house purchase — mods can tag). Crash reports state exactly what was last saved. All of it lives in the settings schema; MMO defaults remain in wall mode. Write-through per system stays a later option if something proves critical. Save cost per tick is visible in the metrics.

**Survey bench:** actual cost of a full player save in AC (ms, queries); whether saves can run incrementally/async — this sets how low the interval can go.
