# Task 046 — A transferable handover of how we develop, for another AI assistant

- **Status:** spec-approved
- **Repo:** platform
- **Date:** 2026-09-10
- **Approved by:** Ludwig, in session, 2026-09-10
- **Effort budget:** small (≤ 1 agent-session; executed by the manager, see Notes)
- **Type:** documentation

## Objective

Produce markdown Ludwig can hand to ChatGPT/Codex (or any other assistant) so it can work the way
this project works, **without** needing this repository's history or this conversation's context. The
audience is an AI assistant and its human operator, on **any** software project — not only World of
Modcraft.

## Scope

`docs/handover/` — an index, the method, the failure catalogue, the environment notes, the brief-writing
guide.

**Scope amended 2026-09-10** (Ludwig, in session, same sitting): add `00-start-here.md`, a front door for
an assistant handed the *complete* rulebook — the constitution, the doctrine tree and all ~120 decision
records — rather than only the method summary. It states which layer binds the reader, and **which of the
decision records transfer to another project and which are product-specific and must not be adopted**.
Recorded as an amendment rather than folded in silently, per MANAGER.md §3.3.

## Out of scope

- Changing any doctrine (`CLAUDE.md`, `docs/manager/*`). This task *summarises and generalises*; if
  it finds doctrine wrong, it reports rather than edits.
- Project-specific contracts, ADRs, or mission content beyond what an example requires.

## Acceptance criteria

1. A reader with no access to this repo's history can apply the method: every rule states **what to
   do**, and the incident that earned it, in a form that transfers to another codebase.
2. Every lesson is traceable to something that actually happened here. **No invented war stories** —
   if a claim is general principle rather than observed, it says so.
3. The environment file separates **what is specific to this machine** from **what is a general
   hazard** (e.g. "a file written by every session cannot be trusted" is general; the path is not).
4. Nothing is cited that does not exist (MANAGER.md §8b.5). Paths named are on disk at commit time.
5. It is honest about cost and about what failed: the process described has produced five fix rounds
   on a single contract. That is reported, not hidden, so a reader can judge the trade.

## Notes

**Executed by the manager rather than delegated, deliberately.** Two reasons, both recorded because
§3 normally sends doc writing to an agent: (a) the content is a distillation of one long session's
judgement, most of which is in the manager's context rather than on disk, so a fresh agent would
reconstruct it worse; (b) the session was in token-guard UNKNOWN at the time (a new day, no usage
figure yet), which bars delegation but explicitly permits non-delegating writing.
