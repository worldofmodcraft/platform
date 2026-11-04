# Task 108: the vault projection also writes `docs/design/*.md` as notes at the vault folder root

- **Mission:** SITE-V1 (operations tooling) — **Status:** done (phase 2 green 2026-11-04); was spec-approved 2026-11-03 (manager, session 14; Ludwig's request: design docs follow the repo automatically,
  "Ja", 2026-11-03; placement at the folder root, not a subfolder: Ludwig 2026-10-28 "Nej, lägg designdokumentet under Project World of Modcraft i vaultet")
- **Agent / model:** implementer — **Budget:** small
- **Branch / worktree:** `task/108-vault-design-notes` / `~/wt/task-108` (platform)

## Objective
Mode `main` of `tools/vault/wom_vault.py` gains one note kind, modelled exactly on task 061's Runbooks: every `docs/design/<stem>.md` on the ref (top level only, the
same stem rule `[A-Za-z0-9][A-Za-z0-9._-]*`) is written as `<stem>.md` **at the vault folder root**, body verbatim under the generated frontmatter, `source_commit` =
the last commit touching that file. Same rules as Runbooks (061): a design doc starting with `---` (after an optional BOM) fails validation, nothing written; not a
regular file in git, an unaccepted name, or a stem that equals any other planned root note name (`Status`, `Tasks`, `Gotchas`, `Commands`, `Mission Log`,
`Decisions`, or any hand-written/forbidden name the tool already guards) is an error; secret scan covers the notes; a ref with no `docs/design/` writes nothing;
`check` ignores the planned design names like the other planned names; never deletes. Update `docs/tools/vault-projection.md` (table row + a "Design docs (task 108)"
paragraph) in the same branch.

## File scope
`tools/vault/wom_vault.py`, `tools/vault/tests/test_vault_108.py` (new), `tools/vault/tests/mutate108.py` (new, if mutations are written in Python as for 061),
`docs/tools/vault-projection.md`, `docs/tasks/108-verify.sh` (new), this file.

## Acceptance criteria
1. Unit tests (temp repos and temp vaults only, `WOM_VAULT_TEST=1`, vault under `mktemp -d`): projected note bytes = frontmatter + verbatim body; name rules;
   collision with a planned root name -> error, nothing written; `---` start -> error; missing `docs/design/` -> nothing written; secret scan hits a design doc.
2. `108-verify.sh [--mutate]` (shape of `061-verify.sh`): runs the new tests, re-runs `051-verify.sh`, `053-verify.sh`, `061-verify.sh` unchanged and green; each
   mutation (rule removed) reddens its test; red-first for the new behaviour (the old tool writes no design note for a fixture repo; the new one does).
3. Never touches the real vault (test mode only); the manager runs the real `refresh-main.sh` after merge and checks `written` includes the design notes.
4. Phase 1 now (code + unit tests; no `*-verify.sh` while the registry 039a sweep holds the machine); phase 2 when the manager releases it.

---
# Task 108 log
- 2026-11-03 manager (session 14): created on Ludwig's "Ja"; dispatched (phase 1).
- 2026-11-03 implementer, PHASE 1 (code + unit tests; no `*-verify.sh` run, per instruction):
  - Red first: `test_vault_108.py` written before the tool change; on the unmodified tool 28 failures out of 16 tests (every AC1-AC5 and the never-deletes/hand-written-target tests; only the "nothing to write" and check-regression tests pass, as expected).
  - Implemented `render_design_docs` (+ `planned_design_names`) in `tools/vault/wom_vault.py`; `check` gained `--repo`/`--ref` (default `.`/`main`) to learn the planned design names, with a stderr note and compare-everything fallback if the ref is unresolvable. Collision test is NFC+casefold against all planned root names; extra: "Mission Log" is rejected earlier by the stem rule (space).
  - Green: `test_vault_108` 16 OK; `test_vault` 32 OK; `test_vault_053` 14 OK; `test_vault_061` 13 OK (run directly with `python3 -B -m unittest`).
  - Mutations (10, `mutate108.py`) were exercised by hand against only their tests: all killed. `108-verify.sh` and its mutations are written, `bash -n` clean, NOT run.
  - Deviation for the manager: the spec's `check` AC was met by giving `check` a repo/ref (names are not a fixed pattern); existing callers are unaffected because they run inside the repo.
  - PHASE 2 commands (when the machine is free), from `~/wt/task-108`:
    `docs/tasks/108-verify.sh` then `docs/tasks/108-verify.sh --mutate` (the latter also re-runs 051/053/061 --mutate; long). The script includes the red-first run against the pre-108 tool (base 001418f).
