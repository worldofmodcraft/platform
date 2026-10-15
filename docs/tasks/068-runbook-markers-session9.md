# Task 068: the SITE-V1 runbook's markers show Ludwig's manual steps of 2026-10-15

- **Mission:** SITE-V1 — **Status:** spec-approved (manager, solo gate, 2026-10-15, session 10; small documentation)
- **Repo:** platform (`wom`). **Agent / model:** doc-writer / per agent frontmatter. **Budget:** small (≤ 1 agent-session)
- **Branch / worktree:** `task/068-runbook-markers` / `~/wt/task-068`, cut from platform `origin/main`
- **Graph:** documentation only; no node or edge.

## Objective
`docs/runbooks/site-v1-manual-steps.md` shows, with evidence cited per marker:
- **M3 ☑** — the `MINISIGN_SECRET_KEY` Actions secret exists (M3 done 2026-09-05, `gh secret list`, mission log line ~898;
  re-confirmed by Ludwig's Q-H answer 2026-10-15).
- **M5 ☑** — GitHub App `worldofmodcraft-pipeline` created under the org, installed on `registry`, `site`, `archive`, key and
  App ID stored as registry Actions secrets (Ludwig, 2026-10-15); public page answers 200.
- **M7 ☑** — `https://github.com/worldofmodcraft/archive` is public with one commit.
- **Q-H ☑** — answered: "MINISIGN_SECRET_KEY finns" (Ludwig looked; nothing was copied).
- **M6 ☐** and **M4 ☐** stay open; M6's text says it is needed before task 010 / the final demo, not before 008b.
- The "Last reviewed" line names 2026-10-15 and task 068, and points to this file's log for the new evidence.
Source for all of the above: mission log, section "Ludwig's manual steps, 2026-10-15 (after the handover entry)".

## Context to load (exhaustive)
This file; `docs/runbooks/site-v1-manual-steps.md`; `docs/tasks/060-runbook-manual-steps.md` (conventions and evidence
style); `docs/tasks/MISSION-worldofmodcraft-site-v1-log.md`, the section named above and the "M3 is DONE" entry (grep for
them; do not read the whole log).

## Acceptance criteria — `docs/tasks/068-verify.sh`, whose output the log pastes
1. Each of M3, M5, M7, Q-H has a ☑ heading marker and a one-line evidence note (who/what/date) — no secret value anywhere.
2. M4 and M6 headings keep ☐.
3. The status line inside M5 no longer says "not done … returns 404".
4. Every public URL cited as evidence is re-checked by the agent with an unauthenticated `curl -s -o /dev/null -w '%{http_code}'`
   and the code is logged (archive repo, App page). The verify script does **not** make network calls; it checks the text.
5. `068-verify.sh --mutate` shows each check red when its marker is reverted (one mutation per marker, in a temp copy).
6. Only the runbook, this task file and `068-verify.sh` changed (`git diff --name-only origin/main...HEAD`).

## File scope (declared)
`docs/runbooks/site-v1-manual-steps.md`, `docs/tasks/068-runbook-markers-session9.md` (log), `docs/tasks/068-verify.sh` (new).

## Forbidden here
Any authenticated call (`gh` included) or reading any secret, token or credential (CLAUDE.md rule 11) — evidence is the
mission log plus unauthenticated public URLs only; changing step instructions beyond the status lines; touching other
task files (moving done task files is task 069).

## Dependencies
None. Task 069 (ledger hygiene, moving done task files) follows after this merges, because it may move task 060's file,
which the runbook cites.

---
# Task 068 log
- 2026-10-15 manager (session 10): spec written and approved (solo gate, SPEC-CHECKLIST 1–8; small documentation).
- 2026-10-15 manager: worktree `~/wt/task-068` cut from platform origin/main `3f25f03`; dispatched. check-log-entry baseline = 2.
