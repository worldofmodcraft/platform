# Task 074: draft ADR — removal policy for published versions (Ludwig's decision 2026-10-17)

- **Mission:** SITE-V1 — **Status:** done (merged platform PR #61 `0aac566`) — was: spec-approved (manager, solo gate, 2026-10-17). The ADR itself takes effect only when
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
- 2026-10-17 doc-writer: drafted docs/decisions/0122-removal-policy.md (Proposed; items 0-5; relations cited to ADR-0041:15, 0046:27, 0037:45, 0121:79,121-122; 8 open questions); README and INDEX.json updated via tools/adr/build_index.py (--check OK, json.tool OK); no existing ADR edited.
- 2026-10-17 manager: Ludwig answered the eight open questions: "Stjärna på alla" (manager's lean on each: Q1 yes, amends ADR-0041 on acceptance; Q2 Ludwig decides each malware case, agents gather evidence; Q3 deferred to a task when 008b/008c are live; Q4 Swedish/EU law plus GitHub terms; Q5 issue or email, Ludwig decides, no formal deadline; Q6 resolution fails with explanation per ADR-0041; Q7 belongs to the launcher design; Q8 record rejected alternatives briefly). Folding into the ADR; acceptance itself still to be stated by Ludwig.
- 2026-10-17 doc-writer: folded Ludwig's answers to the eight open questions into ADR-0122 (Q3, Q7 recorded as deferred; options considered added; ADR-0041 amendment stated for acceptance, not applied); status stays Proposed.
- 2026-10-17 doc-writer: Ludwig's acceptance round (status Accepted, README/INDEX update, 'Amended by' line in ADR-0041) was DENIED by the permission classifier (Modify Shared Resources) on the combined edit command; not retried. State: ADR-0122 still Proposed with answers folded in (uncommitted); build_index --check fails (Amends header mismatch until ADR-0041 gains Amended by); nothing committed.
- 2026-10-25 doc-writer: Ludwig accepted ADR-0122 on 2026-10-17 ("Acceptera"). ADR-0122 status set to Accepted (2026-10-17, accepted by Ludwig); ADR-0041 header gained ADR-0122 in its existing "Amended by" line; README row no longer says Proposed; INDEX.json regenerated with `python3 tools/adr/build_index.py --write` (exit 0). `--check` exit 0 ("CHECK OK"); `python3 -m json.tool docs/decisions/INDEX.json` exit 0. No docs/tasks/*-verify.sh references docs/decisions (grep found none), so none run.
- 2026-10-25 doc-writer (task 072): status corrected by task 072: done, merged as platform PR #61 (`0aac566`, on platform origin/main).
