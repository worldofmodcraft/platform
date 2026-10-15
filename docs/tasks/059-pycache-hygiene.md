# Task 059: No Python bytecode in the platform repository

- **Mission:** tooling (housekeeping) — **Status:** review (spec-approved 2026-10-15; implemented, see log)
- **Agent / model:** scaffolder / per agent frontmatter
- **Budget:** small
- **Branch / worktree:** task/059-pycache-hygiene / ~/wt/task-059

## Objective
`git ls-files` on main lists no `__pycache__/` and no `*.pyc`, and a root `.gitignore` keeps it that way.
Origin: the 053 and 052 reviews (a committed .pyc, twice in one night). Three files are tracked on main today:
`tests/adr/__pycache__/test_build_index.cpython-314.pyc`, `tools/adr/__pycache__/__init__.cpython-314.pyc` and
`tools/adr/__pycache__/build_index.cpython-314.pyc`.

## File scope
`.gitignore` (create or append `__pycache__/` and `*.pyc`), `git rm --cached` of the three files,
`docs/tasks/059-verify.sh`, and this file's log.

## Acceptance criteria (script-verified by `059-verify.sh`)
1. `git ls-files | grep -E '(__pycache__/|\.pyc$)'` prints nothing, and the script fails if it prints anything.
2. A freshly created `x/__pycache__/y.pyc` is ignored (`git check-ignore` succeeds).
3. Mutation: with the .gitignore line removed, check 2 goes red; with one file re-added, check 1 goes red.
4. `python3 tools/adr/build_index.py --check` still passes. The ADR tool works without its bytecode.
5. The script passes in a fresh clone.

## Forbidden here
Deleting any source file. Touching anything outside the declared scope.

# Task 059 log

Final HEAD before this log commit: `2076fe7`. Run in a fresh clone (`git clone -b task/059-pycache-hygiene`), `docs/tasks/059-verify.sh --mutate`, exit 0:

```
== environment
git: git version 2.53.0
python: 3.14.4
temp root: /tmp/wom059-BSaRVU (guard passed)
== AC1: the index of the working tree (/tmp/wom059-fresh-VqI5ig/repo)
ok: no tracked bytecode in the working tree
== AC1, AC2, AC4, AC5: fresh clone of committed HEAD
clone at 2076fe75f1031e02e6d5c03a6024bb9a9bbd1af2
ok: c1 holds in fresh clone
ok: c2 holds in fresh clone
ok: c4 holds in fresh clone
ok: criteria 1, 2, 4 hold in a fresh clone (criterion 5)
== AC3: mutation run (each mutant must turn its check red)
ok: mutant 'no ignore rule' killed -> criterion 2 red
      x/__pycache__/y.pyc is not ignored (check-ignore rc=1)
ok: mutant 're-added file' killed -> criterion 1 red
      tracked bytecode:
        tools/adr/__pycache__/build_index.cpython-314.pyc
== 059-verify: ALL CHECKS PASSED
```
