# Task 010b: first-publish runbook and the M4 text (split from task 010)

- **Mission:** SITE-V1, deliverable **D4** (runbook half) — **Status:** spec-approved (manager, 2026-11-04, solo gate: documentation, no code, no security surface)
- **Repo:** platform. **Agent / model:** doc-writer (model per frontmatter). **Budget:** small (≤ 1 agent-session)
- **Branch / worktree:** `task/010b-first-publish-runbook` / `~/wt/task-010b`, cut from platform `origin/main`
- **Depends on:** 010a (merged; contents on main), 008b-2 (registry main `428df02`). 008b-3a/3b are not built; see criterion 4.
- **Base text:** `docs/tasks/010-test-mod.md`, sections "Runbook" and "Evidence rule", and its criteria 5, 6, 7, 9 apply **as amended here**; where they conflict, this file wins. Criteria 8 (visual review) and 10 (Ludwig's run) stay with 010.
- **Graph:** node N1 mod-source; no new edge.

## Objective
`docs/runbooks/first-publish.md` exists and Ludwig can follow it without improvising: every numbered step states the exact command or
click (*Do*), what he should see (*You should see*) and what it proves (*This proves*). M4 in `docs/runbooks/site-v1-manual-steps.md`
points at it with the decided repository name. Part 1 (M4: create `mbmludric/wom-test-hello-world`, fill placeholders, commit, tag `v1.0.0`,
push) is usable today; the later parts are written from what is built, with anything not observed marked.

## Decisions (★ under ADR-0125, logged in the mission log 2026-11-04)
- D1. Repository: `mbmludric/wom-test-hello-world`, public (010a C1). M4's old `mbmludric/hello-world` text is replaced.
- D2. The runbook ships in two stages: this task (Part 1 ready, later parts marked), then **010c** re-rehearses and removes markers after 008b-3b. Options were: A★ ship now so M4 and the dry run can proceed; B wait for 008b-3b, which blocks the 008b-2 dry run on the whole remaining chain.
- D3. Ludwig pushes with his own existing login. The runbook names the identity check by a command that shows only the account name (`gh auth status` without `--show-token`) and gives the switch command `gh auth switch --user mbmludric`. Every section that switches **ends with `gh auth switch --user womcraft`** and a check that `womcraft` is active again, because all project `gh` work on this machine runs as `womcraft` (OPERATIONS.md); the verify script asserts each switch to `mbmludric` is followed by a switch back. Agents never run a switch.

## Context (≤ 10)
This file; `docs/tasks/010-test-mod.md`; `docs/tasks/010a-test-mod-contents.md` (and its log, C24); `docs/test-mod/hello-world/` and
`docs/test-mod/registry-pr/`; `tools/test-mod/fill_placeholders.py`; `docs/runbooks/site-v1-manual-steps.md` (M1.3 for step style; M4, M6);
`docs/manager/OPERATIONS.md` (Pages lag; gh account section); ADR-0119; ADR-0059 §2-3; registry files read through a fresh clone or
`gh api` of public paths: `CONTRIBUTING.md`, `tools/registry/ci_gate.py`, `tools/registry/ownership_cli.py` (exact messages).

## Acceptance criteria
[script] = `docs/tasks/010b-verify.sh`; [human] = recorded, not scripted.
1. [script] **Shape:** every numbered step in `first-publish.md` has the three labelled parts; each fenced command block is one copy-pasteable unit with no unlabelled `<placeholder>`. Mutation: delete one *This proves* line, add a stray `<...>`; each reddens.
2. [script] **Commands exist:** every `fill_placeholders.py` invocation in the runbook uses the C24 form, and running those exact command lines on a copy of the staging tree with a sample account and commit leaves zero placeholder tokens (asserted non-zero before).
3. [script] **No credential:** no step asks to paste a token, key or secret anywhere; `gh auth token` and `--show-token` are absent. Positive control: a fixture containing them is caught.
4. [script+human] **Evidence rule:** every *You should see* line is copied from an observation (Part 1 is rehearsed in a `mktemp -d` local bare repository, no remote) or prefixed `[UNVERIFIED — expected, not observed]`; steps that cannot run without publishing are `[NOT REHEARSED]` with the reason. The script asserts the count of `[UNVERIFIED` markers equals the count listed in this task's log. Write-back steps carry `[NOT REHEARSED]` and name 008b-3b.
5. [script] **M4 text:** `site-v1-manual-steps.md` M4 names `wom-test-hello-world`, points at `first-publish.md` and no longer contains `mbmludric/hello-world` except as the historical 404 note if kept; status key stays ☐. No other M section changes.
6. [script] `docs/tasks/010b-verify.sh` exists, is executable, mutation-tested (`--mutate`), passes in a fresh clone; own-change checks read fixed SHAs, live guards read HEAD. Every other platform `docs/tasks/*-verify.sh` that reads the changed files exits 0 (the agent lists which it ran).

## File scope
`docs/runbooks/first-publish.md` (new), `docs/runbooks/site-v1-manual-steps.md` (M4 section only), `docs/tasks/010b-first-publish-runbook.md` (log), `docs/tasks/010b-verify.sh`, `docs/tasks/010b-fixtures/**`.

## Forbidden
Creating any remote, pushing, tagging on a remote, opening a PR, publishing anything; `gh auth switch`, `gh auth token` or reading any credential (rule 11; identity questions are answered from docs or unauthenticated requests only); fabricated CI messages (copy them from the tools); editing the mod tree or `fill_placeholders.py` (stop and report if they are wrong); marking M4 done.

---
# Task 010b log
- 2026-11-04 manager (session 15): spec written, gate passed solo. Baseline for `check-log-entry.sh` recorded at dispatch.
- 2026-11-04 doc-writer (010b): **done** -- `docs/runbooks/first-publish.md` (new; Part 1 = M4 steps 1.1-1.16, Parts 2-5 written from registry `main` `428df02`), M4 section of `docs/runbooks/site-v1-manual-steps.md` rewritten (name `mbmludric/wom-test-hello-world`, public, points at Part 1, status key stays ☐, no other section touched), `docs/tasks/010b-verify.sh` plus `docs/tasks/010b-fixtures/**` (checker `check_runbook.py`, four observation transcripts, a credential positive-control file).
  **Rehearsal (criterion 4):** Part 1 steps 1.1-1.10 and 1.13-1.15 were run verbatim as commands in a `mktemp -d` area with `HOME` pointed at it: `~/wom` was a clone of this worktree (so `origin/main` = `24d9141`), and a git `url.insteadOf` rule mapped `https://github.com/mbmludric/` to a local bare repository, so the push commands ran unchanged against a folder. Part 2 steps 2.3 and 2.4 ran against a clone of registry `main` `428df02` with a local bare "fork". Transcripts: `docs/tasks/010b-fixtures/rehearsal-part{1,2,4,5}-observed.txt`; the verify script asserts that every line of the observed "You should see" blocks appears in them (hashes, short hashes and the init path normalised). Steps 1.10 and 5.1 are real unauthenticated requests to api.github.com (404 for the new repository name; 302 for the `womcraft` membership question).
  **Observed vs not observed per step:** observed = 1.1 (empty output), 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 1.10, 1.15, 2.3, 4.2 (the edit on disk), 5.1. Observed against a local bare repository only, GitHub side not observed = 1.13, 1.14, 2.4. Not observed at all (talk to GitHub, change `gh` login state, or need unbuilt parts) = 1.11, 1.12, 1.16, 2.1, 2.2, 2.5, 2.6, 2.7, 3.1-3.3 (write-back is 008b-3b), 4.1, 4.3, 4.4, 5.2.
  **Not rehearsed on principle (rule 11):** `gh auth status` and `gh auth switch` were not run by the agent; no credential file was read; no remote was created; nothing was pushed to GitHub.
  **Remaining:** (1) Ludwig runs Part 1 (M4) and reports the 40-hex commit; (2) task 010c re-rehearses Parts 2-5 after 008b-3b and removes the markers; (3) 010 criterion 10 (his end-to-end run) stays open; (4) the header stamp of `site-v1-manual-steps.md` was left alone (file scope is the M4 section only), the M4 section carries its own review date.
  **Findings:** (a) the machine's global git config has a name but no email, so a plain commit in the new folder would fail or guess; Part 1 therefore sets a folder-local identity using GitHub's noreply address form `37807560+mbmludric@users.noreply.github.com` (id from OPERATIONS.md; the form is GitHub's convention, not verified by a request). (b) The global git config already routes `https://github.com` through `gh auth git-credential`, so a push needs no password; step 1.13 says to stop if git asks for one. (c) The registry has no `mods/` directory yet, so step 2.3 needs `mkdir -p` (observed: plain `mkdir` failed in the first rehearsal). (d) INCIDENT: during the first Part 2 rehearsal the clone of `/home/ludwig/registry` had that checkout as its `origin`, and a push created a local branch `add-test-hello-world` (at `428df02`, equal to `main`) inside `/home/ludwig/registry`. Nothing reached GitHub. Deleting it with the forced-delete form was refused by the git-guard hook; I did not retry or work around it. The manager should delete that branch (the non-forced delete is enough because it equals `main`). The rehearsal was redone against a bare clone and the transcripts above come from that second run.
  UNVERIFIED-LIST 010b (one line per marker in the runbook; the verify script compares this list with the file, step by step):
  - U1 step 1.11
  - U2 step 1.12
  - U3 step 1.13
  - U4 step 1.14
  - U5 step 1.16
  - U6 step 2.1
  - U7 step 2.2
  - U8 step 2.4
  - U9 step 2.5
  - U10 step 2.6
  - U11 step 2.7
  - U12 step 3.1
  - U13 step 3.2
  - U14 step 3.3
  - U15 step 4.1
  - U16 step 4.3
  - U17 step 4.4
  - U18 step 5.2
- 2026-11-04 doc-writer (010b, closing): content commit `fd4473d` is PIN_FINAL in `docs/tasks/010b-verify.sh`; the later commits touch only the verify script and this log (both in scope). Ludwig chose to resume after the incident above; the deletion of the stray local branch `add-test-hello-world` in `/home/ludwig/registry` is his decision, not mine, and I did not touch that checkout again. Results in a fresh clone of `https://github.com/worldofmodcraft/platform`, branch `task/010b-first-publish-runbook`: `docs/tasks/010b-verify.sh` exit 0 ("010b-verify: ALL OK"); `docs/tasks/010b-verify.sh --mutate` exit 0 ("ALL OK (26 mutations, each red with a reason)"). Other verify scripts that read the changed files, run in the worktree: 068, 085, 096, 102 exit 0. 090 exit 2 in the worktree ("working tree is dirty; run from a clean clone"); its re-run in the fresh clone exceeded two minutes and was stopped, so 090 is NOT demonstrated green: the manager should run it on the pushed branch. [script] results: criteria 1-6 as above; [human]: none claimed.
- 2026-11-04 doc-writer (010b, fix round after review PASS-WITH-FINDINGS). **Corrections to the entries above (they stay as written):** (a) the Rehearsal paragraph says the steps were "run verbatim". That is wrong in detail. The transcripts show variants: step 1.3 was run with an extra `; ls -l ... | awk` listing that is not in the runbook; several runbook blocks were run as separate commands or combined with `&&`; step 4.2's heredoc was run as `<<"PY"` while the runbook says `<<'PY'`; the fill commands were run through `bash -c` with `HOME` redirected. "Observed" in this runbook therefore means "the same commands, or close variants, were run in the scratch area", not byte-identical replay. (b) The `observed` check of the verify script proves only that each such line appears in one of the transcript files after normalising hashes and the init path. It does not prove that the line was observed in the order or the context the runbook gives; the transcripts are the agent's own saved output. (c) The manager ran `090-verify.sh` on `034db5e`: exit 0, 86 ok, 0 FAIL (this closes the gap named in the closing entry).
  **Findings fixed (review items):** 1. every step inside a section switched to `mbmludric` (1.11-1.16, 2.1-2.5, 4.2-4.4) now carries a stop line that names `gh auth switch --user womcraft` before "tell the manager"; the general rules and the "screen differs" line say the same. Steps outside a switched section (1.2, 1.10, 2.6 and others) are unchanged on purpose: the account is still `womcraft` there. Step 4.2 is now a separate switch step (switch, `gh auth status`, You should see, stop line, note that the section ends with step 4.4); the old 4.2 to 4.4 became 4.3 to 4.5. 2. step 5.1's "This proves" now describes the real mechanism: the registry workflow step "Ask the organisation whether the author is a member" asks `/orgs/ORG/members/LOGIN` with a GitHub App token and passes the HTTP status to the gate (read from a fresh GitHub clone of the registry, `registry-ci.yml`). 3. the "This proves" of 4.3/4.4 says that for `test:` the owner is the organisation and the author passes as an organisation member. 4. this entry. The reviewer also named lines 71 and 261 (steps 1.2 and 1.10); those steps run before the first switch, so they were left alone.
  **Red then green (§2c rule 5):** the checker rule `stop` was added to `check_runbook.py` first and run on the unfixed runbook: exit 1 with ten lines, "FAIL step 1.11: inside a switched section but no stop line gives the switch-back command", the same for 1.12, 1.14, 1.15, 2.1, 2.2, 2.3, 2.4 and 4.2, and "FAIL step 1.13: a stop line inside a switched section lacks `gh auth switch --user womcraft`: If git asks for a username or a password, press Ctrl+C. ...". After the fix the same command exits 0. Two `--mutate` items were added (a stop line without the command; a switched step without a stop line). The checker now reads the LAST `UNVERIFIED-LIST 010b` in the log, because the log is append-only; the list below supersedes the earlier one. The observed-step list moved 4.2 to 4.3 with the renumbering.
  UNVERIFIED-LIST 010b (supersedes the earlier list; 19 markers, runbook at the new PIN_FINAL):
  - U1 step 1.11
  - U2 step 1.12
  - U3 step 1.13
  - U4 step 1.14
  - U5 step 1.16
  - U6 step 2.1
  - U7 step 2.2
  - U8 step 2.4
  - U9 step 2.5
  - U10 step 2.6
  - U11 step 2.7
  - U12 step 3.1
  - U13 step 3.2
  - U14 step 3.3
  - U15 step 4.1
  - U16 step 4.2
  - U17 step 4.4
  - U18 step 4.5
  - U19 step 5.2
- 2026-11-04 doc-writer (010b, fix round result): PIN_FINAL is now `f78885565dfeb0e2d2a201762c7fcb68dc81ca25` (the content commit of this round; the commits after it touch only the verify script and this log). Fresh clone of `https://github.com/worldofmodcraft/platform`, branch `task/010b-first-publish-runbook` at `c921855`: `docs/tasks/010b-verify.sh` exit 0 ("010b-verify: ALL OK"); `docs/tasks/010b-verify.sh --mutate` exit 0 ("ALL OK (28 mutations, each red with a reason)"). [script] criteria 1-6; [human] none claimed.
