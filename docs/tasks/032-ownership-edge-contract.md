# Task 032: The ownership check is an unwritten edge contract

- **Mission:** SITE-V1 — **Status:** **draft — needs Ludwig's approval before it may start**
- **Agent / model:** doc-writer / sonnet (proposed)
- **Budget:** small (proposed)
- **Blocks:** task 007's ownership gate should not be written before this is decided.

## Why this is a draft and not spec-approved
It would **add an edge to the accepted dependency graph** (`docs/architecture/depgraph.md`, status
"accepted, session 1"). That is an architecture change, and ADR-0117's own rule is that a new
dependency updates the graph *first*. The manager will not make that change unilaterally.

## The finding (task 006, review round 4, independently verified)
`contracts/append-only.rules.md` deliberately does **not** reject an entry whose `owner` belongs to
someone else at a first publish; it delegates that to "the ownership gate", citing ADR-0058 §2-3.
That delegation is correct — the append-only checker is not the right place for it.

But the graph's edge table has **no row and no contract file for ownership**. E1-E14 each name a
contract; ownership appears only inside node **N3**'s prose description ("schema, **ownership by
numeric id**, append-only, PR classification"), and in the mission spec's outcome 2.

**So the risk is not that it gets forgotten.** Task 007 builds N3 and will find the requirement.
The risk is that **the defence against namespace capture — the attack ADR-0058 §2 exists to
prevent — gets implemented from an ADR read fresh, with no contract document and no adversarial
fixture**, immediately after the append-only contract took four review rounds and one escalation to
get right. Every other boundary in this mission has a written agreement; the one guarding ownership
does not.

## Options for Ludwig
- **A ★ Its own small task before 007 starts.** Add the edge to the graph and write
  `contracts/ownership.md`: what identity is compared (the numeric account id, never the username
  string), against what (`owner.id` for every touched namespace), what a first publish binds, the
  reserved-namespace case (ADR-0119), and the exact ADR-0058 §3 confirmation text. Costs one small
  task; gives the namespace-capture defence the same standing as every other boundary.
- **B Fold it into task 025** (the six other boundary contracts, currently running). Cheaper in
  ceremony, but 025 was specified as "no new edges", so this would widen a running task's scope —
  the thing MANAGER.md §3.3 says to stop and report rather than do.
- **C Prose-only: leave the graph alone**, and require a hostile fixture in task 007's spec instead
  (a PR whose author id differs from `owner.id` while the username matches, which must be rejected).
  Cheapest; leaves ADR-0117's "every boundary edge names its contract" rule with a known exception.

**Manager's lean: A.** The one place we skipped a contract this mission is the one that took four
rounds to fix, and this is the boundary where being wrong means someone loses their namespace.
