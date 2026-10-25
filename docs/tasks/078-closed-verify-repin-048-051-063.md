# Task 078: closed verify scripts 048, 051/056 and 063 red on platform main — re-pin own-change checks, fix the 056 plant

- **Mission:** SITE-V1 (verification integrity) — **Status:** spec-approved (manager, solo gate, 2026-10-25; the 070/071 shape)
- **Repo:** platform. **Agent / model:** qa-engineer (§3.5). **Budget:** small (≤ 1 agent-session)
- **Branch / worktree:** `task/078-closed-verify-repin` / `~/wt/task-078`, cut from platform `origin/main`
- **Graph:** verification tooling only.

## Source
Task 076's AC4 (PR #66, log in `~/wt/task-076/docs/tasks/076-doctrine-removal-and-pinning.md`): on unchanged platform
`origin/main` `0aac566`, three closed scripts exit 1:
- **048** c1 ("nothing weakened", `docs/tasks/048-verify.sh` ~34-51): compares `MANAGER.md`, `CLAUDE.md`'s rule-0 block and
  MANAGER.md's token-guard bullet at HEAD against 048's base, so every later legitimate edit (the 2026-10-14 suspension
  note in rule 0; task 076's §7 rewrite) reddens it.
- **051** AC4 (secret scan over all tracked files): hits `docs/tasks/056-verify.sh:279`, which is **not a secret** — 056's
  own mutation test writes the literal minisign secret-key *header text* into a temp file (manager checked 2026-10-25:
  no key material). 051 itself builds its planted control string at runtime for exactly this reason.
- **063** AC1/AC2/AC4: `BASE=merge-base(HEAD, origin/main)` (line ~10) — the open-task frame, wrong now 063 is closed.

## Objective
All three exit 0 on `origin/main` and stay green when later tasks edit the same files, with nothing weakened:
1. **048 and 063:** each own-change check is pinned to the task's own merged PR range (BASE = `git merge-base M^1 M^2`,
   FINAL = `M^2`, M = the task's merge commit on main — find it with `git log --merges --grep`); live guards stay on HEAD.
   Classify every check own-change vs live in the log, one line why (the 070 audit shape). For 048 c1 specifically:
   "rule 0 / the token-guard bullet were not weakened **by task 048**" is own-change (pinned); if a live guard for rule 0's
   text is wanted beyond that, that is a doctrine question — book it, do not invent one.
2. **056-verify.sh:279:** build the planted header string at runtime (e.g. concatenated literals, as 051 does), so the
   committed file no longer contains the literal; 056's own mutation check must still redden exactly as before.
   051's scan and exclusions stay unchanged.
3. Add 048, 056 and 063 to `070-verify.sh`'s closed list if they are not there (later-branch run), so the class cannot
   return for them.

## Acceptance criteria — `docs/tasks/078-verify.sh`, whose output the log pastes
1. Red first: on unchanged `origin/main`, 048, 051 and 063 exit non-zero (shown); after the fix all exit 0.
2. Later-branch test: a throw-away commit editing `docs/manager/MANAGER.md` §7 and `CLAUDE.md` outside rule 0 → 048 and
   063 still exit 0. A throw-away commit that deletes a line of rule 0 **in a new commit** is not 048's concern (own
   range) — state in the log which script, if any, guards that live, as booked Question 1.
3. Mutations red: each re-pinned range widened back to HEAD; unreachable BASE/FINAL pins fail, never skip; 056's planted
   header removed → 056's check reddens; a real secret-shaped string planted in a tracked file → 051 reddens.
4. Quiet machine (`ps` logged), one script at a time from the worktree root: every `docs/tasks/*-verify.sh` on HEAD exits
   0, except those already red on `origin/main` for other reasons — listed with cause (the manager decides).
5. 078-verify.sh's own-change checks use fixed SHAs recorded at the end (REVIEW-CHECKLIST item 12 as proposed in 076).

## File scope
`docs/tasks/048-verify.sh`, `docs/tasks/056-verify.sh` (line ~279 only), `docs/tasks/063-verify.sh`,
`docs/tasks/070-verify.sh` (closed list only), `docs/tasks/078-closed-verify-repin-048-051-063.md` (log),
`docs/tasks/078-verify.sh` (new). Anything else = stop and report.

## Forbidden
Loosening any check beyond moving an own-change check to its pinned range; editing 051's patterns or exclusions;
pinning a live-property check; skips; touching CLAUDE.md or doctrine.

