# Task 060: Ludwig's new manual steps (M5–M7, Q-H) in the SITE-V1 runbook

- **Mission:** SITE-V1 — **Status:** spec-approved (manager, 2026-10-15; small documentation, §2b solo gate)
- **Agent / model:** doc-writer / per agent frontmatter
- **Budget:** small
- **Branch / worktree:** task/060-runbook-manual-steps / ~/wt/task-060

## Objective
`docs/runbooks/site-v1-manual-steps.md` shows the true current state of every manual step:
- M0–M4 status markers are corrected from evidence.
- New steps are added: M5 (create the org-owned GitHub App), M6 (Ludwig's personal account joins the org),
  M7 (create `worldofmodcraft/archive`) and Q-H (check whether the `MINISIGN_SECRET_KEY` secret exists).
- Every step has exact click-paths or commands that Ludwig can follow, written for a non-programmer.

## Context to load
- The runbook itself.
- `docs/manager/OPERATIONS.md` (evidence for M0–M3).
- `docs/tasks/008b-pipeline-workflow.md` (where M5–M7 were first written, with unverified click-paths).
- `docs/tasks/010-test-mod.md` (M4).
- The mission log on branch `session/8-status` (Ludwig's 2026-10-14 answers Q-D/E/F/H):
  `git -C /home/ludwig/wom show session/8-status:docs/tasks/MISSION-worldofmodcraft-site-v1-log.md | tail -60`.

## File scope
`docs/runbooks/site-v1-manual-steps.md` and this file's log only.

## Acceptance criteria
1. Each status marker is backed by cited evidence (a file or a read-only command shown in the log), or marked `[unverified]`.
2. M5–M7 and Q-H exist. Each states why it is needed (cite the decision), when (which task waits on it), and how
   (steps). Click-paths that were not verified are marked `[unverified — check on screen]`.
3. No step asks Ludwig to paste a secret anywhere, and the doc says so explicitly for Q-H (look, do not copy).
No verify script: the criteria are documentary, checked by the manager at review.

## Forbidden here
Credentials of any kind; gh auth/secret commands; editing any other file.
