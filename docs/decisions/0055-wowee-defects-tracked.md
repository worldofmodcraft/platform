# ADR-0055: WoWee polish is done as needed and tracked; upstream relationship maintained

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Process / Client
- **Related:** ADR-0007, ADR-0049, ADR-0054

## Decision
We fix WoWee defects that block *us*, not everything. Each defect is tracked in `docs/survey/wowee-defects.md` with reproduction, severity for our use (blocks slice / disturbs / cosmetic) and status (reported upstream? fixed in fork? waiting). A fix is not merged without updating its row. Upstream reporting is maintained as our goodwill channel to the WoWee project.
