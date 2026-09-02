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
| Task | State | Agent | Blocked by |
|---|---|---|---|
| 001 index completeness | review (awaiting merge approval) | manager | Ludwig §7 |
| 002 asset scanner | draft | implementer/sonnet | **M1** |
| 003 INDEX.json generator | **in progress** | implementer/sonnet | — |
| 004 `Touches:` tagging of 116 ADRs | draft | scaffolder/haiku | 003 |
| 005 ADR-0119 + amend metadata | review (awaiting merge approval) | manager | Ludwig §7 |
| 006 contracts (entry/page/manifest schemas) | not written | implementer/sonnet | M1 |
| 007 registry CI gates | not written | implementer/sonnet | 006 |
| 008 pipeline + archive + signing | not written | implementer/sonnet | 006, M3 |
| 009 site build + design | not written | implementer/sonnet | 006 |
| 010 test mod + first-publish runbook | not written | implementer + doc-writer | M4, 007–009 |
| 011 hardware-key 2FA upgrade | booked | Ludwig | before first real publish |

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
