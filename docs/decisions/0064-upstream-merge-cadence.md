# ADR-0064: Upstream merges are milestone-gated, never mid-phase

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Process
- **Related:** ADR-0055, ADR-0063
- **Amended by:** ADR-0118 (merge recipe, contribute-back, drift radar)

## Decision
Upstream WoWee/AzerothCore is merged **before** major work phases (before the survey, before step 0, then per platform-package release) — never mid-phase. Each merge is its own task with reviewer and full test run; `wowee-defects.md` rows and core-surgeon "merge debt" notes are processed in the same task. The earlier stance stands: the day merging costs more than it yields, we stop — a per-phase choice, not a binding principle.
