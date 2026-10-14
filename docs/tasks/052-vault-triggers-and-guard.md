# Task 052: Keep the vault current automatically, and keep agents' file tools out of it

- **Mission:** tooling (task 047, part C, step 3) — **Status:** review (spec approved by Ludwig 2026-10-14, spec v3)
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
1. **Pinned copy, one code path.** `install-git-hooks.sh` writes `git show main:tools/vault/wom_vault.py`
   (the ref, never a working tree) into `$(git rev-parse --git-common-dir)/wom-vault/wom_vault.py`, and
   records `git log -1 --format=%H main -- tools/vault/` beside it as `pinned_commit`. The hooks **and** the
   manager step run only that copy. On every run the hook prints `pinned_commit`. When main has a newer
   commit touching `tools/vault/`, it warns `wom-vault: pinned copy is stale; run refresh-main.sh` on stderr.
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
   - Vault **configured but unresolvable** (for example, D: is not mounted): block (exit 2) only target
     paths whose normalised text falls under the configured path string, compared lexically and
     case-folded. Allow everything else, so repo editing never stops. Invalid JSON → exit 2.
   - **Recovery** (documented in `docs/tools/vault-projection.md`): to disable the guard, Ludwig deletes
     `~/.config/wom/vault-path`. The exact command is given in the docs.
   - **Out of scope, documented as a known gap:** `\\wsl$`, `//?/` and UNC prefixes, plus Windows'
     trailing-dot/space stripping. Agents in WSL do not produce these paths. Mixed-slash `d:`/`D:` forms
     **are** in scope.
6. **`tools/vault/refresh-main.sh`** is the manager step (doctrine text) after each `gh pr merge` and at
   handover:
   - If `git worktree list --porcelain` shows main checked out somewhere, it runs
     `git -C <that worktree> pull --ff-only`.
   - Otherwise it runs `git fetch origin main:main`. A plain fetch is refused when main is checked out,
     which the reviewer reproduced 2026-10-14.
   - Then it re-pins (item 1) and runs `write --ref main` with the pinned copy.
   - Any failure exits non-zero.

## File scope (declared)
`tools/vault/git-hooks/post-commit`, `tools/vault/git-hooks/post-merge`, `tools/vault/install-git-hooks.sh`, `tools/vault/refresh-main.sh`,
`.claude/hooks/vault-guard.sh` + `.claude/hooks/vault_guard.py`, `.claude/settings.json` (one PreToolUse
entry), `docs/manager/MANAGER.md` §5 item 4 (one step; doctrine → Ludwig approves the merge, §7),
`docs/manager/OPERATIONS.md` (the post-merge step), `docs/tools/vault-projection.md` (triggers section),
`docs/tasks/052-verify.sh`, this file's log.

## Acceptance criteria
Script-verified by `052-verify.sh` (output pasted in the log) unless marked **human**.
1. In a temp repo with a temp remote and a test vault (051 test mode): a commit on `task/NNN-x` writes
   `Tasks/NNN.md`, and a commit on another branch writes nothing. A **real `git pull`** of main writes main's
   notes, and a real `git fetch origin main:main` does **not** (that documents the gap the manager step closes).
   `refresh-main.sh` updates main's notes in **both** layouts: with main checked out in a worktree, and without.
1b. Pinned copy: the installer's copy is byte-identical to `git show main:tools/vault/wom_vault.py`. After a
   new main commit touching `tools/vault/`, the hook prints the stale warning. After `refresh-main.sh`,
   the warning is gone and `pinned_commit` matches.
2. Unconfigured vault: the commit succeeds, the stderr line appears, and the skip is logged. Broken vault:
   non-zero exit and the error on stderr.
3. The installer writes only into the temp repo's git-common-dir, refuses an existing non-WoM hook, and is
   idempotent. **In test mode it refuses any git dir that is not under the temp dir.**
