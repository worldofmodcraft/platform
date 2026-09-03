# Task 027: Correct the two stale statements in the mission spec's D1 and §3

- **Mission:** SITE-V1 — **Status:** spec-approved (manager, 2026-09-03)
- **Agent / model:** manager (documentation correction, no production code)
- **Budget:** small
- **Branch / worktree:** task/027-mission-d1 / `~/wt/platform-task-027`
- **Graph:** none — corrects the mission spec's description of edge **E2**/**E8** fields so it
  agrees with the contract already shipped on `task/006-contracts`.

## Approval
Editing a mission spec requires Ludwig's explicit approval (MANAGER.md §7). **Given in session,
2026-09-03:** *"Mission spec §4 D1: approved — add key_id and correct the ADR count to the current
figure. Log it as an approved spec edit per §7."* This task file is that log.

## Objective
The mission spec stops contradicting the ADRs and the contracts built from them. Two statements are
stale, and both are the kind that mislead someone coding against the spec rather than the ADR.

## The two corrections, with the evidence for each
1. **§4 D1 omits `key_id` from the version-object field list.** Everything else says it belongs:
   ADR-0041 ("the format carries `key_id` for rotation"), task 006's acceptance criterion 1,
   `docs/architecture/depgraph.md` edge E8 (write-back fields, naming `key_id` explicitly), and the
   shipped `contracts/entry.schema.json` on `task/006-contracts`, whose `versions[].required` is
   `['version','commit','source_url','source_archive','source_sha256','signature','key_id',
   'published_at','status']`. The spec itself already names `key_id` twice elsewhere — §4 D2 step 5
   and §7 criterion 2 — so D1 is the single inconsistent line, not the source of truth.
2. **§3 says the decision log has "58 ADRs".** It has 120 (`ls docs/decisions/[0-9]*.md | wc -l`).
   The figure was true when the mission was issued on 2026-09-02 and is not now; left alone, a
   session that reads "58" and finds 120 has to decide which document to distrust.

## File scope (declared)
- `docs/tasks/MISSION-worldofmodcraft-site-v1.md` (two lines)
- `docs/tasks/027-mission-d1-correction.md` (this file)

## Acceptance criteria
1. §4 D1's version-object field list includes `key_id`, in the position the schema uses.
2. §3's ADR count matches the number of ADR files on disk, demonstrated by the count command.
3. Nothing else in the mission spec changes — demonstrated by the diff being exactly two lines.
4. The corrections are marked in the spec as an approved amendment with its date, so a later reader
   sees that the document was edited deliberately rather than drifting.

## Forbidden here
- Any other change to the mission spec — scope, deliverables, acceptance criteria, sequencing.
  Ludwig approved two corrections, not an editing pass.
- Touching `docs/decisions/` (MANAGER.md §3.1).

---
# Task 027 log

- 2026-09-03 spec approved (manager, solo; small documentation correction with Ludwig's explicit
  §7 approval quoted above).

## Acceptance criteria — demonstrated

**1. `key_id` is in D1's field list.**
```
$ grep -n "source_sha256, signature" docs/tasks/MISSION-worldofmodcraft-site-v1.md
47:- `index.json` (or per-mod files under `mods/<ns>.<name>/`): entry schema exactly per ADR-0058 §2 (`owner = { provider, id, name_at_registration }`, versions[] with `{ version, commit, source_url, source_archive, source_sha256, signature, key_id, published_at, status }`).
```
Position matches `contracts/entry.schema.json`'s `versions[].required` ordering on
`task/006-contracts` — `signature`, then `key_id`, then `published_at` — so the spec and the schema
now read in the same order as well as carrying the same fields.

**2. The ADR count matches disk.**
```
$ ls docs/decisions/[0-9]*.md | wc -l
120
$ grep -n "ADRs + index" docs/tasks/MISSION-worldofmodcraft-site-v1.md
41:1. Read the entire decision log (`docs/decisions/`, 120 ADRs + index). ...
```

**3. Nothing else changed.**
```
$ git diff --stat
 docs/tasks/MISSION-worldofmodcraft-site-v1.md | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)
```
**Stated precisely rather than rounded:** two content lines were modified (the two corrections),
and five lines were added — the amendment banner criterion 4 requires. The criterion's wording
("exactly two lines") described the corrections, not the banner; recording the real figure here
rather than a number that sounds like the criterion.

**4. The amendment is marked in the document**, dated, attributed to this task and to Ludwig's §7
approval, and states "No other change" — so a later reader can tell a deliberate edit from drift.

## Booked, not fixed — MANAGER.md §7's own preamble is stale
§7 still opens with *"Default (pending Ludwig's answer, OPEN-QUESTIONS §Q4)"*, while Ludwig has
since referred to that authority as decided ("already decided (Q2-A)"). The question numbering does
not match between the two references, so this is not a mechanical fix, and it is outside this task's
declared file scope besides. Raised in the mission log's `## For Ludwig` rather than edited in
passing — doctrine is not something to tidy on inference.

**Status: criteria 1-4 demonstrated. Ready for merge.**
