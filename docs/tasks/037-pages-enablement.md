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

---

# Log — 2026-09-05, manager (operations)

## What needed Ludwig's hands: **nothing**
He flagged two possibilities in advance — a Cloudflare proxy toggle during certificate issuance,
and Pages settings. Neither was needed, and both were **checked rather than assumed**:

- **The Cloudflare proxy was already off.** The apex resolves to GitHub's own four documented Pages
  addresses, not Cloudflare's, which is what proxied records would show. No toggle, no window of
  downtime, no coordination.
- **No CAA record exists** on the domain, so nothing could obstruct Let's Encrypt issuance.
- **Pages settings were done through the API** by the manager, not through the web UI.

```
$ curl -s "https://dns.google/resolve?name=worldofmodcraft.com&type=A"
185.199.108.153  185.199.109.153  185.199.110.153  185.199.111.153
$ curl -s "https://dns.google/resolve?name=www.worldofmodcraft.com&type=CNAME"
worldofmodcraft.github.io.
$ curl -s "https://dns.google/resolve?name=worldofmodcraft.com&type=NS"
dexter.ns.cloudflare.com.  anastasia.ns.cloudflare.com.
$ curl -s "https://dns.google/resolve?name=worldofmodcraft.com&type=CAA"
status 0, (no answer)
```

## Criterion 1 — Pages enabled with the custom domain
Before: `GET /repos/worldofmodcraft/site/pages` → `404 Not Found`, `has_pages: false`.

```
$ gh api -X POST repos/worldofmodcraft/site/pages -f build_type=workflow
{"status":null,"cname":null,"html_url":"https://worldofmodcraft.github.io/site/",
 "build_type":"workflow","source":{"branch":"main","path":"/"},"public":true,"https_enforced":true}

$ gh api -X PUT repos/worldofmodcraft/site/pages -f cname=worldofmodcraft.com
(empty body on success)

$ gh api repos/worldofmodcraft/site/pages
{"cname":"worldofmodcraft.com","html_url":"http://worldofmodcraft.com/","build_type":"workflow",
 "https_enforced":false}
```

Two things worth keeping, both observed rather than expected:
1. Before the custom domain was set, `html_url` was **`https://worldofmodcraft.github.io/site/`** —
   a *project-page subpath*. Astro's config sets `site: "https://worldofmodcraft.com"` with **no
   `base`**, so the build only serves correctly at a domain root. Setting the apex domain resolved
   this; enabling Pages *without* the custom domain would have served a site with broken asset
   paths.
2. Setting the CNAME flipped `https_enforced` from `true` to **`false`** on its own. That is
   GitHub disabling enforcement until a certificate exists for the new name — see criterion 4.

## Criterion 2 — a deploy run succeeds
The workflow was **already building and already failing at the deploy step only**, which is why
this task enabled a setting rather than fixing a build:

```
$ gh run view 33956828991 --log-failed | tail -1
##[error]Error: Failed to create deployment (status: 404) ... Ensure GitHub Pages has been enabled:
https://github.com/worldofmodcraft/site/settings/pages
```

After enablement:

```
$ gh workflow run deploy.yml --repo worldofmodcraft/site
$ gh run watch 33957759998 --exit-status
  ✓ build in 49s (ID 101284074315)
  ✓ deploy in 9s (ID 101284179184)
exit=0
```

## Criterion 3 — the apex serves over HTTPS
```
$ curl -sI https://worldofmodcraft.com
HTTP/2 200
server: GitHub.com
content-type: text/html; charset=utf-8
last-modified: Sat, 05 Sep 2026 09:22:26 GMT
x-github-edge-region: swedencentral
```

## Criterion 4 — HTTPS is enforced
`gh api -X PUT ... -f https_enforced=true` was **rejected** — `-f` sends every value as a string and
the API requires a real boolean:

```
Invalid property /https_enforced: `"true"` is not of type `boolean`. (HTTP 422)
```

Corrected with `-F`, which types the value:

```
$ gh api -X PUT repos/worldofmodcraft/site/pages -F https_enforced=true
$ gh api repos/worldofmodcraft/site/pages --jq '{cname,https_enforced}'
{"cname":"worldofmodcraft.com","https_enforced":true}
```

**Enforcement did not take effect immediately, and this was NOT reported as done until it did.**
Plain HTTP kept returning 200 for roughly eight minutes — GitHub's edge cache carries
`cache-control: max-age=600`. The state was polled once a minute rather than assumed:

```
09:26:51Z  HTTP/1.1 200 OK
09:27:51Z  HTTP/1.1 200 OK
09:28:52Z  HTTP/1.1 200 OK
...
$ curl -sI http://worldofmodcraft.com
HTTP/1.1 301 Moved Permanently
Location: https://worldofmodcraft.com/
```

