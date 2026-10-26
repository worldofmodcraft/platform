# Archive URL probe (task 058) — PARTIAL: local part done; live push refused

**Status of this report:** the *local* criteria (1, 2, 8) are done and reproducible with `docs/tasks/058-verify.sh`.
Criteria 3, 4 are **NOT RUN — push refused by the permission classifier** (a pre-push baseline is captured); 5, 6, 10 are **NOT RUN — needs Ludwig** (DNS, browser, deletion). Every cell that depends on them
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

## What Pages emits (criteria 3-4) — PUSH REFUSED, probe tree NOT deployed; only a pre-push baseline was captured
**What happened (2026-10-26).** Ludwig created `worldofmodcraft/pages-probe` (public, README, Pages from `main` / root;
`curl -s https://api.github.com/repos/worldofmodcraft/pages-probe | grep -E '"(has_pages|private|default_branch|visibility)"'`
-> `"private": false, "has_pages": true, "visibility": "public", "default_branch": "main"`) and approved in session that the
probe agent pushes the probe tree through the session's configured git remote. The agent cloned the repo, committed the tree
on a local branch (`probe-tree`, commit `c1e8308`; the git-guard hook refuses `git commit` on `main`, so the commit was made on a
branch and the plan was `git push origin probe-tree:main`, plain, no force). The harness permission classifier then **denied the
`git push`** ("Auto-Mode Bypass"). Per CLAUDE.md rule 11 the denial is an answer: it was **not retried**, and no other route
(token, `gh`, API upload) was tried. Nothing from `pages-tree/` is on Pages. Criteria 3 and 4 as specified (`/a/index.html`,
`/b.tar.gz`, `/c`, `404.html`, `_redirects`) are therefore **NOT RUN**; nothing below is a claim about those files.

**What was captured anyway** (the repo contains only `README.md`, deployed by Pages before the agent's push attempt;
`date -u` 2026-10-26 06:12 UTC). Each line is `curl -s -D - -o /dev/null <url>` filtered to status / location / content-type:

| URL | status | location | content-type |
|---|---|---|---|
| `https://worldofmodcraft.github.io/pages-probe` (project root, **no** trailing slash) | **301** | `https://worldofmodcraft.github.io/pages-probe/` | `text/html` |
| `https://worldofmodcraft.github.io/pages-probe/` | 200 | - | `text/html; charset=utf-8` |
| `.../pages-probe/README.md` | 200 | - | `text/markdown; charset=utf-8` (the raw file is served, 13 bytes) |
| `.../pages-probe/README` | 404 | - | `text/html; charset=utf-8` |
| `.../pages-probe/nonexistent` | 404 | - | `text/html; charset=utf-8` |
| `.../pages-probe/a`, `/a/`, `/b.tar.gz` (files not pushed) | 404 | - | `text/html; charset=utf-8` |

`curl -sI https://worldofmodcraft.com/pages-probe/` -> `HTTP/2 404`, `server: GitHub.com`, `content-security-policy: default-src 'none'; ...`
(the custom domain does **not** front the project repo at `/pages-probe/`; it answers its own 404, so the apex site and
this probe are separate; `https://worldofmodcraft.github.io/pages-probe/` is the only working address).

**The one fact this gives:** GitHub Pages **does** emit an HTTP `3xx` with a `Location` header: a `301` that adds the trailing
slash to a directory-style path (observed for the project root). It is Pages' own canonicalisation, to the same host and the
same path plus `/`; nothing in this capture shows that a project can choose the target. Whether `/c` -> `/c/` behaves the same
for a subdirectory, whether `404.html` or `_redirects` can produce a `3xx`: **[unverified — not run; push refused]**.
The sentence "no HTTP redirect route exists on Pages" is therefore **not** supported by this report (spec: report "not found in
these tries", and the tries were not made).

## What is needed to finish criteria 3-4 (Ludwig, exact commands)
The commit is ready in `/home/ludwig/.claude/jobs/95f471eb/tmp/pages-probe` (branch `probe-tree`, commit `c1e8308`).
Either run in your own terminal:
```
cd /home/ludwig/.claude/jobs/95f471eb/tmp/pages-probe
git push origin probe-tree:main
```
or allow the push in the session's permission prompt and ask the agent to continue (it will then poll
`curl -sI https://worldofmodcraft.github.io/pages-probe/a/` every 60 s for up to 15 min and capture
`for p in /a/index.html /a/ /b.tar.gz /c /c/ /_redirects /old /nonexistent; do echo "== $p"; curl -sI "$B$p"; curl -s -D - -o /dev/null "$B$p"; done`
with `B=https://worldofmodcraft.github.io/pages-probe`).

## Criteria 5, 6, 10 status
- **5 (DNS / second hostname): NOT RUN — needs Ludwig's explicit DNS approval; no DNS was touched.**
- **6 (browser): not tested — Ludwig's observation pending.** Steps, after the tree is pushed: open
  `https://worldofmodcraft.github.io/pages-probe/a/` and `https://worldofmodcraft.github.io/pages-probe/b.tar.gz` in one
  desktop browser; note for each whether the address bar ends at `target.txt`, whether it renders or downloads, and the proposed
  file name. Write the three answers into the table cells marked `[UNVERIFIED — not observed]`.
- **10 (deletion): NOT DONE by design — the agent does not delete the repository.** Ludwig, after the captures:
  `https://github.com/worldofmodcraft/pages-probe` -> Settings -> General -> Danger Zone -> Delete this repository
  [click-path from memory, UNVERIFIED]; then record it here.

## Conclusion (plain, evidence-limited)
1. Does Pages emit any HTTP 3xx? **Yes, one kind observed:** a `301` adding the trailing slash for the project-root path
   (capture above). **Not observed:** any `3xx` to a chosen target. Routes `404.html`, `_redirects`, meta-refresh page, `.tar.gz`-named HTML file and subdirectory `/c`: [unverified — not run].
2. Options A-E for the archive URL shape, on the evidence so far: **A and B** stay viable only for clients that execute HTML (browser);
   local matrix shows `curl -L`, `wget`, `urllib`, Node `fetch` do not follow them. **C** (Cloudflare real 301/302) and **D**
   (other static host) remain viable in principle; their feasibility is [unverified] (needs proxied record / a new service, both
   Ludwig's call). **E** is always viable. No option is eliminated by a Pages capture, because the Pages captures of the
   relevant routes were not made. The directory-slash 301 does not look usable as a redirect to a release asset, since its target is fixed by Pages.

## What this means for the tasks that wait
The spec files for 008a, 008b, 055, 010 and 056 are not in this worktree's scope to edit; the sentence-by-sentence mapping
requires reading each and the live outcome, and is **NOT DONE** here (criterion 7 is only partly met). What the local
evidence alone fixes: a meta-refresh or JS front is invisible to `curl -L`, `wget`, `urllib` and `fetch`; only an HTTP 3xx is followed by all of them.
