# ADR-0043: The launcher — a Tauri shell over the CLI; process supervisor; phased scope

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Launcher
- **Related:** ADR-0014, ADR-0029, ADR-0042, ADR-0044, ADR-0045, ADR-0046

## Decision
- **Phase 0 (during the slice):** no launcher. The kernel CLI (`modcraft install|list|validate|dev|test|publish`) does everything; the launcher later wraps it and never implements its own logic.
- **Technology:** Tauri (web UI, Rust core reusing the offline tooling).
- **v1 scope:** point at a WoW installation and extract/validate data with progress; manage mods (dependency resolution, permissions display, load-order drag with locked dependencies); diagnostics panel (category toggles with measured cost, "Share diagnostics", "Show shared data", delete / new id); launch the client against an already running server.
- **Phase 2.5:** install and run the whole server stack (Docker/MySQL/AzerothCore) hidden behind **Play**: start DB → authserver → worldserver in order, supervise, and on crash show the crash report and a one-click "Restart server". Closing the launcher shuts everything down.
- **Worlds:** multiple worlds per install (one database schema set each); **export/import** a world as zip (mysqldump of kernel + character + mod-prefixed tables, mod list with exact versions, config); import resolves the mod list against the registry (archived versions guarantee it can). Phase 2 feature.
- **Protocol URI:** `modcraft://install/<id>@<version>` registered at install; the portal's buttons deep-link into the launcher; without a launcher the button offers to get it.
