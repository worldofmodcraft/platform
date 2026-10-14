# Task 053: Decision and journal notes in the vault projection

- **Mission:** tooling (task 047, part C, step 2b; split out of 051 after the spec review) — **Status:** review (implemented 2026-10-14; spec v3 approved by Ludwig)
- **Agent / model:** implementer / per agent frontmatter (ROUTING.md)
- **Budget:** small
- **Branch / worktree:** task/053-vault-adr-journal / ~/wt/task-053
- **Blocked by:** 051 merged (it extends `tools/vault/wom_vault.py` and inherits every write rule and the contract of 051)

## Objective
Mode `main` also writes `Decisions.md`, one `ADR/<file>.md` per ADR and `Journal/YYYY-MM-DD.md`. These
notes follow 051's contract, and their idempotence and secret-scan behaviour are proven by
`docs/tasks/053-verify.sh`.

## Contract additions (amend `docs/tools/vault-projection.md`)
| Note | Derived from | `source_commit` |
|---|---|---|
| `Decisions.md` | `docs/decisions/INDEX.json`: one row per ADR with id, title and a `[[ADR/<file stem>]]` link | last commit touching INDEX.json |
| `ADR/<file>.md` | `docs/decisions/NNNN-*.md`, body verbatim (ADRs carry no YAML frontmatter; checked on 0103, 2026-10-14). The generated frontmatter is prepended. If an ADR ever starts with `---`, the run fails validation instead of merging two frontmatter blocks. | last commit touching that file |
| `Journal/YYYY-MM-DD.md` | Every commit reachable from main, merges included, grouped by committer date in `Europe/Stockholm` (`zoneinfo`; system tzdata present). One line per commit, newest first: short sha, subject. | the newest commit of that day |

Each day file is re-rendered on every run and written only if its bytes changed, so a new commit
rewrites only its own day (051 write rule 3).

**Checked 2026-10-14 on main `3e2b6ef`:** none of the 120 ADR files starts with `---`. History is
108 commits over 8 Stockholm days. The first live run therefore writes about 130 notes in one LiveSync
burst (120 ADR notes, 8 Journal days, and the 051 set). That is accepted as a one-off; later runs write
only what changed. `ADR/` and `Journal/` are created under 051 write rule 5.

## Amendment 2026-10-14 (approved by Ludwig: "Ja på 053 med dina ändringar"), from task 051's review
These change 051 behaviour inside `tools/vault/wom_vault.py`. 051's contract doc is amended to match.
- **A1 duplicate ids.** If more than one local branch matching `task/NNN-*` is unmerged into main for the
  same `NNN`, then mode `main` writes nothing for `Tasks/NNN.md`, and mode `task` refuses (non-zero exit,
  nothing written). `Status.md` lists the conflict, and the run summary counts it (`id_conflicts=`).
- **A2 non-regular targets.** A planned target that exists but is not a regular file (a symlink, FIFO,
  directory or device) fails validation **before any open**. It is checked with `lstat`. Nothing is written.
- **A3 verify honesty.** In `051-verify.sh`, the committed-secret scan must fail when grep errors (exit ≥ 2),
  not count the error as "none found". The `2>/dev/null` masking is removed.

## File scope (declared)
`tools/vault/wom_vault.py`, `tools/vault/tests/**`, `docs/tools/vault-projection.md`, `docs/tasks/053-verify.sh`, `docs/tasks/051-verify.sh` (A3 only), this file's log.

## Acceptance criteria (all script-verified by `053-verify.sh`, output pasted in the log)
1. In a fixture repo: the note set includes `Decisions.md`, one ADR note per ADR file, and one Journal file
   per commit day, with exact contents checked against `git log` output.
2. A commit dated on a new day, or with a timestamp that crosses midnight UTC versus Stockholm time, lands
   in the correct Stockholm day. Only that day's file and `Decisions.md` / `ADR/*` notes whose source
   changed are rewritten.
3. An ADR fixture starting with `---` fails validation with nothing written.
4. A secret-pattern string inside an ADR fixture or a commit subject (built at runtime) blocks the whole
   run, as in 051 AC4.
5. `053-verify.sh --mutate` turns the checks for criteria 2 and 3 red. The script passes in a fresh clone.
6. All of 051's verify suite still passes (re-run, output pasted).
7. A1: a fixture with two unmerged `task/NNN-*` branches. Main skips the note and `Status.md` names the
   conflict. Task mode on either branch exits non-zero with nothing written. A mutant removing the check is killed.
