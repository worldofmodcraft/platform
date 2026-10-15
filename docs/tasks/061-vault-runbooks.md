# Task 061: Runbooks in the vault projection

- **Mission:** tooling (vault projection, follow-up to 051/053) — **Status:** review (Ludwig chose option A in session 2026-10-15: "A lägg till den (i projektet Projekt World of Modcraft)"; manager gate, small)
- **Agent / model:** implementer / per agent frontmatter
- **Budget:** small
- **Branch / worktree:** task/061-vault-runbooks / ~/wt/task-061, **stacked on task/052-vault-triggers**: both touch
  `docs/tools/vault-projection.md`, so they are sequenced (§6). This task merges after 052.

## Objective
Mode `main` also writes `Runbooks/<stem>.md` inside the WoM project folder (`WOM_VAULT`), one note per
`docs/runbooks/*.md` on the ref. The body is verbatim, with 051's generated frontmatter prepended, and
`source_commit` is the last commit touching that file. Ludwig can then follow `site-v1-manual-steps` from Obsidian
on his phone. `Status.md` gains a "Runbooks" line linking each runbook note.

## Context to load
`docs/tasks/done/051-vault-projection.md`, `docs/tasks/done/053-vault-adr-journal.md` (its rules A1–A3 apply
unchanged), `docs/tools/vault-projection.md`, `tools/vault/wom_vault.py` and its tests.

## File scope
`tools/vault/wom_vault.py`, `tools/vault/tests/**` (new test file preferred; existing tests may only gain the new note
names in exact-set expectations, which is an addition, not a weakening), `docs/tools/vault-projection.md` (contract
table row), `docs/tasks/061-verify.sh`, and this file's log. No `.pyc` files.

## Acceptance criteria (script-verified by `061-verify.sh`)
1. In a fixture repo with two runbooks, mode `main` writes exactly `Runbooks/<a>.md` and `Runbooks/<b>.md`. Bodies are
   verbatim, frontmatter is per 051, and `source_commit` = `git log -1 --format=%H main -- docs/runbooks/<x>.md`.
2. A runbook starting with `---` (its own frontmatter) fails validation with nothing written (053's ADR rule).
3. A secret-shaped string in a runbook, built at runtime, blocks the whole run and is never printed (051 AC4 style).
4. A non-regular target under `Runbooks/` (symlink, FIFO) is refused before any open (053 A2).
5. A second run writes nothing, and a commit touching one runbook rewrites only that note, plus `Status.md` if its bytes change.
6. A repo with no `docs/runbooks/` writes no Runbooks notes and does not error.
7. `--mutate`: a mutant per criterion 1–5 is killed. `051-verify.sh`, `053-verify.sh` and `052-verify.sh` still pass.
8. Everything passes in a fresh clone at the FINAL HEAD, with tails pasted after the last code commit.
9. **Human, after merge:** the manager runs the projection, and Ludwig sees `Runbooks/site-v1-manual-steps` in Obsidian.

## Forbidden here
Anything against the real vault or `~/.config/wom` before criterion 9. Credentials. Weakening any existing check.

## Task 061 log
- Fixtures first: `tools/vault/tests/test_vault_061.py` (13 tests) was run against the unchanged tool and failed
  with 19 failures (commit "fixtures first"). Then `render_runbooks` was added to `wom_vault.py`.
- `Runbooks:` line is omitted when there are no runbooks (AC6). Runbook names outside `[A-Za-z0-9][A-Za-z0-9._-]*`,
  forbidden names and non-regular git modes are errors, not silent skips.
- Verification tails: see the final report / `docs/tasks/061-verify.sh` output.
- `tools/adr/__pycache__/*.pyc` are tracked on the base branch (outside this task's scope); the bytecode check in
  `061-verify.sh` covers `tools/vault` only, like 052's. Reported to the manager.
