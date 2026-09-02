# ADR-0113: Documentation as a product

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** DevEx / Documentation
- **Related:** ADR-0020, ADR-0051, ADR-0053, ADR-0065, ADR-0097

## Context
Poor API documentation is the most common cause of death for modding platforms (Eluna: an API list without examples or context, learned by reading other people's code and guessing). For a project whose entire purpose is turning WoW into a mod API, documentation is not support material — it is the product's front door.

## Decision
Five layers, with a gate rule that keeps the most important one honest:

1. **Reference — generated, never handwritten, always complete.** Every IDL declaration carries its documentation in the declaration (description, parameters, returns, error cases, since-version, stability ring, related ADR links). Three binding requirements: **(a)** every function has at least one runnable example that CI executes — a broken example breaks the build, so the reference can never lie; **(b)** the generator **refuses** to emit a function without description + example — undocumented API is a build error, not a debt (the only rule that survives time, because it is a gate, not an ambition); **(c)** every page shows its ring/stability and links the relevant ADRs — modders see *why*, not just *what*.
2. **Guides — handwritten, few, maintained as code.** A small curated set: Your first mod; Records & the compiler; Server↔client & RPC; Persistence done right (KV pattern, lazy evaluation ADR-0080); Permissions & graceful denial; Publishing. Every code block is extractable and CI-tested. Owned by the doc-writer agent under "docs move with code": an API-behaviour change must update affected guides in the same branch (review checklist item 5).
3. **Example chain — three levels of real code:** (a) snippets in the reference; (b) **small complete example mods in `mods/examples/`** — one per core pattern (counter achievement, custom command, simple upgrade card) — built and smoke-tested in CI as real mods; (c) the roguelike as the large example (ADR-0051), cross-referenced both ways (reference pages link "used in roguelike: …"; roguelike code comments link back).
4. **Location & discovery:** generated into the `site` (docs.worldofmodcraft.com or /docs), versioned per kernel major (picker in the header; 0.x marked "everything may change"), Pagefind-searchable, every page with an "Edit this page" link to its source (IDL declaration or guide) so community fixes are one PR away. Offline: `modcraft docs` opens the same generated pages locally from the SDK.
5. **The AI layer is the same content in other formats** (llms.txt, type annotations, AGENTS.md template — ADR-0053), all generated from the same IDL source as the reference, so human and AI documentation can never diverge.

**Binding rule across layers:** kernel error messages link into the documentation (`see: docs/records/schema-validation`) — validation and API errors carry a docs reference generated from the same source, making the path from error to understanding one click.

## Consequences
- Layers 1 and 5 are near-free (generator outputs already decided, plus the gate rule). Layers 2–3 are ongoing writing work — the doc-writer agent's purpose — and the gate rule guarantees the reference layer can never rot even when guides lag.
- The documentation site is part of SITE phase evolution; the generator gate lands with the IDL generator in the skeleton phase.
