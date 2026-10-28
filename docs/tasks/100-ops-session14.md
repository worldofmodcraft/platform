# Task 100: OPERATIONS.md — session 14 gotchas and the mbmludric membership fact; key-management.md — rotation names the workflow's public-key literal

- **Mission:** SITE-V1 (operations docs) — **Status:** done 2026-10-28 (spec-approved 2026-10-28 (manager, session 14; small, solo §2b; overnight ruling)
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
- 2026-10-28 doc-writer (session 14): done. Edits: OPERATIONS.md (membership fact in table row, identity bullet and paragraph; new section 'What session 14 paid for' with 1a-1e; last-reviewed 2026-10-28); key-management.md (rotation step 7, last-reviewed 2026-10-28). Note: the mission log held no session-14 entries at write time, so 1a-1d facts and the 'request ids' pointer come from this task file and task 099; no request ids were invented.
  AC1 `git diff --name-only origin/main...HEAD` (after commit): see below. AC2 greps:
```
$ grep -n 'share the id 098' docs/manager/OPERATIONS.md
425:"two task files share the id 098". Task 099 moved it to `docs/design/`. Rule: proposals and drafts go unde
$ grep -n 'BLOCKED \[vault\]' docs/manager/OPERATIONS.md
429:git-guard answered `BLOCKED [vault]` to the manager copying files into the vault. Only the projection tool
$ grep -n 'unbalanced parenthesis' docs/manager/OPERATIONS.md
433:A long chained command containing a heredoc with parentheses was refused with "unbalanced parenthesis". Ru
$ grep -n 'reasoning_extraction' docs/manager/OPERATIONS.md
437:Reviewer and doc agents running on Sonnet were terminated mid-report with `[reasoning_extraction]` (reques
$ grep -n 'mktemp -d' docs/manager/OPERATIONS.md
442:With `WOM_VAULT_TEST=1`, create the temporary vault with `mktemp -d` (the system temp dir), not inside the
$ grep -n 'no longer\*\* a non-member' docs/manager/OPERATIONS.md
39:log M6: "Ja det är klart"); organisation Base permissions = Read. It is **no longer** a non-member.
$ grep -n 'non-member' docs/manager/OPERATIONS.md
23:  (Ludwig, mission log M6; not externally verified). Before that it was a non-member with no write
39:log M6: "Ja det är klart"); organisation Base permissions = Read. It is **no longer** a non-member.
41:**History (the 2026-09-06 situation, when `mbmludric` was still a non-member):** it looked like the
42:obvious tool for reproducing any "what does a non-member caller see?" question — and that was exactly
46:stand in for a non-member caller in any case.
48:**The right way to reproduce a non-member caller costs nothing and needs no identity:**
$ grep -n '008b-2' docs/architecture/key-management.md
78:7. **Applies once task 008b-2 is merged:** the registry workflow `.github/workflows/pipeline.yml` carries
```
  Remaining non-member lines: 23, 41, 46, 48 are history/how-to; line 39 states it is no longer one. AC3: text edits only, no credential read.
- 2026-10-28 manager (session 14): independent review (Sonnet reviewer) said PASS with one LOW, then was cut off by the API safeguard before naming the LOW
  (request id req_011CgVS3zJXsGNm2MySvyjCV). Manager review of the full diff against the checklist: facts match the mission log; history kept and
  labelled; rotation step accurate against the 008b-2 workflow. One LOW fixed by the manager: only reviewer agents (not doc agents) were cut off —
  heading and sentence corrected. Status done; merged on the manager's authority (§7, doc task).
