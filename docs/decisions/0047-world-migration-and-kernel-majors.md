# ADR-0047: World data across kernel majors; parallel support of majors

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Versioning / Data
- **Related:** ADR-0013, ADR-0025, ADR-0042, ADR-0045

## Decision
- Kernel 1.x remains supported in parallel with 2.x; **servers pin their kernel major**. Partial compatibility layers may exist but never "forever".
- A world carries `kernel_major` and `data_version`. Opening a world in a newer major runs a **world migration** (kernel tables, ID mapping, KV format, downtime counter) with a **mandatory, verified backup first**. Mods' own tables are untouched; mods handle their own `data_version`. A mod not yet updated for the new major is disabled with a clear message (placeholders appear, ADR-0048) rather than corrupting data.
- Migrations are tested in CI against a **corpus of donated, anonymised world exports** (opt-in); every kernel release must migrate the corpus green.
- Migration is an offer with a consequence list, never forced.
- Import of a kernel-1 world export into kernel 2 uses the same migration.
