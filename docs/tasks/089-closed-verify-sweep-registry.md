# Task 089: registry closed scripts — move every own-change check from HEAD to its pinned FINAL (the 084/087 shape, one sweep)

- **Mission:** SITE-V1 (verification integrity) — **Status:** draft (manager outline, doc-writer text, session 12); independent spec review pending
- **Agent / model:** qa-engineer / sonnet (§3.5; model per its agent frontmatter)
- **Budget:** large (13 findings, about 10 scripts; see Size — splitting is the default and is proposed)
- **Branch / worktree:** `task/089-closed-verify-sweep-registry` / `~/wt/registry-task-089`, cut from registry `origin/main` after the open PRs below merge. The task file is drafted in the platform repo (session/12) and is copied to the registry branch at cut.
- **Repo:** registry. **Graph:** verification tooling only.

## Objective
After this task no closed registry verify script and no registry test file reads a file at `HEAD`, `origin/main` or the worktree as evidence of **that task's own change**. Each such check reads the file with `git show FINAL:path` (or `git diff BASE..FINAL`), with BASE/FINAL = the script's merged PR range (merge commit M: BASE = `git merge-base M^1 M^2`, FINAL = `M^2`; reuse pins the script already defines). A pin that cannot be resolved is a `FAIL`, never a skip. Live-property checks stay on HEAD. Each script gets a `--mutate` case (or extends its existing one) that widens the fixed check back to HEAD and must redden, and a control that merges a later synthetic branch editing the same file and must stay green (REVIEW-CHECKLIST item 12). Source: inventory `docs/research/closed-verify-sweep-088.md` (read at registry `4268735`); Ludwig's decision 2026-10-26 ("A star on the above one").

## Context to load (exhaustive)
- ADRs: none new. Doctrine: MANAGER.md §2b (size), §2c rules 1-5; REVIEW-CHECKLIST.md item 12; SPEC-CHECKLIST.md 5b.
- Files: the inventory above; registry tasks 084 (`084-repin-075-verify.md`, `084-verify.sh`) and 087 (`087-repin-032-067-readme.md`, `087-verify.sh`) as the reference pattern; the scripts and tests in File scope; `docs/tasks/070-verify.sh` header.
- Survey docs: `docs/research/closed-verify-sweep-088.md`.

