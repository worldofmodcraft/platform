# Task 056: The D5 architecture note — what runs where, the server hosts nothing, and the way off GitHub

- **Mission:** SITE-V1, deliverable **D5** (architecture note; the key-management note and the committed decision log, the other D5 items, are already done — see Context) — **Status:** review (doc-writer, 2026-10-15; first version; second pass due after 058, 008b, 055, 010)
- **Agent / model:** doc-writer / sonnet
- **Budget:** small (≤ 1 agent-session) for the first version; a second small pass after 008b/055 land
- **Branch / worktree:** `task/056-architecture-note` / `~/wt/task-056` — **platform** repo (`worldofmodcraft/platform`). The mission lets D5 live "in the site or registry repo as appropriate"; this note goes in the platform repo beside `docs/architecture/depgraph.md` and `key-management.md`, the other D5 documents, so the three are read together. If Ludwig wants it served on the site as well, that is a separate, later task.

## Objective
`docs/architecture/system-overview.md` exists and lets a stranger answer, from the note alone and
without asking anyone, five questions: **what runs where** (every component of the dependency
graph, the machine or service it executes on, and what triggers it); **what is stored where**
(every durable artefact, its location, who can write it, and whether it is append-only);
**why the project owner's own machines host nothing** (no process, port, database or file store
that must stay up for the platform to work); **how a successor moves off GitHub** (every GitHub-specific
dependency, the provider-neutral seam for each, and what is *not* neutral today); and **what
fails if each piece disappears**. Every statement is tagged with its state — `built`,
`specified`, or `not built` — and is checkable against a file or a command.

## Context to load (exhaustive)
- ADRs: **0006** (openness, handover; "if the project dies" plan), **0039** (registry is a git repo),
  **0040** (verified builds, no human in the loop), **0041** (integrity chain, archiving, key in
  build secrets), **0058 §4** (provider neutrality; only the PR path is GitHub-specific), **0059**
  (static pages from archive), **0077** (scheduled disaster mirror; its text says "SITE-V1's D5
  documentation notes the mirror job as phase 1.5" — this note must), **0103** (restart is the unit),
  **0119**. ADR selection: INDEX.json lookups on "provider", "hosting", "archive", "mirror".
- Platform docs: `docs/architecture/depgraph.md` (the eight nodes and the edges — **`depgraph.json` carries fifteen, E1–E15 (checked 2026-10-14); `depgraph.md` also carries E16, ownership, added 2026-09-05 on Ludwig's approval (task 032) and absent from the json: a drift, see Q3** — the note's
  skeleton), `docs/architecture/depgraph.json`, `docs/architecture/key-management.md` (**read, link,
  do not duplicate**; D5's key note), `docs/manager/OPERATIONS.md` (repositories table; Pages notes;
  branch protection), `docs/dev-environment.md` (what runs on Ludwig's machines — needed to *state*
  that none of it is platform infrastructure), the mission §4 D5 and §1.
- Registry `origin/main` contracts for the byte-level facts the note links to instead of restating:
  `artifact-naming.md`, `signature-format.md`, `archive-layout.md`, `site-output.md`, `url-scheme.md`,
  `rebuild-trigger.md`. Site repo: `docs/build.md`, `.github/workflows/deploy.yml`.
- Task logs/specs of 008a, 008b, 055, 010 for what is *actually* built when the final pass runs.

## Facts the note must carry, with their basis (verified 2026-10-14 unless marked)
1. **Components and hosts.** N1 an author's own git host (external). N2 registry data and N3 CI,
   N4 validation, N5 pipeline: `worldofmodcraft/registry` on GitHub, run by **GitHub-hosted Actions
   runners** (basis: mission D2 and `deploy.yml` use `ubuntu-latest`; the registry has no workflows
   yet — `git ls-tree` of `origin/main` shows no `.github/`; 039/008b will add them). N6 artifact
   store: GitHub Releases in the separate repository `worldofmodcraft/archive` (basis: depgraph N6; repository decided by Ludwig, 2026-10-14, Q-E; created by his step M7, so `specified` until it exists — check `curl -s -o /dev/null -w '%{http_code}' https://api.github.com/repos/worldofmodcraft/archive` before tagging it `built`). The automated write-back and dispatch run as an organisation-owned GitHub App (decision Q-D; `specified` until M5 is done).
   N7 site build: Actions in `worldofmodcraft/site`. N8 site host: GitHub Pages with DNS at
   Cloudflare, records DNS-only (basis: `docs/runbooks/site-v1-manual-steps.md` M2, OPERATIONS.md
   "done and verified"). Live check to quote in the note: `curl -sI https://worldofmodcraft.com` →
   `HTTP/2 200`, `server: GitHub.com` (observed 2026-10-14).
2. **"The server hosts nothing."** The mission's phrase (D5, "per conversation") is given a precise,
   testable meaning: *no machine owned or operated by the project owner runs a process, listens on a
   port, or stores data that the platform needs in order to build, publish or serve.* The owner's
   machines run **development tooling only** (Claude Code sessions, git clones, `minisign` for the
   one-time key generation). What this needs the note to say plainly, and to verify rather than
   assert: the offline private-key **backup** is a file on the owner's side, not a service; the
   private key's working copy is a repository secret, not a file on a server (basis:
   key-management.md). The note names the two honest exceptions to "nothing": **DNS** (Cloudflare
   account) and **the GitHub organisation account** — both are third-party-hosted but
   owner-controlled settings (the organisation account also holds the GitHub App of decision Q-D and its private key, a credential-bearing item the note lists), and losing the credentials to either is a handover risk the note states.
