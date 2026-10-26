# Task 088: inventory — every own-change check on a moving frame in every closed verify script (platform + registry)

- **Mission:** SITE-V1 (verification integrity) — **Status:** spec-approved (manager, solo gate, 2026-10-26)
- **Repos:** platform and registry, read-only. **Agent / model:** surveyor. **Budget:** small (≤ 1 agent-session)
- **Output:** a report to the manager (the surveyor writes nothing); the manager records it in the mission log and specs the fix
  tasks 089 (registry) and 090 (platform) from it, to run after 087, 039b and 085 merge.

## Source
Ludwig, 2026-10-26: "A star" — one sweep instead of fixing closed scripts one at a time. Background: REVIEW-CHECKLIST item 12;
eight instances so far (067, 071, 007b, 078's 048/051/063, 084's 075, 085's 068, 087's 032/067/070), and 087 found five latent
README-at-HEAD reads (registry 007a-verify.sh:117-118, 007b-verify.sh:100-101, 008a-verify.sh:74, 057-textchecks.py:180,
tests/registry/test_hardening.py:153).

## Objective
For every closed task's verify artefact in both repos (`docs/tasks/*-verify.sh`, helper scripts they call such as
`057-textchecks.py`, and tests that assert a task's own change), list every check that reads the working tree, `HEAD`,
`origin/main` or `BASE..HEAD`, and classify it: **own-change** (evidence of that task's own change — must be pinned to its PR
range) or **live** (a property of HEAD a later task should still be caught breaking — stays on HEAD). One line why for each.
Note checks already pinned correctly (to confirm coverage) and checks with no moving read.

## Acceptance criteria
1. Every `docs/tasks/*-verify.sh` in both repos (registry: read via `git -C /home/ludwig/registry show origin/main:<path>`;
   platform: /home/ludwig/wom on origin/main) is listed with its count of moving reads; the total matches a grep count.
2. Each own-change finding gives `repo:file:line`, the file it reads, and the task's merge commit (for the pin), found via
   `git log --merges --grep`.
3. Open PRs that already fix some (registry 087 #24, platform 085 #80, registry 039b, platform 039b) are noted so 089/090 do
   not duplicate them.
4. Nothing written.

---
# Task 088 log
- 2026-10-26 manager: written from Ludwig's choice ("A star on the above one").
