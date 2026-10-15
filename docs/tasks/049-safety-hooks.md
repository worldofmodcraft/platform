# Task 049: Mechanical enforcement of the git rules WoM already has (bash PreToolUse hook) and the per-subagent log-entry check

- **Mission:** tooling (task 047, part B, plus Q6) — **Status:** review (manager, 2026-10-15, after independent spec review rounds 2–3; merge requires Ludwig, §7) 
- **Agent / model:** implementer / per agent frontmatter (ROUTING.md)
- **Budget:** medium (two small scripts, a fixture set, a verify script with mutations)
- **Branch / worktree:** task/049-safety-hooks / ~/wt/task-049
- **Sequencing:** after 052 and 048 are merged (052 and 048 both edit `.claude/settings.json`). Order **052 → 048 → 049**, never parallel.
- **Merge authority:** a command-security control, so **Ludwig approves the merge (§7)**. His live check (AC9) is a condition of "done".

## Objective
Three things exist that do not today:
1. A PreToolUse hook on the Bash tool that refuses, before they run, `--force` pushes, commits on main,
   `git reset --hard` and `rm -rf`, for the main session and every subagent. `git branch -D` is refused
   for subagents and allowed for the main session. It also refuses an agent's Bash command that mentions the
   configured vault (`$WOM_VAULT`), closing the gap 052 documented.
2. `tools/manager/check-log-entry.sh`, which the manager runs after every subagent to check that the task
   log got a new dated entry (Q6 ★B; replaces a handover file).
3. For each of the above, fixtures piped as JSON and a mutation-tested verify script (`049-verify.sh`).

## Decisions encoded
- **Q1 ★B:** block `--force`, commits on main, `reset --hard`, `rm -rf`. Allow `branch -D` for the main
  session only, using hook input `agent_type`, which is present inside subagents (official docs, verified
  2026-10-14). **No commit-on-red test gate** (it collides with §2c rule 5, which requires the breaking
  fixture to be written and shown failing before the fix; WoM also has no single "the suite", and
  OPERATIONS.md records `006-verify.sh` as red on main by design). Arcane's `block-destructive.ps1`
  is the functional reference; `test-gate.ps1` is not adopted.
- **Q1 addition:** agents' Bash writes into `$WOM_VAULT` (052 AC8's known gap).
- **Q6 ★B:** no handover file; a script checks for a new dated log entry.

## Verified facts and caveats
- **Official docs (2026-10-14, claude-code-guide):** exit code 2 from a PreToolUse hook blocks the call;
  settings-file hooks fire for subagents' tool calls; a **missing hook script is a non-blocking error**, so
  the hook fails open (AC6 exists because of that); hook input carries `agent_type` inside subagents.
- **Unverified (§3.6b), confirmed by AC9:** (a) that `agent_type` is **absent** (not empty, not "main") in
  the main session. The design treats "key absent" as the main session and any present key, even empty, as a
  subagent. Consequence if wrong: a main session that carries an `agent_type` (for example one started with
  `--agent`) loses `branch -D`; it can still be done by Ludwig in his terminal. (b) That the hook process
  inherits `WOM_VAULT`; the design does not rely on it, it reads `~/.config/wom/vault-path` as 052 does.
- **Measured here:** `jq` is not installed on this machine (`which jq` empty, 2026-10-14); `python3` is. So
  `git-guard.sh` is a bash entry point that calls `git_guard.py` for JSON and parsing, the same shape as
  052's `vault-guard.sh` + `vault_guard.py`. Boring over clever (ADR-0103).

## Context to load (exhaustive)
- ADRs (INDEX.json lookup 2026-10-14): 0056 English everywhere, 0103 boring and restartable, 0115 measure
  outcomes (count blocks and skips with reasons), 0116 ADR compliance gates, 0117 dependency graph and contracts.
- Files: `docs/manager/MANAGER.md` §2c, §3.2, §3.7, §3.9, §6; `docs/manager/OPERATIONS.md`;
  `docs/tasks/052-vault-triggers-and-guard.md` and its `.claude/hooks/vault-guard.sh` / `vault_guard.py`
  (once merged: the shape to follow, and the settings entry to sit beside); `docs/tasks/047-arcane-practices.md`.
