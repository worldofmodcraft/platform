# ADR-0016: Client/server game data uses an overlay format from the start

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Architecture / Data
- **Related:** ADR-0008, ADR-0026, ADR-0027

## Context
DBC files have fixed columns; "a mod can change everything" needs fields DBC does not have. We own both client and server, so neither has to read DBC as the runtime truth.

## Options considered
- A. Compile records to DBC for both sides in steps 0–1; add an overlay later as a ring-3 capability.
- B. Overlay from the start: both client and server build their in-memory data store as **base DBC (user's extraction) + JSON overlay (compiled world)**.

## Decision
**B**, to avoid building a DBC path only to remove it. This requires a core hook in *both* forks in step 0 where the DBC stores are built. The slice grows by an estimated 3–5 evenings.

The compiler keeps its internal model; `modcraft export-dbc` exists as a **tool** (debugging against the Blizzard client, legacy DBC editors), not as the game's data path.

## Consequences
- Schemas mark which fields are DBC-native vs overlay-only, for documentation and for the export tool.
- The legacy FrameXML API must read from the same merged store (ADR-0026).
- The Blizzard client cannot see overlay changes; it is unsupported for play (ADR-0027).
