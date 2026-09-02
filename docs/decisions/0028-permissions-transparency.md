# ADR-0028: Manifest permissions — declared, displayed, not negotiated; server-profile asymmetry

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Mod format / Trust
- **Related:** ADR-0010, ADR-0031, ADR-0044

## Decision
Manifests declare `permissions` from a fixed list: `fs.read_outside`, `fs.write_outside`, `net.outbound`, `process.spawn`, `db.raw_sql`, `threads`, `client.input_hook`, `client.clipboard`, `client.screen`, and `native.unsafe` (set by the build). Own folder, own prefixed tables, own RPC channels and the kernel API are implicit. Each permission has a fixed, plain risk text shown at install; the site shows them as icons and makes them searchable. Known dangerous combinations (e.g. `net.outbound` + `client.input_hook` = keylogger signature) are named in the warning.

Declared = available and logged; undeclared = absent from the mod's Lua environment and rejected by plugin symbol check. This is transparency, not a sandbox (unsafe plugins can bypass it).

**Asymmetry:** mods installed via a **server profile** (approved as a batch when joining someone's server) get the outside-the-game permissions (`fs.*_outside`, `net.outbound`, `process.spawn`, `client.input_hook`, `client.clipboard`, `client.screen`) **off by default**; the user enables them per mod in the profile. Mods installed directly (an informed, per-mod choice) get what they declared.

**Denial is a return value, never an exception**; mods must degrade gracefully. The site's smoke test runs each mod twice — permissions granted and all denied — and rejects mods that crash in the second run. Server mods must tolerate a silent or garbage client (validated the same way). The denial log line names the permission, the mod, the profile and where to enable it; the launcher aggregates these in a per-profile "connection health" view.
