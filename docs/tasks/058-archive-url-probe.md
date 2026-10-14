# Task 058: Probe — can a project-owned URL front the release assets that `source_archive` points at?

- **Mission:** SITE-V1, deliverable **D2/D5** (decision Q-G) — **Status:** in-progress (local part done; live part needs Ludwig) 
- **Agent / model:** implementer / sonnet for the local matrix and the report; Ludwig (or the manager on his behalf, recorded) for the browser observations.
- **Budget:** small (≤ 1-2 agent-sessions). It produces a **report, not a decision**.
- **Branch / worktree:** `task/058-archive-url-probe` / `~/wt/task-058` — **platform** repo.

## Why this exists
Ludwig decided (2026-10-14, Q-G, "Stjärna på allt"): *a project-owned URL fronts `source_archive` before the first publish.* The reason (task 056, fact 4): `source_archive` is stored in an append-only record, so if it is a `github.com/...` URL, leaving GitHub later cannot rewrite it. A URL on a domain the project controls can be repointed.
The decision recorded that **feasibility on GitHub Pages is unverified**. The registry stores one HTTPS URL per version, the site is hosted on Pages (DNS-only at Cloudflare, per the runbook M2), and the release assets live in `worldofmodcraft/archive` (Q-E). Whether a project-owned URL can *redirect* to a release asset in a way every client follows is the open fact. Tasks 008a (the URL function), 008b (criterion 6), 055 (the downloader), 010 (the runbook) and 056 (the architecture note) wait on the answer. **This task does not choose the mechanism and does not touch DNS; if every mechanism needs something Ludwig has not approved (for example Cloudflare proxying, which would reverse the "DNS-only, grey cloud" decision), it reports that and stops.**

## What is already known (observed 2026-10-14, commands shown) and what is not
- **Observed:** a release asset URL on `github.com` answers an unauthenticated request with `302` to a signed, time-limited URL on `release-assets.githubusercontent.com`:
  `curl -s -o /dev/null -w 'status=%{http_code} redirect=%{redirect_url}\n' https://github.com/jedisct1/minisign/releases/download/0.12/minisign-0.12-linux.tar.gz` → `status=302 redirect=https://release-assets.githubusercontent.com/github-production-release-asset/...?sp=r&...&se=2026-10-14T22%3A42%3A32Z&...` (the `se=` expiry was one hour ahead of the request). Consequence: the final URL can never be what the registry stores; the stored value is the `github.com/.../releases/download/...` URL or something in front of it.
- **Observed:** `curl 8.18.0 -L` does **not** follow an HTML `<meta http-equiv="refresh">`. A local server serving `meta.html` (`<meta http-equiv="refresh" content="0; url=/target.bin">`) gave, for `curl -sL -o /dev/null -w 'final=%{url_effective} status=%{http_code}\n'`, `final=http://127.0.0.1:8765/meta.html status=200`; the body returned was the HTML, not the target. So a meta-refresh front is invisible to `curl -L` (and to any client that only follows HTTP redirects).
- **Observed:** an unknown path on `https://worldofmodcraft.com` answers `HTTP/2 404`, `server: GitHub.com` (Pages). It shows nothing about redirect capability.
- **Not verified (every one is a probe item below):** that GitHub Pages can emit an HTTP `3xx` for any path (the documented position, as far as I know, is that it cannot configure server-side redirects; **this is from memory and unchecked**); how Pages serves a file whose name ends in `.tar.gz` and whose content is HTML; whether a directory path without trailing slash is redirected by Pages to the slashed form; what browsers, `wget`, Python `urllib`, Node `fetch` and `git`/the launcher's HTTP client do with each mechanism; whether Cloudflare's free plan offers redirect rules and what it requires of the DNS record (proxied vs DNS-only) — **all unverified**.

## Mechanisms to evaluate (candidates, not a recommendation)
| id | mechanism | what makes it attractive | what is unknown |
|---|---|---|---|
| A | A static HTML page on Pages with `<meta http-equiv="refresh">` (and a canonical link), generated per published version by the site build | no new service; E12 already rebuilds the site on every registry merge | not followed by `curl -L`; the URL must serve HTML, so it cannot end in a file that is itself served as a gzip |
| B | A Pages-hosted JavaScript redirect | none beyond A | not followed by any non-browser client |
| C | Cloudflare redirect rule / bulk redirect on a proxied hostname such as `archive.worldofmodcraft.com` | a real HTTP 301/302 that every client follows | needs the record **proxied**, reversing the DNS-only decision; plan limits unknown |
| D | Any other static host that supports a `_redirects` file or equivalent, behind a project hostname | real HTTP redirects | a new service and a new account; outside the mission as written |
| E | No redirect: store the `github.com` release URL and document the cost | nothing to build | not Q-G; it is the lock-in Q-G declined, listed only as the baseline of the comparison |

