# Task 005: Reserved-namespace ADR and the missing amend back-references

- **Mission:** SITE-V1 — **Status:** review (awaiting Ludwig's approval; MANAGER.md §7 — touches docs/decisions/)
- **Agent / model:** manager (direct — decision-log metadata and one new ADR, both explicitly approved by Ludwig)
- **Budget:** small
- **Branch / worktree:** task/005-decisions-metadata-and-reserved-namespaces (based on task/001)

## Objective
The decision log stops contradicting itself about namespaces. ADR-0119 records that a small
reserved set (`mc`, `test`) is owned by the organisation rather than derived from a username, and
the three ADRs involved in the namespace rule carry the cross-references the log's own amend
protocol requires — so a reader of any one of them learns from its header that it has been
amended.

## Context to load (exhaustive)
- ADRs: 0003, 0030, 0039, 0058, 0059, 0116 (why the index and headers must not lie)
- Files: docs/decisions/README.md (the amend protocol), mission spec §D4/§7, mission log Q2/Q6

## File scope (declared)
- docs/decisions/0119-reserved-namespaces.md (new)
- docs/decisions/0030-manifest.md, 0039-registry-as-git-repo.md, 0058-publishing-flow.md
  (**header metadata lines only** — no substance touched)
- docs/decisions/README.md (index row for 0119)
- docs/tasks/005-decisions-metadata-and-reserved-namespaces.md

## Acceptance criteria
1. ADR-0119 exists, states the reserved set as data (`reserved-namespaces.json`), reuses ADR-0058's
   numeric-id binding unchanged, and carries `Amends: ADR-0030, ADR-0039`. Demonstrated: file read.
2. ADR-0030 and ADR-0039 each carry `Amended by:` lines for both ADR-0058 and ADR-0119.
   Demonstrated: 2 matches each.
3. ADR-0058 carries the `Amends:` line it was missing. Demonstrated: 1 match.
4. Index completeness holds: 119 files, 119 entries, each exactly once, no dangling, all links
   resolve. Demonstrated: set comparison + link-existence loop.
5. No ADR's substance changed. Demonstrated: `git diff` on 0030/0039/0058 shows only added
   header metadata lines.

## Forbidden here
- Changing the substance of any accepted ADR (README: cross-reference metadata is the *only*
  thing ever added).
- Marking ADR-0119 `Accepted` before Ludwig has read the text — he approved the option, not the wording.
- Resolving the namespace question in CI code instead of in the log.

## Questions
- Q: ADR-0119 is `Proposed`. Does Ludwig want it `Accepted` as written, or with edits?
- A (manager): pending — this is the merge gate for this branch.

---
# Task 005 log
- 2026-09-02 opened after Ludwig answered Q2=A and Q6=A in session 1.
- 2026-09-02 wrote ADR-0119; added `Amended by:` to 0030 and 0039 (0058 and 0119 each), and the
  `Amends:` line 0058 lacked; indexed 0119. Criteria 1–5 demonstrated. Status → review.
