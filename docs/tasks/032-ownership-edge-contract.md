# Task 032: The ownership check is an unwritten edge contract

- **Mission:** SITE-V1 — **Status:** **spec-approved (Ludwig, in session, 2026-09-05 — option A)**
- **Agent / model:** doc-writer / sonnet
- **Budget:** small
- **Branch / worktree:** `task/032-ownership-contract` (registry repo). The **platform** half — the
  graph amendment — is already done on `task/032-ownership-edge` and merges first (ADR-0117: the
  graph updates before the contract that fills it).
- **Blocks:** task 007's ownership gate. Its other half (the append-only gates) is unblocked.

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

**Manager's lean: A.**

## Ludwig's ruling, 2026-09-05: **A**
Verbatim: *"A — its own small task before 007's ownership half. Your argument closes it: the one
boundary this mission skipped a contract on is the one where being wrong costs someone their
namespace, right after the append-only contract took four rounds to get right."*

He named the contract's required contents and the regression case; both are written into the
acceptance criteria below.

## Acceptance criteria
Each demonstrated by something a reader can check — a quoted source, or a command with real output.

1. **The graph is amended first** (ADR-0117). Done on the platform side before this task starts:
   edge **E16**, `author (forge identity) → N3`, contract `contracts/ownership.md`, plus an
   amendment-log entry recording that Ludwig approved it. This criterion is satisfied by that merge,
   not by this branch.
2. **`contracts/ownership.md` exists in the registry repository** and states, precisely enough to
   implement without the author present:
   - **What identity is compared: the forge's numeric account id, never the username string.**
     The document must say *why* in one sentence — a username can be released and re-registered by
     someone else; a numeric id cannot — because a reader who does not know that will "helpfully"
     compare names.
   - **Against what:** `owner.id` for **every** namespace the PR touches, not only the first, and
     not only the ones whose files changed most. A PR touching two namespaces is the case to state
     explicitly.
   - **What a first publish binds:** which fields become authoritative at the moment a namespace is
     claimed, and what may never change afterwards.
   - **The reserved-namespace case (ADR-0119):** `mc` and `test` are organisation-owned. State how
     the check behaves for them, and that this is a *reservation*, not an ownership exemption.
   - **The exact ADR-0058 §3 confirmation text**, quoted, not paraphrased.
   - **Where the check runs and what it does on failure** — the same actionable-rejection standard
     `append-only.rules.md` and the asset scanner already meet.
3. **The hostile fixture Ludwig required is specified as a regression case for task 007:** a PR
   whose **author id differs from `owner.id` while the username matches** must be rejected. Written
   into this contract as a required test, so 007 inherits it rather than inventing it.
4. **At least three further attack attempts are recorded**, in the style task 025 used: a real
   attempt against *this* document's rule, not a restatement of the rule. Namespace transfer,
   organisation-owned vs personal accounts, and a deleted-then-recreated account are the obvious
   places to push.
5. **MANAGER.md guardrail 6b is honoured** (task 035, merged 2026-09-05): no environmental fact —
   about GitHub's identity model, account deletion behaviour, or anything else — is stated without
   either a verification command shown or an inline caveat marking it unverified, **at the point the
   claim is made**. This is the first contract written under that rule.
6. **`docs/contracts/README.md` indexes it**, matching the conventions of the ten already there.

## File scope (declared) — registry repository
- `contracts/ownership.md` (new)
- `docs/contracts/README.md` (index row)
- `docs/tasks/032-ownership-contract.md` (the task log on that side)

Anything else = stop and report. In particular: **do not edit `contracts/append-only.rules.md`.**
Its delegation of this check is correct and was settled over four review rounds.