- Arcane reference (read in place; untracked, never copied into git):
  `~/wom/docs/tasks/inbox/arcane-reference/hooks/block-destructive.ps1`, `common.ps1`, `hooks/README.md`.

## Size
Source files: 3 (`git-guard.sh`, `git_guard.py`, `check-log-entry.sh`) plus `.claude/settings.json` = 4, within
5. Changed source lines expected well under 300 (estimate; the verify script and fixtures are excluded).
Reading list: 9, within 10. No justification needed.

## Design

### A. `git-guard` (PreToolUse, matcher `Bash`)
Input is JSON on stdin: `tool_name`, `tool_input.command`, `cwd`, and `agent_type` when inside a subagent.
Output: exit 0 allow; exit 2 block with a one-line reason on stderr naming the rule. **Fail closed, and
only exit 2 blocks in Claude Code (any other non-zero code is a non-blocking error, i.e. fail-open).**
`git-guard.sh` therefore runs `git_guard.py` and exits 2 on **any** result other than a clean exit 0 (allow) or a
clean exit 2 (block): a crash, a traceback, exit 1, a signal, a timeout, a missing `git_guard.py`, a
non-executable one, or no `python3`. Inside the .py, invalid JSON, a missing `command` field on a Bash call, or
any exception → exit 2. A "no match" must be a positive result, never an exception swallowed.
Every decision appends one line (`ts rule decision agent_type|main`) to `~/.config/wom/git-guard.log`, so
blocks and allows are counted, not assumed (ADR-0115). A log-write failure is reported on stderr and never
turns a block into an allow.

**Rules.** **Parsing is quote-aware** (a small shell-aware tokenizer, not a regex over the raw string). The command is
split into simple commands on unquoted `;`, `&&`, `||`, `|`, `&`, newlines, and into the bodies of `$(...)`,
backticks, `( )` subshells, `{ }`, and the string arguments of `bash -c`, `sh -c`, `eval`. Separators and
keywords **inside single or double quotes, in a heredoc body, or in a comment are text, not commands**. Each
simple command is tokenised with `shlex`, so `"git"`, `'rm'` and `"--force"` are normalised to their unquoted
words. Wrappers stripped before finding the program: `env [VAR=x ...]`, bare `VAR=x` assignments, `command`,
`sudo`, `nohup`, `time`, `timeout <dur>`, `exec`, `nice`, a leading backslash (`\git`), a path prefix
(`/bin/rm`), and `xargs [opts] <program>` (the program after xargs is checked as if run directly). Git global
options before the subcommand (`-C dir`, `-c k=v`, `--git-dir=...`, `--work-tree=...`) are skipped when finding
the subcommand. **Long options match by unambiguous prefix**, as git and GNU rm do (`--forc`, `--forc-with`,
`--har`, `--recurs`). **Git aliases:** a `-c alias.NAME=...` option, or a `git config ... alias.NAME` earlier in
the same command, makes `NAME` an alias; a later `git NAME` is judged on the alias body. Aliases defined in a
config file by an earlier command are a known gap.
1. **force push:** `git push` with any of `--force`, `--force-with-lease`, `--force-if-includes`, a short
   flag cluster containing `f`, or a refspec starting with `+`. Blocked for everyone. (MANAGER.md §3.7:
   "`--force` anything".)
2. **reset --hard:** `git reset` with `--hard`. Blocked for everyone.
3. **rm -rf:** `rm` with a recursive flag (`-r`, `-R`, `--recursive`, or a cluster containing r/R) **and** a
   force flag (`-f`, `--force`, or a cluster containing f), in any order, split or clustered, e.g. `-rf`,
   `-fr`, `-r -f`, `--recursive --force`. Blocked for everyone, whatever the target. (Deleting a worktree
   goes through `git worktree remove`, which is not blocked; MANAGER.md §6. Sanctioned alternatives to
   `rm -rf`, named in the docs and in the block message: `rm -r dir` (no force flag), `rm -f file`, `git
   worktree remove`, and for scratch data a `mktemp -d` directory removed with `rm -r`.)
