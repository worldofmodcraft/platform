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
6. Ships `docs/tasks/031-verify.sh` per MANAGER.md §2c, mutation-tested.

## Forbidden here
- Reading `~/.claude/usage-snapshot.json` for a quota figure. It is retired as a quota source
  (Ludwig, 2026-09-04).
- Modifying claude-hud.
- Leaving `~/.claude/token-guard-check.sh` in place as a silent fallback. Retire it explicitly.

## Interim rule, in force until this lands
Every manager checkpoint resamples across 10 s and treats any variation as UNKNOWN — **and** treats
a figure contradicting Ludwig's stated one as UNKNOWN, since the 2026-09-04 observation shows
sampling alone is insufficient. Ludwig's stated figures are authoritative (MANAGER.md §8b.5).
