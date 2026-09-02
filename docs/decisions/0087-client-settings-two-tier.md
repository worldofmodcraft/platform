# ADR-0087: Client settings — personal is global, mod-delivered is per profile

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Client / Profiles
- **Related:** ADR-0029, ADR-0042

## Decision
Two storage tiers in the client: **personal settings** (keybinds, camera, graphics, UI layout, the user's own FrameXML addons) are global with per-profile overrides where wanted; **mod-delivered state** (mod config with client scope, mods' UI state) is per server profile. Your keys are your keys everywhere; server mods never leak between profiles. The launcher shows where a setting lives. This mirrors the config-scope model (ADR-0029) applied to the client side.

**Survey bench:** how WoWee stores settings/addon data today (Config.wtf/WTF heritage or its own scheme).
