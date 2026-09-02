# ADR-0029: Everything is configurable; configuration is schema-driven, generated in launcher and in-game

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Configuration
- **Related:** ADR-0028, ADR-0031, ADR-0034, ADR-0045

## Decision
Platform principle: **every default is a setting**, and every setting has a schema (type, bounds, description, default, `scope`, `requires_restart`). The kernel's and launcher's own settings (backup interval, log categories, telemetry, clock mode, instance limits…) are `config.schema` entries exactly like a mod's.

- The launcher **generates settings UI** from schemas (numbers → slider/field, enums → dropdown, bools → toggles), grouped per mod and per world/profile. Changes are written to config files; the kernel picks them up live where warm; `requires_restart` is shown.
- The **same generator renders in-game** (client UI framework, after step 1).
- `scope = "client"` settings are the player's own and always editable; `scope = "server"` settings are the world's rules and require owner/admin permission (ADR-0031), enforced server-side. Single-player users see everything.
- Complex settings may opt out with `ui = "custom"` and supply their own panel.
- **AzerothCore's `worldserver.conf`** is owned by the kernel: a schema is generated from `conf.dist` (type/default/comment per line) and diffed at each upstream merge; a curated "Common" view exposes the ~30 settings that matter for single-player; unreviewed entries are marked `reviewed = false` and shown greyed. Mods can depend on AC settings and the kernel warns on mismatch.
- Telemetry may (opt-in, aggregated) report setting distributions to mod authors.
