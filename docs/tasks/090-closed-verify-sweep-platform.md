# Task 090: platform closed scripts — move the remaining own-change check to its pinned FINAL and close the pin-override and nested-control gaps

- **Mission:** SITE-V1 (verification integrity) — **Status:** spec-approved 2026-10-26 (manager, after independent spec review; fixes mechanical); dispatch after the open PRs merge
- **Agent / model:** qa-engineer / sonnet (§3.5; model per its agent frontmatter)
- **Budget:** small (one agent-session)
- **Branch / worktree:** `task/090-closed-verify-sweep-platform` / `~/wt/task-090`, cut from platform `origin/main` after the open PRs below merge
- **Repo:** platform. **Graph:** verification tooling only.

## Objective
The one remaining platform own-change finding of the 088 inventory is resolved according to Ludwig's decision (Q1), the pins of `072-verify.sh` and `080-verify.sh` can no longer be overridden from the environment, and `085-verify.sh`'s nested control asserts that its `Last reviewed` edit actually applied. Source: inventory `docs/research/closed-verify-sweep-088.md` (platform read at `3ca6fbf`); Ludwig's decision 2026-10-26 ("A star on the above one"); 085 delta review LOW.

## Context to load (exhaustive)
- ADRs: none new. Doctrine: MANAGER.md §2b, §2c rules 1-5; REVIEW-CHECKLIST.md item 12; SPEC-CHECKLIST.md 5b; the Rule 0 suspension text in CLAUDE.md and MANAGER.md.
- Files: `docs/tasks/048-verify.sh` (c4, c3, c6), `079-verify.sh:28-29`, `072-verify.sh:8-11`, `080-verify.sh:20-23`, `085-verify.sh` (about lines 52-54 and 117-119); tasks 048, 078, 079, 085 files.
- Survey docs: `docs/research/closed-verify-sweep-088.md`.

## Dependencies
Starts only after platform #81 (039b) and #84 (092) are merged into `main`, so the scripts are edited on their final base and the whole closed suite is re-run once on it. The registry PRs (087 #24, 082 #20, 039b #23, 092 #25) do not touch these files; task 089 is independent.

## Findings -> task assignment
All 1 platform finding and the platform side findings are listed; each is assigned or excluded.
- P1 `068-verify.sh` runbook markers: **excluded**, fixed by platform #80 (085).
- P2 `048-verify.sh:90-98` (c4): the `SUSPENDED by Ludwig 2026-10-14` marker in CLAUDE.md/MANAGER.md at HEAD, also anchored by `079-verify.sh:28-29`; 048 merge `c323460b9898e44a7c487c310f0b3707f4bce2e8`, range `8a5f32dfcebfe6eda328066b43eb60204ef3a5ac..047bc41cac555cc125f2650d1b5cc3159f2f17a9`. **Assigned here, decided (Q1, manager ★ session 12): 048 c4 is pinned; `079-verify.sh:28-29` stays live.** It reddens the day Ludwig revokes the suspension. 078 classed c2-c7 as live; c4 measures what 048 wrote, so it moves to the pin.
- N1 (side) `072-verify.sh:8-9` and `080-verify.sh:20-21` allow env overrides of their pins (`T072_BASE`, `T072_FINAL`, `T072_REGISTRY`, `T080_BASE`, `T080_FINAL`): **assigned here.** 078/085 forbid overrides. `T072_REGISTRY` points at a local registry path; see Q2.
- N2 (side, 085 delta review LOW) `085-verify.sh` about line 118: the nested control runs `sed` on the runbook and checks only that M4 flipped (line 119); it does not assert that the `Last reviewed` substitution matched: **assigned here.**
- N3 (side) 048 c3 (exactly 10 agents) and c6 (5b caps) are time-bound: a roster or cap change reddens them. 078 classed them live. **Excluded** from the change: they are deliberate guards. They are listed in Q3 so Ludwig can overrule.
- N4 (side) `063-verify.sh` AC3 reads its task file by a fixed path: **excluded.** Ludwig chose to keep task files in place; low risk.
- Live reads that correctly stay on HEAD (platform: 010a, 049, 052, 053, 061, 079 AC1/2 behaviour tests; external-by-design 010a, 056, 080, 072): **excluded**, unchanged.

