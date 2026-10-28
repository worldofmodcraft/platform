# Task 096: runbook — mark M9, M10 and M11 done; correct M9 step 2's sidebar path

- **Mission:** SITE-V1 — **Status:** spec-approved (manager, solo gate, 2026-10-28; the 085 shape)
- **Repo:** platform. **Agent / model:** qa-engineer (§3.5). **Budget:** small (≤ 1 agent-session, in two phases)
- **Branch / worktree:** `task/096-runbook-m9-m11-done` / `~/wt/task-096`, cut from platform `origin/main` `3562c8f`

## Source (all in the mission log, session 13, 2026-10-28; quote from there)
- M9: Ludwig "Klart för M9 med gate"; manager's API read of `branches/main/protection` (required `gate`, strict, PR required, 0 approvals,
  enforce_admins false); L4 (registry PR #26 `BLOCKED` after update-branch, closed unmerged).
- M9 step 2: Ludwig "\"Code planning and automation\" finns inte i sidebaren"; he reached the page via the direct URL
  `https://github.com/worldofmodcraft/registry/settings/branches`.
- M10: Ludwig "M10 klar, appen heter worldofmodcraft-membership"; secret names listed; live check registry PR #28 `MEMBERSHIP_STATUS: 204`.
- M11: Ludwig "M11 done …"; manager's API read of both environments (`branch:main` policy, one secret each, timestamps) and of the repository
  secrets (only the two `REGISTRY_MEMBERSHIP_…` left); the `.pem` is a pipeline-App key from 2026-10-27 (Ludwig's file name).

## Objective
`docs/runbooks/site-v1-manual-steps.md`: M9, M10, M11 headings ☐ -> ☑, each with a **Status: done (Ludwig, 2026-10-28).** paragraph in the
085 shape (what was done, on whose word, what the manager verified and how, what stays unverified). M9 step 2 gives the direct URL first and
says the sidebar heading varies (`[unverified]` naming; Ludwig did not see "Code, planning, and automation"). M11's status records the open
hygiene item (delete the pipeline App's unused keys after 008b-3b's first live run) and that the minisign offline backup (Q-H) is unconfirmed.
Nothing else in the runbook changes.

## Acceptance criteria
1. Content as in Objective; every claim cites its source above; nothing outside M9, M10, M11 changes (`git diff -U0` hunks inside those three
   sections only).
2. **Phase 2 (only when the manager releases the machine):** `068-verify.sh` and `085-verify.sh` (pinned) exit 0 on the branch; if any
   marker check reads HEAD and reddens on these flips, re-pin it red-first as in 085 (and add that script to File scope in the log, stop and
   report first). `096-verify.sh` (new): scope check (merge-base with origin/main, absent = FAIL), the three headings ☑ at the branch FINAL
   pinned SHA, the step-2 URL present; runs in a fresh GitHub clone; output pasted.
3. **Phase 1 (now):** no `*-verify.sh` is run (task 089b's multi-hour chain owns the machine; its quiet-wait counts verify processes).

## File scope
`docs/runbooks/site-v1-manual-steps.md` (M9, M10, M11 only), `docs/tasks/096-runbook-m9-m11-done.md` (log), `docs/tasks/096-verify.sh` (new).

---
# Task 096 log  (append-only)
- 2026-10-28 manager (session 13): written from the mission log's session 13 entries; phase 1 dispatched.
