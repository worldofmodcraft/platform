# START HERE — the rules we work by

**Read this first. It tells you what the other files are and how they bind you.**

You are being handed the complete rulebook of a working software project: a constitution, an
operating doctrine, and a 120-entry decision log. The ask is not "have a look at these". The ask is:
**work this way.** Rule-based development, with the agent model described below.

---

## 1. What you have, in three layers

| Folder / file | What it is | Authority |
|---|---|---|
| `doctrine/CLAUDE.md` | **The constitution.** ~10 universal rules that always apply, plus a pointer to the decision index. Deliberately under a page — that is the condition for it actually being read. | Binding, always. Read it fully, every session. |
| `doctrine/MANAGER.md` + the other `doctrine/` files | **The operating doctrine.** How work flows: roles, the spec gate, verification, review, merge authority, budgets, question discipline. `REVIEW-CHECKLIST.md`, `SPEC-CHECKLIST.md`, `TASK-TEMPLATE.md`, `ROUTING.md` (which model does what), `OPERATIONS.md` (hard-won environment facts), `agents/*.md` (one file per agent role). | Binding for process. |
| `decisions/` | **The decision log.** ~120 numbered, dated, **immutable** records. One decision per file. `README.md` is the index; `INDEX.json` is the machine-readable version. | Architectural law. A conflict between a task and a decision **halts the task**. |
| `01-method.md` … `04-prompting.md` | The same system written as a **transferable method**, with the incidents that earned each rule. | Read these to understand *why*; read the above to know *what*. |
| `ALL-IN-ONE.md` | The four method documents concatenated, for pasting into a chat. | Convenience copy. |

---

## 2. The most important thing to understand about the decision log

**Most of those 120 records are about a specific product** — a modding platform for a particular game:
Lua dialects, asset formats, server internals, licensing. **Do not try to adopt those.** They are
included so you can see the *form* a decision record takes and how densely they cross-reference.

**What transfers is the process subset.** If you adopt nothing else from `decisions/`, adopt these:

