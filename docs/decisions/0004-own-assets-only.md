# ADR-0004: Own assets only; never Blizzard data

- **Status:** Accepted
- **Date:** 2026-08-31
- **Area:** Legal / Content
- **Related:** ADR-0005, ADR-0033, ADR-0041, ADR-0046
- **Amended by:** ADR-0120 (the guarantee is content whitelisting, not only magic-byte typing)

## Context
Private servers exist in a legal grey zone. Blizzard has shut down prominent servers. The platform's only defensible position is to never distribute a single byte of Blizzard-owned data and to make that enforceable.

## Options considered
- A. Allow mods to ship modified Blizzard assets (recolours, edited models) as Skyrim mods commonly do.
- B. Mods may only ship their own assets; Blizzard assets may be *referenced by path* (they exist in the user's own extraction) but never *distributed*.

## Decision
**B.** Mods contain only original assets. Model format for mod assets is **glTF/GLB**, never M2/WMO/ADT/BLP/DBC/MPQ. The site scans uploads by magic bytes and rejects Blizzard formats regardless of file extension. Assets that are re-creations or upscales of Blizzard assets are prohibited by content rules (ADR-0046) and removed on report with evidence.

## Consequences
- Mods can reference vanilla assets ("use `World/.../Cottage.wmo`") but cannot ship an edited copy.
- Allowed asset formats are a **whitelist** (glTF/GLB, PNG, OGG; possibly WAV, TTF), not a blacklist.
- The asset overlay mechanism (ADR-0033) lets a mod *replace* a vanilla asset at a path with its own original file.

## Interacts with
- ADR-0005 (game data), ADR-0041 (verified builds pipeline), ADR-0046 (content rules).
