# Task 021: Planned handover at 30 % / 40 %, replacing §5's 60 % arithmetic

- **Mission:** SITE-V1 (cross-cutting) — **Status:** done (2026-09-03)
- **Agent / model:** manager (direct — doctrine, specified by Ludwig)
- **Budget:** small · **Branch:** task/021-handover-rule

## Objective
The manager hands over deliberately and early rather than letting auto-compaction decide. MANAGER.md
§5's 60 % figure predates the 1M-token window; at 1M, 60 % is an enormous conversation and recall
degrades well before the arithmetic threshold.

## Acceptance criteria
1. MANAGER.md §5 carries the 30 % soft / 40 % hard thresholds, the self-service reading method, the
   four-step handover procedure, and the instruction never to rely on auto-compaction.
2. Context percentage is self-service: `~/.claude/checkpoint.sh` reports the token guard and the
   context reading together, and treats a missing or >10-minute-stale cache as unknown.
3. OPERATIONS.md is marked a living document, updated as part of every handover.
4. The agents' 60 % rule is left intact — it applies to subagents, whose contexts are separate.

## Why 30/40 rather than lower
Handover is not free: a fresh session re-reads the constitution, the doctrine, the decision index,
the mission log and the open task files before it can act — call it 30–50k tokens of ritual. At a
300k trigger that overhead is ~13 % of the session; at 200k it is ~20 %. Below roughly 25 % the
project would spend more on re-establishing context than on work. 30 % soft with a 40 % hard stop
keeps the overhead proportionate while leaving a full 10 % band to finish cleanly.

## Log
- 2026-09-03 written, merged, and applied immediately: this session was at 46 % when the rule
  landed, past the hard threshold, so it performed the handover procedure at once.
