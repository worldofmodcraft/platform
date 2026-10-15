# git-guard: command-safety hook for the Bash tool (task 049)

A PreToolUse hook that refuses, before they run, the git mistakes this project has already had to rule out
(MANAGER.md 3.7), for the main session and every subagent. It also refuses an agent's Bash command that mentions the
vault. Built by task 049 (`docs/tasks/049-safety-hooks.md`); verified by `docs/tasks/049-verify.sh`. It is a seat belt
against mistakes that have happened, **not a sandbox** (see Known gaps).

| Piece | Path |
|---|---|
| Entry point (the command in settings) | `.claude/hooks/git-guard.sh` |
| Parser and rules | `.claude/hooks/git_guard.py` |
| Wiring | `.claude/settings.json` (PreToolUse, matcher `Bash`) |
| Fixtures, runner, mutation table | `docs/tasks/049-fixtures/` |
| Per-subagent log-entry check (Q6) | `tools/manager/check-log-entry.sh` |

## Contract

Input on stdin: the Claude Code hook JSON (`tool_name`, `tool_input.command`, `cwd`, and `agent_type` inside a
subagent). Output: **exit 0 allows; exit 2 blocks** with one line on stderr naming the rule. Only exit 2 blocks in
Claude Code (any other non-zero status is a non-blocking error, that is, fail-open), so `git-guard.sh` runs
`git_guard.py` and turns **anything other than a clean 0 or a clean 2 into 2**: a crash, traceback, exit 1, a signal,
a missing or non-executable `git_guard.py`, or no `python3`. Inside the python half, invalid or empty JSON, a Bash
call with no `command` string, or any exception is also exit 2. A parse failure (for example an unbalanced quote) is
exit 2, never "allow".

`agent_type` is present in the hook input inside subagents. The design reads **absent or JSON null as the main session**
and any present key, even an empty string, as a subagent. This is unverified until AC9 (below).

## The six rules

The command is parsed quote-aware (a small scanner plus `shlex`), never matched with a regex over the raw string.
Separators (`;` `&&` `||` `|` `&` newline), the bodies of `$( )`, backticks, `( )`, `{ }`, `bash -c`/`sh -c` strings
and `eval` arguments are searched; separators and words inside quotes, heredoc bodies and comments are text.
Stripped before the program is found: `env [VAR=x]`, bare `VAR=x`, `command`, `sudo`, `nohup`, `time`,
`timeout DUR`, `exec`, `nice`, `xargs [opts]`, a leading backslash, a path prefix (`/bin/rm`). Git global options
(`-C dir`, `-c k=v`, `--git-dir`, `--work-tree`, ...) are skipped; long options match by unambiguous prefix
(`--forc`, `--har`, `--recurs`); a git alias from `-c alias.X=...` or an earlier `git config alias.X ...` in the same
command is judged on its body.

1. **force-push** (everyone): `git push` with `--force`, `--force-with-lease`, `--force-if-includes`, a short cluster
   containing `f`, or a refspec starting with `+`.
2. **reset-hard** (everyone): `git reset --hard`.
3. **rm-rf** (everyone): `rm` with a recursive flag (`-r`, `-R`, `--recursive`) and a force flag (`-f`, `--force`),
   in any order, split or clustered. Sanctioned alternatives: `rm -r DIR` (no force flag), `rm -f FILE`,
   `git worktree remove` (MANAGER.md 6), and for scratch data a `mktemp -d` directory removed with `rm -r`.
4. **commit-on-main** (everyone): `git commit` when the effective directory's branch is `main` or `master`. The
   directory is `-C dir`, else the `cd dir` of an earlier segment, else `cwd`. The branch is read from the repository's
   `HEAD` file, found with `git rev-parse --git-dir` run with no user or system config. Detached HEAD or a non-repo
   directory is allowed and logged (`commit-detached-head`, `commit-no-repo`). A command that switches branch and commits
   in one line is judged on the branch at hook time; run the switch separately.
