# Task 091: runbook step M12 — a Cloudflare redirect from archive.worldofmodcraft.com to the archive's Release assets

- **Mission:** SITE-V1 (D2 archive URL, decision C) — **Status:** done (merged 2026-10-26, session 12; spec-approved by the manager, solo gate, 2026-10-26)
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
- 2026-10-26 doc-writer: added `## ☐ M12` to the runbook after M8 (before Q-H); no other runbook section touched (the
  header "Last reviewed" line left as is because `068-verify.sh` pins its text; M12 carries its own "Last reviewed
  2026-10-26 (task 091)"). Mechanism: Cloudflare Redirect Rule (Single Redirects), **Wildcard pattern** option, plus a proxied
  AAAA `archive` -> `100::`. Rule: Request URL `http*://archive.worldofmodcraft.com/*`, Target URL
  `https://github.com/worldofmodcraft/archive/releases/download/${2}`, status 302, Preserve query string off.
  Status choice: 302 (a 301 is cached as permanent, defeating the point of a repointable address).
  Sources, all fetched 2026-10-26 with WebFetch (summaries by the fetch tool's model, not raw HTML):
  - https://developers.cloudflare.com/rules/url-forwarding/ : Single Redirects and Bulk Redirects "require that you proxy the DNS
    records of your domain (or subdomain) through Cloudflare"; "available on all Cloudflare plans"; Single Redirects per zone
    Free 10 / Pro 25 / Business 50 / Enterprise 300; wildcard on all plans, regex not on Free or Pro. Page Rules appear only
    in the execution-order note, not as a redirect product there.
  - https://developers.cloudflare.com/rules/url-forwarding/single-redirects/create-dashboard/ : Rules Overview -> Create rule ->
    Redirect Rule -> rule name -> "When incoming requests match": Wildcard pattern / All incoming requests / Custom filter
    expression -> Request URL, Target URL (static, or dynamic with `${1}`, `${2}`), Status code, Preserve query string ->
    Deploy or Save as Draft; the dashboard may prompt to create a proxied DNS record for a matched hostname.
  - https://developers.cloudflare.com/rules/url-forwarding/examples/redirect-all-different-hostname/ : Request URL
    `http*://smallshop.example.com/*`, Target URL `https://globalstore.example.net/${2}`, 301, Preserve query string enabled
    ("keeping the original path and query string"). Basis for the `${2}` choice.
  - https://developers.cloudflare.com/rules/url-forwarding/examples/redirect-root-to-www/ : `https://example.com/*` ->
    `https://www.example.com/${1}`, 301, preserve enabled.
  - https://developers.cloudflare.com/rules/url-forwarding/single-redirects/settings/ : statuses 301, 302, 307, 308;
    Preserve query string "disabled by default"; the API form of a wildcard redirect is `wildcard_replace(http.request.full_uri, ...)`.
  - https://developers.cloudflare.com/ruleset-engine/rules-language/operators/#wildcard-matching : `*` = zero or more
    characters; operator case-insensitive; matched against `http.request.full_uri`, which includes the query string.
  - https://developers.cloudflare.com/ruleset-engine/rules-language/functions/#wildcard_replace : each `*` is a capture group,
    `${1}`..`${8}`.
  - https://developers.cloudflare.com/dns/manage-dns-records/how-to/create-dns-records/ : Dashboard -> DNS Records -> Add
    record -> Type -> fields -> Proxy status -> Save; originless setups use proxied `100::` or `192.0.2.0`, "work with
    Redirect Rules, Page Rules, or Workers".
  - https://developers.cloudflare.com/dns/proxy-status/ : only A, AAAA, CNAME can be proxied; proxied TTL Auto = 300 s;
    DNS queries answered with Cloudflare anycast addresses.
  - https://developers.cloudflare.com/ssl/edge-certificates/universal-ssl/ : Universal SSL on Free, certificates for the root
    and first-level subdomains, issued automatically for proxied hostnames.
  [unverified] and marked so in M12: (1) whether `${2}` includes the `?query` and whether Preserve-off strips it (the
  documented examples are consistent with the wildcard `*` excluding the query, but the pages never say; the full-URI
  match in the operator page points the other way); (2) whether the capture keeps the case of the request; (3) the exact
  Name/address field labels of the DNS form; (4) certificate issuance time for a new proxied subdomain. Two of the fetched URLs
  (examples/redirect-all-different-domain/, examples/redirect-new-domain/) returned 404 and were not used. The manager's
  curl block in M12 is the check for (1) and (2).
  Also observed: `curl -sI https://github.com/worldofmodcraft/archive/releases/download/v0/test` -> `HTTP/2 404` (used for the
  "you should see" text). No DNS or Cloudflare change, no credential.
  Verification (PYTHONDONTWRITEBYTECODE=1, foreground): `docs/tasks/068-verify.sh` ALL PASS exit 0; `068-verify.sh --mutate`
  all 12 mutations red, exit 0; 048, 052, 072 verify scripts (they mention only the mission log) exit 0. Nothing live was run.
- 2026-10-26 doc-writer, manager review fix (PR #82 FAIL): the wildcard Request URL is matched against `http.request.full_uri`,
  so `${2}` carries the query; the earlier "[unverified] query" item is resolved by switching mechanism. M12 Step 2 is now
  **Custom filter expression** `http.host eq "archive.worldofmodcraft.com"` with **Then**: Type Dynamic, Expression
  `wildcard_replace(http.request.uri.path, "/*", "https://github.com/worldofmodcraft/archive/releases/download/${1}")`,
  status 302, Preserve query string off. Manager's curl check now expects the query **absent** and `v0/Test` case kept; a
  sentence says GitHub tag/asset URLs are case-sensitive. Sources fetched 2026-10-26 (raw `index.md` pages via curl, since
  they return the page source):
  - https://developers.cloudflare.com/ruleset-engine/rules-language/functions/index.md : `wildcard_replace(source, wildcard_pattern,
    replacement, flags)`; "`source` must be a field"; whole value must match the pattern; each `*` is `${1}`..; matching
    case-insensitive by default; usable in target URL expressions of dynamic URL redirects; example
    `wildcard_replace(http.request.uri.path, "/*", "/apps/${1}")` on `/calendar` -> `/apps/calendar`; the full-URI example
    `https://apps.example.com/calendar/admin?expand=true` -> third capture keeps `?expand=true`.
  - https://developers.cloudflare.com/rules/url-forwarding/single-redirects/settings/index.md : Dynamic URL redirect = Expression
    (used as `Location`), Status code (301/302/307/308), Preserve query string (disabled by default); a wildcard URL redirect
    is `wildcard_replace(http.request.full_uri, ...)`.
  - https://developers.cloudflare.com/rules/url-forwarding/examples/perform-mobile-redirects/index.md : Expression Editor text for
    the match; **Then** Type: *Dynamic*, Expression `concat("https://m.example.com", http.request.uri.path)`, Status code.
  - https://developers.cloudflare.com/rules/url-forwarding/single-redirects/create-dashboard/index.md : Custom filter expression option.
  - https://developers.cloudflare.com/ruleset-engine/rules-language/expressions/edit-expressions/index.md : **Edit expression** next
    to the Expression Preview opens the Expression Editor.
  - https://developers.cloudflare.com/ruleset-engine/rules-language/fields/reference/http.host/index.md : "the `Host` header".
  - https://developers.cloudflare.com/ruleset-engine/rules-language/fields/reference/http.request.uri.path/index.md : "The URI path of
    the request", example `/articles/index`. The page does not say in words that it excludes the query; the field is separate
    from `http.request.uri.query` and the function page's path examples show no query. Treated as path-only; the manager's
    `?x=1` curl is the proof.
  Still [unverified]: exact dashboard label for the Hostname drop-down (Editor text used instead); that the Free-plan **Then**
  box shows "Type"/"Expression" as in the example pages; case of `${1}` beyond the doc examples (the `Test` curl proves it);
  the DNS form labels; certificate issuance time. Operator `eq` is the standard equality operator (used in the docs' own
  `http.request.uri.path eq "/contacts.html"`).
  Verification of this fix: `068-verify.sh` NOT re-run — other verify.sh scripts (008a, 039b, 062, 069, ...) were running for
  more than 30 minutes of polling, and the manager asked to run it only when none was; the edit leaves the M3-M7/Q-H
  sections and the header untouched, the first run of this task (before the fix) was ALL PASS. Needs a re-run by the manager.
- 2026-10-26 doc-writer: M12 ticked (heading ☑, status "done 2026-10-26 by Ludwig; manager's curl checks passed (see mission
  log)") on the manager's report of Ludwig's "Nu fungerar cloudflare redirecten till github" and the unauthenticated checks:
  `/mc.hello-world-1.0.0/mc.hello-world-1.0.0.tar.gz` -> 302 to the exact GitHub releases/download target; `+` kept; case kept
  (RC.1, Test); `?x=1` dropped; http:// -> 302 to https Location; root -> HTTP/2 302 `server: cloudflare`; certificate valid.
  The case-preservation and query-drop items are now "Observed 2026-10-26" in the runbook (source: the manager's report; I did
  not run the curls myself). Left [unverified]: certificate issuance time, DNS form labels, Hostname drop-down label, the Free-plan
  "Then" box field names, `http.request.uri.path` excluding the query in the docs' words (behaviour observed, wording not).
  068-verify.sh: PENDING, other verify.sh scripts were running at the time of this edit; manager to re-run (M12 is not among its markers; M4/M6 must stay ☐, untouched).
- 2026-10-26 manager (session 12): the PENDING runs are closed. On a quiet machine at 46f3a20: `068-verify.sh` 15/15 ALL PASS. After merging
  platform main (85's M6 tick; conflict only in this file, branch copy a superset) at d83d0b4: `068-verify.sh` ALL PASS, `085-verify.sh` ALL CHECKS
  PASSED. The live front was re-checked by the manager's `092-verify.sh --live` (2026-10-26T19:56Z) and agrees with the "Observed" text, including
  http:// -> 302 straight to the https GitHub URL. **Independent review (read-only): PASS-WITH-AMENDMENTS**, both LOW: (1) this status/log
  closing line — done here; (2) Cloudflare doc-sourced facts at runbook ~313-319 (Free plan 10 rules, no regex on Free, proxied TTL 300 s) carry no
  "(per Cloudflare docs, not observed)" marker — booked as a follow-up. Merged under Ludwig's overnight approval (mission log, session 12).
