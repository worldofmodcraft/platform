# Task 008b: Pipeline workflow — post-merge run, release upload, protected write-back

- **Mission:** SITE-V1, deliverable **D2** (second half; umbrella `docs/tasks/008-build-pipeline.md`) — **Status:** spec-approved (manager, 2026-10-15, after independent spec review rounds 1–2: PASS) 
- **Agent / model:** implementer / sonnet
- **Budget:** large (≤ 6 agent-sessions)
- **Branch / worktree:** `task/008b-pipeline-workflow` / `~/wt/registry-task-008b` — **registry** repo

## Objective
A merged pull request that adds a version to `worldofmodcraft/registry` causes, within minutes
and without a human, a workflow running on the registry's own `main` to: build the version with
008a's tool, upload the tarball and signature as a GitHub Release named per `artifact-naming.md`,
and land the six write-back values in `mods/<ns>.<name>/entry.json` through a same-repository pull
request that passes the registry's own gates and merges. The signing key is reachable only by that
workflow, only on `push` to `main`, never from a fork-triggered run. A failed build posts its full
log where the author will see it. The contract for the trigger (E15) exists first.

## Context to load (exhaustive)
- ADRs: **0121** (the `pending` lifecycle, the post-merge build, the write-back PR and rejections; amends 0041 and 0058 §1 — it is the authority for design 2, 4 and 7 below), 0041 (key in build secrets, usable only by the build workflow; archiving), 0058 §1 (as amended by 0121), 0040 §5, 0099 (CI
  gates), 0059 §3, 0103, 0117, 0119, 0120.
