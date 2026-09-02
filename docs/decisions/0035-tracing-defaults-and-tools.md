# ADR-0035: Full tracing on by default, per-category toggles with measured cost; debugging tools

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Observability
- **Related:** ADR-0029, ADR-0034
- **Amended by:** ADR-0115 (append-mode log defaults, crash-proof evidence, probe/bisect pattern)

## Decision
- **Default: everything on.** The launcher exposes a master "full traceability" switch and per-category toggles (state changes and hook calls are expensive; lifecycle and compiler are free). Changes apply without restart.
- **Cost is measured, not estimated:** the kernel reports instrumentation time as a share of tick/frame time; the launcher shows "last session: 4.2 % server, 1.1 % client". A rough estimate is shown only before any data exists.
- **Tools:** structured JSON-lines log (one file per session, `mod` field on every line, levels trace…error, per-mod level changeable live via `/mods log <mod> trace`); in-game console with per-mod filters; resource overlay; **inspector** (click anything → what it is, which mod defined it, who modified it, recent events); **trace mode** (`/mods trace 10` records all hooks/events/RPC to a Chrome-trace-format file viewable in Perfetto); **bug-report export** (session log, mod list, config, last crash, last trace, zipped).
