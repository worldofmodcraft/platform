# Task 057: The version lifecycle contract — `pending → published` in `entry.schema.json` and `append-only.rules.md`

- **Mission:** SITE-V1 (unblocks deliverables D1 and D2) — **Status:** draft (spec written 2026-10-14 under task 054). **BLOCKED on ADR question B1 below. Not dispatchable until Ludwig rules on B1 and on D-2, and this spec is spec-approved.**
- **Repo:** registry (`worldofmodcraft/registry`); this file is kept in the platform repository's `docs/tasks/` with the other 054 specs and copied to the registry branch's `docs/tasks/` as that task's log.
- **Agent / model:** doc-writer / sonnet for the contract text; implementer / sonnet for the schema, the `oneOf` support in the test validator, and the verify artefact (one branch, sequenced). Independent reviewer required: this amends two accepted contracts.
- **Budget:** medium (≤ 3 agent-sessions)
- **Branch / worktree:** `task/057-version-lifecycle` / `~/wt/registry-task-057`
- **Decided by:** Ludwig, 2026-10-14, "Stjärna på allt" (mission log on `session/8-status`), Q-B — the author PR adds a version with only `version`, `commit`, `source_url` and `status: "pending"`; the pipeline's write-back PR fills in the rest and sets `published`; this is the second permitted in-place transition, beside the takedown; "it is written into the contracts by its own reviewed task (057)".

## Objective
The two accepted contracts stop contradicting the pipeline. Today `entry.schema.json` requires nine
fields on every version object although the author can supply only three, and `append-only.rules.md`
forbids the write-back that would add the rest. After this task: a version object has three
states (`pending`, `published`, `removed`), each with an exact key set; exactly one transition
leaves `pending` (to `published`) and exactly one leaves `published` (to `removed`, the existing takedown);
the fields each party supplies are named; nothing else may change; and every statement is
demonstrated by a fixture corpus that fails when the contract is weakened.

## BLOCKER B1 — ADR text that the decision strains (checked 2026-10-14 on platform `main` 73ed6a1)
Read in full: `docs/decisions/0058-publishing-flow.md`, `0041-integrity-chain-and-archiving.md`,
`0039-registry-as-git-repo.md`. `grep -il pending docs/decisions/*.md` finds only ADR-0026, which is
unrelated (Eluna). **No ADR defines a `pending` state.** Two passages conflict with Q-B on a literal reading:

1. **ADR-0041, first bullet:** *"Versions are immutable; existing hashes can never be updated, only new versions added (enforced by a CI check on registry PRs)."* Q-B edits an existing
   version object in place (adds five fields, changes `status`). It adds hashes that did not exist
   rather than *updating* one, so the second clause is arguably kept; the first clause, "Versions are
   immutable", is not kept on its plain reading. The takedown carve-out already stretches "immutable"
   (`append-only.rules.md`, "The one permitted in-place mutation") but changes one status field and
   adds a reason; Q-B adds five fields.
