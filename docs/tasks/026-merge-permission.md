# Task 026: Make the tool match the doctrine — allow the gh commands merge authority needs

- **Mission:** SITE-V1 (tooling) — **Status:** spec-approved (manager, 2026-09-03; Ludwig approved
  the change in session and asked for it to be noted in OPERATIONS.md)
- **Agent / model:** manager (configuration, no production code)
- **Budget:** small
- **Branch / worktree:** task/026-merge-permission / `~/wt/platform-task-026`
- **Graph:** tooling for the manager session; no SITE-V1 node or edge.

## Objective
The `gh` pull-request commands the manager's merge authority (MANAGER.md §7) actually requires are
allowed by a committed project permission rule, so the merge step of every task stops depending on
a per-call classifier decision. `OPERATIONS.md` records that the rule exists and why.

## Why
During task 022 a `gh pr merge` call was refused — `Blocked by classifier` — and then succeeded
unchanged on retry. Merge authority is already decided (MANAGER.md §7, Ludwig's answer Q2=A); the
rule does not grant new authority, it makes the tool agree with authority the doctrine already
gives. A merge step that fails intermittently is worse than one that fails always, because it
teaches a session to retry instead of to stop and ask.

## File scope (declared)
- `.claude/settings.json` (new — the project had none; only `.claude/agents/` existed)
- `docs/manager/OPERATIONS.md`
- `docs/tasks/026-merge-permission.md` (this file)

## Acceptance criteria
1. `.claude/settings.json` exists, is valid JSON, and allows exactly the six pull-request
   commands merge authority needs: `gh pr create`, `gh pr merge`, `gh pr view`, `gh pr list`,
   `gh pr diff`, `gh pr checks`.
2. **No broader `gh` grant.** In particular `gh api` is *not* allowlisted: it can change branch
   protection, delete repositories and rewrite settings, and it has never been refused, so there
   is no problem to solve and a real blast radius to avoid.
3. `OPERATIONS.md` records the rule, its scope, and the deliberate exclusion of `gh api`.

## Forbidden here
- Allowlisting `gh api`, `gh repo`, `git push`, or any wildcard broader than the six commands above.
- Disabling the permission system, changing `defaultMode`, or adding a `deny`-list exemption.
- Touching `.claude/agents/` — model routing is fixed there (ROUTING.md) and is not this task.

---
# Task 026 log

- 2026-09-03 **Syntax verified rather than recalled.** Claude Code's permission-rule syntax was
  read from the `update-config` skill's reference (prefix-wildcard form `Bash(git *)`) rather than
  written from memory, per MANAGER.md §3.6. **Both the space form (`Bash(gh pr merge *)`) and the
  colon form (`Bash(gh pr merge:*)`) are written**, because the two spellings appear in different
  places in Claude Code's own documentation and a permission rule that does not match fails
  *silently* — it simply never applies. Twelve entries, six commands, two spellings each. If one
  spelling is inert it costs nothing; if only one is correct, the rule still works.

```
$ python3 -c "import json;d=json.load(open('.claude/settings.json'));print('valid JSON,', len(d['permissions']['allow']), 'rules')"
valid JSON, 12 rules
```

- 2026-09-03 **Not verified in this session:** whether the rule actually suppresses the classifier
  refusal. Settings are read at session start, so proving it needs a session started after this
  merges. Recorded as an assumption rather than claimed as demonstrated (MANAGER.md §3.6), with the
  fallback noted in OPERATIONS.md: if a `gh pr merge` call is still refused in a later session,
  the next thing to try is an `autoMode.allow` entry, because the refusal came from the auto-mode
  classifier and not from a permission prompt.

**Status: criteria 1-3 done; criterion 1's effect on the classifier is an open assumption by
construction, stated above and in OPERATIONS.md.**