4. **commit on main:** `git commit` (`merge`, `cherry-pick` and `revert` are **not** covered, see
   Known gaps) when the effective directory's current branch is `main` or `master`. The effective directory
   is `-C <dir>` if given, else the `cd <dir>` of an earlier segment in the same command, else `cwd`. The
   branch is read **directly from the repository's `HEAD` file** (resolved with `git rev-parse --git-dir` run
   with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null`, so no user or repo config, alias or hook
   can change the answer), honouring `--git-dir` given in the command. An agent-environment `GIT_DIR` is a known gap. Detached HEAD or a non-repo directory →
   allow, logged with the reason. A command that switches branch and commits in one line is judged on the
   branch at hook time, which is still main, so it is blocked; the agent runs the switch separately (Arcane
   documents the same).
5. **`git branch -D`** (also `-d -f`, `-df`, `-fd`, `--delete --force`, `--force --delete`): blocked when
   `agent_type` is present in the input; **allowed** when it is absent **or JSON `null`** (the main session). The
   direction is deliberate: absent means main, anything else means subagent. A wrong assumption (a main session
   that carries `agent_type`) costs the manager `branch -D`, and never gives it to an agent. Allowed because §6 requires
   deleting a derailed task's unmerged branch.
6. **Vault, for agents only:** when `agent_type` is present and the command text mentions the vault, block.
   "Mentions" means a case-folded substring match of any of: the literal `$WOM_VAULT` / `${WOM_VAULT}`, the
   path in `$WOM_VAULT`, the path in `~/.config/wom/vault-path`, and its `D:\`, `D:/` and `/mnt/d/` renderings.
   Reads are blocked too: a text match cannot tell a read from a write, and agents have no need of the vault.
   The main session is exempt, because `refresh-main.sh` and the manager's own steps use it. Vault not
   configured → rule 6 is skipped and the skip is counted in the log with the reason `vault-unconfigured`.

**Recovery if the hook bricks Bash** (documented, exact commands): the agent's Bash is unusable, but Ludwig's
terminal is not covered by hooks. He runs `cd ~/wom && git checkout -- .claude/settings.json` (or deletes the
`git-guard` PreToolUse entry with any editor) and restarts the session.

**Known gaps, documented, not fixed here** (they go in `docs/tools/git-guard.md`, section "Known gaps"):
shell input that reaches a shell without being in the command string (`bash <<EOF ... EOF`, `cat <<EOF | bash`, `curl ... | sh`); shell indirection that hides the command or path (variables, `eval` of a string built at run time, `python -c`,
aliases or functions defined in config files or earlier commands, wrappers other than the list above, a script
file that contains `rm -rf`, `find -delete`, `git clean -fdx`, `git checkout -- .`, `git push` with
`--mirror`/`--delete`); `git merge`, `cherry-pick` and `revert` on main; `cd` into the vault followed by a
relative-path write; `GIT_DIR` set in the environment; Windows path spellings beyond the `D:\`, `D:/` and
`/mnt/d/` forms. The hook is a seat belt against the mistakes that have happened, not a sandbox.

**Recovery** (documented in `docs/tools/git-guard.md`, exact commands): Ludwig can run any blocked command in
his own terminal (hooks apply to agent tool calls, not to his shell). To disable the hook he removes its entry
from `.claude/settings.json` through a normal task; there is no env-var off switch, because one would be
available to an agent.

### B. `tools/manager/check-log-entry.sh`
Interface: `check-log-entry.sh count <task-file>` prints the number of dated log entries; `check-log-entry.sh
check <task-file> <baseline-count>` exits 0 only if the count is greater than the baseline **and** the last
dated entry's date is valid and not in the future. A *dated entry* is a line, after the line `# Task NNN log`
(or the first line starting with `# Task` and containing `log`), matching `^- 20[0-9]{2}-[0-9]{2}-[0-9]{2}`
(the existing logs use `- YYYY-MM-DD ...`). Exit 1 = no new entry; exit 2 = usage error, unreadable file or
no log section (a task file with no log section is a failure, never "zero new entries, fine"). The manager
procedure: `count` before delegating, `check` after the report-back; the numbers go in the task log (MANAGER.md
§5, text written by task 048).

### C. Wiring
`.claude/settings.json`: one PreToolUse entry, matcher `Bash`, command
`"$CLAUDE_PROJECT_DIR"/.claude/hooks/git-guard.sh`, beside 052's entry and 048's `env`. Nothing else in the file changes.

