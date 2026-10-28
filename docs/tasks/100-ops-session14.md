# Task 100: OPERATIONS.md — session 14 gotchas and the mbmludric membership fact; key-management.md — rotation names the workflow's public-key literal

- **Mission:** SITE-V1 (operations docs) — **Status:** spec-approved 2026-10-28 (manager, session 14; small, solo §2b; overnight ruling)
- **Agent / model:** doc-writer — **Budget:** small
- **Branch / worktree:** `task/100-ops-session14` / `~/wt/task-100` (platform)

## Objective and scope
Exactly these edits, in English, matching each file's existing style; nothing else.
1. `docs/manager/OPERATIONS.md`, new gotcha entries (each: what happened, the rule, source = mission log session 14 entry):
   a. Never name a non-task file `docs/tasks/NNN-*.md`: the vault projection reads every such file as a task file and refuses two with one id
      ("two task files share the id 098"; fixed by task 099). Proposals and drafts go under `docs/design/` or a non-numbered name.
   b. In a background session, the manager counts as an agent for git-guard's vault rule (`BLOCKED [vault]`): the manager cannot copy files into
      the vault; only the projection tool (via `tools/vault/refresh-main.sh`) or Ludwig writes there. Do not work around it.
   c. git-guard fails closed on a command it cannot parse ("unbalanced parenthesis" from a heredoc with parentheses in a long chained
      command): split into separate steps; give `gh pr create` its body with `--body-file`.
   d. Reviewer/doc agents on Sonnet were terminated mid-report by an API safeguard (`[reasoning_extraction]`, request ids in the mission log);
      resuming did not help. Working approach: a fresh independent reviewer on Opus (general-purpose, model override) that writes its findings to a
      file in the job tmp dir, which the manager reads.
   e. The vault projection's test mode requires the temporary vault under the system temp dir (`mktemp -d`, not the job tmp dir).
2. `docs/manager/OPERATIONS.md` lines ~21 and ~34-38: `mbmludric` is no longer a non-member. Fact (mission log line ~2364, M6, Ludwig
   2026-10-26: "Ja det är klart"): invited and joined; organisation Base permissions = Read. Correct the table row and the paragraph so they state
   current membership (member, Read) and keep the historical credential incident text (it is history) clearly marked as the 2026-09-06 situation.
   Do not state anything about its access beyond that fact.
3. `docs/architecture/key-management.md`, "Rotation procedure": add a step that the registry workflow `.github/workflows/pipeline.yml` (task 008b-2)
   carries the production public key as a literal in its `sign` job, so a rotation must update that literal (and its key id) in the same change.
   Mark it as applying once 008b-2 is merged.

## Acceptance criteria
1. `git diff --name-only origin/main...HEAD` = `docs/manager/OPERATIONS.md`, `docs/architecture/key-management.md`, this file.
2. Each of 1a-1e present (the agent pastes a grep per item); `grep -n 'non-member' docs/manager/OPERATIONS.md` shows no line asserting it as current.
3. No credential read or printed (rule 11): text edits only.

---
# Task 100 log
- 2026-10-28 manager (session 14): created; dispatched to doc-writer.
