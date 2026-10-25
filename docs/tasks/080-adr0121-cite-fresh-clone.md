# Task 080: the architecture note cites ADR-0121 on main, not a local-only branch — 056/076/078 verify green in a fresh clone

- **Mission:** SITE-V1 (verification integrity) — **Status:** spec-approved (manager, solo gate, 2026-10-25)
- **Repo:** platform. **Agent / model:** doc-writer (ROUTING.md). **Budget:** small (≤ 1 agent-session)
- **Branch / worktree:** `task/080-adr0121-cite` / `~/wt/task-080`, cut from platform `origin/main` (`29b3424` or later)
- **Graph:** docs + verification tooling only.

## Source
Review of task 079 (PR #68), finding 2: `078-verify.sh` (and through it `076-verify.sh`) fails at g056 in **any fresh
clone** and passes only in local worktrees. Cause (manager, 2026-10-25): `docs/architecture/system-overview.md:282`
cites `proposal/adr-0121-version-lifecycle:docs/decisions/0121-version-lifecycle-pending.md`; that branch exists only in
the local repository (`git branch -a` shows no `remotes/origin/` copy). ADR-0121 has been on main since PR #48
(`59aa8f6`) at `docs/decisions/0121-version-lifecycle-pending.md`. REVIEW-CHECKLIST item 8 requires verify scripts to
pass in a fresh clone.

## Objective
1. `docs/architecture/system-overview.md` (~line 282): cite ADR-0121 by its path on main
   (`docs/decisions/0121-version-lifecycle-pending.md`) instead of the branch; keep the sentence's meaning. Grep the note
   for any other `branch:path` cite to a branch that has no `origin/` copy and fix it the same way.
2. If `056-verify.sh` (or 078's g056 path) hard-codes the branch cite, change only that reference to the main path; no
   other change to closed scripts. If it resolves cites generically, no script change is needed.

## Acceptance criteria — `docs/tasks/080-verify.sh`, whose output the log pastes
1. Red first: in a fresh `git clone` of `origin/main` (before the fix), `056-verify.sh` (or the g056 step) fails; shown.
2. In a fresh clone of the PR head: `056-verify.sh`, `076-verify.sh`, `078-verify.sh`, `079-verify.sh` exit 0, run one at
   a time, foreground, `PYTHONDONTWRITEBYTECODE=1`, from the clone root.
3. No `branch:path` cite in `docs/architecture/` names a branch absent from `origin` (checked by the script against
   `git ls-remote`, which needs no credentials for this public repo).
4. Every `docs/tasks/*-verify.sh` exits 0 in the worktree, one at a time. Own-change checks on fixed SHAs (REVIEW-CHECKLIST
   item 12).

## File scope
`docs/architecture/system-overview.md` (cites only), `docs/tasks/056-verify.sh` (the cite only, if needed),
`docs/tasks/080-adr0121-cite-fresh-clone.md` (log), `docs/tasks/080-verify.sh` (new). Anything else = stop and report.

## Forbidden
Pushing or deleting the local `proposal/adr-0121-version-lifecycle` branch; changing any other check; skips.

---
# Task 080 log
- 2026-10-25 manager (session 11): written and approved (solo gate) from 079 review finding 2.
- 2026-10-25 doc-writer (task 080): AC1 red: fresh clone of origin/main (29b3424), `056-verify.sh` exit 1, "30 pass, 1 fail". Fix: `system-overview.md` ~line 282 now cites `docs/decisions/0121-version-lifecycle-pending.md` (on main since PR #48); it was the only `branch:path` cite in `docs/architecture/`. No script change: 056 resolves cites generically. Added `080-verify.sh` (AC3 via `git ls-remote --heads`). Worktree: 056, 076, 078, 079, 080 exit 0 (see AC4 run below and PR for fresh-clone results).
- 2026-10-25 doc-writer (task 080): results. Fresh clone of PR head f173739 (GitHub, one script at a time, foreground-equivalent, PYTHONDONTWRITEBYTECODE=1): 056=0, 076=0, 078=0, 079=0 (AC2). Worktree: all 14 `docs/tasks/*-verify.sh` exit 0 (AC4; 061, 076, 078 exceed 110 s, first pass hit my timeout (124), rerun without timeout gave 0). 080-verify.sh exit 0, 0 branch:path cites remain, ADR-0121 path resolves (AC3).
