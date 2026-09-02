# ADR-0098: Monorepo top-level layout; repository responsibilities in the organisation

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Repo / Architecture
- **Related:** ADR-0049, ADR-0063, ADR-0079

## Decision
The platform monorepo layout is fixed now:
```
platform/
  client/     WoWee fork (subtree)      server/     AzerothCore fork (subtree)
  kernel/     libmodcraft (both sides)  idl/        API definitions (Lua tables)
  kernel/console/  web console assets — served by the kernel's HTTP surface,
                   versioned with the kernel (ADR-0112); NOT part of `site`
  tools/      compiler, validator, CLI  sdk/        generated headers/bindings/templates (the MIT island)
  mods/       mc:* core mods + roguelike (reference mod)
  launcher/   Tauri app                 contracts/  backend API contracts (ADR-0079)
  docs/       decisions, manager, design, survey, tasks
```
The licence boundary (AGPL/MIT) becomes a **directory boundary** (`sdk/`); agents' file-scope declarations get natural roots; subtree prefixes are locked before import.

**Organisation responsibilities:** `platform` = everything that runs at the user's machine *plus all contracts* (the platform owns the definitions of heartbeat, telemetry, artefact fetch, directory queries); `registry` = the truth about mods; `site` = the shell rendering the registry — together with artefact storage, the build pipeline and the phase-3 backend these form the **distribution end of the platform** that launcher and kernel integrate against, not "a website". The backend becomes a fourth repo when born. Same project, different deploy rhythms, all mirror-/forkable separately.

**Survey bench:** WoWee/AC build assumptions about their own location (relative paths, submodules they pull).
