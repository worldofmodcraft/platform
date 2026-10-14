# System overview: what runs where, what is stored where, and the way off GitHub

- **Status:** first version (task 056); a second pass is due after tasks 058, 008b, 055 and 010 land
- **Last reviewed:** 2026-10-15
- **Latest dependency date:** 2026-10-14 (the newest spec-approval this note depends on: tasks 058 and 056)
- **Authority:** mission SITE-V1 deliverable D5 (`docs/tasks/MISSION-worldofmodcraft-site-v1.md`); ADR-0006, 0039, 0040, 0041, 0058 section 4, 0059, 0077, 0103, 0117, 0119
- **Read together with:** `docs/architecture/depgraph.md` (the nodes and edges this note walks) and `docs/architecture/key-management.md` (the signing key; not repeated here)
- **Verified by:** `docs/tasks/056-verify.sh` (completeness, tagging, honesty and path checks; it cannot prove the prose is correct, see "State of this document")

This note answers five questions from the note alone: what runs where, what is stored where, why
the owner's machines host nothing, how a successor moves off GitHub, and what fails if each piece
disappears. It does not restate the contracts, the ADRs or the key note; it links to them.

## How to read the state tags

Every row of the tables below ends in exactly one tag, and the tag describes the state on `main` of
the repository concerned at the date above.

| Tag | Meaning |
|---|---|
| `built` | exists, and was observed for this note: the row cites `obs L<n>`, an observation (command and output) in the log section of `docs/tasks/056-architecture-note.md`. A row carrying an unverified marker is never `built`. |
| `specified` | specified, not built: a spec-approved task, an accepted ADR or a contract describes it; nothing on `main` runs it. Never read it as working. It is also used for items that exist according to a record (the mission log, the key note) but that no agent may or did observe. |
| `not built` | nothing on `main` and no approved specification beyond a mention; it may be deliberately deferred |

A bracketed marker that begins with the word unverified means the
statement rests on documentation, not on an observation made while writing this note.

## What runs where

Hosts, in one paragraph. The registry data (N2), the registry checks (N3), the validators (N4) and
the build pipeline (N5) live in `worldofmodcraft/registry` on GitHub and execute on GitHub-hosted
Actions runners. The artifact store (N6) is GitHub Releases in a separate repository,
`worldofmodcraft/archive`. The site build (N7) is Actions in `worldofmodcraft/site`; the site host
(N8) is GitHub Pages, with DNS at Cloudflare, records DNS-only. N1 is the author's own git host and
is not ours. Nothing in this list is a machine the project owner operates.

### Nodes

| Node | Component | Runs on | Triggered by | State |
|---|---|---|---|---|
| N1 | mod-source: the author's own public git repository (external; the canary repository, step M4, does not exist yet, task `docs/tasks/010-test-mod.md`) | the author's git host | the author pushing a tag; the pipeline clones it at an exact commit | `specified` |
| N2 | registry-data: `mods/<ns>.<name>/entry.json` and `page.json`, the contracts, `reserved-namespaces.json` in `worldofmodcraft/registry` | GitHub (git hosting). No `mods/` directory exists on `main` yet. | pull requests and merges (obs L4) | `built`  |
| N3 | registry-ci: the PR gates (schema, ownership by numeric id, append-only, PR classification). The registry has no `.github/` on `main`. Checkers are task `docs/tasks/007-registry-ci-checkers.md` (spec-approved); the workflow is `docs/tasks/039-registry-ci-workflow.md` (draft). | GitHub-hosted Actions runner | every pull request to the registry | `specified` |
| N4 | validation-core, asset scanner: `tools/validation/scan_assets.py` and `tools/validation/magic.py` | GitHub-hosted Actions runner when called by N3 or N5; any Python 3 for local runs | called by N3 (E5) and N5 (E6) (obs L6) | `built`  |
| N4 | validation-core, manifest and SPDX validator: no file for it on `main` | GitHub-hosted Actions runner | called by N3 and N5 | `not built` |
| N5 | build-pipeline: clone, validate, tarball, hash, sign, upload, write back. Core is `docs/tasks/008a-pipeline-core.md` (spec-approved); the workflow is `docs/tasks/008b-pipeline-workflow.md` and the write-back is `docs/tasks/008c-pipeline-write-back.md` (both draft). | GitHub-hosted Actions runner, on the registry's own `main` | a merge to `main` that adds a version (E15) | `specified` |
| N6 | artifact-store: GitHub Releases of the repository `worldofmodcraft/archive`. The repository did not exist when checked (see State of this document). | GitHub Releases | the pipeline's upload (E7) | `specified` |
| N7 | site-build, from fixture data: Astro and Pagefind, `site:.github/workflows/deploy.yml` in `worldofmodcraft/site`; builds from `fixtures/`, not from the real registry | GitHub-hosted Actions runner (`runs-on: ubuntu-latest`) | a push to site `main`, a manual dispatch, or a `registry-updated` dispatch (receiver present) (obs L5, L10) | `built`  |
| N7 | site-build, from the real registry and the real archive: task `docs/tasks/055-site-live-registry.md` (draft) | GitHub-hosted Actions runner | the registry's dispatch (E12) | `specified` |
| N8 | site-host: GitHub Pages serving `dist/` at the apex domain; DNS at Cloudflare, DNS-only | GitHub Pages servers; Cloudflare DNS | a deploy job from N7 (obs L1, L3) | `built`  |

