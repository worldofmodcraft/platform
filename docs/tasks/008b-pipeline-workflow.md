# Task 008b: Pipeline workflow — post-merge run, release upload, protected write-back

- **Mission:** SITE-V1, deliverable **D2** (second half; umbrella `docs/tasks/008-build-pipeline.md`) — **Status:** spec-approved 2026-10-26 (manager, after independent spec review rounds 1-2 of the split; round-2 fixes mechanical). This file is the umbrella: **no agent is dispatched on it**; it keeps the decisions, design, environmental facts, manual steps, history and the mapping tables of the four parts
- **Agent / model:** none (umbrella)
- **Budget:** n/a — see the parts: 008b-1 medium, 008b-2 medium, 008b-3a small, 008b-3b large
- **Branch / worktree:** none; parts use `task/008b1-pipeline-plan`, `task/008b2-pipeline-build-sign`, `task/008b3a-ownership-carve-out`, `task/008b3b-pipeline-write-back` — **registry** repo

## Split (manager decision, spec gate 2026-10-26; refined after the split's independent review, manager ★, session 12)
The re-gate's size count (7 source files, about 800 changed lines, 28 reading items) was over every cap. The manager split it into four task files. Sequence: **008c -> 008b-1 -> 008b-2 -> 008b-3b**, with **008b-3a** (ownership carve-out; needs Ludwig's approval, CI security check) merged before 008b-3b and free to run in parallel with 008b-1/2, and tasks 082 (registry #20, blocked on 087) and 092 (registry #25) merged first. **No agent is dispatched on this umbrella.** The old file `008b3-pipeline-write-back.md` is removed (`git rm`/rename): its content is in 3a and 3b.
- **008b-1** `docs/tasks/008b1-pipeline-plan.md` — the planner (`plan_pending.py`: C11-C13, C15, PT5 via `summarize_outcomes()`, the `+` classification of 092 Q10, refusal-log recovery, the dry-run input set of PT12, the pinned plan-document schema and exit codes). About 190 lines, 1 source file, 9 reading items.
- **008b-2** `docs/tasks/008b2-pipeline-build-sign.md` — the workflow file with the plan, build, sign, dry-run and summary jobs, the push gate, the **build-result handoff** (owner), `--no-sign`, `sign_built.py`, `handoff.py`, environment `signing`. About 340 lines (over by 40, justified there), 4 source files, 10 reading items.
- **008b-3a** `docs/tasks/008b3a-ownership-carve-out.md` — `ownership.py` carve-out only. About 60 lines, 1 file, 7 reading items.
- **008b-3b** `docs/tasks/008b3b-pipeline-write-back.md` — the write-back job, `write_back_job.py` (loop, pre-T1 check, archive log rule, T3 builder `build_t3()`), `release.sh`, gate removal, environment `write-back`. About 400 lines (justified there), 3 source files, 9 reading items.

### Mapping: acceptance criteria (every original criterion, or clause of one, lands in exactly one part)
| Umbrella criterion | Part | Note |
|---|---|---|
| 1 E15 contract and trigger-block comparison | 008b-2 | needs 082 on `main`; asserts all four dispatch inputs |
| 2 secrets referenced exactly once each | 008b-3b | evaluated on the combined workflow; 008b-2's 14(d) covers the signing key meanwhile |
| 3 naming and URL helpers | 008b-1 | `+` example is derivation only |
| 4 write-back is exactly T1 / T3 | 008b-3b: the T1/T3 diffs built by `apply_write_back` and `build_t3()` pass the append-only and schema checkers · 008b-3a: the ownership checker accepts the permitted diffs for the App's id and rejects another id | |
| 5 ownership carve-out narrow | 008b-3a | needs Ludwig's approval |
| 6 [live] release upload, front fetch | 008b-3b | |
| 7 [live] runner assumptions | 008b-2 | |
| 8 [live] fork safety | 008b-2 | |
| 9 [live] App-token behaviour | 008b-3b | |
| 10 [live] dry run | 008b-2 | |
| 11 [live] failure path (dry run) | 008b-2 | failure log is a workflow artifact (PT12); T3 shown by 008b-3b criteria 4, 21, 28, 29 |
| 12 idempotence of the no-op | 008b-1 | live half also in 008b-3b criterion 27 |
| 13 verify script, mutation-tested | each part | restated per part for that part's criteria; no original criterion is dropped |
| 14 clone job has no secret | 008b-2: clauses (a)-(d), signing and dry-run half of (f) · 008b-3b: clause (e), write-back half of (f), and a re-run of all of 008b-2's verify script on the combined workflow | |
| 15 test-only flags absent | 008b-2 | |
| 16 `--no-sign` and the sign step | 008b-2 | |
| 17 retry path and planner tests | 008b-1: planner clauses and (a)-(g) · 008b-2: the `env:`-only clause | |
| 18 docs move with code | split by section: 008b-1 plan document; 008b-2 plan/build/sign/dry-run jobs; 008b-3b write-back, recoveries (incl. killed run), "what Ludwig must do"; 008b-3a none | |
| 19 write-back loop, fake clock | 008b-3b | |
| 20 `timeout-minutes` sizing | 008b-3b | N x 30 + margin, capped |
| 21 `+` version refused with a T3 | 008b-3b | planner classification is 008b-1's 17(d) |
| 22 pre-T1 `source_archive` check | 008b-3b | |
| 23 [live] environments bind keys to `main` | 008b-3b | covers both environments |
| 24 append-only log and release | 008b-3b | |
| 25 push gate (added at the split review) | 008b-2 | |
| 26 handoff layout (added) | 008b-2 | |
| 27 gate removed, trigger live (added) | 008b-3b | |
| 28 PT10 order and PR comment (added) | 008b-3b | |
| 29 refusal-log recovery (added) | 008b-3b | planner side is 008b-1's 17(e) |

### Mapping: designs, decisions, files, manual steps
| Item | Part |
|---|---|
| Design 1 trigger; dry-run input set (PT12; Q-M) | 008b-2 declares the workflow inputs; 008b-1 owns their names and validation |
| Design 2 (pending listing, C11, C12, C15, `+` classification) | 008b-1 |
| Design 3 concurrency: group declared | 008b-2; planner branch skip (C13) 008b-1; group held until PRs terminal 008b-3b |
| Design 4 write-back sequencing (C22, PT11) | 008b-3b |
| Design 5 release, pre-T1 check (092 Q5/Q9), append-only log (PT8) | 008b-3b |
| Design 6 key use in one step | 008b-2 |
| Design 7 exit-1 T3, `+` T3 (Q10, Q-L), build-log location, comment | 008b-3b; exit-2 faults and PT5 behaviour: 008b-1 (`summarize_outcomes`) and 008b-2 (matrix, summary job, handoff) |
| Design 8 SSRF split, `--no-sign`, sign step, `signing` environment, dry-run job | 008b-2; `write-back` environment and job 008b-3b |
| Design 9 retry/dispatch | 008b-1 (validation, planner), 008b-2 (`env:` only) |
| Decisions Q-B, C11, C12, C15, Q-M | 008b-1 |
| Decisions SSRF split, C14 (signing), C16, C17, C21, Q-H, C20 (signing), push gate, handoff | 008b-2 |
| Decisions Q-D, Q-E, Q-G, Q-J, build-log location, C13 (hold), C14 (write-back), C20 extended (write-back), C22, C23, 092 Q5/Q9/Q10, Q-K, Q-L, Q-N | 008b-3b (Q-D's identity for the carve-out also in 008b-3a) |
| Files: `plan_pending.py` | 008b-1 · `pipeline.yml` (all but write-back job), `sign_built.py`, `handoff.py`, `build_version.py` flag: 008b-2 · `ownership.py`: 008b-3a · `pipeline.yml` write-back job and gate removal, `write_back_job.py`, `release.sh`: 008b-3b |
| `docs/pipeline/build-pipeline.md` | shared by section: 008b-1 plan document; 008b-2 jobs; 008b-3b write-back, recoveries, "what Ludwig must do" |
| Manual steps M5, M7 (this file's section) | 008b-3b · M6: 008b-3a · M11: 008b-2 (`signing`) and 008b-3b (`write-back`) · M3 / Q-H: 008b-2 |

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

## Size (5b) — superseded by the split
**Counts refreshed 2026-10-26 for the undivided task (estimates; nothing built):** 7 source files (cap 5), about 800 changed lines (cap 300), 28 reading-list items (cap 10) — over every cap. The justification for keeping one task (one security argument across workflow, planner, sign step and write-back) was weighed at the gate and **not accepted**: the manager split the task three ways (see "Split" above). Real estimates per part are in each part's own Size section: 008b-1 about 190 lines, 1 file, 9 items; 008b-2 about 340 lines, 4 files, 10 items (justified there); 008b-3a about 60 lines, 1 file, 7 items; 008b-3b about 400 lines, 3 files, 9 items (justified there). The 008d trigger (if the `--no-sign` change is not green after session 3 it becomes its own task) moved to 008b-2.

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
**Moved to the parts.** The full text of criteria 1-29 now lives in the part files named in the mapping table under "Split" (criteria 14 and 17 are divided by clause; 13 and 18 are restated per part). Criterion numbers are kept in the parts so this table can be checked. The numbering history: criteria 1-18 were written 2026-10-14/15; 19-24 were added at the 2026-10-26 re-gate (write-back loop, timeout sizing, `+` T3, pre-T1 check, environments live test, append-only log); 25-29 at the review of the split (push gate, handoff layout, gate removal and live trigger, PT10 order and PR comment, refusal-log recovery). No agent is dispatched on this umbrella.

## Explicitly OUT of scope
- 008a's tool; E12 (site rebuild dispatch, task 055); `page.json` screenshot scan (task 040);
  Software Heritage; binary signing; the site.
- Writing the contract amendments (a separate task precedes this one).

## File scope (declared; anything else = stop and report)
**Superseded by the parts' own File scope sections (mapping table above); retained as the union.** In the **registry** repo:
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
- **Q-K (CLOSED 2026-10-26, decided by the manager: option A, starred; Ludwig's overnight instruction "Ta stjärna på alla beslut"; goes to 008b-3b):** the write-back loop, pre-T1 check and archive-log rule are code that criteria 19, 21, 22 and 24 must test offline with a fake clock and fake APIs, so they need a module. Options: A new `tools/pipeline/write_back_job.py` (adds one source file; 7 in total); B put them in `release.sh` (not testable with a fake clock; criteria 19-24 could not be demonstrated); C put them in 008c's `write_back.py` (outside this task's file scope). **Conservative assumption: A**, already in the file scope above.
- **Q-L (CLOSED 2026-10-26, decided by the manager: option A, starred, consistent with the 2026-10-15 build-log decision; goes to 008b-3b; ★ closure, Ludwig may overrule — the manager lists it For Ludwig; recovery rule added manager ★, session 12):** a T3 needs a non-empty `reason` and an `https://` `build_log_url`; a `+` version has no build log. 092 fixes the reason text but not the URL. Options: A commit a one-line log file `logs/<ns>.<name>/<version>.log` in `archive` containing the refusal text, before the T3 PR, as design 7 does for a rejection (uniform; the append-only rule applies); B point `build_log_url` at 092's contract section (a URL that is not a log); C amend the T3 rule so `build_log_url` may be absent for this cause (changes 057's contract). **Conservative assumption: A.**
- **Q-M (CLOSED 2026-10-26, decided by the manager: option A, starred; 008b owns the naming per PT12; goes to 008b-1 and 008b-2; 082's reviewer still confirms the names):** design 1 names the dry-run source inputs `dry_run_source_url` and `dry_run_commit` and a synthetic in-run entry. 082 PT12 leaves the names to 008b "and this contract reviews". Options: A these names (assumed); B a single `dry_run_source` string `<url>@<commit>`; C drop the pair and dry-run only `pending` versions on `main`, which would leave criterion 10 without the M4 repository as source. **Conservative assumption: A**, and 082's reviewer confirms it at 082's next touch.
- **Q-N (CLOSED 2026-10-26, decided by the manager: option A, starred; revised manager ★, session 12: job `timeout-minutes` = N x 30 + margin capped at the documented limit; goes to 008b-3b):** whether GitHub accepts an expression for `timeout-minutes` and what the maximum job time is for hosted runners; both [unverified] here, so N x 30 minutes may be impossible for a large N. Options: A per-PR deadline enforced in `write_back_job.py` (criterion 19) plus a fixed `timeout-minutes` at the documented limit; the run fails at the limit and the rest wait for the next push; B compute the value per run; C per-step timeouts only. **Conservative assumption: A.**
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
- 2026-10-26 split (doc-writer, branch `task/008b-spec-regate`, on the manager's gate decision): the umbrella is now a decisions record; criteria 1-24, the designs, decisions, files and manual steps are mapped to 008b-1 (`008b1-pipeline-plan.md`), 008b-2 (`008b2-pipeline-build-sign.md`) and 008b-3 (`008b3-pipeline-write-back.md`) in the "Split" tables above; criteria 13 and 18 are restated per part and 14 and 17 are divided by clause. Q-K, Q-L, Q-M, Q-N closed as decided by the manager (option A, starred). Sequence 008c -> 008b-1 -> 008b-2 -> 008b-3, with 082 and 092 merged first. Interface assumption for the reviewer: the plan document (lists `build`, `refuse`, `skip`, `fault`, head SHA) between 008b-1 and 008b-2/3 is internal to node N5 and adds no graph edge. Nothing was executed; part sizes are estimates. Independent spec review of each part pending.
- 2026-10-26 split review fold-in (doc-writer; independent review of head 05f105c returned PASS-WITH-AMENDMENTS on all parts; choices marked "manager ★, session 12"). Where each finding landed:
  1. (HIGH) 008c's `apply_write_back` builds T1 only -> pure `build_t3()` added to `write_back_job.py` and scope; criteria 4 and 21 reworded; the cap clause replaced by a check against the schema's `reason` rule (008b-3b).
  2. (HIGH) 2->3 interface -> new section "Build-result handoff" in 008b-2 (matrix with `fail-fast: false`, artifacts `plan`, `build-<tag>`, `signed-<tag>`, `outcome.json` fields, exit 0/1/2, how refuse/rejected/fault pass through, the write-back job's `always()` condition), `handoff.py` added to 008b-2's scope, criterion 26; 008b-3b cites it. Scope addition `handoff.py` is mine, needed to make the layout testable; the manager may overrule.
  3. (MED) push gate: every job `if: github.event_name != 'push'` in 008b-2 (criterion 25); removed and proven live in 008b-3b (criterion 27).
  4. (MED) planner exit codes pinned (exit 0 with document even with skip/refuse/fault; exit 1 only for bad inputs, no document), the final `summary` job makes the run non-green, 17(a) reworded (008b-1; 008b-2).
  5. (MED) `summarize_outcomes()` in `plan_pending.py` owned and tested by 008b-1 (17(c)); plan-document field schema pinned (17(g)).
  6. (MED) 008b-2 criterion 11: a dry run's failure log is the workflow artifact `build.log`.
  7. (MED) 008b-3b criterion 28: log commit precedes the T3 PR; full `build.log` commented on the merged PR; lookup method named (`git log --reverse -S`, then the commit-associated-PRs endpoint [unverified]).
  8. (MED) 008b-3 split into 008b-3a (`ownership.py`, criterion 5 and the ownership clause of 4, M6) and 008b-3b (the rest); old file renamed to 3b; mapping tables regenerated; sizes re-estimated (3a about 60 lines, 3b about 400 lines with justification, reading lists 7 and 9).
  9. (LOW/MED) Q-L recovery: 008b-1 planner `log_exists` on `refuse` entries (17(e)), 008b-3b re-opens only the T3 PR (criterion 29); Q-L marked "★ closure, Ludwig may overrule", for the manager's For-Ludwig list.
  10. (LOW) `timeout-minutes` = N x 30 + margin capped at the documented limit (criterion 20, Q-N revised); killed-run recovery steps in criterion 18 (008b-3b).
  11. (LOW) 008b-2 criterion 1 asserts all four dispatch inputs; edge labels corrected against `depgraph.md` (E7 = N5 -> N6 naming, E8 = N5 -> N2 write-back, E15 = N2 -> N5 trigger): 008b-1 E15 + E7, 008b-2 E15 + E7, 008b-3b E7 + E8 + E15, 008b-3a E16.
  12. (LOW) 008b-3b criterion 14 re-runs all of 008b-2's verify script on the combined workflow (the push-gate check is replaced by criterion 27).
  Nothing executed; sizes are estimates. Independent spec reviews of 3a and 3b pending.
- 2026-10-26 round-2 review fold-in of the split (doc-writer; 008b-1, 008b-3a and this umbrella PASS, 008b-2 and 008b-3b PASS-WITH-AMENDMENTS; choices "manager ★, session 12"): (c28) 008b-3b criterion 28 states `fetch-depth: 0`, [unverified]. 1 (MED) 008b-2 handoff "Job conditions": build runs only when `has_build`, write-back when `has_writeback`, zero pending ends green; `handoff.plan_flags()` and criterion 26(c) with mutations; empty-matrix rejection marked [unverified]. 2 (MED) sign job `if: always() && needs.plan.result == 'success' && has_build` plus the per-version `exit_code == 0` guard, asserted in 26(a). 3 (MED) any sign-step re-verification failure is `exit_code` 2 in the handoff (only 008a's exit 1 is a rejection); 26(e) and a mutation. 4 (LOW) `reason` format read from the 087+082 merge checkout's `pipeline_errors.py` and `build_version.py` (`REJECTED [<rule>]: <message> -- remedy: <remedy>`; trimming stated; the same read showed that exit 1 and 2 leave only `build.log`, so the handoff's earlier claim of a `result.json` on failure is corrected and `build.stderr` is added; the registry-`main` text is [unverified] to match). 5 (LOW) `summary` condition `always() && github.event_name != 'push'` stated in 25 and 26(a). 6 (LOW) 008b-3b Size: pre-agreed cut of criteria 28 and 29 into 008b-3c if `write_back_job.py` exceeds about 300 lines. 7 (LOW) 008b-3b: the push gate may not be removed before runbook M11 (criterion 27 and Dependencies). Status of all four parts and this umbrella set to spec-approved 2026-10-26; 008b-3a keeps "Needs Ludwig's approval before merge: CI security check". Nothing executed.