## Dependencies
Starts only after these are merged into registry `main`: 087 (#24), 082 (#20), 039b (#23), 092 (#25). Reasons: 087 fixes 032/067/070 AC4.m1 (excluded here); 082 is the later branch that edits `docs/contracts/README.md` (the red-first control for findings 1-6); 039b changes the `*-verify.sh` sweep in 039a (item 6 of Scope notes). Platform PRs #81 and #84 do not touch this task. Task 090 is independent of this one.

## Findings -> task assignment
Numbers are the inventory's. All 13 registry findings are assigned here; none is excluded.

| # | Where | Own change of | Fix |
|---|---|---|---|
| 1 | `007a-verify.sh:117` README "tools/registry" and "task 039" | 007a | README blob at pin `e009ef0..aaf4260` |
| 2 | `007a-verify.sh:118` README lacks "task 007$" / "task 007 +builds" | 007a | same pin |
| 3 | `007b-verify.sh:100` README "ownership" and "task 039" | 007b | `fb76ee5..17555d9` |
| 4 | `007b-verify.sh:101` "ownership checker (task 007b" not "still to come" | 007b | same pin; also make the check non-vacuous (087 log: today the grep matches no line, so the branch passes vacuously) |
| 5 | `008a-verify.sh:74` README mentions build-pipeline.md | 008a | `4d4a204..9ccb3ec` |
| 6 | `057-textchecks.py:179-180` default `--readme`, called from `057-verify.sh:35` | 057 | `057-verify.sh` writes the README blob at the pin (`a50daac..3ab8f43`) with `git show` and passes it via `--readme`; the default path stays for live use |
| 7 | `tests/registry/test_hardening.py:153` README contains `--no-renames` | 007a fix round | read the blob at `aaf4260`, or drop the README half; the CLI-help half at :152 stays live |
| 8 | `065-verify.sh:208-218` (AC3.5) `test_hardening.py` in the HEAD clone | 065 | blob at `e87498b` (range `4356583..e87498b`). Suspected cause of a 065 failure seen by the 039b agent: confirm or refute in the log with the observed output |
| 9 | `075-verify.sh:100-135` (AC4) `contracts/ownership.md` sentences in the HEAD clone | 075 | blob at `7d91a3d` (`79d5377..7d91a3d`). HIGH: 008b's ownership carve-out edits them |
| 10 | `039a-verify.sh:149-150` `HEAD:config/r11-identity.json` must be null | 039a | blob at `ceb0458` (`4356583..ceb0458`). HIGH: reddens when Ludwig configures R11 |
| 11 | `tests/registry/test_ci_gate.py:1018-1021` (AC9ProductionR11Unconfigured) | 039a | blob at FINAL, or move the check into 039a-verify (see Q2) |
| 12 | `039a-verify.sh:111-148` exact per-class test counts of `test_ci_gate.py` in the HEAD clone | 039a | counts taken from the file at `ceb0458`. MEDIUM (inference): first show the counts do change with a later test addition (red fixture); if they do not, record that and leave as live |
| 13 | `tests/registry/test_classify.py:132-134` `reserved-namespaces.json` names == {mc, test} | 007a | blob at `3c94cf2`'s FINAL, or assert the property the test means to guard (see Q3). LOW |

Pins above are the inventory's. The agent re-derives each from the merge commit and records the derivation; where a script already defines a pin, that pin is reused.

### Side findings assigned here
- S1. `069-verify.sh:204-209` reads `origin/task/064-schema-check-end-anchor`; when the branch is deleted AC5.3 prints "not evaluated" and does not fail (silent skip). Fix: read a pinned SHA of that branch's tip; unreachable = FAIL.
- S2. `057-verify.sh:30` reads local `main` of `/home/ludwig/wom` (hard-coded path) for ADR-0121's status. Fix: read the ADR at a pinned commit of the registry/platform history that the script already knows, or take the status from a fixture blob; no hard-coded path to a working copy. Which of the two is Q4.
- S3. `070-verify.sh` header still says "ten closed scripts"; correct the number to the count the script actually runs (derive it, do not copy it). Header text only.
- S4. `039a-verify.sh` sweeps every `*-verify.sh`, including `039b-verify.sh`, which skips 039a. After 039b merges the suite runs twice. Decision is Q1; nothing is decided here.
- S5. Open observation, not a task item: the one-off `FAIL AC1.5` (062 inside 067) seen once in 087's run. If the quiet-machine runs of this task reproduce it, it becomes a finding against 062 and is logged with the full output.

### Excluded, with reason
- `070-verify.sh --mutate` AC4.m1: fixed inside 087 (#24), not here.
- `032-verify.sh` N5/N5b and `067-verify.sh` AC2.5: fixed by 087.
- Live reads that correctly stay on HEAD (inventory last section): contract prose/schema pins (006, 032, 034, 057-textchecks, 065 AC5.1), two-files-agree checks, tool/CLI help and hygiene checks, mutation-runner preconditions, stable doc-presence needles. The agent classifies each touched check in the log with one line why (own-change vs live), as 087 did.

## Size
Exceeds SPEC-CHECKLIST 5b. Source files touched: `007a-verify.sh`, `007b-verify.sh`, `008a-verify.sh`, `057-verify.sh`, `057-textchecks.py`, `065-verify.sh`, `069-verify.sh`, `070-verify.sh`, `075-verify.sh`, `039a-verify.sh`, `tests/registry/test_hardening.py`, `tests/registry/test_ci_gate.py`, `tests/registry/test_classify.py`: 13 against a cap of 5 (verify scripts are not excluded from this count; only the new `089-verify.sh` and fixtures are). Changed lines are not estimated here; the agent reports them. Splitting is the default (MANAGER.md §2b), so the proposed shape is three tasks by script group, each with its own `NNN-verify.sh`, one PR, same pattern:
- A (README pins, findings 1-7, S2, S3): 007a, 007b, 008a, 057-verify, 057-textchecks, test_hardening, 070 header, plus findings 13 (test_classify, same 007a origin) - 8 source files.
- B (contract and R11 pins, findings 8-12, S4): 065, 075, 039a, test_ci_gate - 4 source files. HIGH items 9 and 10 are here and go first.
- C (S1 and S2 if split off): 069, 057-verify - 2 source files.
Why one task might still be acceptable: every change is the same mechanical move, one reference pattern, one set of pins, and one quiet-machine full sweep serves all. Why splitting is better: 13 scripts each need a red fixture, a mutation and a later-branch control; a single reviewer round cannot hold that, and one failure blocks the HIGH items. Recommendation: split A/B/C, B first. Q5 asks Ludwig.

## File scope (declared)
Exactly these, and nothing else:
`docs/tasks/007a-verify.sh`, `docs/tasks/007b-verify.sh`, `docs/tasks/008a-verify.sh`, `docs/tasks/057-verify.sh`, `docs/tasks/057-textchecks.py`, `docs/tasks/065-verify.sh`, `docs/tasks/069-verify.sh`, `docs/tasks/070-verify.sh` (header text only), `docs/tasks/075-verify.sh`, `docs/tasks/039a-verify.sh`, `tests/registry/test_hardening.py`, `tests/registry/test_ci_gate.py`, `tests/registry/test_classify.py`, `docs/tasks/089-closed-verify-sweep-registry.md` (log), `docs/tasks/089-verify.sh` (new; a split uses `089a-`, `089b-`, `089c-` names). In each file only the checks named in the table. Anything else = stop and report.

## Acceptance criteria
All command-based, shipped as `docs/tasks/089-verify.sh`, whose output the log pastes. It runs in a fresh clone, with `PYTHONDONTWRITEBYTECODE=1`, own-change checks on fixed SHAs.
1. Red first (§2c rule 5): for each finding 1-13 and S1, a fixture or temp-clone step that makes the later change (merge of a synthetic branch that rewords or removes the pinned sentence/file content; for 1-6 and 7 the real branch `origin/task/082-pipeline-trigger-contract` is the later branch if still reachable, else a synthetic one) is shown failing against the old script at the red commit, then passing after the fix. A fixture that passes on the unfixed script is rejected. Finding 12: the red fixture adds a test to `test_ci_gate.py` in the later branch.
2. Pins: each fixed check reads `git show FINAL:path` with FINAL a full or abbreviated reachable SHA recorded in the script; `089-verify.sh` asserts every fixed check's pin equals `git rev-parse <merge>^2` (or the merge-base for BASE) for the merge found by `git log --merges --grep`. No `HEAD`, `origin/main` or worktree read remains for a check classified own-change (a grep over the touched checks, with a non-zero count required, §2c rule 1).
3. Unreachable pin = FAIL: for each script, replacing a pin with `deadbee` turns the corresponding check red, and no check prints "skip" or "not evaluated" (grep the script output for those words, expected 0 hits, with a positive control that the grep can match).
4. `--mutate`: for each fixed check, widening it back to HEAD (in a temp clone, where a later branch has changed the file) turns that check red and only that check; one mutation per finding, 14 in total; the controls (unmutated) stay green. Mutation results are listed one per line.
5. The item-12 control: every fixed script, run on HEAD and on a merge of HEAD with a later synthetic branch that edits the same files (README sentence, ownership.md sentence, `config/r11-identity.json`, a new test in `test_ci_gate.py`, `reserved-namespaces.json`), exits 0. Positive control: the same merge makes the unfixed scripts exit non-zero.
6. S1: with `origin/task/064-schema-check-end-anchor` deleted in the temp clone, `069-verify.sh` AC5.3 still passes (pinned SHA) and with a bad pin fails.
7. S3: the `070-verify.sh` header count equals the number of closed scripts the script iterates, asserted by `089-verify.sh`; `git diff` of 070 shows header lines only.
8. S4: the behaviour chosen under Q1 is demonstrated: either the suite runs each script once (a count of invocations in a logged run) or the doubled run is documented in the 039a header.
9. Quiet machine (`ps` logged; wait until no other `*-verify.sh` runs, as 087 did): every closed script, one at a time, green on HEAD and on the merge with the later synthetic branch. If the one-off `FAIL AC1.5` (062 inside 067) recurs, the full output is pasted and S5 becomes a finding.
10. Finding 8: the log states whether the 039b agent's 065 failure is reproduced by merging 039b onto the base with the unfixed 065, with the failing check named; the fixed 065 passes on the same merge.
11. Scope: `git diff --name-only BASE..FINAL` for the task is a subset of File scope; 070 differs by header lines only.

## Forbidden here
Weakening any check: no looser pattern, no dropped assertion, no lowered count, no `|| true`, no skip on an unresolved pin (§3.7; MANAGER.md §2c). Pinning a live property (tests green, other closed scripts green, contract text pinned on purpose, CLI help, hygiene); each such check stays on HEAD. Editing any script or file outside File scope, including `032-verify.sh`, `067-verify.sh` (fixed by 087). Hard-coded absolute paths to a working copy in a new check. Environment-variable overrides of pins (078/085 forbid them). Deleting a check to make a sweep green. Starting before the dependency PRs are merged and the spec is approved.

## Deliverables
Fixed scripts and tests as in File scope; `089-verify.sh` (or `089a/b/c`) with red fixtures, mutations and controls; this file's log with the pins derived, the one-line own-change/live classification per touched check, the red/green/mutation output pasted, and the finding-8 and S5 outcomes; docs that mention the changed behaviour updated in the same branch.

## Questions  (agent-maintained; see MANAGER.md 8b)
- Q1: S4 - 039a sweeps every `*-verify.sh` including 039b-verify, which skips 039a, so the suite runs twice after 039b merges | options: A) leave as is and document the double run in the 039a header; B) make 039a skip `039b-verify.sh`; C) make 039a sweep only scripts older than 039a | assumed: A (conservative: changes no check) | built on assumption: 039a header text only
- Q2: finding 11 - `test_ci_gate.py:1018-1021` | options: A) read `config/r11-identity.json` at FINAL inside the test; B) move the check into 039a-verify and delete it from the test file; C) keep it live and mark it a deliberate canary until Ludwig configures R11 | assumed: A (does not remove a check) | built on assumption: `test_ci_gate.py` only
- Q3: finding 13 - `test_classify.py:132-134` | options: A) read the blob at the 007a pin; B) assert the property the test guards (names include mc and test) instead of equality | assumed: A (B changes what is asserted, so it needs approval) | built on assumption: `test_classify.py` only
- Q4: S2 - `057-verify.sh:30` ADR-0121 status | options: A) read the ADR at a pinned commit; B) a fixture blob in the verify script directory | assumed: A | built on assumption: line 30 only
- Q5: the split in Size | options: A) three tasks A/B/C, B first; B) two tasks (A+C, B); C) one task | assumed: A (splitting is the default) | built on assumption: none yet; this file is written for the whole set and is cut into parts at the spec gate

---
# Task 089 log  (append-only, updated continuously by the executing agent)
- 2026-10-26 doc-writer (session 12): drafted from the 088 inventory. Not yet reviewed. No pins re-derived; the pins in the table are the inventory's.
