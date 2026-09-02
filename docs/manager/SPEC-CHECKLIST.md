# Spec Checklist (gate before any delegation — MANAGER.md §2b)

A task file reaches `spec-approved` only when every item holds. Small tasks: the manager
verifies solo, in the same sitting. Large, core-surgeon or security-touching tasks: the
reviewer agent performs an independent spec review *before* delegation (author ≠ reviewer
applies to specs too).

1. **Objective** describes an observable end state ("X exists and does Y"), not an activity.
2. **Acceptance criteria** are each independently demonstrable by a command/output/screenshot.
3. **File scope** is declared and minimal.
4. **Context list** is complete: the INDEX.json lookup was performed; every ADR the diff could
   touch is listed (ADR-0116 layer 2).
5. **Budget** is set and plausible for the scope; if in doubt, the task is split.
6. **Task-specific traps** are listed under Forbidden (beyond the standing §3.7 list).
7. **Dependencies/sequencing** against other open tasks are stated (file overlaps = sequence);
   the task's node(s)/edge(s) are identified in the dependency graph and no new undeclared
   edges are introduced — a new dependency updates the graph first (ADR-0117).
8. **Core-surgeon only:** the covering survey document exists and is cited; if none, a survey
   task is created first.

Rationale: ROUTING.md already records that most failures are spec failures. Catching them
before code exists is the cheapest fix in the system — every spec error caught here is a
two-strike escalation that never happens.
