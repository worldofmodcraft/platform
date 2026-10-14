# ADR-0121: Version lifecycle — a `pending` state, a one-time pipeline write-back, and a post-merge build

- **Status:** Proposed (awaiting Ludwig; not law until he accepts it)
- **Date:** 2026-10-14 · **Area:** Registry / Build pipeline
- **Touches:** registry, registry/ci, build-pipeline, launcher/resolution
- **Related:** ADR-0039, ADR-0040, ADR-0041, ADR-0058, ADR-0119; task 057 (the contract change this unblocks)
- **Will amend on acceptance:** ADR-0041, ADR-0058 (deliberately not in an `Amends:` header yet: the generator requires matching `Amended by` lines in the targets, and a proposal must not edit accepted ADRs. The accepting commit converts this line to `Amends:` and adds both back-references.)

## Context
ADR-0041 says versions are immutable and lists the statuses. ADR-0058 §1 describes one flow in
which the pipeline builds the PR's commit, writes the hashes into the entry and merges, and returns
rejections in the PR. No ADR defines a `pending` state (task 057's spec, blocker B1, found this by
reading ADR-0041, 0058 and 0039 and grepping the log).

On 2026-10-14 Ludwig decided (Q-B) how the author's PR and the pipeline meet:

- the author's registry PR adds a version with only `version`, `commit`, `source_url` and
  `status: "pending"` — the three fields the author can know;
- the pipeline builds after that PR merges, then opens a **write-back PR** that fills in
  `source_archive`, `source_sha256`, `signature`, `key_id`, `published_at` exactly once and sets
  `status: "published"`;
- this is a second permitted in-place transition beside the takedown.

Read literally, that edits an existing version object in place (ADR-0041 "Versions are immutable"),
introduces a status ADR-0041 does not list, and builds after merge rather than before
(ADR-0058 §1). Task 057 treats these as a conflict that needs a recorded decision, and the
`entry.schema.json` / `append-only.rules.md` contracts cannot be changed under an accepted ADR that
says otherwise. This ADR is that record.

## Options considered
- **A. The `pending` transition, as decided (Q-B).** Author PR adds a four-key `pending` version;
  post-merge build; one pipeline write-back PR completes it once.
  - Pro: the author supplies only what the author can know; no secret is exposed to an
    unmerged, author-controlled PR; the registry stays a plain git repo with PRs only (ADR-0039).
  - Con: the registry briefly contains versions that are not installable; a third state and a second
    in-place mutation exist; a `pending` version occupies its version string and cannot be deleted.
- **B. Author "request" files.** The author PR adds a separate request file (for example
  `requests/<id>-<version>.json`); the pipeline builds it and itself creates the version entry in the
  registry, so the registry never holds a `pending` version and `versions[]` is only ever appended to.
  - **Rejected by Ludwig.** Recorded reasons, as given in the decision: it adds a second kind of
    registry object with its own lifecycle, cleanup and validation rules, and moves the author's
    version-creation act out of the entry the rest of the system reads, to avoid a state that A
    handles with one small, checkable rule. (If Ludwig wants his wording recorded verbatim, he
    should replace this sentence on acceptance.)
