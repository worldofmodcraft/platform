# ADR-0080: Compute on observation — the lazy-evaluation principle

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Architecture / Performance
- **Related:** ADR-0025, ADR-0034

## Decision
Where the result is observably identical, state is computed when observed, never simulated per tick: the crop stores `planted_at` and computes growth at load, instead of a timer ticking for offline players. General rule with three legs: (1) kernel's own systems follow it where possible (survey flags where AC needlessly violates it — respawn handling is a known candidate); (2) the API makes the lazy path the *easy* path (`player.last_seen`, `player.returned` with absence duration, instance-load events); (3) docs and tooling encourage it (persistent mass-timer mods surface via the existing budget/health machinery). The pattern is automatically pause- and clock-mode-correct since `now()` is already the adjusted clock. Hard boundary: this optimises the *unobserved* only — combat, movement and everything players see in real time ticks normally. No mod can pause anything; clock control remains ADR-0025's.
