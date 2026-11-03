# ADR-0124: The remaining ADR lines that gave the roguelike a platform role name "the reference mod"

- **Status:** Accepted (2026-11-03, accepted by Ludwig)
- **Date:** 2026-11-03
- **Area:** Process
- **Touches:** process/build-order, docs/reference-mod
- **Supersedes:** —
- **Amends:** ADR-0001, ADR-0051, ADR-0097, ADR-0098, ADR-0113, ADR-0115 (one section per amended ADR below; add `Amended by` metadata to each target's header)
- **Amended by:** —
- **Related:** ADR-0123

## Context
ADR-0123 (accepted 2026-11-03) amended ADR-0001:17 and ADR-0050:17, :28 so that the mod driving the
kernel API is named by the build-order task file, not fixed to the roguelike. Its Impact section
listed further ADR lines that still give the roguelike a platform-level role (ADR-0051:16,
ADR-0113:14, ADR-0097:1 and :7, ADR-0098:15, ADR-0115:44, and ADR-0001:20 with the title of
ADR-0001) and booked a follow-up for Ludwig. Line numbers below were re-derived on main on
2026-11-03 (ADR-0001 gained a header line from ADR-0123, so its lines moved by one).

## Options considered
- A. Amend none of them; leave the roguelike named in those lines.
- B. Amend only some of them.
- C. Amend all of them, as one ADR with one section per amended ADR (amend, not supersede: each decision stands, only the identity of the mod changes).

## Decision
**Option C.** Ludwig, 2026-11-03 (verbatim): "3. Amend them all". The six ADRs below are amended by
the readings below; the roguelike stays a planned mod and its kit v17 stays its specification.
The title of ADR-0001 (line 1) and the title of ADR-0097 (line 1) are not edited (README rule); the
`Amended by` line in each header is what a reader sees.

## Amendments
### ADR-0001 (`docs/decisions/0001-platform-is-the-goal.md`)
Line 20 of the design-kit consequence currently reads:

> - The existing roguelike design kit (21 locked decisions, 18 design documents) becomes the specification of the first mod, not of the platform.

It is read as:

> - The existing roguelike design kit (21 locked decisions, 18 design documents) becomes the specification of the roguelike mod, a planned mod, not of the platform; which mod is the first/reference mod is named per ADR-0123.

### ADR-0051 (`docs/decisions/0051-modder-first-evening-and-dev-mode.md`)
Line 16 currently reads:

> - **Reference mod:** the roguelike is written as the complete, commented example; every API function is used there. Style rule: clear over clever.

It is read as:

> - **Reference mod:** the reference mod (ADR-0123: named in the build-order task file) is written as the complete, commented example; every API function is used there. Style rule: clear over clever.

### ADR-0097 (`docs/decisions/0097-roguelike-kit-reaudit.md`)
Line 7 (the decision; the title on line 1, "before step 1", is not edited) currently reads:

> Before step 1, a dedicated task walks the roguelike kit (21 locked decisions, v16, 30 files) decision by decision asking: *design choice, or workaround for a wall that no longer exists?* (Overlay, own client, UI framework, achievements service and world overlays removed several old walls — reused icons, DBC field limits, gossip-only UI.) Workarounds are rewritten against platform capabilities; genuine design choices stay untouched. Output: kit **v17**, the first mod specification *under* the platform. Reason: the reference mod teaches every future modder — it must demonstrate the platform's real patterns, not 2025's stopgaps. Reading + decisions, no code; manager + Ludwig work.

It is read as:

> Before the roguelike's own first build task (not platform step 1, which ADR-0123 assigns to the reference mod), a dedicated task walks the roguelike kit (21 locked decisions, v16, 30 files) decision by decision asking: *design choice, or workaround for a wall that no longer exists?* (Overlay, own client, UI framework, achievements service and world overlays removed several old walls — reused icons, DBC field limits, gossip-only UI.) Workarounds are rewritten against platform capabilities; genuine design choices stay untouched. Output: kit **v17**, which stays the roguelike's specification under the platform. Reason: the reference mod teaches every future modder — it must demonstrate the platform's real patterns, not 2025's stopgaps. Reading + decisions, no code; manager + Ludwig work.

### ADR-0098 (`docs/decisions/0098-repo-layout-and-org-responsibilities.md`)
Line 15 (repo-layout comment) currently reads:

>   mods/       mc:* core mods + roguelike (reference mod)

It is read as:

```
  mods/       mc:* core mods + the reference mod(s) (ADR-0123) + other first-party mods
```

### ADR-0113 (`docs/decisions/0113-documentation-as-a-product.md`)
Line 14, item (c) of the example chain currently reads:

> 3. **Example chain — three levels of real code:** (a) snippets in the reference; (b) **small complete example mods in `mods/examples/`** — one per core pattern (counter achievement, custom command, simple upgrade card) — built and smoke-tested in CI as real mods; (c) the roguelike as the large example (ADR-0051), cross-referenced both ways (reference pages link "used in roguelike: …"; roguelike code comments link back).

It is read as:

> 3. **Example chain — three levels of real code:** (a) snippets in the reference; (b) **small complete example mods in `mods/examples/`** — one per core pattern (counter achievement, custom command, simple upgrade card) — built and smoke-tested in CI as real mods; (c) the reference mod as the large example (ADR-0051, ADR-0123), cross-referenced both ways (reference pages link "used in the reference mod: …"; its code comments link back).

### ADR-0115 (`docs/decisions/0115-roguelike-lessons.md`)
Line 44 currently reads:

> The roguelike project comments in Swedish (its reader is Ludwig); World of Modcraft is English throughout (ADR-0056). The reference mod v17 will be English-commented — confirmed as the platform's choice.

It is read as:

> The roguelike project comments in Swedish (its reader is Ludwig); World of Modcraft is English throughout (ADR-0056). The reference mod(s) (ADR-0123) and the roguelike kit v17 will be English-commented — confirmed as the platform's choice.

### Metadata lines added (headers only; no other edit to any of the six files)
- ADR-0001, ADR-0051, ADR-0097, ADR-0098, ADR-0113: after the `Related:` line (ADR-0001 and ADR-0051 keep their existing `Amended by` line).
- ADR-0115: after the `Source:` line (it has no `Related:` line).
- Each reads `- **Amended by:** ADR-0124 (<summary>)`.
- Mechanical: ADR-0124 is added to the index in `docs/decisions/README.md`; `docs/decisions/INDEX.json` is regenerated.

## Consequences
- No ADR line gives the roguelike a platform-level role any more; the reference mod is named by task file (ADR-0123).
- The roguelike kit re-audit (ADR-0097) gates the roguelike's own first build task, not platform step 1.
- The roguelike stays a planned mod (assumption carried from ADR-0123); nothing here cancels it.

## Interacts with
ADR-0123 (the rule this completes); ADR-0001, ADR-0051, ADR-0097, ADR-0098, ADR-0113, ADR-0115 (amended).
