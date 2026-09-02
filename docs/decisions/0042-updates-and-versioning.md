# ADR-0042: Mod updates, versioning, rollback and server profiles

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Launcher / Registry
- **Related:** ADR-0011, ADR-0028, ADR-0037, ADR-0045

## Decision
- **Discovery:** launcher pulls the registry at start; updates are notified, never applied silently.
- **Policy per mod:** *manual* (default), *auto-patch*, *pinned*. A **global opt-in** for auto-patch across all mods exists, with per-mod exceptions.
- **Semver semantics:** patch may auto-apply for those who opt in; minor is suggested; major is warned about. The pipeline rejects dishonest patches (ADR-0040).
- **Hard stop:** any update that adds permissions requires explicit approval regardless of policy.
- **Dependency plan:** the whole graph is resolved before download; the user approves a *plan* ("update housing 1.2→1.3 implies core:entities 1.1→1.2; garden stays (requires housing <1.3)"), or nothing.
- **Data:** manifests declare `data_version`; an older mod version refuses to start against newer data. **Backup before update** of the mod's tables and KV data is offered (default on for major). Rollback = reinstall old version + restore backup, with the explicit warning that data created after the update is lost. Down-migrations are not pretended.
- **Servers control their profile only:** the server's mod list and exact versions are synced to the client at login into a **separate profile per server**; the user's own setup is never touched. A server can never change anything on the user's machine without approval; the first join shows the full diff with a warning; approval may be remembered per server ("trust this server's mod list"), itself an active choice.
- **Cache:** the user's chosen version plus versions required by approved server profiles; unreferenced versions are pruned.
- Kernel, client fork and server fork are versioned and updated the same way (ADR-0048).