## File scope (declared)
`.claude/hooks/git-guard.sh`, `.claude/hooks/git_guard.py`, `tools/manager/check-log-entry.sh`,
`.claude/settings.json` (one PreToolUse entry), `docs/tools/git-guard.md` (new: rules, known gaps, recovery,
log format), `docs/manager/OPERATIONS.md` (one section: how to read `git-guard.log`, and the per-subagent
`check-log-entry.sh` step), `docs/tasks/049-verify.sh`, `docs/tasks/049-fixtures/` (JSON fixtures and the
temp-repo builder), this file's log.

## Acceptance criteria
Script-verified by `docs/tasks/049-verify.sh` (output pasted in the log) unless marked **live**. Each
fixture is a JSON document piped to `git-guard.sh` exactly as Claude Code would send it, and the script
asserts both exit code and the rule named on stderr.
1. **Each block fires**, one fixture each, exit 2 with the rule name: `git push --force origin x`;
   `git push -f`; `git push --force-with-lease`; `git push origin +main`; `git reset --hard HEAD~1`;
   `rm -rf /tmp/x`; `rm -fr x`; `rm -r -f x`; `rm --recursive --force x`; `/bin/rm -rf x`;
   a commit with `cwd` on a temp repo's `main`; the same via `git -C <main-repo> commit` from another cwd;
   via `cd <main-repo> && git commit`; `bash -c "git push --force"`; a chained `echo x; git reset --hard`.
1b. **Bypass fixtures, each must be blocked (exit 2), one fixture per item, and each has its own mutation in
   AC8 (remove that one strip or rule and watch it redden):** wrappers `env X=1 git push --force`, bare
   `X=1 git push -f`, `command git push -f`, `sudo rm -rf x`, `\git reset --hard`, and `nohup`, `time`,
   `timeout 5`, `exec` each in front of a blocked command, plus `xargs rm -rf` and `echo x | xargs git push
   --force`; quoting `"git" push --force`, `'rm' -rf x`, `git push "--force"`; substitution and nesting
   `$(git reset --hard)`, a backtick form, `(git reset --hard)`, `{ rm -rf x; }`, `eval "rm -rf x"`; git options
   `git -c user.name=x push --force`, `git --git-dir=/tmp/r.git reset --hard`; newline separation (`echo a`, LF,
   `rm -rf x`); abbreviations `git push --forc`, `git reset --har`, `rm --recurs --forc x`; aliases `git -c
   alias.p='push --force' p`, and `git config alias.p 'reset --hard' && git p`. Any bypass not handled is moved
   to Known gaps before the task is done; none may be absent from both places.
2. **Each allow holds (positive controls, so the suite cannot pass by blocking everything):** `git push
   origin task/049-x`; `git reset --soft HEAD~1`; `rm file`; `rm -r dir`; `rm -f file`; `git worktree remove
   ../wt/task-1`; a commit with `cwd` on a `task/NNN-x` branch of the temp repo; a commit in a detached HEAD
   (allowed, reason logged); `git status`; `echo "rm -rf is dangerous"` (the text is an argument to `echo`,
   not a command; allowed).
2b. **Quote-aware false positives, each must be allowed (exit 0):** `echo "a; rm -rf x"`; `echo 'git push
   --force'`; a heredoc whose body has lines `rm -rf x` and `git push --force` (`cat <<'EOF' ... EOF`);
   `git commit -m "document why git push --force is banned"` on a task branch; `grep -- --force file`;
   `grep -rn "rm -rf" docs/`; a `# rm -rf x` comment line; `git log --grep=--hard`. Mutation: replace the
   quote-aware splitter by a split on the raw string; at least one of these must redden.
3. **`branch -D` split on `agent_type`:** the same `git branch -D task/x` fixture gives exit 0 without
   `agent_type`, exit 2 with `"agent_type": "implementer"`, and exit 2 with `"agent_type": ""` (present
   but empty counts as a subagent); exit 0 with `"agent_type": null` (null counts as absent). `git branch -d task/x` (lower-case, safe delete) is allowed for both.
