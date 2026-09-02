# ADR-0054: Documentation first; codebase survey before code; manager/subagent model

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Process
- **Related:** ADR-0006, ADR-0050, ADR-0056

## Decision
- **Documentation before code.** The constitution (`CLAUDE.md`/`AGENTS.md`), this decision log, design documents, roadmap, glossary and open questions exist before the first line of platform code. The existing roguelike guides (CLAUDE.md with 14 working rules, handbook) are read first and built upon.
- **Rules are checkable**, not aspirational ("`print` is forbidden and rejected by validate", not "log carefully"). The constitution contains an explicit **forbidden-shortcuts list** (implementing directly against AzerothCore instead of via the kernel; "fixing" a test by changing it; `TODO` instead of an error; code changed without docs; silent stubs).
- **Codebase survey before code:** subagents each survey a subsystem of AzerothCore (object model, DBC loading, script hooks/modules, packet handling, world-DB loading, allocation) and WoWee (render loop, per-expansion network parsers, FrameXML/UI, asset pipeline, editor, build system) and write `docs/survey/azerothcore.md`, `wowee.md`, `integration-points.md`, `risks.md`, `wowee-defects.md`, and a "related projects" section covering WarcraftXL. Findings adjust the design before the skeleton.
- **Manager model** (in Claude Code): the manager (strongest available model) writes **no production code**; it reads the guides, decomposes work, writes task specs with acceptance criteria, chooses the model per task (cheapest that can do it: mechanical → smallest; clear-spec code → mid; core surgery in AzerothCore/WoWee → strongest), and reviews results against the guides before merge. Every task returns code, tests, updated docs and a log line; incomplete tasks are rejected. Exact configuration is verified against current Claude Code documentation when the manager guide is written.
- Every document carries "last reviewed" and "owner".
