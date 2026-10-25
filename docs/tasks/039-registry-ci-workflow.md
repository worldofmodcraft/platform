# Task 039: The registry CI workflow — the 007a and 007b checkers wired onto real pull requests

- **Mission:** SITE-V1, deliverable **D1** (the CI half); mission §7 criterion 1 (registry half). **Status:** draft, revised
  (manager, 2026-10-25; replaces the 2026-09-06 placeholder). **Security-touching → independent spec review before dispatch.**
- **Merge:** needs **Ludwig's written approval** (CI security check, MANAGER.md §7).
- **Repo:** registry; plus one docs-only change in the platform repo (runbook M9/M10, see File scope).
- **Agent / model:** implementer (ROUTING.md). **Budget:** medium (≤ 3 agent-sessions).
- **Branch / worktree:** `task/039-registry-ci-workflow` / `~/wt/registry-task-039`, cut from registry `origin/main`
  (`4356583` on 2026-10-25, or later; the actual cut SHA is `BASE` in the log and in `039-verify.sh`). Platform docs:
  `task/039-runbook-m9` / `~/wt/task-039-runbook`.
- **Graph:** completes node **N3 `registry-ci`**; realises edge **E16** (`author (forge identity) → N3`, read per
  `ownership.md` I1). No new edges. [unverified] the R11 configuration file is an input to N3, not a new node — the manager
  confirms against `docs/architecture/depgraph.md` before approval.

## What changed since the 2026-09-06 draft
- "Task 007" now means **007a** (shape checkers: `tools/registry/cli.py classify|schema|append-only`, registry PR #10) **and**
  **007b** (ownership: `tools/registry/ownership_cli.py`, PR #12, `70cedca`), both merged. Task **075** (R11: any PR containing
  a removal is a takedown; mixed PRs rejected whoever opened them; PR #18, `4356583`) is merged — resolving the 2026-10-15
  "blocked by the mixed-PR takedown question" note.
- **R11 identity** (Ludwig, 2026-10-17): a dedicated takedown-only account or App that only Ludwig controls; every takedown it
  files still needs his written approval before merge (MANAGER.md §7, `ownership.md` I8). That identity does not exist yet.
  This task ships R11 **unconfigured**: per `ownership.md` R11 ("until it is configured, R11 authorises nobody") every takedown
  PR is rejected. **That is the intended, acceptable state for this task.**
- No `.github/workflows/` exists on registry `main` (checked 2026-10-25); the registry has no `mods/` entries yet.

## Objective
Every pull request to `worldofmodcraft/registry` gets one required status check, **`gate`**, computed **only by code from the
base branch**, never by code from the PR. It is red when any of the four checkers (classify, schema, append-only, ownership)
rejects, and red when any step cannot decide; the author sees why in a PR comment. The verdict uses the PR author's numeric
id from the PR object (`pulls.user.id`) and reads every authority input — the reserved list, existing namespaces' owners, the
R11 identity — at the PR's merge-base. The mission §7 criterion-1 registry rejections (invalid schema, wrong account for an
existing namespace, modified version object) are demonstrated offline against recorded PR shapes. `CONTRIBUTING.md` documents
the manual publish flow with the ADR-0058 §3 namespace-permanence notice.

## Context to load (reading list, 10)
1. `contracts/ownership.md`: I1 (identity source), I4 (merge-base reads), I5/R9 (membership: no redirect following; anything
   but 204/404 rejected closed), R11 + "The mechanism, marked rather than assumed" + I8.
2. `contracts/append-only.rules.md`: T1/T2/T3 and "Coexistence" (fail-closed).
3. `tools/registry/cli.py`; 4. `tools/registry/ownership_cli.py`; 5. `tools/registry/report.py` (exit codes 0/1/2; 2 is
   **not** a rejection).
6. `docs/decisions/0058-publishing-flow.md` §2, §3 (confirmation text verbatim), §5.
7. `docs/decisions/0059-mod-pages-and-page-content.md` §3. 8. `docs/decisions/0119-reserved-namespaces.md` §3-4.
9. Platform `docs/tasks/008b-pipeline-workflow.md`, design 1 and 8 only (the seam: push-triggered pipeline, job split).
10. This file.
ADRs the diff may touch (ADR-0116 layer 2): 0039, 0041, 0058, 0059, 0099, 0119, 0121, 0122.

## Approach (decided here; the implementer raises a Question before deviating)

### 1. Trust model
- **Trigger:** `on: pull_request_target`, `types: [opened, synchronize, reopened, edited]`, branches `[main]`. No other trigger.
  Not `pull_request`: fork PRs get no secrets and a read-only token, so the membership question (R9) could not be asked and no
  comment posted. `pull_request_target` is safe here because GitHub runs the workflow file and the checkout from the **base
  branch**, so a PR cannot change the workflow, the checkers or the config that judge it. **The rule that keeps it safe:
  nothing from the PR head is ever executed, imported, installed or sourced** — the PR's files are data (JSON read by
  base-branch checkers from a separate directory). [unverified U1]