## Acceptance criteria
[local] = reproducible with `docs/tasks/058-verify.sh`, no network in the verdict; [live] = real service, run URLs/outputs pasted; [human] = observed by a person, recorded as such.
1. [local] **Client matrix against a local server.** A throwaway local server serves, for the same target bytes: a `302`, a `301`, a meta-refresh page, a JS-redirect page, and a directory path without trailing slash. For each of `curl -L`, `curl` without `-L`, `wget` (if installed — `which wget` is recorded either way), Python 3 `urllib.request`, and Node 24 `fetch` (`redirect: "follow"`), the script records: final URL, final status, whether the bytes equal the target's SHA-256. Output is a table in the report. The `302` row is the positive control (every client must reach the target); a matrix in which the positive control fails is a broken probe. The meta-refresh and JS rows are expected to fail for non-browsers (already observed for curl); the report states what each client actually did.
2. [local] **Filename behaviour.** For a path ending in `.tar.gz` served with each Content-Type (`text/html`, `application/gzip`), record what `curl -O -J`, `wget` and a browser would name the saved file — browsers via criterion 6 only; the local part covers the command-line clients.
3. [live] **What Pages emits.** Using a throwaway public repository with Pages enabled (manual step below), publish: a meta-refresh page at `/a/index.html`; the same at `/b.tar.gz` (HTML content in a `.tar.gz`-named file); a directory `/c/` requested as `/c`. Record, with `curl -sI` and `curl -s -D - -o /dev/null`, the status line, `content-type`, and `location` header (if any) for each. Any claim about Pages answering `3xx` is made only from these captures.
4. [live] **Does any HTTP redirect exist on Pages?** Try each documented-or-rumoured route that does not need credentials: a `404.html` page, a file named `_redirects`, a `CNAME`-less project path. Record the observed status codes. If none yields a `3xx` with a `location` header, the report says so in one sentence, with the captures.
5. [live, only if Ludwig approves a DNS change] **Hostname.** Whether a project hostname such as `archive.worldofmodcraft.com` can serve from a *different* repository's Pages than the apex site (a second CNAME + a second custom domain), and what Cloudflare record type and proxy setting that takes. This criterion changes DNS; it is **not** run without Ludwig's explicit in-session approval, and is otherwise recorded as `NOT RUN — needs Ludwig`.
6. [human] **Browser behaviour** for mechanism A and B on the live probe from criterion 3, in at least one desktop browser: does it follow the redirect, does it download or render, what file name is proposed. Observed by Ludwig, or by the manager with a browser tool and recorded as such. Unobserved cells are written `[UNVERIFIED — not observed]`.
7. [local+live] **The report** `docs/research/archive-url-probe.md` contains one table: rows = mechanisms A-E, columns = every client of criterion 1 plus browser, cells = `follows` / `does not follow` / `not tested` with the capture reference; then a section "What this means for the tasks that wait" naming, for each of 008a, 008b, 055, 010, 056, exactly which sentence of its spec changes under each outcome. It states **no recommendation beyond the comparison**; the choice, and any reversal of the DNS-only decision, is Ludwig's.
8. [local] `docs/tasks/058-verify.sh` runs criterion 1-2 deterministically (loopback only, ports chosen free by the script, servers killed on exit), is mutation-tested — break the redirect status in the server fixture, drop the SHA comparison, swallow a client error — each reddens a named check; run in a fresh clone; output pasted.
9. Every environmental fact in the report carries its command and output, or an inline `[unverified]` (guardrail 6b); a fact checkable here is run, not caveated (6c). Anything about Cloudflare plans or Pages internals is `[unverified]` unless observed in criteria 3-5.
10. The throwaway repository is deleted by Ludwig after the capture, and the report records that it was.

