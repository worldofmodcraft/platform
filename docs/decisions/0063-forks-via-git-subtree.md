# ADR-0063: Forks are imported into the monorepo via git subtree with full history

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Process / Repo
- **Related:** ADR-0007, ADR-0064
- **Amended by:** ADR-0118 (thin patch surface, drift radar)

## Decision
WoWee and AzerothCore are imported into the monorepo (`client/`, `server/`) with **git subtree, full commit history preserved**; upstream merges use `git subtree pull`. Rejected: submodules (error-prone for the workflow and for Ludwig), squash-vendoring (history becomes inaccessible to `git blame`/surveys — we would pay in every survey and every core-surgeon task). Repo size is a one-time cost; `git clone --filter=blob:none` exists.
