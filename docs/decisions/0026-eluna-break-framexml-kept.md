# ADR-0026: Clean break from Eluna; FrameXML addon compatibility kept; overlay-aware legacy API

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Compatibility
- **Related:** ADR-0015, ADR-0016, ADR-0032

## Decision
- **Server-side Eluna/ale scripts:** clean break. The kernel API replaces them; a conversion guide is published.
- **Client-side FrameXML addons** (Questie, Bartender, DBM…): kept as a **legacy addon layer** in the client fork. An "addon-mod" type packages a FrameXML addon so it can be listed on the site, installed with one click and distributed with a server's mod list — licence permitting. Combining an addon with records in one mod is allowed, but the site recommends *depending on* a separately published addon-mod rather than bundling (avoids version drift and licence mixing); the mod's licence field must cover everything in the folder.
- **Overlay × FrameXML:** the legacy API (`GetSpellInfo` etc.) in our client fork reads from the **same merged store** as everything else, so addons see overlay changes for all DBC-native fields. Overlay-only fields are reachable via the bridge (`MODCRAFT_*` API). Addon-mods may declare `modcraft_aware = true`. Lua errors in the addon sandbox are logged with the addon name *and* the overlay change that touched the value.
- Legacy addons are validated more weakly (no `declares`) and marked "legacy addon — API usage not verified".
