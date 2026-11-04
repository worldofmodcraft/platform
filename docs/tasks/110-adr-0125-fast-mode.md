# Task 110: ADR-0125 — fast mode until phase two (manager merges green work and decides on ★; Ludwig keeps takedowns and secrets)

- **Mission:** none (governance) — **Status:** spec-approved 2026-11-04 (manager, session 14; Ludwig's decision, verbatim in the mission log 2026-11-04: "...du får
  mergea allt som blir grönt självt utan min input? Samt att utgångspunkten är att du tar stjärna på alla förslag (men loggar allt i vault)? ... tills vi kommer till
  fas två och ska börja med server / client"; exceptions chosen: "Takedowns, Nycklar och hemligheter")
- **Agent / model:** doc-writer — **Budget:** small
- **Branch / worktree:** `task/110-adr-0125-fast-mode` / `~/wt/task-110` (platform)

## Deliverables
1. `docs/decisions/0125-fast-mode-until-phase-two.md` (TEMPLATE.md shape; Status Accepted 2026-11-04; Area Process/governance; Related ADR-0054, ADR-0099, ADR-0116,
   ADR-0122): **Decision:** until the first phase-two mission (server/client work) is issued, (1) the manager merges any task whose verification and review are green
   without asking Ludwig — this includes CI security checks, signing/keys *code*, doctrine, mission specs and `docs/decisions/`; (2) on every question the manager
   takes the ★ option itself (including accepting new or changed ADRs and mission-scope changes) instead of asking; (3) every such decision is logged in the mission
   log (projected to the vault) the same day, with the options and why ★; (4) **exceptions that stay Ludwig's:** takedowns (ADR-0122; MANAGER.md §7 absolute stop) and
   anything touching credentials, tokens, secrets or private keys (CLAUDE.md rule 11); also unchanged: the absolute stop conditions of MANAGER.md §8 and the forbidden
   shortcuts; (5) **expiry:** the day the phase-two mission spec is issued, or earlier when Ludwig revokes it in writing; on expiry all retained rules apply again.
   Quote Ludwig verbatim in Context. Consequences: faster cycles; Ludwig reads decisions after the fact in the vault; the verification and review gates stay.
2. Time-bound notes, retaining the existing rule text (the token-guard suspension pattern): `CLAUDE.md` (the "asking beats assuming" section and rule 4/the merge
   wording if present) and `docs/manager/MANAGER.md` §2 (stop-and-ask list), §3.1 (ADRs are law: new ADR needs Ludwig), §7 (merge authority), §8 (two stop-and-ask
   events halt), §8b (Ludwig's pile): one short paragraph each, starting "**Until phase two (ADR-0125):** ...", stating what is lifted and what stays (the exceptions).
3. `docs/decisions/README.md` index line; regenerate INDEX.json (`python3 tools/adr/build_index.py --write`).

## Acceptance criteria
1. `python3 tools/adr/build_index.py --check` CHECK OK; `python3 -B -m unittest discover -s tests/adr` OK.
2. Every retained rule text unchanged (diff shows only added lines in CLAUDE.md and MANAGER.md, plus the new ADR, README, INDEX.json, this file).
3. The exceptions (takedowns; credentials) appear in the ADR and in each note.
4. No `*-verify.sh` run by the agent; the manager runs every platform verify script on the head before merge (several read CLAUDE.md/MANAGER.md).

---
# Task 110 log
- 2026-11-04 manager (session 14): created on Ludwig's decision; dispatched.
