# Task 029: MANAGER.md §7 stops calling settled merge authority "pending"

- **Mission:** SITE-V1 (doctrine) — **Status:** spec-approved (manager, 2026-09-03)
- **Agent / model:** manager (doctrine correction, no production code)
- **Budget:** small
- **Branch / worktree:** task/029-merge-authority-decided / `~/wt/platform-task-029`

## Approval
Ludwig, in session, 2026-09-03: *"Q4 — fix the preamble to say decided."*

## The correction, and the discrepancy inside it
§7 opened with *"Default (pending Ludwig's answer, OPEN-QUESTIONS §Q4)"*. Two things were wrong:

1. **It was not pending.** Merge authority was answered A. Two independent records say so:
   `docs/manager/agents/OPEN-QUESTIONS.md` Q8 refers to it in passing as settled — *"When the
   manager merges autonomously (Q2-A)"* — and Ludwig restated it in session, *"That authority is
   already decided (Q2-A)"*.
2. **The cross-reference pointed at the wrong question.** §7 cited **Q4**, but in
   `OPEN-QUESTIONS.md` Q4 is *"Effort budgets"* (small ≤1 agent-session, medium ≤3, large ≤6) and
   **Q2** is *"Merge authority. Who merges to main?"*. §7 is about merge authority; effort budgets
   are §8, which never claimed to be pending. So the citation was an error independent of the
   staleness.

Ludwig's instruction named Q4 because that is the number §7 itself printed — the question put to
him quoted §7's own text. **The fix therefore cites Q2**, which is the question §7 is actually
about and the one that was answered A. This is recorded rather than silently renumbered, because a
doctrine document citing the wrong decision is the kind of error that survives for months: it looks
like a reference, so nobody checks it. **If Ludwig meant Q4 literally, the one-line correction is
to change `Q2 = A` back to `Q4` in §7 — but nothing in §7 concerns effort budgets, so that reading
leaves §7 pointing at a question it does not implement.**

Nothing about the *substance* of merge authority changes here — §7's conditions, the
always-requires-Ludwig list, and task 028's takedown rule are all untouched.

## File scope (declared)
- `docs/manager/MANAGER.md` (§7's opening clause only)
- `docs/manager/agents/OPEN-QUESTIONS.md` (mark Q2 answered)
- `docs/tasks/029-merge-authority-decided.md` (this file)

## Acceptance criteria
1. §7 no longer describes merge authority as pending, and cites Q2.
2. `OPEN-QUESTIONS.md` marks Q2 as answered, so the two documents stop disagreeing about whether a
   decision exists — the disagreement that produced this task.
3. No change to §7's substance: the merge conditions, the always-requires-Ludwig list and the
   takedown rule are byte-identical apart from the opening clause. Demonstrated by the diff.

## Forbidden here
- Changing any merge condition, the approval list, or task 028's takedown rule.
- Marking any other open question answered. Q2 is the only one with two independent records of an
  answer; the rest stay open until Ludwig says otherwise.

---
# Task 029 log

## Acceptance criteria — demonstrated

**1. §7's opening clause.**
```
$ sed -n '92p' docs/manager/MANAGER.md | cut -c1-140
**Decided** (Ludwig, OPEN-QUESTIONS Q2 = A): the manager may merge a task branch **only when all of the following hold** — review checklis
```

**2 and 3. The whole diff is three lines across two files, none of them substantive.**
```
$ git diff --stat
 docs/manager/MANAGER.md               | 2 +-
 docs/manager/agents/OPEN-QUESTIONS.md | 3 ++-
 2 files changed, 3 insertions(+), 2 deletions(-)
```
One line in §7 (the opening clause), two in `OPEN-QUESTIONS.md` (Q2's heading gains "ANSWERED: A"
and a pointer to where it is encoded). No merge condition, approval-list entry or takedown sentence
appears in the diff.

**Status: criteria 1-3 demonstrated. Ready for merge.**