Observed 2026-10-14: `curl -sI https://worldofmodcraft.com` answered `HTTP/2 200` with `server: GitHub.com`.

### Edges

Each edge is named by `docs/architecture/depgraph.json` (E1 to E15) or `docs/architecture/depgraph.md`
(E1 to E16). The State column is the state of the running mechanism, not of the contract text.
Contract files are in the registry repository and all exist on its `main` except E15's, see State of
this document.

| Edge | Carries | Executes on | Contract | State |
|---|---|---|---|---|
| E1 | N1 to N5: public git clone at an exact commit | GitHub-hosted runner, in the pipeline | `contracts/manifest.schema.json` | `specified` |
| E2 | author to N2: a registry entry in a pull request | GitHub pull request | `contracts/entry.schema.json` | `specified` |
| E3 | author to N2: page content in a pull request | GitHub pull request | `contracts/page.schema.json` | `specified` |
| E4 | N2 to N3: versions may be added, never modified or deleted | GitHub-hosted runner, in CI | `contracts/append-only.rules.md` | `specified` |
| E5 | N3 to N4: validator invocation, report and exit code | GitHub-hosted runner, in CI | `contracts/validation-report.schema.json` | `specified` |
| E6 | N5 to N4: the same validator contract | GitHub-hosted runner, in the pipeline | `contracts/validation-report.schema.json` | `specified` |
| E7 | N5 to N6: release tag and asset names | GitHub-hosted runner, pipeline upload | `contracts/artifact-naming.md` | `specified` |
| E8 | N5 to N2: six write-back fields into the entry, through a same-repository pull request (a direct push to `main` is refused by branch protection, `docs/manager/OPERATIONS.md`) | GitHub-hosted runner, pipeline | `contracts/entry.schema.json` | `specified` |
| E9 | N5 to the signing key: minisign detached signature | GitHub-hosted runner, key read from an Actions secret | `contracts/signature-format.md` | `specified` |
| E10 | N2 to N7: the site reads entry and page data, fixtures only | GitHub-hosted runner, site build; today against fixtures only | `contracts/entry.schema.json` (obs L10) | `built`  |
| E10 | N2 to N7: the same read, from the real registry (no `mods/` directory exists yet) | GitHub-hosted runner, site build | `contracts/entry.schema.json` | `specified` |
| E11 | N6 to N7: archive interior (README and screenshots in the tarball), fixture tarballs only | GitHub-hosted runner, site build; today against fixture tarballs, not N6 | `contracts/archive-layout.md` (obs L10) | `built`  |
| E11 | N6 to N7: the same read, from the archive repository's Releases (N6 does not exist) | GitHub-hosted runner, site build | `contracts/archive-layout.md` | `specified` |
| E12 | N2 to N7: `repository_dispatch` rebuild trigger. Receiver in `site:.github/workflows/deploy.yml`; sender not built (registry has no workflows) | GitHub Actions in both repositories | `contracts/rebuild-trigger.md` | `specified` |
| E13 | N7 to N8: `dist/` plus `CNAME` | GitHub Actions deploy job to Pages | `contracts/site-output.md` (obs L1, L5) | `built`  |
| E14 | N8 to the public: HTTPS on the apex, URL scheme `/mods/<ns>/<name>` | GitHub Pages | `contracts/url-scheme.md` (obs L1, L10) | `built`  |
| E15 | N2 (merge to `main`) to N5: post-merge push trigger. The contract file `pipeline-trigger.md` named by the graph does not exist on registry `main`. | GitHub Actions, registry | none on disk | `specified` |
| E16 | author's forge identity to N3: ownership by numeric account id (`pulls.user.id`) | GitHub-hosted runner, in CI | `contracts/ownership.md` | `specified` |