5. **branch-D** (subagents only): `git branch -D`, also `-d -f`, `-df`, `-fd`, `--delete --force`, `--force --delete`.
   Allowed in the main session because MANAGER.md 6 requires deleting a derailed task's unmerged branch. Lower-case
   `-d` (safe delete) is allowed for both. The direction is deliberate: a wrong assumption about `agent_type` costs the
   manager `branch -D` and never gives it to an agent.
6. **vault** (subagents only): the command text mentions the vault, case-folded: the literal `$WOM_VAULT` or
   `${WOM_VAULT}`, the path in `$WOM_VAULT`, the path in `~/.config/wom/vault-path`, and for a drive path its `D:\`,
   `D:/` and `/mnt/d/` renderings. Reads are blocked too (a text match cannot tell read from write; agents have no need
   of the vault). The main session is exempt. Vault not configured: the rule is skipped and a `vault-unconfigured`
   line is logged. A vault config that exists but cannot be read is "configured but broken": agents' Bash is refused
   (fail closed), the same stance as task 052's file guard.

## Log

Every decision appends lines `TIMESTAMP RULE DECISION AGENT` to `~/.config/wom/git-guard.log`: `RULE` is the rule that
fired or `none`; `DECISION` is `block`, `allow` or `skip`; `AGENT` is the `agent_type` or `main`. Blocks and
allows are therefore counted, not assumed. A log-write failure is reported on stderr and never turns a block into an
allow. How to read it: `docs/manager/OPERATIONS.md`, "git-guard.log and check-log-entry.sh".

## Known gaps (documented, not fixed here)

The hook does **not** cover:

- shell input that reaches a shell without being in the command string: `bash <<EOF ... EOF`, `cat <<EOF | bash`,
  `curl ... | sh`; the body of an *unquoted* heredoc is not scanned for `$( )` either;
- indirection that hides the command or path: variables, `eval` of a string built at run time, `python -c`, aliases
  or functions defined in config files or earlier commands, wrappers other than those listed (for example
  `ssh host "git push --force"`), a script file that contains `rm -rf`, `find -delete`, `git clean -fdx`,
  `git checkout -- .`, `git push --mirror`/`--delete`;
- `git merge`, `cherry-pick` and `revert` on main (rule 4 covers `git commit` only);
- `cd` into the vault followed by a relative-path write;
- `GIT_DIR` set in the environment; Windows path spellings beyond `D:\`, `D:/` and `/mnt/d/`;
- a repository the hook's own user does not own (git refuses `rev-parse`, the hook sees "not a repo" and allows).

## Recovery

If the hook ever bricks Bash (the agent's Bash is unusable, Ludwig's terminal is not covered by hooks):

```
cd ~/wom && git checkout -- .claude/settings.json
```

or delete the `git-guard` PreToolUse entry with any editor, then restart the session. Ludwig can run any blocked command
in his own terminal. There is deliberately **no environment variable or flag file** that switches the hook off, because
an agent could set one; disabling it goes through a normal task.

## Verification

`docs/tasks/049-verify.sh` pipes about 110 JSON fixtures (`docs/tasks/049-fixtures/cases.jsonl`) into the hook and asserts
exit code, rule name and log line; `docs/tasks/049-verify.sh --mutate` breaks a scratch copy 75 ways
(`docs/tasks/049-fixtures/mutations.py`) and requires each mutant to turn exactly its listed check groups red.
Core-rule mutations (a force, rm or reset clause) legitimately redden every group whose fixture is that command in a
disguise (for example the `sudo`, `env` and `bash -c` fixtures all contain `git push --force`); those collateral groups
are part of the expected set. The test mode never executes a fixture command and never reads the real
`~/.config/wom`.

**AC9 is not script-verified.** After merge, in a fresh session, the manager and Ludwig confirm live: (i) a real
`git push --force` from the manager session is refused and `git branch -D` on a scratch branch is allowed; (ii) the
same `branch -D` by a probe implementer is refused (this settles that `agent_type` is absent in the main session);
(iii) a probe implementer's Bash command mentioning the vault is refused. If (i) or (ii) shows `agent_type` behaving
differently, the task reopens.
