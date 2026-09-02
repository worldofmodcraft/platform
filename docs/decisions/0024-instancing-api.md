# ADR-0024: Kernel-owned instancing of any map

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Ring 2 / World
- **Related:** ADR-0018, ADR-0025, ADR-0044, ADR-0045

## Decision
`world.instance(map, { owner, persistent, template })` creates a private copy of a map with lifecycle owned by the mod (create/save/freeze/destroy), free of dungeon rules. Persistent instances are part of world data (backup/export include them). Limits (max concurrent, memory per instance) are **settings** with defaults safe for an ordinary PC.

Staging: step 1 supports maps already in AzerothCore's instance system (dungeon shells); step 2 adds open zones (C++ surgery in Map/MapInstanced). Instance state is components on the instance entity, KV-stored.

The API defines from the start **what an instance owns** (its components, KV data, placed objects) so that "export this instance" (portable rooms between servers) can later be a filter over world export rather than a redesign.
