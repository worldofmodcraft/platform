# ADR-0065: The IDL is our own minimal Lua-table format

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Architecture / API
- **Related:** ADR-0008, ADR-0020, ADR-0032, ADR-0066
- **Amended by:** ADR-0115 (int64 boundary type discipline)

## Decision
The API's single source of truth is declared as **Lua data files in the same restricted declaration environment as records**. A generator in the offline tooling emits: C ABI header, Lua bindings, Lua type annotations, documentation (one CI-tested example per function), `llms.txt`, and the `declares` static-analysis data. Rejected: protobuf-style IDLs (generate serialization we don't want, none of the outputs we do); annotated C++ headers as truth (makes C++ the centre — the opposite of the design). Capability tags (ADR-0032) are interface types in this IDL.

**Risk watch:** if the generator cannot emit C header + Lua bindings within its skeleton-phase budget, the humble retreat is header-scraping (option C).
