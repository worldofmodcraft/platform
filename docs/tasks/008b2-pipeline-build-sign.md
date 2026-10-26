# Task 008b-2: Pipeline workflow — plan, build, sign and dry-run jobs

- **Mission:** SITE-V1, deliverable **D2** (umbrella `docs/tasks/008b-pipeline-workflow.md`, which keeps the decisions, design and history; design numbers below refer to it) — **Status:** draft — split from 008b at the spec gate 2026-10-26; independent spec review pending
- **Agent / model:** implementer / sonnet
- **Budget:** medium
- **Branch / worktree:** `task/008b2-pipeline-build-sign` / `~/wt/registry-task-008b2` — **registry** repo
- **Sequence:** 008c -> 008b-1 -> 008b-2 -> 008b-3, and tasks 082 (registry PR #20, blocked on 087) and 092 (registry PR #25) merged first. Follows 008b-1 (the planner it calls). 008b-3 adds the write-back job to the same workflow file afterwards.

## Objective
`.github/workflows/pipeline.yml` exists in the registry with the E15 trigger block, the `pipeline` concurrency group, a **plan** job (runs 008b-1's planner), a **build** job that holds no secret and runs 008a's tool with the new `--no-sign` flag, a **signing** job that receives only the built artefact, re-verifies it with the new `tools/pipeline/sign_built.py` and signs it with `MINISIGN_SECRET_KEY` under `environment: signing`, and a **dry-run** job that signs with an ephemeral in-run key and uploads workflow artifacts only. The workflow has no write-back job yet; a push run therefore builds and signs the planned versions and writes to no repository (the write-back job arrives with 008b-3, and until then the workflow must not be merged to a branch where the push trigger would run it without a consumer for its artifacts — see Dependencies). The signing key is reachable only in runs on `main`, bound by the `signing` environment, not by the job's `if:`.

## Context to load (exhaustive; 10 items)
- ADR-0041 (key in build secrets, usable only by the build workflow).
- Contracts: `pipeline-trigger.md` (task 082: PT1, PT3, PT5, PT12 and the normative trigger block); `signature-format.md`.
- Platform: `docs/architecture/key-management.md`; the umbrella `008b-pipeline-workflow.md` (designs 1, 6, 8, 9 and "Environmental facts").
- 008a modules, read from the registry `origin/main`: `tools/pipeline/build_version.py`, `signing.py`, `reference_verify.py`, `archive.py`.
- 008b-1's plan document (`docs/pipeline/build-pipeline.md` once 008b-1 has merged).

## Size (5b)
Within every cap. Source files: 3 (`pipeline.yml`, `sign_built.py`, `build_version.py` — the `--no-sign` flag only). Changed lines: about 270 (estimate: workflow 120, `sign_built.py` 110, `build_version.py` 40; nothing built). Reading list: 10. Tests, fixtures, `008b2-verify.sh` and docs excluded. Live criteria 7, 8, 10, 11 need Ludwig (M3, M11 for the environment, a fork he creates) and dominate calendar time, not agent time. **Split trigger (from the umbrella):** if after session 3 the `--no-sign` change and its tests (criterion 16) are not green, they become task 008d, a small offline task on 008a's tool, and this task waits for it.

## Design (taken from the umbrella; decisions are recorded there)
Designs 1 (trigger; inputs declared with the names 008b-1 fixes), 6 (key use in one step), 8 (SSRF job split, `--no-sign` and the sign step with tests (a)-(d), key binding for the signing job, dry-run job), and 9 (inputs through `env:`), as written in the umbrella. Decisions carried: SSRF split and `--no-sign` (Ludwig / coordinator 2026-10-15); C14 (ref condition, signing job); C16, C17 (parsed-key comparison, closed trigger list); C20 (the `signing` environment; M11 is Ludwig's); C21 (dry runs sign only with an ephemeral key); PT5 (the per-version driver continues after a fault and the run ends non-green naming each; wired here from 008b-1's plan). Test-only flags of 008a never appear in the workflow (criterion 15). Until M11 is done the trust boundary of the signing key is every account with write access to the registry; the live criteria that use the key wait for it.

## File scope (declared; anything else = stop and report)
In the **registry** repo: `.github/workflows/pipeline.yml` (new; **this part owns the whole file except the write-back job**, which 008b-3 adds and owns), `tools/pipeline/sign_built.py` (new), `tools/pipeline/build_version.py` (**the `--no-sign` flag only**; no other behaviour change) and their tests in `tests/pipeline/`; `docs/pipeline/build-pipeline.md` (additions: the workflow's plan, build, sign and dry-run jobs and their failure modes); `docs/tasks/008b2-pipeline-build-sign.md` (log); `docs/tasks/008b2-verify.sh` (new, executable). No edits to `contracts/`, to 008a's other modules (`gitops.py`, `archive.py`, `signing.py`, `reference_verify.py`, `naming.py`), `tools/pipeline/plan_pending.py` (008b-1's), `tools/registry/`, `reserved-namespaces.json` or the site repo.

## Acceptance criteria
Criterion numbers are the umbrella's (`008b-pipeline-workflow.md`), kept so the mapping table there can be checked; a part's list therefore has gaps. [script] = checked by this part's verify script; [live] = a real run, recorded with run URLs, **not** script-verified.

1. [script] **The E15 contract exists first:** `contracts/pipeline-trigger.md` (task 082, registry PR #20, blocked on 087) is present on `main`
   (landed by the contract task; this criterion cannot be run until 082 has merged) and the workflow matches its normative trigger block **on parsed keys, not bytes**: the verify
   script parses `.github/workflows/pipeline.yml` and asserts the `on` keys are exactly {`push`, `workflow_dispatch`} (PyYAML
   reads the key `on` as boolean `True`; the comparer handles both), `push` and `concurrency` equal the block's, and the
   `workflow_dispatch` inputs are a superset of {`dry_run`, `version`}. It **fails on zero matches** (no `push.branches` `main`
   found, or the block absent from the contract), and asserts the absence of `pull_request_target`, `pull_request:` and
   `workflow_run` in the signing workflow file.
7. [live] **Runner assumptions:** the run log shows the minisign version and the pinned download's
   checksum verification; if apt or a different install path was used instead, the log and this
   file say so.
8. [live] **Fork safety:** a fork pull request (opened by a non-member account, created for the
   test; credentials for it follow CLAUDE.md rule 11 — the permitted mechanism is a *fork created
   by Ludwig himself, in session*, not any stored token) that modifies the signing workflow to print
   the secret does not receive the secret: the run either does not start (approval required — M1.4
   default) or the variable is empty. Recorded with the run. The test PR is closed unmerged.
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
13. [script] **Verification script.** `docs/tasks/008b2-verify.sh` exists, is executable, covers criteria 1, 14, 15, 16 and 17 (workflow clause), is mutation-tested (criteria 1, 14, 15, 16 and 17 with the mutations they name; each mutation shown red then restored byte-identically), is run in a fresh clone, and its output is pasted in the log; the log separates [script] from [live] results. Every check fails on zero matches.
14. [script] **The clone job has no access to the signing secret — a workflow-level check.** The verify script parses `.github/workflows/pipeline.yml` (PyYAML, or a stdlib parser if the CI runner lacks it; runner availability unverified) and asserts, for the job that runs `build_version.py`: (a) the job's whole subtree contains no `secrets.` token, no `secrets: inherit`, and no `uses:` of a reusable workflow; (b) neither the workflow-level nor the job-level `env`/`permissions` references a secret, and the job's `permissions` is exactly `contents: read`; (c) the job has no step with `MINISIGN_SECRET_KEY` or `PIPELINE_APP_PRIVATE_KEY` as a name; and, for the signing job: (d) it contains `secrets.MINISIGN_SECRET_KEY` exactly once, `needs:` the build job, and has no `git clone`, no `build_version.py`, no `source_url` and no `actions/checkout` of anything but this repository's own tools at the pinned `main` sha; and, for the signing job and the dry-run job (design 8, C20): (f) the signing job declares `environment: signing` and carries the `github.ref == 'refs/heads/main'` condition, and the dry-run job declares no `environment` and references neither secret (mutations: drop the `environment:` of the signing job; add `environment: signing` to the dry-run job). The check **fails on zero matches** of the build job (it must find the job by its `build_version.py` step, never pass vacuously). **Mutations**, each shown red then restored byte-identically: add `${{ secrets.MINISIGN_SECRET_KEY }}` to the build job's `env`; add `secrets: inherit`; move the signing step into the build job; add `build_version.py` to the signing job; widen the build job's `permissions` to `contents: write`. Positive control: the unmodified workflow passes. This criterion proves the *structure*; that GitHub withholds a job's secrets from other jobs is documented behaviour, not observed here (`[unverified]`), and the live fork-safety criterion 8 covers only forks. No command in this task prints, tests for, or lists the secret. (Umbrella criterion 14, clauses (a)-(d) and the signing and dry-run half of (f). The write-back half, (e) and the rest of (f), is in 008b-3.)
15. [script] **Test-only flags absent:** the workflow contains none of `--allow-local-source`, `--clone-timeout`, `--max-clone-bytes`, `--max-compressed-bytes`, `--max-uncompressed-bytes`, `--max-entries`, `--scanner` (grep, with a mutation that adds one and shows red).
16. [script] **`--no-sign` and the sign step** satisfy tests (a)-(d) of design 8, each shown red by a mutation (let `--no-sign` accept `--key`; skip the sha re-check; skip the size re-check; skip `reference_verify`) and restored byte-identically; 008a's suite is run unchanged and passes.
17. [script] **Inputs reach scripts only through `env:` (umbrella criterion 17, workflow clause; design 9).** The verify script parses the workflow and asserts that `version`, `dry_run_source_url` and `dry_run_commit` are read only through `env:` and that no `${{ inputs.* }}` appears inside any `run:`. It **fails on zero matches** (the three `env:` bindings must be found). Mutation: put `${{ inputs.version }}` in a `run:` and show red. Also: if the per-version driver is a matrix, `strategy.fail-fast` is `false` (082 PT5; the behaviour itself is 008b-1's criterion 17(c)); mutation: set it `true`.
18. **Docs move with code:** `docs/pipeline/build-pipeline.md` gains the plan, build, sign and dry-run jobs and their failure modes (umbrella criterion 18, first part). `docs/architecture/key-management.md` is **not** edited here (D5 key note is Ludwig's task 056 domain) except for a one-line pointer if needed.

## Explicitly OUT of scope
The write-back job, releases, PRs, the archive log, the App token, the ownership carve-out (all 008b-3); the planner (008b-1); 008a's tool apart from the flag; E12 (task 055); `page.json` screenshot scan (task 040); Software Heritage; binary signing; the site.

## Forbidden here (beyond MANAGER.md §3.7)
- **Printing, copying, or testing for the secret** in any form; no `gh secret` commands of any kind. A denied credential access is information and is not retried (CLAUDE.md rule 11).
- `pull_request_target`, or any trigger a fork can fire with the key reachable.
- Any secret reference in the build job, the dry-run job or at workflow level; any use of the production key in a dry run.
- Test-only flags of 008a (`--allow-local-source`, `--clone-timeout`, `--max-*`, `--scanner`) in the workflow.
- Any use of `GITHUB_ACTOR`/`GITHUB_ACTOR_ID`; reading the author's mod from its live repo after the clone step, or building from a branch name.

## Dependencies and sequencing
008a merged (PR #7); 008b-1 merged; tasks 082 and 092 merged (criterion 1 compares with 082's block); 039a/039b are not needed by this part. **Runbook M11 (Ludwig):** creates the `signing` environment limited to `main`, moves `MINISIGN_SECRET_KEY` into it and deletes the repo-level copy (mechanics [unverified]); until M11 is done, live criteria 7 and 10 may run (the ephemeral key is not the production key) but nothing signs with the production key, and the signing key's trust boundary is every account with write access. M3 (the key exists) is Ludwig's, Q-H below. Blocks 008b-3. Graph: nodes N5, N6; edges E7 (inputs), E15.

## Verification artefact (MANAGER.md §2c)
Declared: `docs/tasks/008b2-verify.sh` for the [script] criteria; the [live] criteria (7, 8, 10, 11) are recorded with run URLs and are said plainly to be unscripted. The criterion-11 note: the T3 PR itself belongs to 008b-3.

## Deliverables
Workflow (without the write-back job) + `sign_built.py` + the flag + tests + docs section + verify script + this file's log section current.

## Questions  (agent-maintained; see MANAGER.md 8b)
- **Q-H (open, fact, for Ludwig):** does `MINISIGN_SECRET_KEY` still exist on `worldofmodcraft/registry`, and is the offline backup of the private key done? (The mission log says M3 was completed 2026-09-05; no agent may check — `gh secret` commands are forbidden.)
- **Q-M: decided** (manager, option A starred, 2026-10-26): the workflow declares the inputs `dry_run`, `version`, `dry_run_source_url`, `dry_run_commit`; 008b-1 owns their validation.

---
# Task 008b-2 log  (append-only, updated continuously by the executing agent)
- 2026-10-26 split from 008b at the spec gate (manager decision); nothing started.