- M1.4's "require approval for first-time contributors" gates `pull_request` fork runs, **not** `pull_request_target`
  [unverified U1]; safety rests on "PR content is data only", not on that setting.
- **Tokens:** M1.4 set the repository default to read and write, so the workflow declares top-level `permissions: {}` and each
  job its minimum. Job **`gate`** (the required check): `contents: read`, `pull-requests: read`; one secret, in one step only
  (membership, §4); produces `verdict.json` + `comment.md` as an artifact. Job **`comment`** (`needs: gate`, `if: always()`):
  `pull-requests: write` only, **no checkout**, runs no repository code; downloads the artifact and posts `comment.md` as data
  (`gh api … -F body=@comment.md`, [unverified U8]); with no artifact it posts a fixed "registry CI could not decide; see the
  run log". Its result never changes `gate`.
- **Checkout:** `actions/checkout` pinned to a 40-hex SHA, `fetch-depth: 0`, `persist-credentials: false`, **no `ref:`**. The PR
  head is fetched as objects only (`git fetch origin +refs/pull/<N>/head:refs/wom/pr-head`); the fetched SHA must equal the
  event's `pull_request.head.sha` or the run exits 2. [unverified U5]
- **No `${{ github.event.* }}` or `${{ github.head_ref }}` inside any `run:`** (script injection); event data reaches scripts as
  files (`$GITHUB_EVENT_PATH`) or env vars.

### 2. The composer: `tools/registry/ci_gate.py` (new, offline, stdlib only)
`python3 -I tools/registry/ci_gate.py --repo DIR --event EVENT.json --pr PR.json --membership-status (INT|none) --out DIR`
→ exit 0 accepted / 1 rejected / 2 could not decide; writes `OUT/verdict.json`, `OUT/comment.md`, `OUT/class`.
1. **Identity (I1):** author = `PR.json.user.id` / `.user.login`; `PR.json` is the `GET /repos/{repo}/pulls/{n}` response the
   workflow fetched with the read-only token. Exit 2 unless event and API object agree on number, `user.id`, `head.sha`,
   `base.ref == "main"` and base repository. Never reads `GITHUB_ACTOR(_ID)`, commit authors or trailers.
2. **Merge-base:** `git merge-base --all <base.sha> <head.sha>`; exactly one result, else exit 2.
3. **Changed paths:** `git diff --no-renames --name-only -z <mb> <head>` (a rename is a deletion plus a creation, per 007a).
4. **Routing (no workflow path filter):** a non-empty diff with **no path under `mods/`** is an *infra PR*: exit 0, comment
   "not a registry content PR; registry CI does not judge it; human review required (MANAGER.md §7)". Every other PR —
   including an empty diff and any mix of `mods/` with other paths — goes through the full gate (classify rejects mixes as
   `other`). Reasons: a `paths:` filter would leave the required check pending on skipped PRs [unverified U3]; 007a rejects
   every path outside `mods/` by design and its Questions(A) left routing to this task.
