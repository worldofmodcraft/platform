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
