# ADR-0033: Asset overlay — mods may replace vanilla assets by path with their own files

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Assets / Content
- **Related:** ADR-0004, ADR-0046

## Decision
A mod may map a vanilla asset path to its own (whitelisted, original) file; the client serves the replacement. Priority follows load order. `validate` checks compatibility (dimension class for textures, animation set for models). The site shows "replaces N vanilla assets". Re-creations/upscales of Blizzard assets are prohibited by content rules (ADR-0046). Server-wide enforcement is already implied by the mod list; a mod marked `client_optional = true` may be disabled locally by a player.
