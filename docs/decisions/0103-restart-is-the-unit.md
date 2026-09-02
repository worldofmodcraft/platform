# ADR-0103: Production mod changes apply at restart; prefer boring, restartable solutions

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Ops / Principles
- **Related:** ADR-0051, ADR-0074, ADR-0112

## Decision
On a running server, mod install/enable/disable/update is **queued and applied at next restart**, with a civilised "restart now" flow: broadcast countdown ("server restarting in 60s for mod changes"), save all, down, up — under a minute given our save requirements. Hot install in production is a possible later optimisation per mod type (pure-Lua mods without records), investigated when someone actually suffers. Dev mode keeps its fast hot-reload world; production keeps predictability.

**General principle (goes into the constitution):** *prefer the boring, restartable, predictable solution; cleverness must be earned by a demonstrated need.* A server restart costs almost nothing; a clever hack costs trust. (Same principle that decided auth ADR-0072, on-demand script porting ADR-0022, and escalation-after-diagnosis in the doctrine.)
