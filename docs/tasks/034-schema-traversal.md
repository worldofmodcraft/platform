# Task 034: the merged schemas still accept `../` in `screenshots[]`

- **Mission:** SITE-V1 — **Status:** **spec-approved (manager, 2026-09-05)**. Booked by Ludwig in
  session 4 as a consequence of task 009's proven exploit; re-created on disk here because the
  original scope note lived only in a session scratchpad.
- **Agent / model:** implementer / sonnet
- **Budget:** small
- **Branch / worktree:** `task/034-schema-traversal` — **registry** repo, worktree
  `~/wt/registry-task-034`. The platform side is this spec file only.
- **Blocks:** nothing today. **Prevents:** the next consumer of these schemas re-introducing the
  hole the site just closed in its own build.

## The finding, already proven (task 009 review, reproduced independently by the manager)
`page.json`'s `screenshots[]` was validated only against a pattern forbidding a leading `/`, a URL
scheme and backslashes — **not `../`** — and the value was joined onto a real filesystem path. The
manager reproduced it on the original commit: `/etc/passwd` copied into `public/_generated/`,
surviving into `dist/`, **sha256 byte-identical to the real file**. Per ADR-0059 §3, `page.json`
publishes on a lighter gate than `entry.json`, so an accepted page-content PR was the whole attack.

**The site now defends itself. The contract does not.** Both merged schemas on registry `main`
carry the identical permissive pattern:

```
contracts/page.schema.json      properties.screenshots.items.pattern
contracts/manifest.schema.json  properties.screenshots.items.pattern
  ^(?!/)(?!.*://)(?!.*\\).+$
```

`../../../../etc/passwd` satisfies it. So does `a/../../../etc/passwd`.

## Scope — deliberately narrow, and this matters
**In scope:** the `screenshots[]` path fields in `contracts/page.schema.json` and
`contracts/manifest.schema.json`.

**Explicitly OUT of scope — do not widen to these** (Ludwig, session 4): `links[].url`, `source`,
`source_url`, `source_archive`. **Those are URLs, and the same reasoning does not apply.** A task
that wants to touch them stops and reports (MANAGER.md §3.3).

## Acceptance criteria
Each demonstrated by a command with **real** output in the task log.

1. **Both schemas reject path traversal** in `screenshots[]`. At minimum these are rejected:
   `../etc/passwd`, `a/../../etc/passwd`, `./../x`, `a/..`, and a bare `..`.
2. **Legitimate paths still validate** — this is half the task, not an afterthought. At minimum
   these are accepted: `assets/screenshots/shop.png`, `docs/img/a.b/c.png`, and a filename
   containing dots that are not traversal (`screenshots/v1.2.3.png`, `a..b/c.png` — two dots
   *inside* a segment are not a traversal segment). A pattern that rejects these is a regression,
   not a fix.
3. **The rejection is demonstrated by running a real JSON-Schema validator** against both schemas,
   not by reasoning about the regular expression. Use whatever validator the repository already
   uses for its existing schema tests (see `docs/validation/` and the existing test suite) — the
   same engine that will run in CI, because a pattern that behaves differently in another regex
   dialect is not a fix.
4. **The traversal cases become permanent fixtures** in the repository's schema test suite,
   alongside the accepted cases from criterion 2 — added **before** the pattern is changed, and
   shown failing first. Ludwig's rule, which this task is the first to apply deliberately:
   *a suite is judged by the breaking cases it contains, not the count it passes.*
5. **Mutation-tested.** Revert the pattern to the old one in a scratch copy and show the new
   fixtures actually redden. A fixture that passes against the vulnerable pattern proves nothing.
6. **The `examples/` directory still validates** — `contracts/examples/` holds the valid and
   invalid examples task 006 made load-bearing. Every existing valid example must still pass and
   every invalid one must still fail, with the counts shown.
7. **The field descriptions are updated** to state the traversal rule, matching the standard the
   other contracts meet. Docs move with code (universal rule 9).

## The trap this task must not fall into (manager error, session 4, recorded)
A counted payload can silently turn a real attack into a green test. `path.join` **clamps** excess
`..` at the filesystem root, so `../../../../../../../../etc/passwd` resolves to `/etc/passwd` on a
shallow tree but to `/home/etc/passwd` on a deeper one — producing a "not found" that looks exactly
like a successful rejection. **Any fixture that exercises a real filesystem must use the clamping
form and assert on the schema's verdict, not on whether a file was found.**

## File scope (declared) — registry repository
- `contracts/page.schema.json`
- `contracts/manifest.schema.json`
- the existing schema test suite (add fixtures; do not weaken existing ones — MANAGER.md §3.5)
- `docs/tasks/034-schema-traversal.md` (the task log on that side)

Anything else = stop and report.