- 2026-11-04 implementer, PHASE 2 (fresh clone of worldofmodcraft/platform at b0ec084, main had not moved so no merge; plain invocations, PYTHONDONTWRITEBYTECODE=1, `ps` checked before each: only worldserver/authserver busy, no other verifier):
  - `docs/tasks/108-verify.sh` -> exit 0, "108-verify: ALL CHECKS PASSED" (includes red-first on the pre-108 tool: 27 failing; 051/053/061/052 re-runs green).
  - `docs/tasks/108-verify.sh --mutate` -> exit 0, ALL CHECKS PASSED, no "MUTANT SURVIVED"; 81 `ok: mutant` lines across 108's 10 mutations plus the nested 051/053/061 mutation runs.
  - Cross-script sweep, every `docs/tasks/*-verify.sh` one at a time on that head (script / exit / FAIL lines): 010a 0/0, 048 0/0, 049 1/1 (see below), 051 0/0, 052 0/0, 053 0/0, 056 0/0, 058 0/0, 059 0/0, 061 0/0, 063 0/0, 068 0/0, 072 0/0, 076 0/0, 078 0/0, 079 0/0, 080 0/0, 085 0/0, 090 0/0, 096 0/0, 102 0/0, 108 0/0.
  - 049 red explained, not a code defect: `FAIL: HYGIENE-pyc` listed two `tools/vault/tests/__pycache__/*.pyc` in the tree under test. They were left in MY clone by the earlier 108 runs (a nested verifier/test import wrote bytecode despite the env var), and 049 checks the tree for stray bytecode. After `rm -r tools/vault/tests/__pycache__` in the clone, `049-verify.sh` -> exit 0, 0 FAIL, ALL CHECKS PASSED. Worth a follow-up: some vault verifier path still writes bytecode into the tests dir (059's territory); not fixed here (out of scope).
  - Callers of `wom_vault.py check` with the new `--repo/--ref` (defaults `.`/`main`): grep of tools/vault shows `wom_vault.py` invoked only with `write` by `refresh-main.sh:22`, `git-hooks/post-merge:30`, `git-hooks/post-commit:30`; `install-git-hooks.sh:28-49` only copies the file (`git show main:...`). None call `check`. Remaining `check` uses are docs (`docs/tools/vault-projection.md` lines 143/145, `docs/manager/COMMANDS.md` lines 10/12), run from inside the repo, where `main` resolves, so unchanged behaviour; outside a repo `check` prints a stderr note and compares every root file. The old 051 tests of `check` stay green (test_vault 32 OK, and 051-verify green).
  - Acceptance: AC1 done (16 tests), AC2 done (verify, mutations, red-first, 051/053/061 green), AC3 done (test mode, temp vaults only; real refresh after merge is the manager's), AC4 done.
- 2026-11-04 implementer, FIX ROUND (review /home/ludwig/.claude/jobs/4c7483d7/tmp/108-review.md, PASS-WITH-AMENDMENTS). Code head 16777e1.
  - MED 2 (.pyc leak): cause confirmed, `108-verify.sh` ran `python3 -I` (ignores PYTHONDONTWRITEBYTECODE, no -B). Red-first: added the end-of-run hygiene check to the old script in a fresh clone of fd0fde0 -> exit 1, `FAIL: bytecode left in the tree: .../tools/vault/tests/__pycache__ ...`. Fix: `-I -B` on every python call, plus the check stays. Because the nested 053-/061-verify.sh also lack -B (out of scope, NOT edited), 108-verify.sh now runs the nested 051/053/061/052 verifiers from a throw-away `cp -a` of the tree under its temp dir. FOLLOW-UP BOOKED: add `-B` to the python calls in `053-verify.sh:39` and `061-verify.sh:39` (and the same pattern in any other verifier importing test_vault); Runbooks equivalent of the case-variant gap (finding 3) also a follow-up.
  - MED 1: `check` and `write` now share `design_candidates()`; `check` ignores exactly the names `write` would plan (forbidden, collisions, non-regular, folder names), and any refused doc triggers the stderr fallback (no root file treated as a design note). Tests: MINISIGN.md hand-written note stays in the baseline; git-symlink design doc stays visible.
  - LOW 3: case-only duplicate design stems -> error (test). LOW 4 (manager decision): stems equal to ADR/Tasks/Runbooks/Journal (NFC, casefold) -> error naming the folder (tests, 5 cases). LOW 5: `write --note <design>.md` accepted (tests incl. unplanned still refused). LOW 6: tests for `--repo`, `--ref` (names from the ref, not main), non-repo and unresolvable-ref fallback, missing git binary (PATH without git), non-UTF-8 design path (named error for write, note for check); `check` catches OSError/ValueError too, and a non-UTF-8 path is a WomError. LOW 7 + INFO 8: contract paragraph rewritten (fallback wording, `Mission Log` caught by stem rule, `added:` after removal, folder/case/UTF-8 rules), header comment fixed.
  - Red-first for the new tests on the previous tool: 12 failing of 28 (the ref/repo/non-repo/unresolvable tests pass on it, being regression tests). Now 28 tests OK. 15 mutations (5 new + design-forbidden-name/non-regular now also kill the check tests), each killed.
  - Fresh clone at 16777e1, plain separate invocations, PYTHONDONTWRITEBYTECODE=1, `ps` before each: `108-verify.sh` exit 0 (28 tests, red-first on old tool 41 failing, hygiene ok); `108-verify.sh --mutate` exit 0 (86 mutants killed, no SURVIVED); `049-verify.sh` run AFTER them in the same clone exit 0. Then every `*-verify.sh` once, all exit 0 / 0 FAIL: 010a 048 049 051 052 053 056 058 059 061 063 068 072 076 078 079 080 085 090 096 102 108.
  - Open for the manager (review INFO 9): `party-board-mod.md` and `party-board-mod-proposed-adr.md` are on main; if Ludwig hand-placed a copy in the vault root, the first refresh refuses the whole run until it is moved. Ask him before merging; I did not look in the vault.
- 2026-11-04 manager (session 14): manager fresh-clone re-run at `2905a94`: 108-verify ALL CHECKS PASSED, then 049-verify in the same clone exit 0 (0 FAIL) — the
  .pyc leak the manager reproduced earlier is gone. Independent review PWA -> fix round -> delta review **PASS** (2 LOW, 2 INFO booked). Review INFO 9 resolved: Ludwig's
  manual vault copy is named `Party Board Mod - Design.md`, not `party-board-mod*.md`, so the first refresh is not blocked. Booked: `-B` for 053/061-verify; Runbooks
  case-variant collision gap. Status done; merged on the manager's authority (§7).