E16 is in `docs/architecture/depgraph.md` (added 2026-09-05 by approved amendment) but not in
`docs/architecture/depgraph.json`; this note covers it and reports the drift.

Related, decided and not built: the automated write-back and the rebuild dispatch run as an
organisation-owned GitHub App (decision Q-D). It is `specified` until Ludwig's step M5 is done and
checked.

## What is stored where

| Artefact | Location | Who can write it | Append-only | State |
|---|---|---|---|---|
| Registry entries (`entry.json`) | git, `worldofmodcraft/registry` `main` | the owner's pull request (E2); the pipeline's write-back pull request (E8) | yes by contract (`contracts/append-only.rules.md`); enforced by CI, which is not built | `specified` |
| Page content (`page.json`) | git, same repository | the owner's pull request (E3) | no, owners edit pages | `specified` |
| Contracts, `reserved-namespaces.json` | git, same repository | the manager via reviewed pull request; `main` is protected | no, but every change is a reviewed commit (obs L4) | `built`  |
| Source tarballs and signatures | GitHub Releases in `worldofmodcraft/archive` | the pipeline, through the organisation-owned GitHub App | intended (names are never reused, `contracts/artifact-naming.md`); Releases themselves are deletable by an organisation owner, so append-only is a convention, not a platform guarantee [unverified — never exercised]. | `specified` |
| `source_archive` URL | inside each version object in the registry entry | the pipeline write-back, once | yes: `contracts/append-only.rules.md` forbids changing it afterwards | `specified` |
| The project-owned redirect host that fronts `source_archive` | not chosen; task 058 reports whether GitHub Pages can do it | the owner (DNS and host settings) | no | `specified` |
| Signing private key (working copy) | Actions secret `MINISIGN_SECRET_KEY` on `worldofmodcraft/registry`, per the mission log, M3, 2026-09-05. [unverified — not checked: no agent may check it, CLAUDE.md rule 11] | the owner | not applicable | `specified` |
| Signing private key (offline backup) | the owner's side, as `docs/architecture/key-management.md` states; the backup is a file, not a service. [unverified — not confirmed: the mission log lists it as the owner's unconfirmed item]. | the owner | not applicable | `specified` |
| GitHub App private key | an Actions secret on `worldofmodcraft/registry`, plus whatever offline copy the owner keeps (decision Q-D). [unverified — until M5 is done]. | the owner | not applicable | `specified` |
| Public signing key, `key_id` `6E5B30596A7A8CC4` | `docs/architecture/key-management.md` | pull request to the platform repository | no (obs L8) | `built`  |
| Public key on the site (`trusted-keys/`) | site repository, task 055 | pull request to the site repository | no | `specified` |
| Public key in the launcher | the launcher; it does not exist | pull request | no | `not built` |
| Site `dist/` | the GitHub Pages deployment artefact; never committed (`contracts/site-output.md`) | the deploy job | no (obs L9) | `built`  |
| DNS records | Cloudflare name servers hold the zone (obs L3); the DNS-only setting is discussed under the runtime table | the owner | no | `built` |
| Organisation account `worldofmodcraft` (numeric id 324218296, from `docs/architecture/key-management.md`; the page answers, the id was not re-read, obs L7) | GitHub | the owner | no | `built` |
| Branch protection and repository settings of the three repositories: `main` requires a pull request and refuses a direct push, per `docs/manager/OPERATIONS.md` [unverified — not observed: the unauthenticated API call was rate-limited, L12, and a push test was not run] | GitHub | the owner | no | `specified` |
| Decisions, task ledger, mission logs | git, `worldofmodcraft/platform` | pull request; `main` is protected | history is kept by git (obs L11) | `built`  |
| Disaster mirror of registry, index and archives | a second host; ADR-0077 | a scheduled job | read-only copy | `not built` |

