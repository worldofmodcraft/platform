# Task 008: The build pipeline — umbrella for 008a (core), 008c (write-back) and 008b (workflow)

- **Mission:** SITE-V1, deliverable **D2** — **Status:** draft (spec written 2026-10-14 under task 054). **Not dispatchable yet: Q1-Q4 are now decided (Ludwig, 2026-10-14, see "Decisions"), but the contract tasks (057 and the siblings listed under Dependencies), the archive-URL probe (058) and the manual steps M5-M7 must land first; it touches signing, so merge needs Ludwig (MANAGER.md §7).** Revised 2026-10-14 after Ludwig's answers.
- **Agent / model:** none directly; see 008a, 008c and 008b
- **Budget:** large + large. D2 is plainly larger than "large" (≤ 6 agent-sessions): it is a clone/validate/archive/sign tool, a second asset scanner wiring, a release upload, a protected-branch write-back, a post-merge workflow with a secret, and a contract nobody has written (E15). It is therefore split exactly the way D1 was split into 007 and 039: **the offline-demonstrable core (008a) and the live wiring (008b)**.
- **Branch / worktree:** none for this file; 008a, 008c and 008b carry their own. Both work in the **registry** repo.

## Objective
Mission D2 is done when both halves are done: given an accepted version in the registry, a
workflow on the registry's own branches clones the exact commit, validates the manifest and
licence, scans every file by magic bytes, produces a deterministic tarball, records its SHA-256,
signs it with the platform key, uploads tarball and signature as a GitHub Release under the
names `contracts/artifact-naming.md` fixes, and lands the results in the registry entry through a
same-repository pull request. This umbrella exists so that the ledger shows D2 whole; it holds
the findings that shape both halves and the questions that must be answered before either is
approved.

## Why split, and where the line is
- **008a — `docs/tasks/008a-pipeline-core.md`:** the tools. Pure functions of (git repo, commit,
  key file) to (tarball, hash, signature, result object, log). No network except cloning a repo
  the test supplies locally; no GitHub. Everything demonstrable offline with hostile fixtures,
  which is where this project's verification works (MANAGER.md §2c).
- **008b — `docs/tasks/008b-pipeline-workflow.md`:** the wiring. Workflow, secret handling,
  release upload, write-back pull request, the E15 contract, the ownership carve-out for the
  pipeline's own PR. Needs live runs, a protected repository and Ludwig's eyes.
