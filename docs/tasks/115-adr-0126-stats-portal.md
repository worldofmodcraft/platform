# Task 115: ADR-0126, the opt-in realm and character stats portal (phase 3)

- **Mission:** none (Ludwig's direct decisions, 2026-11-06; a phase-3 decision recorded now) — **Status:** spec-approved (manager, 2026-11-06, solo gate: documentation only)
- **Agent / model:** manager (an ADR is a record of Ludwig's decisions, not production code) — **Budget:** small
- **Branch:** `session/15`

## Objective
`docs/decisions/0126-realm-and-character-stats-portal.md` records Ludwig's decisions verbatim, amends ADR-0004, ADR-0036 and ADR-0078 by the README's amend protocol (an `Amended by` line on each, no change to their substance), and is listed in `docs/decisions/README.md` and `INDEX.json`.

## Acceptance criteria
1. The ADR quotes Ludwig's three decisions verbatim and states the boundary: in-game data only, nothing about the person behind a character.
2. Amend protocol: the new ADR's `Amends:` lists 0004, 0036, 0078, with one section each; each of them gains exactly one `Amended by` metadata line and nothing else.
3. `python3 -I -B tools/adr/build_index.py --check` exits 0 after `--write`; the ADR test suite passes.
4. Risks the manager raised are recorded as such, with Ludwig's answers, not as open objections.

## Forbidden
Changing the substance of any accepted ADR; building anything; touching the site, registry or design work (task 114 stays parked, its question open).

---
# Task 115 log
- 2026-11-06 manager (session 15): spec written; Ludwig: "Gör dessa ändringar".
