# ADR-0115: Lessons inherited from the roguelike project — amendments to existing decisions

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Observability / Kernel / Process
- **Amends:** ADR-0020, ADR-0023, ADR-0034, ADR-0035, ADR-0040, ADR-0051, ADR-0052, ADR-0065, ADR-0106
- **Source:** the WoW Roguelike project's field-verified documentation (CLAUDE.md 14 rules, design/15 debugging + measurement standard, design/16 Claude integration, design/19 with 18+ verified platform deviations A1–A20, VERSIONS.md, living-docs mechanics). Everything below was paid for in real debugging sessions, 2026-08-12 → 2026-08-23.

## 1. Measurement standard → amends ADR-0034 (observability contract)
Five bugs in one day were hidden not by bad code but by **bad counters** (procs reported "84 damage" while dealing zero — the platform discarded it; splash reported hits while damaging the player herself). Every counter in the kernel and in the generated observability surfaces MUST follow:
1. **Measure outcome, never intent** (read target health before/after; check `AddItem`'s return; diff the resource — never count what we *asked for*).
2. **Show inputs, not just outputs** (impossible otherwise to distinguish "computed correctly on wrong data" from "computed wrong").
3. **Count every silent early return, with reason** ("it works but nobody was in range" must look different from "it is broken").
4. **Summarise reasons** so questions are answerable after the fact ("12 kills gave 0 threat — grey mob: 11, critter: 1"), not only greppable in the moment.
5. **Bookkeeping next to reality**: wherever the kernel keeps its own register, display our figure beside the reconciled ground truth (the one system that did this from day one never lied).
This standard also enters ADR-0113's guides ("counters done right") and is a review question for every ring-2 surface.

## 2. Restore-before-save write barrier → amends ADR-0023 (KV or gone)
Reload empties memory while the database is full; a save inside that window overwrites a player's data with emptiness (observed: a mid-session reload silently removed a player's bonuses; a save in the gap deleted a life). The companion rule to "KV or gone" is therefore **kernel-enforced**: the persistence API refuses writes for a mod until that mod's restore phase has demonstrably run after (re)load. Per-mod discipline is not enough — the barrier lives in the kernel.

## 3. Crash-proof evidence and log defaults → amends ADR-0035, ADR-0106
The platform can kill the process in ways no pcall catches (a core call exiting 0 with no message; a query against a missing table → `>> ABORTED`), and truncate-on-start logging destroyed the evidence of the very crash that needed it. Therefore, as kernel **defaults**: append-mode logging with size caps and per-line timestamps (never truncate-on-start); the recent-events buffer memory-mapped to survive process death (already ADR-0093 — this is its field proof); container/OS logs documented as the last-resort evidence source.

## 4. Guarded database layer → amends ADR-0020 (ring 1 persistence)
A single query against a not-yet-created table took the whole server down — twice, the second time from the test tool itself. The kernel's persistence/query surface makes the fatal path **impossible for mods**: schema existence is guaranteed by the migration lifecycle before any mod code can query, and any dynamic query path validates against `information_schema` and reports UNCERTAIN instead of executing a potentially fatal statement.

## 5. Namespaced loader → amends ADR-0020 (mod runtime)
A file named `combat.lua` silently prevented `trees/combat.lua` from loading (380 tree nodes vanished); a file named `debug.lua` can never load at all (stdlib collision) — consequences of a flat, basename-keyed module registry. The kernel loader keys modules by **mod id + path**; basename collisions across mods or with any standard library are structurally impossible. (The incident also proves the doctor culture: an integrity check caught the missing tree within a minute — kernel world-start validation, ADR-0034's compiler checks, serves the same role.)

## 6. Kernel-owned event semantics → amends ADR-0020 (ring 2)
Two costly semantic traps: a range query answering from the *called object's* perspective (the wolf's enemies = the player), and kill hooks not firing for what a temp-summon kills — the game's core loop silently losing kills. Kernel events and query APIs carry **defined, documented, kernel-guaranteed semantics**: the kernel kill event includes summon kills by definition; spatial queries state their perspective in the signature; the IDL documentation of every event states exactly when it fires and does not.

## 7. Test tools must not be able to kill the server → amends ADR-0052
"A test tool that can take the server down is more dangerous than no tool at all." `modcraft test`, the smoke tests, and every diagnostic command use the guarded paths of §4; a check that cannot verify safely reports UNCERTAIN rather than executing. Additionally (from the summon investigation): **a question a human cannot answer truthfully does not belong in a manual test — it must be measured.** The simulated player exists for exactly this.

## 8. Boundary type discipline → amends ADR-0065 (IDL)
64-bit values crossing the Lua boundary as userdata *look* like numbers until arithmetic, formatting or table-keying silently fails (userdata keys never match). The IDL type system defines int64 handling **once at the boundary** (explicit conversion, documented range guarantees); no API returns a value whose type differs from its declared IDL type.

## 9. Validation additions → amends ADR-0040/0051 (validate)
From A16 (a `local` declared after its use becomes a silent global, dormant until a rare code path runs): `modcraft validate` includes a Lua globals/lint pass (undeclared globals, module-level locals below first use). From A12 (async DB writes): the persistence API makes read-after-write either impossible or explicit — never a silent stale read.

## 10. Debugging doctrine → constitution input (with ADR-0054)
Field-proven rules that enter the constitution when it is written: the diagnostic **order** (status → recent errors → doctor/self-checks → logs → state dump → *then* hypothesis — "never guess before seeing the data"); **run the tools yourself** — never ask Ludwig to paste logs or run commands the agent can reach (the SOAP/ops loop is ADR-0102's ancestor, verified closed 2026-08-12); the **probe/bisect pattern** (step-wise probe commands on an empty world to bisect process-killing calls — the only way to find what pcall cannot catch); deliberate version pinning with "latest master is not a version" (field proof of ADR-0048/0101); and the living-docs Definition of Done including the rule that **anything built but unprovable without a live session gets an explicit TODO row** — "built" and "works" must never blur.

## Note on language
The roguelike project comments in Swedish (its reader is Ludwig); World of Modcraft is English throughout (ADR-0056). The reference mod v17 will be English-commented — confirmed as the platform's choice.

## Consequences
Each amended ADR gains an "Amended by: ADR-0115" header line. The measurement standard, write barrier, guarded queries, namespaced loader and event-semantics guarantees are kernel requirements testable in the skeleton phase; §10 flows into the constitution task.
