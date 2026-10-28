# Task 098: ADR proposal — the first mod becomes an original party board game (replaces the roguelike as vertical slice)

- **Mission:** none (decision record; outside SITE-V1) — **Status:** spec-approved 2026-10-28 (manager, session 14; Ludwig's direct instruction, verbatim: "En sak till, vet att rogue like mod är satt som en ”vertical slice” som första mod, men vill att den första modden ska vara en Mario Party-liknande mod där man går omkring på ett spelbräde och samlar stjärnor och spelar mini games med andra spelare")
- **Agent / model:** doc-writer — **Budget:** medium (scope extended the same evening, see log)
- **Branch / worktree:** `task/098-first-mod-party-board` / `~/wt/task-098` (platform)

## Objective
A **proposed** ADR that Ludwig can accept as written or adjust, plus an impact analysis. Nothing under `docs/decisions/` is created or edited (MANAGER.md §3.1: only an ADR Ludwig has approved is added). The decision itself is Ludwig's (stated above); the task records it faithfully and works out its consequences.

## Context to load
- `docs/decisions/README.md` (rules for supersede/amend; template `TEMPLATE.md`).
- ADRs naming the roguelike or the vertical slice: find them with `grep -il roguelike docs/decisions/*.md` and `grep -il "vertical slice" docs/decisions/*.md` (at least 0001, 0050, 0097, 0115); plus 0002 (audience), 0004 (own assets), 0024 (instancing), 0061 (AI assets), 0104; `docs/open-questions.md`, `docs/design/` files that mention the roguelike.

## Deliverables
1. `docs/tasks/098-proposed-adr.md`: the full ADR text in TEMPLATE.md shape, number = next free ADR number (derive it), status `Proposed`, an explicit `Supersedes:` and/or `Amends:` list per the README rules, and for each affected ADR the exact metadata line that would be added on acceptance. The game is described as an **original** party board game in the genre (board, movement, stars, minigames, small-group multiplayer); no third-party names, characters, art or iconography (ADR-0004); "Mario Party" appears only as the genre reference in Context, quoting Ludwig.
2. In the same file, an **Impact** section: every ADR, design doc, open question and mission/task file that names the roguelike or vertical slice, with what changes (supersede / amend / unaffected, one line why); kernel/API surfaces the new first mod exercises (e.g. instancing, multiplayer sessions, turn state, minigame loading) versus what the roguelike exercised, and what is no longer exercised early (stated plainly, not softened); whether the roguelike stays as a later mod (★ yes, second; marked as assumption).
3. A **Questions for Ludwig** section (MANAGER.md §8b shape: two sentences of context, options A/B/C with consequences, ★ lean) — only questions whose answer changes the ADR text. At most five.

4. **Design document** (Ludwig, 2026-10-28, verbatim: "Ge mig ett detaljrikt designdolument för det tills imorgon, sparas i vault"): `docs/design/party-board-mod.md`, status line `Draft — rests on the proposed ADR in docs/tasks/098-proposed-adr.md; not accepted`. Detailed, written for Ludwig (strong general computer knowledge, limited coding experience: explain terms once). Sections at least: (a) vision and the player's evening, start to finish; (b) core rules: board, turn order, dice/movement, spaces and their effects, currency, stars and how they are bought/moved, items, events, end of game and scoring, bonus awards; (c) minigames: categories (free-for-all, 2v2, 1v3, co-op), the minigame lifecycle, at least 10 original minigame concepts each with goal, controls and length, and how a minigame is itself a small mod-defined unit; (d) boards: at least two original board themes with layout ideas; (e) multiplayer and sessions: 2-4 players (bots fill empty seats? — a question), lobby, joining, disconnects, pacing and timers; (f) presentation: camera, UI, audio, all original assets (ADR-0004, 0061); (g) **technical design on our platform**: which ADR-defined surfaces it uses (records, Lua, instancing 0024, chat commands 0082, overlay rendering 0083, audio 0084, kernel.rng 0091, config 0029, permissions 0028, observability 0034, save/KV 0023/0074, clientmods 0110, etc. — each with ADR file:line), what the server and the 3.3.5a client must do, a data model sketch (records/KV keys), turn state machine, and every gap where the platform has no surface yet (stated as gaps, not invented APIs); (h) what it proves as the vertical slice (ADR-0050) and what it no longer proves early compared with the roguelike; (i) build order in walking-skeleton steps; (j) risks and open questions (cross-referenced to the ADR proposal's questions). All names, characters and iconography original; "Mario Party" only as the genre reference, quoting Ludwig. No claim about a platform surface without its ADR file:line; anything the ADRs do not settle is marked **[design proposal]** or **[open]**.

## Acceptance criteria
1. The files above exist; `git diff --name-only origin/main...HEAD` lists only `docs/tasks/098-*` and `docs/design/party-board-mod.md`.
2. Every ADR found by the two greps appears in the Impact section (the agent pastes the grep output in the log).
3. No claim about an ADR's content without its file:line.

---
# Task 098 log
- 2026-10-28 manager (session 14): created from Ludwig's instruction; dispatched to doc-writer.
- 2026-10-28 manager (session 14): scope extended by deliverable 4 (design document) on Ludwig's second instruction; budget small -> medium. Vault: the doc is copied into the vault by the manager after merge (the projection has no Design/ notes yet; follow-up task booked).
