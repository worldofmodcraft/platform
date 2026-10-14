# Archive URL probe (task 058) — PARTIAL: local part only

**Status of this report:** the *local* criteria (1, 2, 8) are done and reproducible with `docs/tasks/058-verify.sh`.
Criteria 3, 4, 5, 6, 10 are **NOT RUN — needs Ludwig/manager** (live Pages, DNS, browser). Every cell that depends on them
says so. This report states no recommendation; the choice and any reversal of the DNS-only decision are Ludwig's.

## Environment (commands run 2026-10-14 in the worktree)
`which wget` -> `/usr/bin/wget`; Node `v24.20.0`; Python `3.14.4`; `curl 8.18.0 (x86_64-pc-linux-gnu)`.
Raw output of the matrix: run `docs/tasks/058-verify.sh` (tables reproduced in the task log).

## Comparison table
Cells: `follows` / `does not follow` / `not tested`, with the capture reference. "Local" = loopback fixture
(`tools/probe/archive-url/fixture_server.py`), which models the mechanism, **not GitHub Pages**; a local cell says what
the client does with that response shape, not that Pages can emit it.

| mechanism | curl -L | curl (no -L) | wget | python urllib | node fetch | browser |
|---|---|---|---|---|---|---|
| A meta-refresh page | does not follow (local, row `meta-refresh`) | does not follow (same) | does not follow (local) | does not follow (local) | does not follow (local) | [UNVERIFIED — not observed] (criterion 6) |
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

## What Pages emits (criteria 3-4) — NOT RUN — needs Ludwig/manager
Nothing is claimed about GitHub Pages. The earlier observation (404 from `server: GitHub.com` for an unknown path on the apex)
shows nothing about redirects. The probe tree is ready at `tools/probe/archive-url/pages-tree/`
(`a/index.html` meta-refresh, `b.tar.gz` HTML in a `.tar.gz`-named file, `c/index.html` for requesting `/c`, `404.html`,
`_redirects`, `target.txt`). Steps to run (Ludwig's click path is [UNVERIFIED], per the spec):
1. Create public throwaway repo (e.g. `worldofmodcraft/pages-probe`) with a README; Settings -> Pages -> Deploy from a branch -> `main` `/ (root)`.
2. Put the contents of `pages-tree/` at the repo root and push (Ludwig, or the manager with his in-session approval; no token handling by any agent).
3. Wait for deploy (up to ~10 min), then with `B=https://<owner>.github.io/pages-probe`:
   `for p in /a/index.html /b.tar.gz /c /c/ /_redirects /old /nonexistent; do echo "== $p"; curl -sI "$B$p"; curl -s -D - -o /dev/null "$B$p"; done`
   Record status line, `content-type`, `location` per path. Any "Pages answers 3xx" claim only from these captures.
4. Browser (criterion 6): open `$B/a/` and `$B/b.tar.gz`; note whether it follows, renders or downloads, and the proposed file name.
5. Criterion 5 (hostname/DNS): NOT RUN — needs Ludwig's explicit approval; not started.
6. Delete the repo (Settings -> General -> Danger Zone) and record it here (criterion 10: NOT RUN).

## What this means for the tasks that wait
The spec files for 008a, 008b, 055, 010 and 056 are not in this worktree's scope to edit; the sentence-by-sentence mapping
requires reading each and the live outcome, and is **NOT DONE** here (criterion 7 is only partly met). What the local
evidence alone fixes: a meta-refresh or JS front is invisible to `curl -L`, `wget`, `urllib` and `fetch`; only an HTTP 3xx is followed by all of them.
