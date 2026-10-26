# Task 091: runbook step M12 — a Cloudflare redirect from archive.worldofmodcraft.com to the archive's Release assets

- **Mission:** SITE-V1 (D2 archive URL, decision C) — **Status:** spec-approved (manager, solo gate, 2026-10-26)
- **Repo:** platform. **Agent / model:** doc-writer. **Budget:** small (≤ 1 agent-session)
- **Branch / worktree:** `task/091-runbook-m12` / `~/wt/task-091`, cut from platform `origin/main`

## Source
Ludwig, 2026-10-26: "C star" — the archive URL shape is a project-owned hostname with a real HTTP redirect at Cloudflare
(task 058's option C; mission log). DNS for worldofmodcraft.com is at Cloudflare (runbook M2).

## Objective
`docs/runbooks/site-v1-manual-steps.md` gains `## ☐ M12 — Archive download address (Cloudflare redirect)` after the last M-step:
exact Cloudflare dashboard clicks to make `https://archive.worldofmodcraft.com/<tag>/<file>` answer a **301 or 302** with
`Location: https://github.com/worldofmodcraft/archive/releases/download/<tag>/<file>` (path segments preserved, query dropped),
including the DNS record the redirect needs (proxied, so Cloudflare answers), and a "you should see" check Ludwig can do in a
browser. Which redirect status (301 permanent vs 302) is recommended and why, in one sentence.

## Requirements
1. Every UI path, product name (Single Redirects / Redirect Rules / Page Rules — whichever Cloudflare documents today for the
   Free plan), wildcard/dynamic-target syntax and plan limit is taken from developers.cloudflare.com, fetched in this task, with
   URLs in the log; anything not found is `[unverified]`, never invented.
2. Plain web-UI clicks for a non-terminal user. No DNS change is made by the agent; no credential is used.
3. A verification block the manager runs afterwards (unauthenticated): `curl -sI https://archive.worldofmodcraft.com/v0/test`
   expecting the 30x and the computed `Location`; written into M12 as "the manager checks".
4. `docs/tasks/068-verify.sh` and every verify script touching the runbook exit 0 (the runbook's other markers unchanged).

## File scope
`docs/runbooks/site-v1-manual-steps.md` (new M12 section only), `docs/tasks/091-runbook-m12-archive-redirect.md` (log).

## Forbidden
Changing Cloudflare or DNS; credentials; editing other runbook sections.

---
# Task 091 log
- 2026-10-26 manager: written from Ludwig's decision C.
