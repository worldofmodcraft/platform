# Task 074: draft ADR — removal policy for published versions (Ludwig's decision 2026-10-17)

- **Mission:** SITE-V1 — **Status:** spec-approved (manager, solo gate, 2026-10-17). The ADR itself takes effect only when
  Ludwig accepts it (MANAGER.md §3.1); merge needs his explicit approval.
- **Repo:** platform. **Agent / model:** doc-writer / per frontmatter. **Budget:** small
- **Branch / worktree:** `task/074-adr-removal-policy` / `~/wt/task-074`, cut from platform `origin/main` (`73710d4`)

## Objective
A new ADR file `docs/decisions/0122-removal-policy.md` (next free number — verify with the index; if taken, use the next)
with status **Proposed**, recording Ludwig's decision of 2026-10-17 ("Option A for all"; mission log section "Removal
policy — brainstorm and Ludwig's decision, 2026-10-17", items 0–5) and its relation to ADR-0041, ADR-0046, ADR-0037,
ADR-0121: what it reconciles (grounds: legal **and** ADR-0046's narrow malware/illegal content; owners never remove;
files stop being served while entry/hash/signature/reason stay; installed copies warned, malware offered disable, never
silent deletion; appeal = new version, removal final; per-version "don't use" mark recorded as a later intention).
Plus: the ADR index (`docs/decisions/README.md` and `INDEX.json`) gains the entry, marked Proposed. No existing ADR is
edited (ADRs are immutable in substance, ADR-0116).

## Context
This file; the mission log section named above; task 073's survey is summarised there; ADR-0041, ADR-0046, ADR-0037,
ADR-0121, ADR-0116 (format and immutability); `docs/decisions/README.md`, `INDEX.json`, one recent ADR as format template.

## Acceptance criteria (document; human-checked by the manager, then Ludwig)
1. Every statement of a prior decision cites the ADR and line; nothing beyond Ludwig's items 0–5 is decided.
2. Status Proposed; index and INDEX.json entries consistent (INDEX.json still parses: `python3 -m json.tool`).
3. Open questions the ADR cannot settle are listed, not decided (e.g. who confirms a malware ground; how "stop serving"
   is done on GitHub Releases).

## File scope
`docs/decisions/0122-removal-policy.md` (new), `docs/decisions/README.md`, `docs/decisions/INDEX.json`, this task file (log).

---
# Task 074 log
- 2026-10-17 manager: written and approved (solo gate).
