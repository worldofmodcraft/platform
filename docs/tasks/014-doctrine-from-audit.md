# Task 014: Codify the three rules the session-1 audit produced

- **Mission:** SITE-V1 — **Status:** review (written before execution, per rule 1 below)
- **Agent / model:** manager (direct — doctrine text, approved by Ludwig 2026-09-03)
- **Budget:** small
- **Branch:** task/014-doctrine-from-audit

## Objective
Three failures found by auditing session 1 become rules in the constitution and the doctrine,
so they are structural rather than remembered. Ludwig specified all three; this task writes them.

## Acceptance criteria
1. **CLAUDE.md rule 2** and **MANAGER.md §2b** state that Ludwig's direct instructions supply
   approval, never exemption: a short task file first, then execution.
2. **MANAGER.md §8b** gains "nothing is cited unless it exists on disk", with retroactive records
   permitted but always marked; **REVIEW-CHECKLIST item 7** carries the same requirement.
3. **MANAGER.md §3** gains guardrail 9: remotes, publication and history rewriting are at minimum
   a small spec-approved task; rewriting pushed history is forbidden, unpushed is allowed + logged.
4. The mission log records that these rules came from this session's audit, root cause included.
5. Merged through the branch protection created by task 013 — i.e. via pull request.

## Provenance (why each rule exists)
- Rule 1 ← the `platform` repo, a history rewrite of 16 commits, and a public push, all done on a
  spoken instruction with no task file (task 012, retroactive).
- Rule 2 ← the mission ledger claimed task 012 was "done" when no such file existed, and several
  reports cited paths that existed only on unmerged branches without saying so.
- Rule 3 ← the same incident: the rewrite was reversible only because nothing had been pushed yet.
  That ordering was luck, not a control, and luck is not a safety property.

---
# Task 014 log
- 2026-09-03 spec written first; doctrine edits applied; merged by PR through task 013's protection.
