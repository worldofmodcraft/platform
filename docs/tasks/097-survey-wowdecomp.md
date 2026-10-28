# Task 097: survey of `github.com/satypardus/wowdecomp` (a WoW client decompilation) — fit for a 64-bit client

- **Mission:** none (research for Ludwig; outside SITE-V1 scope, reads only) — **Status:** spec-approved 2026-10-28 (manager, session 14; Ludwig's direct request "Under tiden kan du kika lite på det här: https://github.com/satypardus/wowdecomp — 64-bit client vore guld värt för det här projektet")
- **Agent / model:** general-purpose (web access needed; surveyor has none) — **Budget:** small
- **Branch:** `session/14` (platform); output `docs/research/wowdecomp-survey.md`

## Objective
A survey report Ludwig can decide from: what the repository is (client version, scope, completeness, build status, activity, licence, authorship/provenance), whether and how it could give World of Modcraft a 64-bit client, and how it stands against ADR-0004, 0007, 0027, 0049, 0055, 0057, 0062, 0118 and the project's legal exposure (decompiled proprietary code in an AGPL, public platform).

## Method and limits
Read-only, through the GitHub web/API (README, licence, tree, issues, commit history, linked docs). **Do not clone, build or run anything from it; copy no code into this repo** (quotes ≤ a few lines for evidence, with URL). Every claim cites its URL or is marked unverified (MANAGER.md §3.6, 6b). No credentials (rule 11): unauthenticated requests only.

## Acceptance criteria
1. `docs/research/wowdecomp-survey.md` exists with sections: Facts (each with source URL), Technical fit (64-bit, relation to WoWee/our fork and 3.3.5a protocol), Legal and ADR fit (each named ADR addressed), Options for Ludwig (A/B/C with consequences, lean ★), Unverified.
2. No file other than that report and this task file changes.

---
# Task 097 log
- 2026-10-28 manager (session 14): created from Ludwig's request; dispatched.
