# Task 008b: Pipeline workflow — post-merge run, release upload, protected write-back

- **Mission:** SITE-V1, deliverable **D2** (second half; umbrella `docs/tasks/008-build-pipeline.md`) — **Status:** amended 2026-10-26 (re-gate findings folded in); re-gate round 2 pending. Not dispatchable until round 2 passes; also blocked by 082 and 092 merging and by 008c
- **Agent / model:** implementer / sonnet
- **Budget:** large (≤ 6 agent-sessions)
- **Branch / worktree:** `task/008b-pipeline-workflow` / `~/wt/registry-task-008b` — **registry** repo

## Amendment 2026-10-25 (session 11 night)
Sources: platform `docs/tasks/082-pipeline-trigger-contract.md` (the E15 contract, spec-approved 2026-10-25 night; its merge needs
Ludwig; its "Dependencies / sequencing" follow-up list is the checklist for this amendment), `docs/tasks/039-registry-ci-workflow.md`
(§1, §3, log note C23) and the mission log choices C10-C23. This amendment takes no decision of its own: it folds in decisions already recorded by Ludwig (mission log C11-C23, and 092's Q5, Q9, Q10).
Each amendment is applied in place below; the tag in brackets names where.
1. **Objective, key reachability** (C14, C20; 082 PT3) — the key is reachable on `push` to `main` or a `workflow_dispatch` on `main`, never from a fork, and bound to `main` by environments, not by the workflow's `if:`. [Objective]
2. **Design 2, first sentence** (C12, C11; 082 PT4, PT5) — the run reads the state at `main`'s head fetched at plan time, not the pushed range. [Design 2]
3. **Design 4, write-back sequencing** (C22; 082 PT11) — one PR at a time, App merges once `gate` is green, 30-minute deadline, closed or deadline fails the run, `timeout-minutes` sized from the pending count. [Design 4]
4. **Design 8, environments** (C20 extended by review round 2; C14; C21; 082 PT3, PT12) — environments `signing` and `write-back` limited to `main`; the repo-level copies of both secrets are deleted in runbook M11; until then the trust boundary is every account with write access; the dry-run job references neither. [Design 8; Design 6 gets a one-line pointer]
5. **Design 9, dispatch** (C11; 082 PT5, PT6, PT12) — empty `version` plans all pending versions like a push; `version` is validated and passed via `env:`. [Design 9]
6. **Criterion 1** (C16, C17; 082 normative block) — the workflow is compared with 082's normative block on parsed keys. [Criterion 1]
7. **Criterion 10** (C21; 082 PT12) — dry runs sign only with an ephemeral in-run key. [Criterion 10]
8. **Consequential wording, derived from items 3-5, for the re-gate to check:** criterion 9 names `gate` (039) as the required check; criterion 14 gains clause (f) (the `environment:` declarations of design 8, so the structure check cannot pass a workflow without them); criterion 17 gains the `env:`-only check for `version`. [Criteria 9, 14, 17]
9. **Dependencies and status** — 082 (E15 contract), 039a (composer) / 039b (workflow, `gate`) per the C23 split, M11 (Ludwig). [Dependencies; header status]

**Noted at the 2026-10-25 amendment; status after the 2026-10-26 re-gate fold-in (see the log entry of that date for the finding-by-finding map):**
- 082 PT5: a fault or refusal ends that version only and the run continues with the other pending versions, failing at the end naming each. **Folded in 2026-10-26** (design 7, design 9, criterion 17).
- 082 C13/PT8: the planner skips a pending version whose `pipeline/<ns>.<name>-<version>` branch already exists (run non-green, version named); an existing `logs/<ns>.<name>/<version>.log` in `archive` fails that version (append-only). **Folded in 2026-10-26** (design 3, design 5, criteria 17 and 24).
- Once the App key lives only in the `write-back` environment (M11), every job that uses the App token, including task 055's site-dispatch sender (design 4), must declare `environment: write-back`; 008b criterion 14(e) already places the key in one job.
- 082 PT12 says a dry run's source is a `pending` version on `main` or an input set that 008b names and 082 reviews. **Folded in 2026-10-26:** design 1 names the input set (open detail: Question Q-M); 082's reviewer must still confirm it.
- 082 PT11 sizes the job timeout as N x 30 minutes plus build time; whether GitHub caps a job's `timeout-minutes` below that for a large N is [unverified] here. **Handled 2026-10-26** by criterion 20 and Question Q-N.

## Objective
A merged pull request that adds a version to `worldofmodcraft/registry` causes, within minutes
and without a human, a workflow running on the registry's own `main` to: build the version with
008a's tool, upload the tarball and signature as a GitHub Release named per `artifact-naming.md`,
and land the six write-back values in `mods/<ns>.<name>/entry.json` through a same-repository pull
request that passes the registry's own gates and merges. The signing key (and the App key) is reachable only by that
workflow, only in runs on `main` — a `push` to `main`, or a `workflow_dispatch` on `main` by an account with write access
[unverified: who may dispatch] — never from a fork-triggered run. The ref condition on the jobs protects only the unmodified
workflow file; what binds both keys to `main` is the `signing` and `write-back` environments (design 8, runbook M11). A failed build posts its full
log where the author will see it. The contract for the trigger (E15) exists first.

## Context to load (exhaustive)
- ADRs: **0121** (the `pending` lifecycle, the post-merge build, the write-back PR and rejections; amends 0041 and 0058 §1 — it is the authority for design 2, 4 and 7 below), 0041 (key in build secrets, usable only by the build workflow; archiving), 0058 §1 (as amended by 0121), 0040 §5, 0099 (CI
  gates), 0059 §3, 0103, 0117, 0119, 0120.
- Contracts: `entry.schema.json` / `append-only.rules.md` **as amended by task 057** (T1 `pending → published` and T3 `pending → rejected` — each pipeline PR's entire diff); `artifact-naming.md` (never overwrite an existing tag; "What this document does not
  cover" lists idempotency as this task's; **as amended by task 092**: the section "The archived-source URL (`source_archive`)", its producer obligations and the `+` rule), `pipeline-trigger.md` (E15, task 082, rules PT1-PT12, normative trigger block), `signature-format.md`, `archive-layout.md`,
    `contracts/ownership.md` on registry `origin/main` (task 032 merged, PR #4; `git -C /home/ludwig/registry show origin/main:contracts/ownership.md | grep -c R11` > 0) (the identity rule; `GITHUB_ACTOR*`
  forbidden as an identity source), `rebuild-trigger.md` (E12 — **not this task**; see 055, but the
  two interact, criterion 10).
- Platform docs: `docs/architecture/depgraph.md` (E15 and the Q4=A rationale in mission log Q4),
  `docs/architecture/key-management.md`, `docs/manager/OPERATIONS.md` ("Consequences of branch
  protection that bite later", "The manager's own permissions"), `docs/runbooks/site-v1-manual-steps.md` (M1.4, M3).
- Depends on 008a's tool, **merged**: `tools/pipeline/build_version.py` (CLI `--entry --version --workdir --key --pubkey --out`; exit 0 built, 1 rejected, 2 pipeline fault; outputs `<tag>.tar.gz`, `<tag>.tar.gz.minisig`, `result.json`, `build.log`), `tools/pipeline/naming.py` (`release_tag`, `asset_names`, `release_asset_url`), `signing.py`, `reference_verify.py`, `archive.py` — read from `git -C /home/ludwig/registry show origin/main:<path>` on 2026-10-15 (head `a50daac`). The test-only flags (`--allow-local-source`, `--clone-timeout`, `--max-*`, `--scanner`) must never appear in the workflow (008a booked finding 1). And on 008c's `tools/pipeline/write_back.py` (`apply_write_back`, `source_archive_url`, `write_back_values`).
- Graph: nodes **N5**, **N6**, **N2**, **N3**; edges **E7**, **E8**, **E15**, **E16**.

## Size (5b)
**Counts refreshed 2026-10-26 (estimates from the file scope and designs below; nothing is built yet, so these are not `git diff --numstat` figures).** All three numbers are over the soft cap (MANAGER.md §2b: at most 5 source files, 300 changed lines, 10 reading-list files).
- **Source files: 7** (cap 5): `.github/workflows/pipeline.yml`, `tools/pipeline/plan_pending.py`, `tools/pipeline/sign_built.py`, `tools/pipeline/build_version.py` (the `--no-sign` flag only), `tools/pipeline/release.sh`, `tools/pipeline/write_back_job.py` (new, see Question Q-K), `tools/registry/ownership.py` (narrow carve-out only). Tests, `docs/tasks/008b-verify.sh` and `docs/pipeline/build-pipeline.md` are excluded.
- **Changed lines: about 800** (cap 300), estimated per file: workflow 200 (build, signing, write-back and dry-run jobs, environments), `plan_pending.py` 130, `sign_built.py` 110, `build_version.py` 40, `release.sh` 60, `write_back_job.py` 200, `ownership.py` 60.
- **Reading list: 28 listed items** (cap 10): 10 ADRs, 8 contracts (including `pipeline-trigger.md` and 092's section of `artifact-naming.md`), 4 platform documents, 5 modules of 008a plus 008c's `write_back.py`. About 18 of them are read for one fact each and are cited above by path; the earlier figure of "about 12" was stale.

**Justification for keeping it one task.** (1) The workflow, the planner, the sign step, the release script and the `--no-sign` change are one security argument: the criterion-14 structure check and the sign step's re-verification only mean something together, and the split between the build job (no secret), the signing job (key only) and the write-back job (App key only) is the argument itself. (2) The write-back loop, the environments and the ownership carve-out gate each other: the carve-out is only safe to merge while the loop opens exactly one T1/T3 PR at a time. (3) A split costs a second spec gate, a second review and a workflow file edited by two tasks in sequence. **Split trigger (unchanged):** if after session 3 the `--no-sign` change and its tests (design 8, criterion 16) are not green, they become task 008d, a small offline task on 008a's tool, and 008b waits for it. Live criteria (6-11, 23) need Ludwig's M5-M7 and M11 and are expected to dominate calendar time, not agent time.

**Split alternative (manager decides at the gate).** Splitting is the default answer in MANAGER.md §2b, so this is laid out for choice. It differs from "release in part 1" because the release upload needs the App token, which only the write-back job holds (design 8), so the release belongs with the write-back loop.
- **008b-1 — plan, build, sign (no secret except the signing key; writes nothing to any repository).** Contains: `plan_pending.py` (pending listing, `version` input, C13 branch skip, C15 schema fault, PT5 per-version fault handling, the `+` refusal of Q10 as a plan output), the `--no-sign` flag and `sign_built.py` (design 8), the workflow with the build job, signing job and dry-run job and the `environment: signing` declaration, the E15 trigger block. Criteria: 1 (parsed-key comparison), 2 (signing-key half), 3, 10, 11, 12, 14 (a-d, f for signing and dry-run), 15, 16, 17, and the signing half of 23. Source files: 4 (`pipeline.yml`, `plan_pending.py`, `sign_built.py`, `build_version.py`); about 400 lines. Dependencies: 082 and 092 merged, 008a merged, 039b (`gate`) not needed. Ends with workflow artifacts only; the dry run is its live proof.
- **008b-2 — write-back (the App key).** Contains: the write-back job in `pipeline.yml` (App token, `environment: write-back`), `write_back_job.py` (the C22 loop, the archive log commit with the PT8 append-only rule, the release upload, the pre-T1 `source_archive` check of 092 Q5/Q9, the T3 for a `+` version), `release.sh`, the `ownership.py` carve-out, `docs/pipeline/build-pipeline.md`. Criteria: 2 (App-key half), 4, 5, 6, 7, 8, 9, 14 (e, f for write-back), 18, 19, 20, 21, 22, 23 (write-back half), 24. Source files: 4 (`pipeline.yml`, `write_back_job.py`, `release.sh`, `ownership.py`); about 430 lines. Dependencies: 008b-1 merged, 008c, 039b with M9, M5, M7, M11, M12 (done), and 007 for the ownership module.
- Both parts are still over the 300-line figure; each needs its own `Size` justification. The cost of splitting is the second workflow-file edit and a second gate.

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
  - ~~Whether branch protection on `main` requires status checks~~ — **closed 2026-10-26:** superseded by the required check `gate` (task 039b) and runbook M9, which makes it required; design 4 and criterion 9 name `gate`.

## Design (decisions made in this spec)
1. **Trigger (E15, Q4=A):** `on: push: branches: [main]` with `paths: ['mods/*/entry.json']`.
   Never `pull_request`, never `pull_request_target`, never `workflow_run` from a fork. The
   `workflow_dispatch` declares these inputs (082 PT5, PT12; the comparer of criterion 1 requires at least the first two): `dry_run` (boolean, default `false`), `version` (string, default empty; `<namespace>.<name>@<semver>` when set, design 9). **Dry-run input set (PT12):** a dry run (`dry_run=true`) takes its source from one of two places: a `pending` version on `main` named by `version`, or, for criterion 10, the pair `dry_run_source_url` (an `https://` URL) and `dry_run_commit` (40 hex characters), which are accepted only with `dry_run=true` and only together, and with which `version` must be empty. The pair builds a synthetic entry inside the run (never written to `main`). Every input is validated before use and reaches scripts only through `env:` (design 9). The dry-run job and its inputs exist for tests (criterion 10); names and the synthetic entry's shape are Question Q-M.
2. **What to build:** the workflow reads the registry state at `main`'s head, fetched at plan time (the SHA is logged; not the
   push's `github.sha`, not the pushed range — C12, 082 PT4), lists every version object in the `pending`
   state (decided Q-B, Ludwig 2026-10-14; ADR-0121; shape defined by task 057), and builds each. Zero pending versions → the run succeeds doing
   nothing (this is what stops the write-back merge's own push from looping). It never trusts the
   diff for *authority*: the entry's content on `main` is the input, and 008a re-validates
   everything. **An entry on `main` that fails `entry.schema.json` is a pipeline fault (C15; 082 PT9):** nothing is built for it, no T3 is opened, and the run fails naming the file (design 7). **A `pending` version whose `version` contains `+` (build metadata) is not built (092 Q10):** the planner emits it as a refusal, not as a build; it is never cloned, built, signed or released, and design 7 gives it a T3. Prerelease versions without `+` (for example `1.0.0-rc.1`) are built as any other.
3. **Concurrency:** `concurrency: { group: pipeline, cancel-in-progress: false }`. Two merges
   queue. **A run holds the group until every PR it opened has reached a terminal state (C13, C22; 082 PT6, PT11):** merged, `gate` red, closed unmerged, or the 30-minute deadline (design 4). **The planner skips a `pending` version whose `pipeline/<namespace>.<name>-<version>` branch already exists** (a write-back PR from an earlier run is still open, or an earlier run died after pushing): nothing is built for it, and the skip is not silent — the run ends non-green (or raises an error annotation) naming the version. Recovery is manual: close its PR, delete its `pipeline/` branch, dispatch (082 PT8). The branch check reads the repository's branches at plan time; it is the planner's job and is tested without a network (criterion 17).
4. **Branch and PR:** push `pipeline/<ns>.<name>-<version>` to this repository, open a PR to
   `main` whose diff is exactly one version object's `pending → published` transition T1 (task 057) — or, on rejection (design 7), exactly one `pending → rejected` transition T3. Two PRs per
   publish (OPERATIONS.md), by design. **Sequencing (C22, 082 PT11):** write-back PRs are opened and merged one at a time, each
   branched from a `main` head fetched after the previous merge; the GitHub App merges each once `gate` (task 039, the required
   check) is green, and the run holds the `pipeline` group until that PR is merged. `gate` red, a PR closed unmerged, or a PR not
   merged within 30 minutes fails the run and releases the group; the remaining pending versions wait for the next push or an
   empty-`version` dispatch (design 9). The write-back job has a `timeout-minutes` sized from the pending count (N × 30 minutes
   plus build time), or the per-PR steps carry their own timeouts (criterion 20; whether GitHub allows that size is Question Q-N). **Ordering inside the write-back job for a built version (092 Q5, Q9):** archive log commit (design 7 / PT8 rule) is for rejections only; for a built version the order is upload and publish the release (design 5) -> fetch `source_archive` through the front (design 5) -> open the T1 PR. The T1 PR is never opened before the fetch succeeds. The write-back job owns this ordering; the build and signing jobs know nothing of it. (039's "no auto-merge" means no auto-merge by the 039
   workflow; the App merge here is this workflow.) **Identity (decided Q-D, Ludwig 2026-10-14): the organisation-owned GitHub App**
   — one installation token minted per run, used for opening the PR, merging it, and (task 055) the
   site dispatch. The App id is a repository *variable* `PIPELINE_APP_ID`; the private key is the
   repository secret `PIPELINE_APP_PRIVATE_KEY` (both names are this spec's choice, not verified
   against anything). Used in exactly one step (the minting step), never echoed.
5. **Release (decided Q-E, Ludwig 2026-10-14):** in `worldofmodcraft/archive`, not this repository. Create the release as a **draft**,
   upload both assets, then publish. An existing release with that tag: published → fail with
   `artifact-naming.md`'s "never overwrite" wording; draft (an earlier run died mid-way) → delete
   and recreate. The tag is `ns.nm-v` and is created on the **archive** repository's default branch head (the registry's head would be meaningless there).
   **Pre-T1 check of `source_archive` (decided: Ludwig 2026-10-26, 092 Q5 = A and Q9 = A; owned by the write-back job).** After the release is published and before the T1 PR is opened, the job derives `source_archive` with 008c's `source_archive_url` and (i) requests it **without following redirects** and requires hop 1 to be 301, 302, 307 or 308 with a `Location` byte-equal to the derived redirect target `https://github.com/worldofmodcraft/archive/releases/download/<tag>/<tag>.tar.gz` — **the producer checks hop 1 exactly (Q9)**, consumers do not; (ii) fetches the URL through the full chain, requires **https on every hop** (no downgrade), at most 5 hops and the 50 MiB cap of 092, and requires the SHA-256 of the received bytes to equal the computed `source_sha256`. Any failure is **exit 2**: no T3, the version stays `pending`, no T1 is opened, and the run fails naming the URL (the PT5 per-version rule applies). Consequence, not a new rule: the release is already published and is never overwritten (never-overwrite rule above, PT8), so the next run of that version stops at the published-tag failure; recovery is manual and is documented in `docs/pipeline/build-pipeline.md` (criterion 18).
   **Archive log is append-only (PT8).** Before committing `logs/<namespace>.<name>/<version>.log` (design 7) the job checks that the path does not exist in `worldofmodcraft/archive`; if it does, that version fails naming the path, nothing is overwritten, and recovery is by hand.
6. **Key:** `MINISIGN_SECRET_KEY` exists as an Actions secret (M3 done 2026-09-05 per the mission
   log). Used in exactly one step, via an environment variable scoped to that step only, handed to
   008a's tool as a process-substitution path (or a 0600 file under `$RUNNER_TEMP` removed in an
   `if: always()` step). No `set -x` anywhere in that step. The step prints nothing derived from the
   key. Whether the secret exists is **not** checked by this spec (see Questions). From runbook M11 on, the key is the `signing`
   environment's secret, not a repository secret (design 8); the one-step scoping rule above is unchanged.
7. **Failure (decided: ADR-0121 Q-J, Ludwig 2026-10-15):** a build rejection (008a exit 1) is reported in two places and never by blocking a merge (the author's PR has already merged): (a) a comment with the full `build.log` on the originating merged PR; (b) a pipeline PR, from the same App identity, whose diff is exactly one T3 transition — `status: "rejected"`, plus `reason` (non-empty after trimming; the rule/clause line from 008a's rejection message) and `build_log_url` (the permanent `https://` URL of `logs/<namespace>.<name>/<version>.log` in `worldofmodcraft/archive`, committed by the pipeline's App identity before the T3 PR opens; decided, Ludwig 2026-10-15, see "Decision recorded" below; the Actions run log is not the permanent reference). The `reason` is passed through 008c's `apply_write_back` (JSON-encoded, never string-spliced into a file) and length-capped there; the full text is in the log file. The version is never deleted; the author publishes a new version. Exit 2 is a pipeline fault (a fault is not a verdict on the version): comment nothing about the author's mod, open no T3 PR, build nothing further for that version; it stays `pending`. **A fault ends that version only (082 PT5):** the run continues with the other pending versions and fails at the end, naming each version that faulted; the mechanism (a matrix with `fail-fast: false`, or a loop in the driver) is the implementer's, the behaviour is criterion 17's. A faulting version is retried by every later push run as well as by a dispatch (design 9) and ends each of those runs red without blocking the others. (A terminal failure of a write-back PR — `gate` red, closed unmerged, 30-minute deadline, design 4 — is different: it stops the run, as PT11 states.) **Pipeline faults, all exit-2 class, no T3:** a build exit 2; an entry on `main` failing the entry schema (C15, design 2); the pre-T1 `source_archive` check failing (design 5); a published release already existing for the tag (design 5); an existing archive log at the path (design 5). **A second T3 cause, beside the exit-1 rejection (092 Q10):** a `pending` version whose `version` contains `+` is not built, signed or released; it gets a T3 `rejected` with the exact `reason` "versions with build metadata (+) are not yet published — pending proof that GitHub resolves them (task 010)" (copied from 092's contract, `artifact-naming.md`, producer obligation 3; it contains an em dash and must survive `apply_write_back` and its length cap unchanged), not left `pending`. Its `build_log_url` and log file follow Question Q-L. It is opened by the same one-at-a-time loop (design 4). A `rejected` version is not `pending`, so the planning step never rebuilds it.
8. **SSRF job split (decided: Ludwig 2026-10-15; requirement, not a preference).** `source_url` is author-controlled and may be an https URL naming an internal address; 008a does not filter addresses (008a Questions, A-3). The workflow therefore has three jobs (plus the dry-run job, below) with this separation: (i) **build job** — clones the author's repository, runs 008a's validation, archive and scan, and holds **no** secret: no `secrets.*` reference of any kind, no `secrets: inherit`, no job- or workflow-level `env` derived from a secret, `permissions:` limited to `contents: read`; (ii) **signing job** (`needs:` the first) — receives **only the built artefact** (tarball and `result.json` as workflow artifacts), never runs `git clone`, `build_version.py` or any fetch of `source_url`, and holds only `MINISIGN_SECRET_KEY`; (iii) **write-back job** — holds only the App secret, mints the token, commits the build log and uploads the release, opens the PR.
   **Key binding (C20 extended, C14, C21; 082 PT3, PT12).** The signing and write-back jobs run only when `github.ref ==
   'refs/heads/main'`, for both triggers; that condition lives in the workflow file and protects only the unmodified file (a
   write-access account can dispatch a modified file from another branch). What binds the keys to `main` is GitHub Actions
   **environments** [unverified mechanics]: the signing job declares `environment: signing`, holding `MINISIGN_SECRET_KEY`; the
   write-back job declares `environment: write-back`, holding `PIPELINE_APP_PRIVATE_KEY`; each environment's deployment branches
   are limited to `main`. **Runbook M11 (Ludwig's manual step) creates both environments and deletes the repo-level copies of
   both secrets** — an environment copy protects nothing while a repo-level copy exists. Until M11 is done, the trust boundary of
   both keys is every account with write access to the registry. The **dry-run job** (`workflow_dispatch` with `dry_run=true`;
   `needs` the build job, no secret) references neither environment nor either secret: it signs with an ephemeral key generated
   inside the run and discarded (criterion 10) and uploads workflow artifacts only.
   **Required change to 008a's tool (in this task's scope; decided by the coordinator 2026-10-15).** Verified gap: `build_version.py` clones and signs in one process and has no mode without a key (see Environmental facts). Add to `tools/pipeline/build_version.py` a `--no-sign` flag and a separate sign step (`tools/pipeline/sign_built.py`, new, importing 008a's `signing` and `reference_verify`):
   - `--no-sign`: `--key` and `--pubkey` are not accepted (argparse error, exit 2, **before** any clone) — `--no-sign` together with `--key` is refused, the test-visible rule that the build job needs no key. Exit codes unchanged: 0 built, 1 rejected, 2 usage/pipeline fault. Outputs in `--out`: `<tag>.tar.gz`, `result.json`, `build.log`; **no** `.minisig`. `result.json` carries everything the one-shot mode's does except `artifact.signature` and `artifact.key_id` (absent, not empty) and gains `"signed": false`; `artifact.source_sha256` is present. The exact field list is pinned by a test against the one-shot `result.json` (the difference is those keys and nothing else).
   - sign step: inputs are the tarball, `result.json`, `--key`, `--pubkey`, `--out`. Before signing it re-checks, from the tarball alone and independently of the build job: compressed size and uncompressed size, entry count and per-entry rules against 008a's limits (`archive.inspect_archive`), and `sha256(tarball) == result.json.artifact.source_sha256`; any mismatch → exit 1-style refusal named, nothing signed. It signs with `signing.sign` using `signing.trusted_comment`, and its output must pass `reference_verify.verify` (as the one-shot mode does) or exit 2. Output: the `.minisig` and a `result.json` with `signed: true`, `artifact.signature`, `artifact.key_id`.
   - tests (offline, fixture-driven, in `tests/pipeline/`): (a) `--no-sign` followed by the sign step gives a `result.json` and `.minisig` equivalent to the one-shot build on the same fixture (same tag, sha, key_id, signature text modulo `built_at`); (b) `--no-sign --key k` and `--no-sign --pubkey p` are each refused before any clone; (c) a tampered tarball (one byte changed; an extra entry; size over limit) is refused by the sign step; (d) 008a's own suite still passes unchanged (one-shot mode untouched).
   Throwing out any of (a)-(d) is a stop-and-report.

9. **Retry after a pipeline fault.** A build that ends in exit 2 leaves the version `pending` on `main` (design 7); every push run also retries it (PT5). It can be rebuilt on demand by a non-dry-run `workflow_dispatch` with the input `version=<namespace>.<name>@<semver>`; the planner then builds only that version (and only if it is still `pending`). A dry run (`dry_run=true`) never takes this path. Pushes to `main` still plan all pending versions. A non-dry-run dispatch with an **empty `version`** plans all pending versions, exactly like a push (C11; 082 PT5, PT6) — so a waiting push run replaced by a waiting dispatch run [unverified GitHub behaviour] loses nothing. The `version` input is validated against the entry-id and semver patterns before use, and reaches scripts only through `env:` (never `${{ inputs.version }}` inside a `run:`); a dry run's `version` is validated and passed the same way (082 PT12). Concurrency group `pipeline` applies, so a dispatch queues behind a running build.

## Acceptance criteria
Script = `docs/tasks/008b-verify.sh`; live = a real run, recorded with run URLs, **not**
script-verified.
1. [script] **The E15 contract exists first:** `contracts/pipeline-trigger.md` (task 082, registry PR #20, blocked on 087) is present on `main`
   (landed by the contract task; this criterion cannot be run until 082 has merged) and the workflow matches its normative trigger block **on parsed keys, not bytes**: the verify
   script parses `.github/workflows/pipeline.yml` and asserts the `on` keys are exactly {`push`, `workflow_dispatch`} (PyYAML
   reads the key `on` as boolean `True`; the comparer handles both), `push` and `concurrency` equal the block's, and the
   `workflow_dispatch` inputs are a superset of {`dry_run`, `version`}. It **fails on zero matches** (no `push.branches` `main`
   found, or the block absent from the contract), and asserts the absence of `pull_request_target`, `pull_request:` and
   `workflow_run` in the signing workflow file.
2. [script] **The secrets are referenced exactly once each**: `secrets.MINISIGN_SECRET_KEY` in the signing step's `env:`, `secrets.PIPELINE_APP_PRIVATE_KEY` in the token-minting step; the verify
   script counts occurrences of `secrets.MINISIGN_SECRET_KEY` across `.github/` and asserts the
   count of each is 1 and that no `run:` block contains `echo`, `printf` or `cat` of either variable name,
   and no `set -x`/`-o xtrace` appears in the workflow. Mutation: add each forbidden pattern to a
   copy of the workflow and show the check redden.
3. [script] **Naming:** a unit test feeds `(namespace, name, version)` triples through the
   workflow's naming/URL helpers (008a's `release_asset_url`, 008c's `source_archive_url`) and asserts tag, both asset names and both URLs equal the `artifact-naming.md` examples (`mc.hello-world-1.0.0`,
   `.tar.gz`, `.tar.gz.minisig`), The expected strings are 092's worked examples in `artifact-naming.md` ("The archived-source URL"), typed literally into the test, not derived by the code under test: example 1 (`mc`, `hello-world`, `1.0.0`) for tag, assets and URLs, and example 2 (`a`, `b`, `1.0.0-rc.1+build.5`, tag `a.b-1.0.0-rc.1+build.5`) as a pure helper unit test **labelled "derivation only, never published"** — a `+` version is refused by design 2 and 7 (Q10) and no run ever uploads it. The expectations come from the 092 contract, not from task 058's report. Mutation: change one character of a helper's output and show the test red.
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
   (`6E5B30596A7A8CC4`) succeeds on a machine that has none of our code. The entry's `source_archive` (the project-owned URL, decision Q-G; contract: 092) is fetched through the front with `curl -L`: the bytes equal the downloaded tarball (`cmp`), hop 1 (fetched without `-L`) is exactly the 301/302/307/308 with the derived `Location` (092 Q9), and every hop is `https`. This clause is [live] and depends on runbook M12 (done) and on the front answering for this tag. Re-running the workflow
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
   write-back PR receives its required checks (`gate`, task 039), merges under branch protection **without bypass or
   a lifted rule**, and the merge's `push` event runs the workflows that should run. If the App
   token's events do *not* trigger the workflows, this criterion documents the failure and the task stops (§3.4) rather
   than papering over it.
10. [live] **Dry run:** `workflow_dispatch` with `dry_run=true` against the M4 repository's commit
    (needs task 010's M4 repo to exist, **not** a registry entry) builds, signs and uploads to
    *workflow artifacts only*: no release, no branch, no PR. **It signs only with an ephemeral key generated inside the run and
    discarded (C21; 082 PT12), never the production key**, and its artifacts say so; the dry-run job references neither the
    `signing` nor the `write-back` environment. The log contains none of the ephemeral key's characters beyond its public key id
    (check: `grep -c` the 16-hex `key_id` of `result.json` ≥ 1, the key text 0), and the `result.json` `key_id` is not the production
    key id `6E5B30596A7A8CC4` (public). This is the only live signing run before task 010's real publish.
11. [live] **Failure path:** a dry run against a deliberately bad commit (a public throwaway repo
    containing a `.png` with DBC magic bytes) fails with exit 1 semantics: the log is attached where
    specified in design 7(a), and no release or PR is created (a dry run opens no T3 PR). The T3 PR itself is shown by [script] criterion 4 (fixture) and, live, by task 010's deliberately bad publish if the manager schedules one; until then T3 live is unproven and the log says so.
12. [script] **Idempotence of the no-op:** run the planning step against `main` after a write-back
    merge: zero pending versions, no build, success.
13. `docs/tasks/008b-verify.sh` exists, is executable, mutation-tested (criteria 1-5, 14-17 and the script criteria 19-22 and 24, each with the mutations it names), run in a
    fresh clone, output pasted in the log; the log separates [script] from [live] results.
14. [script] **The clone job has no access to the signing secret — a workflow-level check.** The verify script parses `.github/workflows/pipeline.yml` (PyYAML, or a stdlib parser if the CI runner lacks it; runner availability unverified) and asserts, for the job that runs `build_version.py`: (a) the job's whole subtree contains no `secrets.` token, no `secrets: inherit`, and no `uses:` of a reusable workflow; (b) neither the workflow-level nor the job-level `env`/`permissions` references a secret, and the job's `permissions` is exactly `contents: read`; (c) the job has no step with `MINISIGN_SECRET_KEY` or `PIPELINE_APP_PRIVATE_KEY` as a name; and, for the signing job: (d) it contains `secrets.MINISIGN_SECRET_KEY` exactly once, `needs:` the build job, and has no `git clone`, no `build_version.py`, no `source_url` and no `actions/checkout` of anything but this repository's own tools at the pinned `main` sha; and the write-back job: (e) is the only job containing `secrets.PIPELINE_APP_PRIVATE_KEY`; and, for all jobs (design 8, C20): (f) the signing job declares `environment: signing` and the write-back job `environment: write-back`, both jobs carry the `github.ref == 'refs/heads/main'` condition, and the dry-run job declares no `environment` and references neither secret (mutations: drop the `environment:` of the signing job; add `environment: signing` to the dry-run job). The check **fails on zero matches** of the build job (it must find the job by its `build_version.py` step, never pass vacuously). **Mutations**, each shown red then restored byte-identically: add `${{ secrets.MINISIGN_SECRET_KEY }}` to the build job's `env`; add `secrets: inherit`; move the signing step into the build job; add `build_version.py` to the signing job; widen the build job's `permissions` to `contents: write`. Positive control: the unmodified workflow passes. This criterion proves the *structure*; that GitHub withholds a job's secrets from other jobs is documented behaviour, not observed here (`[unverified]`), and the live fork-safety criterion 8 covers only forks. No command in this task prints, tests for, or lists the secret.
15. [script] **Test-only flags absent:** the workflow contains none of `--allow-local-source`, `--clone-timeout`, `--max-clone-bytes`, `--max-compressed-bytes`, `--max-uncompressed-bytes`, `--max-entries`, `--scanner` (grep, with a mutation that adds one and shows red).
16. [script] **`--no-sign` and the sign step** satisfy tests (a)-(d) of design 8, each shown red by a mutation (let `--no-sign` accept `--key`; skip the sha re-check; skip the size re-check; skip `reference_verify`) and restored byte-identically; 008a's suite is run unchanged and passes.
17. [script] **Retry path** (design 9): `plan_pending.py` with a `version` input builds only that version and refuses (exit 1) a version that is not `pending`, a malformed id, or one whose entry is absent; with no input (a push, or a dispatch with an empty `version`) it builds every `pending` version. The workflow passes `version` (and, design 1, `dry_run_source_url` and `dry_run_commit`) only through `env:` (no `${{ inputs.* }}` inside any `run:`; design 9). **Planner-level tests (no network, fixture repository state), each with a mutation:** (a) **C13 skip:** a pending version whose `pipeline/<ns>.<name>-<version>` branch exists is not in the build list, is reported as skipped with the version named, and the planner's result is non-green; mutation: remove the branch check. (b) **C15:** a `mods/*/entry.json` failing the schema yields no build and no T3 for any of its versions, and a fault naming the file; mutation: treat the entry as valid. (c) **PT5:** with three pending versions and fake outcomes (ok, fault, ok), the driver processes all three and ends non-green naming exactly the faulted one; mutation: stop at the first fault. (d) **Q10 refusal:** a pending `1.0.0+build.5` is in the refusal list, not the build list, while `1.0.0-rc.1` is in the build list. Mutations for the first three tests: ignore the `version` input; accept a `published` version; put `${{ inputs.version }}` in a `run:`.
18. **Docs move with code:** `docs/pipeline/build-pipeline.md` gains the workflow, the failure
    modes, the manual recovery for a half-finished release, and a "what Ludwig must do" section;
    `docs/architecture/key-management.md` is **not** edited here (D5 key note is Ludwig's task 056
    domain) except for a one-line pointer if needed.
19. [script] **The write-back loop (C22; 082 PT11), run against a fake clock and a fake GitHub API** (`write_back_job.py` takes both as injected objects; no network): (a) green path: two pending versions, `gate` goes green, each PR is merged by the App and the second branch is cut from the head fetched **after** the first merge (the test asserts the second PR's base sha equals the fake `main` head after merge 1); (b) `gate` red: the run fails, the group is released, the second version is not started; (c) a PR closed unmerged: same; (d) deadline: with the fake clock the PR is still waited on at 29:59 and the run fails at 30:00, naming the PR; (e) one at a time: the fake API records that at most one pipeline PR is open at any moment; (f) the merge call is never made before `gate` reports success. **Mutations, each shown red then restored byte-identically:** remove the deadline; merge without waiting for `gate`; branch from the head fetched before the previous merge; open the second PR before the first is terminal. Positive control: the unmodified code passes (a).
20. [script] **`timeout-minutes` sizing (PT11):** the verify script parses the workflow and asserts the write-back job has `timeout-minutes`, or that every PR-wait step has its own; and a unit test of the sizing function asserts N x 30 minutes plus the build allowance for N = 1, 3 and 5. The log states which mechanism was chosen and what limit GitHub documents for it, marked [unverified] until observed (Question Q-N). Mutations: delete the `timeout-minutes`; size it as a constant 30 for N = 5.
21. [script] **A `+` version is refused with a T3, not published (092 Q10):** a fixture entry with a pending `1.0.0+build.5` goes through the planner and the write-back helper with fake build, sign and release functions; the resulting T3 diff (built by `apply_write_back`) is **accepted** by task 007's checkers with the App's bot id, carries `reason` byte-equal to "versions with build metadata (+) are not yet published — pending proof that GitHub resolves them (task 010)" (if 008c's length cap truncates it, stop and report), and the fake build, sign and release functions record **zero calls** (no release, no signing, no clone). Control: `1.0.0-rc.1` in the same fixture does reach the fake build. Mutations: remove the `+` check (the build function is called, red); change one character of the reason (red).
22. [script] **Pre-T1 `source_archive` check (092 Q5, Q9), against a fake HTTP client:** pass when hop 1 is 301 with the derived `Location` and the final bytes hash to `source_sha256` over https hops; each of these exits 2 naming the URL, opens no T1 and no T3: hop 1 answers 200; hop 1 `Location` differs by one byte; a later hop is `http://`; more than 5 hops; the sha differs. The fake records call order and the test asserts release publish -> hop-1 request -> final fetch -> T1 open. Mutations: skip the sha comparison; accept an `http://` hop; open the T1 before the fetch.
23. [live] **Environments bind the keys to `main` (C20; 082 PT3), after M11:** a `workflow_dispatch` of the workflow from a non-`main` branch (a test branch pushed by the manager's account, deleted afterwards) whose signing and write-back jobs declare `environment: signing` and `environment: write-back` does not get those jobs started or does not receive the environment's secrets: the run shows the deployment to the environment rejected by its branch policy. The test branch's workflow does not reference, echo or test either secret (CLAUDE.md rule 11; no `gh secret` command); the evidence is the run URL and the rejected-deployment message. **Until M11 is done and this criterion is recorded, environment binding is unproven, the trust boundary of both keys is every account with write access, and live criteria 6 and 9 wait for it.**
24. [script] **Append-only log and release (PT8), against a fake archive API:** when `logs/<ns>.<name>/<version>.log` already exists, that version fails naming the path and the file is not written, while another pending version in the same run is still processed and the run ends non-green; the same for a published release with the tag. Mutation: overwrite an existing log.

## Explicitly OUT of scope
- 008a's tool; E12 (site rebuild dispatch, task 055); `page.json` screenshot scan (task 040);
  Software Heritage; binary signing; the site.
- Writing the contract amendments (a separate task precedes this one).

## File scope (declared; anything else = stop and report)
In the **registry** repo:
- `.github/workflows/pipeline.yml` (new)
- `tools/pipeline/plan_pending.py` (new — lists pending versions; the unit-testable half of the workflow), `tools/pipeline/sign_built.py` (new — re-verifies a built tarball and signs it; design 8), `tools/pipeline/build_version.py` (**in scope: the `--no-sign` flag only**, design 8; no other behaviour changes) and its tests in `tests/pipeline/`, `tools/pipeline/release.sh` (new — thin, `set -euo pipefail`, no logging of env), `tools/pipeline/write_back_job.py` (new — the write-back loop of design 4, the pre-T1 check and the archive log rule of design 5, the `+` T3 of design 7; takes the clock and the GitHub and HTTP clients as injected objects so criteria 19, 21, 22, 24 run offline; see Question Q-K)
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
- Cloning, building, signing or releasing a version whose `version` contains `+` (092 Q10); opening a T1 PR before the pre-T1 `source_archive` check of design 5 has passed; skipping the sha or https checks of that check.
- Opening a second write-back PR while one is open, or merging before `gate` is green (design 4).

## Dependencies and sequencing
Task 032 (merged, registry PR #4) → task 045 (merged, PR #6) → ADR-0121 (accepted) → task **057** (version lifecycle contract; spec gate-ready, not merged) → 007 and 039 merged (this task
edits 007's ownership module and relies on 039's workflow scaffolding for checks; neither is on registry `main` on 2026-10-15: `git ls-tree -r --name-only origin/main | grep -c '^tools/registry'` prints 0 and the tree has no `.github/`; **amended 2026-10-25:** 039 is split by C23 into **039a** (the composer `tools/registry/ci_gate.py`) and **039b** (the workflow that provides `gate`, the required check the write-back PRs must pass; required only after Ludwig's M9, which is possible only after `gate`'s first live run); 008b's live criteria need 039b merged and M9 done) → 008a (**merged**, PR #7) → 008c (needs 057, 058, 008a) → **008b** → Ludwig's steps M5-M7 (below; M5 and M7 must precede the live criteria) → 010.
**Amended 2026-10-26:** task **082** (E15 contract; registry PR #20, blocked on task 087) and task **092** (`source_archive` contract; registry PR #25) must merge first; criterion 1 needs 082 on `main`, criteria 3, 6, 21 and 22 take their expected values from 092's contract. 092's pre-T1 check and `+` rule are implemented here (design 5, 7).
Also needed before the workflow can be approved: `contracts/pipeline-trigger.md` (E15) and the
ownership carve-out in `contracts/ownership.md` (E16) — sibling contract tasks, see the umbrella. **E15 is task 082** (spec-approved
2026-10-25 night; its merge needs Ludwig's written approval); criterion 1 compares the workflow with its normative block. **Runbook
M11 (Ludwig, amendment 2026-10-25; C20 extended):** create the `signing` and `write-back` environments limited to `main`, move
`MINISIGN_SECRET_KEY` and `PIPELINE_APP_PRIVATE_KEY` into them and delete the repo-level copies (mechanics [unverified]; the
runbook text is booked by the manager, not written here). Until M11 is done, the trust boundary of both keys is every account with
write access to the registry, and the live criteria that use either key (6, 9) wait for it.
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
- **Branch-protection required checks: closed 2026-10-26** — superseded by the required check `gate` (task 039b) and runbook M9; design 4 and criterion 9 name `gate`.
- **Q-K (open, scope, for the manager):** the write-back loop, pre-T1 check and archive-log rule are code that criteria 19, 21, 22 and 24 must test offline with a fake clock and fake APIs, so they need a module. Options: A new `tools/pipeline/write_back_job.py` (adds one source file; 7 in total); B put them in `release.sh` (not testable with a fake clock; criteria 19-24 could not be demonstrated); C put them in 008c's `write_back.py` (outside this task's file scope). **Conservative assumption: A**, already in the file scope above.
- **Q-L (open, decision, for Ludwig):** a T3 needs a non-empty `reason` and an `https://` `build_log_url`; a `+` version has no build log. 092 fixes the reason text but not the URL. Options: A commit a one-line log file `logs/<ns>.<name>/<version>.log` in `archive` containing the refusal text, before the T3 PR, as design 7 does for a rejection (uniform; the append-only rule applies); B point `build_log_url` at 092's contract section (a URL that is not a log); C amend the T3 rule so `build_log_url` may be absent for this cause (changes 057's contract). **Conservative assumption: A.**
- **Q-M (open, naming, for the manager):** design 1 names the dry-run source inputs `dry_run_source_url` and `dry_run_commit` and a synthetic in-run entry. 082 PT12 leaves the names to 008b "and this contract reviews". Options: A these names (assumed); B a single `dry_run_source` string `<url>@<commit>`; C drop the pair and dry-run only `pending` versions on `main`, which would leave criterion 10 without the M4 repository as source. **Conservative assumption: A**, and 082's reviewer confirms it at 082's next touch.
- **Q-N (open, fact, for the manager):** whether GitHub accepts an expression for `timeout-minutes` and what the maximum job time is for hosted runners; both [unverified] here, so N x 30 minutes may be impossible for a large N. Options: A per-PR deadline enforced in `write_back_job.py` (criterion 19) plus a fixed `timeout-minutes` at the documented limit; the run fails at the limit and the rest wait for the next push; B compute the value per run; C per-step timeouts only. **Conservative assumption: A.**
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
- 2026-10-25 amendment (session 11 night, doc-writer): folded in 082's follow-ups (C11-C17, C20 extended, C21, C22) and 039's C23 split: Objective, design 2, 4, 6 (pointer), 8, 9, criteria 1, 9, 10, 14(f), 17, dependencies, status; see "Amendment 2026-10-25". Needs independent re-gate before dispatch; still blocked by 008c.
- 2026-10-26 re-gate fold-in (doc-writer, branch `task/008b-spec-regate`; independent spec review of 2026-10-26 returned PASS-WITH-AMENDMENTS). No new decision: every change applies C11-C23, 082 PT1-PT12 or 092 Q5/Q9/Q10; four gaps that need one are Questions Q-K to Q-N. Where each finding landed:
  1. (HIGH) 092 Q10/Q5/Q9 -> design 2 (`+` not built), design 7 (second T3 cause with 092's exact reason text, fault list), design 4 (ordering upload -> hop-1 fetch -> T1, write-back job owns it), design 5 (the pre-T1 check, Q9 stated, exit 2, manual recovery), Forbidden, criteria 21 and 22; open detail Q-L.
  2. (HIGH) criterion 3 -> 092 worked examples as the source; the `+` URL kept as a pure helper test labelled "derivation only, never published".
  3. (MED) criterion 6 -> `curl -L` through the front, bytes equal, hop 1 exact, https on every hop; [live], depends on M12 (done) and the front; the "blocked until task 058" wording removed.
  4. (HIGH) C13 -> design 3 and criterion 17(a); PT5 -> design 7, design 9 and criterion 17(c); C15 -> design 2, design 7 and criterion 17(b); PT8 append-only log -> design 5 and criterion 24; the "noted, not folded in" list updated.
  5. (HIGH) demonstrable criteria -> criterion 19 (C22 loop, fake clock and API, four mutations), criterion 20 (timeout sizing, Q-N), criterion 17 (planner tests for C13, C15, PT5, Q10), criterion 23 ([live] environments after M11, and the explicit "unproven" statement that holds live criteria 6 and 9).
  6. (MED) Size -> counts refreshed (7 source files, about 800 estimated changed lines, 28 reading-list items; all over the cap), justification written, and a concrete split alternative 008b-1 / 008b-2 marked "manager decides at the gate".
  7. Design 1 -> inputs `dry_run`, `version` and the dry-run input set (PT12); open detail Q-M.
  8. Questions -> branch-protection item closed (superseded by `gate` and M9); the matching Environmental-facts bullet struck.
  9. Criterion 13 mutation list extended to 1-5, 14-17, 19-22, 24; criterion 1 notes 082 must be on `main`; Dependencies: 082 (registry #20, blocked on 087) and 092 (registry #25) must merge first; File scope gains `write_back_job.py` (Q-K).
  10. Status line and amendment preamble corrected.
  Not measured: nothing here was executed; size figures are estimates. Re-gate round 2 pending.
