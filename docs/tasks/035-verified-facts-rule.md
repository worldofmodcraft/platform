# Task 035: A contract's environmental claims carry their caveat inline

- **Mission:** SITE-V1 (doctrine) — **Status:** spec-approved (Ludwig, in session, 2026-09-05)
- **Agent / model:** manager (doctrine text; no production code)
- **Budget:** small
- **Branch / worktree:** `task/035-verified-facts-rule` (platform repo, `~/wt/platform-task-035`)
- **Graph:** none.

## Objective
MANAGER.md §3 guardrail 6 gains a sub-clause **6b**, in Ludwig's own words:

> No contract or spec states an environmental fact without either a verification command shown or
> an inline caveat marking it unverified.

## Where this came from
Task 025's review, 2026-09-05. The agent wrote an honest "what I could not verify" list in its task
log — minisign's four-line signature layout, Windows reserved-device-name matching, GitHub
Pages/Jekyll behaviour — and then stated all three as flat fact in the contract text itself
("a detached signature **is** a text file of exactly four lines"). Guardrail 6 as written was
satisfied: the assumption *was* marked, in the task log.

**The gap is that a contract is read without its task log.** These six files exist precisely to be
implemented from by someone who was not there — task 008 will build a signature verifier from
`signature-format.md` — and that reader had no way to know a claim had never been exercised. The
honest log protected the record; it did not protect the reader.

## Acceptance criteria
1. MANAGER.md guardrail 6 carries 6b, quoting Ludwig's sentence verbatim.
2. It states the two things the review showed are needed beyond the sentence itself: the caveat
   goes **where the claim is made** (not in a trailing section), and it marks the **basis** of a
   rule without weakening the rule.
3. It cites task 025 as the origin so the rule is traceable to the evidence that produced it.
4. No other doctrine text is altered.

## File scope (declared)
- `docs/manager/MANAGER.md` (guardrail 6 only)
- `docs/tasks/035-verified-facts-rule.md` (this file)

Anything else = stop and report.

## Log
- 2026-09-05 Ludwig ruled it during task 025's fix round ("when the fix round closes, add the
  one-liner to the doctrine's §3.6 area"). Written the same sitting.
- **Not applied retroactively as a review gate on 025 itself:** that branch's fix round had already
  closed the same three findings by hand before this rule existed. The rule's first *gating* use is
  the next contract written — task 032's `contracts/ownership.md`, and task 034's schema fix.
- Verification: this task changes doctrine prose only. There is no command to run and therefore no
  `035-verify.sh` (MANAGER.md §2c applies to command-based criteria). The criteria above are checked
  by reading the diff, which is four lines.

## Status
**done** — pending merge.