---
# Task 078 log
- 2026-10-25 manager (session 11): written and approved (solo gate). 076 waits on this for its AC4.
- 2026-10-25 qa-engineer (task 078, ran on platform `origin/main` `6f90d52`, machine quiet: `ps` top = worldserver/authserver idle-baseline, load ~1.3):
  - **Red first** (078-verify.sh AC1, clone at `6f90d52`): 048 exit 1 (c1 rule-0 block), 051 exit 1 (AC4 secret scan, `056-verify.sh:279`), 063 exit 1 (AC1/AC2/AC4, base = merge-base(HEAD, origin/main)). After the fix: 048, 051, 056, 063 exit 0.
  - **Pins** (fixed SHAs, no env override, unreachable pin exits 2):
    - 048: M = `c323460` (PR #50); PIN_BASE `8a5f32dfcebfe6eda328066b43eb60204ef3a5ac` (= M^1), PIN_FINAL `047bc41cac555cc125f2650d1b5cc3159f2f17a9` (= M^2).
    - 063: M = `0a87b17` (PR #55); BASE `ac407bf311995c11adf1a845c639b0c3fc886852` (= M^1), FINAL `052b5078c53f8d02cb6d6707d365f8f62351d2b6` (= M^2).
  - **Classification** (own-change = pinned to the PR range; live = stays on HEAD):

    | Script / check | Class | Why |
    |---|---|---|
    | 048 c1 deleted-lines per file (docs, agents) | own-change, re-pinned | "task 048 deleted nothing" describes the PR |
    | 048 c1 rule-0 block (CLAUDE.md) and token-guard bullet (MANAGER.md) identical to base apart from the marker | own-change, re-pinned | "not weakened by task 048"; a live guard is a doctrine question, see Q1 |
    | 048 c2 settings.json env and PreToolUse | live | properties the tree must keep |
    | 048 c3 agent files (10, maxTurns, disallowedTools) | live (stays; note it will redden when an 11th agent is added) | current-tree property; out of this task's brief, not touched |
    | 048 c4 marker precedes retained sentence | live | current-tree property |
    | 048 c5 waivers (quotes read from the base mission log at the pin) | live on MANAGER.md; quote source is the historical log, now at the pinned BASE | unchanged behaviour: it passed before and after |
    | 048 c6, c7 phrases in checklists/reviewer | live | current-tree properties |
    | 063 AC1 one hunk, inside the bullet | own-change, re-pinned | diff BASE blob vs the doctrine file at FINAL |
    | 063 AC2 positive control on base blob | own-change, pinned (BASE) | the old text existed at base |
    | 063 AC2 phrases absent from doctrine now | live | must stay absent |
    | 063 AC3 quoted commands and OPERATIONS.md citation | live | commands must run today |
    | 063 AC4 changed files subset of scope | own-change, re-pinned | `git diff --name-only BASE FINAL`; untracked-file arm dropped (it described an open task's working tree) |
    | 051 AC4 secret scan | live, unchanged | patterns and exclusions untouched |
    | 056 planted header (line 279) | fixture | now built as `'... encrypted '"sec""ret key"`; same bytes at runtime, no literal in the committed file |
  - **056 fix**: `056-verify.sh:279` only. 056 still 31 pass / 0 fail, control `secret header` caught (`FAIL [7] ... minisign secret-key header`); with the plant removed, 056 exits 1 on that control. 051 scan/exclusions unchanged.
  - **Later-branch** (AC2): throw-away commits editing MANAGER.md right under `## 7.` and appending to CLAUDE.md outside rule 0 -> 048 exit 0, 063 exit 0. A further throw-away commit deleting a rule-0 line -> 048 still exit 0 (own range). No script guards rule 0 live (Q1).
  - **Mutations** (AC3, all red): FINAL widened to later HEAD -> 048 exit 1, 063 exit 1; unreachable BASE/FINAL -> exit 2 for both scripts (4 cases); 056 plant removed -> exit 1 on the `secret header` control; real secret-shaped string (runtime-built) planted in a tracked file -> 051 exit 1; the old 056 literal re-added -> 051 exit 1. 048 `--mutate`: all 15 mutations red (c1 mutations act on the FINAL export); 063 `--mutate`: all caught, all restored.
  - **AC4 on HEAD** (one at a time, foreground): 048 0, 049 0, 051 0, 052 0, 053 0, 056 0, 059 0, 061 0, 063 0, 068 0, 078 0. (An early 051/053 red was my own 078-verify.sh containing the literal header; fixed by building it at runtime.) None red for other reasons.
  - **AC5**: 078-verify.sh own-change scope check uses `PIN_BASE 6f90d524570d1b518a2d7c294420786bf12666ec`, `PIN_FINAL 68a372ac4e2336ffd267299d1a55b33366bb3172` (content commit; the follow-up commit records the pin and this log).
  - **Scope deviation**: Objective item 3 (add 048/056/063 to `070-verify.sh`'s closed list) not done: `070-verify.sh` is a **registry** file (`~/registry/docs/tasks/070-verify.sh`, its closed list covers registry scripts); no `docs/tasks/070-verify.sh` exists in platform, so it is outside this repo and file scope. Booked as Q2. Substitute in-repo: 078-verify.sh's later-branch and pin-widening runs exercise 048/056/063.
  - **Questions booked for Ludwig/manager**:
    - Q1: should rule 0's text (CLAUDE.md block, MANAGER.md token-guard bullet) have a live guard (e.g. a check in a doctrine script that the retained sentences and "Stop at 90 %" lines exist)? Options: A no (review catches it) / B small live check in an existing doctrine script (task) * lean B, since 048's pinned check no longer covers later edits.
    - Q2: add 048/056/063 to a closed-list in platform (a platform analogue of registry's 070 audit) or accept 078-verify.sh as the guard? * lean: a small platform task, or fold into 076.
