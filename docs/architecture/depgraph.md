# SITE-V1 dependency graph

- **Mission:** SITE-V1 (`docs/tasks/MISSION-worldofmodcraft-site-v1.md`)
- **Status:** accepted (session 1, 2026-09-02); all contracts decided — E9 and E15 settled by Ludwig's answers Q3=A, Q4=A
- **Amended:** 2026-09-05 — **E16 (ownership) added** on Ludwig's explicit approval (task 032, option A). See "Amendment log" at the end of this file.
- **Authority:** ADR-0117 (graph before code; every boundary edge names its contract)
- **Last reviewed:** 2026-09-05

Nodes are components, never files. Eight nodes, as ADR-0117 predicted for this mission.
Every edge crossing a component boundary names a contract; an edge without one is an
architecture error with exactly two fixes — define the contract, or merge the nodes.

## Nodes

| # | Node | Lives in | Responsibility |
|---|---|---|---|
| N1 | `mod-source` | author's own public git repo (external) | The mod at an exact tagged commit. Input to everything; owned by the author, not by us. |
| N2 | `registry-data` | `worldofmodcraft/registry` | The truth about mods: `mods/<ns>.<name>/entry.json` (versions, hashes, signatures) + `page.json` (page content). |
| N3 | `registry-ci` | `worldofmodcraft/registry` | Gates on every PR: schema, ownership by numeric id, append-only, PR classification. |
| N4 | `validation-core` | `worldofmodcraft/registry` | Reusable validators: magic-byte asset scanner (incl. GLB payload walk) + manifest/SPDX validator. Two consumers, hence its own node. |
| N5 | `build-pipeline` | `worldofmodcraft/registry` | Per accepted version: clone exact commit → validate → tarball → SHA-256 → sign → upload → write results back into N2. |
| N6 | `artifact-store` | org-owned GitHub Releases | Durable copies of source tarballs + signatures. Pages and installs point here, never at the author's repo (ADR-0041). |
| N7 | `site-build` | `worldofmodcraft/site` | Astro + Pagefind. Reads N2 and N6, emits static `dist/`. |
| N8 | `site-host` | GitHub Pages + DNS | Serves `dist/` over HTTPS on the apex domain. |

N4 is deliberately not merged into N5: the asset scanner has **two** consumers — the full mod
scan in the pipeline and the screenshot scan on `page.json` PRs (ADR-0059 §3) — so the boundary
is real and gets a contract.

## Edges (contract per edge)

| Edge | From → To | Contract | Where the contract lives |
|---|---|---|---|
| E1 | N1 → N5 | public git clone at an exact commit hash; mod layout + `mod.lua` fields | `contracts/manifest.schema.json` (ADR-0030 subset) |
| E2 | author → N2 | registry entry shape | `contracts/entry.schema.json` (ADR-0058 §2) |
| E3 | author → N2 | page content shape | `contracts/page.schema.json` (ADR-0059 §2) |
| E4 | N2 → N3 | immutability semantics: versions may be added, never modified or deleted (field-level diff) | `contracts/append-only.rules.md` |
| E5 | N3 → N4 | validator invocation: input path → JSON report + exit code | `contracts/validation-report.schema.json` |
| E6 | N5 → N4 | same validator contract as E5 | `contracts/validation-report.schema.json` |
| E7 | N5 → N6 | release tag + asset naming scheme for archived source and signature | `contracts/artifact-naming.md` |
| E8 | N5 → N2 | write-back fields: `source_archive`, `source_sha256`, `signature`, `key_id`, `published_at`, `status` | `contracts/entry.schema.json` |
| E9 | N5 → signing key | minisign (Ed25519) detached signature; `key_id` from the public-key comment; mod id + version + SHA-256 carried in the signed *trusted comment* | `contracts/signature-format.md` — decided (Q3=A) |
| E10 | N2 → N7 | read side of the entry and page schemas | `contracts/entry.schema.json`, `contracts/page.schema.json` |
| E11 | N6 → N7 | archive interior: `README.md` at tarball root, screenshots at manifest-declared paths | `contracts/archive-layout.md` |
| E12 | N2 → N7 | rebuild trigger: `repository_dispatch` event type + payload | `contracts/rebuild-trigger.md` |
| E13 | N7 → N8 | build output: `dist/` tree + `CNAME` | `contracts/site-output.md` |
| E14 | N8 → public | HTTPS on apex; URL scheme `/mods/<ns>/<name>` | `contracts/url-scheme.md` |
| E15 | N2 (merge to main) → N5 | **post-merge** trigger: the pipeline runs on `push`, never on the fork PR, because secrets are unreachable from fork-triggered workflows (Q4=A) | `contracts/pipeline-trigger.md` |
| E16 | author (forge identity) → N3 | ownership: the PR author's **numeric account id** is compared against `owner.id` for every namespace the PR touches; what a first publish binds; the ADR-0119 reserved-namespace case | `contracts/ownership.md` — added by amendment (Ludwig, 2026-09-05) |

