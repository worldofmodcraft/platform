# Review Checklist (manager, before any merge)

A single "no" blocks the merge. The reviewer is never the author.

1. **Task linkage:** work maps to a task file; nothing outside the task's declared file scope was touched (`git diff --stat` against the declaration).
2. **Acceptance criteria:** each one *demonstrated* (command output, screenshot, test run) — not asserted. Demonstrations are linked in the task log.
3. **Tests:** all pass in the worktree; no existing test weakened, skipped or deleted; new behaviour has a test or an explicit, logged reason why not.
4. **ADR conformance (bidirectional, ADR-0116):** (a) the ADRs listed in the task's Context are followed; (b) the diff touches no areas whose ADRs were NOT listed — check the diff's paths against docs/decisions/INDEX.json; a selection miss is reported as a manager error and blocks until the context is corrected and re-verified. Anything that reinterprets an ADR is escalated to Ludwig, not merged.
5. **Docs moved with code:** every behaviour change is reflected in the relevant design doc / README / runbook in the same branch.
6. **Forbidden-shortcut scan:** none of MANAGER.md §3.7 present (grep for TODO/FIXME/skip markers; read error paths).
7. **Task log complete and truthful:** done/remaining/decisions/issues current; a stranger could resume from it. Every path, file and artefact the log cites exists on disk (verify, do not assume); any record written after the fact is marked **retroactive**.
8. **No secrets** in diff, logs or command output.
9. **English throughout.**
10. **Cleanup ready:** branch merges cleanly onto current main; worktree removable.