3. **Stored where.** Registry data: git (append-only by CI). Source tarballs and signatures: Releases in `worldofmodcraft/archive`. GitHub App private key: an Actions secret on `registry` plus whatever offline copy Ludwig keeps (decision Q-D; existence unverified until M5).
   Signing private key: Actions secret `MINISIGN_SECRET_KEY` + owner's offline backup (existence of
   the secret is **unverified by this spec and may not be checked by an agent** — the note states
   it as "per the mission log, M3, 2026-09-05" with that attribution). Public key: embedded in
   docs, the site (task 055's `trusted-keys/`), later the launcher. Site `dist/`: Pages artefact,
   never committed (contracts/site-output.md).
4. **Provider-neutrality, honestly.** The registry *format* is neutral (`owner.provider`, "a public
   git repo" — ADR-0058 §4, `entry.schema.json`). What is **not** neutral and the note must list as
   a cost, with the proof for each:
   - **`source_archive` is a stored URL in an append-only record.** `entry.schema.json` requires
     `^https://\S+$` and `append-only.rules.md` forbids changing `source_archive` after the fact.
     If the tarballs were referenced at `github.com/.../releases/download/...`, a move off GitHub could not
     rewrite the URLs; it would need a redirect the owner controls (a URL on a domain the project
     owns) or a contract change. ADR-0077's mirror and "repointing is a DNS/URL change" only hold if
     the URL is on a domain the project controls. **Decided (Ludwig, 2026-10-14, Q-G): a
     project-owned URL fronts `source_archive` from the first publish.** The note states this as
     `specified`, **not** `built`, and says that whether GitHub Pages can serve it is unverified until
     task 058 reports; if 058 finds it infeasible, the note records that finding and the open question
     instead of the decision's intended benefit. Even when built, the redirect only helps while the
     project controls the domain and the redirect host: the note names that host (from 058) and says
     what is lost if it moves. This remains the note's most important finding and must not be softened.
   - The publish path (a PR to a GitHub repository) — ADR-0058 §4 says this is the one part to be
     replaced by portal upload later.
   - Ownership gate reads GitHub's `pulls.user.id` (`ownership.md`); another forge needs another reader.
   - Actions is the only runtime for N3/N5/N7; `repository_dispatch` (E12) is GitHub-specific.
   - Pages and Releases are GitHub features; `CNAME` + Pages are replaced by any static host, since
     `dist/` is plain files (`site-output.md`).
   - The org's numeric account id (`324218296`) is baked into the reserved-namespace records.
5. **Exit procedure** is a numbered list a successor can follow: what to clone (`registry`, `site`,
   `platform`; the mirror per ADR-0077 once it exists), what to re-create (CI under another runner),
   what to re-key (generate a new key per `key-management.md` rotation; old signatures stay valid),
   what to repoint (DNS, the `source_archive` redirect per Q-G and 058, the GitHub App's installation and secrets), and what is lost (the Actions run history,
   Release download counts). Each step is marked `built`, `specified` or `not built`; the mirror is
   `not built` (ADR-0077 says phase 1.5) and the note says so.
6. **Failure table:** for each of GitHub Actions, Releases, Pages, DNS/Cloudflare, the signing key,
   the author's repo, the registry repo — what stops working, what keeps working (static site keeps
   serving; installs verify offline: ADR-0041 "All local"), and the recovery. Statements about
   behaviour that has never been exercised are tagged `[unverified — never exercised]`.

## Acceptance criteria
[script] = `docs/tasks/056-verify.sh`; [human] = recorded review.
1. [script] The file exists and has the required top-level sections, each found by exact heading
   (the script fails if a heading is absent **or if the count of found headings is zero**):
   *What runs where*, *What is stored where*, *The owner's machines host nothing*, *Moving off
   GitHub*, *If a piece disappears*, *State of this document*.
2. [script] **Every node and edge of the graph is covered:** the script reads the node ids and edge
   ids out of `docs/architecture/depgraph.json` and asserts every id it reads (today N1-N8 and E1-E15) appears in the
   note's tables, and separately lists any edge id present in `depgraph.md` but not in the json (today E16) and asserts the note covers it too and names the drift in *State of this document* (the ids are never hard-coded in the script); mutation: remove one row, the check names it. (`depgraph.json` carries `nodes[].id` and `edges[].id` — checked 2026-10-14 — so the script reads them from there, not from prose.)
3. [script] **State tags:** every row in the two main tables carries exactly one of `built`,
   `specified`, `not built`; no untagged row; the count of `[unverified` markers is stated in the
   *State of this document* section and equals the count in the body (a conjunction, so it fails if
   either is missing — §2c rule 3).
4. [script] **Cited files exist:** every path of the form `` `docs/…`/`contracts/…`/`.github/…` `` the note
   cites is resolved — platform paths against the worktree, registry/site paths against
   `git show origin/main:<path>` of the respective repo — and the script fails on any that does not
   exist, naming it, and on a note that cites **zero** paths. Paths on an unmerged branch are cited
   as `branch:path` (MANAGER.md §8b.5) and checked with `git cat-file -e`.
5. [script] **"Hosts nothing" is not a slogan:** the note contains a table of *every process or
   service the platform needs at runtime* with a "runs on" column; the script asserts no row in that
   column names the owner's machine, WSL, a VPS or "self-hosted", and asserts a positive control
   file containing such a row is caught. The same table must name the GitHub-hosted runner as the
   executor of each automated job.
6. [script] **Honesty guards:** the note must contain the strings `source_archive` and `append-only`
   within the *Moving off GitHub* section (the finding in fact 4), the words `phase 1.5` and
   `ADR-0077` (the mirror), and must **not** contain the unqualified sentences "fully provider-neutral",
   "vendor-neutral" or "no lock-in" (grep; positive control file that does).
7. [script] **No secret material:** no line matches the minisign secret-key header, a 40-char
   GitHub token pattern (`ghp_`/`github_pat_`), or the private key path `wom-keys`; the public key
   and `key_id` `6E5B30596A7A8CC4` are allowed and, if quoted, equal `key-management.md`'s text exactly.
8. [script] **Docs index:** `docs/architecture/depgraph.md`'s header or `docs/manager/OPERATIONS.md`'s
   repositories table links to the note (one-line addition), and a "last reviewed" stamp with a
   date ≥ the date of the latest task it depends on appears in the note's header.
9. [human] A reviewer who did not write it reads only the note and answers the five questions in the
   Objective; wrong or missing answers are findings. The reviewer is a full-tools agent at the same
   tier or higher, or Ludwig, recorded (the roster's `reviewer` cannot run the verify script —
   OPERATIONS.md).
10. `docs/tasks/056-verify.sh` exists, is executable, mutation-tested (criteria 2, 4, 5, 6), run in a fresh
    clone, its output pasted in the log; [script] and [human] results kept apart.

## Explicitly OUT of scope
- Changing any contract, ADR or the dependency graph. If the note finds a contradiction (it is
  expected to find one: fact 4, first bullet), it **reports** it in *State of this document* and the log.
- Implementing the disaster mirror, a redirect domain, or provider migration tooling.
- Re-stating `key-management.md`, the contracts' byte-level rules, or the ADR text: link, do not copy.
- Serving the note on the website.
- The mission's other D5 items (decision log commit; key note), which exist.

## File scope (declared; anything else = stop and report)
In the **platform** repo only:
- `docs/architecture/system-overview.md` (new)
- `docs/architecture/depgraph.md` — **one line**, a link to the note in the header (criterion 8); no change to nodes or edges
- `docs/tasks/056-architecture-note.md` (log), `docs/tasks/056-verify.sh` (new, executable)
`docs/decisions/` and the mission spec are read-only.

## Forbidden here (beyond MANAGER.md §3.7)
- Describing anything as `built` that is not on `main` of its repository at the time of writing; a
  claim about a branch cites `branch:path` (§8b.5).
- Marketing language; "robust", "seamless", "future-proof", "fully decentralised".
- Inventing behaviour of GitHub (Actions, Releases, Pages) — each such statement is verified by a
  command shown in the note's *State* section or tagged `[unverified]` inline (§3.6b).
- Softening or omitting the `source_archive` finding because it is inconvenient.
- Quoting, locating or describing the private key beyond what `key-management.md` already states.
- Running `gh secret` or reading credential files to "confirm" the key's location (CLAUDE.md rule 11).

## Dependencies and sequencing
- **Can start now** for a first version that tags the not-yet-built parts `specified`/`not built`.
- **Final pass after** 058 (the archive URL probe), 008b (pipeline, Releases location, App), 055 (site build and E12), 010 (the
  canary running) — each flips rows from `specified` to `built`, which criterion 3's tags exist to track.
  Criterion 4's "cited files exist" is re-run at the final pass.
- No file overlap with 008a/008b/010/041/055 (it only reads their outputs); 010 and 056 both touch
  `docs/` but different files. The one-line edit to `depgraph.md` must be sequenced against any
  other open edit of that file (none known).
- Graph: documents all nodes and edges; **adds none**. It does not edit `depgraph.json` or the E16 row.

## Verification artefact (MANAGER.md §2c)
Declared: `docs/tasks/056-verify.sh`. Criteria 1-8 and 10 are script-verified; 9 is a human review
and is recorded as one. Prose cannot be proven correct by a script; the script proves the note is
complete, tagged, honest about its states, and resolvable, and says so in its header.

## Deliverables
The note, the link line, the verify script, this file's log section current; a list of every
`[unverified]` item with what would confirm it and who.

## Questions  (agent-maintained; see MANAGER.md 8b)
- ~~Q1 `source_archive` lock-in~~ **decided (Ludwig, 2026-10-14, Q-G): option B** — a project-owned URL
  fronts `source_archive` before the first publish. Options A (accept lock-in) and C (a portable bucket) are not taken.
  Feasibility on GitHub Pages is **unverified**; task 058 is the probe. If it requires Cloudflare rules,
  that changes the "DNS-only, grey cloud" decision recorded in the runbook and returns to Ludwig.
- **Q3 (open; for the manager/Ludwig):** `depgraph.json` (15 edges) has not caught up with `depgraph.md`'s E16 (ownership), added 2026-09-05 by an approved amendment. Is the json to be regenerated? That is a graph update (ADR-0117) and so its own task; this note does not assume it. Whether the ownership carve-out for the pipeline's write-back PR needs an edge of its own (it is a new rule on E16, not a new boundary, in my reading — **unverified judgement**) is likewise a question for that task, not assumed here. | assumed: no new edge.
- **Q2 (open, non-blocking):** Is a "if the project dies" plan (ADR-0006) a separate document, or the *Moving off GitHub*
  section of this note? | options: A★) the section, linked from `README` / B) its own file | assumed: A.

---
# Task 056 log  (append-only, updated continuously by the executing agent)
- 2026-10-14 spec written under task 054; nothing started.
- 2026-10-14 Q-D, Q-E, Q-G folded in from Ludwig's answers; Q1 closed; Q2 remains open.