4. Guard fixtures, one each: absolute path inside; relative path from a `cwd` inside; `..` traversal into
   the vault; a path with spaces; an upper/lower-case variant; a `D:\` path; a symlink into the vault;
   `notebook_path`; a `d:/` mixed-slash path; a path outside (exit 0); invalid JSON (exit 2);
   configured-but-missing vault: a path under it gives exit 2 and a repo path gives exit 0; unconfigured
   (exit 0, plus the counted skip).
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

## Task 052 log
- Implemented 2026-10-15 by the implementer agent in `~/wt/task-052`. Status `review`. AC7 (live, manager + Ludwig) is
  deliberately left open; AC8 is the documented known gap (docs/tools/vault-projection.md, "Known gaps").
- Files: `tools/vault/git-hooks/post-commit`, `post-merge`, `tools/vault/install-git-hooks.sh`, `tools/vault/refresh-main.sh`,
  `.claude/hooks/vault-guard.sh` + `vault_guard.py`, `.claude/settings.json` (one PreToolUse entry), `docs/manager/MANAGER.md`
  (5.4: one step, "(c2)"), `docs/manager/OPERATIONS.md` (post-merge step), `docs/tools/vault-projection.md` (new section),
  `docs/tasks/052-verify.sh`. All tests live inside `052-verify.sh` (the declared scope names no test files).
- Evidence per AC (all from `docs/tasks/052-verify.sh --mutate`, run in a FRESH CLONE of the branch at 40d19d0, exit 0, 93 `ok:` lines, no `FAIL`):
  - AC1: 16 `ok: AC1 ...` lines: other-branch commit writes nothing and the hook is silent; task commit writes exactly `Tasks/060.md`;
    a real `git pull` writes Gotchas.md/Status.md; the fetch-into-unchecked-out-main gap writes nothing; `refresh-main.sh` works with main
    checked out in a worktree (run from a task worktree) and with main checked out nowhere.
  - AC1b: 11 `ok: AC1b` lines: byte-identical pin, `pinned_commit`, stale warning on pull and on task commit, pin not replaced silently,
    re-pin by `refresh-main.sh`, warning gone.
  - AC2: 11 `ok: AC2` lines (test-mode and non-test-mode unconfigured; broken vault: stderr + non-zero when the hook is run directly;
    `git commit` itself still exits 0 because git ignores post-commit).
  - AC3: installer adds exactly 4 files under the git dir, touches no working tree or other repo, refuses a foreign hook (nothing else installed),
    idempotent, and refuses a git dir outside the temp dir in test mode (checked with TMPDIR pointed at a different temp dir).
  - AC4: 27 fixtures, every one in the spec's list, plus extras (sibling-prefix path, Write without path, wrapper without its python half).
    The drive-letter forms run against a temp config holding `D:\WomVault` with the test-only `WOM_GUARD_MNT_ROOT` (a directory under TMPDIR)
    in place of `/mnt`, so no real drive mount is looked at; a pure-function check proves `D:\a\B` -> `/mnt/d/a/B`.
  - AC5: valid JSON, matcher has all four tools, command resolves to an existing executable file, git mode 100755.
  - AC6: control green, then 8 mutants killed (casefold, realpath, fail-closed match, branch filter, installer test-mode refusal,
    installer foreign-hook refusal, stale warning in post-commit and in post-merge). Two mutants initially SURVIVED (fail-closed was an
    equivalent code path; the stale warning was only tested via post-merge); I changed the code anchor and added a test rather than weakening anything.
- Output tail (fresh clone, `docs/tasks/052-verify.sh --mutate`):
```
== AC6: mutation run (the unmutated copy must be green; each mutant must turn the matching checks red)
ok: control (unmutated copy) is green
ok: mutant 'casefold' killed -> FAIL: AC4 upper-case variant (wanted exit 2, got 0: );FAIL: AC4 lower-case variant (wanted exit 2, got 0: );FAIL: AC4 D:\ path, other case (wanted exit 2, got 0: );
ok: mutant 'realpath' killed -> FAIL: AC4 symlink into the vault (wanted exit 2, got 0: );
ok: mutant 'fail-closed' killed -> FAIL: AC4 configured-but-missing vault: a path under it (wanted exit 2, got 0: );FAIL: AC4 configured-but-missing vault: upper-case variant (wanted exit 2, got 0: );
ok: mutant 'branch-filter' killed -> FAIL: AC1 and the hook is silent there;
ok: mutant 'installer-refusal' killed -> FAIL: AC3 test mode refuses a git dir not under the temp dir (exit non-zero);FAIL: AC3 ...saying so;FAIL: AC3 ...and wrote nothing;
ok: mutant 'installer-nonwom' killed -> FAIL: AC3 an existing non-WoM hook makes the installer exit non-zero;FAIL: AC3 ...naming the file;FAIL: AC3 ...the foreign hook is untouched;
ok: mutant 'stale-warning-merge' killed -> FAIL: AC1b after a new tools/vault commit the hook warns pinned copy is stale;
ok: mutant 'stale-warning' killed -> FAIL: AC1b a task commit while stale also warns;
== 052-verify: ALL CHECKS PASSED
exit=0
```
- Regression: `PYTHONDONTWRITEBYTECODE=1 docs/tasks/053-verify.sh` (re-runs 051-verify.sh): `== 051-verify: ALL CHECKS PASSED`, `== 053-verify: ALL CHECKS PASSED`.
  051's "a drive-mount path is committed" check initially tripped on my docs (a literal `/mnt/d/` in vault-projection.md); I reworded the docs, not the check.
- Findings outside scope: `tests/adr/__pycache__/*.pyc` and `tools/adr/__pycache__/*.pyc` are TRACKED on main (not mine, not touched). 052-verify.sh checks only its own scope.
- Design notes: the guard blocks a path inside EITHER `WOM_VAULT` or the config-file vault (union), so an env var cannot hide the configured vault.
  `python3 -I` ignores `PYTHONDONTWRITEBYTECODE`, so the verify script uses `-B` (found because a `__pycache__` appeared in `.claude/hooks/`).
  The hook's staleness check uses `git log -1 --format=%H main -- tools/vault/` from the worktree; if main is unreadable it prints "staleness unknown" instead of staying silent.

## Questions
- Q1 (non-blocking): the guard stats the configured vault path (`os.path.isdir`) on every Write/Edit call. If the vault is on a slow or sleeping drvfs mount this adds a stat per call; accepted as cheap. Say if you want a cache.
- Q2 (non-blocking): the verify script's test-only `WOM_GUARD_MNT_ROOT` knob exists only to avoid touching /mnt/d in tests; it is honoured only with `WOM_VAULT_TEST=1` and a root under TMPDIR. Alternative would be to drop the D:\ end-to-end fixtures and keep only the pure-function check. Lean: keep.

## Task 052 fix round 1 (review finding: the guard failed open)
- Cause: only exit 2 blocks; `vault-guard.sh` ended in `exec python3`, `configured_vaults()` caught only `FileNotFoundError`, `main()` had no catch-all.
- Step 1, fixtures first, run against the OLD code (all red):
```
FAIL: AC4 unreadable vault-path file (vault configured but broken) (wanted exit 2, got 1: Traceback ...
FAIL: AC4 unreadable vault-path file: even a repo path is blocked (cannot tell where the vault is) (wanted exit 2, got 1 ...
FAIL: AC4 non-UTF-8 vault-path file (wanted exit 2, got 1: Traceback ...
FAIL: AC4 non-UTF-8 vault-path file: a repo path is blocked too (wanted exit 2, got 1 ...
FAIL: AC4 injected crash exited 1, not 2 (the python half must catch everything)
FAIL: AC4 injected crash through the wrapper exited 1, not 2
FAIL: AC4 python3 missing exited 127, not 2
```
- Step 2, fix: wrapper has no `exec`, checks `command -v python3`, maps any status other than 0/2 to 2; `main()` is wrapped by a catch-all (`guarded_main`) returning 2.
- Decision (config exists but unreadable or garbled): it counts as configured-but-broken, NOT unconfigured. The vault location is unknown, so I block every call of the four file tools, with a message naming the cause and the recovery line. Narrower options ("block only under determinable vaults") cannot protect the unknown vault, and the recovery path (delete the file) stays available through Bash. An empty file or a multi-line file is treated the same, matching 051's "exactly one line" rule.
- Step 3/4: new mutants catch-all, exec, status-map, broken-config, branch-filter-merge, all killed; a new fixture (guard exiting 1 mapped to 2) and a post-merge-on-non-main test were added. Existing checks untouched.
- Fresh-clone tail after the fix (exit 0, 109 ok lines):
```
ok: no bytecode is tracked in this task's scope
== AC6: mutation run (the unmutated copy must be green; each mutant must turn the matching checks red)
ok: control (unmutated copy) is green
ok: mutant 'casefold' killed -> FAIL: AC4 upper-case variant (wanted exit 2, got 0: );FAIL: AC4 lower-case variant (wanted exit 2, got 0: );FAIL: AC4 D:\ path, other case
ok: mutant 'realpath' killed -> FAIL: AC4 symlink into the vault (wanted exit 2, got 0: );
ok: mutant 'fail-closed' killed -> FAIL: AC4 configured-but-missing vault: a path under it (wanted exit 2, got 0: );FAIL: AC4 configured-but-missing vault: upper-case var
ok: mutant 'catch-all' killed -> FAIL: AC4 injected crash exited 1, not 2 (the python half must catch everything);
ok: mutant 'exec' killed -> FAIL: AC4 a guard exiting 1 reached the caller as 1, not 2;
ok: mutant 'status-map' killed -> FAIL: AC4 a guard exiting 1 reached the caller as 1, not 2;
ok: mutant 'broken-config' killed -> FAIL: AC4 unreadable vault-path file (vault configured but broken) (wanted exit 2, got 0: );FAIL: AC4 unreadable vault-path file: eve
ok: mutant 'branch-filter-merge' killed -> FAIL: AC1 post-merge on a non-main branch writes nothing;FAIL: AC1 ...and is silent;
ok: mutant 'branch-filter' killed -> FAIL: AC1 and the hook is silent there;
ok: mutant 'installer-refusal' killed -> FAIL: AC3 test mode refuses a git dir not under the temp dir (exit non-zero);FAIL: AC3 ...saying so;FAIL: AC3 ...and wrote nothin
ok: mutant 'installer-nonwom' killed -> FAIL: AC3 an existing non-WoM hook makes the installer exit non-zero;FAIL: AC3 ...naming the file;FAIL: AC3 ...the foreign hook is
ok: mutant 'stale-warning-merge' killed -> FAIL: AC1b after a new tools/vault commit the hook warns pinned copy is stale;
ok: mutant 'stale-warning' killed -> FAIL: AC1b a task commit while stale also warns;
== 052-verify: ALL CHECKS PASSED
```