## What the graph tells us

**Topological order.** The contracts are the root of the graph, not any component: E1–E14 name
eleven contract files, and every node reads at least one of them. Writing the schemas first is
therefore not ceremony — it is the only ordering that lets the next two subgraphs run at once.

**Parallelism from disjoint subgraphs.** Once the contracts exist, two subgraphs stop touching
each other:
- **Registry side:** N4 → N3 → N5 → N6
- **Site side:** N7 → N8 (codes against the schemas, with fixture data, before a real mod exists)

They rejoin only at N2/N6, which both sides reach through schema files rather than through each
other's code. This is the practical payoff of contract-first (ADR-0079) and is why the mission's
suggested order D1 → D2 → D5 → D3 → D4 can be shortened in wall-clock time without reordering
any deliverable: D3 (site) starts as soon as the contracts land, not after D2 (pipeline).

**The thinnest path through the graph** (ADR-0050's walking skeleton, applied here): one mod,
one version, straight through N1 → N5 → N6 → N7 → N8, with N3's gates stubbed to "pass". We do
not take that shortcut in this mission — mission §7.1 makes the *rejections* an acceptance
criterion, so N3 and N4 are load-bearing from the start — but it is the right shape to fall back
to if the mission has to be cut short.

**Undeclared edges to watch.** The following are *not* edges in phase 1 and adding one requires
updating this graph first: site → author's live repo (forbidden by ADR-0059 §1 — the archive is
the only source); site → any runtime/dynamic backend (mission §2 — the site is 100 % static);
registry-ci → the signing key (see E9 and mission log Q3 — the gate runs without secrets).

## Amendment log

### 2026-09-05 — E16 (ownership) added
**Approved by Ludwig in session**, task 032, option A. Amending an accepted graph is an
architecture change and was not made on the manager's authority.

**What was wrong.** `contracts/append-only.rules.md` deliberately does not reject a first publish
whose `owner` belongs to someone else — it delegates that to "the ownership gate", citing ADR-0058
§2-3. The delegation is correct: an append-only differ is the wrong place for an identity check.
But the edge table had no row for that gate and no contract file, so ownership existed only inside
**N3**'s one-line node description ("schema, **ownership by numeric id**, append-only, PR
classification") and in the mission spec's outcome 2. Under this file's own rule — "an edge without
[a contract] is an architecture error with exactly two fixes" — that was the error, not an omission
of documentation.

**Why it mattered enough to amend rather than note.** The risk was never that task 007 would forget
it: 007 builds N3 and would meet the requirement. The risk was that the defence against **namespace
capture** — the attack ADR-0058 §2 exists to prevent — would be implemented from an ADR read cold,
with no contract and no adversarial fixture, immediately after `append-only.rules.md` needed four
review rounds and one escalation to state its guarantee in a way that could not be satisfied
falsely. Every other boundary in this mission had a written agreement; the one where being wrong
costs someone their namespace did not.

**What E16 binds.** The comparison is against the forge's **numeric account id**, never the
username string — a username can be released and re-registered by someone else, a numeric id
cannot. `contracts/ownership.md` (registry repo) is the contract; task 007 implements it and must
carry the hostile fixture Ludwig required: **a PR whose author id differs from `owner.id` while the
username matches must be rejected.**
