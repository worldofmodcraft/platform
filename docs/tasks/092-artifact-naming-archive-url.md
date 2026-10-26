# Task 092: `artifact-naming.md` fixes the archived-source URL as `https://archive.worldofmodcraft.com/<tag>/<asset>` (decision C)

- **Mission:** SITE-V1, deliverable **D2** (umbrella `docs/tasks/008-build-pipeline.md`, Dependencies (c): "the `artifact-naming.md`
  amendment for the project-owned `source_archive` URL, after 058"). **Status:** draft (drafted by a Plan agent, 2026-10-26;
  Q1-Q8 decided by Ludwig "Stjärna på allt", 2026-10-26). Contract amendment → **independent spec review before dispatch.**
- **Merge:** needs **Ludwig's written approval** (contract, ADR-0117; MANAGER.md §7). It fixes a value written once into an
  append-only record.
- **Repo:** registry (this file is copied to the registry branch's `docs/tasks/` as the log, as 057/082 did); platform: this file
  and the `depgraph.md` N6 row (Q6).
- **Agent / model:** doc-writer / sonnet (prose recording decided rules; precedent 082). **Budget:** small (≤ 2 agent-sessions).
- **Branch / worktree:** `task/092-artifact-naming-archive-url` / `~/wt/registry-task-092`, cut from registry `origin/main`
  (actual cut SHA = `BASE` in the log and `092-verify.sh`).
- **Graph:** edge **E7** (`N5 → N6`) amended; its reading side (N6 read by N7 and installers, E11's input) described, not
  changed. No new edge.

## Source
- **Ludwig, 2026-10-26:** "C star, repo deleted" (mission log `8a4f2ac`) — option C: a project-owned hostname with a real HTTP
  redirect at Cloudflare. "Stjärna på allt" — Q1-Q8 below decided as ★.
- **Task 058 report** (platform `docs/research/archive-url-probe.md`, merged `313e804`): Pages emits no 3xx to a chosen target;
  meta-refresh/JS are followed by no HTTP client tested (only a browser follows a meta-refresh); a local 301/302 is followed by
  every client; C "not eliminated, not tested".
- **Task 091** (platform PR #82, runbook **M12**): Cloudflare Redirect Rule, custom filter `http.host eq
  "archive.worldofmodcraft.com"`, dynamic target `wildcard_replace(http.request.uri.path, "/*",
  "https://github.com/worldofmodcraft/archive/releases/download/${1}")`, status **302**, Preserve query string off; proxied AAAA
  `archive` → `100::`. [unverified] there: case preservation of `${1}`, certificate issuance time, exact field labels.
- Decisions **Q-E** (Releases live in `worldofmodcraft/archive`) and **Q-G** (a project-owned URL fronts `source_archive` before
  the first publish), 008 umbrella. **ADR-0041**: "the registry points at our copy"; "verify hash → verify signature … no trust in
  hosting behaviour".

## Decisions (Ludwig, 2026-10-26, all ★)
- **Q1 = B:** no byte change to `entry.schema.json`; exact equality to the derived URL is enforced by producer and consumers (a
  pattern cannot tie the tag to `id`/`version`). No site schema re-sync.
- **Q2 = B:** "`source_archive` equals the derived URL" in T1 and the append-only checker is a **booked follow-up** (needs a 057
  pin refresh and checker code; T1 is "shape only" by design).
- **Q3 = A:** `contracts/examples/entry/**` `source_archive` values updated to the new shape, values only.
- **Q4 = A:** no fallback — if the front fails, consumers fail closed; never a self-built `github.com` URL.
- **Q5 = A:** before opening T1 the pipeline fetches `source_archive` through the front and requires its SHA-256 to equal
  `source_sha256`; mismatch = pipeline fault (082 PT10 exit 2: no T3, stays `pending`). Stated here; implemented in 008b.
- **Q6 = A:** `docs/architecture/depgraph.md` N6 "Lives in" cell gains "addressed via `archive.worldofmodcraft.com` (Cloudflare
  redirect, M12)"; no new node or edge; `depgraph.json` untouched.
- **Q7 = A:** AC11's live capture (after Ludwig completes M12) **gates the merge**.
- **Q8 = A:** `system-overview.md`'s "not chosen" rows are updated by the booked 056 second pass, not here.

## Objective
`contracts/artifact-naming.md` gains one deterministic function `(namespace, name, version) → archived-source URL` and the
obligations of every producer and consumer of it:
1. **URL:** `source_archive = "https://archive.worldofmodcraft.com/" + tag + "/" + tag + ".tar.gz"`, `tag` = `ns.nm-v` as the
   contract already defines; the signature asset `…/<tag>/<tag>.tar.gz.minisig` is derived, not stored (entry.json carries the
   signature inline).
2. **Redirect target:** `https://github.com/worldofmodcraft/archive/releases/download/<tag>/<asset>` — byte-for-byte what 008a's
   `naming.release_asset_url("worldofmodcraft", "archive", tag, asset)` returns, so 008a's closed test literals stay true.
3. **Consumer rules (normative; site 055, 008b's checks, task 010's runbook check, any later launcher/installer):** compare
   `source_archive` by exact string equality with the URL derived from the entry's own `id` and `version` (never parse and accept
   "close enough"); fetch over https with TLS verified; follow 301/302/307/308 with a bounded count; never execute or parse HTML;
   never send a query string; verify `source_sha256` and the signature (all of `signature-format.md`'s rejection rules 1-11) on
   the bytes at the end of the chain **before any use**; the host, the redirect and the chain are never a trust anchor.
4. **Fail closed (normative):** DNS failure, TLS failure, 4xx/5xx, a 200 with any body, a redirect elsewhere than the derived
   target, too many hops, hash or signature mismatch → the artefact is **unverified**: consumers do not install, extract or render
   it and never fall back to another URL (Q4); the producer does not write T1 (Q5) — the version stays `pending`.
5. **Stale text goes:** the "What this document does not cover" bullet about which repository hosts the Releases becomes the Q-E
   decision; "Questions" updated.
6. **Live capture before merge** (Q7): unauthenticated `curl` after M12.

## Context to load (reading list, 9)
1. Registry `contracts/artifact-naming.md` (whole). 2. `contracts/entry.schema.json` (`source_archive`, `^https://\S+$`).
3. `contracts/append-only.rules.md` T1 (condition 3; "T1 is checked for shape only"). 4. `contracts/signature-format.md` ("What is
signed"; "What a verifier must reject" 1-11 incl. rule 11's identity binding). 5. `contracts/archive-layout.md` lines ~19, ~195.
6. `tools/pipeline/naming.py`, `tests/pipeline/test_cli.py::test_ac12_*` (read-only), `docs/pipeline/build-pipeline.md` ~54.
7. `docs/contracts/README.md` (032 N5/N5b and 067 AC2.5 phrases "eight prose", "None of the three tasks implements checking
logic" — task 087 re-pins them; whichever merges first, both phrases survive). 8. Platform: 058 report; 091 spec/log (M12);
`008-build-pipeline.md` (F6, Q-E, Q-G); `008c-pipeline-write-back.md` (design 2, criterion 5); `008b-pipeline-workflow.md`
(criteria 3, 6; Forbidden on `source_archive`); `055-site-live-registry.md` (design 3, 4, Q3); `010-test-mod.md` ~96;
`depgraph.md` (N6, E7). 9. ADRs 0041, 0117, 0103; MANAGER.md §2c, §3.7; REVIEW-CHECKLIST items 8, 12; CLAUDE.md rule 11.

## Approach (the amendment's outline)
New section **"## The archived-source URL (`source_archive`)"** after "The naming scheme":
1. **Definition.** Constant host `archive.worldofmodcraft.com`; scheme `https`, no port, userinfo, query, fragment or trailing
   slash; the URL form; worked examples typed literally: `mc`, `hello-world`, `1.0.0` →
   `https://archive.worldofmodcraft.com/mc.hello-world-1.0.0/mc.hello-world-1.0.0.tar.gz`; its `.minisig` = that URL plus
   `.minisig`; `a`, `b`, `1.0.0-rc.1+build.5` →
   `https://archive.worldofmodcraft.com/a.b-1.0.0-rc.1+build.5/a.b-1.0.0-rc.1+build.5.tar.gz`; each example's redirect target.
   One sentence: this section is the only place the hostname is fixed; 008c's single named constant takes its value from here.
2. **Path safety and injectivity (derived, stated as such):** every character of `tag` is in `[0-9A-Za-z._+-]` (RFC 3986 `pchar`;
   no percent-encoding needed or permitted; `+` literal, `%2B` is a different string); no segment can be `.` or `..`; distinct
   triples give distinct URLs (name has no `.`; the semver major is a digit run ending at the first `.`). 092-verify checks it by
   property test.
3. **How the address works (pointer, not configuration):** a real HTTP redirect configured at Cloudflare per runbook M12
   (platform) — path-only, status 302 chosen in 091; consumers must not depend on which 3xx. Target = the `worldofmodcraft/archive`
   Release asset (Q-E); GitHub then redirects again to a signed, expiring asset host (`release-assets.githubusercontent.com`,
   observed in 058) which is never stored. M12 is the source of truth for the rule's syntax. [unverified], one sentence each:
   case preservation of the captured path (matters for uppercase prerelease identifiers); whether GitHub resolves a tag
   containing `+` in `releases/download`; certificate issuance for the proxied name. None is a trust dependency — point 6 catches
   each by failing closed.
4. **Producer obligations (008c, 008b):** `source_archive` is exactly the derived URL from the entry's own `id` and `version` —
   never from upload output, the API or `result.json` text; **before opening T1** the pipeline fetches it through the front under
   the consumer rules and requires the SHA-256 of the received bytes to equal its computed `source_sha256`; mismatch = pipeline
   fault (082 PT10 exit 2: no T3, stays `pending`, the run fails naming the URL) — the only point where a non-resolving URL can be
   stopped before it becomes permanent.
5. **Consumer obligations:** Objective 3, one sentence each, each pinned by full text.
6. **Fail closed:** Objective 4, spelling out "M12 not done yet: the name does not resolve" and "the host answers 200 with HTML (a
   meta-refresh page, 058 option A)" as failures — never "follow the HTML". No fallback to a self-built `github.com` URL (Q4).
7. **Attack attempts** (house style, numbered after the existing two): (3) a hostile or compromised redirect (Cloudflare account
   takeover points the front at attacker bytes or another genuine signed artefact) → hash mismatch or signature rule 11 (id and
   version in the trusted comment) rejects; at worst denial of service, never a substituted install. (4) a plausible variant URL
   accepted by a lenient consumer (`HTTPS://ARCHIVE…`, `%2B` for `+`, trailing `/`, `?x=`, `/../`) → exact string equality rejects
   all; the rule forwards any path, so a consumer fetching non-derived paths could be steered elsewhere on github.com — consumers
   fetch only the derived string, and verification still applies.
8. **"What this document does not cover", updated:** the "which repository hosts these Releases" bullet → "decided:
   `worldofmodcraft/archive` (Q-E, 008 umbrella F6)"; added: the Cloudflare rule's exact configuration (M12); `build_log_url` (a
   repository file at `logs/<ns>.<nm>/<version>.log`, not a Release asset — not served by this front; out of scope); enforcing
   equality in registry CI (Q2, booked). "Questions" → "(none open; task 092's Q1-Q8 decided by Ludwig on 2026-10-26)".
9. **`docs/contracts/README.md`:** in the `artifact-naming.md` row only, one clause naming the archived-source URL
   `https://archive.worldofmodcraft.com/<tag>/<asset>` (Cloudflare redirect to `worldofmodcraft/archive` Releases) and its
   fail-closed consumer rules. No other sentence changes.
10. **`contracts/examples/entry/**` (Q3):** `source_archive` values only, each to the URL derived from that example's id/version.

**Must not change** (each byte-identical `BASE`→`FINAL`): `entry.schema.json` (the site compares raw SHA-256 — no re-sync);
`append-only.rules.md` (T1 text incl. the `cdn.worldofmodcraft.org` example is pinned by `057-pinned-sections.json`, checked
live by closed 057-verify); `signature-format.md`, `archive-layout.md` (their "bytes … as retrieved" wording already covers the
end of a redirect chain).

**Closed scripts and pins (checked 2026-10-26 on registry origin/main):** no closed script pins `artifact-naming.md` text; the
only related pin is `tests/pipeline/test_cli.py` test_ac12 (run by 008a-verify) — the `github.com/…/releases/download/…`
literals, which stay true as the redirect target. A schema hostname pin would redden closed 065-verify AC2
(`https://cdn.example.org/a.tgz` valid) and 057 T1/F1 — the reason for Q1 = B. README: see context 7.

**Downstream sentences 092 does not edit** (the manager books them at merge): 008c design 2 / criterion 5 → this function;
008b criterion 3; criterion 6's "blocked until 058" → "fetched with `curl -L` through the front, bytes equal"; 008b gains the
pre-T1 check (Q5); 055 design 3 (shape fixed), Q3 allowlist `archive.worldofmodcraft.com` → `github.com` → GitHub's asset host,
the "if 058 finds HTML" clause struck, `localArchivePathFor` follows the new path; 010 ~96 ("resolves" = `curl -sL` + `sha256sum`
equals `source_sha256`); 056 second pass (Q8); 008 umbrella criterion 3 and Dependencies (c) done; the Q2 follow-up.

## Acceptance criteria → `docs/tasks/092-verify.sh` (the log pastes its output)
Deterministic and offline (stdlib Python and git) except AC11; exit code = number of failures; own-change checks on the fixed
`BASE`/`FINAL` (and `TIP` if needed) recorded in the script (item 12); live guards on HEAD in a temp clone; the caller's worktree
never modified.
1. **Section exists** at `FINAL`, absent at `BASE` (control); the file's first paragraph still names `E7`, `N5 -> N6`,
   `docs/architecture/depgraph.md`.
2. **Literals:** host, URL form, redirect-target form and the three worked examples byte-equal to literals typed into the script
   (never derived from the code or text under test).
3. **Three-way agreement:** each example's redirect target equals `naming.release_asset_url("worldofmodcraft", "archive", tag,
   asset)` (008a, imported read-only) and test_cli.py's literals; each example `source_archive` fullmatches `entry.schema.json`'s
   pattern in a `published` and a `removed` version document under both `tests/contracts/schema_check.py` and 007a's strict
   `tools/registry/schema.py`.
4. **Injectivity and path safety:** the script's own derivation over ≥ 2,000 generated triples (names with `-` and digits,
   prerelease and build versions, adversarial splits such as `x-1`/`2.3.4`): no collisions; no `%`, `..`, `//` after the authority,
   `?` or `#`; every URL matches `^https://archive\.worldofmodcraft\.com/[0-9A-Za-z._+-]+/[0-9A-Za-z._+-]+\.tar\.gz$`;
   reserved-device-name namespaces stay excluded (quote the unchanged rule).
5. **Normative sentences pinned by full text** (032 round-6 lesson), each exactly once: exact-string equality; https/TLS;
   bounded 301/302/307/308; never parse HTML; never send a query; hash and signature (rules 1-11) before any use; host never
   trusted; no fallback; producer computes from `id`/`version` only; the pre-T1 fetch-and-hash check (pipeline fault, stays
   `pending`); each fail-closed case; attack attempts 3 and 4; the three [unverified] markers of Approach 3.
6. **Stale text gone:** "no ADR or graph node fixes this" 0 at `FINAL`, ≥ 1 at `BASE`; the old Questions sentence replaced; the
   naming-scheme bullets (tag, tarball, `.minisig`), the Windows rule and attack attempts 1-2 byte-identical to `BASE`.
7. **No other contract changed:** `git diff --name-only BASE FINAL -- contracts/` = `artifact-naming.md` plus
   `contracts/examples/entry/**`; a parsed-JSON diff of each example shows only `source_archive` changed, each to its derived URL,
   `_comment` and validity verdicts unchanged; SHA-256 of `entry.schema.json`, `append-only.rules.md`, `signature-format.md`,
   `archive-layout.md` equal at `BASE` and `FINAL` (proof the site needs no re-sync). ADVISORY with `--site DIR`:
   `node DIR/scripts/check-schemas.mjs <clone at FINAL>` → `compared=3 differ=0`.
8. **README:** the `artifact-naming.md` row names the URL; "eight prose" and "None of the three tasks implements checking logic"
   still present.
9. **Pinned own-change scope:** `git diff --name-only BASE FINAL` inside the File scope; controls `FINAL=BASE` → red; unreachable
   pin → red, never skipped.
10. **`--mutate`** (temp clone; each red, restored byte-identically; positive control green): host → `.org`; join → `<tag>-<asset>`;
    target repo → `worldofmodcraft/registry`; example tag → `mc:hello-world-1.0.0`; the hash-and-signature-before-use sentence
    deleted; a permissive tail sentence appended to the consumer rules ("may fall back to the github.com URL"); an [unverified]
    marker dropped; one byte of `entry.schema.json`'s description changed (AC7 red); `signature-format.md` touched (AC7 red); a
    README phrase deleted (AC8 red).
11. **LIVE — gates the merge (Q7)** (network, unauthenticated; run by the manager after Ludwig reports M12 done; offline runs print
    NOT RUN and count as not green): `curl -s -o /dev/null -w '%{http_code} %{redirect_url}'` captures pasted in the log — (a) the
    `mc.hello-world-1.0.0` tarball URL → 3xx (302 per M12) with Location exactly its target; (b) the `+`-build URL and an
    uppercase-prerelease variant (`…-1.0.0-RC.1/…`) → Location keeps every byte, `+` and case; (c) the same URL with `?x=1` →
    Location carries **no** query (M12 is path-only; if it does, record and stop — the contract text must change); (d)
    `curl -sI https://archive.worldofmodcraft.com/` recorded; (e) the certificate is valid (plain `curl`, no `-k`). The end-to-end
    bytes check is 008b criterion 6 / task 010 (no Release exists yet).
12. **Fresh clone and closed scripts:** 092-verify passes in a fresh clone (item 8); every closed verify script on registry main
    at dispatch green on HEAD, one at a time on a quiet machine (`ps` logged).

## File scope
Registry: `contracts/artifact-naming.md` (new section, "does not cover" bullets, Questions); `docs/contracts/README.md` (the
`artifact-naming.md` row only); `contracts/examples/entry/**` (`source_archive` values only); `docs/tasks/092-artifact-naming-
archive-url.md` (log); `docs/tasks/092-verify.sh` (new). Platform: this file; `docs/architecture/depgraph.md` (N6 "Lives in" cell
only). Anything else = stop and report.

## Size
0 source files; ~80-140 lines of contract prose, 1 README row, ≤ 14 example files changed by value only, a verify script of
~250-350 lines; reading list 9.

## Forbidden (beyond MANAGER.md §3.7)
Any byte change to `entry.schema.json`, `append-only.rules.md`, `signature-format.md`, `archive-layout.md`; editing any closed
verify script, `057-pinned-sections.json`, `057-gen-fixtures.py`, `057-transition-fixtures.json`, `tests/` or `tools/`; changing
the tag or asset scheme or the reserved-device-name rule; writing `source_archive_url` (008c); Cloudflare or GitHub behaviour
without a command or `[unverified]`; presenting the redirect or host as a trust or integrity mechanism; any fallback URL; any DNS
or Cloudflare change, any GitHub write, any credential (CLAUDE.md rule 11); deriving an expected literal from the code or text
under test.

## Dependencies / sequencing
Upstream: 058 merged (`313e804`); 091 merged and **M12 done by Ludwig** before AC11 (AC1-AC10 can be written now). File overlap:
`docs/contracts/README.md` is also edited by 082 (#20) and 087 (#24) — rebase onto whichever merges first and re-run 032, 067 and
087. Downstream (booked at merge): 008c (unblocked) → 008b → task 010's first publish; 055 design 3 and Q3; the 056 second pass;
the 008 umbrella; the Q2 follow-up.

---
# Task 092 log
- 2026-10-26 Plan agent: spec drafted from decision C (`8a4f2ac`), the 058 report, 091's M12, the 008/008b/008c/055 specs and the
  registry at `4268735`. Measured: no closed script pins `artifact-naming.md` text; a schema hostname pin would redden closed
  065-verify AC2 and 057 T1/F1; the site compares schemas by raw SHA-256; the examples and 057 fixtures use
  `archive.worldofmodcraft.com` with a non-conforming path (`/kelsi/housing/1.0.0.tar.gz`); `system-overview.md` says "not chosen".
- 2026-10-26 manager: Q1-Q8 decided by Ludwig ("Stjärna på allt"); M12's final form (path-only expression) folded into Approach 3
  and AC11(c). Awaiting independent spec review.
