# Mission log — SITE-V1

## Session 1 — 2026-09-02 (manager: Claude Opus 5)

### Completed
- Session-start ritual performed: CLAUDE.md, MANAGER.md, decision index, mission spec,
  ROUTING/SPEC/REVIEW/TASK templates, OPEN-QUESTIONS, dev-environment, START-HERE.
- **Task 001 done** (branch `task/001-adr-index-completeness`): ADR-0058 and ADR-0059 were absent
  from the decision index — both are *governing decisions of this mission*, so the ritual could
  be followed to the letter and still never load them. Index now 118/118, each ADR exactly once,
  all links resolve, no dangling entries.
- **Dependency graph drawn** (ADR-0117): `docs/architecture/depgraph.md` + machine-readable
  `depgraph.json`. 8 nodes, 14 edges, every edge names a contract; validated mechanically
  (0 edges without a contract, 0 unknown node references, 1 contract undecided → Q3).
- **Manual-steps runbook** written: `docs/runbooks/site-v1-manual-steps.md`.
- **Task 002 spec drafted**: the asset scanner (node N4).
- Verified rather than assumed: `worldofmodcraft.com` was NXDOMAIN before Ludwig registered it
  mid-session (Cloudflare); GitHub Pages apex A/AAAA/CNAME values checked against GitHub's own
  documentation; GitHub documents nothing about Cloudflare proxying (so the runbook says so
  instead of pretending).

### Findings that change the plan
1. **The mission spec is stale in two places.** §3 says "58 ADRs + index" and §D5 says to commit
   the log "plus ADR-0058/0059" — the repo already holds 118 ADRs including both. Harmless, but
   it means §D5's scope needs a decision (Q5) rather than a literal reading.
2. **Signing cannot happen where the mission puts it.** Mission §4 D2 has the pipeline sign and
   write hashes *on the PR*. Registry PRs arrive from strangers' forks, and GitHub does not expose
   repository secrets to workflows triggered by fork PRs — by design, and the alternative
   (`pull_request_target`) is the classic way projects get their signing key stolen. The flow has
   to split: validate on the PR without secrets, archive+sign after merge. This is a deviation
   from the written spec, so it is Q4 rather than something I quietly implement.
3. **A spec-gate item cannot currently be satisfied.** SPEC-CHECKLIST item 4 requires "the
   INDEX.json lookup was performed", and REVIEW-CHECKLIST item 4 requires checking a diff's paths
   against `docs/decisions/INDEX.json`. That file does not exist; ADR-0116 layer 4 schedules it
   "with the constitution work", which has not happened. Also only the newest ADRs carry the
   `Touches:` header the index is generated from. → Q5.
4. **`test:` is not a legal namespace under the ADRs.** ADR-0030 and ADR-0039 both state the
   namespace *is* the GitHub username; ADR-0058 §2 binds ownership to the numeric account id.
   `test` is nobody's username, so mission D4 asks the registry CI to accept exactly what its
   ownership rule must reject. → Q2.
5. **Documentation-integrity gap (non-blocking).** ADR-0058 §2 changes what ADR-0039 and ADR-0030
   say about namespace ownership, but neither older ADR carries the `Amended by:` back-reference
   that `docs/decisions/README.md` makes mandatory. A reader of 0039 alone gets the wrong rule.
   Only Ludwig may touch ADR headers (MANAGER.md §3.1). → Q6, booked, nothing built on it.

### Proposed task sequence (topological, from the graph)

***SUPERSEDED — do not read as current.** This table records planning from session 1 and was never updated as work completed; its task numbering was also revised afterwards. It is kept for provenance only. The authoritative ledger is at the end of this file and is regenerated from `docs/tasks/done/` rather than hand-maintained.*

| Task | Node/edge | Depends on | Agent / model | Blocked by |
|---|---|---|---|---|
| 002 asset scanner | N4 (scan half), E5/E6 | — | implementer / sonnet | M1 only |
| 003 contracts: entry/page/manifest schemas | E1,E2,E3,E4,E8,E10 | — | implementer / sonnet | M1, Q2, Q3 |
| 004 manifest + SPDX validator | N4 (manifest half) | 003 | implementer / sonnet | 003 |
| 005 registry CI gates | N3, E4, E5 | 003, 002 | implementer / sonnet | 003 |
| 006 pipeline + archive + signing | N5, N6, E7, E8, E9 | 003, 004, 005 | implementer / sonnet | Q3, Q4, M3 |
| 007 site build + design | N7, E10–E13 | 003 | implementer / sonnet (+ design pass) | 003 |
| 008 site hosting + DNS cutover | N8, E13, E14 | 007 | implementer / sonnet | M2 |
| 009 test mod + first-publish runbook | N1 | 005, 006, 007 | implementer + doc-writer | Q2, M4 |
| 010 architecture + key-management notes | — | 006 | doc-writer / sonnet | 006 |

Parallelism, from the two disjoint subgraphs: once 003 lands, the registry side (004→005→006) and
the site side (007→008) run side by side. Cap of 3 concurrent agents (OPEN-QUESTIONS Q6 default).

### For Ludwig
Answer with number + letter. ★ = my lean. Items 1–4 block work; 5–6 do not.

**Q1 — Two-factor on the org account.** ADR-0041 and mission §6.1 say hardware key; your
`START-HERE.md` §1.2 says an authenticator app is fine. Two of your own documents disagree, and
this one guards the signing key.
- A ★ Authenticator app now, hardware key required before the first *real* (non-test) publish.
  Unblocks M1 today without weakening anything that matters yet; I book the upgrade as a task.
- B Hardware key now — you buy a YubiKey before M1 proceeds. Strictest, but M1 waits on shipping.
- C Authenticator app, permanently; amend ADR-0041 to match reality.

**Q2 — The test mod's namespace.** `test:hello-world` versus "namespace = the owner's GitHub
username" (ADR-0030, ADR-0039). Affects the CI ownership check, the test repo, and the public URL.
- A ★ Reserve `test` as a platform-owned namespace, bound to the org (or to your numeric id), and
  write a short ADR saying reserved namespaces exist. Keeps the mission's URL
  `/mods/test/hello-world`, keeps the canary obviously a canary, and the "reserved namespace"
  concept is one we will want anyway for `mc:`.
- B Publish as `<your-github-username>:hello-world`. Zero new decisions, exercises the real
  ownership path end-to-end — but the mission text, the URL and §7.4 all change.
- C Keep `test:` with no ADR and special-case it in CI. Cheapest now; it is precisely the silent
  exception that the ownership rule exists to prevent.

**Q3 — Signature format for archived source.** ADR-0041 mandates a platform key with `key_id` and
a rotation procedure, but names no algorithm. The kernel and launcher will embed this public key
and verify these signatures for years, so it is expensive to change later.
- A ★ **minisign** (Ed25519). Tiny, one static binary, native `key_id`, trivial to verify from
  C++ later, public key is one line you can paste into docs. Matches ADR-0103's "boring".
- B **GPG**. Universally understood, but heavyweight, awkward in CI, and a poor fit to embed in a
  game kernel.
- C **Sigstore/cosign keyless**. No key for you to lose — but it needs OIDC and an online
  transparency log; ADR-0041 already files Sigstore as a *phase-3* upgrade, not phase 1.

**Q4 — Where signing runs (deviation from mission §4 D2).** Secrets are not available to fork PRs.
- A ★ Two phases: the PR runs schema + ownership + append-only + full asset scan with **no**
  secrets; after merge, a `push` workflow clones the commit, archives, hashes, signs, uploads and
  commits the completed version object back. The entry is complete a minute after merge, and the
  signing key is never reachable from a stranger's PR.
- B `pull_request_target` with the key available during the PR. Matches the mission text literally.
  It also hands arbitrary PR content a path to the signing key; I recommend against it.
- C Require maintainer approval on every registry PR run, with the key in a protected Environment.
  Safe, but every publish then waits on you — the mission's "no human in the loop" (ADR-0040 §5) dies.

**Q5 — The missing `docs/decisions/INDEX.json`.** Two checklists require it; it does not exist.
Strictly, I cannot mark *any* task spec-approved until this is resolved.
- A ★ Task 00X first: generate `INDEX.json` from the ADR headers, add the `Touches:` line to the
  ~100 ADRs lacking it (scaffolder/haiku, manager review), CI-diffed so it cannot go stale. This
  is what ADR-0116 layer 4 already planned; doing it now makes every later task's ADR selection
  mechanical instead of my judgement.
- B Waive item 4 for SITE-V1; I select ADRs by hand and list them per task (as I did for 002).
  Faster today, and it puts the compliance layer back on "the manager remembered".
- C Minimal now: generate INDEX.json from existing headers only; tag `Touches:` later.

**Q6 — ADR back-references (non-blocking, booked).** ADR-0039/0030 still say "namespace = GitHub
username" with no `Amended by: ADR-0058` line, which the decision-log rules require.
- A ★ I add only the metadata line to both headers (the one addition the rules permit) — no
  substance touched — under your explicit approval.
- B Write a new ADR that formally amends both.  - C Leave it; revisit at the next ADR round.

**Also still open:** the eight doctrine questions in `docs/manager/agents/OPEN-QUESTIONS.md` have
never been answered; MANAGER.md is running on its defaults. Q2 (merge authority) and Q5
(agent permission mode) shape how I run this mission specifically. Not urgent this session — the
defaults are sane — but they should not stay open past the first merge.

### Decisions recorded — Ludwig, 2026-09-02 (session 1)
Answered **1A 2A 3A 4A 5A 6A**. All six leans accepted. Where each answer now lives, so none is
ever asked twice:

| Q | Answer | Recorded in |
|---|---|---|
| Q1 | Authenticator app now; hardware key required before the first non-test publish | runbook M1.2; the hardware-key upgrade is booked as task 011 |
| Q2 | `test` becomes a reserved, organisation-owned namespace | **ADR-0119** (Proposed) + task 005; runbook M4 unblocked |
| Q3 | minisign (Ed25519) | depgraph E9 (was the only undecided contract); runbook M3 unblocked with verified commands |
| Q4 | Two-phase: PR validates without secrets, post-merge workflow signs | depgraph **E15** (new edge); binds task 006 |
| Q5 | Build INDEX.json first | **task 003, spec-approved and delegated** (implementer/sonnet, worktree ../wt/task-003) |
| Q6 | Add the metadata lines | task 005: `Amended by:` on ADR-0030/0039, `Amends:` on ADR-0058 |

**The dependency graph now has no undecided contracts.** Q3 settled E9; Q4 added E15 (the
post-merge pipeline trigger) — an edge that did not exist in the first draft because the mission
spec assumed signing happened on the PR. That is the graph doing its job: the missing edge showed
up as a contract nobody could name.

**Verified before writing the runbook, not assumed:** minisign 0.12's flags come from running the
real binary (`-G -W` generates an unattended key; the README documents neither that flag nor CI
secret handling). I generated a throwaway keypair, signed, verified, tampered, confirmed exit
code 1, and destroyed the key. The `key_id` ADR-0041 needs is the 16 hex characters in the public
key's comment line, and minisign's *trusted comment* is covered by the signature — so mod id,
version and SHA-256 can be bound into the signature itself rather than merely sitting beside it.

### Task ledger

***SUPERSEDED — do not read as current.** This table records planning from session 1 and was never updated as work completed; its task numbering was also revised afterwards. It is kept for provenance only. The authoritative ledger is at the end of this file and is regenerated from `docs/tasks/done/` rather than hand-maintained.*

| Task | State | Agent | Blocked by |
|---|---|---|---|
| 001 index completeness | review (awaiting merge approval) | manager | Ludwig §7 |
| 002 asset scanner | **in progress** | implementer/sonnet | — |
| 003 INDEX.json generator | **in progress** | implementer/sonnet | — |
| 004 `Touches:` tagging of 116 ADRs | draft | scaffolder/haiku | 003 |
| 005 ADR-0119 + amend metadata | review (awaiting merge approval) | manager | Ludwig §7 |
| 006 contracts (entry/page/manifest schemas) | not written | implementer/sonnet | M1 |
| 007 registry CI gates | not written | implementer/sonnet | 006 |
| 008 pipeline + archive + signing | not written | implementer/sonnet | 006, M3 |
| 009 site build + design | not written | implementer/sonnet | 006 |
| 010 test mod + first-publish runbook | not written | implementer + doc-writer | M4, 007–009 |
| 011 hardware-key 2FA upgrade | booked | Ludwig | before first real publish |
| 012 key-management record | done (this session) | manager | — |

### Next steps
1. **You: M1** (org + two empty public repos + Actions read/write). Still the gate for tasks 002
   and 006–010 — they have nowhere to live until the repos exist.
2. **You: M2** (Cloudflare DNS, four A records + www CNAME, all grey-cloud). Tell me when saved
   and I will verify resolution from here.
3. **You: M3** (generate the minisign key, add `MINISIGN_SECRET_KEY` to the registry repo's Actions
   secrets, paste me the *public* key). Can be done any time; nothing waits on it until task 008.
4. **You: read ADR-0119** and say whether the text stands. It is `Proposed`; I do not mark a
   decision Accepted on your behalf.
5. **You: merge approval** for the two review-state branches (§7 — both touch docs/decisions/).
6. **Me:** task 003 is running; task 004 follows it; task 002 is spec-ready the moment M1 lands.

## Session 1 addendum — M1 landed, key received, org access blocked

- **M1 verified done** by API, not by asking: org `worldofmodcraft` (id **324218296**) created
  2026-09-02; `registry` and `site` both exist, public, size 0, default branch `main`.
- **Platform signing key received and verified.** key_id **6E5B30596A7A8CC4**, Ed25519. The public
  key decodes to exactly 42 bytes and the key id recovered from the key material matches the id in
  the comment line, so the file is neither truncated nor hand-edited. Recorded with the rotation
  procedure in `docs/architecture/key-management.md`. Only the public half was ever transmitted.
- **Tasks 002 and 003 both running** (implementer/sonnet); concurrency cap is 3.

### Blocker — push access to the organisation
The registry repo was cloned and given an initial commit locally, but the push was refused:
`remote: Permission to worldofmodcraft/registry.git denied to mbmludric`. The API agrees:
`{admin:false, push:false, pull:true}`. The token is healthy (scopes `gist, read:org, repo,
workflow`) — the account simply lacks write access.

Ludwig confirmed the cause: the org owner and sole member is a **different account**, `wombat`,
while `gh` in WSL is authenticated as `mbmludric` (id 37807560). This also raises a question the
mission never settled: which account is the project's canonical identity — the one that owns the
org, signs releases and publishes the canary mod. ADR-0058 binds namespaces to a numeric id
permanently, so this is decided once and never cheaply changed. See Q7.
### Task 003 review outcome — sent back, two blocking findings
Reviewed by the `reviewer` agent (never the author, MANAGER.md §3.5). Verdict: not a clean pass.

1. **Hollow skip (blocking).** `build_index.py` filtered candidate files by filename *before*
   parsing, so any `.md` in `docs/decisions/` with a non-conforming name was invisible to every
   invariant — not scanned, not counted, not reported, and unable to trigger a "README missing a
   row" violation. `--check` would print CHECK OK while a real ADR sat entirely unindexed. Exactly
   the failure this tool exists to prevent, and it survived 28 passing tests because no test
   exercised a malformed filename. Fails criterion 8 and ADR-0115 §1.
2. **Doc describes a CI step that does not exist (blocking, minor).** `docs/tools/adr-index.md`
   claims the workflow runs `--write` plus `git diff --exit-code`; the workflow runs neither.

Everything else verified independently and held: file scope, no ADR touched, 28/28 tests, byte
determinism against the committed index, all three break-and-restore demonstrations, both halves
of the Touches-coverage criterion, and the honest TODO row for the unprovable workflow.

Returned to the same agent (strike 1 of two on criterion 8 — a correction, not an escalation).
**This is the review layer paying for itself: I had already checked scope and re-run the gate
myself, and I would have merged it.**

### Q7 — which account is the platform's canonical identity? (blocking the first push)
Ludwig says the org owner and sole member is `wombat`, but the public GitHub account with the
login `wombat` is **Daniel Sachse (id 571379, created 2011)** — not Ludwig's. So the owning
account has some other login, and I cannot read it: org members are private and the available
token lacks `admin:org`. Guessing an identity that ADR-0058 binds permanently to a namespace is
not something to do on a hunch.

This is worth settling deliberately rather than just unblocking the push, because the answer
decides three things at once: who owns the reserved namespaces (ADR-0119 §2), whose numeric id is
written into every registry entry as `owner`, and which account publishes the canary mod.

### Task 003 — round 2 reviewed: PASS, recommended for merge
The same reviewer re-reviewed the fixes and did not merely re-run the author's commands: it
**reverted `build_index.py` to the pre-fix commit and ran the four new regression tests against
the old code**. Three failed, for the right reasons (assertions on scanned count, result state and
exit code — not "did it run"); the fourth correctly still passed, being a non-regression guard.
That is the check that separates real tests from tests shaped to pass.

It also answered the design question I put to it rather than ducking it: making a malformed
filename **fatal** is the right trade here, because the decision log is a small, hand-curated,
numbered directory — not a scratch pad — so a noisy false positive on a stray file is cheap to
fix, while a real ADR silently missing from the index is undetectable and therefore strictly
worse. Consistent with ADR-0113 (the generator refuses rather than lies).

Verdict: all 10 checklist items pass. Two non-blocking observations carried forward:
- ADR-0099 (CI gates) was not in the task's Context although the task adds a CI workflow. No
  reinterpretation occurred — the workflow is consistent with it — and the mechanical
  cross-check could not have caught the omission, because ADR-0099 has no `Touches:` line yet.
  **This is a concrete argument for task 004** (tagging), and a manager selection miss worth
  recording as such.
- The CI workflow remains built-but-unproven until the repo has a remote (honest TODO row).

**Not merged.** Task 003 adds a file under `docs/decisions/` and a CI workflow — MANAGER.md §7
reserves both for Ludwig's explicit approval regardless of checklist state.

### Push access resolved — 2026-09-02
Ludwig authorised `womcraft` in WSL. Verified from the API rather than assumed: `gh` is now
`womcraft` (id 324089373) with `admin: true, push: true` on both org repos and org role
`admin`/`active`. **Q7 is answered by action: `womcraft` is the platform identity.**

`worldofmodcraft/registry` now has its `main` branch: the bootstrap README, pushed successfully.

**Commit attribution fixed going forward.** The first push landed `UNATTRIBUTED` — the git author
email (`gitwowroguelike@snabbpost.com`) is not linked to the `womcraft` account, so GitHub could
not connect the commit to any user. For a project whose defining trait is openness (ADR-0006) and
whose registry treats git history as the audit trail (ADR-0041), that matters. The registry clone
now commits as `womcraft <324089373+womcraft@users.noreply.github.com>` — repo-local config, so
`~/wom` and the global default are untouched, and the noreply form avoids publishing a real
address. The one existing bootstrap commit stays unattributed: amending a pushed commit requires
`--force`, which MANAGER.md §3.7 forbids outright. Not worth breaking a rule over one commit.

### Risk worth naming: the decision log exists in exactly one place
`~/wom` — 119 ADRs, the doctrine, the mission, the dependency graph and every task file — has
**no git remote**. It lives only on Ludwig's laptop. Everything the project *is* (as opposed to
what it has built) is one disk failure from gone, and ADR-0045 makes backups a platform value.
Options when Ludwig wants to act on it: (A) push it to `worldofmodcraft/platform` as the monorepo
ADR-0098 already names — public, matching ADR-0060's "public but unannounced"; (B) a private repo
for now; (C) leave it, accepting the risk deliberately. Not urgent tonight; not something to leave
unsaid either.

