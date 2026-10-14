# Task 008: The build pipeline — umbrella for 008a (core) and 008b (workflow)

- **Mission:** SITE-V1, deliverable **D2** — **Status:** draft (spec written 2026-10-14 under task 054). **Not dispatchable: blocked on the Ludwig questions below, and it touches signing, so merge needs Ludwig (MANAGER.md §7).**
- **Agent / model:** none directly; see 008a and 008b
- **Budget:** large + large. D2 is plainly larger than "large" (≤ 6 agent-sessions): it is a clone/validate/archive/sign tool, a second asset scanner wiring, a release upload, a protected-branch write-back, a post-merge workflow with a secret, and a contract nobody has written (E15). It is therefore split exactly the way D1 was split into 007 and 039: **the offline-demonstrable core (008a) and the live wiring (008b)**.
- **Branch / worktree:** none for this file; 008a and 008b carry their own. Both work in the **registry** repo.

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
Dependency: 008b needs 008a. They do not overlap in files.

## Graph (ADR-0117)
| | 008a | 008b |
|---|---|---|
| Nodes | **N5** build-pipeline (core), **N4** validation-core (manifest half added), N6 (asset naming only) | **N5** (workflow), **N6** artifact-store (the actual upload), **N2** (write-back target), **N3** (carve-out for the pipeline PR) |
| Edges | E1 (clone + `mod.lua`), E5/E6 (scanner invocation), E7 (names), E9 (signature bytes), E8 (the object it computes) | E7 (upload), E8 (write-back lands), E15 (post-merge trigger — **contract file missing**, see below), E16 (carve-out) |
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
be approved as written.** See Q1.

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
root … Undecided by the contract"). See Q2.

**F4. The ownership gate will reject the pipeline's own pull request.** Whoever opens the
write-back PR is not the namespace owner. A PR opened with the workflow's built-in token is
authored by `github-actions[bot]`, numeric id **41898282**:
```
$ curl -s https://api.github.com/users/github-actions%5Bbot%5D | grep '"id"'
  "id": 41898282,
```
`contracts/ownership.md` (unmerged registry PR #4) says the gate reads `pulls.user.id` only.
So the pipeline PR needs an explicit, narrow carve-out in the ownership gate — a CI-security
change (MANAGER.md §7: Ludwig). See Q3.

**F5. Events created with the workflow's built-in token do not trigger further workflows.**
*Unverified in this environment — stated from GitHub's documented behaviour; confirm by the live
experiment in 008b criterion 9.* If true, then (i) the write-back PR would never receive its
`pull_request` checks, so a required check would never report and the PR could not merge under
branch protection; (ii) merging it would not fire a `push` workflow, so neither the E12 site
dispatch nor any other `push`-triggered job would run after the write-back lands. The remedy
(a non-built-in credential for these three actions) is a credential and a manual step: Q3.

**F6. Releases need a home.** `contracts/artifact-naming.md` explicitly leaves open which
repository hosts the Releases. Q4.

**F7. What exists for the pipeline to reuse:** `tools/validation/scan_assets.py <DIRECTORY>`
(directory only; exit 2 is a usage error, not a rejection — OPERATIONS.md), `contracts/*.schema.json`,
`tests/contracts/schema_check.py`, `reserved-namespaces.json`. minisign 0.12 is installed on this
machine (`which minisign` → `/home/ludwig/.local/bin/minisign`; `minisign -v` → `minisign 0.12`);
its behaviour was exercised for these specs (see 008a).

## Acceptance criteria
1. 008a is `done` with `docs/tasks/008a-verify.sh` green on `main` and in a fresh clone.
2. 008b is `done` with `docs/tasks/008b-verify.sh` green, and its live criteria recorded.
3. The merged contracts and the pipeline agree (F1, F2 resolved by the contract task below).
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
`docs/tasks/008-build-pipeline.md` only (this file). Code and workflows are in 008a/008b.

## Forbidden here
- Dispatching 008a or 008b before Q1 and Q2 are answered and the contract task has landed:
  each would otherwise be coded against a schema its own output cannot satisfy.
- Resolving Q1-Q4 by assumption. They are written as questions because each one is an architectural
  decision or a credential.

## Dependencies and sequencing
Topological order (derived, not preferred):
`Ludwig answers Q1-Q4` → **contract amendments task (to be created by the manager: entry
schema / append-only / ownership for the pending→published write-back and the pipeline identity;
plus new `contracts/pipeline-trigger.md`; amends accepted contracts, so Ludwig approves)** →
task 007 spec re-check (it validates the author PR against the schema) → **008a** → **008b**
→ M3 verified by Ludwig → task 010 live publish. Tasks 041 and 055's site-side work are
independent of 008 until 055's cutover.

## Deliverables
This file, kept current as the sub-tasks land.

## Questions  (agent-maintained; see MANAGER.md 8b)
- **Q1 (blocks everything; F1): what is the shape of a version object between the author's PR and the write-back?**
  Options — A★) amend `entry.schema.json` and `append-only.rules.md`: a version object may exist
  as `{version, commit, source_url, status: "pending"}` and the write-back is the one new
  permitted in-place transition, `pending → published`, adding exactly the six fields
  (`source_archive`, `source_sha256`, `signature`, `key_id`, `published_at`, status change) and
  nothing else; the site and verifiers ignore `pending`. Matches E8, mission D1 and ADR-0058 §1
  literally. B) the author's PR adds a separate request file under a new path; the pipeline PR
  *appends* the complete version object (and creates `entry.json` at first publish). Append-only
  and the schema stay as merged, but E2 and the ownership gate move to a new file shape, and the
  namespace binding happens in the pipeline's PR, not the author's. C) fill the six fields with
  placeholder values in the author's PR — **rejected**: forbidden fake values, and the schema's
  hash patterns would force fabricated hashes. | assumed: A in 008a/008b's wording | built on
  assumption: the "pending" wording in 008a criterion 10 and 008b criteria 4-5; each would be
  rewritten under B.
