# 01 — The method

How work flows, who may do what, and what counts as done. Every rule here was paid for; the failures
themselves are in `02-lessons.md`.

---

## 1. Roles: one orchestrator, a flat roster, no middle layer

**The orchestrator (the main AI session) writes no production code.** It reads, decomposes, specifies,
delegates, reviews, merges and reports. That single constraint is what keeps the project steerable:
the moment the orchestrator starts implementing, it stops having the context to judge what comes back.

- **Its context is the scarcest resource in the system.** Subagents exist to protect it. Bulk reading,
  surveys, boilerplate, well-specified implementation and doc writing all get delegated — not because
  the orchestrator can't, but because reading 40 files into the window that must stay clear for
  judgement is how a project derails.
- **Flat roster.** Specialised agents (implementer, reviewer, debugger, test-writer, doc-writer,
  surveyor) all sit at the same level. Add a layer only when it produces something no existing layer
  can; *coordination and summarisation do not qualify.*
- **Parallel work = parallel orchestrators**, side by side under the same doctrine, never one
  orchestrating the others.

**Role separations that are not negotiable:**

| Rule | Why |
|---|---|
| **Author ≠ reviewer** | An author reviewing their own work checks whether it matches what they meant, which is the one thing that was never in doubt. |
| **Finder ≠ fixer** | The agent that proves a bug exists has an interest in its diagnosis being right. A separate fix, separately reviewed, removes that. |
| **Tests are read-only for implementers** | An implementer may *add* tests, never weaken or delete one. Changing a test to make code pass is its own task, reviewed as such. |

---

## 2. The spec gate: no work without a task file

Lifecycle: `draft → spec-approved → in-progress → review → done | stopped`.

**No agent starts a task whose file is not spec-approved.** The file carries: objective, scope,
explicit out-of-scope, acceptance criteria, effort budget, and dependencies.

The rule that matters most, and the one everyone wants to skip:

> **A direct instruction from the human supplies approval, never exemption.** When they ask for
> something, the correct response is a short task file *and then* the work — never the work and then a
> note about it.

Approval and specification are different functions: the human supplies the first, the file supplies
the second. They are not substitutes. The one time this was skipped here, the ceremony was thinnest
exactly where reversibility was lowest — a public repository and a history rewrite went through with
less process than a two-line documentation fix.

**Sizing:** a task that cannot plausibly finish inside one agent's context window is mis-scoped.
Split it *before* delegating, never mid-panic. Declare an effort budget (small ≤ 1 agent-session,
medium ≤ 3, large ≤ 6); **exceeding it means stop and report** — a budget overrun is information
("this was mis-scoped"), not something to push through.

**Before a project's first implementation task,** draw the dependency graph: nodes are components,
and *every boundary edge names its contract*. Ordering then falls out topologically, and genuine
parallelism is visible as disjoint subgraphs instead of guessed at.

---

## 3. Verification is a runnable artefact, not a transcript

**This is the single highest-value rule in the document.**

Any task whose acceptance criteria are command-based ships a committed, executable verification
script (`verify-<task>.sh` or equivalent). The agent runs it and pastes *its* output into the task
log; the reviewer and the orchestrator **re-run the same script and diff**.

> Nothing in a log that claims a command's output is trusted unless the script that produced it is on
> disk and re-runnable.

**Why this exists, concretely:** on one task here, three separate log entries recorded command output
that the command *cannot produce* — a `grep` with an alternation that basic `grep` reads literally
(returning nothing), a quoted match for a string that spans a line break, and a hit count that did not
match its own paste. The claims all happened to be true. They were *asserted, not demonstrated*, and
no amount of care caught them, because catching them required re-running every line by hand.

The point is not that the model lies. The point is: **make being wrong detectable by construction
rather than by vigilance.**

### The five rules of a verification artefact

1. **A search that finds nothing is a broken search, never a clean result.** A check whose pattern
   matches zero lines must *fail*. One sweep here "passed" by returning nothing at all.

2. **The artefact must be able to fail, and that must be demonstrated.** Mutation-test it: break the
   thing each check claims to check, and show the check turn red. A 28-check script here stayed fully
   green while a deletion verdict was flipped from "always a violation" to "never", while a
   uniqueness clause was deleted, and while the test suite itself was broken — three checks that could
   not fail, one of them guarding a previous review's own finding.
   > **A check that cannot fail is worse than no check, because it manufactures confidence.**

