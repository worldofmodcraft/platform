# Task 001: Restore completeness of the ADR index

- **Mission:** SITE-V1 (prerequisite; decision-log hygiene) — **Status:** review
- **Agent / model:** manager (direct — docs index, no production code; explicitly ordered by Ludwig)
- **Budget:** small
- **Branch / worktree:** task/001-adr-index-completeness / none (docs-only, no agent delegated)

## Objective
`docs/decisions/README.md` lists every ADR file exactly once, so that the index can be trusted
as the selection surface the session ritual and ADR-0116 layer 2 depend on. Before this task the
index listed 116 of 118 ADRs: ADR-0058 (publishing flow) and ADR-0059 (mod pages) — both
*governing decisions of SITE-V1* — were absent, so a session following the ritual could load the
index and never learn that the two ADRs binding this mission exist.

## Context to load (exhaustive)
- ADRs: 0058, 0059 (the two added), 0116 (indexed selection — why the index must not lie)
- Files: docs/decisions/README.md, docs/manager/MANAGER.md §9

## File scope (declared)
- docs/decisions/README.md  (index section only — no ADR substance touched)
- docs/tasks/001-adr-index-completeness.md

## Acceptance criteria
1. ADR-0058 and ADR-0059 appear in the index under "Registry, site, launcher", in numeric order.
   Demonstrated: `sed -n '/^### Registry, site, launcher/,/^$/p' docs/decisions/README.md`.
2. Every `docs/decisions/NNNN-*.md` appears in the index exactly once; no dangling entries; no
   duplicates. Demonstrated: set comparison of filenames vs indexed numbers — 118 files, 118
   entries, empty missing/dangling/duplicate sets.
3. Every index link target resolves to an existing file. Demonstrated: link-target existence loop.

## Forbidden here
- Editing the substance of any ADR (MANAGER.md §3.1 — the index is not an ADR's substance).
- Adding, renumbering or re-titling ADRs; only index rows for already-existing files.
- Reordering or re-wording existing index rows.

## Deliverables
Index rows for 0058/0059 + this task file. No docs elsewhere describe index contents, so no
other doc moves with this change.

## Questions
- Q: ADR-0039 and ADR-0030 state "namespace = GitHub username"; ADR-0058 §2 binds ownership to
  the numeric account id, but neither older ADR carries the `Amended by:` back-reference the
  decision-log rules require. | options: A) add back-reference metadata lines B) new amending ADR
  C) leave | assumed: none — raised to Ludwig, nothing built on it.
- A (manager): pending Ludwig — out of scope for this task (touching ADR headers needs his
  approval per MANAGER.md §3.1).

---
# Task 001 log
- 2026-09-02 opened after the session-start ritual found the index gap while loading SITE-V1
  governing ADRs; Ludwig ordered the fix directly in-session.
- 2026-09-02 audited index vs files: exactly 0058/0059 missing, no dangling, no duplicates,
  all links resolve.
- 2026-09-02 added the two rows after 0049 in "Registry, site, launcher"; re-ran the audit:
  118/118, each exactly once. All three acceptance criteria demonstrated. Status → review.
