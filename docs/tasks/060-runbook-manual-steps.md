# Task 060: Ludwig's new manual steps (M5–M7, Q-H) in the SITE-V1 runbook

- **Mission:** SITE-V1 — **Status:** done (2026-10-15) (manager, 2026-10-15; small documentation, §2b solo gate)
- **Agent / model:** doc-writer / per agent frontmatter
- **Budget:** small
- **Branch / worktree:** task/060-runbook-manual-steps / ~/wt/task-060

## Objective
`docs/runbooks/site-v1-manual-steps.md` shows the true current state of every manual step:
- M0–M4 status markers are corrected from evidence.
- New steps are added: M5 (create the org-owned GitHub App), M6 (Ludwig's personal account joins the org),
  M7 (create `worldofmodcraft/archive`) and Q-H (check whether the `MINISIGN_SECRET_KEY` secret exists).
- Every step has exact click-paths or commands that Ludwig can follow, written for a non-programmer.

## Context to load
- The runbook itself.
- `docs/manager/OPERATIONS.md` (evidence for M0–M3).
- `docs/tasks/008b-pipeline-workflow.md` (where M5–M7 were first written, with unverified click-paths).
- `docs/tasks/010-test-mod.md` (M4).
- The mission log on branch `session/8-status` (Ludwig's 2026-10-14 answers Q-D/E/F/H):
  `git -C /home/ludwig/wom show session/8-status:docs/tasks/MISSION-worldofmodcraft-site-v1-log.md | tail -60`.

## File scope
`docs/runbooks/site-v1-manual-steps.md` and this file's log only.

## Acceptance criteria
1. Each status marker is backed by cited evidence (a file or a read-only command shown in the log), or marked `[unverified]`.
2. M5–M7 and Q-H exist. Each states why it is needed (cite the decision), when (which task waits on it), and how
   (steps). Click-paths that were not verified are marked `[unverified — check on screen]`.
3. No step asks Ludwig to paste a secret anywhere, and the doc says so explicitly for Q-H (look, do not copy).
No verify script: the criteria are documentary, checked by the manager at review.

## Forbidden here
Credentials of any kind; gh auth/secret commands; editing any other file.

# Task 060 log
Date 2026-10-15. Only unauthenticated, read-only commands and repo files were used. The GitHub REST API was
rate-limited (HTTP 403) for this IP, so github.com HTML pages were used instead.

| Step | Marker | Evidence |
|---|---|---|
| M0 | done | `curl -s "https://cloudflare-dns.com/dns-query?name=worldofmodcraft.com&type=NS" -H accept:application/dns-json` returned `anastasia.ns.cloudflare.com.`, `dexter.ns.cloudflare.com.` |
| M1 | done (repos/org); 2FA and Actions settings `[unverified]` | `curl -s -o /dev/null -w "%{http_code}" https://github.com/worldofmodcraft`, `/registry`, `/site` all 200; OPERATIONS.md "Done and verified: the org, both repos, Actions permissions" |
| M2 | done | same DoH query, type=A: 185.199.108/109/110/111.153; type=CNAME `www`: `worldofmodcraft.github.io.`; type=CAA: no answer; `curl -sI https://worldofmodcraft.com` HTTP/2 200 server GitHub.com; `www` gives 301 |
| M3 | keypair done; secret `[unverified]` | key id in OPERATIONS.md; no read-only way to see secrets; Q-H open in 008b |
| M4 | not done | `https://github.com/mbmludric/hello-world` 404; `https://worldofmodcraft.com/mods/test/hello-world` 404; `docs/test-mod` absent in this tree. A repo of another name or a private one cannot be ruled out, so "not done" is unverified-but-likely |
| M5 | not done | `https://github.com/apps/worldofmodcraft-pipeline` 404 (an App with another name would not be seen) |
| M6 | not done, `[unverified]` | people page lists member count 1, no `mbmludric` in the HTML; OPERATIONS.md: non-member |
| M7 | not done | `https://github.com/worldofmodcraft/archive` 404 |
| Q-H | open | cannot be checked by agents; source 008b Questions section |

Click-paths for M5-M7 are copied from `008b-pipeline-workflow.md` (unverified there), reworded for Ludwig, and marked
unverified in the runbook. Changes from 008b's text: step 9 now says how to move the key (Notepad, straight into the form)
and 008b's "paste into chat" prohibition is kept. Q-H step 4's advice to re-add the old key is my suggestion, not a
decision; the runbook says the choice is shared. Not verified: any click-path; M1.2/M1.4 settings; whether `www` 301 target is the apex.
- 2026-10-15 manager review (small documentation task, solo per §2b scale):
  - Scope matches: two files.
  - Secret handling checked by grep. Line 11 states the rule. The only pastes are the public key (to the manager)
    and the private key straight into GitHub's own Actions-secret form, which GitHub offers no alternative to.
  - The deviation from criterion 3's wording is accepted; its intent (never into chat, a file or an issue) holds.
- Status: done.
