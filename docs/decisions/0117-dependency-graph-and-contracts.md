# ADR-0117: Dependency graph before code; every edge names its contract

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Architecture / Process
- **Touches:** docs/architecture, process/specs, contracts, ci
- **Related:** ADR-0050, ADR-0065, ADR-0079, ADR-0085, ADR-0099, ADR-0116

## Decision
Before implementation of any mission or phase begins, a **dependency graph** is drawn and
committed: nodes = components (coarse — components, never files; the platform is ~15–25 nodes,
SITE-V1 about 8), edges = "depends on / talks to".

**The edge rule:** every edge crossing a component boundary names its contract — an IDL surface,
a file in `contracts/`, a defined file format (`.wompack`, `page.json`, records), or `internal`
(same component, no boundary). An edge without a contract is an architecture error with exactly
two fixes: define the contract, or merge the nodes (it was not a real boundary). This
generalises contract-first (ADR-0079) from backend features to **all** component boundaries;
the graph doubles as the index of contracts.

**Specs build on the graph:** every task file identifies the node(s) or edge(s) it implements
and may only touch its declared edges; creating a new dependency requires updating the graph
*first* — a small, cheap, reviewable design decision instead of a silent import. The manager
derives task ordering topologically and parallelism from disjoint subgraphs (spec-checklist
item 7 becomes derivable rather than remembered).

**Form and verification:** hand-declared intent first (`docs/architecture/depgraph.md` +
machine-readable sibling), verified against reality later: the survey checks whether AC/WoWee's
actual dependency structure matches assumptions, and CI can eventually flag code-level edges
absent from the graph (dependency hygiene as a mechanical gate, ADR-0116 layer 1). The walking
skeleton (ADR-0050) is pointed out as the thinnest path through the graph; CI path-filter
granularity (ADR-0099) gets its first map from it.

## Consequences
- SPEC-CHECKLIST gains: "node(s)/edge(s) identified in the dependency graph; no new undeclared
  edges" — added in the same change.
- SITE-V1's first manager task is drawing the mission's graph; the platform graph is a
  skeleton-phase deliverable.
