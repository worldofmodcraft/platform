# ADR-0101: The bundled database engine is part of the platform package

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Distribution / Data
- **Related:** ADR-0045, ADR-0047, ADR-0048, ADR-0071

## Decision
The portable MariaDB version is **pinned per platform package** (ADR-0048), upgraded deliberately as package content; a package upgrade that bumps the DB version runs mandatory backup + verification before start (existing mechanics). One DB instance per installation; worlds are schemas (ADR-0076), so DB jumps are installation-global and treated as such. We deliberately trail MariaDB releases; security fixes justify package patch versions.

**Survey bench:** which MySQL/MariaDB versions AC actually supports/tests; known Windows issues with portable operation (own datadir, no service).