5. **Materialisation (no checkout of PR trees):** via `git ls-tree -r -z` + `git cat-file blob`, write **old-root** = the
   merge-base tree's `mods/`, `reserved-namespaces.json` and `config/r11-identity.json`, and **new-root** = the head tree's
   `mods/`, into fresh temp dirs. Mode 100644/100755 → regular file; 120000 → a symlink with its literal target, never
   followed (the checkers reject it as `symlink`); any other mode (gitlink 160000, …) on a changed path → rejection (fail
   closed).
6. **Run all four checkers, always, from the base checkout** (`sys.executable -I tools/registry/…`): `cli.py classify
   --reserved-file OLD/reserved-namespaces.json`; `cli.py schema --root NEW`; `cli.py append-only --old-root OLD --new-root
   NEW`; `ownership_cli.py --author-provider github --author-id ID --author-login LOGIN --old-root OLD --new-root NEW
   --reserved-file OLD/reserved-namespaces.json [--membership-status N] [--r11-identity github:ID]`. All four run even after a
   rejection, so the author gets the full log.
7. **Composition (fail closed):** accepted iff all four exit 0 **and** each JSON verdict says `accepted`. A checker exit 2, any
   other exit code, unparsable JSON, or an exit code disagreeing with its verdict → composed exit 2, reported as "could not
   decide (not a rejection)", never green. The ownership verdict's `merge_signal: false` (I8) is restated: green means "the
   checks pass", never "approved".
8. **R11 identity:** read from `OLD/config/r11-identity.json` (merge-base, I4), never from the PR head or an env var. File:
   `{"schema_version": "1.0.0", "r11_identity": null}` or `{"provider": "github", "id": <int>}` in that slot. `null` or absent
   → no `--r11-identity` (R11 authorises nobody); malformed → exit 2. **This task commits it as `null` and forbids setting it.**
9. **Comment:** on rejection or exit 2, the full checker output inside a code fence longer than any backtick run in it (it
   contains PR-controlled strings), truncated below GitHub's limit [unverified U12] with a link to the run log. On a PR that
   first publishes a non-reserved namespace, ADR-0058 §3 verbatim: *"This creates the namespace `X:` permanently bound to your
   GitHub account (id N). Namespaces are never reassigned."* (X = namespace, N = `pulls.user.id`). For a reserved-namespace
   first publish it says instead that the namespace is bound to the organisation in the merge-base reserved list (ADR-0119).
   Page-only PRs: "page.json-only: no build runs" (`OUT/class` = `page-only`).
10. **Process discipline:** `subprocess` only with argv[0] `git` or `sys.executable`; no network modules; no environment reads
    beyond what the arguments name.