## Ludwig's manual step (live part only) — click-path **[UNVERIFIED]**, written from memory of GitHub's interface
1. Create a throwaway **public** repository (for example `worldofmodcraft/pages-probe`; any account works — an account with no other repositories is preferable) at `https://github.com/organizations/worldofmodcraft/repositories/new`, with a README.
2. Repository → Settings → Pages → Build and deployment → Source: **Deploy from a branch** → Branch `main`, folder `/ (root)` → Save. Wait for the Pages deployment (OPERATIONS.md: a Pages change can lag up to ten minutes).
3. Push the probe tree the task produces (`tools/probe/archive-url/pages-tree/`). Either Ludwig pushes it himself with commands the task prints, or he approves in session that the probe agent pushes through the session's already-configured git remote. **The agent never reads, prints or requests a token** (CLAUDE.md rule 11).
4. After the report is written, delete the repository: Settings → General → Danger Zone → Delete this repository.
*You should see:* the probe URL `https://<owner>.github.io/<repo>/` answering `200` on the paths of criterion 3.

## Explicitly OUT of scope
- Choosing a mechanism; amending `artifact-naming.md` (a sibling contract task, after this report); writing any URL function (008a).
- Any DNS change without Ludwig's in-session approval; any Cloudflare configuration; touching the production site repository or `worldofmodcraft.com`.
- Any credential use beyond the push in step 3 above.

## File scope (declared; anything else = stop and report)
Platform repo: `docs/research/archive-url-probe.md` (new), `tools/probe/archive-url/` (new: the local server fixture, the client-matrix runner, `pages-tree/`), `docs/tasks/058-archive-url-probe.md` (log), `docs/tasks/058-verify.sh` (new, executable). `docs/decisions/` and the mission spec are read-only.

## Forbidden here (beyond MANAGER.md §3.7)
- Reporting a Pages capability from documentation or memory instead of a capture.
- Leaving a probe server running, or the probe repository standing, after the task.
- Treating "no 3xx found" as "infeasible" without stating which mechanisms were tried; the report says *not found in these tries*.
- Any `gh auth`, token, `~/.config/gh` or secret command.

## Dependencies and sequencing
Needs nothing merged. **Blocks** (in the sense that their URL-dependent sentences wait): 008a (`source_archive_url`), 008b criterion 6's last clause, 055 criterion 3's URL shape and redirect allowlist, 010's runbook check of `source_archive`, 056's final pass, and the `artifact-naming.md` amendment sibling task. Runs in parallel with 032/045/057. Ludwig's manual step is needed only for the live criteria.
Graph: touches N6 and the E7/E8 value of `source_archive`; adds no node or edge.

## Verification artefact (MANAGER.md §2c)
Declared: `docs/tasks/058-verify.sh` for criteria 1-2 and 8. Criteria 3-6 are live or human and are recorded with their captures and said plainly not to be scripted.

## Questions  (agent-maintained; see MANAGER.md 8b)
- **For Ludwig, if the report finds no HTTP-redirect route on Pages:** accept a meta-refresh front that `curl -L` cannot follow (the launcher and the site can be built to handle it; third-party tools cannot) / allow Cloudflare proxying on a project hostname (reverses DNS-only) / fall back to the baseline E (the lock-in Q-G declined). Not asked now; this task produces the evidence.

---
# Task 058 log  (append-only, updated continuously by the executing agent)
- 2026-10-14 spec written under task 054 (decision Q-G). Two observations made while writing, commands in "What is already known": GitHub's release download answers 302 to `release-assets.githubusercontent.com`; `curl -L` does not follow meta refresh. Nothing else verified.
- 2026-10-14 implementer (local part). Built `tools/probe/archive-url/` (fixture_server.py, matrix.py, node_client.mjs, pages-tree/), `docs/tasks/058-verify.sh`, `docs/research/archive-url-probe.md` (partial). Criteria 1, 2, 8: demonstrated (output in the commit reply / verify run); mutation test: status-break, SHA-drop, error-swallow each reddened checks C1, C3, C6 respectively. First mutation attempt for "swallow" was NOT caught (no real errors in the clean run) so a refused-connection error control (C6) was added. Criteria 3, 4, 5, 6, 10: NOT RUN - needs Ludwig/manager (steps in the report). Criterion 7: table done for local cells; the "what this means for waiting tasks" mapping NOT DONE (needs live outcome). No push, no credentials, no DNS.
