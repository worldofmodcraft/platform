# ADR-0092: Safe reposition for characters in locations that no longer exist

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Data safety
- **Related:** ADR-0024, ADR-0048

## Decision
At world load, every character's position is validated; a reference to a map/instance that no longer exists (mod uninstalled, instance destroyed) moves the character to its last known valid base-world position (fallback: hearthstone point), with a log entry and a login message ("you were moved: the area you were in belonged to kelsi:arcade, which is no longer installed"). This makes uninstall *always* safe — required by the "mods are removable" promise — and pairs with the group-teleport primitive's "origin is always restored" guarantee (open questions).

**Survey bench:** where AC stores position and how invalid map ids are handled today (probably badly).