## The owner's machines host nothing

Precise meaning, which is testable: no machine owned or operated by the project owner runs a
process, listens on a port, or stores data that the platform needs in order to build, publish or
serve. Mission wording: "your server hosts nothing".

The owner's machines run development tooling only: Claude Code sessions, git clones, the `gh`
command, and `minisign` once for key generation (`docs/dev-environment.md`). If every one of those
machines is switched off, nothing in the table below stops.

Every process or service the platform needs at runtime, with where it runs. A job is automated work
and must run on a GitHub-hosted runner; a service answers requests.

| Process or service | Kind | Runs on | Triggered by | State |
|---|---|---|---|---|
| Registry PR checks (N3, N4) | job | GitHub-hosted runner (`ubuntu-latest`) | a pull request | `specified` |
| Build pipeline and write-back (N5) | job | GitHub-hosted runner (`ubuntu-latest`) | a merge to registry `main` | `specified` |
| Registry-to-site dispatch sender (E12) | job | GitHub-hosted runner (`ubuntu-latest`) | a push to registry `main` | `specified` |
| Site build and deploy (N7) | job | GitHub-hosted runner (`ubuntu-latest`) | a site push, a manual dispatch, a dispatch from the registry (obs L5) | `built`  |
| Platform ADR index gate | job | GitHub-hosted runner (`ubuntu-latest`) | a pull request to the platform repository (obs L5) | `built`  |
| Disaster mirror job (ADR-0077) | job | GitHub-hosted runner (`ubuntu-latest`); ADR-0077 does not name the runner [unverified — not specified] | a schedule | `not built` |
| Static site serving (N8) | service | GitHub Pages servers | an HTTPS request (obs L1) | `built`  |
| Release downloads (N6) | service | GitHub Releases servers | an HTTPS request | `specified` |
| DNS resolution for the apex domain | service | Cloudflare DNS | a DNS query (obs L3) | `built`  |
| Redirect host that fronts `source_archive` | service | not chosen, see "Moving off GitHub" | an HTTPS request | `specified` |

DNS-only is inferred, not seen: the A records resolve to GitHub Pages addresses and not to a Cloudflare proxy range (obs L3), and `docs/runbooks/site-v1-manual-steps.md` step M2 says grey cloud [unverified — the Cloudflare dashboard was not viewed].

The positive check for this table, which anyone can repeat:

```
$ git -C <site clone> show origin/main:.github/workflows/deploy.yml | grep -n 'runs-on'
35:    runs-on: ubuntu-latest
78:    runs-on: ubuntu-latest
$ curl -sI https://worldofmodcraft.com | head -2
HTTP/2 200
server: GitHub.com
```

Observed 2026-10-15. The two `runs-on` lines are every job in the site workflow; the platform's
`.github/workflows/adr-index.yml` also uses `ubuntu-latest`.

### The two honest exceptions

"Nothing" is not literally true of accounts. Two third-party-hosted but owner-controlled settings
exist, and losing the credentials to either is a handover risk:

1. **DNS: the Cloudflare account.** Whoever controls the records controls where
   `worldofmodcraft.com` points, including the future `source_archive` redirect.
