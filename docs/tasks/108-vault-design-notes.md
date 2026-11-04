# Task 108: the vault projection also writes `docs/design/*.md` as notes at the vault folder root

- **Mission:** SITE-V1 (operations tooling) — **Status:** review (phase 2 green 2026-11-04); was spec-approved 2026-11-03 (manager, session 14; Ludwig's request: design docs follow the repo automatically,
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
