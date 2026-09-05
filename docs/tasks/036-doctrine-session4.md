# Task 036: Two doctrine rules and one interim rule, from session 4's findings

- **Mission:** SITE-V1 (doctrine) — **Status:** spec-approved (Ludwig, in session, 2026-09-05)
- **Agent / model:** manager (doctrine text; no production code)
- **Budget:** small
- **Branch / worktree:** `task/036-doctrine-session4` (platform repo)
- **Graph:** none.

## Objective
Three rules Ludwig gave during session 4, each traceable to evidence produced the same day.

1. **MANAGER.md guardrail 6c** — the companion to 6b (task 035):
   *"6b covers what you cannot check; it never substitutes for the sub-minute check you can."*
2. **MANAGER.md §8, the token guard** — an interim rule, in force until task 031 lands: the usage
   snapshot file and every tool reading it are **advisory only**; Ludwig's stated figure is
   authoritative; absent a fresh figure from him, prefer UNKNOWN over the file, and UNKNOWN halts.
3. **Deferred to the next session, not written here:** the verification-artefact companion —
   *"a suite is judged by the breaking cases it contains, not the count it passes; every fix round
   adds the found break as a fixture before the fix."* Ludwig tied it to task 023's fix round
   closing, which had not happened when this branch was written. **Do not merge it early.**

## Evidence, so the rules are traceable rather than aphorisms
- **6c** — task 025's second review round found two claims that were neither folklore nor
  unverifiable, just wrong, each falsifiable in under a minute with an installed tool. The key-id
  byte order was backwards, and because rule 6 of the same contract compares that value, a verifier
  built from the text would have rejected **every** correctly signed artefact — found the same
  morning M3 loaded the signing secret. And `git archive` was recommended for producing archives the
  same document rejects as malformed.
- **The interim token-guard rule** — the snapshot read 5-hour 40 % while Ludwig's HUD read 55 %
  minutes later. A 15-point gap in the unsafe direction, during a session where task 023's own round
  had started real `claude` sessions, each rewriting the shared file with its own frozen figures.
  This is the falsification mode from session 3, live again and now measured twice.

## Acceptance criteria
1. Guardrail 6c exists, quotes Ludwig's sentence, and carries both concrete examples with the real
   values (`C48C7A6A59305B6E` / `6E5B30596A7A8CC4`, and the `git archive` behaviour).
2. §8's token-guard bullet carries the interim rule, names its expiry condition (task 031), and
   records the 40 %-vs-55 % observation with its mechanism.
3. Nothing else in the doctrine is altered; the deferred third rule is **not** present.

## File scope (declared)
- `docs/manager/MANAGER.md` (guardrail 6 and §8's token-guard bullet only)
- `docs/tasks/036-doctrine-session4.md` (this file)

Anything else = stop and report.

## Verification
Doctrine prose; no command-based criteria, so no `036-verify.sh` (§2c). The criteria are checked by
reading the diff.

## Status
**done** — pending merge. The third rule stays booked for the session that closes task 023.
