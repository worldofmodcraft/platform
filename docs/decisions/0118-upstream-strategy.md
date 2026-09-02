# ADR-0118: Upstream survival strategy — thin patch surface, drift radar, contribute back

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Process / Forks
- **Touches:** client, server, process/merges, ci
- **Amends:** ADR-0063, ADR-0064
- **Related:** ADR-0062, ADR-0098, ADR-0099

## Decision
1. **Thin patch surface (80 % of the protection).** Merge pain is proportional to overlap
   between our edits and upstream churn. Therefore: the kernel lives in `kernel/` (zero
   conflict by construction); our changes inside WoWee/AC code are thin hooks calling into the
   kernel, never logic spread through their files; new files over edited files. Every touched
   upstream file is recorded in the core-surgeon's merge-debt ledger with its reason — the
   ledger *is* the measure of future merge cost, and review may reject changes that grow the
   footprint needlessly ("can this be a hook + kernel code instead?").
2. **Drift radar.** A weekly scheduled CI job performs a trial `git subtree pull` in a
   throwaway branch: reports conflict count and build status, touches nothing. The cost of the
   next real merge is known continuously; drift explosions trigger a deliberate decision
   (merge early, or freeze until the phase ends) instead of a milestone surprise.
3. **Merge as a recipe** (extends the ADR-0064 task): surveyor (cheap tier) summarises
   upstream changes since last merge against the merge-debt ledger → conflicts resolved in a
   dedicated worktree → both sides built, full CI, smoke tests, simulated player, green doctor
   → only then main. Milestone-gated timing unchanged: before phases, never mid-phase.
4. **Two relief valves.** (a) Contribute back: fixes that are not WoM-specific are PR'd
   upstream — every accepted fix is a diff we stop carrying forever. (b) The freeze right
   (ADR-0064) stands, and grows cheaper with time: WoWee approaches feature-completeness for
   3.3.5a, and its 1.12/2.4.3 work is noise that merges cleanly since we never touch those
   areas (ADR-0062).
