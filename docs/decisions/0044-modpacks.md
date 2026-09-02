# ADR-0044: Modpack is a first-class type; total-conversion single mods remain allowed

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Mod format
- **Related:** ADR-0001, ADR-0030

## Decision
`type = "modpack"`: a manifest consisting mainly of pinned `depends`, a load order and config. Installed with one click; a server can export its whole setup as a modpack. `type = "mod"` may be as large as a total conversion. Whether the roguelike ships as one large mod or a pack of separable mods (permadeath without threat, etc.) is a **roguelike design decision**, taken when the design kit moves under the platform.
