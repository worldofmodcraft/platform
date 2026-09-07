# Task 043 — A test suite is a shared resource: no concurrent agents against one suite

- **Status:** spec-approved
- **Repo:** platform (`worldofmodcraft/platform`)
- **Date:** 2026-09-07
- **Approved by:** Ludwig, in session, 2026-09-07
- **Effort budget:** small (≤ 1 agent-session)
- **Type:** doctrine

## Objective

Add a standing rule to `docs/manager/MANAGER.md`: **a test suite is a shared resource. No two
agents run against the same suite or the same worktree concurrently — sequence them, or give each
a private clone.** This extends §3b (flat roster) and §6 (worktree isolation) from *file* isolation
to *test execution* isolation, which today proved to be a separate axis.

## Why — the evidence, all from 2026-09-07

Worktree isolation stops two agents corrupting each other's files. It does **not** stop two agents
corrupting each other's *measurements*, and this session produced two instances plus a near-miss:

1. **A review's central finding was an artefact of contention.** The adversarial review of task 023
   rounds 4-5 reported the suite failing 3 of 4 runs on a `/exit` probe check and raised it as
   blocking finding R3-B1. An isolated re-measurement — ten runs, each from its own fresh clone of
   the same commit, gated so no two runs overlapped — reproduced that failure **0 times in 10**.
   Every leftover `wom-test-probelaunch-*` tmux session that blocked the gate belonged to a
   concurrent foreign run out of the shared worktree. Working hypothesis, with converging evidence
   but not a demonstrated cause: **the suite collides with itself when run concurrently.**
2. **A fix round dismissed its own final failure as "the known out-of-scope flake"** — while the
   measurement agent was running the same suite. That dismissal is unsafe for the same reason, and
   the guard must be re-run in isolation before task 023 reaches a PR.
3. **Two agents shared one scratchpad and one clobbered the other's clone mid-review**, costing the
   reviewer its claim to an idle machine for three of four runs.

A second, subtler axis appeared with them: **task 023's section-17 guard measures the `~/.claude`
tree, and every running agent writes there** (transcripts, caches, rotating backups). For that
check the shared resource is not the suite but the home directory, so "isolation" means no other
agent alive — not merely no other run of that suite.

**The manager's own error is part of the record:** the contention in instances 1 and 2 was created
by the manager dispatching parallel agents against one suite, and the resulting finding was then
propagated into two further briefs as established fact before an independent measurement corrected
it. The rule exists so the next manager does not have to rediscover this from a wrong finding.

## Scope

- `docs/manager/MANAGER.md` — the rule, placed with §6 (worktree isolation) or §3b, cross-referenced
  from whichever it does not live in.
- `docs/manager/OPERATIONS.md` — a pointer to the rule beside the existing session-writes gotchas.

## Out of scope

- Any change to `tools/test-supervisor.sh` or task 023's suite (that is task 023's own work).
- Any change to the agent roster, `ROUTING.md`, or worktree setup mechanics.

## Acceptance criteria

1. The rule states plainly that no two agents run against the same suite or worktree concurrently,
   and names the two permitted resolutions: **sequence them**, or **give each a private clone**.
2. It names **both** axes with their evidence: suite-level collision, and checks that measure a
   tree every running agent writes to (`~/.claude`).
3. It states the consequence for evidence: **a measurement taken under contention is not evidence**,
   and a finding derived from one is re-measured in isolation before it is acted on or propagated.
4. It cites the 2026-09-07 instances above, in one or two sentences each, so the rule is not
   mistaken for caution in the abstract.
5. Ludwig reviews and merges it as doctrine's reviewer (per the task 042 precedent); the manager
   does not merge it.

## Notes

Doctrine tasks are reviewed by Ludwig himself — the manager writes and delegates, he merges.
