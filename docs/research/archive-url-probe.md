# Archive URL probe (task 058) — local and live Pages captures done; browser, DNS and deletion pending (Ludwig)

**Status of this report:** criteria 1, 2, 8 (local, `docs/tasks/058-verify.sh`) and 3, 4 (live Pages captures, 2026-10-26) are done.
Criterion 5 (DNS) is **NOT RUN — needs Ludwig**; criterion 6 (browser) is **not tested — Ludwig's observation pending**; criterion 10 (repository deletion) is Ludwig's.
This report states no recommendation; the choice and any reversal of the DNS-only decision are Ludwig's.

## Environment (commands run 2026-10-14 in the worktree)
`which wget` -> `/usr/bin/wget`; Node `v24.20.0`; Python `3.14.4`; `curl 8.18.0 (x86_64-pc-linux-gnu)`.
Raw output of the matrix: run `docs/tasks/058-verify.sh` (tables reproduced in the task log).

## Comparison table
Cells: `follows` / `does not follow` / `not tested`, with the capture reference. "Local" = loopback fixture
(`tools/probe/archive-url/fixture_server.py`), which models the mechanism, **not GitHub Pages**; a local cell says what
the client does with that response shape, not that Pages can emit it.

| mechanism | curl -L | curl (no -L) | wget | python urllib | node fetch | browser |
|---|---|---|---|---|---|---|
| A meta-refresh page | does not follow (local row `meta-refresh`; live `/a/`, see below) | does not follow (same) | does not follow (local) | does not follow (local) | does not follow (local) | [UNVERIFIED — not observed] (criterion 6) |
| B JS redirect page | does not follow (local, row `js-redirect`) | does not follow (local) | does not follow (local) | does not follow (local) | does not follow (local) | [UNVERIFIED — not observed] (criterion 6) |
| C Cloudflare redirect rule (a real 301/302) | follows, *if* a 301/302 exists (local `301`/`302` rows are the shape) — whether Cloudflare can emit it for this setup: not tested | stops at the 3xx with Location (local) | follows (local shape) | follows (local shape) | follows (local shape) | not tested |
| D other static host with `_redirects` | same shape as C; the host's behaviour: not tested | as C | as C | as C | as C | not tested |
| E baseline: store the `github.com` release URL | the URL answers 302 (capture below); `curl -L` end-to-end download: not tested here | stops at 302 (capture below) | not tested | not tested | not tested | not tested |

Criterion 1 positive control (302, 301, and directory-without-slash -> 301 `/dir/`) passed for all four following clients
(`curl -L`, `wget`, `python urllib`, `node fetch`) with bytes equal to the target SHA-256. `curl` without `-L` stops at the
3xx and exposes `Location` (checks C2). Meta-refresh and JS pages: every client received the HTML, final URL the page
itself, status 200, bytes != target (checks C3).

Mechanism E capture (unauthenticated, 2026-10-14 22:01 UTC):
`curl -s -o /dev/null -w 'status=%{http_code} redirect=%{redirect_url}\n' https://github.com/jedisct1/minisign/releases/download/0.12/minisign-0.12-linux.tar.gz`
-> `status=302 redirect=https://release-assets.githubusercontent.com/github-production-release-asset/37023739/...?...se=2026-10-14T22%3A47%3A49Z...` (signed, expires ~46 min after the request: the final URL can never be the stored one).

## Filename behaviour (criterion 2, command-line clients; browsers via criterion 6)
Saved names from the local run: for `/dl/ct-html.tar.gz` (Content-Type `text/html`) and `/dl/ct-gzip.tar.gz`
(`application/gzip`), `curl -O -J`, `wget` and `wget --content-disposition` all saved the **URL basename**; Content-Type did
not change the name. With a `Content-Disposition: attachment; filename="named-by-header.tar.gz"` header, `curl -O -J` and
`wget --content-disposition` used the header name, plain `wget` kept `cd.tar.gz`. Bytes equalled the target in all nine runs.
Browser file naming: [UNVERIFIED — not observed].

