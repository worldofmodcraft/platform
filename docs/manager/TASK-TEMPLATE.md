# Task NNN: <imperative title>

- **Mission:** <e.g. SITE-V1> — **Status:** draft | spec-approved | in-progress | review | done | stopped  (no start before spec-approved — MANAGER.md §2b)
- **Agent / model:** <agent name> / <explicit model>
- **Budget:** small | medium | large (MANAGER.md §8)
- **Branch / worktree:** task/NNN-slug / ../wt/task-NNN

## Objective
One paragraph. What exists when this is done that does not exist now.

## Context to load (exhaustive)
- ADRs: ...
- Files: ...
- Survey docs: ...

## File scope (declared)
Paths this task may create/modify. Anything else = stop and report.

## Acceptance criteria
Numbered, each independently demonstrable.

## Forbidden here
Task-specific traps, plus MANAGER.md §3.7 always applies.

## Deliverables
Code + tests + docs updated + this file's log section current.

## Questions  (agent-maintained; see MANAGER.md 8b)
- Q: <what is unclear> | options: A/B | assumed: A | built on assumption: <files/behaviour>
- A (manager): <answer> — per <ADR/spec section>   ← filled at triage

---
# Task NNN log  (append-only, updated continuously by the executing agent)
- <timestamp> started; plan: ...
- <timestamp> done: ... / decided: X because Y / remaining: ...
- <timestamp> [context ~60%] wrapping up sub-step, log current, ending run.
