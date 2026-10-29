# Task 097: survey of `github.com/satypardus/wowdecomp` (a WoW client decompilation) — fit for a 64-bit client

- **Mission:** none (research for Ludwig; outside SITE-V1 scope, reads only) — **Status:** done 2026-10-28 (spec-approved by the manager, session 14; Ludwig's direct request "Under tiden kan du kika lite på det här: https://github.com/satypardus/wowdecomp — 64-bit client vore guld värt för det här projektet")
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
- 2026-10-28 general-purpose agent: survey written to `docs/research/wowdecomp-survey.md` (Facts F1-F18 with URLs, Technical fit, Legal and ADR fit covering 0004/0005/0007/0027/0049/0055/0057/0062/0118, Options A★/B/C, Unverified). Method: GitHub HTML pages, raw.githubusercontent.com files and web search, all unauthenticated. The REST API returned "rate limit exceeded" for every call, so repo metadata comes from the HTML pages. Nothing cloned, built or run; no code copied. Key finding: Blizzard Wow.exe 12340 decompilation, x64 main target, Windows only, no licence; WoWee is already 64-bit, so the 64-bit gain is not a gap for us. Criterion 1 met; criterion 2: only the report and this task file changed.
- 2026-10-28 manager (session 14): report read; key claims spot-checked by the manager with WebFetch (§3.6c): WoWee README "Linux, macOS and Windows
  on x86-64 and ARM64, and Android on arm64"; wowdecomp page "A C++ decompilation of the World of Warcraft 3.3.5a client (`Wow.exe`, build 12340,
  June 2010)", "x64 is the main target", no licence shown. Decision ★ A (watch only; read none of its code; never link, ship or depend on it),
  reported to Ludwig in the morning summary. **Done.**