### 3. page.json-only PRs skip the build
008b's pipeline triggers on `push` to `main` with `paths: ['mods/*/entry.json']` (008b design 1), so a page-only merge starts no
build without wiring here. This task exposes the class (`OUT/class`, job output, comment) and tests it; it does not edit 008b.
**Merge stays a human action in v1** (C8). The screenshot scan ADR-0059 §3 requires is **task 040** (extends `ci_gate.py`).

### 4. Membership oracle (R9/I5)
- Asked only when the class is `reserved-namespace` (a first `--classify-only` pass of the same script), or always with the
  answer ignored otherwise — the implementer picks one, records it, tests it.
- The org is the single organisation named by every merge-base reserved entry; more than one → exit 2. The step validates the
  login against `^[A-Za-z0-9](-?[A-Za-z0-9]){0,38}$`, calls `GET /orgs/{org}/members/{login}` with `curl` **without `-L`**,
  and outputs only the integer status.
- **Credential:** a separate org App with only *Organization → Members: read* (C5), stored as a secret visible to that step only,
  booked as runbook **M10**. **`PIPELINE_APP_PRIVATE_KEY` is never used here.** Until M10, no secret → status `none` → every
  reserved-namespace PR is rejected by R9: accepted for this merge; must be lifted before task 010 (`test:hello-world`).
  [unverified U6]

### 5. Required status check (Ludwig's manual step)
Branch protection changes only by Ludwig, by hand: runbook **M9** (platform repo): registry → Settings → Branches → rule for
`main` → *Require status checks to pass* → select `gate` → *Require branches to be up to date before merging* → Save, plus what
he should see. Only possible **after** the first live run (the check appears in the selector once it has run) [unverified U2].
Org on GitHub Free, repo public [unverified U10; the M9 screen confirms]. Existing protection unchanged; infra PRs stay
mergeable (infra route is green).

### 6. CONTRIBUTING.md
Manual-PR publish flow: fork, `mods/<ns>.<name>/entry.json` (+ `page.json`), namespace = your username (R4), owner = your numeric
id (R5/R6), append-only versions, page-only edits, owners cannot remove a published version (ADR-0122, R11); the ADR-0058 §3
notice verbatim. README's "CONTRIBUTING.md will document…" line updated.

## Acceptance criteria — all run by `docs/tasks/039-verify.sh`; the log pastes its output
**Permitted demonstration mechanism:** offline simulation only — throwaway git repos in `mktemp` dirs (base commit = fixture
registry state, head commit = fixture PR) plus **recorded event and PR-object payloads** committed under
`tests/registry/fixtures/ci/`, trimmed to the documented shapes [unverified U4]; everything under `env -i PATH="$PATH"
HOME="$(mktemp -d)" LANG=C.UTF-8`. **No credential of any kind, no `gh` call, no `curl`, no `act`, no live PR.**
1. **§7 criterion 1, registry trio — each exit 1 with the named rule in `comment.md`:** (a) `entry.json` with `owner.id` as a
   string (schema); (b) a new version on a namespace owned by `github:100200300`, opened by `github:900800700` whose **login
   equals** the owner's `name_at_registration` (R3 — ids, not usernames); (c) an existing version's `commit` changed by its own
   owner (append-only rule 1).
2. **Positive controls (exit 0):** first publish of `alice:demo` by `alice` (comment contains the ADR-0058 §3 sentence with
   `alice:` and alice's id, byte-exact); the owner adding a version; the owner's page-only PR (class `page-only`, "no build
   runs"); an infra PR touching only `README.md`. A suite that rejects everything fails this criterion.
3. **Fail-closed matrix (each exit 2, never 0, never reported as a plain rejection):** event/API disagree on `user.id`; on
   `head.sha`; `PR.json` missing or unparsable; no merge-base; two merge-bases; a checker exiting 2; a stub checker exiting 3
   and one printing non-JSON (test-only `--tools-dir`, asserted unused in the workflow); malformed `config/r11-identity.json`;
   a reserved list naming two organisations.
4. **Identity source:** with `GITHUB_ACTOR`/`GITHUB_ACTOR_ID` set to the owner and the head commit's author/committer set to the
   owner, a stranger's PR is still rejected R3.
5. **Merge-base reads:** a PR removing `test` from `reserved-namespaces.json` and adding `mods/test.x/entry.json` is still judged
   reserved (and rejected); a takedown-only PR by any author with R11 unconfigured → rejected "R11 is not configured"; with a
   **test-only** merge-base config naming `github:555`, a takedown-only PR by 555 passes ownership, the same PR plus another
   change is rejected (R11, 075); a PR setting the config to its own author in the same diff gains nothing. Membership:
   `none`, `302`, `500` → R9 rejection; `204` passes R7; `404` → R7 rejection.
6. **Tree handling:** an `entry.json` rename → rejected as deletion; a symlinked `entry.json` → `symlink`; a gitlink under
   `mods/` → rejected; a path containing a newline handled via `-z` without crashing.
7. **Workflow structure — a live guard on HEAD.** PyYAML parses `.github/workflows/registry-ci.yml` (missing PyYAML → exit 2,
   never skip). Asserts: triggers exactly `pull_request_target` with the four types, no `paths`/`paths-ignore`; top-level
   `permissions: {}`; `gate` exactly `contents: read, pull-requests: read`; `comment` exactly `pull-requests: write`, no
   `actions/checkout`, no step running repository code; `secrets.` only in the membership step; `PIPELINE_APP_PRIVATE_KEY` and
   `MINISIGN_SECRET_KEY` nowhere; no `run:` with `${{ github.event` or `${{ github.head_ref`; every `uses:` pinned to 40 hex;
   checkout `persist-credentials: false` and no `ref:`; no `continue-on-error`, `|| true` or `set +e` in `gate`; the membership
   `curl` has no `-L`/`--location`. **Fails on zero matches** (must find `gate` and its `ci_gate.py` step). **Mutations**, each
   red then restored byte-identically: add a `pull_request` trigger; `gate` permissions `write-all`; checkout `ref: ${{
   github.event.pull_request.head.sha }}`; `${{ github.event.pull_request.title }}` in a `run:`; `-L`; `continue-on-error:
   true`; unpin one `uses:`; a `paths:` filter. Positive control: the unmodified file passes.
8. **No network, no credential in the composer:** an AST scan of `ci_gate.py` finds no import of `socket`, `urllib`, `http`,
   `ssl`, `requests`; every `subprocess` argv[0] is literal `"git"` or `sys.executable`. Mutation: `import urllib.request` → red.
9. **Production R11 unconfigured:** `config/r11-identity.json` at `FINAL` parses with `"r11_identity": null`.
10. **Docs:** `CONTRIBUTING.md` contains the ADR-0058 §3 sentence verbatim (placeholders explained) and "never reassigned";
    `README.md` no longer says CONTRIBUTING "will" exist.
11. **Own-change checks pinned (REVIEW-CHECKLIST item 12):** `BASE` and `FINAL` recorded in the script; `git diff --name-only
    BASE FINAL` inside the file scope; the red-first commit (tests for AC1-AC6 + AC8, before `ci_gate.py`) is an ancestor of
    the implementation commit and its tests fail at that commit (in a `mktemp` worktree). Control: `FINAL=BASE` → exit 1.
12. **Live guards on HEAD:** the full registry test suite green; every closed verify script on the closed list (070/075 list +
    075) green, one at a time from the repo root; the script passes in a **fresh clone** from GitHub (REVIEW-CHECKLIST item 8).

**Post-merge live checks (observed by Ludwig/manager; not merge-gating; logged):** L1 an infra PR shows `gate` green and the run
log prints `python3 --version` and the non-secret PR fields (closes U2, U4, U5, U7); L2 Ludwig does M9; L3 an invalid-schema PR
from `womcraft` in namespace `womcraft` is red with the comment, then closed unmerged; L4 M9 blocks merging L3. R3 and
append-only live demos need entries on `main` and a second account (M6) → the mission §7 walkthrough.

## File scope
Registry: `.github/workflows/registry-ci.yml` (new), `tools/registry/ci_gate.py` (new), `config/r11-identity.json` (new,
`null`), `CONTRIBUTING.md` (new, docs), `README.md` (one paragraph), `tests/registry/test_ci_gate.py`,
`tests/registry/test_ci_workflow.py`, `tests/registry/fixtures/ci/**`, `docs/tasks/039-registry-ci-workflow.md` (carried with
its log), `docs/tasks/039-verify.sh`.
Platform (`task/039-runbook-m9`, docs only; the reviewer reads it): `docs/runbooks/site-v1-manual-steps.md` — new **M9**
(required check), **M10** (membership-read App), and a ⏸ note on the R11 takedown-only identity awaiting its own task.

## Size (SPEC-CHECKLIST 5b)
Source files 3 (workflow, composer, config); reading list 10. **Changed lines estimated 330-400 (over 300).** Justification: the
risk is the seam between the YAML and the composer (which input comes from the event, the API, the merge-base; which job holds
which token). Split, the composer's input contract would be reviewed without its only caller and the workflow without the code
it trusts — `pull_request_target` defects live in that gap; AC7 and AC1-AC6 mean something only together (C7). Diff over 450
lines → stop and report; the manager splits.

## Forbidden (beyond MANAGER.md §3.7)
- Any trigger but `pull_request_target`; any `paths` filter; `workflow_run`; auto-merge of any PR.
- Checking out, executing, importing, installing or sourcing anything from the PR head; `actions/checkout` with a head `ref`.
- `${{ github.event.* }}` / `${{ github.head_ref }}` inside `run:`.
- Identity from anything but the API PR object cross-checked with the event (I1); `GITHUB_ACTOR(_ID)`, commit metadata.
- Reading the reserved list, owners or R11 config from the PR head or base tip instead of the merge-base (I4).
- `r11_identity` other than `null` in a committed file; any `pipeline_app_id` carve-out (008b's amendment).
- `continue-on-error`, `|| true`, exit 2 treated as green, skipping later checkers after an earlier rejection.
- Following redirects in the membership call, or reading 302 as 404 (I5/R9).
- `PIPELINE_APP_PRIVATE_KEY` or `MINISIGN_SECRET_KEY` in this workflow.
- Editing `tools/registry/{cli,ownership_cli,ownership,append_only,schema,classify,report}.py` or any `contracts/*` — if one
  seems needed, stop and report (a contract task with Ludwig's approval).
- **Any credential use by the implementer:** no `gh auth`, `gh api`, `gh secret`, `curl` with a token, reading or listing
  secrets, `act`, live PRs, branch-protection changes (CLAUDE.md rule 11). Unauthenticated public reads are allowed (e.g.
  `git ls-remote https://github.com/actions/checkout` to pin SHAs; docs.github.com). `gh pr create` for this task's own PRs is
  allowed (the session's configured identity; no token read).

## Dependencies / sequencing
- Done: 007a (PR #10), 007b (PR #12, `70cedca`), 075 (PR #18, `4356583`), M1, M5.
- **Before 008b goes live:** its write-back PRs must pass `gate` (T1/T3 stay rejected until 008b amends `ownership.md`).
- **Then 040** (extends `ci_gate.py`; sequenced after this task). **Before 010 / criterion 2:** M10 and M6.
- **Later task, not this one:** create the takedown-only identity (Ludwig, runbook), amend `ownership.md` R11 to name it (U11 —
  R11 currently names the org id `324218296`), set `config/r11-identity.json`; merge needs Ludwig.

## Assumptions marked [unverified], with how each gets verified
U1 `pull_request_target` runs the default-branch workflow with secrets for fork PRs and is not gated by the first-time
contributor approval — docs.github.com "Events that trigger workflows: pull_request_target" and "Approving workflow runs from
public forks". U2 its check runs appear on the PR head and are selectable as required as `gate` — L1 and the M9 screen. U3 a
path-filtered skipped workflow leaves a required check pending — docs "Handling skipped but required checks". U4 payload
field names — webhook/REST docs and L1. U5 anonymous `git fetch` of `refs/pull/N/head` on a public repo — L1. U6 an App token
with org Members:read answers 204/404 (no 302) for private members — after M10, once, about `womcraft` (status only). U7 runner
has Python ≥ 3.10 and git — L1. U8 `gh api -F body=@file` reads the file — `gh api --help` locally. U9 PyYAML present where the
verify script runs; missing → exit 2. U10 required checks available on Free for a public repo — the M9 screen. U11 R11 names the
org id while Ludwig chose a dedicated account — a follow-up `ownership.md` amendment task. U12 PR comment limit (≈65 536) —
docs, and a truncation test.

---
# Task 039 log
- 2026-09-06 manager: placeholder draft (scope only).
- 2026-10-15 session 9: 007 split into 007a/007b; depends on both.
- 2026-10-15 session 10: gated on the mixed-PR takedown answer — resolved by task 075 (merged `4356583`).
- 2026-10-25 manager (session 11 night): spec revised (draft by a Plan agent, gated by the manager): trust model, identity
  source, merge-base reads, R11 unconfigured, M9/M10 runbook steps, offline §7 criterion-1 demonstration, size justification.
  Open questions decided under Ludwig's standing ★ approval as C4-C8 (mission log). Awaiting independent spec review.
