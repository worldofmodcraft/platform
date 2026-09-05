# Task 038: doctrine — breaking cases are the measure of a suite

- **Mission:** SITE-V1 — **Status:** **spec-approved (Ludwig, in session; the companion rule was
  his wording, tied to task 023's fix round closing)**
- **Agent / model:** manager (doctrine is manager-owned; precedent: tasks 035, 036)
- **Budget:** small
- **Branch / worktree:** `task/038-doctrine-session5` (platform)

## Item 1 — the verification-artefact companion (deferred from session 4, now written)
Ludwig's wording, recorded in session 4's status as "not written yet, deliberately":

> *A suite is judged by the breaking cases it contains, not the count it passes; every fix round
> adds the found break as a fixture before the fix.*

Added as **MANAGER.md §2c rule 5**, with the two consequences this project has already paid for:
keep the positive controls beside the hostile fixtures (a suite that passes by rejecting everything
manufactures the same false confidence as a check that cannot fail), and put the defect back to
watch the new fixture redden before believing it guards anything.

Propagated to both checklists, because docs move with code (universal rule 9):
- `REVIEW-CHECKLIST.md` item 8 — a fix round's finding must be in the suite, shown failing first.
- `SPEC-CHECKLIST.md` item 8 — a fix round's *spec* must require that fixture up front.

**Why rule 5 is not already covered by rule 2.** Rule 2 says the artefact must be *able* to fail
and demands mutation-testing. Rule 5 says *which* failures it must contain and *when* they are
written. A fix round can satisfy rule 2 completely — every check mutation-tested — while leaving no
trace of the specific defect that caused the round. The number goes up and the repository forgets
what went wrong.

**Task 023's fix round 2 is the reference implementation**, and is what Ludwig tied this rule to:
the reviewer's four-line prose reproduction and his own `context 24 %, usage 55 %` habit are now
permanent fixtures, sitting beside real statusline renderings that must still parse.

## Item 2 — §5.4(e), the non-tmux case: **RULED BY LUDWIG, NOT YET APPLICABLE ON `main`**
His ruling, session 5:

> §5.4(e) must define the non-tmux case explicitly — **no sentinel outside tmux; the handover is
> complete at the committed session status.** Session 4's deliberate non-creation of the sentinel
> was the correct reading and is the precedent.

**The clarification is not made in this task, and the reason is a fact about the tree rather than a
judgement call: §5.4(e) does not exist on `main`.** The sentinel clause lives only on the unmerged
`task/023-supervisor` branch:

```
$ git grep -n "handover-ready" main -- docs/manager/MANAGER.md
(no output)
$ git grep -n "handover-ready" task/023-supervisor -- docs/manager/MANAGER.md
task/023-supervisor:docs/manager/MANAGER.md:80: ... (e) finish by creating the sentinel file ...
```

Writing the clarification here would either edit a clause that is not present — producing a
conflict when 023 merges — or silently introduce the sentinel rule to `main` through a doctrine
task, which is not what task 038 is for.

**Where it lands instead:** on `task/023-supervisor`, as part of that task's finalisation, since the
sentinel is 023's own deliverable and 023 is the branch that introduces the clause being clarified.
Recorded here so the ruling cannot be lost between branches. **This task is not complete in
Ludwig's eyes until that edit exists**, and this paragraph is the receipt.

## Acceptance criteria
1. MANAGER.md §2c carries rule 5 in Ludwig's wording, with the two consequences. **Done.**
2. Both checklists carry the fix-round fixture requirement. **Done.**
3. The §5.4(e) ruling is recorded with the reason it is applied on another branch, and the
   verification that §5.4(e) is absent from `main`. **Done** — the `git grep` output above.
4. No ADR is edited (guardrail 1). **Done** — file scope below contains none.

## File scope (declared)
- `docs/manager/MANAGER.md` (§2c rule 5)
- `docs/manager/REVIEW-CHECKLIST.md` (item 8)
- `docs/manager/SPEC-CHECKLIST.md` (item 8)
- `docs/tasks/038-doctrine-session5.md` (this file)

## Note on review
Manager-authored doctrine with no independent reviewer — the same pattern flagged to Ludwig as
manager error 5 in session 4 (tasks 033, 035, 032's platform half), on which he has not yet ruled.
Flagged, not assumed away.
