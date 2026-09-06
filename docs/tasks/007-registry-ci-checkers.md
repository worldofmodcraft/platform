# Task 007: Registry CI checkers — the gates that decide what a registry PR is allowed to do

- **Mission:** SITE-V1, deliverable **D1** ("CI checks (GitHub Actions), each with a clear failure
  message") — **Status:** **spec-approved (manager, 2026-09-06)**, dispatch gated on registry PR #4
  merging (see Dependencies).
- **Agent / model:** implementer / sonnet
- **Budget:** medium (≤ 3 agent-sessions). Exceeding it is a stop-and-report event (MANAGER.md §8),
  not something to push through.
- **Branch / worktree:** `task/007-registry-ci-checkers` — **registry** repo, worktree
  `~/wt/registry-task-007`. The platform side is this spec file only.
- **Graph:** builds node **N3 `registry-ci`**. Implements edges **E2** (`entry.schema.json`),
  **E3** (`page.schema.json`), **E4** (`append-only.rules.md`) and **E16** (`ownership.md`).
  Introduces **no new edges**.

## Why this task was split, and where the other half went
Written down because the ledger has been wrong about this shape before. Mission D1's CI section is
one deliverable but two different *kinds* of work:

- **the checkers** — pure decision logic over a pair of JSON documents and a claimed author
  identity, fully demonstrable offline, which is where this project's verification actually works;
- **the wiring** — a GitHub Actions workflow, PR comments, `CONTRIBUTING.md`, and acceptance
  criteria of the form "a real PR was rejected with this message", which need live PRs against a
  protected repository and Ludwig's eyes.

Mixing them produces a task whose criteria cannot all be demonstrated by one agent in one worktree,
which MANAGER.md §5 calls mis-scoped. **This task is the checkers. The wiring is task 039**
(`docs/tasks/039-registry-ci-workflow.md`, draft), and D1 is complete only when both are done.
Nothing in D1 is dropped by the split; the split is recorded in the mission log.

## Objective
Four checkers exist in the registry repository as offline, importable, individually runnable Python
tools, each returning a machine-readable verdict and a human-readable failure message, and each
demonstrated against hostile fixtures:

1. **PR classification** — given the set of paths a PR changes, decide which of the registry's PR
   shapes it is (entry-touching, `page.json`-only, reserved-namespace, other/mixed) and therefore
   which gates and which downstream pipeline apply (ADR-0059 §3: a `page.json`-only PR carries no
   version and triggers no build).
2. **Schema validation** — every changed JSON file validated against the schema its path implies,
   using the repository's own stdlib validator.
3. **Append-only** — a field-level diff of `old`/`new` `entry.json` implementing
   `contracts/append-only.rules.md` exactly, including the single permitted takedown transition.
4. **Ownership** — the PR author's **numeric account id** compared against `owner.id` for every
   namespace the PR touches, implementing `contracts/ownership.md` (E16), including first-publish
   binding and the ADR-0119 reserved-namespace path.

"Exists" means: on `main` in the registry, with tests, with `docs/tasks/007-verify.sh`, and with the
two hostile fixtures named below permanently in the suite.

## Context to load (complete; ADR selection performed against docs/decisions/INDEX.json)
**Contracts (the specification — these are implemented, not interpreted):**
- `contracts/append-only.rules.md` — 511 lines, all of it. The five `versions[]` rules, the
  comparison model, the four file-level existence states, the takedown carve-out, the ordering /
  remove-and-re-add / malformed-edit sections, and "What this document does not cover".
- `contracts/ownership.md` — **merged by registry PR #4**; the E16 contract. Read the merged text,
  not the PR description.
- `contracts/entry.schema.json`, `contracts/page.schema.json`, `contracts/manifest.schema.json`,
  `contracts/examples/**`, `reserved-namespaces.json`, `docs/contracts/README.md`.
- `tests/contracts/schema_check.py` — the validator you must use. `validate(instance, schema)`, in
  that order; it **raises** `SchemaValidationError` rather than returning a list, and raises
  `NotImplementedError` on any JSON Schema keyword it does not support, deliberately.

**ADRs (binding):** 0058 (§2 ownership by numeric id, §3 namespace creation and its confirmation
text, §4 provider neutrality), 0041 (integrity chain; `status: "removed"` paired with a reason;
takedown for legal grounds only), 0059 (§2 page content shape, §3 the lighter `page.json` gate),
0119 (reserved namespaces `mc`/`test`, organisation-owned, §3's org-membership authorisation),
0039 (registry as a git repo), 0042 (updates and versioning — read to confirm it imposes no
monotonicity requirement, which append-only rule 5 relies on), 0120 (content whitelisting — listed
because it is what the deferred screenshot scan below would enforce, so a reader can see the
boundary was considered rather than missed).

**Doctrine:** `CLAUDE.md`; `docs/manager/MANAGER.md` §2c (all five rules), §3.3, §3.7, guardrail 6c;
`docs/manager/REVIEW-CHECKLIST.md`; `docs/manager/OPERATIONS.md` ("Tool interfaces that are easy to
get wrong", and the Environment section: **Python 3 standard library only** — no pytest, no
jsonschema; tests run with `python3 -m unittest`).

**Prior work worth reading rather than rediscovering:** `docs/tasks/006-contracts.md` (four review
rounds; the faithful-checker walkthrough near the end is the reading this task turns into code) and
`docs/tasks/002-asset-scanner.md` (the style precedent for a tool + report + exit codes).

## Acceptance criteria — every one demonstrated by `docs/tasks/007-verify.sh`
1. **The four checkers run standalone**, each with a documented CLI, and each emitting a verdict
   object conforming to a stated report shape (reuse `contracts/validation-report.schema.json`'s
   shape if it fits; if it does not, say why in the log and define the shape in the task, do not
   quietly invent a second convention).
2. **Exit codes are distinguishable and documented**: accepted / rejected / usage-or-internal error
   are three different exits. Reading a usage error as a rejection once produced a completely false
   verification on this project (OPERATIONS.md) — the codes exist so that cannot recur.
3. **THE MALICIOUS FIRST-PUBLISH FIXTURE (required, permanent).** Task 006's `attacker:mod` entry —
   `absent → present`, four version objects — is in the suite, built from the same construction as
   `docs/tasks/006-verify.sh` lines 210-262, and the append-only checker **rejects it**. The test
   asserts **which rule rejects which element**, not merely that it was rejected:

   | Element | Content | Must be rejected by |
   |---|---|---|
   | 0 | `version "1.2.0"` | **rule 4** (with element 1) |
   | 1 | `version "1.2.0"`, **different commit** | **rule 4** |
   | 2 | `version "2.0.0"`, `status "removed"`, **no `reason`** | **rule 2** |
   | 3 | `version "2.1.0"`, `status "removed"`, `reason "   "` | **rule 2**, on the after-stripping clause |

   The premise is part of the fixture: `entry.schema.json` **accepts** this entry
   (`SCHEMA VALIDATION: PASS`), which is exactly why schema validity cannot be the whole rule at a
   first publish. Task 006 could only reason about this on paper — **this task is its first real
   execution**, and the log says so.
4. **THE OWNERSHIP FIXTURE (required, permanent, Ludwig's).** A PR whose **author id differs from
   `owner.id` while the username matches** is rejected. The username-matching half is the point: a
   checker that compares names passes this fixture and is wrong, so the fixture must be able to
   tell the two implementations apart. Add its mirror: author id **matches** while the username
   differs (a legitimate rename) — **accepted**.
5. **First publish binds, and binding is not a bypass.** A first publish of a namespace is accepted
   and records the binding; a *second* PR to that namespace from a different id is rejected. A first
   publish whose namespace merely *resembles* an existing owner's name gains nothing.
6. **Reserved namespaces (ADR-0119).** `mc` and `test` are authorised by **organisation
   membership**, not by `owner.id` equality with an individual, and rejected otherwise with a
   message naming ADR-0119. Membership is a live-API fact: it enters the checker through an
   **injected oracle** (a parameter/callable), so the logic is testable offline and the only
   untestable part is the one real API call, which belongs to task 039. State this seam explicitly.
7. **The takedown transition is implemented and is the only in-place mutation accepted.** A PR
   flipping an existing element's `status` to `"removed"` with a non-empty `reason` passes; the same
   PR without a reason, or changing any other field of that element, or changing a second element in
   the same PR, is rejected. **The checker never merges anything** — MANAGER.md §7 makes a takedown
   Ludwig's written decision, and the checker's verdict is input to that, never a substitute.
8. **PR classification is exhaustive and fails closed.** Every changed-path set lands in exactly one
   class; anything unrecognised is a rejection with a message, never a silent pass. A PR mixing
   `page.json` with `entry.json` does **not** get the lighter `page.json` gate.
9. **Positive controls are in the suite beside the hostile fixtures** (MANAGER.md §2c rule 5): real,
   legitimate PR shapes — a clean first publish, a clean version append, a clean `page.json` edit, a
   legitimate rename — that must be **accepted**. A suite that passes by rejecting everything is not
   a suite.
10. **Every rejection message names what was wrong and what to do about it** (D1: "each with a clear
    failure message"), and identifies the rule or ADR clause it enforces. Asserted by test over the
    message text, not by inspection.
11. **`docs/tasks/007-verify.sh` exists, is executable, and is mutation-tested** (MANAGER.md §2c):
    break what each check claims to check and show the check redden. Prove it passes in a **fresh
    clone**, not only the authoring worktree — task 006's script passed only where it was written.
12. **Docs move with the code:** `docs/contracts/README.md`'s "What is deliberately not here"
    currently says task 007 builds the gates; update it to reflect what now exists and what task 039
    still owes.

## Explicitly OUT of scope
- **The GitHub Actions workflow, PR comments, the ADR-0058 §3 confirmation text as rendered output,
  and `CONTRIBUTING.md`** — all task **039**. This task produces the message *strings*; 039 puts
  them in front of a human.
- **The asset scan on new `page.json` screenshots** that ADR-0059 §3 requires. It is **not dropped —
  it is blocked**: a `page.json` screenshot is a path *into the archived source tarball* (ADR-0059
  §1, `contracts/archive-layout.md`), and no archive exists until task 008 builds node N6. Booked as
  task **040** and raised to Ludwig in the mission log, because until it lands a `page.json` PR
  merges without its screenshots ever being scanned.
- The build pipeline, archiving, signing, the manifest/SPDX validator, the asset scanner itself
  (task 002, already merged) — tasks 008 and beyond.
- **Widening any schema.** Task 034 owns the `screenshots[]` pattern. If a checker needs a schema
  change, **stop and report** (§3.3); do not edit a merged contract from inside this task.

## Forbidden here (beyond the standing MANAGER.md §3.7 list)
- **Inventing registry semantics the contract does not state.** Append-only rule 5 says explicitly
  that nothing requires new versions to be numerically greater, or `published_at` to increase. A
  checker that enforces monotonicity is implementing a decision nobody made. Same for
  semver-normalised version comparison: rule 4 is **exact string equality**, and the gap is booked
  as question Q11 in `docs/tasks/006-contracts.md`, not closed here.
- **Comparing usernames anywhere a numeric id is specified.** ADR-0058 §2 exists because usernames
  are recyclable. Criterion 4's fixture is designed to catch exactly this.
- **A checker that reaches the network.** All four are pure functions of their inputs plus injected
  oracles. The one real API call (org membership) is task 039's.
- **Reimplementing the JSON Schema validator.** Use `tests/contracts/schema_check.py`. If it raises
  `NotImplementedError` on a keyword a contract uses, that is a finding to report, not a keyword to
  quietly emulate — the exception exists so an unsupported rule can never be silently ignored.
- **A test that can only confirm what its author already believes.** This project's signature
  failure, seen five times. Every hostile fixture must be shown to redden when the defence it probes
  is removed.

## Dependencies and sequencing
- **Blocked on registry PR #4 (task 032, `contracts/ownership.md`) merging.** Criteria 4-6 are
  implemented *from that document*; dispatching before it merges means coding the ownership gate
  from an ADR read cold, which is precisely what the E16 amendment was created to prevent.
- Needs task **006** (merged, registry PR #2) and task **025** (merged, registry PR #3).
- **File overlap:** none with task 034 (schemas) beyond reading them; sequence after PR #5 merges to
  avoid two branches editing `tests/contracts/`.
- **Blocks:** task 039 (the workflow), and mission acceptance criterion 1's registry half.
  Task 008 is independent of this task and may run in parallel.

## Verification artefact (MANAGER.md §2c)
Declared: **`docs/tasks/007-verify.sh`**, in the file scope, executable, and the task log pastes
**its** output — not a hand-assembled transcript. Every criterion above is command-based, so none is
exempt. This is not a fix round, so §2c rule 5's "the found break as a fixture" applies in its
forward form: criteria 3 and 4 name the two breaks the suite must contain from the start.

## File scope (declared; anything else = stop and report)
- `tools/registry/` (new) — the four checkers and their shared report code.
- `tests/registry/` (new) — the suite, including the fixtures from criteria 3, 4, 5, 9.
- `docs/tasks/007-registry-ci-checkers.md` (the task log, carried into the registry repo).
- `docs/tasks/007-verify.sh` (new, executable).
- `docs/contracts/README.md` (criterion 12 only).

## Questions
Booked, not assumed (MANAGER.md §8b): none blocking at spec time. The screenshot-scan deferral above
is a manager decision with its reasoning recorded, and is raised to Ludwig as an FYI rather than
asked as a question, because the sequencing fact (no archive before task 008) is not in doubt.
