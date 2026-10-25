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
