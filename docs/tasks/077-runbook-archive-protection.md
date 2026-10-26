# Task 077: runbook step M8 — protect `worldofmodcraft/archive` Releases and tags from deletion

- **Mission:** SITE-V1 (removal policy, item 6) — **Status:** done (merged platform PR #63 `2562f88`) — was: spec-approved (manager, solo gate, 2026-10-18)
- **Repo:** platform. **Agent / model:** doc-writer (ROUTING.md). **Budget:** small (≤ 1 agent-session)
- **Branch / worktree:** `task/077-runbook-archive-protection` / `~/wt/task-077`, cut from platform `origin/main`
- **Graph:** docs only (runbook); no edge changes.

## Source
Ludwig, 2026-10-17, "Option A for all" — removal policy item 6 (mission log, "Removal policy — brainstorm and Ludwig's
decision"): a protection rule on `worldofmodcraft/archive` so Releases cannot be deleted; a manual step for Ludwig with
exact clicks written by the manager's side.

## Objective
`docs/runbooks/site-v1-manual-steps.md` gains a section `## ☐ M8 — Protect the archive's Releases and tags` (after M7,
same format as M5/M7) that Ludwig can follow click by click in the GitHub web UI, plus one way to check afterwards that
the protection is in force.

## Requirements
1. **Verified facts only (§3, verified-facts rule, task 035).** Every UI path, setting name and behaviour is taken from
   GitHub's current documentation (docs.github.com), fetched in this task; each claim cites the doc URL in the log.
   Candidates to check — not facts until verified: tag rulesets restricting deletion/update of `refs/tags/*`;
   GitHub "immutable releases" (repository setting); whether deleting a Release (not the tag) can be prevented at all,
   and whether the org-owner (Ludwig) can still bypass. Say plainly what each mechanism does **not** prevent.
2. Explain in two or three plain sentences why the step exists (ADR-0041:15 and Ludwig's 2026-10-17 decision: a
   published version stays published; a takedown stops public serving but keeps the record). Ludwig is not a terminal
   user: web UI clicks, no shell commands unless unavoidable (then the exact command, complete).
3. A "check afterwards" step that does not need credentials beyond Ludwig's normal browser login.
4. If GitHub offers no way to prevent Release deletion, the section says so and names the closest protection, and the
   gap is booked as a Question in this log — no invented mechanism.

## Acceptance criteria
1. The section exists with ☐ status, follows the M-section format, and each fact has a cited URL in the log.
2. `tools/vault` or runbook-marker checks that exist (e.g. task 068's) stay green; run every `docs/tasks/*-verify.sh`
   that touches the runbook and paste exit codes.
3. No other runbook section changes.

## File scope
`docs/runbooks/site-v1-manual-steps.md` (new M8 section only), `docs/tasks/077-runbook-archive-protection.md` (log).

## Forbidden
Making any change on GitHub (the step is Ludwig's); reading or using any token or credential; editing ADRs.

---
# Task 077 log
- 2026-10-18 manager (session 11): written and approved (solo gate).
- 2026-10-18 doc-writer: M8 added to `docs/runbooks/site-v1-manual-steps.md` (before Q-H, after M7). Nothing changed on GitHub; no credential touched.
  Verified (WebFetch, docs.github.com, 2026-10-18):
  - Tag ruleset steps (Settings > Rulesets > Rulesets > New ruleset > New tag ruleset; name, enforcement Active, Bypass list, Target tags, Tag protections, Create): https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository
  - Rules "Restrict deletions" ("only users with bypass permissions can delete branches or tags") and "Restrict updates": https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets
  - Bypass is configurable per actor; rulesets otherwise apply to all: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
  - Immutable releases, repo UI path (Settings > Releases > "Enable release immutability"), applies only to future releases: https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/establish-provenance-and-integrity/preventing-changes-to-your-releases
  - Immutable releases behaviour (tag locked while release exists; assets protected; after deleting the release the tag may be deleted but the name cannot be reused): https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases and https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository
  - Release deletion (trash icon / "Delete this release"): the managing-releases page above. No page found describing any way to prevent it; the runbook says so.
  Check: `bash docs/tasks/068-verify.sh` exit 0 (ALL PASS); the only verify script referencing the runbook. (First run failed because I had rewritten the "Last reviewed" stamp; restored it and added a separate M8 note.)
  Questions for Ludwig/manager:
  1. No way to prevent Release deletion exists in the docs. Accept tag + file protection as "closest"? (Alternative outside this task: few people hold delete rights on `archive`.)
  2. Can an org owner bypass immutable releases, and who can delete an immutable release? Docs do not say; marked [unverified] in M8.
  3. Rulesets are documented as available "for customers on GitHub Team and GitHub Enterprise plans"; fetched docs did not say about Free plan on public repos. The org's plan is unknown to us; M8 tells Ludwig to stop if Rulesets is missing.
  4. Does `archive` already contain releases? Immutability would not cover them.
  5. Pipeline creating tags is assumed unaffected (only deletion and update restricted); not tested.
- 2026-10-18 doc-writer (review fixes, PR #63): (1) Re-fetched the about-rulesets and creating-rulesets-for-a-repository pages (URLs above): both say only "for customers on GitHub Team and GitHub Enterprise plans"; neither mentions Free or public repositories, so the "Free plan works" sentence was NOT written. M8 quotes the doc and marks Free/public [unverified]; Q3 stays open. (2) Q4 closed: `archive` has 0 releases (manager, unauthenticated API, 2026-10-18); M8 now says immutability covers every release from now on. (3) Neither page names an "All tags" option or the tag target menu choices; step 6 keeps the [unverified] flag and tells Ludwig to stop and ask if the screen differs.
- 2026-10-25 doc-writer (task 072): status corrected by task 072: done, merged as platform PR #63 (`2562f88`, on platform origin/main).
