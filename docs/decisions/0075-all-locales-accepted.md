# ADR-0075: All client locales are accepted

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Data / Launcher
- **Related:** ADR-0005, ADR-0056

## Decision
The data-validation manifest recognises known 3.3.5a locales and validates per locale. Platform rule: records and mods reference data locale-independently (shared file-ID/path forms); the compiler normalises paths (`Data/deDE/` etc.). Platform and mod text stays English (ADR-0056); the game world's strings are whatever the player's data says — no translation system is built. Session headers log the locale (telemetry and bug reports carry it); the test corpus should include at least one non-English extraction. Estimated cost: about an evening plus a survey question.

**Survey bench:** exactly which DBCs and paths are locale-dependent in 3.3.5a; how WoWee handles locale today.
