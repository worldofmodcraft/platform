# ADR-0005: Game data is obtained by the user; the platform only validates it

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Legal / Launcher
- **Related:** ADR-0004

## Context
Every user needs a legally obtained WoW 3.3.5a client to extract base game data. Blizzard no longer sells it. The platform cannot host it.

## Decision
The platform takes **no responsibility for locating game data**. The launcher validates a user-supplied extraction against a published manifest of expected files and hashes ("this is a valid 3.3.5a extraction") and reports what is missing or wrong. It does not link to downloads.

## Consequences
- Launcher contains a data-validation step with clear error reporting.
- Documentation states that a genuine WoW licence plus Blizzard's own legacy installers is the clean path, without hosting or linking anything.
