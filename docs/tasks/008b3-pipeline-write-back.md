# Task 008b-3: Pipeline write-back — release, source_archive check, T1/T3 PRs, ownership carve-out

- **Mission:** SITE-V1, deliverable **D2** (umbrella `docs/tasks/008b-pipeline-workflow.md`, which keeps the decisions, design and history; design numbers below refer to it) — **Status:** draft — split from 008b at the spec gate 2026-10-26; independent spec review pending
- **Agent / model:** implementer / sonnet
- **Budget:** large
- **Branch / worktree:** `task/008b3-pipeline-write-back` / `~/wt/registry-task-008b3` — **registry** repo
- **Sequence:** 008c -> 008b-1 -> 008b-2 -> 008b-3, and tasks 082 (registry PR #20, blocked on 087) and 092 (registry PR #25) merged first. Follows 008b-2 (it adds the write-back job to the same workflow file). Live criteria need Ludwig's M5, M7, M9, M11.

## Objective
The workflow of 008b-2 gains a **write-back job** (under `environment: write-back`, holding only the App key) that, for each built version, publishes the Release in `worldofmodcraft/archive`, checks the project-owned `source_archive` URL through the front, and then opens and merges, one at a time, a same-repository pull request whose diff is exactly one T1 (`pending -> published`) transition — and, for a rejected version (008a exit 1) or a `+` version (092 Q10), exactly one T3 (`pending -> rejected`) transition — which passes the registry's own `gate` and merges under branch protection without bypass. `tools/pipeline/write_back_job.py` holds the sequencing loop, the pre-T1 check and the archive log rule behind injectable clock, GitHub and HTTP clients so they are tested offline; `tools/pipeline/release.sh` is the thin release step; `tools/registry/ownership.py` gains the narrow carve-out for the App's bot id. A failed build's full log is posted where the author will see it. The App key is reachable only in runs on `main`, bound by the `write-back` environment.

## Context to load (exhaustive; 11 items)
- ADR-0121 (the write-back PR and rejections; authority for design 4 and 7).
- Contracts: `append-only.rules.md` and `entry.schema.json` as amended by task 057 (T1, T3); `ownership.md` (R11; the identity rule); `artifact-naming.md` as amended by task 092 (archived-source URL, producer obligations); `pipeline-trigger.md` (task 082: PT6-PT11).
- 008c `tools/pipeline/write_back.py` (`apply_write_back`, `source_archive_url`, `write_back_values`); task 007's `tools/registry/ownership.py` (this task edits it).
- The umbrella `008b-pipeline-workflow.md` (designs 3, 4, 5, 7, 8 and the manual steps M5-M7); `docs/runbooks/site-v1-manual-steps.md` (M9, M11, M12); `docs/manager/OPERATIONS.md` (one fact: branch protection and the manager's permissions).

## Size (5b)
Two numbers are over the soft cap; one is within it.
- Source files: 4 (`pipeline.yml` write-back job, `write_back_job.py`, `release.sh`, `ownership.py`) — within the cap of 5.
- Changed lines: about 400 (cap 300; estimate: workflow 80, `write_back_job.py` 200, `release.sh` 60, `ownership.py` 60; nothing built). Over by about 100.
- Reading list: 11 (cap 10). Over by one; `OPERATIONS.md` is read for a single fact.
- **Justification.** The loop that opens one PR at a time and the ownership carve-out that lets the App's PRs merge are one safety argument: the carve-out is only safe while the loop opens exactly one T1 or T3 PR per version, and criteria 4, 5 and 19 test them together against the same fixtures. Splitting them yields a part whose PRs cannot merge and a part that merges nothing. Nothing else is separable: the release, the pre-T1 check and the archive log all run in the loop's job. Live criteria (6, 9, 23) need Ludwig and dominate calendar time.

## Design (taken from the umbrella; decisions are recorded there)
Designs 4 (write-back sequencing, C22/PT11), 5 (release, pre-T1 check, append-only log), 7 (failure: the exit-1 T3 path, the `+` T3, PT5 for this job) and 8 (write-back job and `environment: write-back`), as written in the umbrella. Decisions carried: Q-D (the organisation-owned GitHub App is the identity; Ludwig 2026-10-14); Q-E (releases in `worldofmodcraft/archive`; Ludwig 2026-10-14); Q-G (the project-owned `source_archive` URL); Q-J / ADR-0121 (the T3 failure path; Ludwig 2026-10-15); build logs in `worldofmodcraft/archive` at `logs/<namespace>.<name>/<version>.log` (Ludwig 2026-10-15, "Kör på A"); C13 (the run holds the group until its PRs reach a terminal state); C14 (ref condition, write-back job); C20 extended (the `write-back` environment; M11); C22 (one PR at a time, App merges once `gate` is green, 30-minute deadline); 092 Q5 and Q9 (the producer checks hop 1 exactly, https on every hop, sha256 equals `source_sha256`; mismatch is exit 2); 092 Q10 (a `+` version gets a T3); C23 (`gate` comes from 039b, required after M9).
- **Q-K decided** (manager, option A starred, 2026-10-26): the loop, pre-T1 check and log rule live in the new `tools/pipeline/write_back_job.py`.
- **Q-L decided** (manager, option A starred, 2026-10-26, consistent with the 2026-10-15 log-location decision): the `+` T3's `build_log_url` is the permanent `https://` URL of a one-line log file `logs/<namespace>.<name>/<version>.log` in `worldofmodcraft/archive` containing the refusal text, committed before the T3 PR opens; the PT8 append-only rule applies to it.
- **Q-N decided** (manager, option A starred, 2026-10-26): the 30-minute per-PR deadline is enforced in `write_back_job.py` (criterion 19); the job carries a fixed `timeout-minutes` at the documented limit (criterion 20); the run fails at the limit and the remaining versions wait for the next push.
- **Identity:** one installation token per run from the App id (repository variable `PIPELINE_APP_ID`) and the private key (`PIPELINE_APP_PRIVATE_KEY`, from the `write-back` environment once M11 is done); used in exactly one step, never echoed. If the App path fails the task stops; it never falls back to `GITHUB_TOKEN`.

## File scope (declared; anything else = stop and report)
In the **registry** repo: `.github/workflows/pipeline.yml` (**only the write-back job; the rest of the file is 008b-2's and must be unchanged**), `tools/pipeline/write_back_job.py` (new), `tools/pipeline/release.sh` (new — thin, `set -euo pipefail`, no logging of env), `tools/registry/ownership.py` (narrow carve-out only; the file is task 007's — sequence after it merges), their tests in `tests/pipeline/` and `tests/registry/`; `docs/pipeline/build-pipeline.md` (additions: the write-back job, failure modes, manual recovery for a half-finished release and for a published-but-unfetchable `source_archive`, a "what Ludwig must do" section); `docs/tasks/008b3-pipeline-write-back.md` (log); `docs/tasks/008b3-verify.sh` (new, executable). No edits to `contracts/`, to 008a's modules, to `tools/pipeline/plan_pending.py`, or the site repo.

## Acceptance criteria
Criterion numbers are the umbrella's (`008b-pipeline-workflow.md`), kept so the mapping table there can be checked; a part's list therefore has gaps. [script] = checked by this part's verify script; [live] = a real run, recorded with run URLs, **not** script-verified.

2. [script] **The secrets are referenced exactly once each**: `secrets.MINISIGN_SECRET_KEY` in the signing step's `env:`, `secrets.PIPELINE_APP_PRIVATE_KEY` in the token-minting step; the verify
   script counts occurrences of `secrets.MINISIGN_SECRET_KEY` across `.github/` and asserts the
   count of each is 1 and that no `run:` block contains `echo`, `printf` or `cat` of either variable name,
   and no `set -x`/`-o xtrace` appears in the workflow. Mutation: add each forbidden pattern to a
   copy of the workflow and show the check redden.
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
9. [live] **App-token behaviour (umbrella F5):** with the App identity (Q-D, M5 done), the
   write-back PR receives its required checks (`gate`, task 039), merges under branch protection **without bypass or
   a lifted rule**, and the merge's `push` event runs the workflows that should run. If the App
   token's events do *not* trigger the workflows, this criterion documents the failure and the task stops (§3.4) rather
   than papering over it.
13. [script] **Verification script.** `docs/tasks/008b3-verify.sh` exists, is executable, covers criteria 2, 4, 5, 14, 19, 20, 21, 22 and 24, is mutation-tested (criteria 2, 4, 5, 14, 19, 20, 21, 22 and 24 with the mutations they name; each mutation shown red then restored byte-identically), is run in a fresh clone, and its output is pasted in the log; the log separates [script] from [live] results. Every check fails on zero matches.
14. [script] **Only the write-back job holds the App key; its environment (umbrella criterion 14, clause (e) and the write-back half of (f)).** The verify script re-runs 008b-2's criterion 14 script unchanged on the combined workflow, and additionally parses `.github/workflows/pipeline.yml` and asserts: (e) the write-back job is the only job containing `secrets.PIPELINE_APP_PRIVATE_KEY`; (f) the write-back job declares `environment: write-back` and carries the `github.ref == 'refs/heads/main'` condition; the dry-run job and the build job still reference neither. The check **fails on zero matches** (it finds the write-back job by its token-minting step, never vacuously). **Mutations**, each shown red then restored byte-identically: add `${{ secrets.PIPELINE_APP_PRIVATE_KEY }}` to the signing job; drop `environment: write-back` from the write-back job; add `environment: write-back` to the dry-run job. Positive control: the unmodified workflow passes. No command prints, tests for, or lists the secret.
19. [script] **The write-back loop (C22; 082 PT11), run against a fake clock and a fake GitHub API** (`write_back_job.py` takes both as injected objects; no network): (a) green path: two pending versions, `gate` goes green, each PR is merged by the App and the second branch is cut from the head fetched **after** the first merge (the test asserts the second PR's base sha equals the fake `main` head after merge 1); (b) `gate` red: the run fails, the group is released, the second version is not started; (c) a PR closed unmerged: same; (d) deadline: with the fake clock the PR is still waited on at 29:59 and the run fails at 30:00, naming the PR; (e) one at a time: the fake API records that at most one pipeline PR is open at any moment; (f) the merge call is never made before `gate` reports success. **Mutations, each shown red then restored byte-identically:** remove the deadline; merge without waiting for `gate`; branch from the head fetched before the previous merge; open the second PR before the first is terminal. Positive control: the unmodified code passes (a).
20. [script] **`timeout-minutes` sizing (PT11):** the verify script parses the workflow and asserts the write-back job has `timeout-minutes`, or that every PR-wait step has its own; and a unit test of the sizing function asserts N x 30 minutes plus the build allowance for N = 1, 3 and 5. The log states which mechanism was chosen and what limit GitHub documents for it, marked [unverified] until observed (Question Q-N). Mutations: delete the `timeout-minutes`; size it as a constant 30 for N = 5.
21. [script] **A `+` version is refused with a T3, not published (092 Q10):** a fixture entry with a pending `1.0.0+build.5` goes through the planner and the write-back helper with fake build, sign and release functions; the resulting T3 diff (built by `apply_write_back`) is **accepted** by task 007's checkers with the App's bot id, carries `reason` byte-equal to "versions with build metadata (+) are not yet published — pending proof that GitHub resolves them (task 010)" (if 008c's length cap truncates it, stop and report), and the fake build, sign and release functions record **zero calls** (no release, no signing, no clone). Control: `1.0.0-rc.1` in the same fixture does reach the fake build. Mutations: remove the `+` check (the build function is called, red); change one character of the reason (red).
22. [script] **Pre-T1 `source_archive` check (092 Q5, Q9), against a fake HTTP client:** pass when hop 1 is 301 with the derived `Location` and the final bytes hash to `source_sha256` over https hops; each of these exits 2 naming the URL, opens no T1 and no T3: hop 1 answers 200; hop 1 `Location` differs by one byte; a later hop is `http://`; more than 5 hops; the sha differs. The fake records call order and the test asserts release publish -> hop-1 request -> final fetch -> T1 open. Mutations: skip the sha comparison; accept an `http://` hop; open the T1 before the fetch.
23. [live] **Environments bind the keys to `main` (C20; 082 PT3), after M11:** a `workflow_dispatch` of the workflow from a non-`main` branch (a test branch pushed by the manager's account, deleted afterwards) whose signing and write-back jobs declare `environment: signing` and `environment: write-back` does not get those jobs started or does not receive the environment's secrets: the run shows the deployment to the environment rejected by its branch policy. The test branch's workflow does not reference, echo or test either secret (CLAUDE.md rule 11; no `gh secret` command); the evidence is the run URL and the rejected-deployment message. **Until M11 is done and this criterion is recorded, environment binding is unproven, the trust boundary of both keys is every account with write access, and live criteria 6 and 9 wait for it.**
24. [script] **Append-only log and release (PT8), against a fake archive API:** when `logs/<ns>.<name>/<version>.log` already exists, that version fails naming the path and the file is not written, while another pending version in the same run is still processed and the run ends non-green; the same for a published release with the tag. Mutation: overwrite an existing log.
18. **Docs move with code:** `docs/pipeline/build-pipeline.md` gains the write-back job, the failure modes, the manual recovery for a half-finished release and for a published release whose `source_archive` check failed, and a "what Ludwig must do" section (umbrella criterion 18, second part).

## Explicitly OUT of scope
The planner (008b-1); the plan, build, sign and dry-run jobs and `--no-sign` (008b-2); 008a's tool; E12 (site rebuild dispatch, task 055 — its sender uses the same App and must itself declare `environment: write-back` once M11 is done, which is 055's change); `page.json` screenshot scan (task 040); Software Heritage; binary signing; the site.

## Forbidden here (beyond MANAGER.md §3.7)
- **Printing, copying, or testing for the secret** in any form; no `gh secret` commands. Reading, printing, copying or testing for the App's private key or any installation token beyond the one minting step (CLAUDE.md rule 11); the App's bot user id is read from the **public** API only. A denied credential access is not retried.
- Bypassing branch protection, `--force`, editing protection settings, or an "admin merge". If protection blocks the design, stop and report.
- Overwriting, re-tagging, or deleting a *published* release; overwriting an existing archive log.
- Writing `source_archive` as anything other than the URL 008c's `source_archive_url` returns.
- Falling back to the built-in `GITHUB_TOKEN` for the write-back PR or the site dispatch if the App path fails.
- Cloning, building, signing or releasing a `+` version (092 Q10); opening a T1 PR before the pre-T1 `source_archive` check has passed; skipping its sha or https checks.
- Opening a second write-back PR while one is open, or merging before `gate` is green.
- Any use of `GITHUB_ACTOR`/`GITHUB_ACTOR_ID` as the author identity (ownership.md).

## Dependencies and sequencing
008b-2 merged; 008c merged; task 057, 007 (the ownership module) and 039a/039b merged (039b provides `gate`, required only after Ludwig's M9, possible only after `gate`'s first live run); tasks 082 (registry #20, blocked on 087) and 092 (registry #25) merged. Ludwig's manual steps, carried in the umbrella's section of that name: **M5** (the App), **M6** (join the organisation), **M7** (the archive repository), and **M11** (create the `write-back` environment limited to `main`, move `PIPELINE_APP_PRIVATE_KEY` into it, delete the repo-level copy); M5 and M7 must precede the live criteria, and live criteria 6 and 9 wait for M11 and for criterion 23 being recorded. Then task 010. Graph: nodes N5, N6, N2, N3; edges E7, E8, E15, E16.

## Verification artefact (MANAGER.md §2c)
Declared: `docs/tasks/008b3-verify.sh` for the [script] criteria; the [live] criteria (6, 9, 23) are recorded with run URLs and are said plainly to be unscripted. The T3 PR is shown by criteria 4, 5 and 21 on fixtures; live, it waits for task 010's deliberately bad publish if the manager schedules one, and the log says it is unproven until then.

## Deliverables
Write-back job + `write_back_job.py` + `release.sh` + the carve-out + tests + docs + verify script + this file's log section current.

## Questions  (agent-maintained; see MANAGER.md 8b)
- **Q-K, Q-L, Q-N: decided** (manager, option A starred, 2026-10-26, on Ludwig's overnight instruction "Ta stjärna på alla beslut"); see Design.

---
# Task 008b-3 log  (append-only, updated continuously by the executing agent)
- 2026-10-26 split from 008b at the spec gate (manager decision); nothing started.
