# Task 086: survey — which ADRs would trip a browser (web) client of World of Modcraft

- **Mission:** none (exploratory; Ludwig's idea, 2026-10-26) — **Status:** spec-approved (manager, solo gate, 2026-10-26)
- **Repo:** platform (read-only). **Agent / model:** surveyor. **Budget:** small (≤ 1 agent-session)
- **Output:** `docs/research/web-client-adr-survey.md` is NOT written by the surveyor (read-only); the report comes back to
  the manager, who records it in the mission log. Nothing is decided by this task.

## Source
Ludwig, 2026-10-26: a browser client (WebAssembly build of the forked WoWee client) that both **streams content** and
**caches assets locally** when the site loads; an online server with a "Find Group"/server browser that spins up instances
with the mods a custom game needs (WC3-custom-games style: "World of WarParty", "World of RogueLike"); the offline/desktop
version stays. "We ignore the legal aspect for now and focus on the technical." "Do nothing with this without my approval."

## Objective
Read **every** ADR in `docs/decisions/` (index: `docs/decisions/README.md`, `INDEX.json`) and report which ones a web client
would conflict with, constrain, or need amended — technical traps only (legal/asset-licensing questions are out of scope by
Ludwig's instruction; list them in one line each only if an ADR's *technical* mechanism depends on them). Also list ADRs that
already *support* the idea. Areas to check at minimum: client architecture and the WoWee fork, rendering/graphics API,
file system / MPQ / DBC access, mod format and loading (Lua, libmodcraft kernel ABI, plugins/native code), sandboxing and
signing/verification, launcher and `modcraft://` protocol, networking (TCP vs WebSocket/WebTransport), server/instance model,
matchmaking/lobbies, telemetry, caching/updates, offline mode, platform/OS assumptions, performance budgets.

## Acceptance criteria
1. Every ADR file was opened (the report states the count read vs the count in `INDEX.json`).
2. Each finding quotes the ADR with `file:line` and says: conflicts / constrains / needs amendment / supports — and why,
   technically.
3. A short list of "cheap now, expensive later" design choices the current plan could keep web-friendly.
4. No file is written; nothing is decided.

---
# Task 086 log
- 2026-10-26 manager: written from Ludwig's request; read-only survey.
