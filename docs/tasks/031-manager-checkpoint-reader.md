# Task 031: A trustworthy usage reader for the manager's own checkpoints

- **Mission:** SITE-V1 (tooling) — **Status:** spec-approved (manager, 2026-09-04)
- **Agent / model:** implementer / sonnet — **not yet dispatched: blocked on task 023**
- **Budget:** small
- **Branch / worktree:** task/031-checkpoint-reader (to be created from platform main)
- **Blocked by:** task 023, which builds the pane-reading primitive this reuses. Dispatching this
  first would duplicate that work and risk two readers disagreeing — the exact failure being fixed.

## Objective
CLAUDE.md rule 0's checkpoints have a source the manager can trust. Today they do not.

## The defect, verified
`~/.claude/usage-snapshot.json` is written by **every** running Claude Code session's statusline,
each with its own last-known figures and an always-current `updated_at`. An idle session rewrites
frozen values that look one second old. Observed on 2026-09-03, sampling once per second:
```
6 samples  2026-09-03T17:21:12.156Z   5h 58%   weekly 38%
6 samples  2026-09-03T17:21:09.948Z   5h 84%   weekly 40%
```
`~/.claude/token-guard-check.sh` — the reader every checkpoint uses — inherits this exactly,
returning **84 %** five times and **58 %** on the sixth, seconds apart:
```
BINDING: 5-hour 84% ... AGE: 1s  VERDICT: OK (<90%) - work may continue
BINDING: 5-hour 58% ... AGE: 1s  VERDICT: OK (<90%) - work may continue
```
**The stale reading is systematically the lower one**, so the guard fails in the one direction that
matters: it under-reports, and would not halt at 90 %. The staleness rule cannot catch it because
the timestamp is always fresh.

**A second observation, 2026-09-04, that rules out the obvious mitigation.** Twelve consecutive
identical samples returned `weekly 0%`, then later `weekly 1%`, while Ludwig's own HUD read 40 % and
an earlier manager read gave 43 %. **Resampling detects divergence between writers; it cannot detect
a single writer that is simply wrong.** So "sample across 10 s and treat variation as unknown" is a
useful interim floor and *not* a fix.

## The constraint that shapes the design
Task 023's answer is to read the figures from the session's own tmux pane, where they are correct by
construction. **That works only when the session runs inside tmux.** Under the supervisor it does;
a manager session started by hand in a bare terminal has no pane to capture. The design must state
what happens in that case rather than silently returning something.

## Acceptance criteria
1. A reader exists in the platform repository under `tools/` — **version-controlled**, unlike
   `~/.claude/token-guard-check.sh`, which lives unversioned in a home directory.
2. It reuses task 023's pane-reading primitive rather than reimplementing it. One mechanism, one
   set of bugs.
3. **Outside tmux it reports UNKNOWN and says why**, naming the one action that resolves it. It
   never falls back to the retired snapshot file, and never returns a figure it cannot stand behind.
4. Unknown is a stop, per CLAUDE.md rule 0 — demonstrated, not asserted.
5. `OPERATIONS.md` replaces the `token-guard-check.sh` row with this tool, and states plainly that
   the old reader was wrong in the under-reporting direction, so nobody resurrects it.
6. **It reads all THREE windows `/usage` reports and halts on the most constrained.** `/usage`
   distinguishes the **5-hour** window, the **weekly all-models** window and the **weekly
   model-specific** window (Fable, today). CLAUDE.md rule 0 and MANAGER.md §8 are worded for two
   ("5-hour or weekly"); the reader is specified for all binding windows, whichever is most
   constrained governing, and written generally enough that a fourth window does not require a
   redesign. **A window the reader cannot see is UNKNOWN, and UNKNOWN halts** — it never reports
   the minimum of the windows it happened to find. Demonstrated with a fixture per window, plus one
   where a window is missing.
7. Ships `docs/tasks/031-verify.sh` per MANAGER.md §2c, mutation-tested.

## Forbidden here
- Reading `~/.claude/usage-snapshot.json` for a quota figure. It is retired as a quota source
  (Ludwig, 2026-09-04).
- Modifying claude-hud.
- Leaving `~/.claude/token-guard-check.sh` in place as a silent fallback. Retire it explicitly.

## Interim rule, in force until this lands
Every manager checkpoint resamples across 10 s and treats any variation as UNKNOWN — **and** treats
a figure contradicting Ludwig's stated one as UNKNOWN, since the 2026-09-04 observation shows
sampling alone is insufficient. Ludwig's stated figures are authoritative (MANAGER.md §8b.5).

## Amendment, 2026-09-06 (Ludwig's ruling, session 6)
Acceptance criterion 6 above is new: **the guard's halt/resume logic must be specified against all
three windows `/usage` reports**, not the two the doctrine text names. Same principle as has been
applied all along — whichever window is most constrained governs — but three-way, and stated so
that it does not have to be rediscovered.

Two consequences worth stating here rather than leaving to the implementer:
- **Rewording CLAUDE.md rule 0 and MANAGER.md §8** from "5-hour or weekly" to the general form is a
  **doctrine change, and therefore Ludwig's** (MANAGER.md §3.1 territory by analogy: the manager
  does not reinterpret a rule it is governed by). Booked for him, not done. Until he rules, this
  task's criterion 6 is the operative specification and the doctrine text is read as the general
  rule with two examples.
- **The reader's failure mode for a window it cannot see is UNKNOWN, never omission.** The retired
  snapshot's defect was under-reporting; a reader that quietly drops a window it cannot parse
  reproduces exactly that defect in a new place.

Also relevant to this task's design, added the same day (see `docs/manager/OPERATIONS.md`, "The
morning ritual"): **the HUD's usage line only renders while a session is actively running**, so an
idle session has no reading at all. The pane-reading primitive this task reuses inherits that: an
idle or freshly-woken session's pane carries no usage element, which criterion 3's UNKNOWN path
must cover as well as the outside-tmux case.
