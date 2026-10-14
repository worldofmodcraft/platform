# Task 049: Mechanical enforcement of the git rules WoM already has, as bash PreToolUse hooks

- **Mission:** tooling (task 047, part B) — **Status:** draft. Spec gate **not passed**: the block list depends on Ludwig's answer Q1.
- **Agent / model:** implementer / per agent frontmatter (ROUTING.md)
- **Budget:** small
- **Branch / worktree:** task/049-safety-hooks / ~/wt/task-049 (after 048: both touch `.claude/settings.json`)

## Objective (finalised once Q1 is answered)
Destructive or forbidden git and shell commands chosen by Ludwig are refused by a hook before they run,
for the main session and for every subagent. Each block is demonstrated, and each is mutation-tested
(§2c). Arcane's `block-destructive.ps1` is the functional reference; `test-gate.ps1` is not adopted
unless Ludwig chooses it (see the 047 correction about §2c rule 5).

## Constraints known now
- §6 needs `git branch -D` for a derailed task's unmerged branch, so a blanket block collides with
  doctrine. ★Q1-B allows it for the main session only, using `agent_type`, which is present in
  PreToolUse input inside subagents (official docs, verified 2026-10-14).
- Also in scope: the agents' Bash writes into `$WOM_VAULT`, which is the gap left open by 052.
