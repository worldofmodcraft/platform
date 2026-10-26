# Task 085: runbook — mark M6 (personal account joins the organisation) done

- **Mission:** SITE-V1 — **Status:** spec-approved (manager, solo gate, 2026-10-26; the 071/084 shape)
- **Repo:** platform. **Agent / model:** qa-engineer (§3.5). **Budget:** small (≤ 1 agent-session)
- **Branch / worktree:** `task/085-runbook-m6` / `~/wt/task-085`, cut from platform `origin/main`

## Source
Ludwig, 2026-10-26: "Ja det är klart" (invited `mbmludric` from the owner account and joined the organisation), and his
screenshot of Organisation → Settings → Member privileges showing **Base permissions: Read**.

## Objective
`docs/runbooks/site-v1-manual-steps.md`: M6's heading ☐ → ☑ and its status sentence records what was done, on whose word,
and the Base permissions value. Nothing else in the runbook changes (068-verify pins the other markers).

## Acceptance criteria
1. Evidence: Ludwig's word (membership); the manager's unauthenticated check of public members returned HTTP 403 (rate
   limit), so membership is **not externally verified** — recorded as such. Base permissions = Read (Ludwig's screenshot).
2. **Re-pin first (red first):** `068-verify.sh`'s marker checks (e.g. line ~21 "M6 heading stays ☐", and every other
   heading-state check) read the runbook at HEAD — own-change checks on a moving frame (REVIEW-CHECKLIST item 12). Pin them to
   068's merged PR range (068 merged as platform PR #58: BASE = `git merge-base M^1 M^2`, FINAL = `M^2`, M found with
   `git log --merges --grep`), the 071/084 pattern; classify every check own-change vs live in the log. Show the old script red
   on a throw-away commit that flips M6, then green after the re-pin. Mutations: range widened to HEAD → red; unreachable pins
   fail, never skip.
3. Then flip M6 ☐ → ☑ with the status sentence above; every `docs/tasks/*-verify.sh` exits 0, one at a time, foreground,
   `PYTHONDONTWRITEBYTECODE=1`; `085-verify.sh` own-change checks on fixed SHAs; passes in a fresh clone.

## File scope
`docs/tasks/068-verify.sh` (marker checks only), `docs/runbooks/site-v1-manual-steps.md` (M6 heading + status only),
`docs/tasks/085-runbook-m6-done.md` (log), `docs/tasks/085-verify.sh` (new).

---
# Task 085 log
- 2026-10-26 manager: written from Ludwig's report.
