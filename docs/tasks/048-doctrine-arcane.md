# Task 048: Write Ludwig's chosen Arcane practices into the doctrine

- **Mission:** tooling (task 047, part A) — **Status:** draft. Spec gate **not passed**: the content depends on Ludwig's answers Q2–Q6 and Q-T.
- **Agent / model:** doc-writer / per agent frontmatter (ROUTING.md)
- **Budget:** small
- **Branch / worktree:** task/048-doctrine-arcane / ~/wt/task-048 (sequenced after 052: both touch `MANAGER.md` and `.claude/settings.json`)

## Objective (finalised once the answers arrive)
CLAUDE.md, MANAGER.md, REVIEW-CHECKLIST.md, SPEC-CHECKLIST.md and `.claude/agents/*.md` carry exactly
the practices Ludwig chose from the draft's items 2–6, and the token-guard text matches his 2026-10-14
decision (Q-T). Every change is additive or explicitly approved; nothing existing is weakened without a
named Ludwig decision.

## Facts already verified for this task (2026-10-14, claude-code-guide agent, official docs)
- `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` exists from v2.1.217. The default is **3**, so subagents *can*
  spawn subagents today. The value `1` turns nesting off. Source: https://code.claude.com/docs/en/env-vars.md.
  The installed version is 2.1.300 (`claude --version`).
- `maxTurns`, `disallowedTools`, `effort` and `permissionMode` are documented subagent frontmatter fields.
  When `maxTurns` is reached the output is returned marked partial (v2.1.246+). Source:
  https://code.claude.com/docs/en/sub-agents.md. Default when omitted: not documented.

## Acceptance criteria
Set at the spec gate after the answers. Doctrine edits → Ludwig approves the merge (§7).
