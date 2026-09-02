# ADR-0085: `.wompack` — the defined mod package format

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Distribution / Format
- **Related:** ADR-0030, ADR-0041, ADR-0043

## Decision
A mod-as-one-file format: a zip with fixed structure (manifest first, **deterministic file order so the hash is reproducible** — plain zips are not, which matters for the integrity chain), extension registered by the launcher (double-click = install through the same verification chain), `modcraft pack`/`unpack` in the CLI. Registry artefacts *are* wompacks. The format specification doubles as documentation.
