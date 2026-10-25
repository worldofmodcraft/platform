# ADR-0122: Removal policy for published versions — grounds, files, installed copies, appeals

- **Status:** Accepted (2026-10-17, accepted by Ludwig)
- **Date:** 2026-10-17 · **Area:** Registry / Legal / Launcher
- **Touches:** registry, registry/takedown, launcher/resolution, launcher/update, site/content-rules
- **Related:** ADR-0037, ADR-0041, ADR-0046, ADR-0121
- **Amends:** — (see "Amendment of ADR-0041 on acceptance")

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
Ludwig chose Option A for every item (mission log, 2026-10-17). The alternatives, as summarised from task 073, with no
further reasons given in the log:
- Owners may remove their own versions. Not chosen; it conflicts with ADR-0041:15.
- Delete the bytes of a removed version. Not chosen; item 2 keeps entry, hash, signature and reason, and stops serving.
- Keep serving a removed version with a warning. Not chosen; item 2 stops serving.
- Appeal restores the removed version (by Ludwig). Not chosen; item 4: a successful appeal means a new version.

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

## Answers recorded 2026-10-17
Ludwig answered "Stjärna på alla" (the manager's lean on each question):
- **Amendment of ADR-0041 on acceptance.** Item 1 widens the grounds clause of ADR-0041:15 ("Only legal grounds").
  On acceptance, ADR-0041's header gains `Amended by: ADR-0122` for that clause; this draft does not edit ADR-0041.
- **Who confirms a malware ground.** Ludwig decides each case; agents gather the evidence.
- **Illegal content.** Swedish and EU law plus GitHub's terms.
- **Appeal procedure.** By issue or email; Ludwig decides; no formal deadline.
- **Dependants of a removed version.** Resolution fails with an explanation, as ADR-0041:15 provides.
- **Deferred: how "stop serving" is done** on GitHub Releases / the archive (ADR-0041:14), including the Software
  Heritage copy. To be decided in a later task once the pipeline tasks 008b/008c are live.
- **Deferred: how the launcher learns of a removal** for a mod the user never updates, and what "disable" means on a
  running server. Belongs to the launcher design.
- **Options considered:** recorded above.

## Interacts with
ADR-0037 (never automatic unpublishing; flags are warnings), ADR-0041 (takedown, statuses, archive; its grounds
clause is amended on acceptance), ADR-0046 (content rules, appeal), ADR-0121 (`published → removed` is its T2 transition, unchanged by
this ADR).