8. A2: a symlink at `Status.md` pointing at a fixture hand-written note, plus a FIFO at a planned name. Each
   gives a non-zero exit, zero files written, and no open of the link target (051's audit hook). A mutant
   removing the check is killed.
9. A3: a fixture making grep exit 2 turns `051-verify.sh`'s scan red.

## Forbidden here
Everything forbidden in 051. In addition: changing any 051 write rule, and reading the vault beyond 051 rule 6.

## Dependency graph
Same node and edge as 051. The contract document is amended, not replaced.

---
# Task 053 log

- 2026-10-14 implementer. Code: `tools/vault/wom_vault.py` (render_decisions, render_journal, A1, A2), tests `tools/vault/tests/test_vault_053.py`, mutants `tools/vault/tests/mutate053.py`, script `docs/tasks/053-verify.sh`, A3 in `docs/tasks/051-verify.sh`, contract `docs/tools/vault-projection.md`.
- Order note (section 2c rule 5): I wrote the tool change before the tests in the working tree; the breaking fixtures were then run against the unmodified tool (`git show 87d3608:tools/vault/wom_vault.py`) and are shown failing below, before the passing run.

## Failing first (fixtures vs the pre-053 tool; A1/A2 = test_ac7/test_ac8, A3 = shim run)
```
$ WOM_VAULT_SCRIPT=<pre-053 tool> python3 -I test_vault_053.py   (14 tests)
Ran 14 tests in 25.296s
FAILED (failures=29, errors=3)
FAIL: test_ac1_decisions_adr_and_journal_exact / _inconsistent_index_is_an_error (x4) / _repo_without_decisions_still_gets_journal
FAIL: test_ac2_only_the_affected_notes_are_rewritten; ERROR: test_ac2_stockholm_day_boundaries, test_ac1_merge_commits_are_listed
FAIL: test_ac3_adr_starting_with_dashes... [frontmatter] [bare rule] [bom]
FAIL: test_ac4 (all 12 subtests, 6 patterns x adr|subject; the old tool writes no ADR/Journal notes)
FAIL: test_ac7_main_skips_names_the_conflict_and_task_mode_refuses, test_ac7_main_leaves_an_existing_note_untouched_and_conflict_clears
FAIL: test_ac8_symlink_target_is_refused_without_opening_it [hand] [generated]; test_ac8_fifo_directory_and_dangling_link [dangling] [dir] [journal-fifo]
ERROR: test_ac8_fifo_directory_and_dangling_link [fifo]   (the old tool blocks on open() of the FIFO until the 20 s test timeout)
$ PATH=<dir with grep that exits 2 for "-IEl">:$PATH docs/tasks/051-verify.sh      (unmodified 051-verify.sh)
ok: no secret-shaped string in 225 tracked files ...
== 051-verify: ALL CHECKS PASSED          <- A3 defect shown: an erroring grep counted as "none found"
```

## Passing, in a fresh clone of the branch at 4d8910c (`git clone` then `TMPDIR=/tmp docs/tasks/053-verify.sh --mutate`, exit 0)
```
== AC1-AC4, AC7, AC8: tests against the real tool
Ran 14 tests in 6.674s
OK
== AC9: a grep that exits 2 turns 051-verify.sh's committed-secret scan red
ok: with a failing grep 051-verify.sh exits 1: FAIL: secret scan: grep failed on 227 file(s) (exit >= 2); an erroring scan proves nothing
== AC6: the whole 051 suite still passes
ok: 051-verify.sh passed
Ran 32 tests in 40.275s
OK
== 051-verify: ALL CHECKS PASSED
== documentation present  (7 x ok)
ok: mutant 'journal-tz' killed -> FAIL: test_ac2_stockholm_day_boundaries
ok: mutant 'skip-identical' killed -> FAIL: test_ac2_only_the_affected_notes_are_rewritten
ok: mutant 'adr-frontmatter' killed -> FAIL: test_ac3_adr_starting_with_dashes_fails_validation_and_writes_nothing
ok: mutant 'secret-scan' killed -> FAIL: test_ac4_secret_in_adr_or_commit_subject_blocks_the_run
ok: mutant 'id-conflict-main' killed -> FAIL: test_ac7_main_skips_names_the_conflict_and_task_mode_refuses
ok: mutant 'id-conflict-status' killed -> FAIL: test_ac7_main_skips_names_the_conflict_and_task_mode_refuses
ok: mutant 'id-conflict-task' killed -> FAIL: test_ac7_main_leaves_an_existing_note_untouched_and_conflict_clears FAIL: test_ac7_main_skips_names_the_conflict_and_task_mode_refuses
ok: mutant 'non-regular' killed -> ERROR/FAIL: test_ac8_fifo_directory_and_dangling_link FAIL: test_ac8_symlink_target_is_refused_without_opening_it
ok: 051 mutation run passed   (13 of 13 051 mutants killed)
== 051-verify: ALL CHECKS PASSED
== 053-verify: ALL CHECKS PASSED
```
Separately, a plain `051-verify.sh` in the same clone: `Ran 32 tests ... OK`, `== 051-verify: ALL CHECKS PASSED`.
Real-repo dry run (temp vault and HOME, test mode, read-only on git): `planned=171 written=171 ... id_conflicts=0 decisions_absent=0` (120 ADR notes, 9 Journal days).

## Acceptance criteria
AC1 test_ac1_decisions_adr_and_journal_exact + merge test (expected content from `git log` with `TZ=Europe/Stockholm`); AC2 TestAC2Days (21:59:59Z, 22:00:00Z, a -08:00 offset, and a winter instant; minimal-rewrite sets asserted exactly); AC3 TestAC3AdrFrontmatter; AC4 TestAC4Secrets (6 patterns x ADR text x commit subject); AC5 mutants above, fresh clone; AC6 051-verify.sh re-run; AC7 TestAC7DuplicateIds + 2 mutants; AC8 TestAC8NonRegular (audit hook shows zero opens in the vault) + mutant; AC9 shim fixture in 053-verify.sh.

## Decisions taken inside the spec (flag if wrong)
- 051's `test_vault.py` had two assertions that encode the pre-053 note set: `test_ac1_note_set_and_frontmatter` (exact set) and `test_ac2_second_run...` (subset of changed notes). Mode main now also writes `Journal/2026-10-14.md` for that fixture, so I extended both expectations by that one name; the exact-set assertion stays exact and nothing was relaxed beyond that one file. Nothing else in 051's tests changed.
- A2 runs after the containment check and before any open, in a first pass over all targets, so no earlier target is opened either. A symlink to the outside still reports "outside the vault" as in 051.
- A3: the scan is now a per-file grep loop (xargs hides grep's exit status behind 123, which also masked real hits whenever a batch had no match). Nothing else in 051-verify.sh changed.
- A ref without `docs/decisions/` writes no decision notes and prints `decisions_absent=1` (needed so 051's fixtures, which have no ADRs, still work). ADR files without INDEX.json, or an ADR set that differs from INDEX.json, is an error.
- Journal: 7-character sha slice (stable across repo size), ordering by committer timestamp descending with git's order as tie-break.

## Questions
- For Ludwig/manager: is the one-name extension of two 051 test expectations (above) acceptable under "never weaken"? I judged it a spec consequence, not a weakening.
- When 051's task file moves to `done/`, the 051-verify.sh secret-scan exclusion (`docs/tasks/051-vault-projection.md`) will no longer match and the scan will hit the spec file's patterns. I did not touch it (A3 only); whoever moves the file must add the `done/` path to the exclusion.
- Ratify: INDEX.json/ADR mismatch is a hard error, so a vault run blocks until the index is regenerated after a new ADR.

## Follow-up 2026-10-14 (manager triage after review)
- Judgement call 1 (extending two 051 test expectations by the newly planned Journal note) accepted by the manager as a spec consequence, not a weakening (section 3.5). The stale-index hard error is accepted for now (ADR-0103); Ludwig's question stays booked.
- `git merge main` done (no rebase). 051's spec now lives in `docs/tasks/done/`. `051-verify.sh` excludes the spec at both `docs/tasks/` and `docs/tasks/done/`, and fails if the spec exists at not exactly one of them. Negative control: with the spec file renamed, the run prints `FAIL: the 051 spec file must exist at exactly one of ...` and ends `== 051-verify: FAILED`.
- Fresh clone at 81efc37, `TMPDIR=/tmp`: `053-verify.sh --mutate` exit 0, ends `== 051-verify: ALL CHECKS PASSED` / `== 053-verify: ALL CHECKS PASSED`; `051-verify.sh --mutate` exit 0, `ok: no secret-shaped string in 229 tracked files`, 13 of 13 mutants killed, ends `== 051-verify: ALL CHECKS PASSED`.