3. **A label that names several things must fail when any one of them is missing.** Those false greens
   were regex alternations behind labels that read as conjunctions ("A and B present" implemented as
   `A|B`). Split them. And beware the half-fix: one "split" here produced two *weaker* checks, each
   matching a bare common string across a 174-line section.

4. **Portable and deterministic, and proven somewhere other than the machine that wrote it** — a fresh
   clone, not the authoring directory. One script passed only where it was written, because committed
   bytecode happened to match that filesystem's timestamps.

5. **A suite is judged by the breaking cases it contains, not the count it passes. Every fix round
   adds the found break as a fixture *before* the fix.** Rule 2 says the artefact must be *able* to
   fail; this says *which* failures it must contain, and when they are written:
   - Write the fixture first. **Show it red.** Then fix. Then show it green. A log showing only the
     final green is not evidence.
   - **A fixture that would have passed against the broken code proves nothing.** Put the defect back
     and watch the new fixture redden before believing it guards anything.
   - **Keep positive controls beside the breaking cases.** A suite of only hostile fixtures can score
     perfectly by rejecting everything — the same manufactured confidence as a check that cannot fail.
   - A round that closes a finding and reports only a larger green total **has destroyed the evidence
     that the finding was ever real.** The number went up and nothing remembers what went wrong.

**Scope note:** this applies to command-based criteria. Visual (a screenshot), external (a live CI
run) or human ("the owner approves") criteria are recorded as they always were — but the log says
**plainly which criteria are script-verified and which are not**, so no reader mistakes the second for
the first.

---

## 4. Claims about the world

Two rules, and the second exists because the first was abused.

**(a) The caveat travels with the claim.** No spec or contract states an environmental fact without
either a verification command shown or an inline caveat marking it unverified — **at the point the
claim is made.** Not in a "could not verify" section at the bottom: the next implementer reads the
contract *without* its log, so a caveat that lives only in the log does not reach the person it exists
to protect.

The caveat marks the **basis** of a rule, never softens the rule: *"this is required; this is why we
believe it; that belief is untested here"* — never *"this might be required"*.

**(b) A caveat where a command was available is a missing check wearing caution's clothes.** If a
document makes a claim about a tool's behaviour and **the tool is on this machine, run it.** Two
claims here were not folklore and not unverifiable — they were simply wrong, and each took under a
minute to falsify:

- A document stated that a signature format's key-id hex was the blob's key-id bytes "in the same byte
  order". It is the **reverse**. Because the same document's rules reject a signature whose key-id
  does not match those bytes, **a verifier built from that text would have rejected every correctly
  signed artefact the platform produces.**
- Another recommended `git archive` and claimed it names the archive root after the ref. Plain
  `git archive` produces no root at all — which the same document elsewhere rejects as malformed.

And the one that closed the loop, five rounds into a contract: a paragraph asserted that *"the
platform's own identity is the organisation that owns every reserved namespace, so such a PR normally
satisfies this rule outright."* A GitHub organisation **is not a member of itself** (`404`, one
command). The consequence chain made the platform unable to perform a legally-mandated takedown in its
own namespaces — the exact capability the rule existed to create.

---

## 5. Review: adversarial, independent, and expected to find things

Every completed task branch is reviewed against a written checklist before merge, by an agent that did
not author it, **at the same model tier or higher than the work.**

A review brief should say, in these words or their equivalent:

> Assume there is something. If you conclude otherwise, your report must state **what you did that
> would have caught a defect had one existed** — a clean verdict from a review that could not have
> failed is worth nothing.

**A review report has a fixed shape**, and each part earns its place:

- **Verdict: PASS or BLOCKING**, unambiguous, first line.
- **Numbered blocking findings, each with the reproduction that proves it.** A finding without a
  reproduction is an opinion.
- **Non-blocking findings, separately.**
- **What was verified as correct** — including every mutation run and what reddened. This is how
  coverage becomes visible, and it is what lets the next round avoid re-deriving settled facts.
