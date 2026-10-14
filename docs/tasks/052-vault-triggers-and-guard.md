# Task 052: Keep the vault current automatically, and keep agents' file tools out of it

- **Mission:** tooling (task 047, part C, step 3) — **Status:** draft (manager's spec gate run 2026-10-14; independent spec review pending; Ludwig's approval pending)
- **Agent / model:** implementer / per agent frontmatter (ROUTING.md)
- **Budget:** small
- **Branch / worktree:** task/052-vault-triggers / ~/wt/task-052
- **Blocked by:** task 051 merged; Ludwig's answer Q-C1 (trigger). The spec below assumes ★A.

## Objective
The vault is refreshed without anyone remembering to do it. A commit in a task worktree refreshes that
task's note. Updating local `main` refreshes the main-derived notes. The manager runs the projection
after every merge and at handover. No agent or main-session Write/Edit call can land inside `$WOM_VAULT`.

## Context to load (exhaustive)
- `docs/tasks/051-vault-projection.md` and `docs/tools/vault-projection.md` (after 051 merges)
- `docs/manager/MANAGER.md` §5 (handover procedure), §7
- `docs/manager/OPERATIONS.md` § "Branch protection changes the workflow", § "`gh pr merge` must be run as a BARE command"
- Hook facts, verified 2026-10-14 against the official docs (https://code.claude.com/docs/en/hooks.md)
  by a claude-code-guide agent: PreToolUse input carries `agent_type` inside a subagent; exit 2
  blocks the call; settings-file hooks fire for subagents' tool calls too. **Caveat (§3.6b):** the
  same source says a missing hook script is a *non-blocking* error, so enforcement is silently lost.
  AC4 below covers that case.

## File scope (declared)
- `tools/vault/git-hooks/post-commit`, `tools/vault/git-hooks/post-merge`, `tools/vault/install-git-hooks.sh`
- `.claude/hooks/vault-guard.sh` (calls a Python 3 stdlib guard, `python3 -I`), `.claude/settings.json` (one PreToolUse entry)
- `docs/manager/MANAGER.md` §5 item 4: one added step, "run the vault projection" (doctrine edit → Ludwig approves the merge, §7)
- `docs/manager/OPERATIONS.md`: after `gh pr merge`, run `git fetch origin main:main` and then the projection
- `docs/tasks/052-verify.sh`, this file's log

## Acceptance criteria
1. `post-commit` on a `task/NNN-*` branch runs mode `task`, and on any other branch does nothing. `post-merge`
   on `main` runs mode `main`. A failure prints to stderr and exits non-zero. It is never swallowed.
   Script-verified in a temp repo with a temp vault.
2. `install-git-hooks.sh` installs into `$(git rev-parse --git-common-dir)/hooks`, refuses to overwrite
   an existing non-WoM hook, and is idempotent. Script-verified in a temp repo.
3. `vault-guard`: Write/Edit/MultiEdit/NotebookEdit targeting the vault (absolute, relative from a cwd,
   via `..`, a path with spaces) exits 2. Paths outside the vault exit 0. Invalid JSON exits 2. An
   unresolvable `WOM_VAULT` exits 2 for every file-tool call (fail closed). Script-verified by
   piping JSON fixtures.
4. A test proves the guard is wired: `.claude/settings.json` references a script path that exists and
   is executable, because a missing script would fail open.
5. Mutation proof for 1–4 (§2c rule 2).
6. **Known gap, documented and not fixed:** shell writes from agents' Bash are not covered (the same
   gap as Arcane's). Booked as a follow-up in 049's scope.
7. **Manual, with Ludwig:** after merge, the manager runs `install-git-hooks.sh` in `~/wom` (this changes
   the local `.git/hooks`, which is shared by all worktrees) only on Ludwig's go. The first real
   commit and the first real `git fetch origin main:main` followed by a projection show up on the phone.

## Forbidden here
- Installing hooks into the real `~/wom/.git` before AC7.
- Running anything against the real vault (same rule as 051).
- Making the git hooks block commits. `post-commit` cannot block, and nothing may pretend to.

## Dependency graph
Same tooling node as 051 (`vault-projection`). No new edges: the triggers invoke the 051 contract.
