# Task 040: The asset scan on `page.json` screenshots that ADR-0059 §3 requires

- **Mission:** SITE-V1 — **Status:** **draft** (manager, 2026-09-06). **Not spec-approved.**
- **Budget:** small, to be confirmed at spec time
- **Graph:** node **N3 `registry-ci`** as the second consumer of node **N4 `validation-core`** —
  the consumer the graph already names and nobody has built. Edges **E5/E6**
  (`contracts/validation-report.schema.json`).

## The gap, stated plainly
**ADR-0059 §3** specifies, for a `page.json` PR: *"same ownership check (numeric id), **asset scan
on new screenshots**, no version, no build."* Task 007 implements the ownership check and the
classification. It does **not** implement the screenshot scan, and the reason is a dependency, not a
judgement:

- a `page.json` screenshot is a **path into the archived source tarball** (ADR-0059 §1,
  `contracts/archive-layout.md`), not a file present in the pull request;
- no archive exists until task **008** builds node **N6 `artifact-store`**.

So there is nothing to scan yet. **Until this task lands, a `page.json` PR merges without its
referenced screenshots ever being scanned** — and ADR-0059 §3 puts `page.json` behind a deliberately
lighter gate, which is exactly the asymmetry task 009's proven exploit used. The site now defends
itself (task 009) and the schemas reject `../` (task 034, registry PR #5); the *content* of a
screenshot the page publishes is still unscanned on this path.

**Reachability today:** low — the canary is the only publisher, the same standing argument recorded
for the Ogg residual gap. **This is a hard gate before third-party publishing opens**, alongside
tasks 018 and 019.

## Intended scope
Resolve each newly referenced `screenshots[]` path against the archived tarball for the relevant
version per `contracts/archive-layout.md`, run task 002's magic-byte scanner (node N4) over the
resolved file, and reject the PR with a named message when it is not a whitelisted, well-formed
asset (ADR-0120, content whitelisting — not container framing).

## Blocked by
Task **008** (node N6 must exist). Depends on task **007** for the classification that identifies a
`page.json`-only PR in the first place.