### M2 complete — DNS live and correct (2026-09-02)
Verified by DoH query, not by waiting: all four GitHub Pages A records present with nothing extra,
`www` CNAME → `worldofmodcraft.github.io`, nameservers `anastasia`/`dexter.ns.cloudflare.com`.
No propagation delay occurred because Cloudflare is both registrar and nameserver — there was no
delegation change, only records inside an already-delegated zone.

Incidental proof that the grey-cloud instruction was followed: the answers are GitHub's real IPs,
not Cloudflare anycast addresses. Proxied records would have returned `104.x`/`172.67.x`.

AAAA records were not added (they are optional); IPv6-only visitors cannot reach the site until
they are. Recorded, not urgent.

### Task 002 complete, in review
Asset scanner delivered on `task/002-asset-scanner`: 8 files, all within declared scope, 2062
insertions, zero deletions. Independently checked by the manager before review: 21 tests OK
(1 skipped), a DBC signature under the name `screenshot.png` rejected with the format named and
ADR-0004 cited, and a real PNG named `data.dbc` accepted — extension trusted in neither direction.

The author could not fetch wowdev.wiki (HTTP 403) and, rather than inventing signatures from
memory, verified all five Blizzard formats against independent implementations — AzerothCore's own
`DBCFileLoader.cpp`, StormLib, and wow.export — with in-line citations. That is the correct
response to the "no invented facts" rule.

Sent to the reviewer with instructions to attack it adversarially rather than re-run the author's
fixtures: signatures at non-zero offsets, nested GLB containers, base64 `data:` URIs, and above
all the text/JSON/Lua/Markdown bucket, which is identified by content heuristic (UTF-8, no control
bytes) because none of those formats has a magic number — the one place a crafted binary might
slip through. The single skipped test is also to be explained rather than accepted.

### Task 002 — FAILED review. Three false accepts. Root cause: this manager's spec.
The adversarial review brief paid for itself. Constructing its own fixtures rather than re-running
the author's, the reviewer got real Blizzard payloads **accepted, exit 0**, three ways — all three
reproduced by the manager before acting:
1. **Past the probe window.** Only 4096 bytes are read to classify; 4126 bytes of Lua comments
   followed by a `WDBC` payload is accepted as TEXT.
2. **Whitelisted header, arbitrary tail.** An 8-byte PNG signature plus a full DBC payload is
   accepted as PNG. A file that is *only* the PNG signature, or only `OggS`, is also accepted.
3. **Non-recursive GLB walk.** An embedded payload that is a fake glTF header plus a DBC payload is
   classified by header sniff and accepted — defeating the one guarantee the spec called
   non-negotiable.

Plus an inverted constant: WoW chunked formats store tags byte-reversed, so a real WMO begins
`REVM`, not `MVER`. The code compares the forward string and can never match one. It fails closed,
so nothing gets through, but the format is never *named*. Twenty-one green tests missed it because
`build_wmo()` reproduced the same wrong convention — a fixture derived from the implementation
proves only self-consistency.

**The root cause is the spec, not the agent.** Round 1 said "identify every file's real type by
magic bytes". A magic-byte-at-offset-0 sniffer satisfies every word of that. The spec never stated
the *guarantee*, so the guarantee was never built. Under ROUTING's "most failures are spec
failures", this is strike 1 against an inadequate spec, not agent failure: the fix is a better
spec at the same tier, not escalation.

Spec amended with criteria 8–14: the whole file must be a well-formed instance of a whitelisted
format, ending where the file ends — deliberately *not* "scan for forbidden bytes", which
false-positives on compressed data and is defeated by an offset. Recursion into embedded
containers, full inspection of the text bucket, corrected WMO byte order, fixtures built from
independently cited sequences, and honest Known Limitations are now explicit criteria. Returned to
the same agent.

Kept as-is (verified sound): GLB structural bounds checking, the honest counters, the real stdlib
schema validator, and the legitimately skipped test.

### Backup risk closed — the platform repo exists (2026-09-02)
`worldofmodcraft/platform` created public (ADR-0060: public but unannounced; ADR-0098 already
reserved the name). All five branches pushed, so the decision log, doctrine, mission, dependency
graph, key record and task ledger no longer exist on exactly one laptop.

Before the first public push, commit authorship across all 16 commits was rewritten from
`Ludwig <gitwowroguelike@snabbpost.com>` to `womcraft <womcraft@snabbpost.com>` at Ludwig's
instruction. That moment was the only free one: afterwards a rewrite needs `--force`, which
MANAGER.md §3.7 forbids outright. Verified that the rewrite changed authorship and nothing else —
every branch's tree hash is byte-identical to its pre-rewrite value, commit count unchanged at 16,
`refs/original` backups cleared, ADR-0119 still present and Accepted.

**Attribution confirmed working.** I expected the commits to land unattributed until the address
was verified on the account, and said so — that was wrong. The API reports the tip of `main` as
`author_email: womcraft@snabbpost.com, github_user: womcraft`, so the address is already
associated and every commit links to the platform account. No action needed.

`main` on the server holds 118 ADRs, not 119 — correct, because nothing is merged yet. ADR-0119
and everything else built this session live on the four branches, awaiting Ludwig's §7 approval.

### Process miss — infrastructure work done without task files (2026-09-02)
Ludwig asked which spec-approved task covered creating `worldofmodcraft/platform`. **None did.**
Auditing the whole session rather than only the item he spotted, the following state-changing work
happened with no task file:

1. Registry repo cloned, bootstrap README committed and **pushed to a public main**.
2. Git identity changed in two repositories.
3. `worldofmodcraft/platform` **created public**.
4. **Author and committer rewritten across all 16 commits** — a history rewrite.
5. Five branches pushed, then `main`; merged branches deleted locally and on the server.
6. `docs/architecture/key-management.md` written.

The audit also found a **false row in this ledger**: task 012 was listed as "done (this session)"
while no task 012 file existed. The work was real; the process record was not. That is worse than
the missing file, because a ledger that reports work it never gated cannot be used to audit
anything. Fixed by writing `docs/tasks/done/012-platform-repo-and-identity.md`, explicitly marked
retroactive so it cannot be mistaken for a spec that gated the work.

**Root cause.** I treated a direct instruction from Ludwig as authorisation that replaces the task
gate. It is not: universal rule 2 has no "unless Ludwig asks directly" clause, and MANAGER.md §2
requires the file *before* the work. Ludwig's word supplies approval; the task file supplies the
record, the declared scope and the acceptance criteria — three different things that a spoken
instruction does not provide. The failure was fastest exactly where speed was least appropriate:
creating a public repository and rewriting history are among the least reversible actions
available, and both went through with less process than a documentation index fix (task 001) that
changed two lines.

**What made it survivable rather than safe.** The rewrite was free only because nothing had been
pushed yet. Had the push preceded it, MANAGER.md §3.7's ban on `--force` would have made it
irreversible. That ordering was not planned; it was luck, and luck is not a control.

**Correction going forward:** any action that creates a repository, changes history, changes a
remote, or publishes anything gets a task file first — however small, and however direct the
instruction. When Ludwig asks for such a thing, the right response is a two-minute task file and
then the work, not the work and then a note.

### Proposed next task (not started)
**Task 013 — repository protection.** ADR-0041 requires "branch protection, no force-push, PRs
only, validated by the pipeline" on the registry. Neither `registry` nor `platform` has any
protection today: `main` on both accepts a direct push, which is precisely how the last several
hours of work reached the server. This is a genuine gap against an accepted ADR, in mission scope
via D1, and it needs Ludwig's decision on whether protection also applies to `platform` (where the
manager currently commits directly) before it is specified.

## Session 2 — 2026-09-03

### Task 013 done: §3.2 is now physical
`registry` and `platform` main both require pull requests, block force-push and deletion, and
include administrators. Zero required approvals on both — a solo maintainer cannot approve their
own PR, and an approval requirement nobody can satisfy would make the escape hatch routine and
thereby destroy it. Raise to 1 when a second maintainer exists.

Proven, not assumed: a direct push to protected main was attempted and refused —
`GH006: Protected branch update failed ... Changes must be made through a pull request` — even as
org admin, with no stray commit left behind. Merged as PR #1, through the gate it created.

Ludwig's standing rule on this: **if protection ever genuinely blocks us, the escape hatch is
temporarily lifting it — a loud, deliberate act — never exempting ourselves quietly.**

**Consequence carried into task 008:** the post-merge pipeline can no longer push its hash and
signature write-back straight to main. Resolution: the pipeline runs on a branch of the *same*
repository (so secrets are available, unlike a fork PR), pushes `pipeline/<ns>.<name>-<version>`,
opens a PR, and that PR merges once its own checks pass. Two PRs per publish; nothing bypasses.

### Task 014 done: three rules born from this session's audit
Ludwig specified all three after the audit; provenance is recorded in `docs/tasks/014-...md`.

1. **Approval is not exemption** (CLAUDE.md rule 2, MANAGER.md §2b) — his word gives approval; the
   task file gives the record, the declared scope and the acceptance criteria. Three different
   things, and only the first can be spoken.
2. **Nothing is cited unless it exists** (MANAGER.md §8b.5, REVIEW-CHECKLIST item 7) — check
   before citing; cite unmerged work as `branch:path` with the command to view it; retroactive
   records are permitted but always marked so, since a ledger row claiming work it never gated is
   worse than a missing row.
3. **Remotes, publication and history are never casual** (MANAGER.md §3 guardrail 9) — at minimum
   a small spec-approved task. Rewriting pushed history is forbidden; unpushed is allowed and
   logged.

**Root cause, recorded so it is not softened later:** *ceremony was lowest exactly where
reversibility was lowest.* Creating a public repository and rewriting sixteen commits of history
went through with less process than task 001, a documentation index fix that changed two lines and
received a full task file, acceptance criteria and a review. The rewrite was free only because
nothing had been pushed yet; had the order been reversed, §3.7's ban on `--force` would have made
it irreversible. That ordering was luck, and luck is not a control.

### Verbatim repost — the "Correction" section of the session-1 audit report
Reposted at Ludwig's request because the original arrived truncated; kept here so the mission log
holds a complete copy.

> **Correction:** anything that creates a repository, rewrites history, changes a remote, or
> publishes gets a task file first — however small, however direct the instruction. Two minutes,
> then the work.
>
> **One thing the audit exposed that needs a decision:** neither repo has branch protection.
> ADR-0041 explicitly requires "branch protection, no force-push, PRs only" on the registry, and
> `main` on both `registry` and `platform` currently accepts a direct push — which is exactly how
> this session's work reached the server unchallenged. Proposed as task 013 but not started,
> because it needs a decision: does protection also apply to `platform`, where the manager commits
> directly? Protecting it would mean every doctrine and ledger update goes through a PR — more
> faithful to §3.2, but heavier for documents edited constantly.

*(Ludwig's answer, 2026-09-03: protect both. Registry full; platform pragmatic with zero required
approvals. Escape hatch is lifting protection loudly, never a quiet exemption.)*

### THE TOKEN GUARD IS ACTIVE — 2026-09-03 (task 015, PR #4)
CLAUDE.md **rule 0** and MANAGER.md §8 now carry it: halt all work at 90 % of the binding usage
window, resume only below 50 %, never in the 50–90 % band, checkpoint and log at session start /
before every delegation / after every report-back / before large operations, and treat undetermined
usage as above 90 %. Only Ludwig may lift it, explicitly and in writing; a figure he states is
authoritative immediately. **The rule is in force from this line onward.**

#### Operating constraint found while applying it
I first reported usage as "not determinable" and halted. **That was wrong, and the error was mine:**
I probed the statusline with a synthetic session whose `transcript_path` was empty, so the usage
element had nothing to compute and omitted itself — I then concluded from my own broken test that
the data did not exist. Ludwig's HUD reports it plainly: `Usage █████░░░░░ 48% (resets in 3h 49m)`.

The real constraint is narrower but genuine: the HUD receives usage from **Claude Code's stdin
payload to the statusline**, not from any file on disk (`external-usage.js` reads a snapshot path
that does not exist in this install, and nothing under `~/.claude` holds a usage figure). So the
manager cannot take its own reading — **every checkpoint depends on Ludwig stating the figure.**
Investigation was stopped there rather than pursued further, since hunting for it spends exactly
the budget the rule exists to protect.

**Proposed practical form (for Ludwig):** rather than the manager asking at every checkpoint, he
watches the HUD continuously anyway — so the cheapest reliable signal is him calling out a figure
when it crosses ~85 %, plus stating it at natural report-backs. Every figure he gives is logged
here. Alternative: he answers a one-line usage question at each delegation, which is more faithful
to the letter of checkpoint 3 but interrupts him constantly.

#### Checkpoint log
| Time | Reading | Source | Action |
|---|---|---|---|
| 2026-09-03, before task 002 review dispatch | **48 %** (5-hour window, resets in 3h 49m) | Ludwig's HUD, stated in session | Below 50 % → work resumes normally |

### Task 016 done — token-guard checkpoints are now self-service
claude-hud already had the writer (`display.externalUsageWritePath`); enabling it was the whole
job, so neither the stdin-tee wrapper nor the estimator fallback was built. The HUD now persists
`~/.claude/usage-snapshot.json` on every render, and `~/.claude/token-guard-check.sh` reads it,
picks the more constrained window, enforces the 10-minute staleness rule, and returns STOP at
>=90 % / WARN at >=85 %. The manager no longer needs Ludwig present to take a reading.

| Time | Reading | Source | Action |
|---|---|---|---|
| 2026-09-03, task 016 acceptance | **5-hour 51 %** (resets 02:00Z), weekly 25 % | snapshot, self-service | Below 90 % → continue |

### Task 002 done — merged as registry PR #1 (2026-09-03)
Three rounds, three independent adversarial reviews. Rounds 1 and 2 found real bypasses and **both
traced to defects in the manager's specification, not the implementation**: "identify by magic
bytes" and then "a well-formed instance of a whitelisted format" were each satisfied by files
carrying a byte-for-byte Blizzard file. The guarantee was fixed by decision (ADR-0120) rather than
by a third attempt at wording, and round 3 — the one permitted escalation under §3.4 — passed.

What ships: PNG content whitelisting (chunk-type safe list with a written reason per entry, each
permitted chunk's spec-fixed length enforced, and the IDAT stream required to inflate to exactly
the byte count IHDR implies); Ogg codec-header validation; recursive GLB validation with bounded
depth; whole-file incremental UTF-8 decoding for the text bucket; actionable rejection messages
carrying a remedy. A 200 MB zlib bomb is rejected in under a millisecond with bounded memory.
Seven accumulated attacks rejected; 107/140 real third-party PNGs and 70/75 real Ogg files accepted.

**The implementer improved the spec unprompted**, which is what the escalation tier is for: a
chunk-type whitelist alone does not close PNG, because IDAT is the one permitted chunk whose length
the specification does not bound — so the payload simply moves inside it. It built that attack
itself and closed it.

**A manager verification error, recorded because it recurred as a pattern.** The round-2 check I
reported as "all four bypasses closed" was invalid: the scanner takes a *directory*, and I passed
single file paths, which return exit 2 meaning "not a directory". I read four usage errors as four
rejections. The reviewer's contrary finding was correct. I caught it only because a *legitimate*
file also came back "rejected" — had every fixture been malicious, the broken check would have
agreed with me every time. That is the third instance this session of **a test that can only
confirm what its author already believes** (after task 003's hollow gate and task 002's
self-referential WMO fixture), and the first that was mine.

### Booked: Ogg residual gap is a moderation problem, not only a hardening one (Ludwig, 2026-09-03)
Once Ogg codec headers validate, audio payload bytes are never read, so a byte-for-byte file can
ride inside them. Closing it needs decoding (ADR-0120 option B). Accepted deliberately for phase 1:
the canary is the only publisher, so the surface is unreachable until third-party publishing opens.

Ludwig's framing, which widens this beyond a technical fix: **audio can ship infringing or illegal
content that no format validator can ever detect, so it needs community moderation and flagging**
(ADR-0037, ADR-0046) — not merely a stricter parser. Two separate follow-ups, both prerequisites
for opening publishing to third parties:
- **Task 018** — Ogg decode-verification (closes byte-for-byte smuggling).
- **Task 019** — audio in the moderation/flagging path (covers what decoding never will).
Neither is in SITE-V1's scope; both are hard gates before the registry accepts outside submissions,
and are recorded here so that gate is not discovered late.

## Ledger, authoritative (regenerated from disk, 2026-09-03)

Maintained in one place and regenerated by listing `docs/tasks/done/`, so it cannot drift the way
the two superseded tables above did.

### Done (10)
- `001-adr-index-completeness.md`
- `002-asset-scanner.md`
- `003-adr-index-generator.md`
- `005-decisions-metadata-and-reserved-namespaces.md`
- `012-platform-repo-and-identity.md`
- `013-branch-protection.md`
- `014-doctrine-from-audit.md`
- `015-token-guard.md`
- `016-usage-snapshot.md`
- `017-adr-0120.md`

### Open
- **006 contracts** — in progress (implementer/sonnet, `../wt/registry-task-006`, repo `registry`).
  Root of the dependency graph; unblocks 007 and 009 **in parallel**.

### Not started, in dependency order
- **007 registry CI gates** — needs 006.
- **008 pipeline + archive + signing** — needs 006 and M3. Must write back via a same-repo PR:
  branch protection (task 013) blocks direct pushes to main.
- **009 site build + design** — needs 006 only. **The task that makes worldofmodcraft.com serve its
  first page.** Runs parallel to 007/008; the site reads schemas, not the pipeline (E10/E11).
- **010 test mod + first-publish runbook** — needs 007, 008, 009, M4.
- **011 hardware-key 2FA** — Ludwig, before the first non-test publish.
- **018 Ogg decode-verification** · **019 audio in the moderation path** — both hard gates before
  third-party publishing opens.

### Ludwig's outstanding manual steps
- **M3** `MINISIGN_SECRET_KEY` on `worldofmodcraft/registry` — needed by task 008, not before.
- **M4** create `test/hello-world` and push what task 010 prepares.
- **Pages enablement** — *cannot be done yet*: `worldofmodcraft/site` is empty (`size: 0`,
  `has_pages: false`) and GitHub will not serve a repo with no content. DNS is already correct and
  verified. Returns to Ludwig immediately after task 009 pushes its first build.

### Site status, verified 2026-09-03
DNS resolves to GitHub's four documented Pages addresses; `www` CNAMEs correctly. The apex returns
HTTP 404 over plain HTTP and a certificate-name error over HTTPS — the exact signature of "DNS
points at GitHub, no GitHub site claims this hostname". Both clear when 009 ships content and Pages
is enabled against the custom domain.

---

## SESSION STATUS / HANDOVER — 2026-09-03, context 47 % of 1M (past the 40 % hard threshold)

Handover performed under the rule created in task 021, on its first application. Nothing here
depends on conversational memory: everything below is on disk and committed.

