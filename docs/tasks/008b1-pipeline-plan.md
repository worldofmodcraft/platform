# Task 008b-1: Pipeline planner — which versions to build, skip, refuse or fault

- **Mission:** SITE-V1, deliverable **D2** (umbrella `docs/tasks/008b-pipeline-workflow.md`, which keeps the decisions, design and history; design numbers below refer to it) — **Status:** draft — split from 008b at the spec gate 2026-10-26; independent spec review pending
- **Agent / model:** implementer / sonnet
- **Budget:** medium
- **Branch / worktree:** `task/008b1-pipeline-plan` / `~/wt/registry-task-008b1` — **registry** repo
- **Sequence:** 008c -> 008b-1 -> 008b-2 -> 008b-3, and tasks 082 (registry PR #20, blocked on 087) and 092 (registry PR #25) merged first. This part has no workflow and no secret: it is a pure, offline-testable helper.

## Objective
`tools/pipeline/plan_pending.py` exists in the registry with offline tests. Given the registry state at `main`'s head (the SHA is logged), the list of existing `pipeline/*` branches, and the dispatch inputs, it prints one plan document that sorts every `pending` version into exactly one of four lists: **build**, **refuse** (a `+` version, 092 Q10), **skip** (an existing `pipeline/<namespace>.<name>-<version>` branch, C13) and **fault** (an entry failing the schema, C15; a malformed input). Published, removed and rejected versions appear nowhere. Zero pending versions give an empty plan and exit 0. The plan document (list names `build`, `refuse`, `skip`, `fault`, and the logged head SHA) is the interface 008b-2 and 008b-3 consume; it is internal to node N5 and adds no edge to the dependency graph. Field names beyond those four lists are pinned by this task's tests and documented in `docs/pipeline/build-pipeline.md`.

## Context to load (exhaustive; 9 items)
- ADR-0121 (the `pending` lifecycle; authority for design 2).
- Contracts: `pipeline-trigger.md` (task 082: PT4, PT5, PT6, PT9, PT12); `entry.schema.json` and `append-only.rules.md` as amended by task 057 (the `pending` state); `artifact-naming.md` as amended by task 092 (the archived-source URL section and the `+` rule).
- 008a `tools/pipeline/naming.py`; 008c `tools/pipeline/write_back.py` (`source_archive_url`), read from `origin/main` once 008c has merged.
- The umbrella `008b-pipeline-workflow.md`: designs 1, 2, 3 (planner half), 9 (validation half), 7 (PT5 and `+` text).
- Mission log decisions C11, C12, C13, C15 (`docs/tasks/MISSION-worldofmodcraft-site-v1-log.md`).

## Size (5b)
Within every cap. Source files: 1 (`plan_pending.py`). Changed lines: about 130 (estimate, nothing built). Reading list: 9. Tests, fixtures, `008b1-verify.sh` and docs are excluded from the counts.

## Design (taken from the umbrella; decisions are recorded there)
- **Input snapshot (design 2; C12, PT4):** the planner reads `mods/*/entry.json` at `main`'s head as fetched at plan time and logs the SHA; never the push's `github.sha` or range.
- **What is listed (design 2; Q-B, C11, PT5):** every version object in state `pending`. A push run and a dispatch with an empty `version` list all of them; a dispatch with `version=<namespace>.<name>@<semver>` lists only that one, and only if it is `pending`; otherwise (malformed id, absent entry, not pending) exit 1, nothing written. Zero pending is success.
- **Schema fault (C15; PT9):** an entry on `main` failing `entry.schema.json` is a pipeline fault: no build, no T3, the plan lists a fault naming the file.
- **`+` versions (092 Q10; decided by Ludwig 2026-10-26):** a `pending` version whose `version` contains `+` goes on the **refuse** list, with the exact reason text "versions with build metadata (+) are not yet published — pending proof that GitHub resolves them (task 010)" (copied from 092's contract, producer obligation 3). The T3 that carries it is opened by 008b-3. A prerelease without `+` (for example `1.0.0-rc.1`) is built as any other.
- **Branch skip (C13; PT6):** a `pending` version whose `pipeline/<namespace>.<name>-<version>` branch exists is on the **skip** list, never built; the workflow (008b-2) ends non-green naming it. Recovery is manual (close the PR, delete the branch, dispatch).
- **Dry-run input set (PT12; Q-M decided by the manager, option A, 2026-10-26):** `workflow_dispatch` inputs `dry_run` (boolean, default `false`), `version` (string, default empty), and, only with `dry_run=true`, the pair `dry_run_source_url` (`https://` URL) and `dry_run_commit` (40 hex), accepted only together and only with `version` empty. The planner validates all of them (exit 1 on a malformed or conflicting set); the synthetic in-run entry is built by 008b-2's dry-run job. Names are 008b's to fix (PT12); 082's reviewer confirms them at 082's next touch.
- **Per-version fault handling (PT5):** a fault or refusal ends that version only; the driver continues with the other versions and ends non-green naming each. The mechanism (matrix with `fail-fast: false`, or a loop) is 008b-2's; the behaviour is tested here with fake outcomes.

## File scope (declared; anything else = stop and report)
In the **registry** repo: `tools/pipeline/plan_pending.py` (new) and its tests and fixtures in `tests/pipeline/`; `docs/pipeline/build-pipeline.md` (additions: the plan document and the planner rules only); `docs/tasks/008b1-pipeline-plan.md` (log); `docs/tasks/008b1-verify.sh` (new, executable). No workflow file, no `contracts/`, no 008a modules, no `tools/registry/`.

## Acceptance criteria
Criterion numbers are the umbrella's (`008b-pipeline-workflow.md`), kept so the mapping table there can be checked; a part's list therefore has gaps. [script] = checked by this part's verify script; [live] = a real run, recorded with run URLs, **not** script-verified.

3. [script] **Naming:** a unit test feeds `(namespace, name, version)` triples through the
   workflow's naming/URL helpers (008a's `release_asset_url`, 008c's `source_archive_url`) and asserts tag, both asset names and both URLs equal the `artifact-naming.md` examples (`mc.hello-world-1.0.0`,
   `.tar.gz`, `.tar.gz.minisig`), The expected strings are 092's worked examples in `artifact-naming.md` ("The archived-source URL"), typed literally into the test, not derived by the code under test: example 1 (`mc`, `hello-world`, `1.0.0`) for tag, assets and URLs, and example 2 (`a`, `b`, `1.0.0-rc.1+build.5`, tag `a.b-1.0.0-rc.1+build.5`) as a pure helper unit test **labelled "derivation only, never published"** — a `+` version is refused by design 2 and 7 (Q10) and no run ever uploads it. The expectations come from the 092 contract, not from task 058's report. Mutation: change one character of a helper's output and show the test red.
12. [script] **Idempotence of the no-op:** run the planning step against `main` after a write-back
    merge: zero pending versions, no build, success.
17. [script] **Retry path** (design 9): `plan_pending.py` with a `version` input builds only that version and refuses (exit 1) a version that is not `pending`, a malformed id, or one whose entry is absent; with no input (a push, or a dispatch with an empty `version`) it builds every `pending` version. The planner validates `version`, `dry_run_source_url` and `dry_run_commit` as design 1 states (a malformed or conflicting dry-run input exits 1). **Planner-level tests (no network, fixture repository state), each with a mutation:** (a) **C13 skip:** a pending version whose `pipeline/<ns>.<name>-<version>` branch exists is not in the build list, is reported as skipped with the version named, and the planner's result is non-green; mutation: remove the branch check. (b) **C15:** a `mods/*/entry.json` failing the schema yields no build and no T3 for any of its versions, and a fault naming the file; mutation: treat the entry as valid. (c) **PT5:** with three pending versions and fake outcomes (ok, fault, ok), the driver processes all three and ends non-green naming exactly the faulted one; mutation: stop at the first fault. (d) **Q10 refusal:** a pending `1.0.0+build.5` is in the refusal list, not the build list, while `1.0.0-rc.1` is in the build list. Mutations: ignore the `version` input; accept a `published` version; drop the branch check of (a); treat the invalid entry of (b) as valid; stop at the first fault in (c); remove the `+` check of (d). Positive control: the unmodified planner passes all four.
13. [script] **Verification script.** `docs/tasks/008b1-verify.sh` exists, is executable, covers criteria 3, 12 and 17, is mutation-tested (criteria 3 and 17 with the mutations they name, and criterion 12 by planning against a state that still has a pending version; each mutation shown red then restored byte-identically), is run in a fresh clone, and its output is pasted in the log; the log separates [script] from [live] results. Every check fails on zero matches.
18. **Docs move with code:** `docs/pipeline/build-pipeline.md` gains the plan document, the four lists and the manual recovery for a skipped (C13) version. (Umbrella criterion 18 is split by section: this part, 008b-2 and 008b-3 each own the sections named in their own criterion 18.)

## Explicitly OUT of scope
The workflow file and every job (008b-2, 008b-3); signing; releases; PRs; the dry-run job's synthetic entry (008b-2); 008a's tool; `tools/registry/`.

## Forbidden here (beyond MANAGER.md §3.7)
- Any network access in the planner or its tests: the registry state, the branch list and the clock are injected.
- Reading the author's mod from its live repository (the planner reads only registry entries).
- Any use of `GITHUB_ACTOR`/`GITHUB_ACTOR_ID`.
- Building, signing or opening anything for a `+` version; weakening a test to make a fixture pass.

## Dependencies and sequencing
Tasks 082 and 092 merged (the contract text and the `+` rule are cited from `main`); task 057 (version lifecycle) merged; 008c merged (provides `source_archive_url`, used by criterion 3). Blocks 008b-2, which wires this planner into the workflow. Graph: node N5, edge E15 (input side). Parallel-safe with 041 and 056.

## Verification artefact (MANAGER.md §2c)
Declared: `docs/tasks/008b1-verify.sh` for every criterion above. There are no [live] criteria in this part.

## Deliverables
Planner + tests + fixtures + docs section + verify script + this file's log section current.

## Questions  (agent-maintained; see MANAGER.md 8b)
- **Q-M: decided** (manager, option A starred, 2026-10-26, on Ludwig's overnight instruction "Ta stjärna på alla beslut"): the dry-run source inputs are `dry_run_source_url` and `dry_run_commit`, with a synthetic in-run entry. Open follow-up, not blocking: 082's reviewer confirms the names.

---
# Task 008b-1 log  (append-only, updated continuously by the executing agent)
- 2026-10-26 split from 008b at the spec gate (manager decision); nothing started.
