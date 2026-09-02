# ADR-0091: `kernel.rng` — seeded randomness as a ring-1 service

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Ring 1
- **Related:** ADR-0034, ADR-0035

## Decision
Per-mod (and per-run/instance on request) seeded RNG streams; seeds logged in the session header and included in bug-report exports — trace + seed = replayable bug. `validate` warns on `math.random` in server Lua. Bonus: the roguelike gets daily seeds and shareable runs (same seed = same upgrade offers) for free. A wrapper with bookkeeping; near-zero cost, large leverage.
