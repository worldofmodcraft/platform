# ADR-0123: The reference mod that drives the kernel API is chosen by task, not by this log

> **PROPOSAL, not accepted.** Lives in `docs/tasks/` until Ludwig approves it; only then does the
> manager add it to `docs/decisions/` (MANAGER.md section 3.1). **It is conditional on Ludwig's
> answer to Question 1 below.** If the answer is B, this proposal is void and nothing changes.
> Ludwig's redirect of 2026-10-28 (task log): the party mod must not affect ADRs; mods are
> built standalone on the mod API. This proposal therefore touches **no mod content and names no
> mod inside any ADR text**; it only says that the mod driving the platform build order is named
> in a task file, not fixed in the ADRs.

- **Status:** Proposed
- **Date:** 2026-10-28
- **Area:** Process
- **Touches:** process/build-order, vision
- **Supersedes:** —
- **Amends:** ADR-0001, ADR-0050 (one section per amended ADR below; add `Amended by` metadata to each target's header)
- **Amended by:** —
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

**Amend, not supersede.** The README defines an amendment as "the decision stands but gains
requirements/refinements" and a supersede as "the decision was wrong or is replaced". ADR-0001's
decision (the platform is the goal and is built from a real mod's needs, ADR-0001:16, :20) stands;
only the identity of the driving mod changes, and this proposal removes the identity from the ADRs
altogether. Superseding ADR-0001 would replace the platform decision itself. Ludwig decides
whether he accepts that reading; if not, the alternative is a partial supersede of the two
sentences, which the README does not provide for.

## Options considered
- A. The party mod becomes the reference/first mod that drives the kernel API. Amend only the
  sentences named below; the roguelike stays a planned mod.
- B. The party mod is simply a mod. The roguelike stays the reference mod and vertical slice.
  No ADR change.
- C. Both are reference mods: party mod first, roguelike second.

## Decision
Conditional on Ludwig's answer to Question 1. The ADR text is the **same for A and for C**
because it names no mod and covers one or more mods; A and C differ only in what the build-order
task file then says (one mod or two). For **B** nothing is written.

## Amendments
### ADR-0001 (`docs/decisions/0001-platform-is-the-goal.md`)
Line 16: the sentence beginning "The roguelike is the first modpack" currently reads:

> The roguelike is the first modpack and the reference implementation that drives the kernel API from real needs.

It is read as:

> The reference implementation that drives the kernel API from real needs is the mod (or are the mods) named in the current build-order task file; the roguelike remains a planned mod and is no longer fixed in this role.


### ADR-0050 (`docs/decisions/0050-build-order-walking-skeleton.md`)
- Line 17 currently reads:

  > **Step 1 — first real roguelike feature:** "on level-up, three upgrade cards are offered": a new record type, a server hook, RPC, a client panel, persistence, observability.

  It is read as: "**Step 1 — first real feature of the reference mod:** one feature that needs a
  new record type, a server hook, RPC, a client panel, persistence and observability. The feature
  is named in the reference mod's own task file, not in this ADR."
- Line 28 currently ends: "8. Breadth, driven by the roguelike." It is read as: "8. Breadth,
  driven by the reference mod(s) named in the build-order task file."

### Metadata lines added on acceptance (headers only; no other edit to either file)
- `docs/decisions/0001-platform-is-the-goal.md`, after the `Related:` line:
  `- **Amended by:** ADR-0123 (the driving reference mod is named by task file, not fixed to the roguelike)`
- `docs/decisions/0050-build-order-walking-skeleton.md`, after the `Related:` line:
  `- **Amended by:** ADR-0123 (step 1 and step 8 name "the reference mod", not the roguelike)`
- Also on acceptance (mechanical, not ADR substance): add ADR-0123 to the index in
  `docs/decisions/README.md`; regenerate `docs/decisions/INDEX.json` (the generator reads the
  headers, `docs/tools/adr-index.md`).

## Consequences
- The build order's first real feature and its driving mod are chosen in a task file, so a later
  change needs no ADR.
- No ADR contains party-mod rules, names or art; the design document is the only home for them.
- The roguelike is **assumed** (marked assumption) to stay a planned mod. Nothing in this proposal
  cancels it.

## Impact
Only the two ADRs above are amended (sentences with file:line given above). Checked per file with
a context read (task log, 2026-10-28):

**Unaffected, because they cite the roguelike as an example, as history or as inherited lessons,
not as a platform rule:** ADR-0001:9, :12, :13 (history and options); ADR-0009:15 (example
conflict message); 0015:17 (a performance test the roguelike would provide); 0022:18 (future user
of `replace`); 0044:9 (roguelike packaging is a roguelike design decision); 0050:18 (the old M0
server stays as reference and fallback); 0050:24 (read the existing guides first); 0052:13
(playerbots give solo roguelike players party members); 0054:9 (existing guides are read first);
0083:7 (driver-mod list); 0091:7 (daily-seed bonus); 0102:7 (SOAP proven by the roguelike
project's ops scripts); 0112:24 (claimant list); 0114:7, :17, :32 (driver-mod list; character
lifecycle named as the roguelike's blocker, which stays true for the roguelike whenever it is
built; example automation); 0115:1, :5 (title and source of the inherited lessons).

**Exceptions: these ADR lines DO give the roguelike a platform-level role.** They are not amended
by this proposal (the manager's instruction was "only 0001 and 0050"); Ludwig decides whether a
follow-up is wanted if the answer is A or C:
1. ADR-0051:16 — "Reference mod: the roguelike is written as the complete, commented example; every
   API function is used there." (a documentation/DX rule that names the roguelike.)
2. ADR-0113:14 — example chain level (c), "the roguelike as the large example (ADR-0051)".
3. ADR-0097:1, :7 — "The roguelike design kit is re-audited ... before step 1" (a gate on step 1
   that assumes the roguelike is the step-1 mod).
4. ADR-0098:15 — the repo-layout comment "mc:* core mods + roguelike (reference mod)".
5. ADR-0115:44 — "The reference mod v17 will be English-commented"; v17 is the roguelike kit
   (ADR-0097:7), so this line assumes the roguelike is the reference mod.
Also: ADR-0001:19 ("design kit becomes the specification of the first mod") and the title of
ADR-0001 (line 1) still say "first mod" = roguelike; the amendment note in the header is what a
reader sees (titles of accepted ADRs are never edited).

**The arcade driver mod.** ADR-0114:7 names three driver mods: roguelike, housing, arcade. The
arcade mod already pulls teams (ADR-0114:20), match abort on restart (ADR-0114:24) and group
teleport and player-state snapshot (`docs/open-questions.md:23-24`); the party mod's minigames
need the same surfaces. Whether the two share code is open (design doc h.3a) and is Q5.

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
step-1 feature. Your party mod could be just another standalone mod, or take over that driving
role.
- **A ★** The party mod becomes the reference/first mod. Amend only the sentences above; the
  roguelike stays planned. Consequence: platform work is pulled by the party mod's needs
  (instancing, groups, overlays, UI) first; combat and character-lifecycle surfaces wait. Resting on
  assumption until you answer: nothing is written to the ADRs.
- **B** The party mod is simply a mod; the roguelike stays reference and vertical slice. No ADR
  change; this proposal is void. Consequence: the party mod is built when its dependencies on
  the platform exist, which the roguelike's order may delay.
- **C** Both are reference mods, party first, roguelike second. The same ADR text as A; the
  build-order task file names both. Consequence: two sets of platform needs are tracked; slightly
  more process, no loss of either.
Lean: A, because you called it the first mod and the party mod stresses the few-friends
multiplayer surfaces (ADR-0002:13, :16). Note that the audience is "mostly single-player", so Q2
(bots) decides whether most users can play it at all. B is equally valid, since mods are standalone.

### Q2 (changes the design doc, section e)
Should bots fill empty seats when fewer than the maximum players are present? Options:
- A. No bots in version 1; 2-4 humans only. Consequence: you cannot test alone with one client.
- B ★ Board-only bots (they roll, pick up and carry lanterns, choose forks; in minigames they get a
  simulated score drawn from a distribution; with a bot seated only free-for-all and duel
  minigames are drawn). Consequence: solo play and testing work; no real bot play in minigames.
- C. Full bots in minigames too. Consequence: large extra work per minigame.

### Q3 (changes the design doc, sections b and e)
Player count. A. 2-4 players ★ (small groups, ADR-0002:13). B. up to 6. C. up to 8.
Consequence: more players mean more minigame categories to rebalance, a different number of lit
lanterns and longer games.

### Q4 (changes the design doc, section b)
Default game length: A. 10 rounds (about 30 min). B. 15 rounds ★ (about 45 min). C. 20 rounds
(about 60 min). All are settings anyway (ADR-0029:9); this only sets the default and what the
pacing numbers are tuned for.

### Q5 (changes the design doc, sections h.3a and c.5)
The ADRs plan an arcade driver mod (ADR-0114:7) that needs teams, zones, countdowns and match abort
(ADR-0114:20, :24), which the party mod's minigames also need. Should the two be related?
- **A ★** Separate mods that both build on the platform's surfaces. Consequence: some duplicated
  minigame plumbing; each mod stays standalone, as you asked.
- **B** The party mod's minigame layer becomes the arcade mod (or the arcade mod is a minigame
  pack for it). Consequence: less duplication, but the arcade mod then depends on the party mod.
- **C** Decide later. Consequence: nothing changes now; the design assumes A.

## Interacts with
ADR-0001, ADR-0050 (amended); ADR-0051, ADR-0097, ADR-0113, ADR-0098, ADR-0115 (exceptions above,
not amended); ADR-0044 (modpacks: the party mod ships as one standalone mod; unaffected).
