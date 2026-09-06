# Task 039: The registry CI workflow — the checkers wired onto real pull requests

- **Mission:** SITE-V1, deliverable **D1** (the other half of the CI section) — **Status:** **draft**
  (manager, 2026-09-06). **Not spec-approved; not dispatchable.**
- **Agent / model:** to be decided at spec time (implementer / sonnet, expected)
- **Budget:** medium (≤ 3 agent-sessions), to be confirmed when the spec is written
- **Branch / worktree:** to be created in the **registry** repo
- **Graph:** completes node **N3 `registry-ci`**; introduces no new edges.

## Why this file exists now, as a draft
Two things booked only in a session scratchpad were later lost and had to be re-created from memory
(tasks 034 and 007). A forward declaration costs five minutes and makes the ledger show the whole of
D1 rather than the half currently in flight. **This is a placeholder with a scope, not a spec** —
nothing may be dispatched from it.

## Intended objective
The four checkers from task 007 run on every pull request to `worldofmodcraft/registry`, and their
verdicts are visible to the human who opened the PR.

## Intended scope (to be turned into acceptance criteria)
1. A GitHub Actions workflow running the task-007 checkers on every PR, path-filtered per ADR-0099,
   with the full log posted as a PR comment on failure (mission D2 §6 applies the same rule to the
   pipeline).
2. **The one live-API fact task 007 deliberately left out:** organisation membership for the
   ADR-0119 reserved-namespace path, injected into the checker as its oracle.
3. The **ADR-0058 §3 confirmation text** rendered in the CI comment on a first publish: *"This
   creates the namespace `X:` permanently bound to your GitHub account (id N). Namespaces are never
   reassigned."*
4. **`page.json`-only PRs skip the build pipeline and merge on green checks** (mission D1, ADR-0059
   §3) — the classification comes from task 007; this task wires it to what actually runs.
5. `CONTRIBUTING.md` documenting the manual-PR publish flow for humans, including the
   namespace-permanence notice (mission D1's last bullet).
6. **Which identity the workflow reads** — settled in `contracts/ownership.md`, implemented here.
   A fork PR, a bot-opened PR and a maintainer-opened PR must each resolve to the identity the
   contract names, and that must be demonstrated, not reasoned about.

## Acceptance shape (why this could not be part of task 007)
Mission acceptance criterion 1 requires the CI to **reject** specific PRs. Its registry half —
invalid schema, wrong account for an existing namespace, a modified version object — is demonstrated
by opening real pull requests against a protected repository and showing the red check and its
message. That needs merge authority, live runs and Ludwig's eyes; task 007's criteria are all
offline. The seam is the reason for the split, recorded in `docs/tasks/007-registry-ci-checkers.md`.

## Blocked by
Task **007** (the checkers). Nothing else.
