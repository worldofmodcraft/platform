# Mission: worldofmodcraft.com v1 — registry, pipeline and portal (Phase 1 infrastructure)

- **Project:** World of Modcraft
- **Mission id:** SITE-V1
- **Date issued:** 2026-09-02
- **Issued by:** Ludwig (project owner)
- **Executor:** Claude Code, operating under the manager model (see Working Rules)
- **Governing decisions:** ADR-0003, 0004, 0006, 0039, 0040, 0041, 0056, 0058, 0059 (in `docs/decisions/`; the full decision log is attached to this mission and MUST be read before any work)

---

> **Amended 2026-09-03 (task 027, approved by Ludwig per MANAGER.md §7):** §4 D1's version-object
> field list gained `key_id` (ADR-0041, depgraph edge E8 and `contracts/entry.schema.json` all
> carry it; D1 was the only place that did not), and §3's ADR count was corrected from 58 to 120.
> No other change.

## 1. Objective

Stand up the complete Phase-1 publishing infrastructure for World of Modcraft and prove it end-to-end with one test mod, so that:

1. `worldofmodcraft.com` is live, serving a **statically generated portal** with a start page, a browse view, search, and **one automatically generated mod page** for a test mod — including description, README, screenshots, tags, version list and licence, all synced automatically from the registry and archived source.
2. The **registry repository** exists with working CI enforcement (ownership by numeric account id, append-only versions, schema validation, asset scanning).
3. The **build/validation pipeline** exists (GitHub Actions) and runs on every registry PR: it fetches the tagged commit, validates the manifest, scans assets by magic bytes, archives the source tarball to platform storage, and signs it.
4. **Page content editing** works: changing `page.json` via PR updates the mod page without a new version, published immediately on green CI.
5. The whole chain has been demonstrated by publishing `test:hello-world` from Ludwig's personal GitHub account and then editing its page.

**Success is binary:** Ludwig opens worldofmodcraft.com, sees a well-designed portal, clicks into `test:hello-world`, sees its screenshots and README, and has watched the page change after a `page.json` PR — with zero manual steps beyond approving PRs and the one-time setup in §6.

## 2. Explicitly OUT of scope

Do not build any of the following in this mission, even partially, even as stubs beyond what §4 specifies:

- The kernel, the forks, the compiler, Lua, plugins, the launcher, `modcraft` CLI beyond nothing (the CLI is a later mission; this mission uses plain git/PRs).
- Plugin building, binary signing (source-tarball signing only), symbol checks, smoke tests.
- Telemetry, health panels, ratings, accounts, any server-side/dynamic component. The site is 100 % static.
- The `modcraft://` protocol handler (the install button renders but links to a "launcher coming soon" note plus the raw archived download).
- Any content for the roguelike mod.

## 3. Context you must load first

1. Read the entire decision log (`docs/decisions/`, 120 ADRs + index). The ADRs listed under "Governing decisions" above are binding for this mission; if anything in this spec contradicts an ADR, **stop and ask** — do not resolve it silently.
2. Key facts: platform name **World of Modcraft**; site **worldofmodcraft.com**; core namespace `mc:`; everything in **English**; mods may contain **only whitelisted original assets** (glTF/GLB, PNG, OGG); Blizzard formats (M2/WMO/ADT/BLP/DBC/MPQ) are rejected **by magic bytes, not extension**, including inside GLB containers; registry entries are **append-only**; namespace ownership is the **numeric GitHub account id**.

## 4. Deliverables

### D1 — Repository: `worldofmodcraft/registry`
- `index.json` (or per-mod files under `mods/<ns>.<name>/`): entry schema exactly per ADR-0058 §2 (`owner = { provider, id, name_at_registration }`, versions[] with `{ version, commit, source_url, source_archive, source_sha256, signature, key_id, published_at, status }`).
- `mods/<ns>.<name>/page.json` per ADR-0059 §2 (description, screenshots[], tags[], links[], deprecated).
- **CI checks (GitHub Actions), each with a clear failure message:**
  - JSON schema validation of every changed file.
  - Ownership: PR author's numeric account id must equal `owner.id` for every touched namespace; first publish of a namespace binds it (and the CI comment shows the ADR-0058 §3 confirmation text).
  - Append-only: a PR may add versions but never modify or delete an existing version object (field-level diff check).
  - `page.json`-only PRs skip the build pipeline and merge on green checks (immediate publish).
- `CONTRIBUTING.md` documenting the publish flow for humans (manual-PR path), including the namespace-permanence notice.

### D2 — Pipeline (in `worldofmodcraft/registry` or a dedicated `build` repo — your call, document why)
On every PR that adds a version:
1. Fetch the exact `commit` from `source_url` (any public git host — do not hardcode GitHub API for the fetch; use `git clone`).
2. Validate `mod.lua` manifest against the manifest schema (implement the schema for the fields in ADR-0030 that exist without the kernel: id, name, version, api_version, license, source, type, description, tags, screenshots, ai_assisted; `license` must be OSI-approved — validate against the SPDX OSI list).
3. **Asset scan**: walk every file; identify type by magic bytes; reject anything not on the whitelist (PNG, OGG, glTF/GLB, plus text/JSON/Lua/MD); for GLB, parse the container and scan embedded payloads; reject Blizzard formats explicitly with named detection.
4. Create source tarball of the exact commit; compute SHA-256; upload as a release artefact under the org (platform storage per ADR-0041); write `source_archive`, `source_sha256` into the entry.
5. Sign the tarball hash with the platform key (from repo secrets; generate the keypair as part of setup docs — see §6); write `signature` and `key_id`.
6. Post the full log as a PR comment on failure.

