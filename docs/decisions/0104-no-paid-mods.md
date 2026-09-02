# ADR-0104: No paid mods; funding links welcome

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Site / Policy
- **Related:** ADR-0040, ADR-0046, ADR-0049

## Decision
Stated policy, not accidental silence: **no paid mods, no paywalls, no "premium versions" via the site.** Content rule added: mods whose function is locked behind payment elsewhere ("free demo here, full version on my Patreon") are rejected — the platform distributes whole works. Donation/sponsor links are allowed and visible: `funding = {...}` in the manifest (FUNDING.yml-style), rendered on the mod page. Rationale: the open-source requirement already chose this side; writing it out prevents the community's most poisonous conflict class (Skyrim paid-mods wars, Minecraft EULA fights). Forgone marketplace revenue is zero real cost for an AGPL hobby project with a handover goal.
