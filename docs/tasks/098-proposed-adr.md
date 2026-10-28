# ADR-0123: The reference mod that drives the kernel API is chosen by task, not by this log

> **PROPOSAL, not accepted.** Lives in `docs/tasks/` until Ludwig approves it; only then does the
> manager add it to `docs/decisions/` (MANAGER.md section 3.1). **It is conditional on Ludwig's
> answer to Question 1 below.** If the answer is B, this proposal is void and nothing changes.
> Ludwig's redirect of 2026-10-28 (task log): the party mod must not affect ADRs; mods are
> built standalone on the mod API. This proposal therefore touches **no mod content**; it only
> says which mod drives the platform build order.

- **Status:** Proposed
- **Date:** 2026-10-28
- **Area:** Process
- **Touches:** process/build-order, vision
- **Supersedes:** —
- **Amends:** ADR-0001, ADR-0050 (one section per amended ADR below; add `Amended by` metadata to each target's header)
- **Amended by:** (metadata only — added later by amending ADRs, never written at creation)
- **Related:** ADR-0001, ADR-0050, ADR-0051, ADR-0097

## Context
ADR-0001 line 16 says: "The roguelike is the first modpack and the reference implementation that
drives the kernel API from real needs." ADR-0050 line 17 defines build step 1 as "first real
roguelike feature" and line 28 ends the build sequence with "Breadth, driven by the roguelike."
Those three sentences make one particular mod the **driver of the platform's build order**. That
is a process decision, not mod content.

Ludwig, 2026-10-28 (verbatim, Swedish): "vill att den första modden ska vara en Mario Party-liknande
mod där man går omkring på ett spelbräde och samlar stjärnor och spelar mini games med andra
spelare" ("Mario Party-like" is the genre reference only). The mod is designed in
`docs/design/party-board-mod.md` (draft, not accepted). Ludwig then added that the mod should not
affect ADRs, because the point of the mod API is that mods are built standalone. That is
consistent with this proposal: the design document is the mod's whole specification; the only
ADR text in question is *which mod drives the build order*.

## Options considered
- A. The party mod becomes the reference/first mod that drives the kernel API. Amend only the
  sentences named below; the roguelike stays a planned mod.
- B. The party mod is simply a mod. The roguelike stays the reference mod and vertical slice.
  No ADR change.
- C. Both are reference mods: party mod first, roguelike second.

## Decision
Conditional on Ludwig's answer to Question 1. The text below is for **A**; the **C** variant is
given in brackets. For **B** nothing is written.

## Amendments
### ADR-0001 (`docs/decisions/0001-platform-is-the-goal.md`)
Line 16, sentence 2 currently reads: "The roguelike is the first modpack and the reference
implementation that drives the kernel API from real needs." It is read as:
"The party-board mod is the first mod and the reference implementation that drives the kernel API
from real needs; the roguelike remains a planned mod and is no longer the driver."
[C: "The party-board mod is the first, and the roguelike the second, reference implementation that
drives the kernel API from real needs."]

### ADR-0050 (`docs/decisions/0050-build-order-walking-skeleton.md`)
- Line 17 currently reads: "**Step 1 — first real roguelike feature:** 'on level-up, three upgrade
  cards are offered': a new record type, a server hook, RPC, a client panel, persistence,
  observability." It is read as: "**Step 1 — first real feature of the reference mod:** one feature
  that needs a new record type, a server hook, RPC, a client panel, persistence and observability.
  The feature is named in the reference mod's own task file, not in this ADR."
- Line 28 currently ends: "8. Breadth, driven by the roguelike." It is read as: "8. Breadth, driven
  by the reference mod." [C: "driven by the reference mods."]

### Metadata lines added on acceptance (headers only; no other edit to either file)
- `docs/decisions/0001-platform-is-the-goal.md`, after the `Related:` line:
  `- **Amended by:** ADR-0123 (the party-board mod, not the roguelike, drives the kernel API)`
  [C: `(the party-board mod and the roguelike are the reference mods, in that order)`]
- `docs/decisions/0050-build-order-walking-skeleton.md`, after the `Related:` line:
  `- **Amended by:** ADR-0123 (step 1 and step 8 name "the reference mod", not the roguelike)`
- Also on acceptance (mechanical, not ADR substance): add ADR-0123 to the index in
  `docs/decisions/README.md`; regenerate `docs/decisions/INDEX.json` (the generator reads the
  headers, `docs/tools/adr-index.md`).

## Consequences
- The build order's first real feature is chosen in a task file, so a later change of reference
  mod needs no ADR.
- No ADR contains party-mod rules, names or art; the design document is the only home for them.
- The roguelike is **assumed** (marked assumption) to stay a planned mod. Nothing in this proposal
  cancels it.

## Impact
Only the two ADRs above are amended (sentences with file:line given above). Checked per file with
a context read (task log, 2026-10-28):

**Unaffected, because they cite the roguelike as an example or as inherited lessons, not as a
platform rule:** ADR-0009:15 (example conflict message), 0015:17 (a performance test the roguelike
would provide), 0022:18 (future user of `replace`), 0044:9 (roguelike packaging is a roguelike
design decision), 0052:13 (playerbots give solo roguelike players party members), 0054:9 (existing
guides are read first), 0083:7 (driver-mod list), 0091:7 (daily-seed bonus), 0102:7 (SOAP proven by
the roguelike project's ops scripts), 0112:24 (claimant list), 0114:7, :32 (driver-mod list,
example automation), 0115:1, :5 (title and source of the inherited lessons).

**Exceptions: these four DO give the roguelike a platform-level role.** They are not amended by
this proposal (Ludwig's instruction was "only 0001 and 0050"); Ludwig decides whether a follow-up
is wanted if the answer is A or C:
1. ADR-0051:16 — "Reference mod: the roguelike is written as the complete, commented example; every
   API function is used there." (a documentation/DX rule that names the roguelike.)
2. ADR-0113:14 — example chain level (c), "the roguelike as the large example (ADR-0051)".
3. ADR-0097:1, :7 — "The roguelike design kit is re-audited ... before step 1" (a gate on step 1
   that assumes the roguelike is the step-1 mod).
4. ADR-0098:15 — the repo-layout comment "mc:* core mods + roguelike (reference mod)", and
   ADR-0114:17 — character lifecycle listed as a blocker "the roguelike's core loop cannot start
   without it" (descriptive; becomes a roguelike-later fact under A/C, no rule changes).
Also: ADR-0001:19 ("design kit becomes the specification of the first mod") and the title of
ADR-0001 (line 1) still say "first mod" = roguelike; the amendment note in the header is what a
reader sees (titles of accepted ADRs are never edited).

Non-ADR files: `docs/open-questions.md` Q8 and "Deferred to the roguelike design kit" stay valid
(roguelike-specific). `docs/handover/00-start-here.md:36` summarises 0050 generically (checked:
no roguelike wording to change). `docs/tasks/MISSION-worldofmodcraft-site-v1.md:37` ("Any content
for the roguelike mod" out of scope for SITE-V1) and `docs/tasks/010-test-mod.md:155` are
unaffected: scope fences for other missions, a party mod is equally out of scope there.
`docs/tools/adr-index.md:52` and `docs/tasks/done/003-adr-index-generator.md:164` quote ADR-0001's
title as test data and stay as they are.

## Questions for Ludwig
Each: two sentences of context, options, consequences, lean marked with a star.

### Q1 (decides whether this proposal exists)
ADR-0001/0050 make the roguelike the mod that "drives the kernel API from real needs" and the
step-1 feature. Your party mod could be just another standalone mod, or take over that driving role.
- **A ★** The party mod becomes the reference/first mod. Amend only the sentences above; the
  roguelike stays planned. Consequence: platform work is pulled by the party mod's needs
  (instancing, groups, overlays, UI) first; combat and character-lifecycle surfaces wait. Resting on
  assumption until you answer: nothing is written to the ADRs.
- **B** The party mod is simply a mod; the roguelike stays reference and vertical slice. No ADR
  change; this proposal is void. Consequence: the party mod is built when its dependencies on
  the platform exist, which the roguelike's order may delay.
- **C** Both are reference mods, party first, roguelike second. Amend 0001/0050 to name both.
  Consequence: two sets of platform needs are tracked; slightly more process, no loss of either.
Lean: A, because you called it the first mod and the party mod stresses the multiplayer surfaces
the platform is meant for (ADR-0002:13); but B is equally valid, since mods are standalone.

### Q2 (changes the design doc, section e)
Should bots fill empty seats when fewer than the maximum players are present? Options:
- A. No bots in version 1; 2-4 humans only. Consequence: you cannot test alone with one client.
- B ★ Board-only bots (they roll, buy stars, choose forks; in minigames they get a
  simulated score drawn from a distribution). Consequence: solo play and testing work; no
  real bot play in minigames.
- C. Full bots in minigames too. Consequence: large extra work per minigame.

### Q3 (changes the design doc, section b/e)
Player count. A. 2-4 players ★ (small groups, ADR-0002:13). B. up to 6. C. up to 8.
Consequence: more players mean more minigame categories to rebalance and longer games.

### Q4 (changes the design doc, section b)
Default game length: A. 10 turns (about 30 min). B. 15 turns ★ (about 45 min). C. 20 turns
(about 60 min). All are settings anyway (ADR-0029:9); this only sets the default and what the
pacing numbers are tuned for.

## Interacts with
ADR-0001, ADR-0050 (amended); ADR-0051, ADR-0097, ADR-0113 (exceptions above, not amended);
ADR-0044 (modpacks: the party mod ships as one standalone mod; unaffected).