### D3 — Repository: `worldofmodcraft/site`
- Static site generator: **Astro**. Builds from the registry (checked out as input) + archived sources (README + screenshots are read from the **source tarball**, never the live repo — ADR-0059 §1).
- **Pages:** start page (what the platform is, honest "in development" status, link to decision log); browse page (all mods, filter by tag/type, sorted by recently updated); mod page per ADR-0059 (description, screenshot gallery, README rendered, version list with per-version commit hash + archived-source link + licence, tags, install button rendering the `modcraft://` URI with a "launcher coming soon" tooltip and a direct archived-download link); an "About / Licensing explained" stub page.
- **Search:** Pagefind, client-side.
- **Design:** distinctive and polished, not template-default. Dark, atmospheric, subtly fantasy-flavoured without using any Blizzard assets, names, fonts or iconography. Follow the frontend-design skill if available in the environment. Must look intentional on mobile and desktop. This is the public face of the project; treat visual quality as an acceptance criterion, not a nice-to-have.
- Deployed to GitHub Pages with `CNAME` for worldofmodcraft.com; rebuild triggered on every registry merge (repository-dispatch or scheduled pull — document the choice).

### D4 — Test mod: `test:hello-world`
- A repo under Ludwig's personal account (he creates it; you provide the full contents): `mod.lua` manifest (type "mod", MIT, description, tags, 2–3 screenshots), `README.md` with real formatted content, `assets/` with the screenshots (PNG, original images — generate simple original placeholder art; nothing Blizzard-derived), no code.
- A written, step-by-step runbook (`docs/runbooks/first-publish.md`) that Ludwig follows: create repo → tag release → open registry PR (manual path) → watch CI → merge → see the page → edit `page.json` → see the page change. Every step states what he should see and what it proves.
- The mod is kept afterwards as the permanent pipeline canary; note this on its page description.

### D5 — Documentation (in the site or registry repo as appropriate)
- `docs/decisions/` — the attached decision log committed as-is, plus ADR-0058/0059.
- Architecture note for this system: what runs where, what is stored where, "your server hosts nothing" (per conversation), how to move off GitHub later (provider-neutrality notes from ADR-0058 §4).
- Key-management note: how the signing keypair was generated, where the private key lives (Actions secret), the rotation procedure, `key_id` usage (ADR-0041).

## 5. Working rules (binding)

1. **Manager model (ADR-0054):** you act as manager; write no production code yourself in the manager role — decompose into tasks with acceptance criteria and delegate to subagents on the cheapest model that can do each task (mechanical scaffolding/boilerplate → smallest; CI logic, magic-byte scanner, generator → mid). Review every result against this spec before accepting.
2. **No silent shortcuts.** Specifically forbidden: extension-based file-type checks where magic bytes are specified; skipping the GLB-internal scan; reading README/screenshots from live repos instead of archives; hand-editing generated output; `TODO` left in place of an error; marking an acceptance criterion done without demonstrating it.
3. **Everything in English** (ADR-0056), including commit messages.
4. **Docs move with code:** any behaviour you implement that this spec did not fully specify gets a line in the architecture note; any deviation from an ADR requires stopping and asking.
5. Each work session ends with a written status: what was completed (mapped to §4/§7), what is blocked on Ludwig (§6), what is next.

## 6. Requires Ludwig (you cannot do these — list them, prepare them, wait)

1. Create the GitHub organisation `worldofmodcraft` (with hardware-key 2FA per ADR-0041) and the empty `registry` and `site` repos; grant Actions permissions.
2. Point worldofmodcraft.com DNS at GitHub Pages (you provide the exact records to enter).
3. Add the generated signing key to Actions secrets (you provide the generation command and instructions; the private key must never appear in a repo or log).
4. Create the `test/hello-world` repo under his personal account and push the contents you prepared; approve the registry PRs.

Prepare everything so each of these is a copy-paste or click-through with your instructions next to it.

## 7. Acceptance criteria (all must be demonstrated, in order)

1. Registry CI rejects: an entry with invalid schema; a PR from the wrong account for an existing namespace; a PR modifying an existing version object; a mod containing a file with DBC/MPQ/BLP/M2 magic bytes under an innocent extension; a GLB with a disallowed embedded payload; a non-OSI licence.
2. Registry CI accepts and pipeline completes for `test:hello-world`: source archived under the org, SHA-256 recorded, signature + key_id recorded.
3. worldofmodcraft.com serves over HTTPS on the apex domain; start page, browse and search work; Lighthouse performance ≥ 90 on the mod page.
4. `worldofmodcraft.com/mods/test/hello-world` shows description, rendered README, screenshot gallery, tags, licence, version 1.0.0 with commit hash and archived-source link, and the install button with launcher-coming-soon behaviour. All content demonstrably sourced from registry + archive (prove by deleting nothing but pointing at the archive paths in the build log).
5. A `page.json` PR changing the description and adding a screenshot merges on green CI and the live page reflects it after the automatic rebuild, with no version added.
6. The runbook (D4) has been executed by Ludwig end-to-end without improvisation.
7. The site's design has been explicitly reviewed and approved by Ludwig (criterion: he says so, after seeing it on mobile and desktop).

## 8. Estimate and sequencing

2–3 evenings of Ludwig-time expected (mostly §6 actions and reviews). Suggested order: D1 → D2 → D5(keys) → D3 → D4 → §7 walkthrough. Ask before reordering.