- **C. Build before merge, as ADR-0058 §1 literally reads.** On the author's PR, a workflow fetches
  the commit, validates, builds, signs and archives, then writes the hashes into the PR's entry
  before the merge. Rejections are logged in the PR. No `pending` state exists.
  - Feasible, but only with care. Unverified GitHub specifics are marked `[unverified]`.
  - Pro: matches ADR-0058 and ADR-0041 as written, so no amendment; a rejected build never
    reaches `main`, so no squatted version strings and no Q-J; every merged version is complete.
  - Con 1: the signing key (ADR-0041: "usable only by the build workflow") must be usable from a
    run triggered by an untrusted author's PR. The standard split — unprivileged build job, privileged
    signing job that sees only hashes — removes most of the risk but is a larger security surface
    than A, where nothing privileged runs until the PR has been merged by a reviewer or the
    ownership check. `[unverified]` that a fork PR's `pull_request` run has no access to secrets; this
    is the usual GitHub behaviour but has not been checked here.
  - Con 2: the pipeline must write hashes into the author's PR branch. That needs push access to the
    author's fork or a pipeline-opened replacement PR; either way the author's PR is no longer the
    thing that merges, which is B's problem in another place. `[unverified]` whether "allow edits
    from maintainers" is available for every fork.
  - Con 3: artefacts and source tarballs are archived to platform storage before merge, so closed or
    abandoned PRs leave archived artefacts that must be garbage-collected or are kept without a
    registry entry, which sits badly with ADR-0041's "registry points at our copy".
  - Con 4: a build takes real time; merges to the same entry in the meantime force a rebuild or a
    conflict. A has no such window because the build starts from merged state.
  - Con 5: the accepted dependency graph (edge E15, Ludwig's Q4=A in session 1, as cited by task
    057) already moved the build to after the merge. Choosing C would reverse an accepted
    graph decision as well as Q-B.

## Decision
**A.** The registry has a three-state version lifecycle with exactly three permitted transitions:

1. **Born `pending`.** An author PR may append a version only as `pending`, with exactly the keys
   `version`, `commit`, `source_url`, `status`.
2. **T1, `pending → published`** — the pipeline's write-back PR. It adds exactly `source_archive`,
   `source_sha256`, `signature`, `key_id`, `published_at`, sets `status` to `published`, and changes
   nothing else; `version`, `commit` and `source_url` are frozen. It happens exactly once: a
   `published` version is covered by plain immutability, so the five fields can never be rewritten.
3. **T2, `published → removed`** — the existing takedown (ADR-0041), unchanged.
4. **T3, `pending → rejected`** (Q-J, below).

No other change to an existing version is permitted. Shape rules (which key sets and transitions are
legal) belong to `append-only.rules.md`; who may carry T1/T3 (the pipeline identity) and T2
(organisation takedown) belongs to `ownership.md`. Until that authority rule exists, a checker must
reject every T1 or T3 mutation whoever authors it (fail closed).

### Q-L — newly appended versions may only be `pending`
**Proposed, awaiting Ludwig.** Manager's lean: yes. A newly appended element must be `pending` with
exactly four keys. Today an author PR may append a version already `published` or already
`removed`; under Q-B that would let an author write their own hashes and skip the pipeline, so
shape-level rejection of born-published and born-removed is the safe default. There are no registry
entries to migrate (task 057 spec, checked 2026-10-14). If Ludwig answers no, born-published
versions remain shape-legal and only the ownership layer stops forgery.

### Q-J — a version whose build is rejected
**Proposed, awaiting Ludwig.** Manager's lean: a third transition `pending → rejected`. The pipeline's
PR sets `status: "rejected"` and adds `reason` (non-empty after trimming) and `build_log_url` (a link
to the full build log). The version is never deleted and its version string stays occupied; the
author fixes the problem and publishes a new version. `rejected` is terminal, and a `rejected`
version is never installable or resolvable. This keeps "nothing unpublished" (ADR-0041): the
registry records that the version was proposed and why it failed, in the same spirit as `removed`
keeping its reason. Alternatives not chosen in this proposal: deletion of the pending element
(violates append-only and loses the record; also lets an author retry the same version string after
a hostile build), or leaving it `pending` forever (squats the string with no explanation).
If Ludwig answers otherwise, T3 is dropped from this ADR and task 057 is amended again.

### Amendments

**ADR-0041, "Hash in registry" bullet.** Quoted: *"Versions are immutable; existing hashes can never
be updated, only new versions added (enforced by a CI check on registry PRs)."* Amended to: a
version is immutable **except** for the transitions T1, T2 and T3 above, each defined by exact key
sets and each performed at most once per version. "Existing hashes can never be updated" is kept
unchanged: T1 adds hashes that did not exist, and no hash is ever altered. "Only new versions added"
now reads "new versions are added only as `pending`" (Q-L). The CI check is extended to classify
every element as unchanged, T1, T2 or T3.