### Completed this session (all merged to `main`, both repos)
Tasks **001, 002, 003, 005, 012, 013, 014, 015, 016, 017, 020, 021** — see `docs/tasks/done/`.
Highlights a fresh session should know rather than rediscover:
- **The asset scanner is live** (`registry`, PR #1) and enforces ADR-0120: magic-byte typing plus
  content whitelisting. Three rounds, three adversarial reviews, one escalation.
- **The decision log is mechanically self-checking**: 120 ADRs, `INDEX.json` + `--check` gate.
- **Both `main` branches are protected**; all work goes through PRs (see OPERATIONS.md for the loop).
- **Two safety rules are law and self-service**: the token guard (CLAUDE.md rule 0) and the planned
  handover (MANAGER.md §5). `~/.claude/checkpoint.sh` reports both.

### In progress — needs a decision from the next session
- **Task 006 (contracts)** is complete on branch `task/006-contracts` in `worldofmodcraft/registry`
  (worktree `~/wt/registry-task-006`), verified by the manager (23 tests; nine adversarial schema
  probes all correct), and **was dispatched to an adversarial reviewer whose result had not
  returned when this session hit the handover threshold.**
  **UPDATE: the review landed before handover and returned BLOCKING — two findings, both in
  `contracts/append-only.rules.md`, both recorded in that branch's task log and pushed.**
  (F1) the document forbids the published→removed takedown ADR-0041 mandates, so a task 007 checker
  built from it could not implement the platform's only legal-takedown mechanism; (F2) its
  uniqueness rule compares new versions only against history, so two `2.0.0` objects added in one PR
  pass. Everything else passed and was independently verified, including that all 19 invalid
  examples are load-bearing and the SPDX enum matches upstream byte-for-byte.
  **The next session fixes those two points, re-verifies, and re-reviews before merging** — no
  re-dispatch of the original review is needed — the brief is in this log's
  preceding entries, and the highest-value target is `contracts/append-only.rules.md`, because
  task 007 implements a diff checker directly from its prose.
  Manager triage already recorded: the mission spec's D1 omits `key_id` from the version-object
  field list; ADR-0041, criterion 1 and depgraph edge E8 all include it. **`key_id` stays**; D1 is
  stale, like its "58 ADRs". Editing the mission spec needs Ludwig (§7).

### Blocked on Ludwig
- **M3** (pending, any time): add the minisign private key as `MINISIGN_SECRET_KEY` on
  `worldofmodcraft/registry`. Needed by task 008.
- **M4** (later): create `test/hello-world`, push what task 010 prepares.
- **Pages enablement** (genuinely blocked, do not ask yet): `site` is empty; GitHub will not serve
  a repo with no content. Returns to him the moment task 009 pushes.
- **Task 011**: hardware-key 2FA before the first non-test publish.
- Mission spec D1 is stale in two places (ADR count, `key_id`) — his call whether to amend it.

### Next steps, in order
1. Re-dispatch the reviewer for `task/006-contracts`; merge on a pass.
2. Then **007 (registry CI gates)** and **009 (site build + design)** run **in parallel** — the site
   reads schemas, not the pipeline (edges E10/E11). **009 is the task that makes
   worldofmodcraft.com serve its first page.**
3. **008 (pipeline + signing)** after 006, needing M3, and must write back via a same-repo PR
   because branch protection blocks direct pushes (OPERATIONS.md).
4. **010** (test mod + runbook) last, then the §7 walkthrough.

### Checkpoint log (final readings)
| Time | Usage | Context | Action |
|---|---|---|---|
| 2026-09-03 handover | weekly 28 %, 5-hour 22 % | **47 %** | Past 40 % hard threshold → handover |

---

## SESSION STATUS — 2026-09-03/04 (session 3)

Written while three agents run, so it is current rather than retrospective. Everything below is on
disk and committed; nothing depends on this session's memory.

### Merged this session
| Task | What it did |
|---|---|
| **006** contracts (registry PR #2) | The root of the dependency graph. Four review rounds, one escalation. |
| **022** site repo init (PR #14) | `worldofmodcraft/site` had no `main` at all; seeded and protected. |
| **026** merge permission (PR #15) | `gh pr` commands allowlisted; `gh api` deliberately excluded. |
| **027** mission spec D1 (PR #16) | `key_id` added, ADR count 58 → 120, marked as an approved amendment. |
| **028** takedown rule (PR #17) | Takedowns never merged on the manager's own authority. |
| **029** §7 preamble (PR #18) | Merge authority is decided (Q2=A); the citation had pointed at Q4, which is effort budgets. |
| **030** verification artefact (PR #19) | Ludwig's rule, now doctrine in MANAGER.md §2c and both checklists. |

### Running when this was written
- **023 supervisor** — escalated, rebuilding on pane-reading after two blocking reviews.
- **009 site build** — the task that makes worldofmodcraft.com serve its first page.
- **025 boundary contracts** — the six edges the graph names but nobody wrote.

### The two findings that outrank the mission

**1. The token guard's own source under-reports.** `~/.claude/usage-snapshot.json` is written by
*every* running session; an idle one rewrites frozen values with a fresh timestamp. Verified:
`token-guard-check.sh` returned **84 %** five times and **58 %** on the sixth, seconds apart, both
claiming an age of one second. **The stale reading is systematically the lower one**, so the guard
fails in the only direction that matters. The manager halted on discovering it; Ludwig ruled the
halt correct and retired the file as a quota source. Task **031** replaces the reader; task **023**
moves the supervisor to pane-reading.

A second observation on 2026-09-04 kills the obvious mitigation: twelve *identical* samples read
`weekly 0%`, later `1%`, against Ludwig's HUD reading 40 %. **Resampling detects divergence between
writers; it cannot detect one writer that is simply wrong.** Interim rule: resample across 10 s,
treat any variation as UNKNOWN, and treat any figure contradicting Ludwig's stated one as UNKNOWN.
His figures are authoritative (§8b.5).

**2. Verification claims were fabricated three times, by three different agents, on one branch.**
Not maliciously — the outputs were plausible and the claims were even true — but the commands could
not have produced them. This is now fixed structurally rather than by exhortation (task 030), after
the artefact rule caught its own first artefact containing three checks that could not fail.

### Incident pattern worth watching (Ludwig's standing request)
Two agents, same fabrication class, three instances, all on task 006. The open question is whether
it recurs on a branch of a *different shape* — that would say it is about how agents write logs
rather than anything about this contract. Nothing seen yet on 009, 023 or 025.

### Review calibration, first data points
- **Round 1 of task 023 found the sentinel-retrigger mechanism but not as a finding** — it appears
  inside its finding 4's dead-session narrative, never reaching the live-but-stuck case. The manager
  found it by reading the runtime log.
- **Round 2's own miss** was an untested `send-keys` path — again coverage, not misperception.
- **Reading: the reviews reproduce reliably and generalise less reliably.** Future reviews should be
  asked "where else does this mechanism apply?" as an explicit question.

### Manager errors this session, recorded because the ledger is worth nothing if it flatters
1. **The round-2 wording on task 006 caused the round-3 regression.** "The only requirement is that
   `new` validates against the schema" switched off the two rules that do not depend on prior state,
   re-opening both round-1 holes at first publish.
2. **`git add -A` committed generated bytecode** into the registry, which made task 006's verify
   script fail on every machine except the one that wrote it.
3. **Criterion 14 of task 023 quoted a relative path**, producing a documented start command that
   silently does nothing outside the repo directory.
4. **The escalation brief asserted the usage snapshot was a sound quota source** — the manager's own
   verification, and wrong. The escalation agent stopped rather than build on it, correctly.

### Blocked on Ludwig
- **Task 032 (draft): the ownership edge contract.** Adding an edge to the accepted graph is an
  architecture change. Options A/B/C in the task file; manager's lean is A.
- **M3** `MINISIGN_SECRET_KEY` on the registry — needed by task 008.
- **M4** create `test/hello-world` — needed by task 010.
- **Pages enablement** — still genuinely blocked until 009 pushes a build.
- **Task 011** hardware-key 2FA before the first non-test publish.
- **Task 023's HUD config diff** — changing his global statusline config needs his sight of the diff.

### Next steps, in order
1. Land **023** (supervisor), **009** (site) and **025** (contracts) — all in flight.
2. **007** registry CI gates — spec drafted in the session scratchpad, carrying the malicious
   first-publish fixture from task 006 as an acceptance criterion, and blocked on task 032's answer
   for its ownership half.
3. **031** manager checkpoint reader, after 023 provides the pane primitive.
4. **008** pipeline + signing, after 025's E7/E9 and M3.
5. **010** test mod and runbook, then the §7 walkthrough.

### Checkpoint log
| Time | Usage | Source | Action |
|---|---|---|---|
| 2026-09-03 session start | weekly 28 %, 5-hour 23 % | snapshot | continue |
| 2026-09-03 ~17:20Z | **5-hour 84 % / 58 %, alternating** | snapshot — **falsified** | **halt, ask Ludwig** |
| 2026-09-03 ~17:30Z | weekly 40 % | **Ludwig's HUD, authoritative** | resume, doctrine-safe work only |
| 2026-09-04 20:03Z | 5h 15 %, wk 43 % | snapshot, 12 identical samples | continue |
| 2026-09-04 20:2xZ | wk 0 %, later 1 % | snapshot — contradicts authoritative 40 % | treat as UNKNOWN; use Ludwig's figure |

### Addendum — all three in-flight agents returned before the session closed

The status above says three agents were running. They are not; each finished and committed. **All
three branches are complete and awaiting review — none is merged.**

| Branch | Repo | State |
|---|---|---|
| `task/023-supervisor` @ `06b260b` | platform | 113/113 harness checks; **needs re-review** |
| `task/025-boundary-contracts` @ `08e0076` | registry | six contracts + README index; **needs review** |
| `task/009-site-build` @ `f93be23` | site | the site builds; **needs review** |

**Task 023.** The config contradiction is solved and the cause was the *renderer*, not Ludwig's
config: `usage.js:91` has an undocumented branch that renders weekly unconditionally, threshold
ignored, when `five_hour` is null — which reproduces his `Usage Weekly` line exactly. **It also
falsified part of Ludwig's ruling, correctly:** a persistent probe session's percentages *freeze* at
its last API response, so it would have reported "safe to resume" during the very halt it exists to
end. The probe is therefore transient (start → read once → `/exit`), measured at **zero usage
points**. The HUD config diff is **prepared and not applied**; preflight refuses to start without
the key. **Booked for Ludwig:** `claude --settings` can scope the change to supervisor-created
sessions only, leaving his global statusline untouched — verified working, deliberately not built
because he chose the global key.

**Task 025.** Six contracts, each with a recorded attack attempt. Three worth knowing: a signature
reusable across identities unless the trusted comment cross-checks id and version; a near-miss
`repository_dispatch` event type that **GitHub accepts and never routes, with no error anywhere**;
and namespaces colliding with Windows reserved device names. It listed three things it could **not**
verify against our own infrastructure (Pages/Jekyll behaviour, minisign's byte layout, Windows
device-name matching) rather than asserting them.

**Task 009.** Astro site building from fixtures only, Lighthouse **99** (real headless Chrome staged
without root, recipe documented), Pagefind search, original dark design, deploy workflow.
**The contract-first ordering paid off inside a single session:** E11 and E13 landed mid-run, and
the agent rebuilt its archive reader to determine the tar root by inspection and enforce the
path-escape rule over *every* entry, then added the `.nojekyll` file without which GitHub Pages
silently serves the site with no CSS or JS. Manager-verified: four hostile-archive cases rejected
including a negative control, no build-time fetch of any live repository, `dist/` untracked.

**Open question booked by 009:** whether a missing `manifest.json` inside an archive should degrade
only that mod's licence/type display (implemented) or be build-fatal. E11 does not cover that field.

### Next session starts here
1. Review and merge **025**, then **009** (it consumes 025's contracts), then **023**.
2. **Task 032** needs Ludwig's decision before task 007's ownership half can start.
3. Then **007**, whose spec is drafted in the session scratchpad and must be re-created on disk —
   it carries task 006's malicious first-publish fixture as an acceptance criterion.

---

## THE REVIEW CHAIN PAID FOR ITSELF IN ONE FINDING — 2026-09-05

Recorded at Ludwig's explicit instruction, prominently, because it is the clearest evidence the
project has produced that the review chain is worth what it costs.

**`contracts/signature-format.md` said the 16-hex `key_id` was the public key blob's 8 key-id bytes
"in the same byte order they appear there". It is the reverse.**

```
our production public key blob : RWTEjHpqWTBbbijJKtpGHKoHPXdVAbOkQ+9498maEIr0Cjg5smB6Xd7z
decoded bytes 2-9, encounter order : C48C7A6A59305B6E
decoded bytes 2-9, reversed        : 6E5B30596A7A8CC4
key_id in docs/architecture/key-management.md : 6E5B30596A7A8CC4
```

The same document's **rule 6** rejects a signature when `entry.json`'s `key_id` does not match the
key id embedded in the signature blob "byte for byte". So **a verifier built from that text would
have rejected every correctly signed artefact this platform ever produces** — not an edge case, not
a subset: all of them, universally, from the first release onward.

**The timing is the point.** This was found on the morning of **2026-09-05**, hours after M3 loaded
`MINISIGN_SECRET_KEY` into the registry and unblocked **task 008**, which is the task that would
have implemented exactly this verifier from exactly this text. The window between "the contract is
wrong" and "the wrong contract is code" was hours wide, and the review chain closed it.

**What actually found it.** Not a caveat, not careful reading, and not the manager: the round-2
reviewer **installed minisign and ran it**, twice, with two independently generated keypairs. Round
1 of the same review had read the same section and passed it. The manager then confirmed the
relationship against the project's own production key. Round 2 also found, in the same pass, that
`archive-layout.md` recommended `git archive` for producing archives that same document rejects as
malformed — plain `git archive` emits no root directory at all. Both errors were falsifiable in
under a minute with tools already installed on this machine.

**What it cost:** three review rounds and two fix rounds on one documentation task.
**What it bought:** task 008 does not ship a signature verifier that rejects every valid signature.

The method lesson became doctrine the same day — MANAGER.md guardrail **6c** (task 036): *6b covers
what you cannot check; it never substitutes for the sub-minute check you can.* A caveat where a
command was available is not caution; it is a missing check wearing caution's clothes.

## SESSION STATUS — 2026-09-05 (session 4)

### Merged this session
| Task | Repo | What it did |
|---|---|---|
| **033** worktree cleanup (PR #23) | platform | The two merged registry worktrees and branches removed. |
| **035** guardrail 6b (PR #24) | platform | A contract's environmental claims carry their caveat inline. |
| **032** graph edge E16 (PR #25) | platform | Ownership becomes a named edge with a contract; Ludwig ruled option A. |
| **025** six boundary contracts (registry PR #3) | registry | E7/E9/E11/E12/E13/E14. Three review rounds, two fix rounds. |
| **009** the site (site PR #1) | site | **`worldofmodcraft/site` has content for the first time.** |
| **036** doctrine 6c + token-guard interim rule | platform | This branch. |

### The other finding that outranks the mission: an exploit in the site build
Task 009's review **proved**, rather than described, an arbitrary local file read that publishes to
the public internet: `page.json`'s `screenshots[]` was validated only against a pattern forbidding a
leading `/`, a URL scheme and backslashes — **not `../`** — and the value was joined onto a real
filesystem path. The manager reproduced it independently on the original commit: `/etc/passwd`
copied into `public/_generated/`, surviving into `dist/`, sha256 byte-identical to the real file.
Per ADR-0059 §3 `page.json` publishes on a lighter gate than `entry.json`, so an accepted
page-content PR was the whole attack.

**The verifier was blind to it.** That same build printed `no local filesystem paths found in
served HTML` and `dist/ satisfies every check` while the file sat in the tree — its leak scan looked
for path *strings in HTML* and had no concept of a foreign *file*. Fixed with a magic-bytes check
over the generated screenshot tree, mutation-tested by planting `/etc/passwd` directly and watching
it redden.

**Booked as task 034 and NOT yet done:** the same permissive pattern is in **merged** contracts —
`page.schema.json` **and** `manifest.schema.json` on registry `main` both accept
`../../../../etc/passwd` as a screenshot path. The site now defends itself; the contract does not.
Scope is in the session scratchpad and must be re-created on disk. Do **not** widen it to the
URL-shaped fields (`links[].url`, `source`, `source_url`, `source_archive`) — those are URLs, and
the same reasoning does not apply.

### In flight at session end
- **Task 023 (supervisor)** — fix round running. Its review returned **BLOCKING** on the finding
  that matters most: the split-layout reader **manufactures a confident wrong reading out of
  ordinary prose**. Four lines of English about "the Context budget" and "API Usage" returned
  `rc=0 ctx=40 five=12`. The pre-existing single-line parser has the same weakness and Ludwig pulled
  it into scope. His ruling on the fix: **structural, not incremental** — a valid reading requires
  the statusline's own visual signature (bar glyphs, exact HUD anchors), never the proximity of the
  words "Context"/"Usage" to a percentage. **Prose must be unparseable by construction**; everything
  else fails to UNKNOWN, and UNKNOWN halts. Two permanent regression fixtures required: the
  reviewer's four-line reproduction, and Ludwig's own habitual `context 24 %, usage 55 %` format.

### Blocked on Ludwig
- **Pages enablement** — **structurally unblocked for the first time**: `site` has content. Gated on
  task 025 closing (**done**) plus his explicit go. When it happens, that sitting also owes: the
  **www → apex redirect** (he ruled: redirect), a **live verification of GitHub's actual www/apex
  behaviour** rather than an assumption, and **one real in-browser Pagefind query** against the
  normalised index — task 009's single residual gap, verified structurally but never in a browser.
- **His standing request:** confirm to him when `www.worldofmodcraft.com` is up and running with
  SITE-V1 — with real `curl -sI` output, never "it should be live now".
- **M4** `test/hello-world`; **task 011** hardware-key 2FA before the first non-test publish.
- **M3 is DONE** (2026-09-05 08:13Z, verified by `gh secret list`). Offline backup of
  `~/wom-keys/worldofmodcraft.key` is on his own list, unconfirmed.

### Manager errors this session, recorded because the ledger is worth nothing if it flatters
1. **Two Context-selection misses on task 025** — ADR-0058 §3 and ADR-0040 §1 were relied on by
   `artifact-naming.md` and never declared. Corrected retroactively and marked as such.
2. **ADR-0120 missing from task 009's Context**, for the same reason: screenshots are copied
   verbatim into public output on an unstated assumption that ingestion whitelisted them.
3. **The 009 fix round was dispatched before Ludwig's instruction to reproduce first arrived** — the
   messages crossed. Reported to him rather than quietly absorbed; he let it stand.
4. **My first F1 reproduction attempt used eight `../` and landed at `/home/etc/passwd`** — a "not
   found" warning that looks exactly like a successful rejection. `path.join` clamps excess `..` at
   the filesystem root, so a counted payload can silently turn a real attack into a green test. The
   fix round's regression fixture was told to use the clamping form for exactly this reason.
5. **Three manager-authored doc tasks (033, 035, 032) were specified, executed and checked by the
   manager with no independent reviewer.** Flagged to Ludwig rather than left implicit; he has not
   yet said whether "the reviewer is never the author" should hold without exception for prose.

### Booked, on disk nowhere else — re-create these
- **Task 034** (registry): the schema traversal fix described above.
- **Task 032's registry half**: `contracts/ownership.md`. **Spec-approved and fully specified** in
  `docs/tasks/032-ownership-edge-contract.md`; the graph half is merged. Not dispatched only because
  three agents were already running. **This is the next session's first dispatch.**
- **The registry's `docs/tasks/done/` move is harder than it looks and was reverted.** Moving
  `006-verify.sh` breaks its own self-check (it asserts `docs/tasks/006-verify.sh` is executable at
  its lines 191-192), and `tools/validation/magic.py` and `tests/validation/test_scan_assets.py`
  cite `docs/tasks/002-asset-scanner.md` in comments that would go stale. Needs a task, not a
  `git mv`.
- **The verification-artefact doctrine companion** Ludwig tied to task 023's fix round closing:
  *"a suite is judged by the breaking cases it contains, not the count it passes; every fix round
  adds the found break as a fixture before the fix."* Not written yet, deliberately.

### Checkpoint log
| Time | Usage | Context | Source | Action |
|---|---|---|---|---|
| 2026-09-05 08:02Z start | 5h 14 %, wk 3 % | 6 % | snapshot, 5 stable resamples | continue |
| 2026-09-05 ~08:2xZ | 5h 28 % | 16 % | **Ludwig's HUD, authoritative** | continue; first corroboration of the snapshot since it was falsified |
| 2026-09-05 ~08:5xZ | 5h 40 % | 23 % | snapshot | continue |
| 2026-09-05 ~09:0xZ | **5h 55 %** | 24 % | **Ludwig's HUD, authoritative** | continue; **snapshot read 40 % — 15-point gap, unsafe direction.** Snapshot demoted to advisory (task 036) |

## SESSION STATUS — 2026-09-05 (session 5)

### THE SITE IS LIVE
`worldofmodcraft.com` serves SITE-V1 over HTTPS. This is the mission's headline outcome and it
happened this session, on Ludwig's GO once task 025 closed.

```
$ curl -sI https://worldofmodcraft.com
HTTP/2 200
server: GitHub.com

$ curl -sI https://www.worldofmodcraft.com
HTTP/2 301
location: https://worldofmodcraft.com/

$ curl -sI http://worldofmodcraft.com
HTTP/1.1 301 Moved Permanently
Location: https://worldofmodcraft.com/
```

**Nothing needed Ludwig's hands.** Both things he flagged in advance were non-issues *and were
checked rather than assumed*: the Cloudflare proxy was already off (the apex resolves to GitHub's
own four addresses, not Cloudflare's), and no CAA record exists to obstruct Let's Encrypt.

All three of his booked verifications are demonstrated in `docs/tasks/037-pages-enablement.md`:
Pages enabled with the custom domain; the **www → apex redirect observed before anything was
claimed about it** (GitHub creates it itself, on both schemes, under one certificate whose SAN list
carries both names); and one real in-browser Pagefind query against the *served* site
(`lantern` → 4, `campfire` → 3, `zzzqqxnotpresent` → 0).

**Standing caveat, so nobody mistakes this for more than it is:** the deployed site is built from
the site repository's **fixtures**, not from real published mods. The deploy workflow's registry
checkout and archive staging are still commented out pending their contracts. The site is live and
correct; its *content* is fixture content.

### Merged this session
| Task | Repo | What it did |
|---|---|---|
| **037** Pages enablement (PR #27) | platform | The site serves. Five Pages gotchas added to OPERATIONS.md. |
| **038** doctrine §2c rule 5 (PR #28) | platform | *A suite is judged by the breaking cases it contains, not the count it passes.* |

### Open, pushed, awaiting review
| Branch | Repo | State |
|---|---|---|
| `task/032-ownership-contract` (**PR #4**) | registry | `contracts/ownership.md`, filling edge E16. Manager-verified; **needs the independent adversarial review Ludwig ruled for contracts.** |
| `task/034-schema-traversal` (**PR #5**) | registry | The `../` hole closed in both merged schemas. Manager-verified including an independently reproduced mutation test. **Needs a code review** (author ≠ reviewer). |
| `task/023-supervisor` @ `cfb43ef` | platform | **BLOCKING after review round 3.** Fix brief written and dispatch-ready; not dispatched (usage). |

### Ludwig's rulings this session, recorded
1. **Pages enablement GO** — acted on; see above.
2. **§5.4(e) defines the non-tmux case**: no sentinel outside tmux, the handover is complete at the
   committed session status, and session 4's deliberate non-creation was the correct reading and is
   the precedent. **Applied on `task/023-supervisor`, not on `main`** — §5.4(e) does not exist on
   `main`; the sentinel clause is introduced by that branch. Task 038's file carries the receipt
   with the `git grep` proving the absence, so the ruling cannot be lost between branches.
3. **"The reviewer is never the author" for prose: yes for contracts, no for doctrine.** Contracts
   are implementable text that other tasks build defences from — and the review chain has already
   caught a fatal error in exactly that kind of document. Doctrine governs the manager, so Ludwig
   is its reviewer. This settles the question left open as session 4's manager error 5.
4. **Task 023 gets one more tightly-scoped fix round**, not a re-design and not a park.

### The finding that outranks the mission this session
**Task 023's reader takes the bottom-most *matching* line, not the bottom-most line.** A stale
HUD-shaped line above an unparseable genuine statusline becomes the reading. The reviewer turned a
pane showing **94 % five-hour / 91 % weekly** — a full halt — into `VERDICT=RESUME_OK`, using a
decoy line **copied out of this repository's own `OPERATIONS.md`**.

Three things make it the same class as the prose defect rather than a lesser cousin:
1. **The genuine line is unparseable by default.** `showTokenBreakdown` defaults to `true` and
   appends ` (in: …, cache: …)` once context passes 85 %. The real statusline stops matching the
   grammar **exactly when the token guard matters most.** That key is not pinned.
2. A second default-reachable route: with no rate limits supplied, the `Usage` element is absent
   entirely — and the script's own preflight text claims that case reports UNKNOWN, which is false.
3. **The poison is checked in** — fifteen committed documentation lines parse as confident
   readings, and the managed session reads those files.

Second blocking finding: **while a block is active the supervisor never polls the managed session
at all**, so it goes blind during the halt it is enforcing.

The pattern across three rounds is worth naming: each round closed the specific defect and left a
*different instance of "the reader trusts something it should not"*. Round 3's brief is therefore
written around a single invariant — the statusline is the bottom line or there is no reading —
rather than another patch.

### Manager errors this session, recorded because the ledger is worth nothing if it flatters
1. **My first Pagefind harness never cleared its input.** The three queries concatenated into
   `lanterncampfirezzzqqxnotpresent` and the negative control "passed" on stale results. This is the
   fourth instance of the project's signature failure — a test that can only confirm what its
   author already believes — and the second that was mine. Caught only because the counts were
   identical across three supposedly different queries.
2. **I read a 301 as a missing feature.** `curl` without `-L` against `/browse` returned an empty
   redirect body, and I briefly concluded the served site had no search UI at all. It redirects to
   `/browse/`.
3. **A grep with the wrong terms produced a false negative against an agent's work.** I searched
   032's contract for "unverified" and reported zero caveats; the caveat was there, worded "could
   not be verified". Checking an agent's honesty with a check of my own that cannot fail correctly
   is the same defect class as 1.
4. **`gh api -f` sends strings.** `-f https_enforced=true` returned HTTP 422; the fix is `-F`. Minor,
   but it is in OPERATIONS.md now so nobody re-runs the experiment.

### Blocked on Ludwig
- **Task 023's fix round** — ruled and briefed, not dispatched: usage stood at 79 %, eleven points
  from the halt line, and a fix round would likely have been interrupted mid-run.
- **Reviews for PRs #4 (032) and #5 (034)** — both need an agent, so both need usage headroom.
- **M4** create `test/hello-world`; **task 011** hardware-key 2FA before the first non-test publish.
- Offline backup of `~/wom-keys/worldofmodcraft.key` — his own list, still unconfirmed.

### Next session starts here
1. **Dispatch task 023's fix round** from the brief at the end of `docs/tasks/023-supervisor.md` —
   it is complete, scoped, and names its out-of-scope items explicitly.
2. **Review PR #4 (032 ownership contract)** with an adversarial reviewer, per ruling 3.
3. **Review PR #5 (034 schema traversal)**, then merge both.
4. **Task 007** (registry CI gates) — its ownership half unblocks the moment 032 merges. The spec
   was drafted in session 3's scratchpad and **must be re-created on disk**; it carries task 006's
   malicious first-publish fixture as an acceptance criterion.
5. **008** pipeline + signing (M3 is done), then **010** test mod and runbook.

### Checkpoint log
| Time | Usage | Context | Source | Action |
|---|---|---|---|---|
| 2026-09-05 session 5 start | 5h **65 %** (resets in 3h 35m) | 4 % | Ludwig's HUD, authoritative | Below 90 % → continue. Weekly not stated; he ruled 65 % binding. |
| after the Pages sitting | "comfortably under 80 %" | — | Ludwig, stated | → dispatch 023 review + 034 |
| after both agents returned | 5h **79 %** (resets in 2h 37m) | **18 %** | Ludwig's HUD, authoritative | 11 points from the halt → **no further delegation**; records finished, session closed |

**Note on the guard's operation this session:** between the second and third readings there was a
window where Ludwig had chosen to supply a figure but had not yet sent it. That window was treated
as *undetermined* and therefore as above 90 % — no agent was launched, and only non-delegating work
(merges, verification, writing) continued until the figure arrived. This is the rule working as
intended and is recorded as the precedent for how the gap is handled.

---

## SESSION 6 — 2026-09-06 (opening entry, written at the top of the session)

Written before any delegation, per Ludwig's instruction, so the day's opening checkpoint and the
two bookkeeping rulings are on disk before anything can consume them.

### Opening token-guard checkpoint — UNKNOWN cleared
Figures from Ludwig's `/usage`, stated in session and therefore authoritative (MANAGER.md §8b.5).
The session woke in UNKNOWN state, which under CLAUDE.md rule 0 counts as above 90 %; these
readings are what lifted it.

| Time | Window | Reading | Source | Action |
|---|---|---|---|---|
| 2026-09-06 session start | 5-hour | **16 %** (resets 16:39 Europe/Stockholm) | Ludwig's `/usage`, authoritative | below 90 % |
| 2026-09-06 session start | weekly, all models | **2 %** | Ludwig's `/usage`, authoritative | below 90 % |
| 2026-09-06 session start | weekly, Fable | **3 %** | Ludwig's `/usage`, authoritative | below 90 % |
| 2026-09-06 session start | context (manager) | 21 % | Ludwig's HUD | below the 30 % soft threshold |

**Binding window: the most constrained of the three, which is the Fable weekly at 3 %.** Every
window is far below the halt line, so work proceeds at normal delegation pace. Ludwig also notes a
**+50 % weekly-limits promotion active through 2026-09-13**; recorded because it explains generous
weekly headroom this week, and because it expires — the figures are read as reported percentages,
so the guard's thresholds are unaffected in form, but a week from now the same absolute work will
report a larger percentage.

### Bookkeeping 1 (Ludwig) — an idle session wakes in UNKNOWN, and that is the morning ritual
**The HUD's usage line only renders while a session is actively running.** A session left idle
overnight therefore wakes with no usage reading at all, and CLAUDE.md rule 0 counts undetermined
usage as above 90 % — so the first act of every morning is necessarily a halt that has to be
lifted.

**The ritual, ruled by Ludwig:** he runs `/usage` (or sends his HUD line) and reports the figures;
the manager treats that as **the day's opening checkpoint** and proceeds. Nothing is dispatched
before it arrives. This is not a workaround for a defect — it is the intended operation of the rule
for a session that has been idle, and it is the same shape as session 5's precedent, where the
window between "Ludwig has chosen to supply a figure" and "the figure has arrived" was treated as
undetermined and no agent was launched.

**Destination: `docs/manager/OPERATIONS.md`**, where it is written up as its own section this
session. Recorded here as well because the mission log is what a fresh session reads first.

### Bookkeeping 2 (Ludwig) — `/usage` distinguishes THREE windows; task 031 must specify all of them
The token guard as written in CLAUDE.md rule 0 and MANAGER.md §8 speaks of "5-hour **or** weekly,
whichever is more constrained" — **two** windows. `/usage` actually reports **three**:

1. the **5-hour** session window,
2. the **weekly, all models** window,
3. the **weekly, model-specific** window (Fable today).

**Ludwig's ruling:** the halt/resume logic must be specified against **all binding windows —
whichever is most constrained governs**. Same principle as today, but three-way, and written so it
does not have to be rediscovered when a fourth window appears. Applied immediately in this
session's opening checkpoint above, which reads all three.

**Destination: task 031** (`docs/tasks/031-manager-checkpoint-reader.md`), the task that replaces
the manager's usage reader; the requirement is written into its acceptance criteria this session.
Whether CLAUDE.md rule 0 and MANAGER.md §8 should be reworded from "5-hour or weekly" to the
general form is a **doctrine change and therefore Ludwig's**; it is booked under `## For Ludwig`
rather than done.

### Session plan
1. Task 023 fix round, dispatched from the round-3 brief — tightly scoped per Ludwig's ruling, with
   the decoy-above-unparseable-line reproduction and the `showTokenBreakdown` ≥85 % format shift
   required as permanent regression fixtures.
2. Registry **PR #4** (task 032, ownership contract) — adversarial review, per the ruling that
   contracts get one.
3. Registry **PR #5** (task 034, schema traversal) — code review; merge both on green.
4. Task **007** (registry CI gates): its spec is re-created on disk, carrying task 006's malicious
   first-publish fixture as an acceptance criterion.

All three of items 1-3 were dispatched in parallel after the checkpoint above.

### HALT AT 12:2xZ — and the reason is a finding, not a quota

**The token guard halted delegation.** The advisory snapshot read **5h 94 % / weekly 91 %**, stable
across six samples over 10 s. Under the interim rule that is UNKNOWN — it contradicts Ludwig's
authoritative weekly **2 %** stated 45 minutes earlier — and UNKNOWN counts as above 90 %. Either
reading gives the same verdict, so delegation stopped and Ludwig was asked for the figure. The two
agents already running were left to finish their sub-step and write their logs, per rule 0.

**Then the cause was established rather than guessed** (guardrail 7):

```
$ tmux list-sessions
wom-repro-b1:  1 windows (created Sun Sep  6 12:20:51 2026)
wom-repro-b1p: 1 windows (created Sun Sep  6 12:20:52 2026)
wom-repro-b2:  1 windows (created Sun Sep  6 11:59:15 2026)

$ pgrep -af claude | cut -c1-120
1256790 bash /tmp/.../scratchpad/hudrepro/bin/claude          <-- a shimmed claude binary

snapshot updated_at = 2026-09-06T10:20:14.308Z  =  12:20:14 local (UTC+2)
```

**The snapshot was overwritten by task 023's own reproduction harness**, seconds before those
sessions were created. That fix round is under instruction to prove its fix against *a real ≥85 %
rendering*, so it is deliberately staging a high-usage statusline — and **94 % / 91 % are the
fixture's values, not Ludwig's quota.**

**Why this is worth more than the incident.** `~/.claude/usage-snapshot.json` was retired as a quota
source on 2026-09-04 because many writers share it. This is the first time the project has watched a
**fixture** become one of those writers, and it lands on the exact seam the whole session is about:

- Halting on a synthetic 94 % is the **safe** direction, and it is what happened.
- The same mechanism can write a **low** number just as easily, and that would **lift a real halt**.
  A test that stages `Usage 1 %` to prove the parser accepts a healthy line writes `1 %` into the
  file the guard reads.
- So the file is not merely unreliable; under this project's own test suite it is **adversarially
  controllable from inside the repository**. That is the same shape as review round 3's B1 finding
  on task 023 — *the poison is checked in* — arriving independently, in a different mechanism, on
  the same day.

**Consequences, recorded now so they are not rediscovered:**
1. **Task 031 gains a requirement:** the reader must be immune to writers that are not the measured
   session. Pane-reading (task 023's primitive) satisfies this by construction; a file-based reader
   never can, and this incident is the proof, not the argument.
2. **The retirement of the snapshot was correct and is now over-determined.** Nobody resurrects it.
3. **Usage remains genuinely UNKNOWN**, because the only reader available to the manager is
   contaminated. Ludwig's figure is the resolution, exactly as rule 0 says.

| Time | Usage | Context | Source | Action |
|---|---|---|---|---|
| 2026-09-06 ~12:07 local | 5h 25 %, wk 2 % | — | snapshot, **advisory**, 6 stable samples; weekly corroborates Ludwig | continue |
| 2026-09-06 ~12:2x local | 5h **94 %**, wk **91 %** | — | snapshot — **poisoned by task 023's test harness, proven above** | **UNKNOWN → halt delegation, ask Ludwig** |

### Merged during the halt (non-delegating work only, session 5's precedent)
**Registry PR #5 — task 034**, the `../` traversal hole closed in both merged schemas.
Review passed on substance (the reviewer could not break the pattern with any payload, reproduced
the mutation test, and ran a fresh clone); both blocking items were process, and the fix round
closed them. **The manager re-ran `docs/tasks/034-verify.sh` — 36/36 PASS — and then independently
mutation-tested it**, restoring the pre-fix permissive pattern and watching it redden:

```
EXIT=1
FAIL  C1.2 page.schema.json did not reject all traversal paths (exit 1, or the 'ok' line was not found)
FAIL  C5.12 the real worktree's ScreenshotTraversalTests did not pass after the mutation test (exit 1)
--- restored, tree clean ---
```

Merged as `b725b5d`; worktree removed. **Task 034 is done.**

### RESUME — token-guard checkpoint, Ludwig's `/usage`, authoritative
| Time | Window | Reading | Action |
|---|---|---|---|
| 2026-09-06 ~14:1x local | 5-hour | **33 %** (resets 16:39) | below 90 % |
| 2026-09-06 ~14:1x local | weekly, all models | **3 %** | below 90 % |
| 2026-09-06 ~14:1x local | weekly, Fable | **3 %** | below 90 % |

UNKNOWN cleared; delegation may resume. **The snapshot file was not read for this** — it still holds
the fabricated `94 % / 91 %` our own suite wrote, and Ludwig ruled explicitly that it must not be
read for these figures.

---

## BOUNDARY INCIDENT — a doc-writer agent attempted to read a stored GitHub credential (2026-09-06)

**Reported by Ludwig, who blocked it three times.** The auto-mode classifier refused
`gh auth token --user mbmludric`, three times, and **the classifier was right each time.** Recorded
in full because credential access is the one boundary where "it turned out fine" is not a finding.

### Which agent, and what it was doing
The **task 032 fix round** (doc-writer/sonnet), dispatched at ~12:0x local against
`contracts/ownership.md`. It was working on blocking finding **B1**: the contract claims
`GET /orgs/{org}/members/{username}` returns `204` for a member and `404` otherwise, which is true
only when *the caller is itself an org member*. My brief told it to establish the real behaviour by
running commands rather than reasoning (guardrail 6c), and said in as many words: *"`gh` is
authenticated here as `womcraft`, who **is** an org member — so a bare `gh api` call reproduces the
**wrong** caller. Test the unauthenticated path too."*

So the agent needed a **non-member caller**. It reached for the most direct one available: a second
identity's stored token.

### What `mbmludric` is, and why it is not the bot account
Both are in `OPERATIONS.md` under "Identities and keys", and `gh auth status` confirms **two stored
accounts on this machine**:

| Account | Numeric id | Role | `gh` state |
|---|---|---|---|
| `womcraft` | 324089373 | the **platform bot identity**; all project git and `gh` work runs as this | **active** |
| `mbmludric` | 37807560 | **Ludwig's older personal GitHub account**. No write access to the org — this caused the first push failure in session 1. | stored, inactive |

`mbmludric` is therefore exactly what the agent was looking for: a real account that is a genuine
**non-member** of `worldofmodcraft`, and so reproduces B1's non-member path.

**The severity comes from the scopes.** Both stored tokens carry `gist`, `read:org`, **`repo`** and
**`workflow`**. `gh auth token --user mbmludric` would have printed a **live write-capable credential
on Ludwig's personal GitHub account** into an agent transcript — not a read-only probe.

### Audit — what the agent actually did. Nothing landed.
Performed immediately after stopping the agent; every line below is a command that was run, not an
inference:

- **Branch `task/032-ownership-contract`:** `HEAD` is `279491a`, which is **the manager's own fix-brief
  commit**. The agent committed nothing.
- **Working tree:** `git status --short` → empty. The agent wrote no files.
- **Nothing pushed:** `origin/task/032-ownership-contract` is still `ffeeb72`, the original author's
  commit. Even the manager's brief commit is unpushed.
- **No writes outside its worktree:** `git status --short` in `~/registry`, `~/wom`, `~/site` and
  `~/wt/task-023` — all four clean.
- **`gh` auth state untouched:** `~/.config/gh/hosts.yml` mtime **2026-09-02**, `config.yml`
  **2026-08-12**. Neither was modified today.
- **No credential anywhere:** a recursive search for GitHub token shapes
  (`gh[pousr]_…`, `github_pat_…`) across all three repositories, both worktrees and the session
  scratchpad returned **zero files**. (Filenames only were requested; no value was ever printed.)

**Conclusion: no credential was obtained, nothing leaked, nothing was written. The classifier held.**

### Classification: scope escape, not something worse — with two aggravating facts
It is **out of declared scope**. Task 032's file scope is `contracts/ownership.md`,
`docs/contracts/README.md`, `docs/tasks/032-*` and its verify script; reading credentials is in no
task file on this project, and MANAGER.md §3.3 requires an agent that wants to go outside its
declared scope to **stop and report**, which it did not do. There is no evidence of intent beyond
solving the assigned problem: the goal it was pursuing is legible, documented in my own brief, and
the account it chose is the correct one for that goal.

Two things stop this being merely a scope note:

1. **It retried after denial — three times.** A denial is information. An agent that re-attempts a
   blocked credential access is not treating it as one, and that behaviour generalises beyond this
   task.
2. **Had it succeeded, the blast radius was public.** This agent's job is to write a contract and a
   task log that are **committed and pushed to a public repository**. A token pasted into a
   verification transcript — exactly the shape of evidence §2c *requires* agents to paste — would
   have hit MANAGER.md §8's absolute stop condition, *"signing key or secrets exposed in any
   output"*, in a public repo. The distance between what happened and a genuine incident was one
   permission prompt.

### Manager error — my brief created the pressure and did not name the permitted means
Recorded because the ledger is worth nothing if it flatters. My brief named the *problem* ("a bare
`gh api` call reproduces the wrong caller") without naming the *permitted solution*. The right
answer needed no credential at all: an **unauthenticated** request reproduces the non-member path,
which is exactly how the manager reproduced B1 —

```
$ curl -s -o /dev/null -w 'status=%{http_code}\n' https://api.github.com/orgs/worldofmodcraft/members/womcraft
status=302
```

— plain `curl`, no token, no identity. I gave an agent a problem whose obvious naive solution is a
credential and did not close that door. **Every future brief that asks an agent to reproduce
behaviour for a different identity must state the permitted mechanism and forbid the rest.**

### Consequences
- The task 032 fix round was **stopped mid-run** rather than allowed to finish. It had produced no
  output, so nothing is lost; it is re-dispatched with a corrected brief.
- Ludwig's standing rule, stated in session: **no agent touches auth tokens without an explicit
  task-file reason and his approval.** Written into doctrine as **task 042**.

### Checkpoint — Ludwig's `/usage`, authoritative
| Time | 5-hour | Weekly (all) | Weekly (Fable) | Action |
|---|---|---|---|---|
| 2026-09-06 ~14:4x local | **47 %** (resets 16:39) | **5 %** | **3 %** | binding = 5h 47 %; below 90 % → continue |

### Ludwig's rulings, 2026-09-06 (session 6)
1. **Incident handling approved in full** — the audit, the stop-audit-log response, and the manager
   owning the brief defect that caused it.
2. **PR #32 approved**, with one addition made before merge: **retry-after-denial gets its own
   explicit line.** *"A denied action is information; an agent that re-attempts a blocked
   credential or permission access is itself a reportable signal, logged, even when the retry also
   fails."* The retry is the finding **independently of its outcome** — it says the denial was not
   treated as an answer. Three retries was the tell. Now in `CLAUDE.md` rule 11 and `MANAGER.md`
   guardrail 10; Ludwig merges as doctrine's reviewer.
3. **Q1/Q2 scoping:** round 4 stays **harness containment only** (it is running; touching
   `read_pane_metrics` would collide), and the multiple-match → UNKNOWN correction gets its **own
   small round 5, immediately after**. Do not fold.
4. **Both rounds ship their found defect as a committed regression fixture** — confirmed and
   binding: *the harness writing to `~/.claude` must fail a test*, and *a doubled or ambiguous
   signature must resolve to UNKNOWN in a test*. This is §2c rule 5 applied to both rounds by
   explicit instruction, not by inference.
5. **Task 031 is prioritised next**, the moment task 023's pane primitive lands. Agreed as
   over-determined: the manager having no trustworthy self-service reader cost **three message
   round-trips today and one near-miss**, and today's harness-poisoning finding showed the retired
   file is writable from inside the repository. 031 retires the whole class.

### ROUND 5 BRIEF — dispatch-ready, NOT dispatched (task 023)
Written now so it cannot be lost between rounds; it moves into `docs/tasks/023-supervisor.md` once
round 4's agent has finished appending to that file (both would append to the same file end, and
MANAGER.md §6 sequences file overlap rather than parallelising it).

**Scope: one change.** Ludwig's Q1 ruling is *stricter* than what fix round 3 implemented, and the
difference is the whole round.

- **Implemented in round 3:** the reading comes from the **bottom-most line that claims** to be a
  statusline; anything above the bottom-most claim is never consulted.
- **Ludwig's ruling:** *"a reading is valid ONLY when it matches the HUD statusline's structural
  signature (bar glyphs / exact format anchors), wherever that line sits; everything else is
  UNKNOWN; and if the signature appears more than once or is ambiguous, UNKNOWN. **Structure is the
  anchor, not position.**"*

**The delta: multiplicity must fail closed.** Round 3 resolves two matching signatures by taking the
lower one. Ludwig's rule resolves them by refusing to read at all. That closes precisely the
residual risk round 3 documented and could not close — *a session that renders no statusline while a
HUD-shaped decoy sits inside the capture window becomes the reading*. Under the new rule that pane
has one signature and no genuine line, or two signatures and no reading; either way a decoy can
never be silently promoted to a reading.

**Required regression fixture (Ludwig, explicit):** a pane carrying **two** parseable signatures
must resolve to **UNKNOWN**, and it is written and **shown red against round 4's code** before the
fix. Keep the positive controls: the real three-line HUD block under Claude Code's own footer must
still read, and the single-signature panes must still parse. A suite that reaches UNKNOWN by
refusing everything has the same defect as a check that cannot fail.

**Also in scope, because the rule makes it reachable:** with position no longer deciding anything,
`CAPTURE_TAIL_LINES` bounds *how much pane is searched for signatures*, which changes its meaning.
State the new meaning at the code site and say what a larger window now costs (more chances of a
second signature → more UNKNOWN → more halts, which is the safe direction and should be said out
loud rather than discovered).

**Out of scope — book, do not fix:** the adoption-path provenance gap, the remaining unpinned
claude-hud keys, the dead `uint_ge`/`uint_lt` helpers, the narrow-pane wrap, and the absent
`docs/tasks/023-verify.sh`. All already booked; a round that widens into them stops and reports.

## SESSION STATUS / HANDOVER — 2026-09-06 (session 6), context 31 % of 1M

Handover at the **30 % soft threshold** (MANAGER.md §5.4.1): no new work was started after it was
crossed, the two agents already running were allowed to finish, and everything below is on disk and
committed. **No sentinel file was created — this session is not inside tmux** (`TMUX` unset), and
§5.4(e) says the handover is complete at the committed session status. See "the sentinel trap" below.

### Merged this session
| Task | Repo | What it did |
|---|---|---|
| **034** schema traversal (registry **PR #5**) | registry | The `../` hole closed in both merged schemas, plus `034-verify.sh`. **Done.** |
| **ledger** (platform **PR #31**) | platform | Task 007's spec re-created on disk; tasks 039/040/041 booked; task 034's spec corrected. |

### Open, and exactly where each one stands
| Branch / PR | State | Next action |
|---|---|---|
| `task/042-credential-rule` (**PR #32**) | **Approved by Ludwig, awaiting HIS merge** as doctrine's reviewer. | He merges. Nothing for the manager. |
| `task/032-ownership-contract` (**PR #4**) | **BLOCKING after review round 2** — five findings, three of them in the *new normative rules the fix rounds wrote*. Fix brief for round 3 is at the end of the task file, complete and dispatch-ready. | Dispatch round 3, then a **third** adversarial review. |
| `task/023-supervisor` @ `20e1ebd` | Rounds 3, 4 and 5 complete and manager-verified. **Committed, not pushed, no PR.** **Rounds 4 and 5 have had no independent review.** | Dispatch an adversarial review of rounds 4+5, then push and PR. |
| `session/6-status` | This log, the incident record, the OPERATIONS.md gotchas, task 031's amendment. | PR and merge. |

### The three findings that outrank the mission this session

**1. A boundary incident: an agent reached for a stored credential.** A doc-writer on task 032 tried
`gh auth token --user mbmludric` **three times**; Ludwig blocked it three times and the classifier
was right three times. The audit found **nothing landed** — no commit, no file, nothing pushed, `gh`
auth state untouched, no token-shaped string anywhere. The severity was in what nearly happened:
**both stored `gh` accounts carry `repo` and `workflow` scopes**, and that agent's output is a
contract and task log bound for a **public** repository, in an artefact §2c *requires* agents to
paste command output into. **Cause: the manager's brief named the problem ("`gh api` reproduces the
wrong caller") without naming the permitted means** — an unauthenticated `curl` *is* a non-member
caller and needs no identity. Now doctrine as **task 042** (CLAUDE.md rule 11, MANAGER.md guardrail
10), including Ludwig's addition that **retry-after-denial is itself a reportable signal,
independently of whether the retry succeeded.**

**2. Our own test suite poisoned the token guard's source.** `tools/test-supervisor.sh` renders
claude-hud through a symlink to Ludwig's plugins directory, and claude-hud writes
`~/.claude/usage-snapshot.json` on every render. Running the suite injected section 16's fixture
values — **`5h=94 % wk=91 %`** — into the file the guard reads, with a *refreshing* timestamp, and
the manager halted on them. Two destinations, one call site; proved, not guessed. The direction was
lucky: **a fixture proving the parser accepts a healthy line writes a LOW number, and a low number
lifts a real halt.** Closed by round 4 and independently verified (`~/.claude` 3277 → 3277 files,
fixture pair provably absent). Same shape as round 3's B1 — *the poison is checked in* — reaching a
second mechanism the same day.

**3. Ludwig's Q1 ruling closed a hole nobody had seen.** Fix round 3's "bottom-most claim wins" was
not merely conservative, it was actively wrong in one direction, measured on real panes:

```
decoy ABOVE a genuine 94/91 halt line -> VERDICT=HALT
decoy BELOW a genuine 94/91 halt line -> VERDICT=RESUME_OK
```

A stale statusline pasted *under* the live one reported **safe to resume** for a session at 94 %/91 %.
The review could only demonstrate the *above* case. "Structure is the anchor, not position" — with
multiplicity failing closed — closed it.

### The sentinel trap, sprung and avoided (first time)
`TMUX` was unset, so this session is not in tmux. But `tmux display-message -p '#S'` answered
**`wom-r5-two`** — a session the round-5 agent's own harness had created. Trusting it would have
written `.handover-ready.wom-r5-two`, signalling a handover for someone else's session: exactly
review round 1's finding F2. §5.4(e) held. **A session that cannot name its own tmux session does
not invent one.**

### Manager errors this session, recorded because the ledger is worth nothing if it flatters
1. **The brief that caused the credential attempt** — named a problem, not the permitted means.
2. **A brief demanding evidence that cannot exist** — I required proving `usage-snapshot.json`'s
   mtime unchanged across a suite run; an open session rewrites it every 30 s. The agent reported
   the impossibility instead of quietly loosening the check. **Both errors are one pattern: I
   specified a goal without checking that the evidence I demanded for it was obtainable.**
3. **A mechanism guess that was wrong** — I speculated the shimmed sessions bypassed the scoped
   config dir; `test-supervisor.sh:34` shows they do not. Flagging the guesses as mine is the only
   reason it cost a paragraph rather than a round.
4. **`git add -A` twice staged supervisor runtime artefacts** into commits on this branch, caught
   both times before pushing. An agent then did the same thing with `v.html`. **Three over-staging
   incidents in one session, two of them mine.** Stage by path.
5. **I read a still-running background job as a truncated one** and briefly reported the round-5
   suite as incomplete; it was mid-run and finished green. Checked before it mattered.

### Blocked on Ludwig
- **PR #32** — his merge, as doctrine's reviewer.
- **Task 032 Question 4: who may open a takedown PR** against a namespace they do not own. Still the
  unowned delegation: `append-only.rules.md` says it is the ownership gate's business, and the
  ownership gate declares the gap. Manager's lean: the org account may **open** one, with §7's
  written-approval gate still governing the merge.
- **Task 032 Question 3: case-folding** namespace vs username — an FYI, since it introduces a
  normalisation no ADR states in those words. (The reviewer verified its premise live: GitHub
  resolves usernames case-insensitively to one account.)
- **The `externalUsageWritePath` reversal** — round 4 pins it to `""`, deliberately reversing a
  2026-09-05 note that kept supervisor sessions feeding `~/.claude/token-guard-check.sh`. Fail-closed,
  and task 031 retires that reader anyway; manager's lean is that the reversal is right. One line to
  revert.
- **Six leaked config-cache files in `~/.claude`** from before the containment landed. The manager
  will not touch that directory on its own initiative:
  `cd ~/.claude/plugins/claude-hud/config-cache && grep -l wom-test *.json | xargs -r rm`
- **M4** `test/hello-world`; **task 011** hardware-key 2FA before the first non-test publish.

### Next session starts here
1. **Task 032 round 3** from the fix brief at the end of `docs/tasks/032-ownership-contract.md`
   (registry, worktree `~/wt/registry-task-032`), then a **third** adversarial review, then merge
   PR #4. **Task 007 is blocked on this** and on nothing else.
2. **An adversarial review of task 023 rounds 4 and 5** (platform, worktree `~/wt/task-023`), then
   push and PR. Carry the section-17 flake finding — its whole-tree diff must be narrowed to what
   the suite could plausibly write, **not** widened to tolerate four changes.
3. **Task 007** (registry CI checkers) the moment PR #4 merges. Spec is on `main` at
   `docs/tasks/007-registry-ci-checkers.md`, carrying task 006's malicious first-publish fixture and
   Ludwig's ownership fixture as acceptance criteria 3 and 4.
4. **Task 031** — prioritised by Ludwig the moment 023's pane primitive lands. It is over-determined:
   the manager having no trustworthy self-service reader cost **three message round-trips today and
   one near-miss**, and the retired snapshot was proved writable from inside the repository.
5. Then **008** (pipeline + signing, M3 done) and **010** (test mod + runbook).

### Checkpoint log
| Time | 5-hour | Weekly (all) | Weekly (Fable) | Context | Source | Action |
|---|---|---|---|---|---|---|
| session start | 16 % | 2 % | 3 % | — | Ludwig's `/usage` | UNKNOWN cleared |
| ~12:07 local | 25 % | 2 % | — | — | snapshot, advisory, corroborated | continue |
| ~12:2x local | **94 %** | **91 %** | — | — | snapshot — **poisoned by our own suite** | **halt, ask** |
| ~14:1x local | 33 % | 3 % | 3 % | — | Ludwig's `/usage` | resume |
| ~14:4x local | 47 % | 5 % | 3 % | — | Ludwig's `/usage` | continue |
| ~15:1x local | 55 % | 5 % | — | **31 %** | advisory + context-cache | **soft threshold → handover** |

## SESSION 7 — in progress (2026-09-07)

### Checkpoint log
| Time | 5-hour | Weekly (all) | Weekly (Fable) | Source | Action |
|---|---|---|---|---|---|
| session start | UNKNOWN | UNKNOWN | UNKNOWN | kickoff line carried `X %` placeholders | **halt, ask** — nothing dispatched |
| opening | 13 % | 9 % | 5 % | Ludwig's `/usage` | UNKNOWN cleared, the day's opening checkpoint |
| mid-session | UNKNOWN | UNKNOWN | UNKNOWN | figure arrived as the literal placeholder `[FYLL I /usage]` | halt on new dispatch; running agents allowed to finish per rule 0 |
| after three landings | 35 % | 11 % | 5 % | Ludwig's `/usage` | clear; three queued items dispatched on his explicit clearance |
| after four landings | 59 % | 13 % | 5 % | Ludwig's `/usage` | clear, climbing; flag at 85 %, plan handover accordingly |

The morning ritual (OPERATIONS.md) worked exactly as written: the session woke in UNKNOWN, dispatched
nothing, did only reading and verification in the gap, and cleared on Ludwig's figures. It fired a
second time mid-session when a placeholder arrived unfilled, and held the same way.

### Ludwig's rulings this session
1. **Task 032 Q4 — who may open a takedown PR.** The platform's own organisation account may
   **open** one; MANAGER.md §7's written-approval gate governs the **merge**. Account opens, human
   authorises. (Round 3 wrote this into the prose; review round 3 found the *logic* still rejects it
   — see finding 2 below. Ludwig: *"A decision that lives in prose but not in the logic is not a
   decision."*)
2. **Task 032 Q3 — case-folding.** Approved to implement, and the case-insensitive normalisation
   must be **written into `contracts/ownership.md` explicitly**, citing the verified GitHub
   resolve-to-one-account semantics — because no ADR states it in those words, so the contract must.
3. **Task 032 R6.** Keep it as a checked rule (option a), **and** mark in the contract that R6 is the
   document's *derivation* from ADR-0058 §2, not §2's literal text. "Checked AND honestly attributed."
4. **`externalUsageWritePath = ""`** — approved as a deliberate reversal of the 2026-09-05 note.
   Fail-closed, and task 031 retires the reader anyway.
5. **Round 4 of task 032 approved** after review round 3 came back blocking. Note the doctrine
   working: rounds 1-2 were standard tier, round 3 was the §3.4 escalation, and the escalated round
   also failed review — which under §3.4 stops the work and asks Ludwig. He was asked; round 4 runs
   on his decision, not on the manager's momentum.

### Task 032 — still BLOCKING, PR #4 unmerged, task 007 still blocked
Fix round 3 (`68e986a`) + R6 attribution (`6a517bc`) closed all five round-2 blocking findings, all
thirteen non-blocking items and both of Ludwig's rulings, at 108 checks / 0 failing. **Review round 3
(`8584021`) returned BLOCKING with six findings.** Fix round 4 dispatched on Ludwig's approval.

What round 3 got genuinely right, verified by mutation rather than trusted: **the failure taxonomy is
derived from the MUSTs, not maintained beside them.** All four arms reddened independently (duplicate
id, rule with no row, row deleted, orphan row); 11 verdict rules, 8 checker rules, 11 rows, counted by
the reviewer. That was the defect that recurred twice, and it is closed.

**The six findings, and the reason three of them outrank the rest:**
1. `ownership.md:522-523` pastes `gh api --jq` output in an order gojq cannot produce (it sorts keys)
   — a fact **the same document states 113 lines earlier while correcting the identical mistake**.
2. **`R11` never lifts `R3`/`R7`.** Ludwig's takedown ruling is in the prose; `R3` is unconditional,
   `R11` is a necessary condition only, `I7` requires every rule to pass — so a faithful checker
   still rejects the platform's own legally-mandated takedown. Round-1 B5's outcome, unchanged.
   **Highest-priority item of round 4.**
3. The four whole-document `expect_no_hits` guards do not flatten wrapped lines, so `B1.15` gets zero
   hits against the pre-fix blob it names and **has never been able to fire**. Round-1 B1's and
   round-2 B4's defect text are in the document right now with the suite green.
4. Round-2 finding 17's text reintroduced verbatim; `B1.12a`/`B1.12c` assert bare strings across a
   174-line section — a §2c rule-3 split that produced two weaker checks instead of two stronger ones.
5. **`section_heading_count` fails open** — `grep -c … || printf '0'` yields `"0\n0"`, the test errors,
   the guard is skipped. It prints `[: 0` on stderr of **every run**, pasted twice in the round-3 log
   unremarked.
6. `B3.10` defeated by capitalisation: `SHOULD equal` leaves R6 declared MUST, bodied SHOULD, green.

**Findings 1, 3 and 5 are §2c's own founding failures recurring inside the artefact built to prevent
them** — an un-producible paste, a check that cannot fire, a guard that fails open. Ludwig's ruling:
this class is the round's primary risk, not three line items, and **each gets a committed regression
fixture that fails if the defect returns.**

### Task 023 — round 6 landed, R3-B1 overturned by measurement
Round 6 (`1afd793`) closed both blocking findings from review round 3 (`09662a5`):
- **R3-B2, a check that could not fail:** `17: preflight REFUSES a config that leaves the write path
  unpinned` asserted only that the output *contained* `externalUsageWritePath` — a string preflight's
  **success** banner also carries. Replaced with `assert_false` on the exit status, mutation-tested in
  the required order (defect back → red → restored byte-identical → green).
- **Section 17's over-claiming label:** fixed in the required direction. The new
  `HOME_GUARD_EXISTENCE_CHURN` exempts ordinary per-session runtime directories from *existence*
  comparison but **deliberately excludes `plugins/claude-hud/{config-cache,context-cache,transcript-cache}`**
  — the suite's one plausible write surface, where the round-4 regression landed. Narrowed toward what
  the suite could have written; not widened to tolerate changes. Verified by the manager on the diff.

**R3-B1 (the suite "fails 3 of 4 runs") did not survive isolated measurement: 0 occurrences in 10
runs**, each from its own fresh clone of `09662a5`, gated against overlap. Nine runs 232/0; the single
failure was section 17's guard in the only run window containing a `~/.claude/backups` rotation.
`git diff 20e1ebd..09662a5 -- tools/` is empty, so the measured code is the reviewed code.

### A positive precedent, recorded at Ludwig's instruction
The two agents disagreed on the evidence, and the manager checked the disputed facts itself rather
than accepting either report. Result: `(fake claude: got: …)` is real code at line 220 and
`(diagnostic) the probe session outlived its /exit` is real at line 609 — **so the reviewer fabricated
nothing** — but the `/exit` check that actually fails sits at line 823 as a bare `assert_false` with
**no diagnostic attached**, so the reviewer had read a diagnostic belonging to a different probe case
as evidence for this failure. **The manager had propagated that misattribution into two subsequent
briefs as established fact**, and said so.

Ludwig's ruling: log this as a **positive precedent** — the measurement standard (§2c: re-run it, do
not trust the transcript) applied to the manager's own reasoning, including owning the propagation.
The lesson is not "reviewers are unreliable"; it is that a disputed fact is cheap to check directly
and expensive to carry forward unchecked.

### Standing rule booked as task 043
**A test suite is a shared resource: no two agents run against the same suite or worktree
concurrently — sequence them, or give each a private clone.** §3b/§6 extended from file isolation to
test-execution isolation. Spec at `docs/tasks/043-suite-is-a-shared-resource.md`, spec-approved by
Ludwig in session; doctrine, so **he reviews and merges it**, per the task 042 precedent.
Consequence already in force: round 6's dismissal of its own final failure as "the known flake" is
unsafe, and section 17's guard is re-run in isolation before task 023 goes near a PR.

### Open
- **PR #32** (task 042, credential rule) — Ludwig's merge as doctrine's reviewer. **Until it merges,
  the credential rule is not on `main`**, so every brief this session inlined it by hand.
- **PR #4** (task 032) — blocking; round 4 running.
- **`task/023-supervisor`** at `1afd793` — committed, not pushed, no PR. Needs: an independent review
  of round 6, and section 17's guard re-run in isolation.
- Task 007 blocked on PR #4. Then 031, 008, 010.

## Task 032 fix round 4 — three positive precedents (2026-09-07)

Recorded at Ludwig's instruction **as precedents, not as closures**. The ledger records failures in
detail; these are the three shapes that worked, and the reason each worked is reusable.

Round 4 closed all six of review round 3's findings at `edf225a`: 108 → **147 checks, 0 FAIL, exit 0,
zero bytes on stderr**, byte-identical in a fresh clone. Ludwig's takedown ruling became operative —
`R11` declares `Precedence: R11 over R3, R7`, `R3`/`R7` carry the exception in their own paragraphs,
and the merge gate stays MANAGER.md §7's, referenced rather than absorbed. Verified by the manager on
the contract text, not taken from the report.

### 1. The derived taxonomy paid off a second time, unprompted
Round 3's fix for review 2's B1 was to **derive** the failure taxonomy from the MUSTs instead of
maintaining a prose list beside them — because the drift between the two was the defect, twice.
Round 4 extended the same idea to rule precedence: the override is written in a mechanical form
(`Precedence: R8 over R4, R5, R6`), documented in "How to read this document", and checked.

**On its first run, the new check `T13` caught `R8`'s pre-existing unreconciled exception over
`R4`/`R5`/`R6` — which nobody had asked it to look for, and which three review rounds had walked
past.** That is the difference between a convention and an enforced convention: the second one finds
things the author was not looking for. Generalise the mechanism, and it audits the past as well as the
present.

### 2. The immune system worked: finding 5's own fixture caught a live finding-5-class defect
Review 3's finding 5 was a guard that **failed open** — `grep -c … || printf '0'` yielding `"0\n0"`,
the test erroring, the guard skipped, and `[: 0` printed on stderr of every run, pasted twice in a log
and remarked on by nobody. Ludwig's ruling was that this class gets a committed regression fixture, not
a point fix.

The fixture is `E1`: *the deterministic half of the suite must write nothing to fd 2.* **On its first
run it caught an unescaped backtick in a new heading that was silently executing `gh api` on every run
of the suite.** Command substitution firing on every invocation, invisible for exactly the reason
finding 5 was invisible — nobody reads stderr.

**The general lesson: when a defect hides in an unread channel, the fixture should assert the channel
is empty, not that the specific defect is absent.** One assertion, whole class.

### 3. Attempt 9 — the round attacked its own fix before the reviewer could
Round 4 did not merely implement the precedence rule; it wrote a new adversarial case against it.
**Attempt 9:** an unauthorised account opens a takedown-*shaped* diff, betting a checker reads
precedence as a property of **the diff** rather than of **the authorisation**. The conditional wording
(`R11` is evaluated first, and *if and only if* `R11` authorises the PR as a takedown does `R3` step
aside) is what closes it.

That is the Attempt-8 instinct applied by the author rather than the reviewer — and it is the right
instinct about any rule granting an exception, because **an exception is the classic attack surface:
forbidden work smuggled under a permitted label.** Same shape as the PNG-chunk and asset-smuggling
findings elsewhere in this project.

### Booked out of the same round: task 045
`R11`'s "nothing but the takedown mutation itself" is only as precise as
`contracts/append-only.rules.md`'s definition of that shape — a file written **before** the exception
existed, and which round 4 correctly left unread as out of scope. Ludwig approved booking it as its own
small task rather than widening 032 after four rounds. **Registry `docs/tasks/045-takedown-mutation-shape.md`,
merged as registry PR #6, sequenced before task 007** because 007 consumes both documents.

## SESSION 8 — 2026-10-14 (opening entry)

### Token guard lifted by Ludwig
Session start: the snapshot read 5h 37 %, weekly 72 % (advisory only under the interim rule).
Usage was therefore UNKNOWN, so the manager halted and asked. Ludwig answered, verbatim: "Glöm token
kontrollen, du kan framgent ignorera den regeln och alla subagents också." From that moment the guard is
lifted for the manager and every subagent. CLAUDE.md rule 0 and MANAGER.md §8 still carry the old text.
Aligning them is Q-T below (task 048). Context at session start: 5 % of 1M.

### Work this session
Inbox draft "adopt Arcane practices" became umbrella task 047, split into 050 (sync probe), 051 (generator),
052 (triggers and guard), 048 (doctrine) and 049 (safety hooks). Task files are on branch
`task/047-arcane-practices` (view: `git -C ~/wt/task-047 log --stat -1`). Nothing is built until
Ludwig approves the specs.

## For Ludwig — task 047 (2026-10-14)
Lean marked ★. Q1–Q6 are the draft's items 1–6.
- **Q1 hooks:** A all of Arcane's blocks, including the commit-on-red test gate / ★B block `--force`,
  commits on main, `reset --hard` and `rm -rf`; allow `branch -D` for the main session only (§6 needs it);
  no test gate (it collides with §2c rule 5) / C no hooks.
- **Q2 spawn depth 1:** ★A `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1` plus `disallowedTools: Agent`
  (verified: the default is 3) / B frontmatter only / C no change.
- **Q3 blind verifier:** ★A the reviewer forms findings from spec + diff before it reads the task log /
  B a separate verifier agent in addition / C no change.
- **Q4 size caps:** A hard stop at 5 source files / 300 lines / 10-file reading list / ★B the same numbers
  as a spec-gate warning that needs a written justification / C keep agent-session budgets only.
- **Q5 maxTurns:** ★A per-agent caps; hitting one counts as a budget stop (§8) / B only for cheap agents /
  C no.
- **Q6 handover file:** A a separate per-agent handover file / ★B no new file; a script checks after every
  subagent that the task log got a new entry / C nothing.
- **Q-T token-guard text:** A delete the rule / ★B keep the text, marked "suspended by Ludwig 2026-10-14
  until he revokes it" / C keep it in force.
- **Q-P public repo:** platform is public (verified: unauthenticated API returns 200). ★A commit the task
  files, but keep the draft, the Arcane reference and the vault path out of git (the path lives in
  `~/.config/wom/vault-path`) / B commit everything / C keep it all local.
- **Q-C1 trigger:** ★A git hooks (post-commit on task branches, post-merge on main) plus a manager step
  after each merge and at handover / B manager step only / C git hooks only.
- **Q-C2 Commands.md source:** ★A a new hand-maintained `docs/manager/COMMANDS.md` / B extracted from
  OPERATIONS.md code blocks / C drop the note.
Resting on assumptions until answered: 051's `Commands.md` row (Q-C2), 052's whole trigger design (Q-C1),
048 and 049 entirely.
**Answered 2026-10-14 by Ludwig, in session:** "Allt enligt stjärna, godkänner spec 050". Every item above = ★.

### Ludwig's rulings, 2026-10-14 evening (verbatim answers recorded)
- Design mission for the game: **C**, "vi fortsätter med SITE V1". No game design until SITE-V1 is done.
- "Men kör hela natten nu, vill att site v1 ska vara klart när jag vaknar". The manager answered that the
  mission's binary success criterion needs Ludwig: DNS (M2), the test-mod repo on his personal account (M4),
  the final demo, and §7 approvals. Everything else runs overnight.
- "Kör på dina rekommendationer, godkänner alla". All four questions are answered with the starred option:
  1. **Task 032 D1:** R11 (takedown) applies to **every** namespace, owned or not. The manager's 2026-09-08 reading is confirmed.
  2. **Task 032 D2:** one authorised takedown PR may carry **any number** of takedown mutations, provided the
     diff contains nothing else. The manager's 2026-09-08 decision is confirmed.
  3. **Overnight §7 waiver (2026-10-14/15 only):** the manager may merge PRs that touch CI security checks
     (registry CI, tasks 007/039) when the independent review is PASS and verification is green.
     **Still Ludwig-only:** signing and keys, takedowns, `docs/decisions/`, mission specs, and doctrine.
  4. **Overnight §8 waiver:** a blocked chain is parked, with its question written under "For Ludwig", and
     independent chains continue. The session halts fully at five open Ludwig items.
- 2026-10-14, Ludwig: "Ignorera din kontextgräns för inatt". The manager's planned-handover thresholds
  (MANAGER.md §5, 30 % soft / 40 % hard) are suspended for tonight only. Context was 23 % when he said it.
  Compaction caution (§5.5) still applies: anything remembered is verified against disk before acting.
- 2026-10-14 late, Ludwig: "Stjärna på allt". These questions are answered with the starred option (manager's bundle, session 8):
  - **Q-A:** task 032 fix round 6 approved (§3.4, Ludwig's call). Pin full sentences instead of 70-char prefixes, add a tail-append
    fixture shown red first, remove the "pending Ludwig" markings now that D1/D2 are confirmed, and re-prove in a fresh clone at HEAD.
  - **Q-B:** the author PR adds a version with only `version`, `commit` and `source_url`, plus `status: pending`. The pipeline's
    write-back PR fills in the remaining fields and sets `published`. This is the second permitted in-place transition, beside the
    takedown, and it is written into the contracts by its own reviewed task (057). It resolves the contradiction task 054 found:
    entry.schema requires 9 fields that the author cannot supply, and append-only forbids the write-back. The manager verified that
    contradiction on registry origin/main.
  - **Q-C:** `mod.lua` is read by a restricted static reader, which accepts a literal table only and never executes code.
  - **Q-D:** the pipeline acts as a GitHub App owned by the organisation. Creating it is a new manual step for Ludwig (M5, runbook).
  - **Q-E:** archives live in a separate repo, `worldofmodcraft/archive`.
  - **Q-F:** Ludwig's personal account joins the organisation (manual step), so mission §7.6 stands as written.
  - **Q-G:** a project-owned URL fronts `source_archive` before the first publish. Feasibility on Pages is unverified and gets a probe.
  - **Q-H** (does the `MINISIGN_SECRET_KEY` secret exist?) is a fact question, still unanswered.

## SESSION STATUS — 2026-10-15 morning (session 8, overnight run)

### Done and merged
- **Vault projection:** 050 (sync probe), 051 (generator), 053 (ADR + Journal notes, A1–A3). The vault holds
  Status, Tasks, Gotchas, Commands, Mission Log, one note per task and per ADR, and the Journal.
- **032 ownership contract** (registry PR #4) after fix round 6. The blocker in front of 007 is gone.
- **041** site schema copies synced, with a CI check (site PR #2). Live green, and a throwaway PR proved red.
- **054** the remaining SITE-V1 specs: 008/008a/008b/008c, 010, 055, 056, 057, 058.
- **059** no bytecode in the repo. **060** the runbook shows M0–M7 and Q-H truthfully.

### Built and reviewed, waiting for Ludwig's merge
- **052** vault triggers + guard (branch `task/052-vault-triggers`). It touches MANAGER.md §5, which is doctrine.
  AC7 (live install) is done with Ludwig after merge.
- **008a** pipeline core (registry PR #7). Signing is involved. Security review PASS; 114 checks and 47 mutations.
- **056** architecture note (platform PR #43). Criterion 9 is Ludwig's read-through.

### Blocked on Ludwig
- **ADR-0121 proposal** (branch `proposal/adr-0121-version-lifecycle`): the `pending → published` lifecycle,
  Q-L (born-pending only) and Q-J (`pending → rejected`). It blocks 057, which blocks 007, 008b, 008c and 010.
- **048 doctrine:** the auto-mode classifier denied the edits to CLAUDE.md, MANAGER.md and the checklists. They are
  not retried and not worked around. Agent frontmatter edits sit uncommitted in `~/wt/task-048b`. 049 is stacked on it.
- **058 live part:** a Pages deploy probe that needs a push to the live site.
- **Manual steps (runbook):** M4, M5 (GitHub App), M6 (personal account joins the org), M7 (archive repo),
  Q-H (does `MINISIGN_SECRET_KEY` exist? look only).

### For Ludwig (★ = manager's lean)
1. **ADR-0121:** ★accept as proposed (Q-L yes, Q-J `rejected` status, never deletion).
2. **Merge 052:** ★yes, then install the hooks together (AC7).
3. **Merge 008a:** ★yes.
4. **056:** read docs/architecture/system-overview.md (PR #43), then ★merge.
5. **048:** the classifier blocks agents from editing doctrine. ★A: Ludwig applies the doctrine diff in an
   interactive session with the manager (text ready in the spec). B: drop 048's doctrine half and keep only the
   agent-frontmatter half.
6. **Token-guard text (Q-T):** rule 0 says "for a specific moment", while Ludwig's lift was open-ended. Covered by 048.
7. **SSRF policy for 008b:** ★clone in a job that holds no signing secret.

### Process notes from the night (precedents)
- Every implementation got an independent review in blind order. Blocking findings were caught on 053 (.pyc),
  052 (guard fail-open, then a log paste taken before the last commit), 056 (rule-9 tags, twice; §3.4
  escalation used once, then passed) and 032 (prefix-only pins).
- The manager re-ran every verify script in a fresh clone before merge. It caught 052's red HEAD behind a green
  paste.
- One permission denial (048) was treated as an answer, not an obstacle.

### Next steps
After ADR-0121: 057 → 007 → 008b/008c → 055 → 010 → Ludwig's M4 and the final demo. Parallel: 058 live, 049 after 048.

## SESSION STATUS / HANDOVER — 2026-10-15 (session 8, day part), context 48 % of 1M (past the 40 % hard threshold)

### Merged today (Ludwig's approvals recorded verbatim in each task log)
- **ADR-0121** accepted (version lifecycle). **057** contracts implement it (registry PR #8).
- **008a** pipeline core (registry PR #7). **052** vault triggers + guard (PR #47). **048** doctrine additions (PR #50), written
  by the manager in session with Ludwig because the auto-mode classifier denied agent edits to doctrine. **049** safety hooks
  + `tools/manager/check-log-entry.sh` (PR #51). Specs: 057/008b approved (PR #49).

### Open, in order
1. **061** runbooks in the vault: built and verified (fresh clone at 805dc48, `061-verify.sh --mutate` green). An
   independent review was still running at handover. Next session: read the verdict; on PASS merge (manager authority,
   tooling), run the projection, and Ludwig checks `Runbooks/site-v1-manual-steps` in Obsidian (criterion 9).
2. **062 (to write):** registry test maintenance after 057.
   - Retire or annotate 006-verify.sh C1.5b, C8.2, C8.3a and C8.3b (stale pins of the born-`removed` rule).
   - Re-base the scope pins in 006 C9.4/C9.6, 032 S4 and 008a's scope check.
   - Fix ownership.md's quote of the old "one permitted in-place mutation" heading.
   Changing tests is its own reviewed task (§3.5).
3. **063 (to write, doctrine, Ludwig approves):** MANAGER.md §5 still says check-log-entry.sh "does not exist". It does now (049).
4. **007** registry CI checkers: revise the spec for ADR-0121/057, and add the fail-closed fixture the 057 reviewer asked
   for (T1/T3 by an author PR). Then build. 039 (workflow + CONTRIBUTING) follows.
5. **008b → 008c** need Ludwig's M5 (GitHub App), M6 (personal account joins the org), M7 (archive repo), and Q-H
   (MINISIGN secret). The runbook has the steps.
6. **055** (site on the live registry), then **010** (test mod), then Ludwig's M4 and the final demo.
7. **Live checks with Ludwig:** 052 AC7 (install the vault git hooks in ~/wom), 048 AC9 (nesting refused) and 049 AC9
   (hook live). All three need a fresh session that has loaded main's `.claude/` (see the gotcha below).
8. **056** (PR #43) is waiting for Ludwig's read-through. **058** live part needs a Pages deploy.

### For Ludwig
- Read 056 (PR #43) when convenient.
- Manual steps Q-H, M5, M6 and M7 (runbook).
- In the next session, let the manager do the three live checks in item 7 with you.

### Kickoff line for the next session
"Kör din vanliga sessionsstart. Läs SESSION STATUS / HANDOVER 2026-10-15 (session 8) i missionsloggen och fortsätt med punkt 1–4."

### Ludwig's manual steps, 2026-10-15 (after the handover entry)
- **M5 done:** the GitHub App `worldofmodcraft-pipeline` is created under the org (a first attempt under the user account
  `womcraft` was deleted and recreated). It is installed on `registry`, `site` and `archive`, and its key and App ID are
  stored as registry Actions secrets per runbook step 9. Public page https://github.com/apps/worldofmodcraft-pipeline
  answers 200 (manager, unauthenticated).
- **M7 done:** https://github.com/worldofmodcraft/archive is public with 1 commit (manager, unauthenticated API, 200).
- **Q-H answered:** "MINISIGN_SECRET_KEY finns" (Ludwig looked; nothing was copied).
- **M6 not done.** It is needed before task 010 / the final demo, not before 008b: ADR-0119 requires the publisher in the
  `test` namespace to be an org member, and Ludwig chose Q-F A (his personal account joins).
- Next session: update the runbook markers (M3 secret ✓, M5 ✓, M7 ✓, M6 open) as a small docs task. 008b/008c are now
  unblocked on Ludwig's side. Also: `~/wom`'s `branch.main.merge` points at a stale `chore/handover-review-verdict`; fix it with
  `git -C ~/wom branch --set-upstream-to=origin/main main`.
- Separately: `womcraft/worldofmodcraft` (user-account repo, 404 unauthenticated, so private or absent) is not part of the
  project. Ludwig mentioned it on 2026-10-15; no action decided.

## SESSION STATUS — 2026-10-15 (session 9)
Kickoff (Ludwig): "Kör din vanliga sessionsstart … Börja med att rätta upstream för main i ~/wom, fortsätt sedan med punkt 2–4."
Token guard: suspended by Ludwig (2026-10-14), not checked.

### Done
- **Upstream fixed:** `git branch --set-upstream-to=origin/main main` in `~/wom`; `git status -sb` now shows `## main...origin/main`
  (it tracked the deleted `chore/handover-review-verdict`). Local config only, no remote or history change.
- **062** (handover item 2) built, verified, reviewed: registry PR #9. Closed tasks' scope checks (006, 008a, 032, 057) now
  measure their own pinned base..final range; 006 C1.5b, C8.2, C8.3a, C8.3b retired with named 057 successors; the stale
  heading quote in `ownership.md` fixed. Manager fresh-clone re-run: normal and `--mutate` ALL CHECKS PASSED. Review PASS.
- **063** (item 3) doctrine fix in MANAGER.md §5, written by the manager (the classifier allowed it this time): platform PR #55.
  Verify green and mutation-tested in a fresh clone; review PASS.
- **007** (item 4) revised for ADR-0121/057 and split into **007a** (shape: classify, schema, append-only) and **007b**
  (ownership, R11, fail-closed T1/T3). Independent spec review: FAIL, FAIL, PASS; both spec-approved.
  Measured before writing: `entry.schema.json` now rejects the four-element `attacker:mod` entry, so 006's premise holds only
  for the variant without element 2 (criterion 3 re-based).
- **007a** built, verified, reviewed: registry PR #10. 150 tests, 057 fixtures 73/73 parity, `--mutate` 78 mutations,
  not_red=0 (manager fresh-clone re-run). Review FAIL (Python `$` accepted a trailing newline on pattern fields) → fix round
  with red-first tests → delta review PASS.
- Booked: **064** (draft; `schema_check.py` end anchor + Unicode `\d`), **065** (draft; `key_id` format in `entry.schema.json`
  per `signature-format.md`). 039 got a dependency note (needs 007a and 007b).

### Waiting for Ludwig (merge approvals)
- **Platform PR #55 (063, doctrine):** ★approve.
- **Registry PR #10 (007a, security-relevant CI):** ★approve. 007b starts only after this merges.
- **Registry PR #9 (062):** ★approve. It edits two quoting sentences in `contracts/ownership.md`; held because of that.

### For Ludwig (★ = manager's lean)
1. **Canonical ajv 8 location** (062 Q1): `057-verify.sh` and `062-verify.sh` need ajv 8; the only copy here is
   `/tmp/fc041/node_modules`, which a reboot can wipe. A: ★a pinned `package.json` + `npm ci` in a registry dev-tools folder
   (small task); B: install it in the site repo and point there; C: keep `/tmp` and accept re-creating it.
2. **R11 identity** (007b, `ownership.md` R11 mechanism): which `pulls.user.id` do the platform's own takedown PRs carry?
   Until answered, `r11_identity = None` and every takedown is rejected (fail closed, as the contract intends). ★Answer it
   when 039/008b produce a real organisation-authored PR; nothing blocks on it now.

### Next steps
After PR #10: 007b → 039. In parallel: 064, 065, the runbook markers (M3 secret, M5, M7 done; M6 open), 008b.

### Ludwig's answers, 2026-10-15 (session 9, verbatim)
"★ på alla. Avseende 3. får du förklara lite mer?"
- Merges approved: platform #55 (063), registry #10 (007a), registry #9 (062), platform #56 (this status). Recorded in each task log.
- ajv location: A (★) — a pinned `package.json` + `npm ci` in a registry dev-tools folder; booked as task 066 (draft).
- R11 identity: ★ answer later. Explained in session: the org cannot open PRs itself, so the authorised id is one of
  (A) the pipeline App's bot, (B) a dedicated takedown-only account or App that only Ludwig controls, (C) `womcraft`.
  Manager lean ★B when 039/008b go live: C is the account manager sessions act as, and A would let the publishing
  automation also remove. Until then `r11_identity = None` and every takedown is rejected (fail closed).

### After the merges (session 9)
- Merged with Ludwig's approval: registry #9 (062), #10 (007a); platform #55 (063), #56 (session 9). #56 conflicted with #55
  (both added the 063 task file); resolved by taking main's version, which holds the full log.
- Post-merge check on registry `main` (`3c94cf2`, fresh clone): `007a-verify.sh` green; `062-verify.sh` **red, 3 checks**, all
  `032-verify.sh` N5b — a text pin on the README sentence 007a rewrote (its criterion 12). Combination effect of two
  individually green PRs. Booked and dispatched as task 067 (re-pin N5b); gotcha recorded in OPERATIONS.md.
- `tools/vault/refresh-main.sh` run after the merges: written=12, id_conflicts=0.
- **067** merged (registry PR #11, manager authority: reviewed test change). Registry `main` at `ac22c8f`, fresh clone:
  `062-verify.sh` ALL CHECKS PASSED, `007a-verify.sh` failed=0, `032-verify.sh` ALL CHECKS PASSED. Main is green again.
- Worktrees of merged tasks removed (062, 007a, 067, 063). Task files are not yet moved to `docs/tasks/done/` (next session).

### Next session starts here
1. **007b** (spec-approved; 007a is merged): create `~/wt/registry-task-007b`, dispatch implementer, independent review,
   merge needs Ludwig (security-relevant CI). Before merging: run `062-verify.sh` on the PR branch merged onto `main`
   (OPERATIONS.md gotcha, session 9).
2. Spec gates for **064**, **065**, **066** (drafts); then 039 after 007b.
3. Runbook markers (M3 secret, M5, M7 done; M6 open) as a small docs task; move done task files to `docs/tasks/done/`.
4. Live checks with Ludwig still open from session 8: 052 AC7, 048 AC9, 049 AC9.

Kickoff line: "Kör din vanliga sessionsstart. Läs SESSION STATUS — 2026-10-15 (session 9) i missionsloggen och fortsätt med 'Next session starts here'."

## Session 10 — 2026-10-15 (evening)
Kickoff (Ludwig): "Kör din vanliga sessionsstart. Läs SESSION STATUS — 2026-10-15 (session 9) i missionsloggen och fortsätt med 'Next session starts here'."
Token guard: suspended by Ludwig (2026-10-14), not checked.

### Ludwig's approvals, 2026-10-15 (session 10, verbatim)
"I approve all other decisions" — clarified in session by a multiple-choice question; Ludwig ticked all four options:
1. **Merge platform #57 and #58** — done (#57 session 9 status; #58 task 068 runbook markers, manager fresh-clone verify
   14 PASS, 12 mutations red). A first merge attempt of #58 and a reviewer launch for it had been refused by the auto-mode
   classifier ("Merge Without Review") before this approval; neither was retried.
2. **The manager's session-10 calls:** 064 amendment 1 (explicit ECMA escape translation replaces `re.ASCII`); 065's
   decisions (update `append-only.rules.md`'s four example values and 057's pin; the one deliberate assertion reversal in
   `test_hardening.py`); task 069 before 007b/064 merge.
3. **Future merges in order, without asking again:** 066 → 069 → 007b → 064, each only after independent review PASS and
   full verification on the merge result. This is a standing approval for these four PRs only (007b is security-relevant
   CI, normally Ludwig's under §7); it is not a precedent for other PRs.
4. **Platform PR #43 (task 056 architecture note)** — merged, though it had been waiting for his read-through.
Vault refreshed after the merges: written=9, id_conflicts=0.

### For Ludwig (session 10; ★ = manager's lean)
1. **Can a namespace owner remove their own published version?** (007b review round 1, finding F2.) ADR-0041 makes a
   takedown a legal-grounds action by the platform, and `ownership.md` R11 authorises a *pure* takedown PR only from the
   platform identity. But R11 also says a PR that sets `removed` **and** makes any other change "is not a takedown for this
   rule's purposes and is judged in full by the ordinary rules" — under which the owner passes R3. So an owner can remove
   their own published version by bundling it with, say, a new version. 007b implements the contract as written; nothing
   else stops this today.
   - A ★: any PR that sets any version to `removed` is a takedown, whatever else it contains: only the platform identity
     may open it, and mixed PRs are always rejected. Needs a small contract amendment to `ownership.md` R11 (a task,
     reviewed, your approval) and a one-line change in 007b's checker.
   - B: owners may withdraw their own versions (author-initiated removal is a feature). Then ADR-0041's "legal grounds
     only" needs a new ADR, and removal by owners should be allowed *without* the mixed-PR detour.
   - C: keep the contract as written (the loophole stays; document it as a residual).
   Rests on it: task 039 (registry CI going live) must not ship before this is answered; 007b merges either way.
2. **R11 identity** (carried over from session 9, not blocking): which `pulls.user.id` the platform's takedown PRs carry.
   ★B (a dedicated takedown-only account or App that only you control) when 039/008b go live.

### Merges and gates (session 10)
- **066 merged** (registry #14, `198dc98`): review PASS; gate `062-verify.sh` ALL CHECKS PASSED on the merge result.
  **Manager's gap:** that gate ran only 062, which does not run 067; 067 AC5.1 had been red on any later branch, so `main`
  was red on 067 from `198dc98` until 069 fixed it. From then on every merge gate runs **every** closed verify script, one
  at a time, on a quiet machine.
- **069 merged** (registry #15, `2347ffb`): 008a temp-dir race fixed (per-run TMPDIR), 007a and 067 AC5.1 re-pinned to
  their PR ranges, 062 AC6.034 allowance for 064. Review PASS; gate: 007a, 008a, 032, 034, 057, 062, 066, 067, 069 green.
- **007b gate** on its merge result: all green except **067 AC2.4** (`git diff BASE HEAD` on `docs/contracts/README.md`,
  which 007b edits in scope). Same defect class for the fourth time → **task 070**: audit every closed verify script for
  own-change checks measured against HEAD, re-pin them all, plus the ajv default for 067/069. 007b and 064 merge after it.
- Ledger hygiene (move done task files) is renumbered **071**.
- **070 review FAIL** (B1: pinning 062 AC6.* dropped the live "no closed check removed" guard on HEAD). 070 had used its 2-session budget → §8 stop-and-ask. Ludwig, 2026-10-16 (multiple choice, after first declining the prompt and then asking for the options again): **"Extend by 1 fix round"** — one extra session for 070 only; fix round dispatched (live id-superset guards beside the pins, F2/F3, red first).
- **070 merged** (registry #16, `fb76ee5`): delta review PASS; full gate green (007a, 008a, 032, 034, 057, 062, 066, 067, 069, 070). Merging required a rebase of one manager log commit made on a stale worktree base (resolved by taking the remote log and re-appending; no force).
- **007b merged** (registry #12, `70cedca`): review FAIL (F1 recycled-username hijack) → PASS → PASS (N1 owner-field and disagreeing-owners fail-closed); full gate on the merge result green, 007b-verify included. Production `r11_identity = None`. F2 gates 039.
- **064**: review PASS; pre-merge R1 (remove the 008a filter and 007a allowance from 064-verify.sh now that 069/070 landed) sent to its agent.

## SESSION STATUS — 2026-10-16 (session 10), handover at 32 % context (past the 30 % soft threshold)
Token guard: suspended by Ludwig (2026-10-14), not checked.

### Done
- **Platform:** #57 (session 9 status), #58 (task **068** runbook markers M3/M5/M7/Q-H ☑), #43 (task 056 note) merged with
  Ludwig's approval; vault refreshed.
- **Registry merged** (each: independent review PASS, full closed-script gate green on the merge result):
  **066** pinned ajv 8.20.0 in `tools/dev` (#14, `198dc98`); **069** 008a race fixed, 007a/067 AC5.1 pinned, 062 allowance for
  064 (#15, `2347ffb`); **070** audit of all closed verify scripts: own-change checks pinned, live guards kept beside them,
  ajv default everywhere (#16, `fb76ee5`); **007b** ownership checker (#12, `70cedca`) — review found and fixed a real
  recycled-username hijack (F1) and a namespace-reassignment path (N1).
- Specs: 064 (amendment 1: explicit ECMA translation, replacing the manager's `re.ASCII` defect), 065 (revised after spec
  review round 1 FAIL; Ludwig approved its decisions), 066, 068, 069, 070 approved.
- OPERATIONS.md: "What session 10 paid for" (three gotchas).

### In progress
- **064** (registry PR #13): review PASS; R1 done (`e42f5bc`); all closed scripts green **except `007b-verify.sh`** (exit 2),
  whose scope and "007a modules unchanged" checks measure HEAD — 064 legitimately edits `tools/registry/schema.py`.
- **065**: spec ready, independent spec review round 2 pending; dispatch after 064 merges.

### For Ludwig (★ = manager's lean)
1. **Mixed-PR takedown (007b review F2)** — can an owner remove their own published version by bundling it with another
   change? A ★ any `removed` makes the PR a takedown (platform identity only, nothing else in the PR; small contract
   amendment); B owners may withdraw (new ADR); C keep as is (documented residual). Gates task 039.
2. **R11 identity** (carried): ★ a dedicated takedown-only account/App only Ludwig controls; answer when 039/008b go live.
3. **Doctrine proposal (new):** add to REVIEW-CHECKLIST: "the task's verify script measures its own change on its pinned
   range and its live guards on HEAD — checked before merge, because the task becomes closed at merge". A ★ add it (a
   small doctrine task, your approval); B keep it as an OPERATIONS gotcha only. Five instances so far (OPERATIONS.md).

### Next session starts here
1. **Task 071** (new, small, qa-engineer): re-pin `007b-verify.sh`'s scope and "007a modules unchanged" checks to PR #12's
   range (base = merge-base of `70cedca`, final = `70cedca^2`); add 007b to 070-verify's closed list; red first. Then
   **064**: before merging, check 064-verify.sh's own AC5/scope checks for the same class (they are framed against
   `70cedca`..HEAD); decide the pattern for a not-yet-merged task's own-change checks; full gate; merge (standing approval
   covers 064).
2. **065**: spec review round 2 → dispatch (registry, then site re-sync).
3. **072** ledger hygiene (renumbered from 071): true statuses, move done task files to `docs/tasks/done/`, remove merged
   worktrees (`~/wt/registry-task-{066,069,070,007b}`, `~/wt/task-068`).
4. Live checks with Ludwig still open from session 8: 052 AC7, 048 AC9, 049 AC9.

Kickoff line: "Kör din vanliga sessionsstart. Läs SESSION STATUS — 2026-10-16 (session 10) i missionsloggen och fortsätt med 'Next session starts here'."

### Ludwig's answers, 2026-10-17 (verbatim)
1. "I dont think owners should be able to remove their mods, once published that version is published for all future
   since its hosted by my site? Brainstorm on this one, also in relation to my previous decisions in regard of this."
   → Direction: no owner removal. Survey of prior decisions dispatched as task 073; the brainstorm follows in session.
2. "Sounds good. This account should only be able to do take downs with my approval so it cannot go rogue."
   → R11 identity: a dedicated takedown-only account or App that only Ludwig controls, and every takedown it files still
   needs Ludwig's written approval before merge (MANAGER.md §7 already requires this per PR). Recorded for 039/008b.
3. "Ok" → the REVIEW-CHECKLIST item (verify script pins own-change checks, live guards on HEAD, checked before merge) is
   approved; booked as a small doctrine task next session.
4. "Ok to merge." → platform PR #59 merged.

### Removal policy — brainstorm and Ludwig's decision, 2026-10-17
Survey: task 073 (surveyor report, quotes with file:line). Ludwig's answer, verbatim: **"Option A for all"**.
The manager's reading of that answer, per item (Ludwig may correct any line):
0. **Owners cannot remove published versions** (Ludwig, same day) — this is ADR-0041:15 already; `ownership.md` R11's
   "mixed PR is judged by the ordinary rules" contradicts it. Fix: contract amendment — any PR that sets a version to
   `removed` is a takedown (platform identity only, nothing else in the PR) — plus the one-line 007b checker change.
1. **Grounds:** a takedown may be for legal grounds (ADR-0041) **or** known malicious code / illegal content as ADR-0046
   defines them narrowly. Wire ADR-0046 into the takedown mechanism.
2. **Files of a removed version:** stop serving them publicly; keep the registry entry, hash, signature and reason forever.
3. **Already-installed copies:** on its next registry update the launcher warns with the reason; for malware it also offers
   to disable the mod. Never silent deletion (ADR-0037).
4. **Appeals:** a successful appeal means a new version; a removal stays final (no un-remove).
5. **Authors with a broken release:** a per-version "don't use this one" mark (still installable, warned) — later, not now.
6. **Archive protection:** a protection rule on `worldofmodcraft/archive` so Releases cannot be deleted; a manual step for
   Ludwig, with exact clicks written by the manager.
7. **Doctrine housekeeping:** MANAGER.md §7's "legal grounds only" and "the single in-place change" corrected.
Booked for next session: an ADR draft covering 1–4 (and 5 as a recorded intention) for Ludwig's acceptance; the
`ownership.md` R11 amendment + 007b checker change (item 0; gates 039); the runbook step for 6; the §7 doctrine fix (7,
together with the approved REVIEW-CHECKLIST item).

### Next session starts here — addendum (2026-10-17)
Add to session 10's list, after item 1 (071, then 064): **5.** ADR draft "removal policy" (items 1–5 above) for Ludwig's
acceptance; **6.** `ownership.md` R11 amendment + 007b checker change (item 0), merge needs Ludwig (contract, takedown);
**7.** runbook step: protect `worldofmodcraft/archive` Releases (item 6); **8.** doctrine task: MANAGER.md §7 wording
(item 7) + the approved REVIEW-CHECKLIST item. Ludwig's R11 answer (dedicated takedown-only account under his control,
each takedown still needing his written approval) goes into 039/008b's specs.
Kickoff line unchanged: "Kör din vanliga sessionsstart. Läs SESSION STATUS — 2026-10-16 (session 10) i missionsloggen och fortsätt med 'Next session starts here'."

### Ludwig, 2026-10-17: continue in this session (verbatim)
"Fortsätt i den här sessionen, är på resande fot och har inte tillgång till min terminal" — waives the §5 soft handover threshold (30 %) for this session; the 40 % hard threshold stays in force (context 35 % at this point). Agents are asked for short reports to conserve context.

## SESSION STATUS — 2026-10-17 (session 10, continued), handover at ~38 % context (40 % hard limit)
### Done since the 2026-10-16 status
- Ludwig's answers 2026-10-17 recorded; platform #59 and #60 merged. Removal policy decided ("Option A for all").
- **065** spec-approved (spec review round 2 PASS, three fixes folded in).
- **071** merged (registry #17, `825da5e`): 007b-verify's own-change checks pinned to PR #12's range; review PASS; full gate
  (12 scripts) green. This unblocks 064.
- **074 / ADR-0122** drafted (platform PR #61, still the original Proposed draft). Ludwig answered its eight open questions
  ("Stjärna på alla") and **accepted it ("Acceptera", 2026-10-17)**. The acceptance edits under `docs/decisions` (status
  Accepted, index, "Amended by ADR-0122" in ADR-0041's header) were **refused by the permission classifier** ("Modify Shared
  Resources") for the doc-writer; not retried; the manager declined to make the same edits itself (that would launder the
  denial). The folded-in version (eight answers, Options considered, status Proposed) sits **uncommitted** in
  `~/wt/task-074`; `build_index.py --check` fails there until ADR-0041 carries the "Amended by" line.

### Blocked on Ludwig
- **ADR-0122 acceptance edits:** A ★ allow edits under `docs/decisions/` for task 074 (permission rule) and say continue;
  B Ludwig edits himself (manager writes exact steps); C leave Proposed for now (nothing urgent depends on it).

### Next session starts here
1. **064** (registry PR #13): merge `origin/main` (`825da5e`) into the branch; full closed-script gate on the merge result
   (now including 071); merge under the standing approval.
2. **065**: dispatch (registry, then site re-sync) — merge needs Ludwig (signature/key contract).
3. **ADR-0122**: per Ludwig's A/B/C above.
4. `ownership.md` R11 amendment + 007b checker change (removal policy item 0); merge needs Ludwig; gates 039.
5. Runbook step: protect `worldofmodcraft/archive` Releases (item 6). Doctrine task: MANAGER §7 wording + approved
   REVIEW-CHECKLIST item (doctrine edits may hit the same classifier wall — plan for Ludwig doing or allowing them).
6. 072 ledger hygiene (statuses, `docs/tasks/done/`, remove merged worktrees incl. registry-task-{066,069,070,007b,071},
   task-068); 070-verify header still says "ten closed scripts" (cosmetic).
7. Live checks with Ludwig: 052 AC7, 048 AC9, 049 AC9.
Kickoff line: "Kör din vanliga sessionsstart. Läs SESSION STATUS — 2026-10-17 (session 10, continued) i missionsloggen och fortsätt med 'Next session starts here'."

### Ludwig, 2026-10-18 (verbatim): "1. OK att merga 62. 2. Kör Stjärna för ADR-0122"
→ #62 merged. ADR-0122: option **A** (★) — a narrow permission rule allowing edits under `docs/decisions/` for task 074, then the doc-writer finishes the acceptance edits (status Accepted, index, "Amended by ADR-0122" in ADR-0041) and PR #61 merges. Deferred to the start of the next session (manager at the 40 % hard context limit; permission changes done with full context). **Next session: this is item 0, before 064.** Ludwig's instruction is the authorisation; the rule is scoped to `docs/decisions/**` and recorded in this log.

## Session 11 — 2026-10-18
Token guard: suspended by Ludwig (2026-10-14), not checked. Context at start: 5 % (HUD cache).
- **Item 0 (ADR-0122, option A):** the manager tried to write the narrow allow rule
  (`Edit(//home/ludwig/wt/task-074/docs/decisions/**)` and the matching `Write(...)`) into `~/wom/.claude/settings.local.json`
  (git-ignored, local only). **Refused by the auto-mode classifier ("Self-Modification").** Not retried by any other means:
  a permission rule the classifier will not let the manager grant itself is Ludwig's to add. Exact steps go to Ludwig
  under "For Ludwig" at session end. ADR-0122 stays Proposed until then; nothing urgent depends on it.
- **Item 1 (064):** implementer dispatched (log baseline 14): pin 064-verify.sh's own-change checks to the task's own
  range before merge, merge `origin/main` into the branch, full closed-script gate, push. Merge by the manager afterwards
  under the standing approval.
- **075** (R11 amendment + 007b checker, removal policy item 0): spec written; independent spec review round 1 FAIL
  (3 blocking, 2 minor: incomplete contract-passage list, under-specified detection, 032 T16/T17 pins), all folded in;
  round 2 PASS; **spec-approved**. Dispatch after 064 merges (base must contain 064). Merge needs Ludwig.
- **077** (runbook M8, archive protection, removal policy item 6): doc-writer, platform PR #63. Facts verified on
  docs.github.com: tag rulesets ("Restrict deletions/updates") and "Enable release immutability" exist; **no GitHub
  setting prevents deleting a Release** — M8 says so and names tag + file protection as the closest. Manager measured
  (unauthenticated API): `archive` is public with 0 releases. Review round 1 FAIL (3 minor), fixed in `cc4da92`, delta
  review PASS. Open: rulesets documented "for GitHub Team and Enterprise" only — Free/public marked [unverified]; M8
  tells Ludwig to stop if the menu is missing. Task 076 is reserved for the doctrine task (§7 wording + approved
  REVIEW-CHECKLIST item), to be specified after ADR-0122 is accepted (its grounds wording depends on it).
- **064**: implementer re-pinned 064-verify.sh's own-change checks (AC5.1-5.6, S1-S3) to MAINB..FINAL
  (FINAL `69f74a1`, re-pin `e288c43`, red shown first), merged `origin/main` (`1f99708`, no conflicts), tip `5002b46`.
  Delta review PASS; serial gate on a quiet machine: all 14 closed scripts exit 0 (064-verify ~40 min). Observed: 062/067
  redden when two verify runs overlap — the known shared-suite class (task 043); serial runs are green.
- **Merge of registry PR #13 refused by the auto-mode classifier ("Merge Without Review").** Not retried. Second
  stop-and-ask in a row → session halts per MANAGER.md §8 until Ludwig answers.

## SESSION STATUS — 2026-10-19 (session 11), halted on two classifier refusals (§8), context ~12 %
### Done
- 075 spec-approved (two independent spec-review rounds); 077 PR #63 reviewed PASS (not merged); 064 ready (review
  PASS, gate green on `5002b46`).
### For Ludwig (★ = manager's lean)
1. **ADR-0122 permission rule** (your option A, 2026-10-18) — the classifier will not let the manager grant it.
   ★A you add it: in the Claude Code prompt type `/permissions`, choose "Allow", add the rule
   `Edit(//home/ludwig/wt/task-074/docs/decisions/**)` and save it to "Project settings (local)"; then say "fortsätt".
   B you make the three edits yourself (manager writes the steps). C leave ADR-0122 Proposed.
2. **Registry PR #13 (task 064)** — reviewed and green, merge refused by the classifier. ★A you click "Merge pull
   request" at https://github.com/worldofmodcraft/registry/pull/13 (keeps the human gate visible to the classifier);
   B write "OK att merga #13" and the manager tries once more with the plain merge command. 075 waits on this.
3. **Platform PR #63 (task 077, runbook M8)** — reviewed PASS. A ★ "OK att merga 63"; B changes first.
4. **Fact question for M8:** GitHub documents rulesets "for GitHub Team and GitHub Enterprise". Which plan is the org
   on? See https://github.com/organizations/worldofmodcraft/settings/billing — the plan name is at the top.
### Next session starts here
1. After answer 2: 064 merged → cut 075 from registry main, dispatch implementer; merge needs Ludwig.
2. After answer 1: doc-writer finishes ADR-0122 acceptance edits in `~/wt/task-074`; PR #61 merge (Ludwig).
3. Then 076 doctrine task (§7 wording per ADR-0122 + approved REVIEW-CHECKLIST item); 072 ledger hygiene;
   live checks 052 AC7, 048 AC9, 049 AC9.
Kickoff line: "Kör din vanliga sessionsstart. Läs SESSION STATUS — 2026-10-19 (session 11) i missionsloggen och fortsätt med 'Next session starts here'."

### Ludwig, 2026-10-25 (verbatim): "merge"
Read by the manager as approval for the three PRs listed under "For Ludwig" items 2-3 (registry #13, platform #63, #64);
not as an answer to item 1 (the ADR-0122 permission rule, still open) or item 4 (org plan, still open).
→ registry #13 (064) merged at reviewed head `5002b46` → `79d5377`; platform #63 (077) merged at `cc4da92` → `2562f88`;
#64 merged after this entry. The §8 halt is lifted by the answer; 075 is unblocked (base = registry main `79d5377`).
- **Session worktree pin (2026-10-25):** after the manager entered the session worktree (EnterWorktree), the isolation
  guard pinned the session and its agents to it; 075's first implementer stopped before writing code (it could not run
  registry verify scripts from the registry worktree root) and did not work around the guard. Ludwig: "lämna worktree"
  → the manager left it (kept on disk); 075 relaunched. Lesson for OPERATIONS.md: the manager should not EnterWorktree
  when agents must work in other repositories' worktrees; session-log edits go in a manually created worktree instead.
- **075 (registry PR #18):** implementer: red `45c5be9` (17 tests red), fix `067a45d`. Independent review: owner removal
  impossible in every probed PR shape; platform-only removals still authorised; CONDITIONAL PASS, one blocking finding
  (the unreadable-entry R11 message falsely claimed a takedown). Fix: red `49a64f3`, fix `4509f57`, log `7d91a3d`; fresh
  delta review PASS. All 15 closed scripts exit 0 (064 run without timeout), 273 tests OK. The author's two booked
  questions answered by the manager from the spec (a strengthened assertion; fail-closed R11 for unreadable entries).
  Ludwig 2026-10-25: "ok att merga" → **merged `4356583`**.
- **ADR-0122 (task 074):** Ludwig could not add a permission rule from the mobile app (`/permissions` shows only the mode
  picker); he switched the session to Manual mode and approved each edit himself. Doc-writer: status Accepted
  (2026-10-17, by Ludwig), ADR-0041 "Amended by" line, README/INDEX.json regenerated, `build_index.py --check` OK
  (`3405ab7`, merge `f905136`). Ludwig: "Ok att merge 61" → **platform PR #61 merged `0aac566`. ADR-0122 is Accepted.**

## SESSION STATUS — 2026-10-25 (session 11, end)
### Done this session
064 (#13), 077 runbook M8 (#63), 075 owner-removal fix (registry #18), ADR-0122 Accepted (#61), session logs (#64, this PR).
### For Ludwig (★ = manager's lean)
1. **Org plan (for M8):** GitHub documents rulesets "for GitHub Team and GitHub Enterprise". Which plan is the org on?
   https://github.com/organizations/worldofmodcraft/settings/billing — the plan name is at the top. Then do M8 in the
   runbook (`docs/runbooks/site-v1-manual-steps.md`); stop and tell the manager if the Rulesets menu is missing.
2. Switch the session back to Auto (`/permissions` → "Auto").
### Next session starts here
1. **076** doctrine task: MANAGER.md §7 wording per ADR-0122 (grounds: legal + ADR-0046 malware/illegal content; "the
   single in-place change" corrected) + the approved REVIEW-CHECKLIST item (verify scripts pin own-change checks, live
   guards on HEAD, checked before merge). Doctrine edits may need Manual mode (classifier wall).
2. ADR-0122 follow-ups: specs for launcher warning on removed versions (item 3) and stopping public serving of removed
   files (item 2), as the mission graph allows. R11 identity (dedicated takedown-only account, each takedown needing
   Ludwig's written approval) goes into 039/008b's specs; 039 is now unblocked by 075.
3. 072 ledger hygiene: statuses, `docs/tasks/done/`, remove merged worktrees (registry-task-{064,066,069,070,071,007b,075},
   task-068, task-074, task-077, `.claude/worktrees/session-11`, session-11b after merge).
4. OPERATIONS.md gotchas: the EnterWorktree pin (above); verify scripts must run from the repo root and one at a time;
   a fresh registry worktree has no `tools/dev/node_modules` (062 needs WOM_NODE_MODULES or `npm ci`).
5. Live checks with Ludwig: 052 AC7, 048 AC9, 049 AC9.
Kickoff line: "Kör din vanliga sessionsstart. Läs SESSION STATUS — 2026-10-25 (session 11, end) i missionsloggen och fortsätt med 'Next session starts here'."

### Session 11 continued — 2026-10-25 (Ludwig: "Fortsätt i den här sessionen")
- **076** (doctrine, platform PR #66): §7 takedown wording per ADR-0122 (grounds; T2 is one of three permitted in-place
  mutations T1/T2/T3; owners cannot remove, enforced by R11) + REVIEW-CHECKLIST item 12 (verify-script pinning). Not
  refused by the classifier. Its AC4 was blocked by three closed scripts already red on main → task 078 first. Review
  PASS. Ludwig: "Ok merga 66" → **merged `bf4710d`**.
- **078** (platform PR #67): 048 c1 pinned to PR #50's range, 063 to PR #55's; 056-verify's planted minisign header text
  built at runtime (051's secret scan hit was **not a secret** — manager checked with masked output). Q2 (070-verify is
  registry-only) was the manager's spec defect; 078-verify carries the later-branch checks instead. Review PASS (049 red
  only on stale ignored `__pycache__`; cleared, 049 exit 0). Ludwig: "Go wit star" → **merged `8004828`**.
- **Ludwig 2026-10-25:** answer 2 "Go with star" (live guard on rule 0) → task 079; answer 3 "i have GitHub pro", then
  "Worldofmodcraft is on a free plan" — the org is on **GitHub Free**. Docs (fetched 2026-10-25) name rulesets only for
  Team/Enterprise and say nothing about public repos; unverified — Ludwig checks
  https://github.com/worldofmodcraft/archive/settings/rules for a "New ruleset" button before doing M8.
- **079** (platform PR #68): `docs/manager/rule0.reference.md` + `tools/manager/check-rule0.sh` (byte-exact, 0/1/2,
  never skip); 11 mutations as specified. Review PASS incl. merged-with-main clone. Ludwig: "Ok att merga 68" →
  **merged `29b3424`**.
- **080** (platform PR #69): 079's review found 056/076/078 verify red in **every fresh clone** — the architecture note
  cited ADR-0121 on a local-only branch. Cite moved to the main path; fresh-clone runs green after, red before. Review
  pending.
- Gotchas for OPERATIONS.md (booked, 072/hygiene): stale ignored `__pycache__` reddens 049 (run with
  PYTHONDONTWRITEBYTECODE=1); add/add conflicts on task files between session branch and task PR — main's copy is the
  superset; verify scripts must be checked in a fresh clone (item 8), not only in worktrees.
- Booked, non-blocking: 048 c3 asserts exactly 10 agent files (reddens on an 11th); 056 has no later-branch case in 078.
- **080** update: review PASS, then an item-12 finding (own-change check read HEAD) fixed in `a36b758` (pins BASE `29b3424`, FINAL `f173739`; control FINAL=BASE exits 1); delta review PASS; PR #69 head `fe050ab` awaits Ludwig's OK.
- Ludwig: "Ok att merga 69 70" → **080 merged `9a73990`**, session log **#70 merged `d9d48de`**.
- **072** (ledger hygiene, platform PR #71): 34 task files set to `done` with a named merge each; 13 left (no merge
  evidence: 007, 008, 008b, 008c, 010, 031, 039, 040, 043, 047, 055, 058, 065); **041 uncertain** (merged as site PR #2,
  outside the evidence rules). OPERATIONS.md "What session 11 paid for" (a)-(g). 16 merged worktrees removed (three
  checks each, no --force, no branch deleted); kept: task-023, task-058 (unmerged), session-10, session-9-specs,
  session-11b, task-072. Review pending at handover.

## SESSION STATUS — 2026-10-25 (session 11, final), handover at ~25 % context
### Done this session (all reviewed; merges with Ludwig's written OK where §7 requires it)
064 (registry #13), 075 owner-removal fix (registry #18), 077 runbook M8 (#63), ADR-0122 Accepted (#61), 076 doctrine
§7 + REVIEW-CHECKLIST item 12 (#66), 078 closed-verify repins (#67), 079 rule-0 live guard (#68), 080 fresh-clone cite
fix (#69), session logs (#64, #65, #70).
### In progress
- **072** (PR #71): independent review running at handover; merge needs Ludwig's OK (ledger + OPERATIONS.md).
### For Ludwig (★ = manager's lean)
1. **Move finished task files to `docs/tasks/done/`?** Verify scripts cite task files by path. A ★ leave them in place
   (the status line is the truth); B move them and update every citing script (a larger task).
2. **M8 (archive protection):** org is on GitHub Free; rulesets availability on Free/public is unverified. Open
   https://github.com/worldofmodcraft/archive/settings/rules — if a "New ruleset" button exists, follow M8 in
   `docs/runbooks/site-v1-manual-steps.md`; if not, tell the manager.
3. **PR #71 (072):** OK to merge once its review is PASS.
### Next session starts here
1. 072: review result → merge with Ludwig's OK (resolve the expected add/add conflict on the session branch: main's copy
   is the superset). Remove `~/wt/task-072` and `~/wt/session-11b` after their merges (three checks, no --force).
2. 041's status: check site PR #2 and correct it (or leave with the reason).
3. ADR-0122 follow-up specs: stop public serving of removed files (item 2), launcher warning on removed versions
   (item 3); 039 (registry CI workflow) is unblocked by 075 — its spec gets Ludwig's R11 identity answer (dedicated
   takedown-only account under his control; each takedown still needs his written approval).
4. Booked, small: 048 c3 hard-codes 10 agent files; 056 lacks a later-branch case in 078; 043's rule never reached
   MANAGER.md (decide: finish or stop 043).
5. Live checks with Ludwig: 052 AC7, 048 AC9, 049 AC9.
Kickoff line: "Kör din vanliga sessionsstart. Läs SESSION STATUS — 2026-10-25 (session 11, final) i missionsloggen och fortsätt med 'Next session starts here'."
