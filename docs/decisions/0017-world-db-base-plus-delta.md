# ADR-0017: World database = pristine base + compiler-owned delta

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Architecture / Data
- **Related:** ADR-0008, ADR-0044, ADR-0045

## Options considered
- A. Rebuild the whole world DB from scratch at every start.
- B. Keep the base DB untouched; the compiler owns its generated rows (tagged with mod id and build hash) and applies only the difference from the previous build. Uninstall = delete rows with that mod's tag.

## Decision
**B**, with A retained as `modcraft rebuild` and as the ground truth:
- Deltas apply in a transaction; interruption leaves the previous state.
- Each build records a hash; at start the kernel checks a checksum over tagged rows and warns on divergence ("world DB differs from last build — rebuild recommended").
- `rebuild` runs automatically on kernel upgrade and world import.
- Hand-editing generated tables is documented as unsupported; they carry a prefix and a schema comment.

## Consequences
- Warm changes take seconds; the dev loop (ADR-0051) depends on this.
- World export/backups only need the delta plus character data (ADR-0045).
