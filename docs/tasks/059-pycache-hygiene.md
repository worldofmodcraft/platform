# Task 059: No Python bytecode in the platform repository

- **Mission:** tooling (housekeeping) — **Status:** spec-approved (manager, 2026-10-15; small, §2b solo gate)
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
