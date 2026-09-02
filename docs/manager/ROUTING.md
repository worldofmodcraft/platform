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
