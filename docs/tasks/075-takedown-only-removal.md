# Task 075: any PR that removes a published version is a takedown — owners cannot remove (R11 amendment + 007b checker)

- **Mission:** SITE-V1 (registry integrity) — **Status:** draft (manager, 2026-10-18; security-touching → independent
  spec review before delegation, MANAGER.md §2b)
- **Repo:** registry. **Agent / model:** implementer (ROUTING.md). **Budget:** small (≤ 1 agent-session)
- **Branch / worktree:** `task/075-takedown-only-removal` / `~/wt/registry-task-075`, cut from registry `origin/main`
  **after task 064 merges** (064 touches `tools/registry/schema.py`; this task must start from main containing it)
- **Graph:** registry CI ownership check (007b node); edge: `contracts/ownership.md` ↔ `tools/registry/ownership.py`.
- **Merge:** Ludwig's written approval required (contract + CI security check + takedown semantics, §7).

## Source of the decision
Ludwig, 2026-10-17 (mission log, "Ludwig's answers, 2026-10-17", item 1, and "Removal policy — brainstorm and Ludwig's
decision", item 0): owners cannot remove a published version. ADR-0041:15 already says so; `contracts/ownership.md` R11
(lines ~1022-1025 at registry `825da5e`) contradicts it: "a PR that sets `status` to `"removed"` with its reason *and*
makes any other change ... is not a takedown for this rule's purposes and is judged in full by the ordinary rules" — so
an owner bundling a removal with, e.g., a new version of their own entry passes R3 as the owner (007b review F2).

## Objective
After this task, **every** PR whose diff contains at least one takedown mutation (a version's `status` becoming
`"removed"` with its reason, as `contracts/append-only.rules.md` defines it) is rejected unless R11 authorises it — the
platform's own identity **and** a diff of nothing but takedown mutations. A mixed PR (a takedown mutation plus anything
else) is rejected **whoever** its author is, with a finding that names R11 and says to split the PR. The non-takedown
part of a PR is still judged by the ordinary rules as now; only the presence of a removal changes the verdict.

## Approach (the manager's reading; the implementer flags any disagreement as a Question before building)
1. **Contract:** amend `contracts/ownership.md` R11's "nothing but" sentence (and the Attempt 8 discussion, ~line 879-890,
   wherever it states the mixed-PR consequence) so a mixed PR is **rejected by R11**, not judged by the ordinary rules.
   Add the corresponding row/wording change in the "Where the rules are enforced" table (~line 687) so R11's rejection
   condition covers both cases: wrong identity, or a takedown mutation in a PR that is not purely takedowns. Record the
   amendment's source (Ludwig 2026-10-17, ADR-0041:15) in the text. No other rule changes.
2. **Checker:** in `tools/registry/ownership.py` (around `_takedown_shape`, ~line 95, and the R11 verdict, ~line 237),
   detect "contains at least one takedown mutation" separately from "is nothing but takedown mutations", and emit an
   R11 rejection for a mixed PR regardless of author (including the platform identity).
3. **Tests:** in `tests/registry/test_ownership.py` (and `test_ownership_mutations.py` if the mutation harness covers
   R11): owner + removal + new version → rejected (R11); platform identity + removal + other change → rejected (R11);
   platform identity + only removals → authorised (unchanged); owner + only removals → rejected (unchanged); owner + new
   version without removal → accepted (unchanged).

## Acceptance criteria — `docs/tasks/075-verify.sh`, whose output the log pastes
1. **Red first:** a commit containing only the new tests, on which the mixed-PR tests fail (owner case passes the old
   checker); the fix commit after it. Shown by the script checking out both commits in temporary clones.
2. **Fixed at HEAD:** the five cases in Approach 3 hold; the full `tests/registry` suite is green.
3. **Mutation red:** reverting the checker's mixed-PR branch (in a temporary clone) turns the new tests red.
4. **Contract text:** `contracts/ownership.md` no longer contains "judged in full by the ordinary rules" in R11's
   mixed-PR sentence; R11's paragraph names ADR-0041 and Ludwig 2026-10-17 as the source. Any existing contract-text
   check (e.g. the line-62 "R3/R7 must name R11" check in the test suite) stays green.
5. **Closed scripts:** every `docs/tasks/*-verify.sh` on HEAD exits 0 (quiet machine, one at a time). If a closed
   script's own-change check reddens because this task edits a file it pins (the class OPERATIONS.md documents), stop
   and report — do not edit closed scripts in this task.
6. **Own-change pinning:** 075-verify.sh's own-change checks (file scope, red-commit ancestry) use explicit SHAs
   recorded at the end of the task, never HEAD or origin/main (approved REVIEW-CHECKLIST item, Ludwig 2026-10-17).

## File scope
`contracts/ownership.md`, `tools/registry/ownership.py`, `tests/registry/test_ownership.py`,
`tests/registry/test_ownership_mutations.py`, `docs/tasks/075-takedown-only-removal.md` (copy + log),
`docs/tasks/075-verify.sh` (new). Anything else = stop and report.

## Size
Source files: 2 (`ownership.py`, `ownership.md`), well under 300 lines. Reading list (≤ 10): this file; ADR-0041;
`contracts/ownership.md` (R3, R7, R11, Attempt 8, enforcement table); `contracts/append-only.rules.md` (permitted
in-place mutations, ~line 590-630); `tools/registry/ownership.py`; `tests/registry/test_ownership.py`;
`tests/registry/test_ownership_mutations.py`; `docs/tasks/007b-registry-checker-ownership.md` (review F2);
`docs/tasks/071-verify.sh` (pinning pattern); OPERATIONS.md "What session 10 paid for".

## Forbidden here
Changing who R11 authorises (identity, configuration); touching append-only rules or any schema; weakening or deleting
any existing test or check; editing closed verify scripts; `--force`; any credential.

## Dependencies
064 merged (base). Gates task 039 (registry CI workflow). ADR-0122 (Proposed) is not needed: this rule stands on
ADR-0041:15 alone.

---
# Task 075 log
- 2026-10-18 manager (session 11): drafted from Ludwig's 2026-10-17 decision (removal policy item 0). Line numbers
  measured on `~/wt/registry-task-064` (registry branch at 064 + main `825da5e`); the implementer re-measures on its base.