**Gotcha for OPERATIONS.md:** a Pages settings change is not observable at the edge for up to ten
minutes. Reading the API back confirms the *setting*, never the *behaviour*.

## Criterion 5 — the www behaviour, observed before any claim was made
Ludwig's instruction was *"check, don't assume"*, so these were run **before** anything was written
about what GitHub does. GitHub does create the redirect itself; no implementation was needed.

```
$ curl -sI https://www.worldofmodcraft.com
HTTP/2 301
location: https://worldofmodcraft.com/

$ curl -sI http://www.worldofmodcraft.com
HTTP/1.1 301 Moved Permanently
Location: http://worldofmodcraft.com/

$ curl -sIL http://www.worldofmodcraft.com     # the full chain, after enforcement landed
HTTP/1.1 301 Moved Permanently   Location: http://worldofmodcraft.com/
HTTP/1.1 301 Moved Permanently   Location: https://worldofmodcraft.com/
HTTP/2 200
```

Note the plain-HTTP www path is a **two-hop** chain (www→apex over HTTP, then HTTP→HTTPS). It ends
correctly on HTTPS; it is recorded here because it means one hop travels in clear text before the
upgrade, which is inherent to GitHub's ordering and not something this repository controls.

## Criterion 6 — the certificate covers what is served
Not inferred from the absence of a curl error. One Let's Encrypt certificate covers **both** names,
and its `notBefore` matches the minute the custom domain was set:

```
$ echo | openssl s_client -servername worldofmodcraft.com -connect worldofmodcraft.com:443 \
    | openssl x509 -noout -subject -issuer -dates -ext subjectAltName
subject=CN=worldofmodcraft.com
issuer=C=US, O=Let's Encrypt, CN=YR1
notBefore=Sep  5 08:22:59 2026 GMT
notAfter=Dec  4 08:22:58 2026 GMT
X509v3 Subject Alternative Name:
    DNS:worldofmodcraft.com, DNS:www.worldofmodcraft.com
```
The same command against `www.worldofmodcraft.com` returns the identical certificate.

## Criterion 7 — one real in-browser Pagefind query against the SERVED site
Task 009's Chrome staging was gone (its scratch directory had been cleaned), so the documented
recipe was re-run: `npx @puppeteer/browsers install chrome@stable`, then `apt-get download`
(fetch-only, no root) of `libnspr4`, `libnss3`, `libasound2t64` — `libnssutil3` and `libsmime3`
turned out to ship *inside* `libnss3`, which the original recipe does not say — extracted with
`dpkg-deb -x` and pointed at with `LD_LIBRARY_PATH`. Chrome then launched headless.

Driven with `puppeteer-core` against **`https://worldofmodcraft.com/browse/`** — the public site,
not `dist/`:

```
--- query: "lantern" (page 200) ---
input value in the real DOM: "lantern"
message: 4 results for lantern
  * Lantern Quests => /mods/fixture/lantern-quests
  * Browse => /browse
  * A modding platform, built out in the open. => /
  * Campfire Tales => /mods/fixture/campfire-tales

--- query: "campfire" (page 200) ---
message: 3 results for campfire

--- query: "zzzqqxnotpresent" (page 200) ---
message: No results for zzzqqxnotpresent
result count: 0

=== failures: 0 ===
```

### The first version of this harness was broken, and it "passed"
Recorded because it is the same failure class this project has hit three times — a test that can
only confirm what its author already believes. The first harness reused one input element and
cleared it with `click({clickCount: 3})`, which did not select the text. The terms concatenated:

```
--- query: "campfire" ---
message: 4 results for lanterncampfire
--- query: "zzzqqxnotpresent" ---
message: 4 results for lanterncampfirezzzqqxnotpresent
result count: 4        <-- the negative control returned results and did not redden
```

The fix was a **fresh page load per query**, plus asserting on the input's real DOM value. The
evidence that the corrected harness genuinely queries is that the three counts **differ** (4 / 3 /
0); the broken one returned 4 every time.

### A manager misreading, corrected in the same sitting
An earlier check reported "no page on the served site contains the word *search*", which would have
been a real finding. It was wrong: `/browse` **301-redirects to `/browse/`**, and `curl` without
`-L` returned the empty redirect body. The search UI is present on `/browse/`.

## Criterion 8 — what needed Ludwig's hands
Nothing. See the top of this log.

## Status
**in-progress → review.** All eight criteria are demonstrated with real output above.
`worldofmodcraft.com` serves SITE-V1 over HTTPS, `www` redirects to the apex on both schemes under
a certificate covering both names, and Pagefind has been queried in a real browser against the
served site with a negative control that reddens.

**Standing caveat:** the deployed site is built from this repository's **fixtures**, not from real
published mods — the deploy workflow's registry checkout and archive staging are still commented
out pending their contracts. The site is live and correct; its *content* is fixture content.
