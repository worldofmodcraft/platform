# Task 055: The site builds from the real registry, and a registry merge rebuilds it (E12)

- **Mission:** SITE-V1, deliverables **D3** (the "builds from the registry … rebuild triggered on every registry merge" part) and the live half of §7.4-§7.5 — **Status:** draft (spec written 2026-10-14 under task 054). **Not dispatchable until tasks 041, 057 and 008 (at least 008a) are merged, task 058 has reported, and the vendored-schema re-sync after 057 is done. The credential question is decided (Q-D, Ludwig 2026-10-14: the GitHub App); Q-K below is open but has a default.**
- **Agent / model:** implementer / sonnet
- **Budget:** large (≤ 6 agent-sessions). Two repositories, a signature verifier, a staging step, a sender and a receiver. If the manager prefers, split at the repo boundary: **055a site side** (criteria 1-9), **055b registry sender** (criteria 10-12); the criteria are written so they separate cleanly.
- **Branch / worktree:** `task/055-site-live-registry` / `~/wt/site-task-055` in the **site** repo (`worldofmodcraft/site`), and `task/055-site-live-registry` / `~/wt/registry-task-055` in the **registry** repo (`worldofmodcraft/registry`). One task id, two worktrees, two PRs; merge the registry sender **last** (see Dependencies).