- **What could not be verified, and why, marked as such.** Never quietly dropped. Items that cannot be
  resolved in this environment (e.g. needing a second identity) **stay marked, not settled.**
- **If blocking: a fix brief specific enough to dispatch without further analysis.**

**Re-run everything the log quotes, and diff.** A quoted result you did not reproduce is not evidence.
(In one review here, ten of eleven command transcripts reproduced byte-for-byte; the eleventh was the
finding.)

### Two-strike escalation

An agent that fails the same acceptance criterion twice is **stopped**. The orchestrator may escalate
**once**: a stronger model *and* an improved spec — in that order of importance, because **most
failures are spec failures**, and a stronger model with the same bad spec buys the same
misunderstanding at a higher price. If the escalated attempt also fails, **work stops and the human is
asked.** Never a silent third attempt with the same approach.

This is not a formality. Here, the escalated round also failed review, work stopped, the human was
asked, and round four then ran *on his decision* rather than on the orchestrator's momentum. Recording
whose decision a round runs on is part of the point.

---

## 6. Isolation: files, and also measurements

**The file part (standard):** all work happens in a git worktree on a task branch. Main is reachable
only by reviewed merge (enforced by branch protection, including for administrators). One task, one
branch, one worktree, one log. A derailed agent can at worst ruin its own branch.

**The part almost nobody has:** *a test suite and a shared directory are resources too.*

> **No two agents run against the same suite, worktree, or shared tree concurrently.** Sequence them,
> or give each a private clone — and name each agent's scratchpad directory explicitly in its brief.

Earned in one afternoon, three ways:

1. A review reported a suite failing **3 of 4 runs** and raised it as a blocking finding. An isolated
   re-measurement — ten runs, fresh clone each, gated so none overlapped — got **0 of 10.** The
   difference was other agents of the same session running the same suite.
2. A fix round then dismissed its own final failure as "the known flake" — while the measurement agent
   was running. Same error, opposite direction.
3. Two agents shared one scratchpad and one clobbered the other's clone mid-review.

And a subtler axis: a check that measures a *shared home directory* is perturbed by every running
agent (transcripts, caches, rotating backups). For that check, isolation means **no other agent
alive**, not merely no second run of the suite.

> **A measurement taken under contention is not evidence.** Re-measure in isolation before acting on,
> or propagating, any finding that could be an artefact of load.

---

## 7. Context discipline

**State lives on disk; context is cache.** Every task keeps a log — done / remaining / decisions with
reasons / open issues — continuously, such that *any* agent can resume from the log alone.

- **Agents:** past ~60 % of context, finish the current sub-step, update the log, **end the run.**
  Continuation is a fresh agent reading the log — **a handover by file, never a handover by summary
  from a tired context.**
- **The orchestrator, with a large window:** 60 % is too late, because recall degrades long before the
  arithmetic threshold. Use **30 % soft** (at the next natural boundary — a step finished, an agent
  reporting back — do a deliberate handover; *start no new tasks*) and **40 % hard** (wrap up
  mid-step if necessary).
- **Never rely on auto-compaction.** If it fires anyway, treat the session as **untrusted for
  operational detail** and verify against disk before acting on anything remembered. A summariser
  keeps narrative and drops exactly the operational detail that causes false verifications.

**The handover procedure:** (a) bring every open task log to a resumable state; (b) write a session
status in the project log — done / in progress / blocked on the human / next steps — and append fresh
gotchas to the operations file; (c) verify with `ls` and `git status` that everything cited exists and
is committed; (d) tell the human it is handover time and give them **the exact line to paste into the
fresh session.**

> **A session with no written status did not happen.**

---

## 8. Budget guard (adapt the numbers; keep the shape)

The human's subscription is shared with their own work, so headroom for them is a hard constraint, not
a courtesy.

- **Halt at 90 %** of the binding window (whichever of the rolling windows is most constrained):
  launch nothing new, let running agents write their logs and end at their current sub-step, write the
  session status, stop.
- **Resume only below 50 %** — never in the 50–90 % band. The hysteresis is deliberate.
- **Check at session start, before every delegation, after every report-back, and before any large
  operation.** Log the reading every time.
