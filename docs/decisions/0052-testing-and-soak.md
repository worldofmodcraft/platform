# ADR-0052: Testing — `modcraft test` with a strictly bounded simulated player; playerbots for soak

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Developer experience / Quality
- **Related:** ADR-0028, ADR-0040, ADR-0051
- **Amended by:** ADR-0115 (test tools must not be able to kill the server; measure, do not ask)

## Decision
- `modcraft test` runs Lua test files in `tests/` against a **headless kernel** (real server, no sockets/client) with a **simulated player** built on the server's own Player class. The simulated player can: log in, stand at a position, gain levels, take damage, cast, manage inventory, exchange RPC messages as the client (`client:receive`, `client:send`). It **cannot**: walk, pathfind, think or render. Anything needing that is a play session, not a test. The site runs the same tests; the mod page shows "tests: N run, N green". Client UI is not covered (acknowledged gap until headless rendering exists).
- The pipeline's smoke tests (permissions denied, silent client) are predefined tests in this framework.
- **Soak/load testing** uses **mod-playerbots**: `modcraft soak --bots 50 --hours 6` with the kernel's leak flagging and crash report as output.
- Porting mod-playerbots to `mc:playerbots` as an **unsafe-tier plugin** is an early ring-3 milestone *after* the ABI has settled in step 0→1: it stress-tests the plugin ABI, provides soak testing, and gives solo roguelike players party members.
- Session recording/replay as tests is deferred (fragile against protocol changes).
