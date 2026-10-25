# Review Checklist (manager, before any merge)

A single "no" blocks the merge. The reviewer is never the author.

**Order (task 048; Ludwig's decision Q3, 2026-10-14):** the independent pass comes first: spec + diff, findings written down and placed first in the verdict under "Findings formed before reading the log", and only then is the task log opened, so item 7 is checked after it. The log is the author's account; a reviewer anchored on it inherits its blind spots.

1. **Task linkage:** work maps to a task file; nothing outside the task's declared file scope was touched (`git diff --stat` against the declaration).
2. **Acceptance criteria:** each one *demonstrated* (command output, screenshot, test run) — not asserted. Demonstrations are linked in the task log.
3. **Tests:** all pass in the worktree; no existing test weakened, skipped or deleted; new behaviour has a test or an explicit, logged reason why not.
4. **ADR conformance (bidirectional, ADR-0116):** (a) the ADRs listed in the task's Context are followed; (b) the diff touches no areas whose ADRs were NOT listed — check the diff's paths against docs/decisions/INDEX.json; a selection miss is reported as a manager error and blocks until the context is corrected and re-verified. Anything that reinterprets an ADR is escalated to Ludwig, not merged.
5. **Docs moved with code:** every behaviour change is reflected in the relevant design doc / README / runbook in the same branch.
6. **Forbidden-shortcut scan:** none of MANAGER.md §3.7 present (grep for TODO/FIXME/skip markers; read error paths).
7. **Task log complete and truthful:** done/remaining/decisions/issues current; a stranger could resume from it. Every path, file and artefact the log cites exists on disk (verify, do not assume); any record written after the fact is marked **retroactive**.
8. **Verification artefact (MANAGER.md §2c):** for command-based criteria, `docs/tasks/NNN-verify.sh` exists, is executable, and **you re-ran it yourself** — its real output matches the log. Then **mutation-test it**: break what each check claims to check and confirm the check reddens. A check that stays green while its subject is broken is a finding, however true its claim happens to be. Confirm it passes in a *fresh clone*, not only the authoring worktree. **If this is a fix round, the finding it closes is in the suite as a fixture** (§2c rule 5) — and the log shows it failing before the fix, not only the larger green total afterwards. Check the positive controls are still there: a suite that passes by rejecting everything is not a suite.
9. **No secrets** in diff, logs or command output.
10. **English throughout.**
11. **Cleanup ready:** branch merges cleanly onto current main; worktree removable.
12. **Verify-script pinning (closed at merge; Ludwig, 2026-10-17):** the task's `NNN-verify.sh` measures the task's *own* change (file scope, red-commit ancestry, own-file diffs) on a fixed commit range recorded in the script — never `HEAD` or `origin/main` — and its *live* guards (tests green, other closed scripts green) on `HEAD`. Checked before merge, because the task becomes a closed task at merge and a moving frame then reddens it the first time a later task touches the same files (OPERATIONS.md, 'What session 10 paid for').
