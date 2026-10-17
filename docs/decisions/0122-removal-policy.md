# ADR-0122: Removal policy for published versions — grounds, files, installed copies, appeals

- **Status:** Proposed
- **Date:** 2026-10-17 · **Area:** Registry / Legal / Launcher
- **Touches:** registry, registry/takedown, launcher/resolution, launcher/update, site/content-rules
- **Related:** ADR-0037, ADR-0041, ADR-0046, ADR-0121
- **Amends:** — (none declared; see Open question Q1)

## Context
Four accepted decisions touch the removal of a published version, and read together they leave gaps:

- ADR-0041:15 — authors "cannot remove versions"; "Only legal grounds (Blizzard assets, stolen code) lead to
  **removed**: artefacts pulled, registry entry kept with status and reason so dependency resolution can explain the
  failure."
- ADR-0046:27 — removed content is Blizzard data, illegal content, and "**known malicious code** — defined narrowly as
  matching a published signature/advisory *or* confirmed by reproduction"; suspicion and heuristics "produce
  **warnings only**"; "Every removal has a public reason and can be appealed."
- ADR-0037:45 — flagging is badge, author notification and launcher warning; "**Never automatic unpublishing.**"
- ADR-0121:79 — `published → removed` is "the existing takedown (ADR-0041), unchanged"; ADR-0121:121-122 states that it
  adds no author-initiated way to remove a version.

What was not stated anywhere: whether ADR-0046's malware/illegal-content grounds feed the ADR-0041 takedown
(ADR-0041:15 names only legal grounds), what happens to the files and to already-installed copies, and what an appeal
produces. Task 073 surveyed the repository for this; its result is summarised in the mission log
(`docs/tasks/MISSION-worldofmodcraft-site-v1-log.md`, section "Removal policy — brainstorm and Ludwig's decision,
2026-10-17"). Ludwig's answer there, verbatim: **"Option A for all"**, applied to the manager's per-item reading
(items 0-5 below; Ludwig may correct any line).

## Options considered
The survey's per-item options are recorded in the task 073 report and are not reproduced here. Ludwig chose Option A
for every item; the alternatives are therefore not restated, and no reason for rejecting them was given in the log.
(Open question Q8.)

## Decision
This ADR decides items 0-5 of the mission log section named above, and nothing else.

0. **Owners cannot remove published versions.** This restates ADR-0041:15; it adds no new rule. The decision records
   that any pull request that sets a version to `removed` is a takedown, not an ordinary change, so an owner cannot
   obtain removal by mixing it into another change.
1. **Grounds for a takedown.** A takedown (`published → removed`, ADR-0121:79) may be made on legal grounds, as
   ADR-0041:15 states, **or** for known malicious code or illegal content as ADR-0046:27 defines them narrowly.
   Suspicion, heuristics and permission combinations remain warnings only (ADR-0046:27), not grounds.
2. **Files of a removed version.** They stop being served publicly. The registry entry, the hash, the signature and the
   reason are kept permanently. This is consistent with ADR-0041:15 ("artefacts pulled, registry entry kept with
   status and reason").
3. **Already-installed copies.** On its next registry update the launcher warns the user and shows the reason. For
   malware (ADR-0046:27) it also offers to disable the mod. It never deletes silently (ADR-0037:45 states the
   no-automatic-unpublishing principle for health flags; Ludwig applied the same "never silent deletion" rule here).
4. **Appeals.** ADR-0046:27 says a removal "can be appealed". A successful appeal results in a **new version**. A
   removal is final; there is no un-remove.
5. **Recorded intention, not a decision now:** an author-set per-version "don't use this one" mark (version stays
   installable, users are warned) for authors with a broken release. Ludwig: later, not now. Nothing in this ADR
   specifies or implements it.

## Consequences
- ADR-0041:15 and ADR-0046:27 become one mechanism: the takedown is the single route to `removed`, with two kinds of
  ground. `ownership.md`, `append-only.rules.md` and the registry checker must say so; those contract changes are
  separate tasks (mission log, "Next session starts here — addendum", items 6-8) and are not part of this ADR.
- "Files stop being served" and "registry entry kept" fit ADR-0041's chain (ADR-0041:17): a launcher that still holds
  the entry can verify the signature on the entry and report why a download is gone.
- Launcher behaviour in item 3 requires a registry-update path that surfaces `removed` status and reason for
  installed mods; its current state was not verified for this ADR.
- No un-remove means a mistaken takedown is repaired only by a new version.

## Open questions (not decided here)
- **Q1.** Does item 1 amend ADR-0041:15 ("Only legal grounds")? If yes, on acceptance this ADR needs an `Amends:
  ADR-0041` header and `Amended by` metadata on ADR-0041 (README, ADR rules for amendment); the ADR-0041 file is not
  edited by this draft.
- **Q2.** Who confirms a malware ground ("confirmed by reproduction", ADR-0046:27), and who may initiate a takedown?
  (Ludwig's R11 answer in the mission log mentions a takedown-only account under his control with his written
  approval per takedown; that is a separate contract task, not decided here.)
- **Q3.** How "stop serving" is done on GitHub Releases, where the archive lives (ADR-0041:14), including the
  planned protection rule on `worldofmodcraft/archive`; and the effect on the Software Heritage copy
  (ADR-0041:14), which this platform cannot remove.
- **Q4.** What counts as "illegal content" in item 1 beyond the words of ADR-0046:27, and in which jurisdiction.
- **Q5.** What is the appeal procedure, who decides, and within what time? (ADR-0046:27 says only "can be appealed".)
- **Q6.** Dependants: what a resolver does when a dependency is `removed` (ADR-0041:15 says only that resolution "can
  explain the failure").
- **Q7.** How the launcher learns of a removal for a mod the user never updates, and what "disable" means for a mod in
  a running server.
- **Q8.** Whether Ludwig wants the rejected alternatives from the task 073 report recorded in "Options considered".

## Interacts with
ADR-0037 (never automatic unpublishing; flags are warnings), ADR-0041 (takedown, statuses, archive; possibly
amended, Q1), ADR-0046 (content rules, appeal), ADR-0121 (`published → removed` is its T2 transition, unchanged by
this ADR).
