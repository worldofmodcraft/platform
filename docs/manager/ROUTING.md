# Model Routing — World of Modcraft

Set the model **explicitly, always** (agent frontmatter or Task call). Verify in the agent panel/HUD.

| Tier | Model (alias) | Used for | Agents |
|---|---|---|---|
| Cheap | `haiku` | Bulk reading, surveys of well-trodden code, file inventories, boilerplate from templates, log summarisation, doc formatting | surveyor (simple), scaffolder, doc-writer (mechanical) |
| Standard | `sonnet` | Implementation against a clear spec (CI logic, generators, scripts, site code, Lua), test-suite construction, bug reproduction and isolation, doc writing with judgement, survey of unfamiliar subsystems | implementer, qa-engineer, debugger, surveyor (complex), doc-writer |
| Strong | strongest available (e.g. `opus`-class / the model the manager runs on) | Core surgery in AzerothCore/WoWee C++, ABI/IDL design, security-relevant CI, anything where a wrong-but-plausible answer costs days | core-surgeon, reviewer (for strong-tier work) |

Rules:
1. Start one tier lower than instinct suggests; escalate on demonstrated failure (two-strike rule, MANAGER.md §3.4) — never pre-emptively "to be safe".
2. Review runs at **the same tier or higher** than the work being reviewed, and by a *different* agent than the author.
3. `CLAUDE_CODE_SUBAGENT_MODEL` (env) force-overrides every subagent's model for a session — usable as a cost ceiling; note it takes full model names, not aliases. Do not use it routinely; it defeats routing.
4. **Escalation paths (two-strike rule):** escalation swaps the *model*, never the *role* — same
   system prompt, stronger tier, and only after the manager has diagnosed the failure and
   improved the spec (most failures are spec failures; a stronger model with the same bad spec
   burns money on the same misunderstanding). Defined paths: implementer → implementer-strong;
   debugger → debugger-strong; surveyor(haiku) → surveyor(sonnet); qa-engineer / reviewer /
   doc-writer → strong tier via a manager-rewritten spec; scaffolder never escalates (a failed
   scaffold is always a spec problem); core-surgeon's escalation is stop-and-ask-Ludwig.
   The -strong variants are never routed to directly for fresh tasks.
5. Cost visibility: HUD/statusline per-agent token counts; `/usage` for session totals. Anomalies (an agent burning far beyond its task size) are a stop-and-look signal, not background noise.

## Turn caps and nesting (task 048; Ludwig's decisions Q2 and Q5, 2026-10-14)
Nesting is off: `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1` in `.claude/settings.json` and `disallowedTools: Agent`
in every agent definition. Each agent has a `maxTurns` cap; reaching it is a budget stop (MANAGER.md §8).
The numbers are estimates, not measurements; revise them from observed runs.

| Agent | maxTurns | Reason |
|---|---|---|
| scaffolder | 30 | mechanical generation from a template; needing more means the spec is ambiguous |
| doc-writer | 50 | reads sources, writes several files, updates the log |
| surveyor | 60 | bulk reading; read-only, so a high cap carries little risk |
| debugger | 60 | reproduce, isolate, report; no edits |
| debugger-strong | 80 | escalation tier; re-tests the prior investigation's assumptions first |
| reviewer | 80 | re-reads and judges verify scripts and mutation tests |
| qa-engineer | 80 | writes many fixtures and runs them |
| implementer | 100 | the largest ordinary task: code, tests, docs, verify script, log |
| implementer-strong | 120 | escalation tier: the same work plus the failure history |
| core-surgeon | 120 | fork internals; an early stop is cheapest to recover from here |