**ADR-0041, "Statuses" bullet.** Quoted: *"authors may mark a mod **deprecated** … Only legal grounds
… lead to **removed**: artefacts pulled, registry entry kept with status and reason …"* Amended: the
version status set also contains `pending` (born, not installable, no artefacts) and, if Q-J is
accepted, `rejected` (terminal, with reason and build log link, no artefacts). `deprecated` and
`removed` are unchanged. `deprecated` remains a mod-level mark; this ADR adds no author-initiated
way to remove a version.

**ADR-0058 §1, sequence.** Quoted: *"The pipeline fetches that exact commit, validates, builds, signs,
archives artefacts + source tarball to platform storage, writes hashes into the entry and merges.
Rejections return the full log in the PR."* Amended: the opening of the PR is unchanged
(`modcraft publish` opens a PR with id, version, commit hash and source URL; the entry is `pending`).
The author PR is validated for shape and ownership and merged **before** the build. The pipeline then
fetches the exact commit, validates, builds, signs and archives, and **opens a write-back PR** that
applies T1. "Writes hashes into the entry and merges" therefore refers to that second,
pipeline-opened PR rather than to the author's. Archiving, signing, hashing and source-tarball
steps are unchanged.

**ADR-0058 §1, rejections.** Quoted: *"Rejections return the full log in the PR."* Amended: a
rejection is reported in two places — a comment with the full log on the already-merged author PR,
and, if Q-J is accepted, a T3 PR carrying `reason` and `build_log_url` into the registry entry.
Nothing is reported by blocking the author's merge, because the build no longer precedes it.
Pre-merge validation (shape, ownership, `validate` output reproduced by CI) still rejects in the
PR as before; only the build, signing and archiving stages move after the merge.

ADR-0058 §§2-5 are not amended.

## Consequences
- The registry contains versions that are not installable. Every consumer (launcher, site, kernel
  resolver) must treat `pending` and `rejected` as non-resolvable and say so in the error
  ("version exists but is not yet published"), not as "not found".
- `entry.schema.json` must express three or four key sets by status; task 057 chooses the schema
  form and the validator support it needs. `append-only.rules.md` gains T1 (and T3 if accepted), and
  its "one permitted in-place mutation" wording becomes plural.
- A `pending` version occupies its version string and cannot be deleted. Authors can squat strings
  with versions that never build; T3 turns such a squat into a recorded, explained terminal state
  rather than removing it. The squat itself is still possible; the cost falls on the squatter's own
  namespace only.
- T1 is shape-checked only. A write-back with a well-formed but wrong hash cannot be caught by the
  contract; defence stays with the pipeline-identity carve-out and the fresh hash and signature
  verification on install (ADR-0041 install chain). Because T1 happens once, a wrong hash is
  corrected by a new version or a takedown, not by rewriting.
- The pipeline needs write access to the registry via its own PRs, and a trigger that fires on merge
  of an author PR (the pipeline-trigger contract, edge E15). Neither is defined by this ADR.
- ADR-0041 and ADR-0058 must carry `Amended by: ADR-0121` once this is accepted; the ADR index
  generator enforces the back-reference. Documents that say "a version starts `published`" or
  "all nine fields are required" (`entry.schema.json`, `append-only.rules.md`) change in task 057.
- Reverting to build-before-merge (Option C) later would need a superseding ADR.

## Interacts with
ADR-0039 (registry is a git repo — unchanged, PRs only), ADR-0040 (build pipeline order — build
now follows the author merge), ADR-0041 (amended), ADR-0058 (amended), ADR-0119 (reserved
namespaces: T1/T3 apply to them identically; owner stays frozen), task 057 (unblocked by this
ADR), task 008/008b (post-merge build and rejection reporting), `ownership.md` (authority for T1/T3).
