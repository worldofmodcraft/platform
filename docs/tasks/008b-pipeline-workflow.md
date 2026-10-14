# Task 008b: Pipeline workflow — post-merge run, release upload, protected write-back

- **Mission:** SITE-V1, deliverable **D2** (second half; umbrella `docs/tasks/008-build-pipeline.md`) — **Status:** draft (spec written 2026-10-14 under task 054). **Not dispatchable.** Touches the signing secret and a CI security check: **merge requires Ludwig's explicit approval (MANAGER.md §7).** An independent reviewer performs a spec review before delegation (SPEC-CHECKLIST: security-touching).
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
- ADRs: 0041 (key in build secrets, usable only by the build workflow; archiving), 0058 §1 (the
  pipeline "merges" write-back; rejections return the full log in the PR), 0040 §5, 0099 (CI
  gates), 0059 §3, 0103, 0117, 0119, 0120.
- Contracts: `artifact-naming.md` (never overwrite an existing tag; "What this document does not
  cover" lists idempotency as this task's), `signature-format.md`, `archive-layout.md`,
  `entry.schema.json`/`append-only.rules.md` **as amended by the contract task**,
  `origin/task/032-ownership-contract:contracts/ownership.md` (the identity rule; `GITHUB_ACTOR*`
  forbidden as an identity source), `rebuild-trigger.md` (E12 — **not this task**; see 055, but the
  two interact, criterion 10).
- Platform docs: `docs/architecture/depgraph.md` (E15 and the Q4=A rationale in mission log Q4),
  `docs/architecture/key-management.md`, `docs/manager/OPERATIONS.md` ("Consequences of branch
  protection that bite later", "The manager's own permissions"), `docs/runbooks/site-v1-manual-steps.md` (M1.4, M3).
- Depends on 008a's tool: `tools/pipeline/build_version.py`, `release_url`, `apply_write_back`.
- Graph: nodes **N5**, **N6**, **N2**, **N3**; edges **E7**, **E8**, **E15**, **E16**.

## Environmental facts (what is verified, what is not)
- **Verified 2026-10-14:** `origin/main` of the registry has no `.github/` directory (`git -C
  /home/ludwig/registry ls-tree -r --name-only origin/main | grep -c '^\.github'` → `0`), and no
  `contracts/pipeline-trigger.md` (see umbrella F2). `github-actions[bot]` is numeric id 41898282
  (unauthenticated `GET /users/github-actions[bot]`). minisign behaviour: see 008a.
- **Unverified here (no workflow has ever run in this repo); each is tested by a criterion below,
  and the spec's rule stands regardless of the basis:**
  - GitHub-hosted runners can run the pinned minisign 0.12 static binary (the M3 download), and
    `ubuntu-latest` provides `git`, `gh`, `python3`. (criterion 7)
  - Pull requests and merges made with the workflow's built-in `GITHUB_TOKEN` do not trigger other
    workflows (documented GitHub behaviour). (criterion 9)
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
   state (umbrella Q1 assumed A), and builds each. Zero pending versions → the run succeeds doing
   nothing (this is what stops the write-back merge's own push from looping). It never trusts the
   diff for *authority*: the entry's content on `main` is the input, and 008a re-validates
   everything.
3. **Concurrency:** `concurrency: { group: pipeline, cancel-in-progress: false }`. Two merges
   queue; the second run sees the first's write-back PR (or waits for it).
4. **Branch and PR:** push `pipeline/<ns>.<name>-<version>` to this repository, open a PR to
   `main` whose diff is exactly one version object's `pending → published` transition. Two PRs per
   publish (OPERATIONS.md), by design. Identity per umbrella Q3.
5. **Release:** repository per Q4 (assumed A: this one). Create the release as a **draft**,
   upload both assets, then publish. An existing release with that tag: published → fail with
   `artifact-naming.md`'s "never overwrite" wording; draft (an earlier run died mid-way) → delete
   and recreate. The tag is `ns.nm-v` and is created on `main`'s current head.
6. **Key:** `MINISIGN_SECRET_KEY` exists as an Actions secret (M3 done 2026-09-05 per the mission
   log). Used in exactly one step, via an environment variable scoped to that step only, handed to
   008a's tool as a process-substitution path (or a 0600 file under `$RUNNER_TEMP` removed in an
   `if: always()` step). No `set -x` anywhere in that step. The step prints nothing derived from the
   key. Whether the secret exists is **not** checked by this spec (see Questions).
7. **Failure:** a build rejection (008a exit 1) → comment `build.log` on the originating merged
   PR, mark the version's pipeline PR not opened, fail the run with a distinct message. Exit 2 is
   a pipeline fault → fail the run, comment nothing about the author's mod. A rejected version
   stays `pending` on `main`; the remedy is a new version PR — **Q-open: what removes a rejected
   pending version?** (append-only forbids deletion; this is a design hole to settle in the
   contract task, flagged below).

## Acceptance criteria
Script = `docs/tasks/008b-verify.sh`; live = a real run, recorded with run URLs, **not**
script-verified.
1. [script] **The E15 contract exists first:** `contracts/pipeline-trigger.md` is present on `main`
   (landed by the contract task) and the workflow's trigger block matches it; the verify script
   greps the workflow for `on:` → `push` → `branches` `main` and **fails on zero matches**, and
   asserts the absence of `pull_request_target`, `pull_request:` and `workflow_run` in the
   signing workflow file.
2. [script] **The secret is referenced exactly once**, in the signing step's `env:`; the verify
   script counts occurrences of `secrets.MINISIGN_SECRET_KEY` across `.github/` and asserts the
   count is 1 and that no `run:` block contains `echo`, `printf` or `cat` of that variable name,
   and no `set -x`/`-o xtrace` appears in the workflow. Mutation: add each forbidden pattern to a
   copy of the workflow and show the check redden.
3. [script] **Naming:** a unit test feeds `(namespace, name, version)` triples through the
   workflow's naming/URL helper (008a's `release_url`) and asserts tag, both asset names and the
   `source_archive` URL equal the `artifact-naming.md` examples (`mc.hello-world-1.0.0`,
   `.tar.gz`, `.tar.gz.minisig`), including a prerelease+build version.
4. [script] **The write-back is exactly the permitted transition:** a test builds the PR diff for a
   fixture entry (using 008a's `apply_write_back`) and runs it through task 007's append-only,
   schema and ownership checkers (with the pipeline identity as PR author, per the carve-out):
   accepted; the same diff with any extra changed field, a second version touched, or a different
   author id → rejected, each shown.
5. [script] **The carve-out is narrow and tested both ways:** the ownership gate accepts the
   pipeline identity's id *only* for a PR whose changes are exactly the transition in criterion 4 and
   rejects it for: a first publish, a new version, a `page.json` edit, a takedown, any change under
   `contracts/` or `.github/`. The hostile fixture from task 007 (id differs, username matches) still
   rejects. Positive control: an owner's ordinary PR still accepts. [Needs Ludwig's approval: CI
   security check.]
6. [live] **Release upload:** for one real accepted version, the Release exists with the two assets;
   `sha256sum` of the downloaded tarball equals the entry's `source_sha256`; the downloaded
   `.minisig` equals the entry's `signature` byte for byte; `minisign -V` with the published public key
   (`6E5B30596A7A8CC4`) succeeds on a machine that has none of our code. Re-running the workflow
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
9. [live] **Built-in-token behaviour (umbrella F5):** with the identity chosen under Q3, the
   write-back PR receives its required checks, merges under branch protection **without bypass or
   a lifted rule**, and the merge's `push` event runs the workflows that should run. If Q3=A was
   chosen and F5 is true, this criterion documents the failure and the task stops (§3.4) rather
   than papering over it.
10. [live] **Dry run:** `workflow_dispatch` with `dry_run=true` against the M4 repository's commit
    (needs task 010's M4 repo to exist, **not** a registry entry) builds, signs and uploads to
    *workflow artifacts only*: no release, no branch, no PR. The log contains none of the key's
    characters beyond the public key id (check: `grep -c` the 16-hex `key_id` ≥ 1, the key text 0).
    This is the only live signing run before task 010's real publish.
11. [live] **Failure path:** a dry run against a deliberately bad commit (a public throwaway repo
    containing a `.png` with DBC magic bytes) fails with exit 1 semantics: the log is attached where
    specified in design 7, and no release or PR is created.
12. [script] **Idempotence of the no-op:** run the planning step against `main` after a write-back
    merge: zero pending versions, no build, success.
13. `docs/tasks/008b-verify.sh` exists, is executable, mutation-tested (criteria 1-2, 4-5), run in a
    fresh clone, output pasted in the log; the log separates [script] from [live] results.
14. **Docs move with code:** `docs/pipeline/build-pipeline.md` gains the workflow, the failure
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
- `tools/pipeline/plan_pending.py` (new — lists pending versions; the unit-testable half of the workflow), `tools/pipeline/release.sh` (new — thin, `set -euo pipefail`, no logging of env)
- `tools/registry/ownership.py` (narrow carve-out only; the file is task 007's — sequence after it merges)
- `tests/pipeline/` (additions), `docs/pipeline/build-pipeline.md` (additions)
- `docs/tasks/008b-pipeline-workflow.md` (log), `docs/tasks/008b-verify.sh` (new, executable)
No edits to `contracts/`, `reserved-namespaces.json`, or the site repo.

## Forbidden here (beyond MANAGER.md §3.7)
- **Printing, copying, or testing for the secret** in any form; no `gh secret` commands of any
  kind. Whether `MINISIGN_SECRET_KEY` exists is not checked by running anything — it is a question
  for Ludwig (below). A denied credential access is information and is not retried (CLAUDE.md rule 11).
- `pull_request_target`, or any trigger a fork can fire with the key reachable.
- Bypassing branch protection, `--force`, editing protection settings, or an "admin merge" to get
  the write-back through. If protection blocks the design, stop and report; Ludwig lifts it loudly or not at all.
- Overwriting, re-tagging, or deleting a *published* release.
- Writing `source_archive` as anything other than the URL `release_url` returns.
- Reading the author's mod from its live repo after the clone step, or building from a branch name.
- Any use of `GITHUB_ACTOR`/`GITHUB_ACTOR_ID` as the author identity (ownership.md).

## Dependencies and sequencing
`Ludwig: Q1-Q4` → contract-amendment task → 007 and 039 merged (this task edits 007's ownership
module and relies on 039's workflow scaffolding for checks) → 008a → **008b** → (Ludwig
manual steps below) → 010.
Parallel-safe with 041 and 056. Shares no file with 055.

## Ludwig's manual steps this task creates (exact instructions are written into the runbook by the task)
- Possibly **M5**: create the GitHub App or token chosen under Q3 and store its secret(s) — a
  credential action: only with his in-session approval.
- Confirm in repository settings, as chosen: Actions → General → "Allow GitHub Actions to create
  and approve pull requests" (needed if Q3=A; **whether this setting exists under that name for an
  organisation repository is unverified here**).
- Confirm `MINISIGN_SECRET_KEY` is present — by looking at the repository secrets page himself.

## Verification artefact (MANAGER.md §2c)
Declared: `docs/tasks/008b-verify.sh` for [script] criteria; the [live] criteria are recorded with
run URLs and are said plainly to be unscripted.

## Deliverables
Workflow + helpers + tests + docs + verify script + this file's log section current.

## Questions  (agent-maintained; see MANAGER.md 8b)
- **For Ludwig:** does `MINISIGN_SECRET_KEY` still exist on `worldofmodcraft/registry`, and is the
  offline backup of the private key done? (The mission log says M3 was completed 2026-09-05; I did
  not and may not check — `gh secret` commands are forbidden.)
- **For Ludwig/manager:** do the branch-protection rules on registry `main` require status checks,
  and which? (Determines whether F5 blocks the write-back PR.)
- **Design hole (contract task):** a version whose build is rejected stays `pending` forever; the
  append-only rule forbids deleting it. Options: A) a `pending → rejected` transition performed by
  the pipeline with a reason (new terminal state, new schema enum value) / B) `pending` versions
  are allowed to be withdrawn by the author's own PR (a new carve-out) / C) rejected submissions
  never reach `main`: the PR-time checks run the 008a build in a no-secret mode and block the merge.
  ★C is the closest to ADR-0058's "rejections return the full log in the PR" and to mission D2
  step 6, and is the only one that adds no new state — but it moves the full build onto
  untrusted PR content (safe only because 008a never executes mod code). | assumed: none; the
  failure design above (7) is provisional until this is answered.
- umbrella Q1-Q4 apply.

---
# Task 008b log  (append-only, updated continuously by the executing agent)
- 2026-10-14 spec written under task 054; nothing started.
