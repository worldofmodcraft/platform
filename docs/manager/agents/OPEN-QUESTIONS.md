# Manager doctrine — open questions for Ludwig

Defaults marked ★ are what MANAGER.md currently encodes; answers adjust the doc.

**Q1 Autonomy horizon.** How long may the manager run before checking in?
A) ★ Per mission milestone: runs until a §8 stop condition, budget end, or milestone done, then reports.
B) Per task: report after every completed task.
C) Time-boxed: report at least every N hours of wall time.

**Q2 Merge authority.** Who merges to main?
A) ★ Manager merges when checklist is fully green; Ludwig always approves ADRs, specs, security/CI, keys, data deletion.
B) Ludwig approves every merge (safest, slowest — you become the bottleneck).
C) Manager merges docs-only freely; all code merges need Ludwig.

**Q3 Two-strike numbers.** MANAGER.md sets: 2 failures → 1 escalation → stop. Keep, or tune (e.g. 3 failures, or no escalation without asking)?

**Q4 Effort budgets.** Defaults: small ≤1 agent-session, medium ≤3, large ≤6, overruns stop. Keep, or set token/cost ceilings instead/in addition (visible via HUD/`/usage`)?

**Q5 Permission mode for agents.** What may agents do without per-action approval?
A) ★ Within worktree: full file + test/build commands; anything outside worktree, package installs, network beyond git/npm/pip to allowlisted registries, and all destructive git ops require approval.
B) Stricter: every bash command approved manually (very slow).
C) Looser: agents may also install packages freely.

**Q6 Parallelism cap.** Max concurrent agents? ★ Default 3 (readable HUD, reviewable output). Raise later when the rhythm works?

**Q7 Reporting language.** Docs/logs are English (ADR-0056). Session status reports *to you*:
A) ★ English (single language everywhere).
B) Swedish summaries on top of English logs.

**Q8 Your veto window.** When the manager merges autonomously (Q2-A), do you want a standing "daily digest" of merges so you can revert anything, or is the mission log enough? ★ Default: mission log only.
