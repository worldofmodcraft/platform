# ADR-0071: Players run a native Windows server + portable database; Docker remains for dev/VPS

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Launcher / Distribution
- **Related:** ADR-0043, ADR-0067

## Decision
The launcher's Play button starts a **native Windows build of the server fork plus a portable MariaDB/MySQL** (bundled, own data directory, no service install) — no Docker/WSL2/hypervisor requirement, no alien error surface. Docker stays the path for VPS/dedicated servers and for the development environment. Two supported server platforms in CI (needed anyway for verified-builds symmetry). We do not promise zero learning: the launcher removes *extraneous* obstacles (hypervisors, realmlists), not the fact that one runs a server.

**Survey bench:** state of AzerothCore's Windows build today; whether WoWee + worldserver + MariaDB coexist acceptably on the reference machine (ADR-0081) — also yields the launcher's "can my PC run this" minimums.