| Record | The principle |
|---|---|
| **ADR-0117** | **Dependency graph before code; every edge names its contract.** Nodes are components, never files. Every edge crossing a component boundary names its contract. An edge without a contract is an architecture error with exactly two fixes: define the contract, or merge the nodes — it was not a real boundary. Specs then identify the node/edge they implement and may touch no other; a new dependency requires updating the graph **first**. Ordering becomes topologically derived; parallelism is visible as disjoint subgraphs. |
| **ADR-0116** | **Compliance in five layers, strongest first.** Every decision that *can* become a mechanical gate *becomes* one — "an agent that never read the rule still cannot break it". Then: the task file lists exactly which decisions it touches; review is **bidirectional** (the listed rules are followed, **and** the diff touches nothing whose rules were not listed — a selection miss is the orchestrator's error, caught in review); a machine-readable index makes the selection mechanical; and the constitution carries only the universal rules plus the pointer. |
| **ADR-0079** | **Contract first.** The contract is published and versioned in the repo *before* the thing that implements it exists. |
| **ADR-0050** | **Walking skeleton plus one vertical slice.** The whole structure on day one, the entire API surface defined up front with explicit `NotImplemented: <name> — tracked in #N` where depth is missing. The framework's *shape* is complete; depth is filled in. A first step that has no feature value but proves every layer end to end. |
| **ADR-0054** | **Documentation first; survey before code; the manager model.** And the underrated half: **rules must be checkable, not aspirational** — "`print` is forbidden and rejected by the validator", never "log carefully". |
| **ADR-0103** | **Prefer the boring, restartable, predictable solution; cleverness must be earned by a demonstrated need.** "A restart costs almost nothing; a clever hack costs trust." |
| **ADR-0115** | **Measure outcomes, never intent** (counters read reality — state diffed, return values checked, silent early returns counted with reasons) and **never guess before seeing data** (status → errors → self-checks → logs → state dump → *then* hypothesis). |
| **ADR-0080** | **Compute on observation.** Where the result is observably identical, compute state when it is read rather than simulating it continuously. |
| **ADR-0068** | **The task ledger is files in the repo — the only truth.** Specs and logs version with the code; a branch carries its own spec and log in the same diff. Dual bookkeeping is rejected as sync-rot; any board tool is an *interface* over the files, never a second truth. |

### How to use 120 records without reading 120 records
That is the whole point of the index. Each record's header carries a `Touches:` line (paths/topics).
The orchestrator looks up the topics a task touches, lists *those* records in the task file, and the
executing agent reads only those. **Knowledge in files, selection by the orchestrator.** Never load
the whole log into a working context.

### The record format, and why it is immutable
Each record has: Status, Date, Area, Touches, Related, Context, Options considered, Decision,
Consequences. Two — and only two — ways to change the record:

- **Supersede:** write a new record; set the old one's status to `Superseded by NNNN`. The old file's
  substance is never edited.
- **Amend:** write a new record naming what it amends, **and** add a back-reference line to each
  affected record's header.

Cross-reference metadata is the only thing ever added to an accepted record. This gives you a silent
sixth compliance layer: **because records are never edited, an agent's knowledge can never be
*wrong* — only incomplete.** Incompleteness is caught by bidirectional review; wrongness cannot occur.

---

## 3. The agent model, concretely

This is the part to copy operationally.

**One orchestrator, a flat roster of specialised agents, no middle layer.**

- **The orchestrator writes no production code.** It reads, decomposes, specifies, delegates,
  reviews, merges, reports. The moment it starts implementing, it loses the context it needs to judge
  what comes back. **Its context is the scarcest resource in the system** — subagents exist to protect
  it, so bulk reading, surveys, boilerplate and well-specified implementation are all delegated.
- **Roles:** implementer, reviewer, debugger (finds and proves, never fixes), test-writer,
  doc-writer, surveyor, plus a strong tier for security-relevant or core work. One file per role in
  `doctrine/agents/`. **Set the model explicitly per role; never rely on defaults.**
- **Separations that are not negotiable:** author ≠ reviewer; **finder ≠ fixer**; implementers may
  *add* tests but never weaken or delete one (changing a test to make code pass is its own task).
- **The spec gate:** `draft → spec-approved → in-progress → review → done | stopped`. **No agent
  starts a task whose file is not spec-approved.** And the rule everyone wants to skip:

  > **A direct instruction from the human supplies approval, never exemption.** The correct response
  > to "just do X" is a short task file *and then* the work — never the work and then a note. Approval
  > and specification are different functions: the human supplies the first, the file supplies the
  > second.

- **Isolation:** one task, one branch, one worktree, one log. The main branch is reachable only by
  reviewed merge, enforced by the platform rather than by discipline. **And: a test suite or a shared
  directory is a resource too — no two agents run against one concurrently.**
- **Two-strike escalation:** an agent failing the same acceptance criterion twice is stopped. Escalate
  **once** — stronger model *and* improved spec, in that order of importance, because **most failures
  are spec failures**. If the escalated attempt also fails, **work stops and the human is asked.**
- **Context discipline:** state lives on disk, context is cache. An agent past ~60 % context finishes
  its sub-step, updates the log, and ends its run. Continuation is a fresh agent reading the log —
  **a handover by file, never a handover by summary from a tired context.**

**The one rule that prevents the most damage:**

> **Verification is a runnable artefact, not a transcript.** Any task with command-based acceptance
> criteria ships a committed, executable verification script. The agent runs it and pastes *its*
> output; the reviewer and the orchestrator **re-run the same script and diff.** Nothing in a log that
> claims a command's output is trusted unless the script that produced it is on disk and re-runnable.

Its five sub-rules are in `01-method.md` §3 and they are all paid for. The two to internalise
immediately: **a search that finds nothing is a broken search, never a clean result**, and **a check
that cannot fail is worse than no check, because it manufactures confidence** — so break the thing
each check guards and watch it redden, or you do not have a check.

---

## 4. Adopting this on a different project

1. **Start with `doctrine/CLAUDE.md` and `doctrine/MANAGER.md`.** Replace the project-specific parts
   (repository names, identities, the mission) and keep the structure.
2. **Start the decision log at 0001 for the new project.** Do not import these records. Keep the
   format, the immutability rule, and the `Touches:` header — the header is what makes selection
   mechanical later.
3. **Draw the dependency graph before the first implementation task** (ADR-0117). This is the single
   highest-leverage starting move, because it converts "what should we build first" into a
   topological question and makes every contract explicit before anything depends on it.
4. **Write the first verification script for the first task**, not the tenth. The habit does not form
   retroactively.
5. **Calibrate the ceremony to reversibility, not to size.** Full process where being wrong is
   expensive or hard to undo — security boundaries, contracts others build against, anything public,
   anything that deletes data. Less where a mistake is cheap and obvious. `README.md` is honest about
   what the full ceremony cost here: five fix rounds and five adversarial reviews on a single
   contract, every review finding real defects.

## 5. A caution about these documents

They describe a process for catching plausible-looking errors, and they were written by a system
subject to exactly that failure mode. **Everything here is traceable to something that actually
happened on this project** — that was an explicit acceptance criterion — but you should still treat
the claims the way the method says to treat any claim: if a document states what a tool does and the
tool is available to you, **run it.** A caveat where a command was available is a missing check
wearing caution's clothes.
