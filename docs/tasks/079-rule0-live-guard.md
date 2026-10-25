# Task 079: a live guard on CLAUDE.md rule 0 (the token guard) — its text changes only together with a reviewed reference

- **Mission:** SITE-V1 (doctrine integrity) — **Status:** spec-approved (manager, solo gate, 2026-10-25)
- **Repo:** platform. **Agent / model:** qa-engineer (§3.5). **Budget:** small (≤ 1 agent-session)
- **Branch / worktree:** `task/079-rule0-live-guard` / `~/wt/task-079`, cut from platform `origin/main` (`8004828` or later)
- **Graph:** verification tooling + doctrine reference; no component edges.
- **Merge:** Ludwig's written approval (doctrine, §7).

## Source
Ludwig, 2026-10-25, "Go with star" on: "Should something keep watching CLAUDE.md rule 0? A ★ a small new task adds a
check that turns red if the rule-0 text changes without your approval." Background: task 078 pinned 048's c1 to PR #50's
range (platform `8004828`), so nothing watches rule 0's wording live any more (078 log, Question 1). CLAUDE.md rule 0
itself says "no one deletes or edits the rule, and revocation is Ludwig's alone, in writing".

## Objective
A live check, run on HEAD forever, that fails when the rule-0 block of `CLAUDE.md` (from the line starting `0. **THE TOKEN
GUARD` up to, not including, the line starting `1. **English everywhere**`) differs byte-for-byte from a committed
reference copy `docs/manager/rule0.reference.md`. The way to change rule 0 legitimately is a PR that changes both files;
such a PR touches `docs/manager/`, so §7 already requires Ludwig's approval — the check's failure message says so.
Missing block, missing reference, or more than one rule-0 block = fail, never skip.

## Approach
1. `docs/manager/rule0.reference.md`: the exact current block (byte-identical extraction), below a short header and a
   marker line saying what it is, its source (this task, Ludwig 2026-10-25) and that changing it needs Ludwig's written
   approval. The comparison uses only the part after the marker.
2. `tools/manager/check-rule0.sh`: extracts both, compares, exit 0 / 1 (differs) / 2 (block or reference missing or
   ambiguous); on 1 prints a unified diff and the sentence above. Matches the style of `tools/manager/check-log-entry.sh`.
3. `docs/tasks/079-verify.sh` runs it on HEAD (live) plus its own-change checks on fixed SHAs (REVIEW-CHECKLIST item 12
   as proposed by task 076).

## Acceptance criteria — `docs/tasks/079-verify.sh`, whose output the log pastes
1. On HEAD: `check-rule0.sh` exits 0.
2. Mutations (in a temp clone): one character changed inside rule 0 → 1; the suspension paragraph deleted → 1; rule 0's
   heading line removed → 2; reference file removed → 2; a duplicated rule-0 block → 2; a change **outside** rule 0
   (e.g. rule 1's text) → still 0; rule 0 and the reference changed identically → 0.
3. Every `docs/tasks/*-verify.sh` exits 0 on HEAD, one at a time, foreground, from the worktree root (stale ignored
   `__pycache__` removed first; 049 reddens on them).
4. Own-change checks (file scope, red-first ancestry if any) use fixed SHAs recorded at the end.

## File scope
`docs/manager/rule0.reference.md` (new), `tools/manager/check-rule0.sh` (new), `docs/tasks/079-rule0-live-guard.md` (log),
`docs/tasks/079-verify.sh` (new). **`CLAUDE.md` is read, never edited.** Anything else = stop and report.

## Forbidden
Editing CLAUDE.md or MANAGER.md; normalising whitespace in the comparison (byte-exact is the point); a skip on missing
input. If writing under `docs/manager/` is refused by the permission classifier, stop and report — never work around it.

---
# Task 079 log
- 2026-10-25 manager (session 11): written and approved (solo gate) from Ludwig's answer 2 ("Go with star").
- 2026-10-25 qa-engineer (session 11): built check-rule0.sh, rule0.reference.md (written under docs/manager/ without classifier refusal), 079-verify.sh. Mutations (all via copies; CLAUDE.md never edited): char change ->1, suspension paragraph deleted ->1, heading removed ->2, reference missing ->2, duplicated block ->2, rule 1 text change ->0, rule 0 + reference changed identically ->0; extras: marker removed ->2, empty reference ->2, reworded heading ->2, trailing space ->1 (byte-exact). Finding: none; note the bare-heading match is on `0. **THE TOKEN GUARD`, so a reworded heading is exit 2 (fail, not skip).