2. **ADR-0041, "Statuses" bullet** lists `deprecated` and `removed`; the schema's own description
   calls `status` a *closed enum* "published / removed" and says "a version starts `published`".
   Q-B adds a third value and a different starting state. (The "starts published" sentence is the
   contract's, not an ADR's, but it is the contract's reading of ADR-0041.)
3. **ADR-0058 §1:** *"The pipeline fetches that exact commit, validates, builds, signs, archives … writes hashes into the entry and merges. Rejections return the full log in the PR."* This
   describes one flow in which the PR is built **before** it merges and a rejection is reported in that PR. The
   accepted dependency graph (E15, Ludwig's Q4=A of session 1) already moved the build **after** the merge,
   and Q-B makes that concrete: the author's PR merges with a `pending` version and a second PR
   writes back. Whether "writes hashes into the entry and merges" can cover a second, pipeline-opened
   PR is a reading; "Rejections return the full log in the PR" cannot be satisfied by a post-merge
   build except by commenting on the already-merged PR (what task 008b does).

**This spec does not paper over that.** It treats the three passages as a conflict that needs a new ADR
(working title: "Version lifecycle: `pending`, one-time write-back, and the post-merge build"), amending
ADR-0041 (immutability wording, statuses) and ADR-0058 §1 (sequence), accepted by Ludwig **before** this
task is spec-approved. `docs/decisions/` is Ludwig's and is outside this task's scope and outside this
agent's; the manager books the ADR draft. If Ludwig rules instead that Q-B is a *clarification* of the
existing ADRs, he says so in session, the ruling is quoted here, and B1 closes — that is his call, not
this spec's. **Until one of those two things is on record, 057 stays a draft.**

Related consequence, recorded not decided: a `pending` version occupies its `version` string
(`append-only.rules.md` rule 4) and cannot be deleted (rule 3). What happens to a version whose build is
rejected is open question Q-J (umbrella 008 and 008b), deliberately **not** answered here by adding a
`rejected` state; if Q-J is answered A, this task's contract is amended again.

## Context to load (exhaustive)
- ADRs: 0041, 0058, 0039, 0119 (reserved namespaces: their `owner` freeze), 0103 (boring), 0117 (graph first). Task 054 finding F1 (umbrella `docs/tasks/008-build-pipeline.md`).
- Registry `origin/main` (ec56e9f when read): `contracts/entry.schema.json`, `contracts/append-only.rules.md` (all of it, esp. "File-level existence", rules 1-5, "The one permitted in-place mutation: takedown"), `contracts/examples/entry/**`, `tests/contracts/test_contracts.py`, `tests/contracts/schema_check.py` (supported keywords: `type pattern minimum minLength maxLength minItems enum required properties additionalProperties items` plus annotation keywords; **no `oneOf`, `anyOf`, `if`, `const`, `$ref`** — read 2026-10-14; unsupported keywords raise `NotImplementedError`), `docs/contracts/README.md`.
- `origin/task/032-ownership-contract:contracts/ownership.md` and task 032's takedown exception `R11` (precedence over R3, R7; "one authorised takedown PR may carry any number of takedown mutations, provided the diff contains nothing else" — Ludwig's confirmation, mission log). **Note:** `grep -n R11` on `origin/task/032-ownership-contract:contracts/ownership.md` printed nothing on 2026-10-14; the round-4+ text is presumably on a later commit or unpushed. Re-read at sequencing time; this spec quotes R11 only as the mission log describes it.
- `origin/task/045-takedown-mutation-shape` (spec only so far): 057 edits the same file as 045's implementation.
- Site repo `src/lib/validate.mjs`: uses Ajv 2020 with `strict: true` (read 2026-10-14) — relevant to D-1.

## Design (decisions made in this draft; D-2 is Ludwig's)

### The version object has three states, each an exact key set
| status | exact keys (no others) | who creates / changes it |
|---|---|---|
| `pending` | `version`, `commit`, `source_url`, `status` | the author's PR (E2), as a newly appended element only |
| `published` | the above plus `source_archive`, `source_sha256`, `signature`, `key_id`, `published_at` (nine keys) | only by transition T1 |
| `removed` | the nine keys plus `reason` (non-empty after trimming) | only by the takedown, transition T2 |

### T1, the `pending → published` transition (the second permitted in-place mutation)
For an index `i < n`, `new.versions[i]` may differ from `old.versions[i]` under T1 if, and only if, **all** hold:
1. `old.versions[i].status == "pending"` and `new.versions[i].status == "published"`.
2. **Author-supplied fields, frozen:** `version`, `commit` and `source_url` are deep-equal to the old values.
3. **Pipeline-written fields, each present in `new` and absent in `old`:** `source_archive`, `source_sha256`, `signature`, `key_id`, `published_at`. Each satisfies its `entry.schema.json` pattern. (Shape only: this contract cannot check that a hash matches an archive or a signature verifies — no checker here has the tarball or the key. That is E9's verifiers' job (`signature-format.md`; task 055's site verifier; the launcher). See Attack 2.)
4. `new.versions[i]` has no key outside the nine, and no `reason`.
5. The array is otherwise untouched: rules 1-3 and "Ordering of `versions[]`" apply to every other element.

**Exactly once, structurally.** T1 requires `old.status == "pending"`, and a `pending` object has none of the five fields (shape table). After T1 the status is `published`, and a `published` element is covered by plain deep-equality (rule 1) — the five fields can never be rewritten. No `published → pending` (reverting) and no `pending → pending` change exist: both are rule-1 violations.

**Nothing else may change:** `id` and `owner` stay frozen; `page.json` is untouched by a T1 diff at this layer; no element is added, removed or reordered by T1.

### Coexistence with the takedown (T2)
- T1 and T2 start from different `old` states (`pending` vs `published`) and no state reaches both, so **one element cannot undergo both in one PR**. `pending → removed` is a violation (nothing was archived; there is nothing to pull). A T1 element carrying a `reason` is a violation (key set above).
- The takedown section's sentence *"This is the only status transition this document permits on an existing element"* becomes false and is amended to *"the only status transition permitted on an element whose old status is `published`"*; the "one-way and terminal" paragraph is unchanged in substance.
- **Two exceptions, not one.** Rule 1 is rewritten as three branches (unchanged / T1 / T2). The section heading "The one permitted in-place mutation: takedown" becomes "The permitted in-place mutations" with T1 and T2 as sibling subsections.
- **Shape layer versus authority layer.** `append-only.rules.md` classifies each element independently, so a PR holding a T1 on one version and a T2 on another is *shape-legal*. Who may carry which is `ownership.md`'s (E16): R11's takedown PR must contain nothing but takedown mutations, which excludes T1 in the same PR; the pipeline's carve-out (sibling task, umbrella 008 "Dependencies") must be keyed on "exactly T1 mutations". **Fail-closed default written into this contract:** *until `ownership.md` carries that carve-out, a checker implementing T1 must reject every PR containing a T1 mutation, whoever its author is.* Without it, an author could write their own "published" fields.
- Authority for T1 is therefore **not** defined here (as the takedown section says of T2: shape, not who).

### D-1 Schema representation (made here; reviewer may overturn)
`entry.schema.json`'s version-item `required` list of nine cannot stay, and `if/then` is unsupported by the repository's validator. Options:
- **S1★ `oneOf` with three branches** (one per status). Item-level `properties` keep every pattern once; each branch is `{type: "object", required: [...], properties: {<its keys>: {}, status: {enum: [<its status>]}}, additionalProperties: false}`, and `removed`'s branch requires `reason`. Needs `oneOf` added to `tests/contracts/schema_check.py` (and nothing else; unsupported keywords must still fail loudly) and a check that the site's Ajv 2020 in strict mode accepts the same schema (**unverified**; criterion 4). Keeps the schema strict: a `published` version without `key_id` (the existing invalid example `missing-key-id.json`) stays invalid, and a `pending` object carrying `signature` is schema-invalid.
- **S2 relax `required` to the four author fields, enforce status-by-shape only in task 007's checker.** Simpler validator; but `missing-key-id.json` would then *validate*, so that invalid example would have to be moved out of the schema tests — a weakened test by another name (CLAUDE.md rule 5) — and every schema consumer (site, launcher) would have to re-implement the status-by-shape rule.
Chosen: **S1**. This also closes the gap `entry.schema.json` records for `reason` ("this schema does not enforce that conditional requirement"): with `oneOf`, `removed` requires `reason` and the other branches forbid it. Trim-emptiness of `reason` stays the checker's (rule 2/T2).

### D-2 Born states — **needs Ludwig's ruling** (question Q-L below)
Today rule 2 lets any PR append an element already `published` (with nine fields it invents) or already `removed`. Under Q-B that would let an author skip the pipeline by writing a forged `published` object. This draft therefore says: **every newly appended element must be `pending`**. That tightens rule 2's "born removed" clause and the creation case; there are no entries in the registry to migrate (`git ls-tree origin/main mods` prints nothing, 2026-10-14). Mark: this is a behaviour change to an accepted rule, taken in this draft as the safe default, pending his word.

### D-3 What does *not* change
`id`, `owner` freeze; rules 3-5 (length, uniqueness by exact string, no monotonicity); the takedown's field-level shape and one-way terminal rule (045's precision work lands first and is not redone here); `page.json`.

## Edit map (so the diff is reviewable against anchors that exist today)
`contracts/append-only.rules.md`, quoted anchors verified 2026-10-14 on `origin/main`:
| anchor (text today) | change |
|---|---|
| Rule 1: "with exactly one permitted exception: the takedown transition" | three-branch statement: unchanged / T1 / T2 |
| Rule 2 and the creation case ("any element whose `status` is `"removed"` must carry a `reason`") | newly added elements must be `pending` with exactly the four keys (D-2); the born-removed pairing sentence is replaced, not duplicated |
| Rule 2: "`entry.schema.json` cannot express this conditional requirement" | false after S1; rewritten |
| "The one permitted in-place mutation: takedown (ADR-0041)" and bullet "This is the only status transition this document permits on an existing element" | heading and bullet amended as above |
| "Fields outside `versions[]`": "whose permitted changes (appending, and the one takedown transition below)" | "appending, T1 and T2" |
| New section "T1: `pending → published`" | the five numbered conditions, the fail-closed sentence, worked example, attack attempts |
`contracts/entry.schema.json`: items `required`, `status` enum (+`pending`), the item and field descriptions that say "required-9-field", "starts published", "Every element is a single published version", and `source_archive`'s "absent until the pipeline runs" (the sentence that contradicted `required`). `docs/contracts/README.md`: rows for both files updated, task 057 named.
Examples: `contracts/examples/entry/valid/pending-first-publish.json`, `…/valid/removed-version-with-reason.json` kept; `invalid/pending-with-signature.json`, `invalid/status-rejected.json`, `invalid/published-with-reason.json`; the existing `invalid/missing-key-id.json` must stay invalid.

## Acceptance criteria
1. **The ADR blocker is on record before anything else:** a quoted Ludwig ruling (new ADR accepted, or "clarification, proceed") appears in this file. Criterion 2 onward cannot start without it.
2. `append-only.rules.md` states T1 as the five numbered conditions above, the "exactly once" argument, the T1/T2 coexistence paragraph, the fail-closed sentence and the shape-versus-authority split. Every anchor in the edit map is changed; a grep for each *old* sentence in the table returns zero (with a positive control that the grep finds them in the pre-change blob).
3. `entry.schema.json` is S1 (or, if the reviewer overturns D-1, the alternative with its consequences stated). The registry's own tests pass: `python3 -m unittest` over `tests/contracts` exits 0, and `missing-key-id.json` is still rejected by name.
4. **Both validators agree.** The same entry corpus (all `examples/entry/**` plus the shape cases of the fixture file) is run through `tests/contracts/schema_check.py` and through Ajv 2020 with `strict: true` using the site repo's `node_modules` (path passed as an argument; if Node/Ajv is unavailable the verify script reports SKIPPED loudly and the criterion is not met — a skip never yields green). Any disagreement is a failure.
5. **Fixture corpus** `docs/tasks/057-transition-fixtures.json` (below) is complete and a reference oracle `docs/tasks/057-oracle.py` classifies every fixture as recorded. The oracle is **not** the checker and is not placed under `tools/`; task 007 must pass the same fixtures. Positive controls sit beside the hostile cases.
6. **Mutation (§2c rules 2, 5):** each of the oracle mutations listed below turns at least one fixture red, named; each contract-text mutation turns at least one text check red; each was shown red *before* the fix where a fix is involved, and restored byte-identically.
7. **No unpinned sentence:** the new "T1" section's sentences are all pinned in the verify script by full text (not 70-character prefixes — task 032's round-6 lesson); a sentence appended to the section turns a check red (the tail-append fixture, shown red first).
8. `docs/tasks/057-verify.sh` is committed, executable, deterministic (no network in the verdict), its scope check is merge-base-relative (task 045 criterion 6), and was run in a **fresh clone**; output pasted in the log.
9. Guardrail 6b/6c: every environmental statement made in the contract (e.g. about Ajv's strict mode) carries its command or an inline `[unverified]`.
10. The sibling contract gaps are named in the log but not done: `pipeline-trigger.md` (E15), the `ownership.md` carve-out (E16), the `artifact-naming.md` URL amendment (after task 058).

## Verification artefact (MANAGER.md §2c) — declared: `docs/tasks/057-verify.sh`
House style of `docs/tasks/032-verify.sh`: deterministic checks only decide the verdict; anything needing the network or another repo's checkout is labelled ADVISORY and cannot gate; an exit code reflects the failure count.

**Fixtures** (`057-transition-fixtures.json`; each has `name`, `old` (null for a first publish), `new`, `expect` = `accept`/`reject`, `rule`). Minimum set:
| name | expect | what it proves |
|---|---|---|
| first-publish-one-pending | accept | the author's PR is legal |
| first-publish-born-published | reject | D-2: forged published object |
| first-publish-born-removed | reject | D-2 |
| append-second-pending-after-published | accept | later versions |
| t1-exact | accept | the transition |
| t1-two-elements-two-transitions | accept (shape layer) | per-element classification |
| t1-extra-changed-field-commit | reject | frozen author fields |
| t1-source-url-changed | reject | frozen author fields |
| t1-missing-one-of-five (each of five, five fixtures) | reject | all five required |
| t1-extra-key | reject | key set |
| t1-with-reason | reject | key set / coexistence |
| t1-published-at-not-rfc3339, t1-sha256-wrong-length, t1-source-archive-http | reject | patterns |
| pending-with-partial-writeback (pending carrying `signature`) | reject | shape table |
| pending-to-pending-changed-commit | reject | frozen |
| pending-to-removed | reject | coexistence |
| published-to-pending | reject | one-way |
| published-rewritten-hashes (second write-back) | reject | exactly once |
| t2-takedown-exact | accept | existing behaviour unchanged |
| t2-with-t1-same-element | reject | coexistence (impossible start state) |
| t1-plus-whitespace-only-change-elsewhere | accept | comparison over parsed values (whitespace carries no meaning) |
| t1-plus-owner-change | reject | `owner` frozen |
| t1-reorders-versions | reject | ordering |
| delete-pending-version | reject | rule 3 |

**Oracle mutations (each must redden a named fixture):** drop the frozen-author-field check; allow `pending → removed`; stop requiring all five; allow `reason` on T1; allow born-published; allow `published → pending`; compare raw text instead of parsed values; treat the T1 key set as "at least" instead of "exactly".
**Text mutations:** delete the fail-closed sentence; delete the "exactly once" paragraph; change "exactly" to "at least" in condition 4; append a permissive sentence to the T1 section (tail-append); restore a stale takedown sentence.
**Positive controls** are the `accept` rows; a suite that rejects everything must fail here.

## Attack attempts the contract must answer (recorded in the new section, each against this document's own rule)
1. **Author self-publishes:** a PR appends a version already `published` with invented hashes. Answer: D-2 / shape table (rejected as born-published); and if D-2 were refused, only `ownership.md` + E9 verification would stand between a forged object and users.
2. **Garbage write-back by the pipeline identity:** a compromised or buggy pipeline PR writes a valid-shaped but wrong `source_sha256`. This contract **cannot** reject it (shape only). Defences: the carve-out keyed on the App's id and on "exactly T1"; the site's and launcher's fresh hashing and signature verification (`signature-format.md` rule 9-11); the fact that a wrong hash cannot be corrected (frozen) — so the remedy is a new version or a takedown. Stated as a known limit, not hidden.
3. **Splice a takedown into the pipeline PR** so a version vanishes unnoticed: shape-legal per element, rejected at the authority layer (R11 "nothing but takedown mutations"; the carve-out "exactly T1"). Test lives in the sibling tasks; this contract records the dependency.
4. **Pending squatting:** an author appends `pending` versions that will never build, burning version strings. Rule 4 makes the squat permanent. Recorded as the consequence behind Q-J; no new rule here.

## File scope (declared; anything else = stop and report)
Registry repo: `contracts/entry.schema.json`, `contracts/append-only.rules.md`, `contracts/examples/entry/**`, `tests/contracts/schema_check.py` (adding `oneOf` only), `tests/contracts/test_contracts.py` (only if a new test must be added for `oneOf` and the three-branch cases), `docs/contracts/README.md`, `docs/tasks/057-*` (this file as log, fixtures, oracle, verify script).
Out: `contracts/ownership.md` (task 032's; sibling task), `docs/decisions/` (Ludwig's), any checker under `tools/` (task 007), the site's vendored schema copies (task 041's sync; re-run after this merges — booked by the manager).

## Forbidden here (beyond MANAGER.md §3.7)
- Adding a `rejected`, `withdrawn` or any further state (Q-J is open).
- Moving `missing-key-id.json` or any invalid example out of the schema tests to make them pass.
- Implementing authority for T1 (who may perform it) or any checker.
- Stating Ajv/GitHub behaviour without a command or an `[unverified]` marker.
- Editing the ADRs or deciding B1.

## Dependencies and sequencing
`032 merged` (touches `docs/contracts/README.md`; Ludwig's fix round 6 approved) → `045 merged` (same file, `append-only.rules.md`; its takedown precision is the base 057 builds on) → **B1 ruling + D-2 ruling + spec-approval** → **057** → `007` (spec re-check; it validates author PRs against the amended schema) and `008a`/`008b` → site vendored-schema re-sync (task 041's procedure; blocks 055). Sibling contract tasks (E15 `pipeline-trigger.md`; `ownership.md` carve-out; `artifact-naming.md` URL amendment after 058) are independent files but 008b needs all of them.
Graph: no new node or edge. E2 and E8 already name `contracts/entry.schema.json`; E4 names `append-only.rules.md`. (Verified in `docs/architecture/depgraph.md` rows E2, E4, E8, 2026-10-14.)

## Questions  (agent-maintained; see MANAGER.md 8b)
- **B1 (blocks; Ludwig):** new ADR, or a ruling that Q-B is a clarification of ADR-0041/0058? Lean: new ADR (the immutability wording and the status set change; a future reader of ADR-0041 alone would be misled). | built on assumption: none.
- **Q-L (D-2; Ludwig):** may newly appended versions only be `pending` (tightening rule 2)? ★Yes. Alternative: keep born-published/born-removed legal and rely on the ownership layer alone — not recommended; it leaves author-forged hashes shape-legal. | built on assumption: yes, in criterion 2 and fixtures.
- **Q-J (open, inherited):** rejected pending versions (008b). Not answered here.

---
# Task 057 log  (append-only, updated continuously by the executing agent)
- 2026-10-14 spec written under task 054 from Ludwig's Q-B decision; nothing started; blocked on B1.