- **008c — `docs/tasks/008c-pipeline-write-back.md`** (split out of 008a on spec review, 2026-10-14):
  the pure functions that depend on contracts not yet written — `apply_write_back` (the
  `pending → published` shape, task 057), `source_archive_url` (task 058's report), and the write-back
  view of the result. Offline, fixture-driven, like 008a.
Dependencies: 008c needs 008a, 057 and 058; 008b needs 008a and 008c. **008a needs neither 057 nor 058.**
No two of them overlap in files.

## Graph (ADR-0117)
| | 008a (+008c, write-back functions) | 008b |
|---|---|---|
| Nodes | **N5** build-pipeline (core), **N4** validation-core (manifest half added), N6 (asset naming only) | **N5** (workflow), **N6** artifact-store (the actual upload, into `worldofmodcraft/archive`, decision Q-E), **N2** (write-back target), **N3** (carve-out for the pipeline PR) |
| Edges | E1 (clone + `mod.lua`), E5/E6 (scanner invocation), E7 (names), E9 (signature bytes), E8 (008c: the object it computes) | E7 (upload), E8 (write-back lands), E15 (post-merge trigger — **contract file missing**, see below), E16 (carve-out) |
| New edges | none | none — but E15 and E8 need contract work first |

## Findings that shape both halves (each verified 2026-10-14; commands shown)

**F1. The contracts as merged make the pipeline's write-back impossible. This is the blocking one.**
`contracts/entry.schema.json` requires all nine fields on every version object, including
`source_archive`, `source_sha256`, `signature`, `key_id`, `published_at`. The author's publish PR
(ADR-0058 §1, E2) carries only id, version, commit and source URL. And
`contracts/append-only.rules.md` forbids modifying an existing version object, the one exception
being the `published → removed` takedown. So: (a) the author's PR cannot validate against the
schema, which task 007 requires of every changed file; (b) if it somehow did, the pipeline's
write-back would be a rejected in-place modification of a version object.
```
$ git -C /home/ludwig/registry show origin/main:contracts/entry.schema.json | python3 -c "
import json,sys; s=json.load(sys.stdin)
print(s['properties']['versions']['items']['required'])"
['version', 'commit', 'source_url', 'source_archive', 'source_sha256', 'signature', 'key_id', 'published_at', 'status']
$ git -C /home/ludwig/registry show origin/main:contracts/entry.schema.json | grep -n "absent until"
84:   ... Written back by the pipeline (edge E8); absent until the pipeline runs."
```
The schema's own text calls `source_archive` "absent until the pipeline runs" while listing it
under `required`: the contradiction is in the merged file (line 84 above).
The depgraph (E8: "write-back fields … `status`") and ADR-0058 §1 both assume a pending state
the contracts do not define. **This needs a contract decision before 007, 039, 008a or 008b can
be approved as written.** **Resolved by decision Q-B (Ludwig, 2026-10-14); the contract change is task 057** (`docs/tasks/057-version-lifecycle-contract.md`).

**F2. `contracts/pipeline-trigger.md` (E15) does not exist anywhere.** The depgraph lists it as
the contract for E15, which is a decided edge (Q4=A).
```
$ git -C /home/ludwig/registry ls-tree -r --name-only origin/main | grep -c pipeline-trigger        # prints 0
$ git -C /home/ludwig/registry ls-tree -r --name-only origin/task/032-ownership-contract | grep -c pipeline-trigger   # prints 0
```
(Both counts are 0 as of 2026-10-14. `origin/main` also has no `.github/` directory at all, so no
workflow of any kind exists in the registry yet.) Contract first (ADR-0117): E15 must be written
before 008b is approved.

**F3. The manifest the pipeline must validate is `mod.lua`, and nothing in the repo can read it.**
`contracts/manifest.schema.json` validates a JSON object. ADR-0030's manifest is a Lua file.
`tools/validation/` holds the asset scanner and `magic.py` only; there is no manifest reader, no
SPDX tool. `which lua lua5.4 luajit` on this machine prints nothing (Lua is not installed here,
and whether a CI runner has it is unverified). The site, separately, currently expects a
`manifest.json` at the archive root (`site: docs/build.md`, "E11: manifest.json at the archive
root … Undecided by the contract"). **Decided: Q-C (Ludwig, 2026-10-14) — a restricted static reader.**

**F4. The ownership gate will reject the pipeline's own pull request.** Whoever opens the
write-back PR is not the namespace owner. A PR opened with the workflow's built-in token is
authored by `github-actions[bot]`, numeric id **41898282**:
```
$ curl -s https://api.github.com/users/github-actions%5Bbot%5D | grep '"id"'
  "id": 41898282,
```
`contracts/ownership.md` (unmerged registry PR #4) says the gate reads `pulls.user.id` only.
So the pipeline PR needs an explicit, narrow carve-out in the ownership gate — a CI-security
change (MANAGER.md §7: Ludwig). **Decided: Q-D (Ludwig, 2026-10-14) — the pipeline acts as an org-owned GitHub App**, so the carve-out is keyed on that App's bot user id (known only after M5; an unauthenticated `GET /users/<slug>%5Bbot%5D` is the expected way to read it — *unverified for an App*, confirm after M5). The built-in token above is no longer the pipeline identity; F4's `41898282` stays as the id the carve-out must **not** accept.

**F5. Events created with the workflow's built-in token do not trigger further workflows.**
*Unverified in this environment — stated from GitHub's documented behaviour; confirm by the live
experiment in 008b criterion 9.* If true, then (i) the write-back PR would never receive its
`pull_request` checks, so a required check would never report and the PR could not merge under
branch protection; (ii) merging it would not fire a `push` workflow, so neither the E12 site
dispatch nor any other `push`-triggered job would run after the write-back lands. The remedy
(a non-built-in credential for these three actions) is a credential and a manual step: with Q-D decided, that credential is the GitHub App of M5. Whether an App installation token's events do trigger downstream workflows is likewise documented behaviour and *unverified here*; 008b criterion 9 tests it.

**F6. Releases need a home.** `contracts/artifact-naming.md` explicitly leaves open which
repository hosts the Releases. **Decided: Q-E (Ludwig, 2026-10-14) — a separate repository, `worldofmodcraft/archive`** (created by Ludwig, step M7). `artifact-naming.md` says the choice changes no input or output of the contract, so it needs no amendment for the repository name; the *URL* written into `source_archive` is a separate matter (decision Q-G, below).

**F7. What exists for the pipeline to reuse:** `tools/validation/scan_assets.py <DIRECTORY>`
(directory only; exit 2 is a usage error, not a rejection — OPERATIONS.md), `contracts/*.schema.json`,
`tests/contracts/schema_check.py`, `reserved-namespaces.json`. minisign 0.12 is installed on this
machine (`which minisign` → `/home/ludwig/.local/bin/minisign`; `minisign -v` → `minisign 0.12`);
its behaviour was exercised for these specs (see 008a).

## Acceptance criteria
1. 008a is `done` with `docs/tasks/008a-verify.sh` green on `main` and in a fresh clone, and 008c is `done` with `docs/tasks/008c-verify.sh` likewise.
2. 008b is `done` with `docs/tasks/008b-verify.sh` green, and its live criteria recorded.
3. The merged contracts and the pipeline agree: F1 resolved by task 057 (merged), F2 (`pipeline-trigger.md`), the ownership carve-out and the `source_archive` URL shape resolved by the sibling contract work listed under Dependencies (merged).
4. Mission §7.2 ("pipeline completes for `test:hello-world`: archived under the org, SHA-256
   recorded, signature + key_id recorded") is demonstrated by the first real publish, which is
   task 010's runbook — recorded there, referenced here. This umbrella is `done` only after it.
5. This is a coordination file with no code of its own: no `verify.sh`; criteria 1-4 are checked
   by reading the two sub-tasks' status. Said plainly so nobody mistakes "umbrella done" for
   evidence of its own.

## Context to load (exhaustive)
- ADRs: 0041 (integrity chain), 0058 (§1, §2, §3 publishing/ownership/namespace creation), 0059
  (§1, §3), 0030 (manifest), 0039, 0040 (§5 no-human-in-the-loop), 0099 (CI gates), 0103, 0117,
  0119 (reserved namespaces), 0120 (content whitelist), 0042 (versioning — confirms no
  monotonicity requirement).
- Contracts (registry `origin/main`): `entry.schema.json`, `append-only.rules.md`,
  `artifact-naming.md`, `signature-format.md`, `archive-layout.md`, `manifest.schema.json`,
  `validation-report.schema.json`; `origin/task/032-ownership-contract:contracts/ownership.md`
  (unmerged).
- Platform docs: `docs/architecture/depgraph.md`, `docs/architecture/key-management.md`,
  `docs/manager/OPERATIONS.md` ("Consequences of branch protection that bite later"),
  mission log Q3, Q4.

## File scope (declared)
`docs/tasks/008-build-pipeline.md` only (this file). Code and workflows are in 008a/008c/008b.

## Forbidden here
- Dispatching 008c or 008b before task 057 has merged: each would otherwise be coded against a
  schema its own output cannot satisfy. 008c additionally waits for task 058's report (the
  `source_archive` URL shape); 008b additionally waits for 008c and M5-M7 (below). 008a waits for
  neither 057 nor 058 and may start as soon as it is spec-approved.
- Re-opening Q-B..Q-G by assumption. They are decided; a change needs Ludwig.

## Dependencies and sequencing
Topological order (derived, not preferred):
task **032** merges (its fix round 6 is approved; it touches the contracts index) → task **045**
(takedown mutation shape in `append-only.rules.md`; same file as 057) → task **057** (version
lifecycle contract: `entry.schema.json` and `append-only.rules.md`, the `pending → published`
transition) → task **007** spec re-check (it validates the author PR against the amended schema;
057 is sequenced before 007 and before 008c/008b) → **008c** (also needs 008a and 058) → **008b** → M3 verified by Ludwig → task 010 live publish.
**008a is off that chain**: it needs only merged contracts and the scanner, and can run in parallel with 032/045/057/058.
In parallel, independent of that chain: task **058** (archive URL probe) must report before 008c
fixes `source_archive`'s shape; Ludwig's manual steps **M5, M6, M7** (below) must be done before
008b's live criteria.

**Contract work 057 does NOT cover (gap, for the manager to book as sibling tasks; not written
here because this task's scope is this file):** (a) `contracts/pipeline-trigger.md` for E15
(missing, F2); (b) the narrow ownership carve-out for the App's write-back PR in
`contracts/ownership.md` (E16) — it must be keyed on the transition 057 defines; (c) the
`artifact-naming.md` amendment for the project-owned `source_archive` URL, after 058. Each amends or
adds a contract, so each needs Ludwig's approval and the graph-first rule (ADR-0117).
Tasks 041 and 055's site-side work are independent of 008 until 055's cutover; 055 must re-sync the
site's vendored schemas after 057 merges.

## Ludwig's new manual steps (decided 2026-10-14; exact text lives in 008b)
- **M5** create the organisation-owned GitHub App (Q-D).
- **M6** add his personal account to the `worldofmodcraft` organisation (Q-F) — also serves task 010.
- **M7** create the `worldofmodcraft/archive` repository (Q-E).
Click-paths are in `008b-pipeline-workflow.md`, marked unverified where they could not be checked.

## Deliverables
This file, kept current as the sub-tasks land.

## Decisions  (Ludwig, 2026-10-14: "Stjärna på allt" — the starred option of each question; recorded in the mission log on branch `session/8-status`)
- **Q-B (was Q1; F1).** The author's PR adds a version object containing only `version`, `commit`,
  `source_url` and `status: "pending"`. The pipeline's write-back PR fills in `source_archive`,
  `source_sha256`, `signature`, `key_id`, `published_at` and sets `status: "published"`. This is
  the second permitted in-place transition beside the takedown. Written into the contracts by task 057.
  The other options (separate request file; placeholder values) are rejected.
- **Q-C (was Q2; F3).** `mod.lua` is read by a restricted static reader: a literal table only,
  never executed. (Option B, sandboxed Lua in CI, and C, a mandatory `manifest.json`, are not taken.)
- **Q-D (was Q3; F4, F5).** The pipeline acts as a GitHub App owned by the organisation, for the
  write-back PR, its merge, and the E12 site dispatch. Creating it is Ludwig's step M5. The
  ownership gate gets a carve-out keyed on the App's bot user id (sibling contract work, above).
- **Q-E (was Q4; F6).** Release assets live in a separate repository, `worldofmodcraft/archive`
  (Ludwig's step M7).
- **Q-F.** Ludwig's personal account joins the organisation (step M6); mission §7.6 stands as written.
- **Q-G.** A project-owned URL fronts `source_archive` before the first publish. Whether GitHub Pages
  can do this is **unverified**; task 058 is the probe. If 058 finds it infeasible on Pages, the
  question returns to Ludwig — this file does not pick a fallback.

## Questions  (agent-maintained; see MANAGER.md 8b)
- **Q5 (non-blocking): is Software Heritage pinging (ADR-0041) in this mission?** The mission
  spec §4 D2 omits it. | options: A★) no, booked as a later task / B) yes | assumed: A. (Not part
  of Ludwig's 2026-10-14 answers.)
- **Q-H (fact; open): does the `MINISIGN_SECRET_KEY` Actions secret exist on `worldofmodcraft/registry`,
  and is the offline backup done?** The mission log says M3 was completed 2026-09-05; no agent may
  check (CLAUDE.md rule 11; `gh secret` forbidden). Ludwig answers by looking at the secrets page
  himself. Blocks 008b's live criteria 6 and 10, not its script criteria.
- **Q-J (open; design hole, inherited from 008b): what removes a rejected pending version?** Append-only
  forbids deletion, and Q-B means a pending version sits on `main`. See 008b "Questions" for options
  A/B/C (lean ★C: PR-time dry build, so rejections never reach `main`). Also touches 057, which
  deliberately adds no `rejected` state.

---
# Task 008 log  (append-only, updated continuously by the executing agent)
- 2026-10-14 umbrella and split specs written under task 054; nothing dispatched.
- 2026-10-14 Ludwig's answers recorded (Q-B..Q-G); Q1-Q4 converted to decisions; Q-H, Q5 and Q-J remain open; sibling contract gaps listed under Dependencies.
- 2026-10-14 spec review: 008a split — 008c (write-back functions; needs 057 and 058) created; 008a no longer depends on 057/058; 008a gains https-only clone and tarball-hardening criteria. Graph note: `depgraph.json` carries E1-E15 while `depgraph.md` also lists E16; see 056 Q3.
