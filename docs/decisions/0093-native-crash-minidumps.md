# ADR-0093: Native crash handling — minidumps and a persistent event ring buffer

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Observability
- **Related:** ADR-0034, ADR-0036, ADR-0048

## Decision
Both forks get crashpad/breakpad-class handlers from the start: a segfault produces a minidump plus the last events. The kernel keeps its recent-events buffer in a **memory-mapped ring buffer that survives process death** — that is how "last 200 events" stays true even for native crashes. The build pipeline archives symbol files per release (platform storage). The launcher presents crashes comprehensibly and offers sharing via the existing diagnostics opt-in, whose consent text gets a dedicated line: minidumps can contain memory contents. Estimated 3–5 evenings of real integration; with two C++ forks, native crashes are a certainty, not a risk.

**Survey bench:** existing crash handling in WoWee (probably none) and AC (some).