- **Q2 (blocks 008a; F3): how is `mod.lua` read?** A★) a purpose-written static reader for a
  restricted literal-table subset (no execution; anything else rejected with a named message),
  projecting the eleven schema fields and ignoring kernel-only keys such as `depends`; the site
  gets the same subset (task 055). B) execute `mod.lua` under a real, sandboxed Lua in CI (needs
  Lua on the runner: unverified; execution of attacker-supplied code in the privileged workflow).
  C) require authors to ship `manifest.json` (deviates from ADR-0030). | assumed: A | built on
  assumption: 008a criteria 5-6, 010's mod contents.
- **Q3 (blocks 008b; F4, F5): which identity opens and merges the pipeline's write-back PR, and
  sends the cross-repo site dispatch (E12)?** A) the built-in workflow token for all of it —
  no credential to create, but F5 suggests the checks and downstream workflows will not fire.
  B★) a GitHub App installation token — a new credential (secret + app id) and one-time manual
  steps for Ludwig (create the app and install it on the registry and site repositories). C) a fine-grained personal access token for `womcraft`,
  stored as a repository secret — simpler, ties automation to a person-like account, expires.
  Whichever is chosen: it is a credential, so CLAUDE.md rule 11 applies (task file states why,
  Ludwig approves in session), and the ownership gate needs a carve-out keyed on that identity's
  numeric id. | assumed: none; 008b is written to be identity-agnostic where possible and says
  where it is not.
- **Q4 (blocks 008b; F6): where do the Releases live?** A★) on `worldofmodcraft/registry` itself
  (no new repository, no new Ludwig step; release tags like `test.hello-world-1.0.0` appear beside
  the registry's own refs). B) a dedicated `worldofmodcraft/artifacts` repo (cleaner separation,
  matches the graph's N6 as a distinct node, costs a Ludwig step to create it and a token with
  write access to it). | assumed: A | built on assumption: the URL shape in 008b criterion 3.
- **Q5 (non-blocking): is Software Heritage pinging (ADR-0041) in this mission?** The mission
  spec §4 D2 omits it. | options: A★) no, booked as a later task / B) yes | assumed: A.

---
# Task 008 log  (append-only, updated continuously by the executing agent)
- 2026-10-14 umbrella and split specs written under task 054; nothing dispatched.
