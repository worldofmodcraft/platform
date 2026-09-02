# Task 013: Make §3.2 physical — branch protection on both repositories

- **Mission:** SITE-V1 — **Status:** spec-approved (Ludwig, 2026-09-03)
- **Agent / model:** manager (direct — repository settings, no code)
- **Budget:** small
- **Branch:** task/013-branch-protection

## Objective
`main` on `worldofmodcraft/registry` and `worldofmodcraft/platform` cannot be written except
through a pull request, cannot be force-pushed, and cannot be deleted — for administrators too.
MANAGER.md §3.2 already forbids direct pushes to main; today that rule is moral, and this session's
own audit showed what a moral rule is worth under speed. This makes it physical.

## Context to load
- ADRs: **0041** ("Registry protection: branch protection, no force-push, PRs only, validated by
  the pipeline"), 0058, 0069, 0099
- Files: MANAGER.md §3.2, §7; docs/tasks/done/012-platform-repo-and-identity.md (why this exists)

## File scope
Repository settings only (GitHub API). One file in git: this task file.

## Acceptance criteria
1. `registry` main: PRs required, force-push blocked, deletion blocked, admins included.
   Demonstrated by reading the protection back from the API.
2. `platform` main: same, with zero required approving reviews (manager opens and merges its own
   PR under §7 merge authority).
3. A direct push to a protected main is **refused**. Demonstrated by attempting one and showing
   the rejection — a protection nobody has tested is a claim, not a control.
4. The settings are recorded here so they can be restored if a repo is recreated.

## Forbidden here
- Granting any bypass actor or exemption. If protection genuinely blocks work, the escape hatch is
  temporarily lifting it — loudly and deliberately — never a quiet exemption (Ludwig, 2026-09-03).
- Requiring approvals that a solo maintainer cannot satisfy, which would force the escape hatch to
  become routine and thereby destroy it.

## Known consequence to carry into task 008
Full protection on `registry` collides with the two-phase publishing flow decided in Q4: the
post-merge workflow writes `source_archive`, `source_sha256`, `signature` and `key_id` back into
the entry, which is a write to `main`. Under this protection it can no longer push directly.
The resolution belongs to task 008, not here: the pipeline runs on a branch of the *same*
repository (so repository secrets are available, unlike a fork PR), pushes
`pipeline/<ns>.<name>-<version>`, opens a PR, and that PR is merged once its own checks pass.
Two PRs per publish instead of one, and nothing bypasses the gate.

---
# Task 013 log
- 2026-09-03 spec written before execution, per the rule being codified in task 014.
