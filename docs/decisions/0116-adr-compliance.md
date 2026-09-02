# ADR-0116: ADR compliance — gates first, indexed selection, bidirectional review

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Process / Governance
- **Related:** ADR-0054, ADR-0068, ADR-0113, ADR-0115

## Context
The log now holds 115+ decisions. No agent can hold them all in context, and pasting the log into every session would burn the scarcest resource (context) on 90 % irrelevance. Compliance must therefore not depend on anyone "knowing all ADRs".

## Decision
Five layers, strongest first:

1. **Mechanical gates.** Every ADR that *can* become a gate *becomes* one: registry CI (append-only), the doc generator's refusal (0113), symbol checks (0012/0034), validate lints (0115), worktree structure (doctrine). Skeleton and survey work continuously moves decisions from "read and obey" to "cannot be done wrong". An agent that never read the ADR still cannot break it.
2. **The task file is the context filter.** The manager lists the exact ADRs a task touches in "Context to load"; the executing agent reads those before work — never the whole log. Knowledge in files, selection by the manager.
3. **Bidirectional review.** Review-checklist item 4 is sharpened: the reviewer verifies (a) the listed ADRs are followed, **and** (b) the diff touches no areas whose ADRs were *not* listed — a selection miss is a manager error, caught in review. Two independent chances instead of one.
4. **A machine-readable ADR index.** Every ADR header gains a `Touches:` line (paths/topics, e.g. `kernel/persistence`, `registry`, `client/ui`) alongside `Area:`. A generated `docs/decisions/INDEX.json` is built from the headers (CI-diffed so it never lies). The manager's session ritual and task creation use it: task touches `kernel/persistence` → index yields 0008, 0017, 0023, 0034, 0115 → into the Context field. Later, a CI check on task PRs performs the same lookup and warns on gaps between the diff's paths and the task's ADR list — making layer 2 mechanical too. Tagging the existing 115 is a cheap-agent task with manager review, run with the constitution work.
5. **The constitution carries only the universal rules** (~10 that apply to everyone, always: English, the forbidden-shortcuts list, the measurement standard, the boring-solutions rule, "never guess before data") **plus the pointer to the index** — which is why it can stay under a page, the condition for actually being read.

A sixth, silent layer already exists: **immutability itself.** ADRs are never edited, so an agent's knowledge can never be *wrong* — only incomplete. `Amended by` headers guarantee visibility of additions; incompleteness is caught by layer 3; wrongness cannot occur.

## Consequences
- REVIEW-CHECKLIST item 4 updated (bidirectional) in the same change as this ADR.
- TEMPLATE gains the `Touches:` header line.
- The INDEX.json generator and the tagging of existing ADRs are scheduled with the constitution task.