2. **The GitHub organisation account** (`worldofmodcraft`). It holds the repositories, the Actions
   secrets, branch protection, the organisation-owned GitHub App of decision Q-D and that App's
   private key. The App is `specified`, not built. A credential-bearing item.

The offline backup of the signing key (`docs/architecture/key-management.md`) is a file on the
owner's side, not a service; nothing at runtime reads it. Its loss is a key-management risk, stated
in that note.

## Moving off GitHub

### The finding that matters most: `source_archive`

The registry format is provider-neutral: `owner.provider` is a field and the source requirement is "a
public git repo" (ADR-0058 section 4; `contracts/entry.schema.json`). The storage and the stored URLs
are not.

- `source_archive` is a stored URL inside an append-only record. `contracts/entry.schema.json`
  requires the pattern `^https://\S+$`, and `contracts/append-only.rules.md` lists `source_archive`
  among the fields that must be unchanged after the fact.
- If the tarballs were referenced as `github.com/.../releases/download/...`, a later move off
  GitHub could not rewrite those URLs. It would need either a redirect on a domain the project
  controls, or a contract change that allows the field to be rewritten.
- ADR-0077's statement that provider neutrality "makes repointing a DNS/URL change" holds only if the
  stored URL is on a domain the project controls.
- **Decision (Ludwig, 2026-10-14, Q-G): a project-owned URL fronts `source_archive` from the first
  publish.** State: `specified`, not built. Whether GitHub Pages can serve such a redirect is
  unverified until task `docs/tasks/058-archive-url-probe.md` reports; its report file does not
  exist yet. If 058 finds it infeasible, this section must record that finding and the open
  question, not the intended benefit. If it needs Cloudflare proxying, that reverses the recorded
  DNS-only decision and returns to Ludwig.
- Even when built, the redirect helps only while the project controls the domain and the host that
  answers it. The host is named by task 058's report; today there is none. If that host moves, every
  stored URL breaks with it unless DNS can be repointed to a replacement that answers the same paths.
- An observation, not a decision: the examples in `contracts/append-only.rules.md` use
  `cdn.worldofmodcraft.org`, while the registered domain is `worldofmodcraft.com`. Examples are not
  contract, but this note has not checked who holds the `.org` name [unverified — not checked].

### Every GitHub-specific dependency

| Dependency | Provider-neutral seam | What is not neutral today | Proof | State |
|---|---|---|---|---|
| Stored `source_archive` URL | a project-owned URL in front of the real location (Q-G) | the URL is frozen in append-only records; without the redirect, no seam exists | `contracts/entry.schema.json`, `contracts/append-only.rules.md` | `specified` |
| Publish path: a pull request to a GitHub repository | the registry is "a public git repo"; ADR-0058 section 4 says only this path is to be replaced, later, by portal upload | the PR is the only way in | ADR-0058 section 4 (`docs/decisions/0058-publishing-flow.md`) | `not built` |
| Ownership gate | the `owner.provider` field | the gate reads GitHub's `pulls.user.id`; another forge needs another reader | `contracts/ownership.md` | `specified` |
| Reserved namespaces | the record shape allows any provider | the organisation's numeric account id 324218296 is stored in `reserved-namespaces.json` for `mc` and `test` | `reserved-namespaces.json` in the registry (obs L4) | `built`  |
| CI and pipeline runtime | none: the workflows are GitHub Actions files | N3, N5 and N7 run only on Actions; recreating them elsewhere is work, not configuration | `site:.github/workflows/deploy.yml`; registry workflows are not built | `specified` |
| Rebuild trigger E12 | the contract names an event and a payload | `repository_dispatch` is a GitHub Actions feature | `contracts/rebuild-trigger.md` | `specified` |
| Artifact store | `contracts/artifact-naming.md` names tags and assets, not a URL | GitHub Releases is the store; any object store can hold the same names | `contracts/artifact-naming.md` | `specified` |
| Site host | `dist/` is plain files plus `CNAME`, so any static host serves it | GitHub Pages is the host; the deploy job uses Pages actions | `contracts/site-output.md`, `site:.github/workflows/deploy.yml` (obs L5) | `built`  |
| Branch protection | none | a setting of the GitHub organisation account; re-created by hand elsewhere | `docs/manager/OPERATIONS.md` [unverified — not observed, L12] | `specified` |
| GitHub App (decision Q-D) | none | an identity of the GitHub organisation account; re-created on the new forge | decision Q-D; step M5 not done | `specified` |
| Disaster mirror | ADR-0077: a scheduled push to a second host (Codeberg, GitLab or an S3-compatible bucket) | it is `not built`; the ADR places it in phase 1.5 | ADR-0077 (`docs/decisions/0077-disaster-mirror.md`) | `not built` |

