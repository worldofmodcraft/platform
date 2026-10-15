# Task 007b: Registry checkers, authority half — ownership by numeric id, reserved namespaces, R11, fail-closed T1/T3

- **Mission:** SITE-V1, D1 — **Status:** draft (independent spec review required before approval:
  security-relevant CI). Not dispatchable until 007a merges.
- **Umbrella:** `docs/tasks/007-registry-ci-checkers.md` — read it in full, including the
  "Revision 2026-10-15" section, which overrides its older text.
- **Agent / model:** implementer / sonnet
- **Budget:** medium (≤ 3 agent-sessions)
- **Branch / worktree:** `task/007b-registry-checker-ownership` / `~/wt/registry-task-007b`, cut from
  registry `origin/main` after 007a's merge
- **Graph:** node N3; edge E16. No new edges.

## Objective
An offline ownership checker `tools/registry/ownership` exists, using 007a's report module and 007a's
per-element classification, implementing `contracts/ownership.md` as merged (task 032, PR #4): the PR
author's **numeric** account id against `owner.id` for every touched namespace; first-publish binding;
the ADR-0119 reserved-namespace path through an **injected org-membership oracle**; R11's takedown
authorisation (a takedown PR contains nothing but takedown mutations); and the **fail-closed rule**:
every PR containing a T1 or T3 mutation is rejected, whoever the author is, until the pipeline carve-out
(task 008b) amends `ownership.md`.

## Context to load (exhaustive)
- Umbrella 007 (all), ADR-0058 §2–4, ADR-0119, ADR-0121, ADR-0041 (takedown grounds).
- Registry `origin/main`: `contracts/ownership.md` (all; rules R1–R11), `contracts/append-only.rules.md`
  ("Coexistence of T1, T2 and T3", "Attack attempts"), `reserved-namespaces.json`,
  `docs/tasks/032-b1-fixtures.json` (HTTP evidence only), 007a's `tools/registry/` and `tests/registry/` as merged.
- Doctrine as in 007a.

## Acceptance criteria — all demonstrated by `docs/tasks/007b-verify.sh`
Umbrella criteria 4, 5, 6, 10 (ownership messages), 11, 12 (ownership half), and 14 (fail-closed), plus:
- **B1. Fail-closed matrix.** T1-only, T3-only, and T1+T3 PRs, each authored by: the namespace owner; a
  stranger; an org member on a reserved namespace; an id equal to an injected `pipeline_app_id`. All twelve
  rejected, message naming ADR-0121 and the missing carve-out (task 008b). A T2-only PR from an R11-authorised
  author is accepted; a T2 + T1 PR is rejected (R11: nothing but takedowns).
- **B2. Every rule has a test both ways.** The suite enumerates the rule ids `R1`–`R11` from
  `contracts/ownership.md`'s `**Rn (MUST` markers at test time (11 on `e009ef0`; a count of zero fails) and
  requires, per id, at least one test that the rule accepts and one it rejects, tagged with that id. A rule
  without both fails the suite. `docs/tasks/032-b1-fixtures.json` is recorded HTTP evidence about the
  membership endpoints, not PR fixtures; read it only to choose the oracle's failure semantics as
  `ownership.md` states them.
- **B3. Mutation.** `007b-verify.sh --mutate` in a temporary clone injects at least: compare usernames instead
  of ids; skip the fail-closed branch; let `pipeline_app_id` bypass fail-closed; let a binding PR rebind an
  existing namespace; treat the membership oracle's exception as "member"; let R11 admit a non-takedown change;
  reject everything (positive control). Each reddens named tests.
- **B4. The oracle seam is explicit.** The membership oracle and `pipeline_app_id` are parameters; the module
  performs no network or environment reads (asserted by test: patched `socket` and `os.environ` access raise).

## File scope (declared)
`tools/registry/ownership*.py` (new), `tests/registry/test_ownership*.py` (new),
`docs/tasks/007b-registry-checker-ownership.md` (log), `docs/tasks/007b-verify.sh` (new),
`docs/contracts/README.md` (ownership half of umbrella criterion 12). Changing 007a's modules = stop and report.

## Forbidden here
The umbrella's list, plus: hard-coding any real GitHub App id or account id outside test fixtures; any
carve-out letting the pipeline identity carry T1/T3 (that is 008b's contract amendment, not code here); a
network call or credential read of any kind (rule 11 of CLAUDE.md).

## Dependencies
After 007a (merged). Blocks 039. Task 008b later amends `ownership.md` and this checker together.

---
# Task 007b log
- 2026-10-15 manager: spec written (session 9) from the umbrella's revision.
