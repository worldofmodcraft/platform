# Task 077: runbook step M8 — protect `worldofmodcraft/archive` Releases and tags from deletion

- **Mission:** SITE-V1 (removal policy, item 6) — **Status:** spec-approved (manager, solo gate, 2026-10-18)
- **Repo:** platform. **Agent / model:** doc-writer (ROUTING.md). **Budget:** small (≤ 1 agent-session)
- **Branch / worktree:** `task/077-runbook-archive-protection` / `~/wt/task-077`, cut from platform `origin/main`
- **Graph:** docs only (runbook); no edge changes.

## Source
Ludwig, 2026-10-17, "Option A for all" — removal policy item 6 (mission log, "Removal policy — brainstorm and Ludwig's
decision"): a protection rule on `worldofmodcraft/archive` so Releases cannot be deleted; a manual step for Ludwig with
exact clicks written by the manager's side.

## Objective
`docs/runbooks/site-v1-manual-steps.md` gains a section `## ☐ M8 — Protect the archive's Releases and tags` (after M7,
same format as M5/M7) that Ludwig can follow click by click in the GitHub web UI, plus one way to check afterwards that
the protection is in force.

## Requirements
1. **Verified facts only (§3, verified-facts rule, task 035).** Every UI path, setting name and behaviour is taken from
   GitHub's current documentation (docs.github.com), fetched in this task; each claim cites the doc URL in the log.
   Candidates to check — not facts until verified: tag rulesets restricting deletion/update of `refs/tags/*`;
   GitHub "immutable releases" (repository setting); whether deleting a Release (not the tag) can be prevented at all,
   and whether the org-owner (Ludwig) can still bypass. Say plainly what each mechanism does **not** prevent.
2. Explain in two or three plain sentences why the step exists (ADR-0041:15 and Ludwig's 2026-10-17 decision: a
   published version stays published; a takedown stops public serving but keeps the record). Ludwig is not a terminal
   user: web UI clicks, no shell commands unless unavoidable (then the exact command, complete).
3. A "check afterwards" step that does not need credentials beyond Ludwig's normal browser login.
4. If GitHub offers no way to prevent Release deletion, the section says so and names the closest protection, and the
   gap is booked as a Question in this log — no invented mechanism.

## Acceptance criteria
1. The section exists with ☐ status, follows the M-section format, and each fact has a cited URL in the log.
2. `tools/vault` or runbook-marker checks that exist (e.g. task 068's) stay green; run every `docs/tasks/*-verify.sh`
   that touches the runbook and paste exit codes.
3. No other runbook section changes.

## File scope
`docs/runbooks/site-v1-manual-steps.md` (new M8 section only), `docs/tasks/077-runbook-archive-protection.md` (log).

## Forbidden
Making any change on GitHub (the step is Ludwig's); reading or using any token or credential; editing ADRs.

---
# Task 077 log
- 2026-10-18 manager (session 11): written and approved (solo gate).