## Objective
`https://worldofmodcraft.com` is built from the real registry and the real archived tarballs, not
from `fixtures/`: the deploy workflow checks out `worldofmodcraft/registry` at the commit that
triggered it, downloads the current version's tarball for each mod from its `source_archive`
URL (a project-owned URL that redirects to the release asset in `worldofmodcraft/archive`; decisions Q-G and Q-E), verifies hash and signature **before extracting** (`signature-format.md`, E9; closes the
TODO row in the site's `docs/build.md`), builds, and deploys. And a merge to the registry's
default branch causes that to happen with no human: a workflow in the registry sends
`repository_dispatch` with `event_type` exactly `registry-updated` and the two-field payload;
the site's workflow receives it, pins the checkout to `client_payload.commit`, and degrades
visibly when the payload is absent or malformed, as `contracts/rebuild-trigger.md` (E12) states.

## Does the site already have a receiver? (verified 2026-10-14)
**Yes, partly.** `.github/workflows/deploy.yml` on site `origin/main` already declares
`on: repository_dispatch: types: [registry-updated]` plus `push` to `main` and `workflow_dispatch`:
```
$ git -C /home/ludwig/site show origin/main:.github/workflows/deploy.yml | sed -n 15,22p
on:
  push:
    branches: [main]
  repository_dispatch:
    types: [registry-updated]
  workflow_dispatch: {} # manual "rebuild now" button, useful while wiring this up
```
What it does **not** do, each a gap this task closes: (1) it never reads `client_payload.commit`
(the workflow's own comment says "no payload fields read"); (2) the registry checkout and the
archive staging are commented out ("NOT YET WIRED UP"), so every run builds `fixtures/`; (3) there
is no E9 verification; (4) `concurrency: cancel-in-progress: true` means a dispatch arriving while a
deploy runs cancels the running one — the contract leaves concurrency behaviour to this task (its
"What this document does not cover"). The **sender does not exist**: the registry has no `.github/`
directory (`git -C /home/ludwig/registry ls-tree -r --name-only origin/main | grep -c '^\.github'`
→ `0`). The live site's last deploy was 2026-09-05 (`last-modified` header; Actions API shows
`workflow_dispatch` success and an earlier `push` failure) — the reconciliation table in
`docs/build.md` still lists E12 as "Still an open assumption", though `contracts/rebuild-trigger.md`
has since landed.

## Context to load (exhaustive)
- Task 057 (the `pending` state and the `pending → published` transition) and task 058's report (how the project-owned `source_archive` URL is served).
- ADRs: 0059 §1 (every registry merge triggers the build; archive, never the live repo), 0041
  (verify entry signature → hash → signature before install; keys; archive), 0058 §4 (provider
  neutrality: `source_archive` is an `https://` URL, any host), 0103, 0117, 0099.
- Contracts (registry `origin/main`): `rebuild-trigger.md` (all of it, incl. the "attack attempt"
  — a wrong `event_type` is silent), `archive-layout.md` (verify before extract; path-escape),
  `signature-format.md` (all eleven rejections, `key_id` reversal), `artifact-naming.md` (the
  URL shape the downloader may accept), `site-output.md`, `url-scheme.md`, `entry.schema.json`
  (as amended by task 057: `pending` versions exist and must be ignored).
- Site repo: `.github/workflows/deploy.yml`, `src/lib/{config,archive,registry,validate,semver}.mjs`,
  `scripts/prepare-content.mjs`, `scripts/self-test-archive-safety.mjs`, `docs/build.md` (the
  E9 TODO row, the fixtures section, "Assumptions bound to task 025"), `docs/tasks/009-site-build.md`.
- Platform docs: `docs/architecture/depgraph.md` (E12, E10, E11, E13), `docs/architecture/key-management.md`
  (the public key, `key_id` `6E5B30596A7A8CC4`), OPERATIONS.md ("GitHub Pages, learned during
  enablement": a Pages change can lag ten minutes — `cache-control: max-age=600`).
- Doctrine: MANAGER.md §2c, §3.6b, §3.6c, §3.7, §3.10; CLAUDE.md rule 11.

## Environmental facts (verified / not)
- **Verified 2026-10-14:** Node `v24.20.0` provides `crypto.getHashes()` including `blake2b512`,
  and Ed25519 verification from a raw 32-byte key works via `crypto.verify(null, …)` with an SPKI
  DER built from the raw key (`302a300506032b6570032100` prefix). So an E9 verifier needs no new
  dependency. minisign 0.12's `ED` signatures (prehashed, BLAKE2b-512) were produced and inspected
  in task 008a's research; the legacy `Ed` variant was not.
- **Unverified here; each tested by a criterion:** that GitHub-hosted runners can reach
  `github.com/…/releases/download/…` URLs and follow their redirects for a public repo (criterion 4);
  that `repository_dispatch` returns HTTP 204 and starts the receiving workflow only on the default
  branch's workflow file (documented GitHub behaviour; criterion 11); that a dispatch needs a
  credential with write access to the *target* repository, which the built-in `GITHUB_TOKEN` of the
  sending repository does not have (documented; this is the reason Q-D chose a GitHub App); and that Pages serves
  the new build within the ten-minute edge cache OPERATIONS.md records (criterion 12).

## Design (decisions made in this spec)
1. **Registry source:** `actions/checkout` of `worldofmodcraft/registry` into `registry-checkout/`,
   `ref` = the resolved commit (below). `REGISTRY_DIR=registry-checkout` — the existing configuration
   point, no code change in `src/lib/config.mjs`.
2. **Ref resolution** (`scripts/resolve-registry-ref.mjs`, offline-testable): input = event name and
   payload JSON; output = `{ref, warnings[]}`. `repository_dispatch` + `client_payload.commit`
   matching `^[0-9a-f]{40}$` → that commit. `repository_dispatch` with the payload missing, the
   commit missing, or not a 40-lowercase-hex string → ref = the registry's default branch,
   **and a warning that quotes what was expected and what was received verbatim** (E12), the build
   proceeds. `push` / `workflow_dispatch` → default branch, no warning (no payload is expected).
3. **Staging** (`scripts/stage-archives.mjs`, a step *before* `npm run build`; the Astro build itself
   still never touches the network — task 009's rule is kept): for each mod, the current version =
   highest `published` (existing `highestPublished`); `pending` and `removed` versions are never
   downloaded. The URL must match the project-owned shape fixed by decision Q-G, task 058's report and any
   `artifact-naming.md` amendment (**the hostname and path are not fixed by this spec — they come from
   058**; the tag part is derived from the entry's own id and version), and the redirect chain must
   end at `https://github.com/worldofmodcraft/archive/releases/download/<tag>/<tag>.tar.gz` (decision
   Q-E; the final host after GitHub's own redirect is unverified, see Q3). If 058 finds the front is an
   HTML meta-refresh page rather than an HTTP redirect, the staging script's handling of it is
   specified after 058, not guessed here. Any other `source_archive` is a hard failure naming the
   entry — the registry is data written by a pipeline, but a bad URL is never fetched. Size ceiling
   and timeout are constants in the script (assumed values below, Q3). Output path = what
   `localArchivePathFor` already computes, so `archive.mjs` is unchanged.
4. **E9 verification** (`src/lib/verify-signature.mjs`) runs after staging and before
   `extractArchive`, for the *current* version only (the one extracted). Implements all eleven
   rejections in `signature-format.md`; trusted public keys are committed at
   `trusted-keys/<key_id>.pub` (the 2026-09-02 public key from `key-management.md`, copied and
   cross-checked in the log against that document — public by design) and selected **by
   `key_id`**, never by trying each. Any failure → that mod's build fails loudly (not "degrade like a
   missing README": an unverified archive is a security event, not a content gap).
5. **Concurrency:** `cancel-in-progress: false`, group `pages`. Two close merges queue; each
   build pins its own commit, so the later one wins in order. (Today's `true` can cancel a deploy
   that is mid-flight and leave a stale site; judged worse than a short queue. Changing the
   behaviour is this task's decision, recorded in `docs/build.md`.)
6. **Sender** (registry): `.github/workflows/notify-site.yml`, `on: push: branches: [main]`, no path
   filter (a `page.json`-only merge still changes the site; `rebuild-trigger.md`). One step:
   `POST /repos/worldofmodcraft/site/dispatches` with `event_type` the literal `registry-updated`,
   `client_payload` `{commit: $GITHUB_SHA, triggered_at: <RFC3339 now, UTC>}`, asserting the HTTP
   status is 204 and failing the job otherwise (a silent failure is the contract's named attack).
   The credential (decided Q-D, Ludwig 2026-10-14) is a token minted from the organisation's GitHub App
   (the same App as task 008b; installed on `site`, M5) inside the sender step; the App's private key
   (`secrets.PIPELINE_APP_PRIVATE_KEY`) and id (`vars.PIPELINE_APP_ID`) are referenced only there.
7. **Empty registry is a supported state:** with zero published versions the build must succeed and
   show an honest "nothing published yet" browse state, so the cutover does not have to wait for the
   canary. (`loadMods` currently throws on a missing/empty `mods/`; changing that is a deliberate
   reversal of a 009 decision, recorded in `docs/build.md`.)
8. **Cutover:** `fixtures/` stays in the repository for tests and local builds
   (`npm run build` default) but the **deploy workflow never builds fixtures again**. The 009 note
   "delete fixtures in the same PR that points at the real thing" is superseded by this sentence,
   and `docs/build.md` is updated to say why (fixtures are test data, not content).

## Acceptance criteria
Site side — [script] = `docs/tasks/055-verify.sh` (runs in the site worktree, with the registry
worktree path as an argument for the cross-repo criterion 9); [live] = real run, recorded.
1. [script] **Ref resolution, all cases:** valid 40-lowercase-hex → pinned; absent payload,
   missing `commit`, 39 hex, 41 hex, uppercase hex, non-hex, `commit: null`, `commit: 123` (number)
   → default branch + a warning whose text contains the received value verbatim; `push` and
   `workflow_dispatch` → default branch, no warning. The valid case is the positive control. Mutation:
   relax the regex to accept uppercase; the uppercase case must redden.
2. [script] **Workflow shape** (greps that fail on zero matches): `types: [registry-updated]` present;
   the checkout step passes `ref:` from the resolver's output; `cancel-in-progress: false`; the
   registry checkout step exists and is **not** commented out; no step runs `npm run build` before
   staging and verification; no fixture path is passed to the deploy build. Mutation of each.
3. [script] **Staging, hostile inputs** (local HTTP server fixture on loopback; no real network):
   a `source_archive` on another host, `http://`, with a different tag than the entry's id+version,
   with `..` or encoded `%2e%2e`, a redirect to a different host, an over-size body, and a hang
   past the timeout → each fails naming the entry and the reason, and writes nothing into
   `ARCHIVE_DIR`. A well-formed local response is staged at the path `localArchivePathFor` computes
   (positive control). `pending` and `removed` versions: no request is made (the server's request log
   is asserted empty for them).
4. [live] **Real download:** a runner actually fetches a real release asset of the registry (after
   task 010 has published, or earlier against any public release created for the purpose without
   touching the registry) and the log shows the HTTP final status and the bytes' SHA-256.
5. [script] **E9 verifier against real minisign output.** Fixtures are generated by the real
   `minisign` binary with a throwaway key at fixture-creation time and committed with their
   (throwaway) public key: accepted — a correctly signed archive. Rejected, each its own check and
   each naming the violated rule number of `signature-format.md`: tampered archive byte (4 and 9);
   edited trusted comment (5); key-id bytes edited (6); `key_id` not in the trusted set (7);
   malformed or reordered trusted comment (8); `entry.source_sha256` ≠ trusted-comment sha256 (10);
   **valid signature for a different `id`/`version`** (11 — the contract's reuse attack); not four
   lines / wrong base64 length / algorithm bytes neither `Ed` nor `ED` (1-3). The `Ed` legacy
   variant is tested if `minisign -l` is available; if the fixture cannot be produced, the log says
   so and rule 3 is tested with a hand-built header.
6. [script] **The verifier is shown to fail first:** the verifier is written against a deliberately
   naive reference ("signature verifies the file's bytes") and the attack fixtures of criterion 5
   must be accepted by it (they are the naive verifier's blind spots) before the real implementation
   replaces it (MANAGER.md §2c rule 5). The log shows both runs.
7. [script] **Verify-before-extract is structural:** a test replaces `extractArchive` with a stub that
   records calls and runs the staging+verification pipeline over a tampered archive: the stub is
   called zero times. Mutation: move the verification after extraction; the test reddens.
8. [script] **Empty and fixture-free:** with `REGISTRY_DIR` pointing at a registry checkout containing
   no mods, `npm run build` exits 0 and `dist/browse` contains the "nothing published yet" state;
   with a registry containing one published version (staged locally), the mod page builds from the
   staged, verified archive and the build log prints the archive path it read (mission §7.4's
   "pointing at the archive paths in the build log"). `npm test` still passes.
9. [script] **Event-type literal agrees across repos:** `055-verify.sh <registry-worktree>` extracts
   the event type from the site's `on.repository_dispatch.types` and from the registry sender's
   `event_type`, and asserts both equal the literal in `contracts/rebuild-trigger.md` (`registry-updated`);
   a one-letter mutation in either file reddens the check. Fails if any of the three extractions finds nothing.
Registry side —
10. [script] **Sender shape:** greps (fail on zero) — `on: push` `branches: [main]` with no `paths:` key;
    `event_type` literal; payload keys exactly `commit` and `triggered_at`; the step fails on non-204;
    the App secret is referenced once (the token-minting step), never echoed, and no `GITHUB_TOKEN`/PAT fallback exists; no `pull_request*` trigger.
    Payload builder is a small script with unit tests: `commit` is 40 lowercase hex, `triggered_at` is
    RFC 3339 and passes `entry.schema.json`'s `published_at` pattern.
11. [live] **End to end, E12 and §7.5:** merge one real registry PR (it may be this task's own docs
    change); within five minutes `gh run list --repo worldofmodcraft/site` shows a run whose event is
    `repository_dispatch` and whose resolved ref equals the merge commit's SHA; the run succeeds and
    deploys. Then a malformed dispatch (sent by hand by Ludwig in session with a credential he
    controls — the agent does not craft one with a stored token or the App key) logs the E12 warning and still
    builds from the default branch. Run URLs in the log.
12. [live] **The public result:** after the deploy, `curl -sI` and a content fetch of
    `https://worldofmodcraft.com/` show the new build (compare a build-stamped marker — the build
    writes the registry commit it used into a comment in `dist/index.html` and into
    `dist/build-info.txt`, both in the verified `dist/` tree and neither containing a path), allowing
    for the ten-minute edge cache; the log states how long it took. After task 010's publish:
    `/mods/test/hello-world` returns 200 (mission §7.4). Lighthouse is task 009's and not repeated.
13. `055-verify.sh` exists, executable, mutation-tested (criteria 1, 2, 5, 7, 9), run in fresh clones
    of both repos; [script] and [live] separated in the log. Docs updated: `docs/build.md` (E12 row
    reconciled, E9 TODO row closed, cutover and concurrency decisions), `docs/design`-neutral.

## Explicitly OUT of scope
- Schema sync (task 041, done first). The pipeline (008). The test mod (010). Mod-page design.
- Verifying older versions' archives (the site only extracts the current one; the version list shows
  hashes from the entry). Booked as a known limit, not silently dropped: the launcher verifies on
  install (ADR-0041).
- `modcraft://`, Lighthouse tuning, changing contracts. If the manifest source (decided Q-C) needs
  the site to parse `mod.lua`, where that port is built is Q-K; it is **not** done here unless Q-K is answered A.

## File scope (declared; anything else = stop and report)
**Site repo:**
- `.github/workflows/deploy.yml`, `scripts/resolve-registry-ref.mjs`, `scripts/stage-archives.mjs`
- `src/lib/verify-signature.mjs`, `src/lib/registry.mjs` (empty-registry handling only),
  `src/pages/browse.astro`, `src/pages/index.astro` (empty state only), `scripts/prepare-content.mjs`
  (verification hook and build-info only), `scripts/verify-dist.mjs` (build-info check)
- `trusted-keys/` (new, public keys only), `scripts/tests/` and `fixtures/signatures/` (new)
- `docs/build.md`, `docs/tasks/055-site-live-registry.md` (log), `docs/tasks/055-verify.sh` (new, executable)
**Registry repo:**
- `.github/workflows/notify-site.yml` (new), `tools/notify/` (new, payload builder + tests)
- `docs/tasks/055-site-live-registry.md` (log copy), a short `docs/pipeline/` or `README.md`
  paragraph stating the trigger.

## Forbidden here (beyond MANAGER.md §3.7)
- Any stored credential read, printed or tried. The only credential in this task is the GitHub App
  (decision Q-D); it is created by Ludwig (M5, see `008b-pipeline-workflow.md`), stored only as a repository
  secret and variable, referenced in one step, never logged. A denied access is not retried.
- Fetching `source_archive` (or any URL) from the Astro build itself, from any `src/` module, or from
  anything other than `stage-archives.mjs`.
- Extracting an archive that has not passed `verify-signature.mjs`; "degrading" a verification failure
  into a warning.
- Trusting `entry.json`'s `source_sha256` as the hash (signature-format rejection 9 requires a fresh
  hash of the received bytes).
- A hard-coded `event_type` string typed independently in the two repositories — it is copied from the
  contract and criterion 9 checks it.
- Pinning the build to a stale registry commit by default; skipping the E12 payload warning.
- Editing `contracts/`, `docs/decisions/`, or the vendored schemas (task 041 owns their sync).
- Leaving `fixtures/` data reachable from the deploy path.

## Dependencies and sequencing
- **Needs:** task 041 merged (it adds the registry checkout step and the schema check to
  `deploy.yml`; 055 edits the same file — sequence, not parallel). Task 008a merged and 008b built
  (releases and signatures must exist in the real shape; criteria 3-9 use fixtures and do not need a
  real publish, criteria 4, 11, 12 do). Task 057 (entry `pending` state) merged, **and the site's
  vendored schema copies re-synced to it** — task 041 owns that sync and 055 may not edit them, so the
  manager books a small re-run of 041's sync after 057 merges (not written here). Task 058 reported.
- **Ludwig:** M5 done (GitHub App created and installed on `registry`, `site`, `archive`) before the
  sender's live criteria 11-12; M7 (archive repo) before criterion 4.
- **Order within the task:** site side first (merge), registry sender last — a sender merged before
  its receiver is verified would fire real dispatches at a workflow that cannot yet use them.
- **Blocks:** mission §7.3-§7.5 live; task 010's rehearsal of the later runbook steps.
- Graph: nodes **N2, N7, N8**; edges **E10, E11, E12, E13, E9** (the site-side verifier), **E14**
  (unchanged). **No new edge.** The cross-repository dispatch *is* E12.

## Verification artefact (MANAGER.md §2c)
Declared: `docs/tasks/055-verify.sh` (site repo; takes the registry worktree path). Script-verified:
1-3, 5-10, 13. Live and not scripted: 4, 11, 12 — recorded with run URLs and said so.

## Deliverables
Workflows + scripts + verifier + fixtures + tests + docs + verify script + both repos' logs current.

## Questions  (agent-maintained; see MANAGER.md 8b)
- ~~Q1 credential for the dispatch~~ **decided (Ludwig, 2026-10-14, Q-D):** the organisation's GitHub App,
  the same one as task 008b's pipeline identity, installed on both repositories, token minted per run.
  Options A (personal access token) and C (polling, which would have amended E12) are not taken.
- **Q-K (open, was Q2; non-blocking; the reader itself is decided):** Ludwig decided (Q-C) that `mod.lua`
  is read by a restricted static reader, so the site needs the same reader in JavaScript with a shared
  fixture corpus so the two readers cannot drift. *Where that port is built is not covered by his
  answers.* | options: A★) in this task (adds ~1 session) / B) a separate follow-up task, the page
  degrading to "licence unavailable" meanwhile (mission §7.4 requires the licence to show, so B would
  leave §7.4 open) | assumed: neither — criterion 8's mod page uses a fixture archive that carries
  `manifest.json` as today; **the licence display for a real publish is unresolved until this is answered.**
- **Q3 (open, assumption):** staging limits. | assumed: 50 MiB body ceiling, 30 s timeout, 3 redirects.
  The permitted redirect hosts change with decisions Q-G/Q-E: the project-owned host (from 058), then
  `github.com`, then the host GitHub redirects release downloads to. Observed 2026-10-14 (unauthenticated, a
  public release of another project, `curl -s -o /dev/null -w '%{http_code} %{redirect_url}' <release asset URL>`):
  `302` to `https://release-assets.githubusercontent.com/...` with a signed, time-limited query string — so the
  allowlist needs that host (not `objects.githubusercontent.com`, which earlier drafts assumed), and the final
  URL can never be the value stored in the registry. GitHub may change this; re-read it when implementing |
  built on: criterion 3.

---
# Task 055 log  (append-only, updated continuously by the executing agent)
- 2026-10-14 spec written under task 054; nothing started.
- 2026-10-14 Q-D, Q-E, Q-G folded in from Ludwig's answers; Q1 closed; Q2 renamed Q-K (reader decided, port location open); dependencies on 057/058/M5/M7 added.