- Contracts: `entry.schema.json` / `append-only.rules.md` **as amended by task 057** (T1 `pending → published` and T3 `pending → rejected` — each pipeline PR's entire diff); `artifact-naming.md` (never overwrite an existing tag; "What this document does not
  cover" lists idempotency as this task's), `signature-format.md`, `archive-layout.md`,
    `contracts/ownership.md` on registry `origin/main` (task 032 merged, PR #4; `git -C /home/ludwig/registry show origin/main:contracts/ownership.md | grep -c R11` > 0) (the identity rule; `GITHUB_ACTOR*`
  forbidden as an identity source), `rebuild-trigger.md` (E12 — **not this task**; see 055, but the
  two interact, criterion 10).
- Platform docs: `docs/architecture/depgraph.md` (E15 and the Q4=A rationale in mission log Q4),
  `docs/architecture/key-management.md`, `docs/manager/OPERATIONS.md` ("Consequences of branch
  protection that bite later", "The manager's own permissions"), `docs/runbooks/site-v1-manual-steps.md` (M1.4, M3).
- Depends on 008a's tool, **merged**: `tools/pipeline/build_version.py` (CLI `--entry --version --workdir --key --pubkey --out`; exit 0 built, 1 rejected, 2 pipeline fault; outputs `<tag>.tar.gz`, `<tag>.tar.gz.minisig`, `result.json`, `build.log`), `tools/pipeline/naming.py` (`release_tag`, `asset_names`, `release_asset_url`), `signing.py`, `reference_verify.py`, `archive.py` — read from `git -C /home/ludwig/registry show origin/main:<path>` on 2026-10-15 (head `a50daac`). The test-only flags (`--allow-local-source`, `--clone-timeout`, `--max-*`, `--scanner`) must never appear in the workflow (008a booked finding 1). And on 008c's `tools/pipeline/write_back.py` (`apply_write_back`, `source_archive_url`, `write_back_values`).
- Graph: nodes **N5**, **N6**, **N2**, **N3**; edges **E7**, **E8**, **E15**, **E16**.

## Size (5b)
Large (≤ 6 agent-sessions), kept as one task on purpose: (1) the workflow, the planner, the release script and the `--no-sign` change are one security argument — the criterion-14 check and the sign step's re-verification only mean something together; (2) the reading list is long (about 12 items: ADR-0121, 0041, 0058 §1, four contracts, `ownership.md`, `depgraph.md`, `key-management.md`, OPERATIONS.md, the manual-steps runbook, 008a's four modules) but most are skimmed for one fact each, cited above by path; (3) the code written is small (a ~100-line workflow, two thin helpers, a flag). **Split trigger:** if after session 3 the `--no-sign` change and its tests (design 8, criterion 16) are not green, they become task 008d, a small offline task on 008a's tool, and 008b waits for it. Live criteria (6-11) need Ludwig's M5-M7 and are expected to dominate calendar time, not agent time.

## Environmental facts (what is verified, what is not)
- **Verified 2026-10-15 (against registry `origin/main` `a50daac`):** `build_version.py` is one process that clones, archives, scans, hashes **and signs**, taking `--key` and `--pubkey`: `git show origin/main:tools/pipeline/build_version.py | grep -n 'gitops.clone\|signing.sign'` finds both inside `execute()`. It has **no mode without a key** (`--key` and `--pubkey` are `required=True` in `parse_args`). The SSRF job split (design 8) therefore requires the `--no-sign` change that design 8 puts in this task's scope. `PyYAML` 6.0.3 imports in this session (`python3 -c 'import yaml; print(yaml.__version__)'`); whether it is on the CI runner is unverified.
- **Verified 2026-10-14:** `origin/main` of the registry has no `.github/` directory (`git -C
  /home/ludwig/registry ls-tree -r --name-only origin/main | grep -c '^\.github'` → `0`), and no
  `contracts/pipeline-trigger.md` (see umbrella F2). `github-actions[bot]` is numeric id 41898282
  (unauthenticated `GET /users/github-actions[bot]`). minisign behaviour: see 008a.
- **Unverified here (no workflow has ever run in this repo); each is tested by a criterion below,
  and the spec's rule stands regardless of the basis:**
  - GitHub-hosted runners can run the pinned minisign 0.12 static binary (the M3 download), and
    `ubuntu-latest` provides `git`, `gh`, `python3`. (criterion 7)
  - Pull requests and merges made with the workflow's built-in `GITHUB_TOKEN` do not trigger other
    workflows (documented GitHub behaviour), whereas those made with a GitHub App installation token
    do (documented; the reason Q-D chose an App). Neither has been observed here. (criterion 9)
  - A GitHub App installation token can be minted inside a workflow from the App id and private key,
    and can create a PR, merge it under the registry's branch protection, create a release in
    `worldofmodcraft/archive`, and send `repository_dispatch` to `site`. The minting step's
    action (commonly `actions/create-github-app-token`) and its pinned version were **not checked**;
    the implementer picks and verifies one. (criteria 6, 9)
  - A release can be created in `worldofmodcraft/archive` only if the repository has a commit for
    the tag to point at (hence M7's README); not verified. (criterion 6)
  - A repository secret is withheld from workflows triggered by fork pull requests (documented;
    the mission-log Q4=A design depends on it). (criterion 8)
  - `gh release create` with `contents: write` can create releases and upload assets in the same
    repository; a draft release can be deleted and recreated; a published release's tag can be
    detected. (criterion 6)
  - Whether branch protection on `main` currently requires status checks. OPERATIONS.md says
    "requires a pull request, blocks force-push and deletion, includes administrators, zero required
    approvals"; it does not say required checks. Task 039 may add them. Ludwig/manager confirms.

## Design (decisions made in this spec)
1. **Trigger (E15, Q4=A):** `on: push: branches: [main]` with `paths: ['mods/*/entry.json']`.
   Never `pull_request`, never `pull_request_target`, never `workflow_run` from a fork. A
   `workflow_dispatch` with a `dry_run` input exists for tests (criterion 10).
2. **What to build:** the workflow diffs the pushed range, lists version objects in the `pending`
   state (decided Q-B, Ludwig 2026-10-14; ADR-0121; shape defined by task 057), and builds each. Zero pending versions → the run succeeds doing
   nothing (this is what stops the write-back merge's own push from looping). It never trusts the
   diff for *authority*: the entry's content on `main` is the input, and 008a re-validates
   everything.
3. **Concurrency:** `concurrency: { group: pipeline, cancel-in-progress: false }`. Two merges
   queue; the second run sees the first's write-back PR (or waits for it).
4. **Branch and PR:** push `pipeline/<ns>.<name>-<version>` to this repository, open a PR to
   `main` whose diff is exactly one version object's `pending → published` transition T1 (task 057) — or, on rejection (design 7), exactly one `pending → rejected` transition T3. Two PRs per
   publish (OPERATIONS.md), by design. **Identity (decided Q-D, Ludwig 2026-10-14): the organisation-owned GitHub App**
   — one installation token minted per run, used for opening the PR, merging it, and (task 055) the
   site dispatch. The App id is a repository *variable* `PIPELINE_APP_ID`; the private key is the
   repository secret `PIPELINE_APP_PRIVATE_KEY` (both names are this spec's choice, not verified
   against anything). Used in exactly one step (the minting step), never echoed.
5. **Release (decided Q-E, Ludwig 2026-10-14):** in `worldofmodcraft/archive`, not this repository. Create the release as a **draft**,
   upload both assets, then publish. An existing release with that tag: published → fail with
   `artifact-naming.md`'s "never overwrite" wording; draft (an earlier run died mid-way) → delete
   and recreate. The tag is `ns.nm-v` and is created on the **archive** repository's default branch head (the registry's head would be meaningless there).
6. **Key:** `MINISIGN_SECRET_KEY` exists as an Actions secret (M3 done 2026-09-05 per the mission
   log). Used in exactly one step, via an environment variable scoped to that step only, handed to
   008a's tool as a process-substitution path (or a 0600 file under `$RUNNER_TEMP` removed in an
   `if: always()` step). No `set -x` anywhere in that step. The step prints nothing derived from the
   key. Whether the secret exists is **not** checked by this spec (see Questions).
7. **Failure (decided: ADR-0121 Q-J, Ludwig 2026-10-15):** a build rejection (008a exit 1) is reported in two places and never by blocking a merge (the author's PR has already merged): (a) a comment with the full `build.log` on the originating merged PR; (b) a pipeline PR, from the same App identity, whose diff is exactly one T3 transition — `status: "rejected"`, plus `reason` (non-empty after trimming; the rule/clause line from 008a's rejection message) and `build_log_url` (the permanent `https://` URL of `logs/<namespace>.<name>/<version>.log` in `worldofmodcraft/archive`, committed by the pipeline's App identity before the T3 PR opens; decided, Ludwig 2026-10-15, see "Decision recorded" below; the Actions run log is not the permanent reference). The `reason` is passed through 008c's `apply_write_back` (JSON-encoded, never string-spliced into a file) and length-capped there; the full text is in the log file. The version is never deleted; the author publishes a new version. Exit 2 is a pipeline fault → fail the run, comment nothing about the author's mod and open no T3 PR (a fault is not a verdict on the version; it stays `pending` and the run is retried by a fresh dispatch). A `rejected` version is not `pending`, so the planning step never rebuilds it.
8. **SSRF job split (decided: Ludwig 2026-10-15; requirement, not a preference).** `source_url` is author-controlled and may be an https URL naming an internal address; 008a does not filter addresses (008a Questions, A-3). The workflow therefore has three jobs with this separation: (i) **build job** — clones the author's repository, runs 008a's validation, archive and scan, and holds **no** secret: no `secrets.*` reference of any kind, no `secrets: inherit`, no job- or workflow-level `env` derived from a secret, `permissions:` limited to `contents: read`; (ii) **signing job** (`needs:` the first) — receives **only the built artefact** (tarball and `result.json` as workflow artifacts), never runs `git clone`, `build_version.py` or any fetch of `source_url`, and holds only `MINISIGN_SECRET_KEY`; (iii) **write-back job** — holds only the App secret, mints the token, commits the build log and uploads the release, opens the PR.
   **Required change to 008a's tool (in this task's scope; decided by the coordinator 2026-10-15).** Verified gap: `build_version.py` clones and signs in one process and has no mode without a key (see Environmental facts). Add to `tools/pipeline/build_version.py` a `--no-sign` flag and a separate sign step (`tools/pipeline/sign_built.py`, new, importing 008a's `signing` and `reference_verify`):
   - `--no-sign`: `--key` and `--pubkey` are not accepted (argparse error, exit 2, **before** any clone) — `--no-sign` together with `--key` is refused, the test-visible rule that the build job needs no key. Exit codes unchanged: 0 built, 1 rejected, 2 usage/pipeline fault. Outputs in `--out`: `<tag>.tar.gz`, `result.json`, `build.log`; **no** `.minisig`. `result.json` carries everything the one-shot mode's does except `artifact.signature` and `artifact.key_id` (absent, not empty) and gains `"signed": false`; `artifact.source_sha256` is present. The exact field list is pinned by a test against the one-shot `result.json` (the difference is those keys and nothing else).
   - sign step: inputs are the tarball, `result.json`, `--key`, `--pubkey`, `--out`. Before signing it re-checks, from the tarball alone and independently of the build job: compressed size and uncompressed size, entry count and per-entry rules against 008a's limits (`archive.inspect_archive`), and `sha256(tarball) == result.json.artifact.source_sha256`; any mismatch → exit 1-style refusal named, nothing signed. It signs with `signing.sign` using `signing.trusted_comment`, and its output must pass `reference_verify.verify` (as the one-shot mode does) or exit 2. Output: the `.minisig` and a `result.json` with `signed: true`, `artifact.signature`, `artifact.key_id`.
   - tests (offline, fixture-driven, in `tests/pipeline/`): (a) `--no-sign` followed by the sign step gives a `result.json` and `.minisig` equivalent to the one-shot build on the same fixture (same tag, sha, key_id, signature text modulo `built_at`); (b) `--no-sign --key k` and `--no-sign --pubkey p` are each refused before any clone; (c) a tampered tarball (one byte changed; an extra entry; size over limit) is refused by the sign step; (d) 008a's own suite still passes unchanged (one-shot mode untouched).
   Throwing out any of (a)-(d) is a stop-and-report.

9. **Retry after a pipeline fault.** A build that ends in exit 2 leaves the version `pending` on `main` (design 7). It is rebuilt by a non-dry-run `workflow_dispatch` with the input `version=<namespace>.<name>@<semver>`; the planner then builds only that version (and only if it is still `pending`). A dry run (`dry_run=true`) never takes this path. Pushes to `main` still plan all pending versions. Concurrency group `pipeline` applies, so a dispatch queues behind a running build.

## Acceptance criteria
Script = `docs/tasks/008b-verify.sh`; live = a real run, recorded with run URLs, **not**
script-verified.
1. [script] **The E15 contract exists first:** `contracts/pipeline-trigger.md` is present on `main`
   (landed by the contract task) and the workflow's trigger block matches it; the verify script
   greps the workflow for `on:` → `push` → `branches` `main` and **fails on zero matches**, and
   asserts the absence of `pull_request_target`, `pull_request:` and `workflow_run` in the
   signing workflow file.
2. [script] **The secrets are referenced exactly once each**: `secrets.MINISIGN_SECRET_KEY` in the signing step's `env:`, `secrets.PIPELINE_APP_PRIVATE_KEY` in the token-minting step; the verify
   script counts occurrences of `secrets.MINISIGN_SECRET_KEY` across `.github/` and asserts the
   count of each is 1 and that no `run:` block contains `echo`, `printf` or `cat` of either variable name,
   and no `set -x`/`-o xtrace` appears in the workflow. Mutation: add each forbidden pattern to a
   copy of the workflow and show the check redden.
3. [script] **Naming:** a unit test feeds `(namespace, name, version)` triples through the
   workflow's naming/URL helpers (008a's `release_asset_url`, 008c's `source_archive_url`) and asserts tag, both asset names and both URLs equal the `artifact-naming.md` examples (`mc.hello-world-1.0.0`,
   `.tar.gz`, `.tar.gz.minisig`), including a prerelease+build version. The `source_archive_url` expectation comes from task 058's report and any `artifact-naming.md` amendment, not from this sentence.
4. [script] **The write-back is exactly a permitted transition (T1; and T3 for the rejection PR):** a test builds the PR diff for a
   fixture entry (using 008c's `apply_write_back`) and runs it through task 007's append-only,
   schema and ownership checkers (with the App's bot user id as PR author, per the carve-out; the id is read after M5, see umbrella F4):
   accepted (the T3 diff likewise, built by the same helper); the same diff with any extra changed field, a second version touched, or a different
   author id → rejected, each shown.
5. [script] **The carve-out is narrow and tested both ways:** the ownership gate accepts the
   pipeline identity's id *only* for a PR whose changes are exactly the transition in criterion 4 and
   rejects it for: a first publish, a new version, a `page.json` edit, a takedown, a mixed T1 and T3 PR, a T3 whose `reason` is blank or whose `build_log_url` is not `https://`, any change under
   `contracts/` or `.github/`. The hostile fixture from task 007 (id differs, username matches) still
   rejects. Positive control: an owner's ordinary PR still accepts. [Needs Ludwig's approval: CI
   security check.]
6. [live] **Release upload:** for one real accepted version, the Release exists in `worldofmodcraft/archive` with the two assets;
   `sha256sum` of the downloaded tarball equals the entry's `source_sha256`; the downloaded
   `.minisig` equals the entry's `signature` byte for byte; `minisign -V` with the published public key
   (`6E5B30596A7A8CC4`) succeeds on a machine that has none of our code. The entry's `source_archive` (the project-owned URL, decision Q-G) is fetched with `curl -L` and with a browser-equivalent client and yields the same bytes — **blocked until task 058 reports how that URL is served**; if 058 reports infeasible, this clause waits for Ludwig. Re-running the workflow
   for the same version fails with the never-overwrite message and leaves the release unchanged
   (asset checksums before/after).
7. [live] **Runner assumptions:** the run log shows the minisign version and the pinned download's
   checksum verification; if apt or a different install path was used instead, the log and this
   file say so.
8. [live] **Fork safety:** a fork pull request (opened by a non-member account, created for the
   test; credentials for it follow CLAUDE.md rule 11 — the permitted mechanism is a *fork created
   by Ludwig himself, in session*, not any stored token) that modifies the signing workflow to print
   the secret does not receive the secret: the run either does not start (approval required — M1.4
   default) or the variable is empty. Recorded with the run. The test PR is closed unmerged.
9. [live] **App-token behaviour (umbrella F5):** with the App identity (Q-D, M5 done), the
   write-back PR receives its required checks, merges under branch protection **without bypass or
   a lifted rule**, and the merge's `push` event runs the workflows that should run. If the App
   token's events do *not* trigger the workflows, this criterion documents the failure and the task stops (§3.4) rather
   than papering over it.
10. [live] **Dry run:** `workflow_dispatch` with `dry_run=true` against the M4 repository's commit
    (needs task 010's M4 repo to exist, **not** a registry entry) builds, signs and uploads to
    *workflow artifacts only*: no release, no branch, no PR. The log contains none of the key's
    characters beyond the public key id (check: `grep -c` the 16-hex `key_id` ≥ 1, the key text 0).
    This is the only live signing run before task 010's real publish.
11. [live] **Failure path:** a dry run against a deliberately bad commit (a public throwaway repo
    containing a `.png` with DBC magic bytes) fails with exit 1 semantics: the log is attached where
    specified in design 7(a), and no release or PR is created (a dry run opens no T3 PR). The T3 PR itself is shown by [script] criterion 4 (fixture) and, live, by task 010's deliberately bad publish if the manager schedules one; until then T3 live is unproven and the log says so.
12. [script] **Idempotence of the no-op:** run the planning step against `main` after a write-back
    merge: zero pending versions, no build, success.
13. `docs/tasks/008b-verify.sh` exists, is executable, mutation-tested (criteria 1-2, 4-5, 14-17), run in a
    fresh clone, output pasted in the log; the log separates [script] from [live] results.
14. [script] **The clone job has no access to the signing secret — a workflow-level check.** The verify script parses `.github/workflows/pipeline.yml` (PyYAML, or a stdlib parser if the CI runner lacks it; runner availability unverified) and asserts, for the job that runs `build_version.py`: (a) the job's whole subtree contains no `secrets.` token, no `secrets: inherit`, and no `uses:` of a reusable workflow; (b) neither the workflow-level nor the job-level `env`/`permissions` references a secret, and the job's `permissions` is exactly `contents: read`; (c) the job has no step with `MINISIGN_SECRET_KEY` or `PIPELINE_APP_PRIVATE_KEY` as a name; and, for the signing job: (d) it contains `secrets.MINISIGN_SECRET_KEY` exactly once, `needs:` the build job, and has no `git clone`, no `build_version.py`, no `source_url` and no `actions/checkout` of anything but this repository's own tools at the pinned `main` sha; and the write-back job: (e) is the only job containing `secrets.PIPELINE_APP_PRIVATE_KEY`. The check **fails on zero matches** of the build job (it must find the job by its `build_version.py` step, never pass vacuously). **Mutations**, each shown red then restored byte-identically: add `${{ secrets.MINISIGN_SECRET_KEY }}` to the build job's `env`; add `secrets: inherit`; move the signing step into the build job; add `build_version.py` to the signing job; widen the build job's `permissions` to `contents: write`. Positive control: the unmodified workflow passes. This criterion proves the *structure*; that GitHub withholds a job's secrets from other jobs is documented behaviour, not observed here (`[unverified]`), and the live fork-safety criterion 8 covers only forks. No command in this task prints, tests for, or lists the secret.
15. [script] **Test-only flags absent:** the workflow contains none of `--allow-local-source`, `--clone-timeout`, `--max-clone-bytes`, `--max-compressed-bytes`, `--max-uncompressed-bytes`, `--max-entries`, `--scanner` (grep, with a mutation that adds one and shows red).
16. [script] **`--no-sign` and the sign step** satisfy tests (a)-(d) of design 8, each shown red by a mutation (let `--no-sign` accept `--key`; skip the sha re-check; skip the size re-check; skip `reference_verify`) and restored byte-identically; 008a's suite is run unchanged and passes.
17. [script] **Retry path** (design 9): `plan_pending.py` with a `version` input builds only that version and refuses (exit 1) a version that is not `pending`, a malformed id, or one whose entry is absent; with no input it builds every `pending` version. Mutations: ignore the input; accept a `published` version.
18. **Docs move with code:** `docs/pipeline/build-pipeline.md` gains the workflow, the failure
    modes, the manual recovery for a half-finished release, and a "what Ludwig must do" section;
    `docs/architecture/key-management.md` is **not** edited here (D5 key note is Ludwig's task 056
    domain) except for a one-line pointer if needed.

## Explicitly OUT of scope
- 008a's tool; E12 (site rebuild dispatch, task 055); `page.json` screenshot scan (task 040);
  Software Heritage; binary signing; the site.
- Writing the contract amendments (a separate task precedes this one).

## File scope (declared; anything else = stop and report)
In the **registry** repo:
- `.github/workflows/pipeline.yml` (new)
- `tools/pipeline/plan_pending.py` (new — lists pending versions; the unit-testable half of the workflow), `tools/pipeline/sign_built.py` (new — re-verifies a built tarball and signs it; design 8), `tools/pipeline/build_version.py` (**in scope: the `--no-sign` flag only**, design 8; no other behaviour changes) and its tests in `tests/pipeline/`, `tools/pipeline/release.sh` (new — thin, `set -euo pipefail`, no logging of env)
- `tools/registry/ownership.py` (narrow carve-out only; the file is task 007's — sequence after it merges)
- `tests/pipeline/` (additions), `docs/pipeline/build-pipeline.md` (additions)
- `docs/tasks/008b-pipeline-workflow.md` (log), `docs/tasks/008b-verify.sh` (new, executable)
No edits to `contracts/`, to 008a's other modules (`gitops.py`, `archive.py`, `signing.py`, `reference_verify.py`, `naming.py`), `reserved-namespaces.json`, or the site repo.

## Forbidden here (beyond MANAGER.md §3.7)
- **Printing, copying, or testing for the secret** in any form; no `gh secret` commands of any
  kind. Whether `MINISIGN_SECRET_KEY` exists is not checked by running anything — it is a question
  for Ludwig (below). A denied credential access is information and is not retried (CLAUDE.md rule 11).
- `pull_request_target`, or any trigger a fork can fire with the key reachable.
- Bypassing branch protection, `--force`, editing protection settings, or an "admin merge" to get
  the write-back through. If protection blocks the design, stop and report; Ludwig lifts it loudly or not at all.
- Overwriting, re-tagging, or deleting a *published* release.
- Writing `source_archive` as anything other than the URL 008c's `source_archive_url` returns.
- Reading, printing, copying or testing for the GitHub App's private key or any installation token beyond the one minting step (CLAUDE.md rule 11); the App's bot user id is read from the **public** API only.
- Falling back to the built-in `GITHUB_TOKEN` for the write-back PR or the site dispatch if the App path fails: stop and report instead.
- Reading the author's mod from its live repo after the clone step, or building from a branch name.
- Any use of `GITHUB_ACTOR`/`GITHUB_ACTOR_ID` as the author identity (ownership.md).

## Dependencies and sequencing
Task 032 (merged, registry PR #4) → task 045 (merged, PR #6) → ADR-0121 (accepted) → task **057** (version lifecycle contract; spec gate-ready, not merged) → 007 and 039 merged (this task
edits 007's ownership module and relies on 039's workflow scaffolding for checks; neither is on registry `main` on 2026-10-15: `git ls-tree -r --name-only origin/main | grep -c '^tools/registry'` prints 0 and the tree has no `.github/`) → 008a (**merged**, PR #7) → 008c (needs 057, 058, 008a) → **008b** → Ludwig's steps M5-M7 (below; M5 and M7 must precede the live criteria) → 010.
Also needed before the workflow can be approved: `contracts/pipeline-trigger.md` (E15) and the
ownership carve-out in `contracts/ownership.md` (E16) — sibling contract tasks, see the umbrella.
Decisions Q-B, Q-D, Q-E, Q-G (Ludwig, 2026-10-14), Q-J/ADR-0121 and the SSRF policy (2026-10-15) are made. Parallel-safe with 041 and 056. Shares
no file with 055, but 055's registry sender uses the same App (decision Q-D).

## Ludwig's manual steps this task creates
These are the exact instructions the platform's `docs/runbooks/site-v1-manual-steps.md` must carry
(that file is outside this task's scope: the manager books a small docs task to copy this section
there; until then this is the source). GitHub's web interface changes; **every click-path below is
unverified — written from memory of GitHub's settings layout, not observed in this session.** If a
screen differs, trust the screen, and report the difference so the runbook is corrected.
CLAUDE.md rule 11: no agent reads, prints or uses the App's private key; Ludwig stores it himself
and never pastes it into chat. The in-session approval for creating this credential is Q-D
(Ludwig, 2026-10-14); the credential's *purpose* is: identity for the write-back PR, its merge, and
the site dispatch (task 055).

### M5 — Create the organisation-owned GitHub App  (Q-D)  [UNVERIFIED click-path]
1. Open `https://github.com/organizations/worldofmodcraft/settings/apps/new`
   (or: organisation → Settings → Developer settings → GitHub Apps → New GitHub App).
2. GitHub App name: `worldofmodcraft-pipeline` (names are globally unique; if taken, add a suffix
   and tell the manager the final name). Homepage URL: `https://worldofmodcraft.com`.
3. Webhook: **untick "Active"** (the pipeline does not receive webhooks).
4. Repository permissions — set exactly these and nothing else: **Contents: Read and write**,
   **Pull requests: Read and write**; "Metadata: Read-only" is added automatically.
   *(That Contents:write is what `repository_dispatch` and release creation require is GitHub's
   documented behaviour, not verified here.)*
5. "Where can this GitHub App be installed?": **Only on this account**.
6. Click **Create GitHub App**. On the App's page, note the **App ID** (a number, not a secret).
7. Same page → "Private keys" → **Generate a private key**. A `.pem` file downloads. This is a
   credential: it never goes into chat, a PR, or a file in any repository.
8. Left sidebar → **Install App** → install on the organisation → **Only select repositories** →
   `registry`, `site`, `archive` (M7 first, or add `archive` afterwards).
9. In `worldofmodcraft/registry` → Settings → Secrets and variables → Actions:
   *Secrets* tab → **New repository secret** → name `PIPELINE_APP_PRIVATE_KEY`, value = the whole
   contents of the `.pem` file. *Variables* tab → **New repository variable** → name `PIPELINE_APP_ID`,
   value = the App ID. (Task 055's sender needs the same pair on `registry`; nothing is needed on `site`.)
10. Keep the `.pem` offline with the minisign key's backup, or delete it: a lost key is replaced by
    generating a new one on the App's page (unverified that old keys can then be revoked there).
11. Tell the manager only the **App's name** (its slug appears in its public URL
    `https://github.com/apps/<slug>`). The manager reads the bot's numeric user id from the public API
    (`curl -s https://api.github.com/users/<slug>%5Bbot%5D`; *unverified for Apps*) for the ownership carve-out.

*You should see:* the App listed under organisation → Settings → GitHub Apps with "Installed on 3
repositories", and the secret/variable named on `registry`'s Actions secrets page.

### M6 — Join the organisation with your personal account  (Q-F)  [UNVERIFIED click-path]
Why: `test` is a reserved namespace; ADR-0119 §3 accepts a PR only from an organisation member, so
mission §7.6 ("you open the first-publish PR from your personal account") stands as written only if
`mbmludric` is a member. (Task 010 finding 1 records that it is documented as *not* a member.)
1. As an organisation **owner** (whichever account owns the org; the manager session acts as
   `womcraft` and whether that account is an owner is **unverified** — if not, do this step yourself
   from the owning account): `https://github.com/orgs/worldofmodcraft/people` → **Invite member** →
   enter `mbmludric` → role **Member** → send.
2. Signed in as `mbmludric`: open the invitation email, or `https://github.com/orgs/worldofmodcraft/invitation`
   → **Join worldofmodcraft**. (The organisation requires two-factor authentication, M1.2; your
   personal account must have it on or the join will be refused.)
3. Optional, relevant to a check in `ownership.md`: on the people page, set your own membership
   visibility to **Public**. Whether the CI's check can see a *private* membership is unverified;
   `ownership.md` fails closed ("the caller cannot see") when it cannot.
4. Look at organisation → Settings → Member privileges → **Base permissions** and tell the manager
   what it says: what membership grants on the repositories is unchecked.

*You should see:* `https://github.com/orgs/worldofmodcraft/people` listing `mbmludric` as Member.

### M7 — Create the archive repository  (Q-E)  [UNVERIFIED click-path]
1. `https://github.com/organizations/worldofmodcraft/repositories/new`
2. Name `archive` — **Public** — description "Source tarballs and signatures for published mods".
3. **Do tick "Add a README file"** (unlike `registry` and `site` in M1.3). Reason, unverified: a
   release tag needs a commit to point at; an empty repository may refuse the first release. 008b
   criterion 6 is where this is tested.
4. No `.gitignore`, no licence. Create.
5. Branch protection on `archive`: none required by this spec. Releases are append-only by the
   pipeline's own rule (`artifact-naming.md`: never overwrite an existing tag); whether to protect
   tags is a separate decision, not taken here.

*You should see:* `https://github.com/worldofmodcraft/archive` with one commit and the README.

### Existing, unchanged
- Confirm `MINISIGN_SECRET_KEY` is present — by looking at the repository secrets page himself (Q-H, open).
- The old option "Allow GitHub Actions to create and approve pull requests" is **no longer needed**:
  the App, not the built-in token, opens the PR (Q-D).

## Verification artefact (MANAGER.md §2c)
Declared: `docs/tasks/008b-verify.sh` for [script] criteria; the [live] criteria are recorded with
run URLs and are said plainly to be unscripted.

## Deliverables
Workflow + helpers + tests + docs + verify script + this file's log section current.

## Questions  (agent-maintained; see MANAGER.md 8b)
- **Q-H (open, fact, for Ludwig):** does `MINISIGN_SECRET_KEY` still exist on `worldofmodcraft/registry`,
  and is the offline backup of the private key done? (The mission log says M3 was completed 2026-09-05;
  I did not and may not check — `gh secret` commands are forbidden.) Not covered by Ludwig's 2026-10-14
  answers.
- **For Ludwig/manager (open):** do the branch-protection rules on registry `main` require status checks,
  and which? (Determines whether the App's write-back PR must wait for checks, and which.)
- **Q-J: closed** by ADR-0121 (Ludwig, 2026-10-15): `pending → rejected` with `reason` and `build_log_url`; design 7 follows it.
- **Build log location: closed** (Ludwig 2026-10-15, option A): `worldofmodcraft/archive` at `logs/<namespace>.<name>/<version>.log`. Needs M7.
- **SSRF split mechanism: closed** (coordinator 2026-10-15): `--no-sign` in `build_version.py` plus a sign step; design 8.
- Umbrella Q5 (Software Heritage) applies; Q-B..Q-G and Q-J are decided and no longer questions.

---
# Task 008b log  (append-only, updated continuously by the executing agent)
- 2026-10-14 spec written under task 054; nothing started.
- 2026-10-14 Ludwig's answers folded in (Q-B, Q-D, Q-E, Q-G); manual steps M5-M7 written with unverified click-paths; Q-H and Q-J remain open.
- 2026-10-14 spec review: write-back functions now come from 008c; 008b depends on 008a and 008c.
- 2026-10-15 finalised: 008a merged (PR #7) and its real CLI read; ADR-0121 closes Q-J (failure path is now a T3 PR); the SSRF job split is a requirement (design 8) with criteria 14-15, 17; the 008a no-sign-only-mode gap is recorded; dependencies updated (007, 039, 057, 058, 008c still pending).

## Decision recorded 2026-10-15 (Ludwig, in session: "Kör på A")
**Build logs live in `worldofmodcraft/archive` at `logs/<namespace>.<name>/<version>.log`**, committed by the
pipeline. `build_log_url` is that file's permanent https URL in a repo the project owns (ADR-0041: nothing
unpublished). The Actions run log is not used as the permanent reference (retention believed ~90 days,
[unverified]). Depends on M7 (archive repo exists).
- 2026-10-15 spec review fixes: design 8 rewritten around `--no-sign` and a sign step (throwaway-key design deleted); `build_version.py` brought into scope; retry path (design 9, criterion 17); Size section; build-log location integrated into design 7; criteria renumbered 1-18; ownership.md cited from registry main.
- 2026-10-15 manager gate note: test (a) must state whether the one-shot result.json carries `signed`; if not, the pinned difference lists it (review round 2, minor).