4. **Vault rule:** with a temp vault path configured through a temp `~/.config/wom/vault-path` (test mode
   sets `HOME` to a temp dir): an agent command that contains the path, the `D:\`, `D:/` and `/mnt/d/`
   forms, a case variant, and the literal `$WOM_VAULT` → exit 2; the same commands without `agent_type` →
   exit 0; an agent command not mentioning the vault → exit 0; unconfigured → exit 0 and a
   `vault-unconfigured` line in the log.
5. **Fail closed:** invalid JSON, empty stdin, a Bash call with no `command` → exit 2. An unwritable log
   location does not turn a block into an allow. **Wrapper fixtures:** with `git_guard.py` replaced by a
   script that exits 1, one that raises a traceback, one killed by a signal, a missing file, a non-executable
   file, and with `python3` absent from `PATH`, `git-guard.sh` exits 2 every time. Mutation: make the wrapper
   pass the .py's exit code through; each of these must redden.
6. **Wiring:** `.claude/settings.json` is valid JSON; a PreToolUse entry with matcher `Bash` names a command
   path that exists and is executable; 052's and 048's entries are still present (positive controls). The
   hook is run through the exact command string from the settings file, not by calling the script directly.
7. **`check-log-entry.sh`:** `count` on a fixture log returns the known number; `check` is 0 after an entry
   is appended with today's date; 1 when nothing was appended; 1 when only an undated line was appended;
   1 when the new entry's date is in the future; 2 on a task file with no log section; 2 on a missing file.
8. **Mutation proof.** `049-verify.sh --mutate` applies each mutation in the table below to a scratch copy,
   runs the suite, and requires **exactly the named check group to go red** (a mutation that reddens nothing,
   or only an unrelated group, fails the run). The tree is restored after each. The unmodified tree passes
   (positive controls included), the script passes in a fresh clone (§2c rule 4), and a pattern that matches
   nothing is a failure (§2c rule 1). Group names are the fixture ids in `049-fixtures/`.

   | Fixture group | Mutation (named, scripted) | Expected red |
   |---|---|---|
   | AC1 `push --force`, `-f`, `--force-with-lease` | delete the force-flag clause for the long form / for the short cluster (two mutations) | AC1 force |
   | AC1 `push +main` | delete the `+refspec` clause | AC1 force |
   | AC1 `reset --hard` | delete rule 2 | AC1 reset |
   | AC1 `rm -rf`, `rm -fr` | delete the flag-cluster branch of rule 3 | AC1 rm |
   | AC1 `rm -r -f`, `rm --recursive --force` | require the flags in one token / drop the long forms (two mutations) | AC1 rm |
   | AC1 `/bin/rm -rf` | drop the path-prefix strip | AC1 rm, AC1b |
   | AC1 commit on main via `cwd` | make the branch lookup return "task" always | AC1 main |
   | AC1 `git -C <main> commit` from another cwd | ignore `-C` when choosing the effective directory (use `cwd`) | AC1 -C |
   | AC1 `cd <main> && git commit` | ignore earlier `cd` segments | AC1 cd |
   | AC1 `bash -c "..."`, chained `; ` | do not recurse into `-c` strings / do not split on `;` (two mutations) | AC1 -c, AC1 chain |
   | AC1b `env X=1 git ...` | remove only the `env` strip, keeping bare-assignment handling | AC1b env (the bare `X=1` fixture stays green, proving the strips are independent) |
   | AC1b bare `X=1 git ...` | remove only the bare-assignment strip, keeping `env` | AC1b bare (the `env` fixture stays green) |
   | AC1b `command`, `sudo`, `nohup`, `time`, `timeout`, `exec` | remove each wrapper from the strip list (one mutation each) | the matching wrapper fixture only |
   | AC1b `xargs ...` | drop xargs handling | AC1b xargs |
   | AC1b `\git`, `"git"`, `'rm'`, `"--force"` | **replace `shlex` with `str.split`** (one mutation reddens all four); plus a mutation that keeps shlex but keeps a leading backslash | AC1b shlex-forms |
   | AC1b `$(...)` | do not descend into `$(` bodies | AC1b subst |
   | AC1b backticks | do not descend into backticks | AC1b backtick |
   | AC1b `( )` subshell | do not descend into `( )` | AC1b subshell |
   | AC1b `{ ...; }` | do not descend into `{ }` | AC1b brace |
   | AC1b `eval "..."` | do not scan `eval` arguments | AC1b eval |
   | AC1b `git -c k=v push --force` | do not skip `-c k=v` when finding the subcommand | AC1b -c |
   | AC1b `--git-dir=...` | do not skip `--git-dir=` | AC1b git-dir |
   | AC1b newline separation | do not split on newlines | AC1b newline |
   | AC1b `--forc`, `--har`, `--recurs --forc` | require exact long-option names | AC1b abbreviations |
   | AC1b `-c alias.p=...` | ignore `alias.` options / do not resolve the alias | AC1b alias-c |
   | AC1b `git config alias.p ... && git p` | ignore a same-command `git config alias.` | AC1b alias-config |
   | AC2 positive controls (`rm -r`, `rm -f`, `reset --soft`, task-branch commit, detached HEAD, `git status`, `echo "rm -rf ..."`) | make the hook block everything (`exit 2` first) | every AC2 fixture |
   | AC2b `echo "a; rm -rf x"` | split on the raw string instead of quote-aware | AC2b quote-sep |
   | AC2b `echo 'git push --force'` | match the raw string with a regex | AC2b quote-text |
   | AC2b heredoc body | treat heredoc bodies as commands | AC2b heredoc |
   | AC2b `git commit -m "...git push --force..."` | scan quoted arguments of other programs | AC2b commit-msg |
   | AC2b `grep -- --force`, `grep -rn "rm -rf" docs/`, `git log --grep=--hard` | scan the arguments of non-git, non-rm programs | AC2b grep (the three share one splitter flaw: each is its own fixture and all three redden) |
   | AC2b `# rm -rf x` comment | do not strip comments | AC2b comment |
   | AC3 `branch -D` main / subagent | invert the `agent_type` test | AC3 both directions |
   | AC3 `"agent_type": ""` | treat empty as absent | AC3 empty |
   | AC3 `"agent_type": null` | treat null as present | AC3 null |
   | AC3 `branch -d` | extend rule 5 to lower-case `-d` | AC3 safe-delete |
   | AC4 vault: path, `D:\`, `D:/`, `/mnt/d/` | drop each rendering from the match list (four mutations) | the matching AC4 form |
   | AC4 case variant | drop the case-folding | AC4 case |
   | AC4 literal `$WOM_VAULT` | drop the literal match | AC4 literal |
   | AC4 main session exempt | apply rule 6 without the `agent_type` test | AC4 exempt |
   | AC4 unconfigured | make unconfigured block / skip the log line (two mutations) | AC4 unconfigured |
   | AC5 invalid JSON, empty stdin | make invalid JSON / empty input exit 0 (two mutations) | AC5 json, AC5 empty |
   | AC5 Bash call with no `command` | treat a missing command as allow | AC5 no-command |
   | AC5 unwritable log | let a log failure turn a block into an allow | AC5 log |
   | AC5 wrapper: crash, traceback, signal, missing, non-executable, no python3 | make the wrapper pass the .py's exit code through; separately, treat a missing .py as allow | AC5 wrapper (each case), AC6 for the missing file |
   | AC6 wiring | delete the hook file after wiring; separately, remove the `Bash` matcher | AC6 exists, AC6 matcher |
   | AC7 `count` | miscount by skipping the first entry | AC7 count |
   | AC7 `check` appended / nothing appended | make `check` ignore the baseline | AC7 baseline |
   | AC7 undated line appended | accept any `- ` line | AC7 undated |
   | AC7 future date | drop the date-in-the-future test | AC7 future |
   | AC7 no log section | treat a missing section as count 0 / success | AC7 no-section |
   | AC7 missing file | exit 0 on an unreadable file | AC7 missing-file |

9. **Live, in a fresh session, after merge (manager + Ludwig):** (i) a real Bash call of `git push --force`
   from the manager session is refused with the denial shown, and `git branch -D` on a scratch branch is
   allowed from the manager; (ii) the same `branch -D` attempted by a probe implementer is refused — this
   settles unverified (a); (iii) a probe implementer's Bash command mentioning the vault is refused. If (i)
   or (ii) shows `agent_type` behaving differently from the design, the task reopens before "done". The log
   states plainly that AC9 is not script-verified.
10. **Docs moved with code:** `docs/tools/git-guard.md` exists and lists the six rules, the known gaps and the
    recovery commands; every path it cites exists (§8b.5); OPERATIONS.md has the two new sections.

## Forbidden here
- A commit-on-red test gate, or any hook that runs a test suite (Q1 ★B excludes it; §2c rule 5).
- An env-var, file-flag or other off-switch that an agent could set. Recovery is Ludwig's terminal or a task.
- Making `branch -D` allowed for subagents, or blocking it for the main session.
- Treating a hook as covering what the Known gaps list excludes; the docs say so in plain words.
- A wrapper that returns the python script's exit code unchanged: only a clean 0 or 2 may pass through.
- A regex over the raw command string as the matcher: it blocks quoted text (AC2b), which is what those
  fixtures are there to catch.
- Catch-and-ignore: a parser error is exit 2, not exit 0. A "no match" must be a positive result of the
  matcher, never an exception swallowed.
- Weakening a fixture to make the hook pass (§3.5). A hook rule that the fixtures cannot redden is not done.
- Reading or printing `~/.config/gh`, tokens or credentials while building fixtures (CLAUDE.md rule 11): the
  force-push fixtures are command strings only; nothing is ever executed against a remote.
- Running any blocked command for real to "test" it. Fixtures are piped JSON; the temp repo for the main-branch
  rule lives under a temp dir and the builder refuses any git dir outside it (as 052 AC3 does).
- Editing CLAUDE.md, MANAGER.md, `.claude/agents/` (task 048), the vault scripts (task 052), or installing
  anything into the real `~/wom/.git`.
- Copying Arcane's `.ps1` files into git; the reference is read in place.

## Dependency graph and sequencing
New node: `git-guard` (the Claude Code PreToolUse input contract on one side, the exit-code contract on the
other); it reads the vault path from `~/.config/wom/vault-path`, the same file 052's guard reads, so it adds one
edge to the existing vault-config contract and none to the projection generator. `check-log-entry.sh` reads
task files and adds no edge. The graph is not changed. Order **052 → 048 → 049**.

## Deliverables
The scripts, the fixtures, `049-verify.sh` with its real output and its `--mutate` output pasted in the log,
the docs, AC9's evidence once the live check is run, the log current.

## Questions  (agent-maintained; see MANAGER.md 8b)
- Q: Is `agent_type` absent in the main session? | options: A absent / B present with an empty or "main"
  value | assumed: A | built on assumption: rule 5 and the vault exemption in rule 6; closed by AC9(ii).
- Q: Should `git merge`, `cherry-pick` and `revert` on main be blocked too? Ludwig's list (Q1 ★B) names
  commits only. | options: A leave as documented gap / B add to rule 4 | assumed: A | built on assumption:
  the Known gaps list.

---
# Task 049 log  (append-only, updated continuously by the executing agent)
- 2026-10-14 manager: spec finalised from the drafts, task 047, task 052 and the Arcane `block-destructive.ps1`
  reference. Q1 ★B and Q6 ★B are Ludwig's answers. Not started; waits for 052 and 048 merged and the spec gate.
- 2026-10-15 implementer: built in worktree ~/wt/task-049 (from main with 048 and 052 merged). Not pushed. Ludwig lifted
  the token guard for this run. Nothing was activated for a live session; the hooks were only fed JSON fixtures.
- 2026-10-15 implementer: section 2c red stage, commit 53eda90. Fixtures (`049-fixtures/cases.jsonl`, 106 JSON cases, plus
  wrapper, log, wiring and `check-log-entry.sh` checks in `run_suite.py`) were written first against allow-everything
  stubs (`exit 0`). Result against the stubs: `TOTAL 151 checks, 109 red`; the positive controls were the 42 green ones.
  RED-GROUPS were: AC1-*, AC1b-* (all 31), AC3-*, AC4-* (blocking ones), AC5-*, AC6-*, AC7-* ... (full list in the commit's
  first run; every block-expecting group was red).
- 2026-10-15 implementer: implemented `git-guard.sh`, `git_guard.py`, `check-log-entry.sh`, wired `.claude/settings.json`
  (one PreToolUse entry, matcher `Bash`; the permission system allowed the edit), wrote `docs/tools/git-guard.md` and the
  OPERATIONS.md section. Commit a0fe6ec. First full run was green (151 checks, 0 red).
- 2026-10-15 implementer: mutation run found five survivors on the first pass and each was a real defect in the
  suite, fixed before the table was frozen: (1) `rm-long` survived because `--force` contains an `r`, so the cluster
  branch caught it: the cluster branch now excludes `--` options; (2) `no-command` survived because a crash on `None`
  also exits 2 (correct behaviour, so the mutation now makes the missing command an allow); (3) AC7 future-date fixture
  used the year 2999, which the spec's dated-line regex `20[0-9]{2}` never matches, so it passed for the wrong reason:
  fixture now 2099; (4) `undated` was redundantly caught by the date-validity test: the last date is now read only
  from a strictly dated line, so the two checks are independent; (5) `no-section` was caught twice by two die lines.
- 2026-10-15 implementer: DEVIATIONS from the spec text, each for a stated reason (none changes a rule):
  (a) AC8 says "exactly the named group goes red". For core-rule mutations that is impossible by construction, because the
  bypass fixtures (`env`, `sudo`, `bash -c`, ...) are the same command in a disguise: deleting the `--force` clause
  reddens every group whose fixture is a force push. The table pins the exact observed set, reviewed one by one; it is
  explained in `docs/tools/git-guard.md`, "Verification". (b) AC8's "delete the hook file after wiring" was replaced by
  "settings points at a missing file" (deleting the file reddens every group, which proves nothing about wiring).
  (c) AC8 "missing .py treated as allow" reddens AC5-wrapper-missing only (python3 exits 2 on a missing file anyway, so the
  mutation changes the wrapper's own `exit 2` to `exit 0`); the wrapper pass-through mutation reddens crash, traceback and
  signal only, the three pre-checks (missing, non-executable, no python3) have their own mutations. (d) AC1b `-c k=v` also
  reddens `alias-c`, because that fixture needs the skip. (e) The non-executable-file wrapper case needs an explicit
  `[ -x ]` check (python3 would run a 0644 script happily), so the wrapper has one. (f) Added beyond the spec: `nice`,
  `--git-dir <space>`, `-Rf`, `-fu`, `--force-if-includes`, `branch -vD`, `echo "$(...)"`, an indented `<<-` heredoc, a
  same-line `# ... ; rm -rf x` comment, a vault config that is present but unreadable (agents' Bash is refused, fail
  closed, the stance of 052), `nice`, and a LOG-lines check that every fixture's decision left a block/allow line.