## What Pages emits (criteria 3-4) — LIVE CAPTURES, 2026-10-26
**Setup.** Ludwig created `worldofmodcraft/pages-probe` (public, Pages from `main` / root). The agent's own push was denied by the harness
permission classifier (not retried); Ludwig then pushed the probe tree himself, `833d333..c1e8308 probe-tree -> main`
(reported by the manager). Deployment seen at 16:46 UTC (`curl` of `/target.txt`: 404 at 16:45:14, 200 at 16:46:15).
Base `B=https://worldofmodcraft.github.io/pages-probe`. Each capture below is
`curl -s -D - -o /dev/null "$B<path>"` filtered to status / location / content-type / content-length (`tr -d '\r' | grep -i -E '^(HTTP|location|content-type|content-length)'`).

| path | status | Location | Content-Type | length | body (`curl -s`) |
|---|---|---|---|---|---|
| `/target.txt` | 200 | - | `text/plain; charset=utf-8` | 20 | `WOM058 pages target` |
| `/a/index.html` | 200 | - | `text/html; charset=utf-8` | 161 | meta-refresh to `../target.txt` |
| `/a/` | 200 | - | `text/html; charset=utf-8` | 161 | same |
| `/a` (directory, no slash) | **301** | `https://worldofmodcraft.github.io/pages-probe/a/` | `text/html` | 162 | - |
| `/b.tar.gz` (HTML content, `.tar.gz` name) | 200 | - | **`application/gzip`** | 155 | the meta-refresh HTML, not gzip |
| `/c` (directory, no slash) | **301** | `https://worldofmodcraft.github.io/pages-probe/c/` | `text/html` | 162 | - |
| `/c/` | 200 | - | `text/html; charset=utf-8` | 74 | `directory c` |
| `/_redirects` (file `/old /target.txt 302`) | 404 | - | `text/html; charset=utf-8` | 117 | the 404 page |
| `/old` (the `_redirects` rule's source) | **404** | - | `text/html; charset=utf-8` | 117 | the 404 page |
| `/nonexistent` | **404** | - | `text/html; charset=utf-8` | 117 | the repo's `404.html` body (meta-refresh) |
| `/404.html` | 200 | - | `text/html; charset=utf-8` | 117 | meta-refresh |

Facts read off the table (no claim beyond it):
1. Pages **does** emit HTTP 3xx: a `301` with `Location` for a directory requested without trailing slash (`/a`, `/c`, and the project root `/pages-probe`, captured earlier the same day). The target is the same URL plus `/`; nothing in the captures lets the project choose it.
2. `_redirects` has **no effect** (`/old` -> 404; `/_redirects` itself -> 404). **Not found in these tries:** any 3xx to a chosen target via `404.html`, `_redirects`, or a plain file. The custom 404 page is served **with status 404** and its meta-refresh body, so clients see a 404, not a redirect.
3. A file named `b.tar.gz` is served with `Content-Type: application/gzip` whatever its content; the bytes are served as stored (155 bytes of HTML). Pages therefore also serves a real tarball under a `.tar.gz` name; that is hosting the bytes, not redirecting.
4. `curl -sI https://worldofmodcraft.com/pages-probe/target.txt` -> `HTTP/2 404`, `server: GitHub.com`: the apex custom domain does not serve this repo at `/pages-probe/`; the only working address was `worldofmodcraft.github.io/pages-probe/`. (Criterion 5 would change this and was not run.)

### Clients against the live URLs (criterion 3/4 "curl/wget exactly as the spec says" plus the matrix clients)
Target SHA-256 (of `/target.txt`): `c40a80d865cb2e46...` (first 16 hex shown; `curl -s $B/target.txt | sha256sum`). Commands: `curl -sL -o /dev/null -w 'final=%{url_effective} status=%{http_code} redirects=%{num_redirects}'`, `wget -S -O out.bin`, `python3 -I live058/py.py $B ...` (`urllib.request.urlopen`), `node live058/n.mjs $B ...` (`fetch`, `redirect: "follow"`); the two scripts are in `/home/ludwig/.claude/jobs/95f471eb/tmp/live058/` (not committed; 14 lines each).

| path | curl -L | wget | python urllib | node fetch | bytes = target? |
|---|---|---|---|---|---|
| `/a/` (meta-refresh) | final `/a/`, 200, 0 redirects | 200, stays, 161 B | final `/a/`, 200 | final `/a/`, 200 | **no** (sha16 `fb1ddd7e...`) in all four |
| `/a` | follows the 301 to `/a/`, then stops (200 HTML) | follows 301, stops | follows 301, stops | follows 301, stops | no |
| `/b.tar.gz` | final `/b.tar.gz`, 200, `application/gzip`, HTML bytes | 200, saved HTML named `b.tar.gz` (`file`: HTML document) | 200, HTML bytes | 200, HTML bytes | no (sha16 `c75e3630...`) |
| `/c` | follows 301 to `/c/`, 200 | follows 301 | follows 301 | follows 301 | n/a (not the target) |
| `/old` (`_redirects`) | 404, 0 redirects | `ERROR 404` | HTTPError 404 | status 404 | no |
| `/nonexistent` (`404.html`) | 404, 0 redirects | `ERROR 404` | HTTPError 404 | status 404 | no (404 body) |
| `/target.txt` (control) | 200 | 200 | 200 | 200 | yes |

`curl` without `-L`: `/a` -> `status=301 redirect=https://worldofmodcraft.github.io/pages-probe/a/`; `/c` the same; `/b.tar.gz` -> `status=200`.
Saved names: `curl -sOJ $B/b.tar.gz` and `wget -q $B/b.tar.gz` both saved `b.tar.gz`; `file` reports `HTML document, ASCII text` (155 bytes). Consistent with the local result that Content-Type does not change the name.
All four non-browser clients reach the same end state on every Pages route: the meta-refresh HTML or a 404, **never** `target.txt`.

## Criteria 5, 6, 10 status
- **5 (DNS / second hostname): NOT RUN — needs Ludwig's explicit DNS approval; no DNS was touched.**
- **6 (browser): not tested — Ludwig's observation pending.** Steps (one desktop browser, a private window):
  1. Open `https://worldofmodcraft.github.io/pages-probe/a/`. Write down: does the address bar end at `.../pages-probe/target.txt`? is the text `WOM058 pages target` shown?
  2. Open `https://worldofmodcraft.github.io/pages-probe/b.tar.gz`. Write down: does a download start, with which proposed file name; or is the HTML rendered; or does it show an error?
  3. Open `https://worldofmodcraft.github.io/pages-probe/nonexistent`. Write down whether it ends at `target.txt` (the 404 page's meta-refresh) or stays on a 404.
  4. Send the three answers to the manager; they go into the browser cells below.
- **10 (deletion): NOT DONE by design — the agent does not delete the repository.** Ludwig, after step 6: `https://github.com/worldofmodcraft/pages-probe` -> Settings -> General -> Danger Zone -> Delete this repository [click-path from memory, UNVERIFIED]; then tell the manager so it is recorded here.

## Conclusion (evidence = the captures above; "not found in these tries")
1. **Does Pages emit any HTTP 3xx?** Yes, exactly one kind observed: the `301` that appends `/` to a directory path. Not found in these tries: any 3xx to a project-chosen target (`404.html`, `_redirects`, meta-refresh page, `.tar.gz`-named file, plain file; `/old` and `/nonexistent` answered 404).
2. **Options for the archive URL shape:**
   - **A (meta-refresh page) and B (JS redirect):** servable on Pages, but **no HTTP client tested follows them** (curl -L, wget, urllib, fetch all end on the HTML; live and local agree). Viable only if every consumer is a browser or our own code that parses the HTML. Browser behaviour [UNVERIFIED — not observed]. A `.tar.gz`-named meta-refresh file is served as `application/gzip` with HTML bytes: a poor shape for any download client.
   - **C (Cloudflare real 301/302):** not eliminated, not tested. [unverified] whether it needs a proxied record (the DNS-only decision is Ludwig's) and what the plan allows.
   - **D (other host with real redirects):** not eliminated, not tested; new service outside the mission.
   - **E (store the `github.com` release URL):** works today (302 captured 2026-10-14) but is the lock-in Q-G declined.
   - Remaining on Pages alone: **no option gives a project-chosen HTTP redirect.** An observation outside A-E: Pages serves arbitrary files with their own Content-Type (`b.tar.gz` -> `application/gzip`), so the project-owned URL could serve the tarball bytes itself instead of redirecting. That is hosting, not fronting `worldofmodcraft/archive`; its size limits and its fit with decision Q-E are [unverified] and the choice is Ludwig's.

## Comparison table, live cells filled
| mechanism | curl -L | curl | wget | urllib | node fetch | browser |
|---|---|---|---|---|---|---|
| A meta-refresh on Pages | does not follow (live `/a/`) | does not follow | does not follow | does not follow | does not follow | not tested — Ludwig pending (step 1) |
| B JS redirect on Pages | does not follow (local; same shape as A, not deployed live) | same | same | same | same | not tested |
| C Cloudflare real redirect | follows if a 301/302 exists (local shape) | stops at 3xx | follows | follows | follows | not tested |
| D other host `_redirects` | as C; host not tested | as C | as C | as C | as C | not tested |
| Pages' only 3xx (dir `/a` -> `/a/`) | follows, ends on the HTML | stops at 301 | follows | follows | follows | not tested |
| `_redirects` / `404.html` on Pages | 404 (no 3xx) | 404 | 404 | 404 | 404 | `/nonexistent`: not tested |

## What this means for the tasks that wait
Sentences quoted from the specs on origin/main of this branch (2026-10-26). "If A/B" = the front is a Pages HTML page; "if C/D" = a real HTTP redirect on a project hostname; "if E" = the `github.com` URL is stored.
- **008a (`pipeline-core`).** Line 231 ("`source_archive_url` ... — 008c (they need tasks 057 and 058)") and line 279 ("URL shape waits on task 058"): 008a itself is unaffected (it does not need 058, line 259). The URL function moves to 008c; its body is: A/B -> a Pages path of the form `https://<project host>/<path>` that is an HTML page (hostname and path still to be fixed by Ludwig); C/D -> the redirecting hostname; E -> the `github.com/.../releases/download/<tag>/<tag>.tar.gz` URL already produced by `release_asset_url`.
- **008b (`pipeline-workflow`).** Line 158-159 ("The `source_archive_url` expectation comes from task 058's report ..."): the expected string is the one chosen above. Line 174 ("is fetched with `curl -L` and with a browser-equivalent client and yields the same bytes — blocked until task 058 reports"): this clause **cannot pass under A or B** (curl -L ends on the HTML, live capture); it passes under C/D/E, or under hosting the bytes on Pages; it is Ludwig's decision which, and it should not be silently rewritten. Line 235 ("Writing `source_archive` as anything other than the URL 008c's `source_archive_url` returns") stays as is.
- **055 (`site-live-registry`).** Line 88-94 ("The URL must match the project-owned shape ...; the redirect chain must end at `https://github.com/worldofmodcraft/archive/releases/download/<tag>/<tag>.tar.gz` ... If 058 finds the front is an HTML meta-refresh page rather than an HTTP redirect, the staging script's handling of it is specified after 058, not guessed here"): this probe shows Pages offers **only** the meta-refresh shape. Under A the staging script must parse HTML (an extra, attackable step before the host allowlist); under C/D the chain is the HTTP redirects it already assumes; under E the first hop is `github.com`. Q3's allowed-redirect-host list gains the project host (its name from Ludwig). Under all outcomes the dir-slash 301 stays on the project host.
- **010 (`test-mod`).** Line 96 ("check that the entry's `source_archive` URL (the project-owned one ...; shape from task 058) resolves"): "resolves" means, under A/B, "returns the HTML page" (200, bytes not the tarball), under C/D/E "redirects to the asset". The runbook check must name which; a plain `curl -sL ... | sha256sum` check is wrong under A/B.
- **056 (`architecture-note`).** Lines 66-76 ("whether GitHub Pages can serve it is unverified until task 058 reports; if 058 finds it infeasible, the note records that finding ... the note names that host (from 058) and says what is lost if it moves"): the second pass records: Pages cannot emit a project-chosen HTTP redirect (not found in these tries; captures in this report); the benefit of Q-G holds only through A/B (browser-only), C/D (needs Ludwig's DNS/service decision) or hosting bytes; it must not be described as `built`.
- **`artifact-naming.md` amendment (sibling).** Waits on Ludwig choosing the shape; this report fixes nothing.
This section is a mapping, not a recommendation; the choice and any reversal of the DNS-only decision are Ludwig's.
