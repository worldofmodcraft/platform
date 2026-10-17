# Task 073: survey of every prior decision on removing a published version (input for Ludwig's F2 brainstorm)

- **Mission:** SITE-V1 — **Status:** done (2026-10-17) (manager, solo gate; read-only survey, no code)
- **Agent / model:** surveyor / per frontmatter. **Budget:** small. **Branch:** none (read-only; the report is returned to
  the manager and summarised in the mission log).
- **Graph:** contract edges E4 (append-only rules) and the ownership edge (`ownership.md`); no change.

## Objective
A report that quotes, with file and line, every accepted decision and contract rule bearing on: who may remove a
published version, on what grounds, what "removed" does to the hosted archive and the site, whether authors may withdraw
or yank, and how the R11 takedown identity is authorised. Sources: ADR index, ADR-0041, ADR-0058, ADR-0119, ADR-0121 and
any other ADR the index ties to takedown/removal/immutability/archive; registry `contracts/ownership.md` (R3, R7, R11,
Attempt 8), `contracts/append-only.rules.md` (T2, coexistence, attack attempts); MANAGER.md §7 (takedown approval).
It ends with contradictions or gaps found between them. No recommendation.

## Acceptance criteria
1. Every claim carries a file:line citation; quotes are verbatim.
2. A "none found" for a source states the search that was run.
3. Gaps and contradictions are listed separately from the quotes.
Criteria are human-checked (manager reads the report); no verify script — read-only survey.

---
# Task 073 log
- 2026-10-17 manager: written and approved; dispatched to surveyor. Trigger: Ludwig's answer to "For Ludwig" item 1
  (session 10): owners must not be able to remove published versions; brainstorm against prior decisions.
- 2026-10-17 manager: survey received (removal grounds, file fate, installed copies, appeals, author yank, archive protection, stale §7 wording). Ludwig decided "Option A for all"; recorded in the mission log with the manager's per-item reading. Task done.
