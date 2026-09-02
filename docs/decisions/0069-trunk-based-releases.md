# ADR-0069: Trunk-based development; platform packages are signed tags on main

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Process / Release
- **Related:** ADR-0047, ADR-0048

## Decision
One main branch, always green (reviewed merges from task branches per the doctrine). Platform packages (ADR-0048) are created as **immutable tags** on main by the pipeline, with signed artefacts — consistent with the registry's append-only model. Maintenance branches are created only when a second kernel major actually exists in parallel (ADR-0047), retroactively from the tag if a hotfix on an old package is ever needed; package patch versions cover the common case. Gitflow is rejected: it solves problems (parallel release tracks, large teams) we don't have.
