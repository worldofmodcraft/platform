# Task 037: Pages enablement — worldofmodcraft.com serves for the first time

- **Mission:** SITE-V1 — **Status:** **spec-approved (Ludwig, in session, 2026-09-05: "Pages
  enablement is GO — 025 closed, so my gate is met")**
- **Agent / model:** manager (operations, not production code)
- **Budget:** small
- **Branch / worktree:** `task/037-pages-enablement` (platform repo). Any redirect *implementation*
  that turns out to be needed belongs in the `site` repository and gets its own branch there.
- **Blocks:** nothing. **Unblocks:** the mission's headline outcome — the site is publicly served.

## Why this needs a task file at all
Guardrail 9: anything that publishes is *at minimum* a small spec-approved task, however trivial it
looks. Enabling Pages publishes a website to the public internet under a domain Ludwig owns. His
"GO" supplies approval; this file supplies the record, the declared scope and the acceptance
criteria — three different things (CLAUDE.md rule 2).

## Context — the state this task starts from (verified 2026-09-05, commands in the log below)
- `worldofmodcraft/site` has content for the first time (task 009, site PR #1, merged session 4).
- `has_pages: false`; `GET repos/worldofmodcraft/site/pages` returns 404.
- The deploy workflow **already ran and already builds**: run 33956828991 built successfully and
  failed *only* at the deploy step, with GitHub's own message
  `Ensure GitHub Pages has been enabled`. So this task enables a setting; it does not fix a build.
- `public/CNAME` contains `worldofmodcraft.com`, and Astro copies `public/` into `dist/`.
- DNS: apex has GitHub's four documented Pages A records; `www` CNAMEs to
  `worldofmodcraft.github.io`. Nameservers are Cloudflare's, and **the proxy is off** — the apex
  resolves to GitHub's real addresses, not Cloudflare's. **No CAA record exists**, so nothing
  obstructs Let's Encrypt issuance.

## Ludwig's three booked verifications (session 4 named all three; this task owes all three)
1. **Enable Pages with the custom domain.**
2. **The www → apex redirect** — he ruled *redirect*. It must be **implemented and verified against
   GitHub's ACTUAL www/apex behaviour**. His instruction, verbatim: *"check, don't assume"*.
   GitHub is widely believed to create the www→apex redirect automatically for an apex custom
   domain; that belief is exactly what this criterion forbids relying on. Whatever is true must be
   *observed*, and if the redirect does not appear, it is implemented rather than explained away.
3. **One real in-browser Pagefind search** against the *served* site — task 009's single residual
   gap, verified structurally but never in a browser.

## Acceptance criteria
Each demonstrated by a command with **real** output pasted into this task's log. Fabricated
verification output is this project's one unforgivable failure (task 030).

1. **Pages is enabled** on `worldofmodcraft/site` with `build_type: workflow` and custom domain
   `worldofmodcraft.com`. Demonstrated by `GET repos/worldofmodcraft/site/pages` returning the
   configured site rather than 404.
2. **A deploy run succeeds.** The previously failing workflow is re-run and reaches a green
   `deploy` job. Demonstrated by `gh run view` output.
3. **The apex serves over HTTPS.** `curl -sI https://worldofmodcraft.com` returns 200 with GitHub's
   Pages headers. **This output goes to Ludwig verbatim** — his standing request is real `curl -sI`
   output, never "it should be live now".
4. **HTTPS is enforced** (`https_enforced: true`), and plain HTTP redirects to HTTPS rather than
   serving. Demonstrated by `curl -sI http://worldofmodcraft.com`.
5. **The www behaviour is observed, not assumed.** `curl -sI https://www.worldofmodcraft.com` and
   its HTTP form are run and their **actual** status codes and `Location` headers recorded — before
   any claim is made about what GitHub does. If the observed behaviour is not a redirect to the
   apex, the gap is closed rather than documented as a quirk, and the closing change gets its own
   branch in the `site` repository.
6. **The certificate covers what is served.** Whatever hostnames end up returning 200 or a redirect
   over HTTPS must present a valid certificate for that name. Demonstrated by the TLS handshake
   detail from `curl -sIv`, not inferred from the absence of an error.
7. **One real in-browser Pagefind query against the served site** — not the local build, not the
   `dist/` directory: the site as the public internet receives it. A query is typed, results come
   back, and the evidence is the actual result payload. Task 009 staged real headless Chrome
   without root and documented the recipe; reuse it (`site:docs/`).
8. **This log records what needed Ludwig's hands and what did not** — he asked to be told
   specifically about the Cloudflare proxy toggle and Pages settings.

## File scope (declared) — platform repository
- `docs/tasks/037-pages-enablement.md` (this file, which is also its own log)
- `docs/tasks/MISSION-worldofmodcraft-site-v1-log.md` (session status / ledger)
- `docs/manager/OPERATIONS.md` — only if a gotcha worth keeping is found

Anything else = stop and report. Changes to the `site` repository (if criterion 5 forces a redirect
implementation) are a **separate branch in that repository**, not this scope.

## Rollback
Pages can be disabled again (`DELETE repos/worldofmodcraft/site/pages`), which un-serves the site
without touching DNS or repository content. Nothing in this task rewrites history, changes a remote,
or deletes data. The domain is Ludwig's and already points at GitHub; this task does not change DNS.

## Log
Populated as the work runs — see below.