- 2026-10-15 implementer: evidence at commit a0fe6ec, from a FRESH CLONE (`git clone` of the worktree, `checkout a0fe6ec`),
  `docs/tasks/049-verify.sh --mutate`, rc=0, 241 ok lines, 0 FAIL. Tails:
  `TOTAL 151 checks, 0 red` / `RED-GROUPS: ` (empty) / `== AC8: mutation run ...` / `ok: mutant validdate killed -> AC7-baddate` /
  `ok: mutant no-section killed -> AC7-no-section` / `ok: mutant missing-file killed -> AC7-missing-file` /
  `== 75 mutations, 0 problems` / `== 049-verify: ALL CHECKS PASSED`. The tree at the final HEAD differs from a0fe6ec
  only in this file; the final-HEAD fresh-clone run is repeated and reported in the hand-off message.
- 2026-10-15 implementer: AC status. AC1, AC1b, AC2, AC2b, AC3, AC4, AC5, AC6, AC7 and AC10: script-verified (group names
  `AC1-*` ... `AC7-*` in the run). AC8: `--mutate`, 75 mutants all killed with their expected sets. **AC9 is NOT
  script-verified**: it needs a fresh session after merge (Ludwig + manager); it settles the unverified assumption (a),
  that `agent_type` is absent in the main session. Unverified (b), that the hook inherits `WOM_VAULT`, is not relied on.
- 2026-10-15 implementer: OPEN ITEMS for the manager. (1) MANAGER.md section 5 still says `check-log-entry.sh` "does not exist
  until 049 merges"; editing MANAGER.md is outside this task's scope (Forbidden here), so the manager updates that sentence
  after merge. (2) The two Questions stay open (agent_type absent: closed by AC9; merge/cherry-pick/revert on main: left as a
  documented gap). (3) During testing a harness safety check refused a command of mine that contained a `rm -r "$HOME"` in a
  compound line; it did not run, I did not retry it, and I removed nothing outside `mktemp` directories I created.
  (4) Ludwig approves the merge (section 7: command-security control).
