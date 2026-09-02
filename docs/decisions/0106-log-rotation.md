# ADR-0106: Local log rotation

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Observability
- **Related:** ADR-0035
- **Amended by:** ADR-0115 (append + size caps + per-line timestamps as defaults)

## Decision
Default: keep the **10 most recent session logs plus every session containing a crash**; configurable like everything else. Bug-report export unaffected. Metric history for the console: see ADR-0112 (30-day rolling series).