- **If usage cannot be determined, treat it as above 90 %.** Unknown means stop, and ask.
- **No self-exemption.** Only the human lifts it, explicitly, for a specific moment.

Two things this taught that generalise past quota:

- **The metering source must be one you can trust.** Ours wrote to a file that *every* running session
  overwrote, so an idle session's frozen numbers reappeared with a fresh timestamp — and **the stale
  reading was systematically the lower one**, failing in the only direction that matters. Resampling
  does not fix it: sampling detects disagreement between writers, never one writer that is simply
  wrong. **Fix the writer or change the source.**
- **Our own test suite poisoned that file.** A fixture proving the parser accepts a *healthy* usage
  line wrote a *low* number into the live file the guard reads — i.e. the test suite could silently
  lift a real halt. Note the direction: the unsafe one.

---

## 9. Question discipline

**Agents book questions; the orchestrator triages; the human decides only what only they can decide.**

1. Code-touching agents **do not interrupt** for questions. They record them in the task log: what is
   unclear, options seen, which option was *assumed* to keep working, and what was built on that
   assumption. Exception: genuinely blocking questions (cannot proceed, or proceeding risks violating a
   decision or damaging data) stop the run immediately.
2. **Assumptions are loans, not decisions.** Everything resting on one is marked, so a different answer
   later knows exactly what to redo. An unmarked assumption found in review is a checklist failure.
3. The orchestrator triages at every report-back: **answer it itself** when the answer follows
   unambiguously from the spec or the written rules (and write the answer into the task log, citing the
   source); **escalate** anything that would create or reinterpret a decision, change scope, or trade
   cost against quality; **reject** questions already answered in material the agent should have read —
   the answer is a pointer, and repeats signal a documentation gap.
4. The human's pile is **decision material, not a question dump**: two sentences of context, options
   A/B/C with consequences, the orchestrator's lean marked ★, and what currently rests on assumptions.
   Bundle at natural pauses; flag urgent items immediately.
5. **Nothing is cited unless it exists.** No status names a file or artefact that is not on disk at
   that moment — and unmerged work is cited as `branch:path` with the command to view it, since most
   work is invisible on the main branch. Retroactive records are allowed but **always marked
   "retroactive"**, so they cannot be mistaken for a spec that gated anything. *A ledger row claiming
   work it never gated is worse than a missing row: it makes the ledger unusable.*
6. **Unanswered questions never accumulate silently.** Past a threshold (we use five), new tasks that
   depend on them pause. Every answer is fed back into the task log — and into a written decision when
   the answer is principled — so no question is asked twice.

---

## 10. Decisions are law, and live in files

Architectural decisions go in numbered, dated, immutable records (one file per decision). Two, and
only two, ways to change the record: **supersede** (new record; old one's status updated, substance
untouched) or **amend** (new record naming what it amends, plus a back-reference added to each
affected record's header). Cross-reference metadata is the *only* thing ever added to an accepted
record.

No agent — including the orchestrator — edits those files except to add a new record the human has
approved. A conflict between a task and a decision **halts the task**.

Two corollaries that cost us rounds:

- **A decision that lives in prose but not in the logic is not a decision.** A ruling was written into
  a contract's text while the contract's *rules* still rejected the thing it authorised. The review's
  phrase for it is worth keeping.
- **Rules earned by an incident should carry the incident.** "Don't do X" is forgettable; "don't do X,
  because on this date it caused Y" survives a handover and stops the next person re-litigating it.

---

## 11. Forbidden shortcuts — reject on sight

- A `TODO` or stub where an error belongs.
- Extension-based checks where content/magic-byte checks were specified.
- An acceptance criterion marked done without demonstration.
- Code changed without its documentation, in the same branch.
- Catching and ignoring errors.
- `--force` anything. (And: **rewriting history on a pushed branch is forbidden** — it requires
  `--force`. On an unpushed branch it is allowed, and must be logged with what changed and what was
  verified unchanged. The window in which a rewrite is free closes at the first push, and that ordering
  must be a *decision*, never luck.)
- Disabling a linter or a test to make something pass.
- **Anything that creates or changes a remote, publishes anything, or rewrites history is at minimum a
  small spec-approved task, however trivial it looks.**