### Exit procedure for a successor

Follow in order. Each step carries its state.

1. **Clone everything now, before anything else.** Clone `worldofmodcraft/registry`,
   `worldofmodcraft/site` and `worldofmodcraft/platform` (all three are public). Clone the
   `worldofmodcraft/archive` repository too and download its Release assets once it exists; Release assets are not part of a git clone and are downloaded separately [unverified — not tested here]. State: `specified`; the three repositories answer 200 without credentials (obs L2), the archive does not exist (404).
2. **Use the disaster mirror if one exists.** ADR-0077 says the mirror is a phase 1.5 item. It is
   `not built`: today there is no second copy of the tarballs except the authors' own repositories
   at the pinned commits, and whether a rebuild from them gives the same SHA-256 is [unverified — never exercised]. State: `not built`.
3. **Re-create CI under another runner.** The workflows are GitHub Actions files; the checks and the
   pipeline are tools (`tools/validation/`, 008a's pipeline tool) that run from a shell. State:
   `specified`.
4. **Re-key the signing identity if the old private key is unavailable.** Generate a new key and
   follow the rotation procedure in `docs/architecture/key-management.md`. Old signatures stay valid
   under the old public key, as `docs/architecture/key-management.md` states [unverified — documented, never exercised]. State: `specified`; the procedure is written and has never been run.
5. **Repoint DNS.** Change the Cloudflare records for `worldofmodcraft.com` to the new static host
   (`dist/` is plain files). State: `specified`; never run. Today the apex's A records point at GitHub Pages addresses and the name servers are Cloudflare's (obs L3).
6. **Repoint the `source_archive` redirect.** Change the redirect host's target to the new tarball
   location; the stored URLs stay unchanged. State: `specified`, depends on task 058.
7. **Replace the GitHub App.** Re-create the automation identity on the new forge, move its
   installation and the secrets, and delete the old installation. State: `specified`.
8. **Replace the ownership reader** with one for the new forge (`contracts/ownership.md`), and keep
   the numeric ids already stored; they are provider-qualified. State: `specified`.
9. **Accept what is lost:** the Actions run history and Release download counts do not move. State:
   `specified`; a statement, not an observed fact.

## If a piece disappears

Statements about behaviour that has never been exercised carry a bracketed unverified marker; none
of these failures has been rehearsed.

| Piece | What stops | What keeps working | Recovery |
|---|---|---|---|
| GitHub Actions | new PR checks, new builds, new site deploys (N3, N5, N7) | the last deployed site keeps serving from Pages; installs verify offline against the signature and hash (ADR-0041: "All local") [unverified — never exercised]. | re-create the jobs elsewhere (exit step 3); the shell tools do not need Actions |
| GitHub Releases / the archive repository | downloads of every tarball (N6), the site's archive reads, new publishes | the registry entries, the site's already-built pages, signatures and hashes | restore from the mirror: `not built`, so restore from the authors' repositories at the pinned commits; same-bytes rebuild [unverified — never exercised] |
| GitHub Pages | the public site | the registry, the pipeline, installs (they do not read the site) | deploy `dist/` to another static host; repoint DNS (exit step 5) |
| DNS / Cloudflare | the apex domain; the `source_archive` URLs if they are on that domain | the git repositories, `github.com` Release URLs, local verification | recover the Cloudflare account; if impossible, the stored `source_archive` URLs are unreachable and a contract change is needed |
| The signing key | new signatures under `6E5B30596A7A8CC4` | everything already signed; verification needs only the public key | rotate (`docs/architecture/key-management.md`). The rotation procedure replaces a key; it does not describe what to do with versions already signed by a key later found compromised. |
| The author's repository (N1) | new publishes from that author; a pipeline rebuild of that mod | the archived tarball, the signature and the registry entry, since the registry points at its own copy (ADR-0041) | none needed for existing versions; the author restores or the mod is taken down by a pull request |
| The registry repository (N2, N3, N5) | all publishes, the entry data for the site, E12 | the deployed site and the tarballs until the next rebuild; local clones carry full history | restore from any clone, or from the mirror (`not built`); append-only history is git history |
| The GitHub organisation account / the GitHub App | automation write-back and dispatch; any admin change | public repositories stay readable; the deployed site keeps serving [unverified — never exercised]. | recover the account; the owner holds the credentials (see the two exceptions above) |

## State of this document

- **Written:** 2026-10-15, by the task 056 doc-writer, first version; fix round 1 the same day re-tagged rows so that `built` means observed (observations L1 to L12 in the task log).
- **Date stamp rule:** the "Last reviewed" date is not earlier than the newest spec-approval date of
  the tasks this note depends on (2026-10-14).
- **Unverified markers in body:** 15
- **What `docs/tasks/056-verify.sh` proves:** the required sections exist; every node id and edge id
  in `docs/architecture/depgraph.json` (and every edge id in `docs/architecture/depgraph.md`) has a
  row; every row of the tables with a State column carries exactly one tag; every cited path
  resolves; no table row in the runtime table runs on an owner's machine and every job runs on a
  GitHub-hosted runner; the honesty strings are present and the forbidden phrases absent; no secret
  material is present; the depgraph carries a link to this note. It does not prove the prose is true.
  Criterion 9 (a reviewer who did not write this reads only this note and answers the five questions)
  is a human check, recorded in the task log.
- **Drift found, reported, not fixed (out of scope for this task):**
  1. `docs/architecture/depgraph.json` has edges E1 to E15; `docs/architecture/depgraph.md` also has E16
     (ownership). The json has not been regenerated. Whether it should be, and whether the
     write-back pull request needs its own ownership edge, is a graph update (ADR-0117), not assumed.
  2. E15's contract file, named by the graph as contracts/pipeline-trigger.md, does not exist on registry `main`.
  3. `contracts/append-only.rules.md` examples use the host `cdn.worldofmodcraft.org`; the registered
     domain is `worldofmodcraft.com`.
  4. The `source_archive` finding above: the contract stores a URL that cannot be rewritten.
- **Pending, all `specified`, not built:** task 058 (archive URL probe), 008b (pipeline workflow, the
  Releases location, the App), 055 (site from the real registry, E12 sender), 010 (the canary mod
  and runbook), and ADR-0121 (version lifecycle, a proposal on branch
  `proposal/adr-0121-version-lifecycle`, see `proposal/adr-0121-version-lifecycle:docs/decisions/0121-version-lifecycle-pending.md`;
  it would amend the append-only and entry statements above if accepted). Each flips rows from
  `specified` to `built` at the second pass.
- **Observed 2026-10-15:** `curl -s -o /dev/null -w '%{http_code}' https://github.com/worldofmodcraft/archive`
  answered `404`, so N6 is `specified`; the same check answered `200` for `registry`, `site` and
  `platform`.
- **Items that need a person to confirm (none was checked by an agent):** the working secret
  `MINISIGN_SECRET_KEY` exists (owner or manager with Ludwig's approval, never an agent); the offline backup
  exists (Ludwig); the GitHub App and its secret exist after step M5 (Ludwig); Releases deletion
  rights and append-only behaviour of Releases (a test on a throwaway repository); GitHub Actions
  and Pages failure behaviour (not exercised); whether a rebuild gives identical tarball bytes (task
  008a's verification); the runner of the ADR-0077 mirror (the task that builds it).
