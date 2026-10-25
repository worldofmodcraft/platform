# Task 081: runbook — mark M8 (archive Releases and tags protection) done

- **Mission:** SITE-V1 (removal policy item 6) — **Status:** done (manager, 2026-10-25; merged with session PR #72)
- **Repo:** platform. **Agent:** manager (a two-line runbook marker; Ludwig's direct instruction). **Budget:** trivial
- **Branch:** `session/11b` (session PR #72).

## Source
Ludwig, 2026-10-25, after doing M8 on his phone: "Sådär, klart. Du kan bocka för det och merga PR71 o 72".

## Objective
`docs/runbooks/site-v1-manual-steps.md`: M8's heading ☐ → ☑ and its status sentence records what was done and how it
was checked. Nothing else in the runbook changes (068-verify pins the "Last reviewed" line and the other markers).

## Acceptance criteria
1. Evidence (manager, unauthenticated public API, 2026-10-25): `GET /repos/worldofmodcraft/archive/rulesets` lists
   `archive-tags-permanent`, target `tag`, enforcement `active`; its rules are `deletion`, `update`,
   `non_fast_forward`; conditions include `~ALL`. Release immutability and the bypass list are not visible without login
   — recorded as Ludwig's word.
2. `docs/tasks/068-verify.sh` exits 0 after the change.

---
# Task 081 log
- 2026-10-25 manager: evidence as in AC1 (rules `['deletion', 'non_fast_forward', 'update']`, include `['~ALL']`,
  bypass not returned to an unauthenticated caller). "Block force pushes" (non_fast_forward) was pre-ticked by GitHub;
  kept — it only stops moving an existing tag, not creating new ones.
