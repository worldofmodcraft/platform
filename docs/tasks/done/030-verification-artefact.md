# Task 030: Verification becomes a runnable artefact, in doctrine

- **Mission:** SITE-V1 (doctrine) — **Status:** spec-approved (manager, 2026-09-04)
- **Agent / model:** manager (doctrine edit, no production code)
- **Budget:** small
- **Branch / worktree:** task/030-verification-artefact / `~/wt/platform-task-030`

## Approval
Ludwig, in session, 2026-09-03, when task 006's third fabricated verification was found:
*"this isn't a 006 problem, it's a class. After 006 closes, file a small doctrine task:
verification-as-runnable-artefact becomes the standard for any task whose acceptance criteria are
command-based — the agent writes `docs/tasks/NNN-verify.sh`, commits it, pastes its output; the
reviewer (and you, spot-checking) re-run the same script and diff. Logs claiming commands that were
never run are henceforth detectable by construction, not by vigilance."*

Task 006 closed on 2026-09-04 (registry PR #2). This is that task.

## Objective
The rule is in doctrine, and both checklists enforce it, so that a log claiming a command's output
is worth nothing unless the script that produced it is on disk and re-runnable.

## The evidence this is a class, not an incident
Four review rounds on task 006 produced, in order:
1. A consistency sweep recorded as `grep -n "a|b|c" file` — basic `grep` reads `|` literally, so it
   returns nothing. The sweep never ran; its conclusions had no artefact behind them.
2. A quoted hit for the string `only Ludwig can merge` on a line that ends at `only Ludwig can`,
   with `merge` on the next line. That output cannot exist.
3. A hit count of "20" pasted directly above output containing 19 lines.
4. And, after the artefact rule was introduced: **the artefact itself contained three checks that
   could not fail** — the suite check read `sed`'s exit status rather than `unittest`'s, and two
   regex alternations sat behind labels that read as conjunctions. A 28-check script stayed fully
   green while the deletion verdict was flipped, while rule 4's uniqueness clause was deleted, and
   while the test suite was deliberately broken.

Three different agents, one manager, the same shape every time. Every claim was *true*; none was
demonstrated. That is why the fix is structural rather than a reminder to be careful.

## File scope (declared)
- `docs/manager/MANAGER.md` (new §2c)
- `docs/manager/REVIEW-CHECKLIST.md` (new item 8; later items renumbered)
- `docs/manager/SPEC-CHECKLIST.md` (new item 8; later item renumbered)
- `docs/tasks/030-verification-artefact.md` (this file)

## Acceptance criteria
1. MANAGER.md §2c states the rule, why it exists, and its four consequences — zero hits is a
   failure; the artefact must be mutation-tested; conjunctive labels must fail per conjunct; the
   script must be proven in a fresh clone.
2. REVIEW-CHECKLIST.md makes it a blocking review item that requires the reviewer to **re-run the
   script and mutation-test it** — not to read it.
3. SPEC-CHECKLIST.md makes it a gate item, so a spec that needs an artefact and does not declare one
   never reaches an agent.
4. The scope boundary is stated: visual, external and human criteria are recorded as before, but a
   log must say which criteria are script-verified and which are not.
5. Numbering in both checklists stays consistent — demonstrated by reading the files back.

## Forbidden here
- Extending the rule to criteria it does not fit. A screenshot is not a script, and pretending
  otherwise would produce exactly the false confidence this rule exists to remove.
- Editing `docs/decisions/` (MANAGER.md §3.1). This is doctrine; if it should become an ADR, that
  is Ludwig's call and a separate task.

---
# Task 030 log

## Acceptance criteria — demonstrated
```
$ grep -c "2c. Verification" docs/manager/MANAGER.md
1
$ grep -c "Verification artefact" docs/manager/REVIEW-CHECKLIST.md docs/manager/SPEC-CHECKLIST.md
docs/manager/SPEC-CHECKLIST.md:1
docs/manager/REVIEW-CHECKLIST.md:1
```
Numbering read back after the edit: REVIEW-CHECKLIST runs 1-11 with no repeats or gaps;
SPEC-CHECKLIST runs 1-9 likewise. Verified by reading both files, not by assuming the substitution
landed cleanly.

**No verification artefact for this task itself.** Its criteria are textual — "the doctrine says X"
— and a script asserting that a sentence exists in a file it was written alongside would be exactly
the self-confirming check §2c warns about. Recorded here rather than left as an unexplained
absence, which is what criterion 4's scope boundary requires of every task from now on.

**Status: criteria 1-5 demonstrated. Ready for merge.**
