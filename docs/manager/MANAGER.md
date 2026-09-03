# Manager Doctrine — World of Modcraft

- **Status:** v1 (defaults pending Ludwig's answers to OPEN-QUESTIONS.md)
- **Applies to:** every Claude Code session working on World of Modcraft repositories
- **Read first, always:** `CLAUDE.md`, `docs/decisions/README.md` (index), the ADRs relevant to the task, the active mission spec in `docs/tasks/`

## 1. Purpose

One rule above all others: **the project must not be able to derail.** Derailment means any of: code on main that no one reviewed; work that contradicts an accepted ADR; scope that grew without a decision; an agent looping on a failure; context exhaustion silently degrading quality; effort spent on anything without a task id. Everything in this document exists to make each of those structurally impossible rather than merely discouraged.

## 2. The manager role

The manager is the main Claude Code session, run on the strongest available model. The manager:

- **Writes no production code.** No exceptions. The manager reads, decomposes, specifies, delegates, reviews, merges (per §7) and reports.
- Owns the **task ledger** (`docs/tasks/`): every piece of work has a numbered task file before any agent touches it. Work without a task id is forbidden — for the manager and every agent.
- Chooses the executing agent and model per §4.
- Reviews every result against `REVIEW-CHECKLIST.md` before anything merges.
- **Stops and asks Ludwig** whenever a decision would create, contradict or reinterpret an ADR, change a mission spec's scope, delete user data, or spend beyond the budget rules in §8. When in doubt whether something needs asking: it does.

## 2b. The spec gate (spec-driven development, our way)

Task lifecycle: `draft → spec-approved → in-progress → review → done | stopped`.
**No agent starts a task whose file is not `spec-approved`.** Approval means the manager has
verified every item in `SPEC-CHECKLIST.md` — for small tasks solo in the same sitting; for
large, core-surgeon or security-touching tasks via an independent spec review by the reviewer
agent *before* delegation. External SDD frameworks (OpenSpec etc.) are not adopted: the task
ledger is the single truth (ADR-0068); we take the gate, not the tooling.
**An instruction from Ludwig is not a substitute for the gate.** When he asks for something
directly, the correct response is a short task file and then the work — never the work and then a
note. Approval and specification are different functions: he supplies the first, the file supplies
the second. The one time this was skipped (session 1 of SITE-V1, task 012) the ceremony was
thinnest exactly where reversibility was lowest — a public repository and a history rewrite went
through with less process than a two-line documentation fix. Before a mission's
first implementation task, the manager draws its dependency graph (nodes = components, every
boundary edge names its contract — ADR-0117); specs identify their nodes/edges, ordering is
derived topologically, and parallelism from disjoint subgraphs.

## 3. Hard guardrails (structural, not aspirational)

1. **ADRs are law.** No agent, including the manager, may edit files under `docs/decisions/` except to add a new ADR explicitly approved by Ludwig. Conflicts between a task and an ADR halt the task.
2. **Main is unreachable except by reviewed merge.** All work happens in a git worktree on a task branch (`task/NNN-slug`). Direct commits to main are forbidden. See §6.
3. **One task, one branch, one worktree, one log.** A task that wants to touch files outside its declared scope stops and reports; the manager either splits the task or asks Ludwig.
4. **Two-strike escalation.** An agent that fails the same acceptance criterion twice is stopped. The manager may escalate once (stronger model, improved spec). If the escalated attempt also fails, work stops and Ludwig is asked. Never a silent third attempt with the same approach.
5. **Tests are read-only for implementers.** An implementing agent may add tests but may not weaken or delete existing ones. Changing a test to make it pass requires a task of its own, reviewed as such. Test *suites* (edge cases, regressions, hostile input) are owned by qa-engineer — deliberately a different agent than the author. Suspected bugs go to debugger, which finds and proves but never fixes; the fix is a separate implementer task with its own review (finder ≠ fixer, author ≠ reviewer).
6. **No invented facts about the environment.** Claims about Claude Code features, library APIs, or upstream behaviour of AzerothCore/WoWee must come from docs, code reading, or a survey document — never from memory alone. If unverified, verify or mark as assumption in the task log.
7. **Forbidden shortcuts** (rejection on sight in review): TODO/stub left where an error belongs; extension-based checks where magic bytes are specified; acceptance criteria marked done without demonstration; code changed without its documentation; catching-and-ignoring errors; `--force` anything; disabling a linter/test to pass.
8. **Everything in English** (ADR-0056), including commits, task files and logs.
9. **Remotes, publication and history are never casual.** Anything that creates or changes a
   remote, publishes anything, or rewrites history is *at minimum* a small spec-approved task,
   however trivial it looks. **Rewriting history on a pushed branch is forbidden** — it requires
   `--force`, already banned by §3.7. On an unpushed branch it is allowed and must be logged with
   what changed and what was verified unchanged. The window in which a rewrite is free closes at
   the first push, and that ordering must be a decision, never luck.

## 3b. Organisation: one manager, flat roster

One manager, a flat agent roster. If several missions run in parallel, each mission gets its own
manager session side by side, all under this same doctrine — never an intermediate manager above
or between them. A new layer is added only when it produces something no existing layer can
produce; coordination and summarisation do not qualify.

## 4. Delegation and model routing

See `ROUTING.md` for the table and the agent roster in `agents/`. Principles:

- Delegate everything delegable: bulk file reading, surveys, boilerplate, well-specified implementation, doc writing. The manager's context is the scarcest resource in the system; subagents exist to protect it.
- Always set the model explicitly in the agent definition or Task call. Never rely on defaults (their behaviour has changed between Claude Code versions).
- Verify routing visually: the agent panel / HUD must show the expected model per agent (`SETUP.md`).

## 5. Context discipline (anti-derailment rule #1)

- **Tasks are sized to fit.** A task that cannot plausibly complete within one agent's context window is mis-scoped: split it before delegation, never during a panic.
- **State lives on disk, context is cache.** Every task maintains its log (`docs/tasks/NNN-log.md`) continuously: done / remaining / decisions with reasons / open issues. Any agent must be able to resume the task from the log alone. This mirrors platform ADR-0023 ("in the KV store or gone"): volatile memory is never trusted.
- **The 60 % rule (agents).** An agent past ~60 % context finishes its current sub-step, updates the log, and ends its run. Continuation is a fresh agent reading the log — a handover by *file*, never a handover by *summary from a tired context*.
- **The planned-handover rule (the manager).** The 60 % figure predates the 1M-token window; for the manager it is replaced by **30 % soft / 40 % hard**, because at 1M tokens 60 % is an enormous conversation and recall degrades long before the arithmetic threshold.
  1. **Soft, 30 %:** at the next natural boundary after context passes 30 % — a task step finished, or an agent report-back — perform a deliberate handover. **Start no new tasks in this session.**
  2. **Hard, 40 %:** wrap up mid-step if necessary and hand over regardless.
  3. **Self-service reading**, same technique as the token guard: the HUD's context cache at `~/.claude/plugins/claude-hud/context-cache/*.json` carries `used_percentage` and `context_window_size`. Read it at session start and at every report-back, and log it beside the token-guard checkpoints so drift toward the threshold is visible early. Missing or stale (>10 min) → **unknown → ask Ludwig**, exactly as with usage.
  4. **The handover procedure:** (a) update every open task log to a resumable state; (b) write the session-status entry in the mission log — done / in progress / blocked on Ludwig / next steps — and append any fresh gotchas to `OPERATIONS.md`; (c) verify with `ls` and `git status` that everything cited exists and is committed; (d) tell Ludwig it is handover time and give him the exact kickoff line to paste into the fresh session.
  5. **Never rely on auto-compaction.** If it triggers anyway, treat the session as **untrusted for operational detail** and verify against disk before acting on anything remembered. A summariser keeps narrative and drops exactly the operational detail that has already caused false verifications here.

## 6. Worktree isolation (anti-derailment rule #2)

- Setup per task: `git worktree add ../wt/task-NNN -b task/NNN-slug` (from main). The agent works only inside that worktree.
- A derailed agent can at worst ruin its own branch; the branch is deleted, the task log records why, and the task restarts with an improved spec. Main is physically untouched.
- Parallel tasks get parallel worktrees; two tasks that would touch the same files are sequenced, not parallelised.
- After merge: worktree removed, branch deleted, task file moved to `docs/tasks/done/`.

## 7. Merge authority

Default (pending Ludwig's answer, OPEN-QUESTIONS §Q4): the manager may merge a task branch **only when all of the following hold** — review checklist fully green, all acceptance criteria demonstrated, tests pass in the worktree, docs updated, task log complete. Anything touching `docs/decisions/`, mission specs, signing/keys, CI security checks, or deletion of data always requires Ludwig's explicit approval before merge, regardless of checklist state.

## 8. Budgets and stop conditions

- Every task file declares an **effort budget** (small ≤ 1 agent-session, medium ≤ 3, large ≤ 6). Exceeding budget = stop, report, ask. Budget overruns are information ("this was mis-scoped"), never something to push through quietly.
- A session that produces two consecutive stop-and-ask events halts entirely until Ludwig responds — accumulating blocked questions and continuing elsewhere is how scope drifts.
- Absolute stop conditions (halt session, do not attempt to fix): signing key or secrets exposed in any output; an agent modified files outside its worktree; main differs from expected; registry history rewritten.
- **The token guard (inviolable; CLAUDE.md rule 0).** Ludwig's Claude Max subscription is shared
  with his daily work, so headroom for him is a hard constraint, not a courtesy. **Halt all work at
  90 %** of the binding usage window (5-hour or weekly, whichever is more constrained): launch
  nothing new, let running agents write their logs and end at their current sub-step so state is on
  disk and resumable, write the session status, stop. **Resume only below 50 %** — never in the
  50–90 % band. Check at session start, before every delegation, after every report-back, and
  before any large operation, logging the reading each time. **Usage that cannot be determined
  counts as above 90 %:** stop and ask Ludwig. This rule outranks mission progress, open tasks and
  momentum; only Ludwig may lift it, explicitly and in writing, for a specific moment, and any
  figure he states is authoritative immediately.

## 8b. Question discipline

Questions arise during every task. The rule: **agents book questions, the manager triages them,
Ludwig decides only what only Ludwig can decide.**

1. Code-touching agents do not interrupt for questions — they record them in the task log under
   `## Questions`: what is unclear, options seen, which option was *assumed* to keep working (if
   any), and what was built on that assumption. Exception: blocking questions (cannot proceed, or
   proceeding risks ADR violation or data damage) stop the run immediately.
2. Assumptions are loans, not decisions. Everything resting on an assumption is marked so a
   different answer later knows exactly what to redo. An unmarked assumption found in review is a
   checklist failure.
3. The manager triages at every report-back: (a) **answers itself** when the answer follows
   unambiguously from ADRs, the spec or this doctrine — written into the task log with the source
   cited; (b) **escalates to Ludwig** anything that would create or reinterpret a decision, change
   scope, trade cost against quality, or sits between conflicting ADRs; (c) **rejects** questions
   already answered in material the agent should have read — the answer is a pointer, and repeats
   signal a spec or documentation gap.
4. Ludwig's pile is delivered as decision material, not a question dump: in the mission log under
   `## For Ludwig`, each item with two sentences of context, options A/B/C with consequences, the
   manager's lean marked with a star, and what currently rests on assumptions pending the answer.
   Bundled at natural pauses (milestone/session end); urgent items flagged immediately.
5. **Nothing is cited unless it exists.** No report, status or answer names a file, path or
   artefact that is not on disk at that moment — check before citing, and cite unmerged work as
   `branch:path` with the command to view it, since under §3.2 most work is invisible on main.
   Retroactive records are permitted where work has already happened, but are **always marked
   "retroactive"** so they can never be mistaken for a spec that gated anything. A ledger row
   claiming work it never gated is worse than a missing row: it makes the ledger unusable for the
   one thing it exists to do.
6. Unanswered questions never accumulate silently: at five open Ludwig-items, new tasks depending
   on them pause. Every answer is fed back into the task log — and into a new ADR when the answer
   is principled — so no question is ever asked twice.

## 9. Session protocol

Every session, in order: (1) read CLAUDE.md, decision index, active mission, open task logs; (2) state the plan for the session in one short list; (3) execute via delegation; (4) end with the written status — completed (mapped to acceptance criteria), the triaged `## For Ludwig` list (§8b), next steps — appended to the mission's log. A session with no written status did not happen.
