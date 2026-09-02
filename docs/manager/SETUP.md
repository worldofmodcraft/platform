# Manager Environment Setup

1. **HUD:** install claude-hud (or erwint/claude-code-statusline) via `/plugin marketplace add ...` for context-window health, running subagents and per-agent token counts. The 60 % context rule (MANAGER.md §5) is enforced by watching this.
2. **Agent roster:** copy `docs/manager/agents/*.md` into the repo's `.claude/agents/`. Restart the session or run `/agents` to load. Verify each agent's model in `/agents` and at runtime via the agent panel / `/tasks`.
3. **Worktrees:** keep a `../wt/` directory beside the repo clone; one worktree per task (MANAGER.md §6).
4. **Statusline (later):** a `subagentStatusLine` script showing model-per-agent makes routing visually verifiable; add when the roster is in daily use.
5. **Session start ritual** is MANAGER.md §9 — the manager performs it unprompted.
