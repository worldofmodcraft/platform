# Task 008b-3a: Ownership carve-out for the pipeline identity

- **Mission:** SITE-V1, deliverable **D2** (umbrella `docs/tasks/008b-pipeline-workflow.md`, which keeps the decisions, design and history; design numbers below refer to it) — **Status:** draft — split from 008b at the spec gate 2026-10-26, and again from 008b-3 at the review of the split (manager ★, session 12); independent spec review pending
- **Agent / model:** implementer / sonnet
- **Budget:** small
- **Branch / worktree:** `task/008b3a-ownership-carve-out` / `~/wt/registry-task-008b3a` — **registry** repo
- **Sequence:** merges **before** 008b-3b. It needs only tasks 032 (merged), 057 and 007 (the ownership module), so it can run in parallel with 008b-1 and 008b-2. **Needs Ludwig's approval: CI security check** (the carve-out widens what the ownership gate accepts).

## Objective
`tools/registry/ownership.py` accepts the pipeline identity's numeric account id — and only that id — for a pull request whose entire diff is exactly one T1 (`pending -> published`) or exactly one T3 (`pending -> rejected`) transition, as `contracts/ownership.md` (E16, R11) specifies, and rejects it for everything else. Tests show both directions on hand-written fixture diffs taken from task 057's oracle (not built by 008c or by the pipeline), so this part has no dependence on the write-back code.

## Context to load (exhaustive; 7 items)
- `contracts/ownership.md` (R11 and the identity rule; `GITHUB_ACTOR*` forbidden as an identity source).
- `contracts/append-only.rules.md` (T1, T3, "Coexistence of T1, T2 and T3") and `entry.schema.json` as amended by task 057; task 057's oracle fixtures (`contracts/examples/entry/**` and the T1/T3 diff fixtures).
- Task 007's `tools/registry/ownership.py` and its tests (this task edits them).
- The umbrella `008b-pipeline-workflow.md` (criteria 4 and 5 text in this part; umbrella F4 on reading the App's id after M5; manual step M6).

## Size (5b)
Within every cap. Source files: 1 (`tools/registry/ownership.py`). Changed lines: about 60 (estimate; nothing built). Reading list: 7 items. Tests, fixtures and `008b3a-verify.sh` excluded.

## Design (taken from the umbrella; decisions are recorded there)
The carve-out identifies the pipeline identity by **numeric account id**, never by username or `GITHUB_ACTOR*` (ownership.md). The real id is the App's bot user id, read from the public API after Ludwig's M5 and recorded by the manager (umbrella F4); the tests use a fixture id, so this task can be built and merged before M5. Decision carried: Q-D (the organisation-owned GitHub App is the pipeline identity; Ludwig 2026-10-14). The App-PR flow itself (opening, merging) is 008b-3b's.

## File scope (declared; anything else = stop and report)
In the **registry** repo: `tools/registry/ownership.py` (the narrow carve-out only; the file is task 007's) and its tests and fixtures in `tests/registry/`; `docs/tasks/008b3a-ownership-carve-out.md` (log); `docs/tasks/008b3a-verify.sh` (new, executable). No edits to `contracts/` (E16 is merged), to `.github/`, to `tools/pipeline/`, or to any other module.

## Acceptance criteria
Criterion numbers are the umbrella's, kept so the mapping table there can be checked. [script] = checked by this part's verify script.

4. [script] **Ownership acceptance of the permitted diffs (umbrella criterion 4, ownership clause):** the fixture T1 diff and the fixture T3 diff from 057's oracle, authored by the pipeline identity's fixture id, are **accepted** by 007's ownership checker; the same diffs authored by a different id are **rejected**, each shown. (The clause that the diffs built by 008b-3b's code are accepted by the append-only and schema checkers is 008b-3b's criterion 4.)
5. [script] **The carve-out is narrow and tested both ways:** the ownership gate accepts the
   pipeline identity's id *only* for a PR whose changes are exactly the transition in criterion 4 and
   rejects it for: a first publish, a new version, a `page.json` edit, a takedown, a mixed T1 and T3 PR, a T3 whose `reason` is blank or whose `build_log_url` is not `https://`, any change under
   `contracts/` or `.github/`. The hostile fixture from task 007 (id differs, username matches) still
   rejects. Positive control: an owner's ordinary PR still accepts. [Needs Ludwig's approval: CI
   security check.]
13. [script] **Verification script.** `docs/tasks/008b3a-verify.sh` exists, is executable, covers criteria 4 and 5, is mutation-tested (widen the carve-out to a first publish; accept the id for a `page.json` edit; drop the `https://` check on `build_log_url`; accept a username instead of the id; each shown red then restored byte-identically), is run in a fresh clone, and its output is pasted in the log. Every check fails on zero matches.
18. **Docs move with code:** no `docs/pipeline` change (the carve-out is already specified by `contracts/ownership.md`); the log records the fixture id used and states that the real id is set after M5. (Umbrella criterion 18 is split by section; this part owns none.)

## Explicitly OUT of scope
The write-back job, releases, PRs and the T3 builder (008b-3b); the planner (008b-1); the workflow (008b-2, 008b-3b); changes to `contracts/ownership.md`.

## Forbidden here (beyond MANAGER.md §3.7)
- Any use of `GITHUB_ACTOR`/`GITHUB_ACTOR_ID` as the author identity.
- Weakening or skipping task 007's hostile fixtures (id differs, username matches) to make the carve-out pass; widening the carve-out beyond the transitions of criterion 5.
- Reading or printing the App's private key or any token; the App's bot id is read from the **public** API only (CLAUDE.md rule 11).

## Dependencies and sequencing
Tasks 032 (merged, registry PR #4), 057 and 007 merged. Parallel-safe with 008b-1 and 008b-2. Blocks 008b-3b. Ludwig's manual step **M6** (join the organisation with the personal account, so an organisation-member PR is accepted) is carried here; it matters to the positive control of criterion 5 only if run live. Graph: nodes N2, N3; edge E16 (author identity -> N3).

## Verification artefact (MANAGER.md §2c)
Declared: `docs/tasks/008b3a-verify.sh` for criteria 4, 5 and 13. There are no [live] criteria in this part.

## Deliverables
Carve-out + tests + fixtures + verify script + this file's log section current.

## Questions  (agent-maintained; see MANAGER.md 8b)
- (none open.)

---
# Task 008b-3a log  (append-only, updated continuously by the executing agent)
- 2026-10-26 split from 008b-3 at the review of the 008b split (manager ★, session 12); nothing started.
