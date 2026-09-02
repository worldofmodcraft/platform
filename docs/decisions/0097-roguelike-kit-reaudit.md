# ADR-0097: The roguelike design kit is re-audited against the platform before step 1

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Process / Roguelike
- **Related:** ADR-0001, ADR-0051

## Decision
Before step 1, a dedicated task walks the roguelike kit (21 locked decisions, v16, 30 files) decision by decision asking: *design choice, or workaround for a wall that no longer exists?* (Overlay, own client, UI framework, achievements service and world overlays removed several old walls — reused icons, DBC field limits, gossip-only UI.) Workarounds are rewritten against platform capabilities; genuine design choices stay untouched. Output: kit **v17**, the first mod specification *under* the platform. Reason: the reference mod teaches every future modder — it must demonstrate the platform's real patterns, not 2025's stopgaps. Reading + decisions, no code; manager + Ludwig work.
