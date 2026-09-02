# ADR-0108: `day_boundary` and kernel day services

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Ring 1 / World
- **Related:** ADR-0025, ADR-0091

## Decision
World config gets `day_boundary` (default: the server's local midnight); the kernel exposes `time.day_index()` and the `day.changed` event so no mod counts days itself. In world-clock mode, days advance by played time — seven "days" of a login streak are seven days of play if the world freezes between sessions, which is what a solo player expects. Daily seeds (kernel.rng) and daily quests hang off the same service.
