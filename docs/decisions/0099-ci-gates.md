# ADR-0099: CI gates — path-filtered per merge; nightly full build with stop-the-line

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Process / CI
- **Related:** ADR-0067, ADR-0069

## Decision
Per task-merge, CI runs what the diff touches (`tools/` → tool tests; `kernel/` → kernel + fast server link; `client/` → Windows client build) plus the always-cheap set (lint, IDL generator diff check, docs links). **Full platform build + soak runs nightly** and mandatorily before a platform-package tag. A red nightly **freezes merges to main until green** (stop-the-line rule, added to the manager doctrine). Cross-dependency misses thus never accumulate past a day. Core-surgeon tasks may declare `ci: full` in the task file for the whole suite immediately. Exact path-filter granularity is drawn after the skeleton reveals the real dependency edges — the principle is decided now.
