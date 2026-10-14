# Task 052: Keep the vault current automatically, and keep agents' file tools out of it

- **Mission:** tooling (task 047, part C, step 3) — **Status:** draft (spec v2 after the independent spec review, 2026-10-14; second review pending; Ludwig's approval pending)
- **Agent / model:** implementer / per agent frontmatter (ROUTING.md)
- **Budget:** small
- **Branch / worktree:** task/052-vault-triggers / ~/wt/task-052
- **Blocked by:** 051 and 053 merged. Q-C1 = ★A (Ludwig, 2026-10-14).

## Objective
The vault refreshes without anyone remembering to do it:
- A commit in a task worktree refreshes that task's note.
- `git pull` of main refreshes main's notes.
- The manager's post-merge step and handover step refresh main's notes explicitly.

No Write/Edit/MultiEdit/NotebookEdit call from the main session or any subagent can land inside a
configured vault.

## Verified facts this spec rests on
- **Git (manager, temp repo, 2026-10-14):** `git fetch origin main:main` fires **no** `post-merge`.
  `git pull` on a checked-out main does. So after `gh pr merge`, the manager's own step is the trigger
  (Q-C1 ★A), and `post-merge` covers Ludwig's own pulls.
- **Claude Code hooks (official docs, https://code.claude.com/docs/en/hooks.md, read by a claude-code-guide
  agent 2026-10-14):** exit 2 from PreToolUse blocks the call. Settings-file hooks fire for subagents'
  tool calls too. A **missing hook script is a non-blocking error**, which means the hook fails open.
  AC4 exists because of that last point.
- **Unverified (§3.6b), confirmed by AC7:** whether the hook process inherits `WOM_VAULT` from the
  session. The design does not depend on it, because the guard also reads `~/.config/wom/vault-path`.

## Context to load (exhaustive)
- `docs/tasks/051-vault-projection.md`, `docs/tasks/053-vault-adr-journal.md`, `docs/tools/vault-projection.md`
- `docs/manager/MANAGER.md` §5 item 4, §7. `docs/manager/OPERATIONS.md` § "`gh pr merge` must be run as a BARE command"
- ADRs (INDEX.json lookup 2026-10-14): 0103 boring and restartable, 0115 measure outcomes (count skips with reasons)

## Design
1. **Pinned copy.** `install-git-hooks.sh` copies `tools/vault/wom_vault.py` from the current main into
   `$(git rev-parse --git-common-dir)/wom-vault/` and records the source commit. The hooks run that copy,
   never a branch's own (possibly missing or old) version. Re-running the installer updates the copy.
2. **`post-commit`:** on a branch `task/NNN-*` it runs mode `task`; on any other branch it does nothing.
   **`post-merge`:** on main it runs mode `main`.
3. **Vault not configured** (no env var and no config file): the hook prints `wom-vault: not configured,
   skipped` to stderr, appends one line with the reason to `$(git-common-dir)/wom-vault/skips.log`, and
   exits 0. **Configured but failing:** it prints the error to stderr and exits non-zero. Nothing is
   swallowed. The hook can never block a commit (git ignores a post-commit exit code, and the docs say so).
4. **Lock wait:** the hooks inherit 051's 30 s cap, so a commit waits at most 30 s.
5. **`vault-guard`** (PreToolUse; matcher `Write|Edit|MultiEdit|NotebookEdit`). It checks
   `tool_input.file_path` (Write, Edit, MultiEdit) and `tool_input.notebook_path` (NotebookEdit). The
   path is normalised: a relative path is joined to `cwd`, `D:\…` / `D:/…` are mapped to `/mnt/d/…`, the
   result goes through `realpath`, and the comparison with `realpath(vault)` is **case-folded** (drvfs is
   case-insensitive).
   - Inside the vault → exit 2.
   - Vault **not configured** → exit 0, and the reason is counted in `~/.config/wom/guard-skips.log`.
     A fresh clone or another machine must not be bricked.
   - Vault **configured but unresolvable**, or invalid JSON → exit 2 (fail closed).
6. Manager steps (doctrine text): after each `gh pr merge`, run `git fetch origin main:main` and then
   `python3 -I tools/vault/wom_vault.py write --ref main`. The same at handover.

## File scope (declared)
`tools/vault/git-hooks/post-commit`, `tools/vault/git-hooks/post-merge`, `tools/vault/install-git-hooks.sh`,
`.claude/hooks/vault-guard.sh` + `.claude/hooks/vault_guard.py`, `.claude/settings.json` (one PreToolUse
entry), `docs/manager/MANAGER.md` §5 item 4 (one step; doctrine → Ludwig approves the merge, §7),
`docs/manager/OPERATIONS.md` (the post-merge step), `docs/tools/vault-projection.md` (triggers section),
`docs/tasks/052-verify.sh`, this file's log.

## Acceptance criteria
Script-verified by `052-verify.sh` (output pasted in the log) unless marked **human**.
1. In a temp repo with a temp remote and a test vault (051 test mode): a commit on `task/NNN-x` writes
   `Tasks/NNN.md`, and a commit on another branch writes nothing. A **real `git pull`** of main writes main's
   notes, and a real `git fetch origin main:main` does **not** (that documents the gap the manager step closes).
2. Unconfigured vault: the commit succeeds, the stderr line appears, and the skip is logged. Broken vault:
   non-zero exit and the error on stderr.
3. The installer writes only into the temp repo's git-common-dir, refuses an existing non-WoM hook, and is
   idempotent. **In test mode it refuses any git dir that is not under the temp dir.**
4. Guard fixtures, one each: absolute path inside; relative path from a `cwd` inside; `..` traversal into
   the vault; a path with spaces; an upper/lower-case variant; a `D:\` path; a symlink into the vault;
   `notebook_path`; a path outside (exit 0); invalid JSON (exit 2); configured-but-missing vault (exit 2);
   unconfigured (exit 0, plus the counted skip).
5. Wiring: `.claude/settings.json` is valid JSON. Its PreToolUse matcher covers all four tools. The
   command path it names exists and is executable.
6. `052-verify.sh --mutate` re-runnably turns 1–5 red: remove the case-folding, the realpath, the
   fail-closed branch, the branch filter, and the installer refusal. The script passes in a fresh clone.
7. **Live, in session, after merge (manager + Ludwig):** in a real session, a Write call aimed into the
   vault is blocked, with the denial shown. On Ludwig's go, the manager runs the installer for `~/wom`.
   The next real task-branch commit, and the next manager post-merge step, show up on the phone (Ludwig confirms).
8. **Known gap, documented and not fixed here:** agents' Bash writes into the vault are not covered. That
   is in task 049's scope (049's file, "Constraints known now").

## Forbidden here
- Installing into the real `~/wom/.git` before AC7. Anything against the real vault (051's rules apply).
- Making any hook look as if it blocks a commit.
- Editing CLAUDE.md, or `.claude/agents/` (that is task 048).

## Dependency graph and sequencing
Same node as 051. No new edges: the triggers invoke the 051 contract. `.claude/settings.json` and
`MANAGER.md` are also touched by 048 and 049, so the order is **052 → 048 → 049**, never parallel.
