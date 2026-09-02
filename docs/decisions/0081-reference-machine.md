# ADR-0081: The reference machine is Ludwig's PC

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Performance / Process
- **Related:** ADR-0034, ADR-0071, ADR-0074

## Decision
All performance defaults (save interval, instance caps, tracing-cost warnings), the launcher's "can my PC run this" minimums, and CI soak thresholds (resource-limited containers approximating it) are calibrated against one named machine: **Ludwig's PC** — the only reference actually owned and measurable, and conveniently the machine development happens on, so problems hit the developer first. Specs to be recorded in `docs/reference-machine.md` (CPU, RAM, GPU, disk, Windows version; whether the server is measured in WSL or native). The reference changes by decision, never by silently buying a new computer; if telemetry later shows weaker player machines, it is lowered deliberately. Individual installs are still measured live — the reference anchors defaults, requirements and regression alarms, nothing else.
