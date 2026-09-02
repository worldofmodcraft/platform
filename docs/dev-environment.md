# Dev environment: how Windows and WSL cooperate

The manager session and all agents run in **WSL Ubuntu** (`~/wom`, Linux filesystem — fast).
The client fork builds and runs on **Windows** (ADR-0067). Three lanes cross the boundary:

1. **Network (Windows→WSL, automatic):** WSL2 forwards localhost ports — the Windows client
   connecting to `localhost:<port>` reaches the worldserver running in WSL with zero config
   (the roguelike project already runs exactly this split).
2. **Process invocation (WSL→Windows):** agents can call `powershell.exe` / `cmd.exe` from
   WSL — triggering `build-client.ps1`, launching the client, reading build output. Pattern:
   the monorepo lives in WSL; client C++ builds run in a **Windows-side working copy**
   (e.g. `D:\wom-client`, synced via git push/pull), never directly across `\\wsl$` (too slow
   and fragile for large builds). *Survey item: pin the exact sync/build flow.*
3. **Filesystem (both ways):** WSL reads Windows via `/mnt/c`, `/mnt/d`; Windows reads WSL via
   `\\wsl$\`. Client crash dumps and logs on the Windows disk are directly readable by the
   debugger agent.

**What agents cannot do:** see or drive the client GUI. Covered by design: the simulated
player (ADR-0052) is Linux-runnable and tests server↔client behaviour at protocol level (most
cases); CI Windows runners verify client builds (ADR-0067); and anything requiring human eyes
falls under the inherited rule (ADR-0115 §10): built-but-unproven work gets an explicit TODO
row, and Ludwig runs the visual playtests from a manager-prepared test list.