## Size
Within the soft cap: source files `048-verify.sh`, `079-verify.sh`, `072-verify.sh`, `080-verify.sh`, `085-verify.sh` = 5 (cap 5); changed lines expected well under 300 (guard pin blocks and a few assertions). Reading list under 10 files. `079-verify.sh` is touched by a comment only; no Size justification needed.

## File scope (declared)
`docs/tasks/048-verify.sh` (c4 only), `docs/tasks/079-verify.sh` (lines 28-29 comment only; relabel as live guard), `docs/tasks/072-verify.sh` (pin lines only), `docs/tasks/080-verify.sh` (pin lines only), `docs/tasks/085-verify.sh` (nested-control assertion only), `docs/tasks/090-closed-verify-sweep-platform.md` (log), `docs/tasks/090-verify.sh` (new). Anything else = stop and report.

## Acceptance criteria
All command-based, shipped as `docs/tasks/090-verify.sh`, run in a fresh clone with `PYTHONDONTWRITEBYTECODE=1`, own-change checks on fixed SHAs.
1. P2 (decided, Q1: option A for 048 c4), red first: a synthetic later branch that replaces the `SUSPENDED by Ludwig 2026-10-14` marker with a revocation line makes the old `048-verify.sh` fail and the new one pass, because c4 reads CLAUDE.md and MANAGER.md with `git show 047bc41cac555cc125f2650d1b5cc3159f2f17a9:path` (pin `8a5f32dfcebfe6eda328066b43eb60204ef3a5ac..047bc41cac555cc125f2650d1b5cc3159f2f17a9`, re-derived from merge `c323460b9898e44a7c487c310f0b3707f4bce2e8` and recorded). A bad pin turns c4 red, never skip. `--mutate` widens c4 to HEAD and it reddens on the merge with that branch.
2. `079-verify.sh:28-29` stays live (Q1 manager ★: option B). Its comment is relabelled as a live guard with a one-line reason (comment only), and a temp-clone test shows it still reddens when the `SUSPENDED by Ludwig 2026-10-14` marker is removed from HEAD's CLAUDE.md/MANAGER.md (the 079 check goes red, named in the log).
3. N1: `grep -nE 'T072_(BASE|FINAL)|T080_' docs/tasks/072-verify.sh docs/tasks/080-verify.sh` returns 0 lines (with a positive control that the same grep matches in a temp copy of the old scripts); setting the old variable names in the environment has no effect on the pins (shown by running 072 with `T072_BASE=deadbee` and 080 with `T080_BASE=deadbee`, exit status unchanged from the unset run). The unreachable-pin test applies to both 072 and 080: replacing a script's own pin with `deadbee` turns it red, never skip (080's pin lines carry env defaults too and are in scope). `T072_REGISTRY` is kept (Q2 manager ★: a live read of the registry's `origin/main`, not a pin); `072-verify.sh` gains an assertion that `REG` exists, is a git repository and that its `origin/main` resolves, else FAIL (shown by pointing `T072_REGISTRY` at a non-repo directory in a temp run: red, not skipped).
4. N2: red first: a temp copy of `085-verify.sh` whose nested-control `sed` is broken so the `Last reviewed` substitution cannot match is shown passing the old script (the gap) and failing the new one at a new named check, `nested: Last reviewed substitution applied` (placed right after the existing M4 check near line 119; the agent keeps the script's label style); the unbroken script passes. The new check asserts that the old string `Last reviewed: 2026-10-15 (task 068)` is absent from the nested runbook and the new `Last reviewed: 2026-11-01 (task 999)` string is present after the sed.
5. The item-12 control: every script touched here exits 0 on HEAD and on a merge of HEAD with a later synthetic branch editing the file each one reads (CLAUDE.md marker, runbook M4 and `Last reviewed`); the unfixed scripts exit non-zero on the same merge (positive control).
6. Every closed platform script, one at a time on a quiet machine (`ps` logged), is green on HEAD and on that merge.
7. Scope: `git diff --name-only BASE..FINAL` for this task is a subset of File scope; unchanged lines of 048, 072, 080, 085 outside the named checks are byte-identical (diff hunks listed).

## Forbidden here
Weakening any check: no looser pattern, no dropped assertion, no skip on an unreachable pin. Pinning a live property: if Q1 resolves to live, c4 must stay on HEAD. Changing the Rule 0 text itself (the suspension is Ludwig's alone to lift) or any file other than those in File scope. Adding or keeping environment-variable pin overrides. Reading, printing or testing credentials (CLAUDE.md rule 11); the checks read marker text only. Starting before the dependency PRs are merged and the spec is approved.

## Deliverables
Edited scripts as in File scope; `090-verify.sh` with the red fixtures, mutation and controls; this file's log with the derived pins, the own-change/live classification of c4 with one line why, the red/green/mutation output pasted; docs touched only if a script comment states the old behaviour.

## Questions  (agent-maintained; see MANAGER.md 8b)
- Q1: P2 - is 048 c4 (and `079-verify.sh:28-29`) an own-change check or a live guard of the suspension marker? | options: A) own-change, pin to `047bc41cac555cc125f2650d1b5cc3159f2f17a9`; B) live, keep on HEAD and relabel; C) keep it live and add a pinned copy that records the 048-time state | assumed: A for 048 c4 (it measures what 048 wrote and a revocation must not redden a closed task), B for 079 (it exists to guard the live state) | built on assumption: 048 c4 pinned; 079 unchanged. Needs Ludwig/manager confirmation before the build, since 078 classed c2-c7 as live.
- A (manager ★, session 12): A for 048 c4 (pinned), B for `079-verify.sh:28-29` (stays live).
- Q2: N1 - `T072_REGISTRY` defaults to `/home/ludwig/registry`, a working copy outside this repo | options: A) remove all `T072_*` overrides and keep the default path; B) read the registry files at a pinned registry SHA from a clone the script makes; C) leave `T072_REGISTRY` only (it is a location, not a pin) | assumed: C (smallest change; the BASE/FINAL pins lose their overrides) | built on assumption: `072-verify.sh` pin lines only
- A (manager ★, session 12): C. Keep `T072_REGISTRY` (a live read of the registry's `origin/main`); remove the BASE/FINAL overrides; add the `REG` existence/git-repo/`origin/main` assertion (AC3).
- Q3: N3 - 048 c3 (exactly 10 agents) and c6 (5b caps) are time-bound | options: A) leave as deliberate live guards (078); B) relax to a minimum; C) pin | assumed: A (B and C weaken or change what is guarded) | built on assumption: none
- Q4: dependency on 085 - `085-verify.sh` is on `origin/main` (read at session 12); the agent confirms the nested-control lines (about 117-119) are unchanged before editing | options: none | assumed: unchanged | built on assumption: line numbers in this file

---
# Task 090 log  (append-only, updated continuously by the executing agent)
- 2026-10-26 doc-writer (session 12): drafted from the 088 inventory and the 085 delta review. Not yet reviewed. No pins re-derived; pins quoted are the inventory's.
- 2026-10-26 manager (session 12): independent spec review PASS-WITH-AMENDMENTS folded in (mechanical). Mapping: T072_REGISTRY kept, AC3 grep narrowed, REG assertion added (review 1); Q1 -> 048 c4 pinned, 079 live, AC1/AC2 rewritten with 079 red-on-marker-removal (2); N2 check named with old/new Last reviewed strings (3); deadbee test applies to 080 too (4); full SHAs (5). Status set to spec-approved.
