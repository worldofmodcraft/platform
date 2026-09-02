# Task 015: The token guard — subscription headroom as an absolute stop condition

- **Mission:** SITE-V1 (cross-cutting) — **Status:** done (merged as PR #4, 2026-09-03)
- **Agent / model:** manager (direct — doctrine text, specified by Ludwig 2026-09-03)
- **Budget:** small · **Branch:** task/015-token-guard

## Objective
The 90 %/50 % token guard is law in both places an agent will actually read it: CLAUDE.md's
universal rules (as rule 0, above all others) and MANAGER.md §8's absolute stop conditions.

## Acceptance criteria
1. CLAUDE.md carries it as **rule 0**, marked as outranking every rule below. Existing rules 1–10
   keep their numbers, so prior citations (e.g. "universal rule 2") stay valid.
2. MANAGER.md §8 carries it among the absolute stop conditions, with the same thresholds.
3. Both state the four operative parts: stop at 90 %, resume only below 50 %, checkpoint and log at
   the named moments, and **unknown usage counts as above 90 %**.
4. Both state that only Ludwig may lift it, explicitly and in writing, and that a figure he states
   is authoritative immediately.
5. Merged by PR through the branch protection from task 013.

## Note on immediate applicability
The rule binds this session from the moment it is written. The first checkpoint was taken while
writing it: **usage is not determinable from inside this environment** — the HUD reports context
percentage, not subscription usage; there is no usage file under `~/.claude` and no CLI flag that
exposes it. Under criterion 3 that reading is "above 90 %", so work is halted pending Ludwig's
figure. Writing this task itself proceeded only because Ludwig instructed it explicitly, in
writing, in this session — which is precisely the exemption the rule permits and no wider.

**Open question for Ludwig:** with no machine-readable source of usage, every checkpoint depends on
him stating a figure. That makes the guard depend on a human in the loop at exactly the moments the
loop is busiest. Worth deciding how he wants checkpoints to work in practice — see the mission log.

---
# Task 015 log
- 2026-09-03 written and merged by PR; first checkpoint recorded as UNDETERMINED → treated as >90 %.
