# Task 010: The `test:hello-world` canary mod, its first-publish runbook, and Ludwig's step M4

- **Mission:** SITE-V1, deliverable **D4** — **Status:** draft (spec written 2026-10-14 under task 054). **Ludwig's identity question (Q1) is decided (2026-10-14: his personal account joins the organisation, M6); the contents (criteria 1-4) wait on 008a and tasks 057/058; the runbook waits on 008b and 055 being far enough along to rehearse (see Dependencies). Q2 and Q3 below remain open.**
- **Agent / model:** implementer / sonnet for the mod contents and generator; doc-writer / sonnet for the runbook (two sessions, one branch, sequenced)
- **Budget:** medium (≤ 3 agent-sessions)
- **Branch / worktree:** `task/010-test-mod` / `~/wt/task-010` — **platform** repo (`worldofmodcraft/platform`). The mod's own repository is created by Ludwig (M4) and is not a repo this task can touch. The registry PR the runbook describes is opened during the runbook, not by this task.

## Objective
Everything Ludwig needs to publish the permanent pipeline canary exists and has been
rehearsed: a complete, original, no-code mod source tree (`mod.lua`, `README.md`, `LICENSE`,
2-3 original PNG screenshots); the registry-side files for its first publish; and
`docs/runbooks/first-publish.md`, a step-by-step runbook in which every step states the exact
command or click, what he should see, and what it proves (mission D4, §7.6). The mod tree
passes the project's own validators locally before he ever sees it. Mission §7.6 itself ("executed
by Ludwig end-to-end without improvisation") is his run, recorded, not this task's output.

## Context to load (exhaustive)
- ADRs: 0058 (§1 flow, §3 the namespace-creation confirmation text), 0119 (`test` is reserved and
  bound to the organisation; §3 authorises by **organisation membership** of the PR author — this
  drove the identity decision Q-F), 0059 (§2 `page.json`, §3 the `page.json` PR path), 0030 (manifest fields),
  0049 (licence), 0061 (AI-generated assets allowed, must be original, nothing imitating Blizzard
  style), 0120 (whitelist), 0041 (what the pipeline does, what appears on the page).
- Files: mission §4 D4 and §7.6; `docs/runbooks/site-v1-manual-steps.md` (M4 text to be updated;
  M1.3 style for how a runbook step reads); `docs/architecture/depgraph.md` (N1);
  registry `contracts/{manifest,page,entry}.schema.json` and `contracts/examples/**`
  (`mit-mod.json`, `basic.json` for shape), `reserved-namespaces.json`,
  `tools/validation/scan_assets.py`, `contracts/archive-layout.md` (screenshots resolve under the
  archive root), `contracts/url-scheme.md` (`/mods/test/hello-world`).
- The runbook author must also read the task logs of 008a, 008b, 039, 055 *as built*, not as
  specified (the screens and messages Ludwig sees come from what exists).

## Findings that shape this task (verified 2026-10-14)
1. **The mission's identity assumption conflicts with ADR-0119.** M4 says the repo lives under
   Ludwig's personal account and *he* opens the registry PR. `test` is a reserved namespace: a PR
   touching it is authorised only if its author is a **member of `worldofmodcraft`**, rejected
   otherwise with a message naming ADR-0119. Ludwig's personal account `mbmludric` (id 37807560) is
   documented as **not** a member (`docs/architecture/key-management.md`; `docs/manager/OPERATIONS.md`).
   Unauthenticated check of the public side only (run 2026-10-14):
   ```
   $ curl -s -o /dev/null -w 'status=%{http_code} redirect=%{redirect_url}\n' https://api.github.com/orgs/worldofmodcraft/members/mbmludric
   status=302 redirect=https://api.github.com/organizations/324218296/public_members/mbmludric
   $ curl -s -o /dev/null -w 'status=%{http_code}\n' https://api.github.com/orgs/worldofmodcraft/public_members/mbmludric
   status=404
   ```
   This shows only that `mbmludric` is not a **public** member (an unauthenticated caller cannot
   see private membership; `ownership.md` says a 302 means "the caller cannot see", not "not a
   member"). That he is not a member at all rests on the two platform docs cited above.
   As written, §7.6 could not pass with Ludwig's personal account opening the PR. **Resolved: Ludwig
   decided (2026-10-14, Q-F) that his personal account joins the organisation — manual step M6,
   whose text is in `008b-pipeline-workflow.md` — so mission §7.6 stands as written** (he opens the PR
   from `mbmludric`). The runbook therefore has an M6 prerequisite step and a check that the
   membership exists before the PR is opened.
2. **The page.json screenshot scan does not exist yet** (task 040): until it lands, a `page.json`
   PR's screenshots are not scanned. The canary's own screenshots are scanned by the pipeline when
   the *version* is built (008a criterion 7), but the runbook's later "add a screenshot via
   `page.json`" step (§7.5) only works for a screenshot that is already **inside the archived
   1.0.0 tarball**, because `page.json` paths resolve into the archive (`archive-layout.md`). So the
   mod's 1.0.0 must ship a spare, unreferenced screenshot for that step. Designed in below.
3. **`mod.lua` vs `manifest.json`** — decided (Ludwig, 2026-10-14, Q-C): the pipeline and the
   site read `mod.lua` with a restricted static reader (literal table, never executed). The mod
   ships only `mod.lua`, written within that literal subset (no function calls, no concatenation).
4. **Lua is not installed on this machine** (`which lua` empty), so the mod's `mod.lua` cannot be
   executed locally; it is validated by 008a's reader, which does not execute it.

## Contents the task produces (all original; nothing Blizzard-derived)
Staging tree in the platform repo, `docs/test-mod/hello-world/`, which Ludwig copies into the new repo:
- `mod.lua` — `return { id = "test:hello-world", name = "Hello World", version = "1.0.0",
  api_version = "1.0", license = "MIT", source = "<the M4 repository URL>", type = "mod",
  description = ..., tags = {...}, screenshots = {three paths}, ai_assisted = <see below> }`.
  No code, no `server`/`client` blocks. The `source` URL is a placeholder token the runbook has
  Ludwig replace with a stated command before tagging (the URL is only known after he creates the repo).
- `README.md` — real formatted content: headings, a list, a table, a fenced code block, a link,
  and an image reference to a screenshot — it is the sample the site's Markdown renderer is
  shown rendering (mission §7.4). States that this mod is the permanent pipeline canary.
- `LICENSE` — MIT text, copyright line "World of Modcraft contributors" **or** Ludwig's name (Q3).
- `assets/screenshots/{welcome,gallery,spare}.png` — three **original** PNGs produced by a
  committed, deterministic generator `tools/test-mod/make_screenshots.py` (Python stdlib: `zlib`,
  `struct`; abstract geometric/gradient art, not a game scene; no fonts, no Blizzard motif).
  Dimensions fixed in the script (e.g. 1280×720). `spare.png` is deliberately **not** referenced
  from `mod.lua`'s `screenshots`; the runbook's `page.json` step adds it.
- Registry-side files for the first-publish PR, in `docs/test-mod/registry-pr/` (shape decided,
  Ludwig 2026-10-14, Q-B; defined by task 057): the submission for `1.0.0` is an `entry.json` whose
  one version object holds exactly `version`, `commit`, `source_url` and `status: "pending"` — the
  five write-back fields are absent and are written by the pipeline's PR (id, owner =
  `{provider: "github", id: 324218296, name_at_registration: "worldofmodcraft"}` — the org, per
  `reserved-namespaces.json`, to be re-read from that file by the task, not from this sentence;
  version, commit placeholder, source_url placeholder), and `page.json` (description that says it
  is the permanent canary, `screenshots` = the two referenced ones, `tags`, `links` = [], `deprecated: false`).
  Commit hash and source URL are placeholders with a stated fill-in command.

## Runbook `docs/runbooks/first-publish.md`
Steps, each with *Do* (exact command or click) / *You should see* / *This proves*:
M6 join the organisation (check: the people page lists `mbmludric`) → M4 create repo → copy tree and replace placeholders → commit and tag `v1.0.0`, capture the 40-hex
commit → open the registry PR (from `mbmludric`, Q-F) → watch the registry CI checks and read each
message → merge (who merges: MANAGER.md §7 / Ludwig's approval) → watch the pipeline run, the Release appear in `worldofmodcraft/archive`, the
write-back PR (opened by the pipeline's GitHub App) open and merge, and check that the entry's `source_archive` URL (the project-owned one, decision Q-G; shape from task 058) resolves → open `worldofmodcraft.com/mods/test/hello-world` and check each
element mission §7.4 lists → open the `page.json` PR (change description, add `spare.png`) → merge
→ watch the site rebuild → see the changed page with no new version. Also a final section: the
**negative checks** Ludwig may run to see the gates refuse (wrong account, modified version),
clearly marked optional, since they are acceptance criterion 1 of the mission and belong to 039.

**Evidence rule for "You should see".** Every such line is copied from an observation made while
rehearsing the runbook (see criterion 5), or it is prefixed `[UNVERIFIED — expected, not observed]`
and listed in the log. Task 037's lesson (OPERATIONS.md, Pages): a setting read back is not a
behaviour observed; a page may lag ten minutes after a deploy, and the runbook must say to wait
and how to tell.

## Acceptance criteria
[script] = `docs/tasks/010-verify.sh`; [human] = Ludwig or a reviewer, recorded, not scripted.
1. [script] **Mod tree validity.** The staging tree passes, with the registry tools checked out at
   `main`: `scan_assets.py docs/test-mod/hello-world` exit 0 (directory argument — a file path
   gives exit 2, which is never read as "accepted"); the manifest validates through 008a's reader
   and `manifest.schema.json` with `MIT`; `id` is `test:hello-world`; every `screenshots[]` path
   exists and is a PNG by magic bytes (`89 50 4E 47 0D 0A 1A 0A`) with a valid IEND; none is
   referenced by `..` or absolute path.
2. [script] **Originality guardrail:** the three PNGs are produced by the generator and
   byte-identical on re-generation (determinism), and the tree contains no file with a
   Blizzard-format magic (`scan_assets.py` already enforces this) and no file named like an
   extracted game asset. State in the log what this does *not* prove: it cannot prove visual
   originality; that is criterion 8.
3. [script] **Registry-side files validate:** `page.json` validates against `page.schema.json`
   (using `schema_check.validate`), the submission file validates against `entry.schema.json` as amended by task 057 (a `pending` version with exactly the four author fields), the `page.json`
   `screenshots` are a strict subset of `mod.lua`'s, and `spare.png` is in the tree but in neither list.
4. [script] **Placeholders cannot leak:** a grep for the placeholder tokens over the staging tree
   finds them exactly where intended (non-zero count, asserted — a search that finds nothing is a
   broken search) and the runbook names the command that replaces each; after running that
   replacement command on a copy with a sample URL and sample hash, zero placeholder tokens remain.
5. [human] **Rehearsal.** The runbook was executed end to end by the implementer against a scratch
   environment as far as the environment allows. Because the registry is append-only and
   permanent, **no rehearsal step may publish `test:hello-world` to the real registry.** The
   rehearsal uses a local bare registry clone and 008a's tool; steps that cannot be rehearsed
   without publishing are marked `[NOT REHEARSED]` with the reason. The log lists observed vs
   not-observed per step.
6. [script] **Runbook shape:** the verify script checks that every numbered step in
   `first-publish.md` contains the three labelled parts (*Do*, *You should see*, *This proves*),
   that every fenced command block is a single copy-pasteable unit (no `<placeholder>` left
   unlabelled), and that `[UNVERIFIED` markers equal the log's list in count. Mutation: delete one
   *This proves* line, add a stray `<...>`; each reddens.
7. [script] **No credential in the runbook:** no step asks Ludwig to paste a token, key or secret
   into chat, a file or the PR; `gh auth token`/`--show-token` do not appear (grep with a positive
   control file that contains them and must be caught).
8. [human] **Visual review:** Ludwig (or the manager on his behalf, recorded as such) has looked at
   the three screenshots and confirms they are original and acceptable on the page.
9. [human] **M4-M7 recorded:** `docs/runbooks/site-v1-manual-steps.md` M4 section updated to point at
   `first-publish.md` and to state the identity answer (Q-F: personal account, after M6); M5, M6, M7 sections present with the text from `008b-pipeline-workflow.md` (click-paths still marked unverified unless observed by Ludwig); status keys unchanged (☐ until he does them).
10. [human, mission §7.6] Ludwig runs the runbook; deviations from it are recorded verbatim in the
    mission log. "Without improvisation" is judged by that record. Outside this task's `done`:
    it closes the mission criterion, and this task is `done` only when that record exists.
11. `docs/tasks/010-verify.sh` exists, executable, mutation-tested (criteria 1, 4, 6, 7), run in a
    fresh clone; output pasted in the log; the log separates [script] from [human] results.

## Explicitly OUT of scope
- Creating the repository, pushing, tagging, opening the registry PR — Ludwig's (M4) and the runbook's.
- Any publish of anything to the real registry as a "test". The first publish is the real one.
- Code in the mod (mission D4: "no code"); a roguelike or any other mod's content (mission §2).
- The registry gates, pipeline and site themselves (039, 007, 008, 055).

## File scope (declared; anything else = stop and report)
In the **platform** repo:
- `docs/test-mod/hello-world/**`, `docs/test-mod/registry-pr/**`
- `tools/test-mod/make_screenshots.py`, `tools/test-mod/tests/` (generator determinism test)
- `docs/runbooks/first-publish.md` (new), `docs/runbooks/site-v1-manual-steps.md` (M4-M7 sections only; M5-M7 text is copied from 008b, where it is the source. Because M5 and M7 gate 008b's live criteria, the manager may split this one edit into an earlier docs task)
- `docs/tasks/010-test-mod.md` (log), `docs/tasks/010-verify.sh` (new, executable)
Everything else, including `docs/decisions/` and the mission spec, is read-only.

## Forbidden here (beyond MANAGER.md §3.7)
- Any Blizzard-derived, Blizzard-styled or trademark-evoking art, text, name or icon; AI-generated
  screenshots in the manner of ADR-0061's forbidden case ("prompt Stormwind"). The generator is
  deterministic abstract art on purpose.
- Fabricating "You should see" text; inventing CI messages (copy them from the tools).
- Putting a real token, key or private repository URL in any file; instructing Ludwig to copy one.
- Publishing, tagging or pushing anything to a remote as part of rehearsal.
- Declaring Ludwig's M4-M7 or §7.6 done.
- Setting `ai_assisted` without Q3's answer (the field is tri-state; omitted shows nothing).

## Dependencies and sequencing
- Needs: Q-F decided (it is); registry tools at `main` (scanner, schemas — exist); task 057 merged (the
  submission shape); task 058 reported (the URL the runbook tells Ludwig to check);
  008a merged (manifest reader, for criterion 1); 039 (so the runbook describes CI messages that exist).
- The runbook's pipeline and site sections need 008b and 055 *built* to rehearse; criterion 5
  marks what cannot be. So: contents (criteria 1-4) can start after 008a; the runbook is finalised
  after 008b and 055.
- M3 (secret) is already done per the mission log (its existence is unconfirmed: umbrella Q-H); M4 is the manual step this task serves; M5, M6, M7 (GitHub App, org membership, archive repo) must be done before the runbook's live part.
  Task 011 (hardware-key 2FA) is required "before the first non-test publish" — this publish is the
  test one, but Ludwig should be told.
- Blocks mission §7.2, §7.4-§7.6.
- Graph: node **N1 mod-source** (and it exercises N2, N3, N5-N8 end to end). No new edge.

## Verification artefact (MANAGER.md §2c)
Declared: `docs/tasks/010-verify.sh` for criteria 1-4, 6, 7. Criteria 5, 8, 9, 10 are human and
external and are recorded as such.

## Deliverables
Mod tree, generator, registry-side files, runbook, M4 update, verify script, this file's log current.

## Questions  (agent-maintained; see MANAGER.md 8b)
- ~~Q1 identity~~ **decided (Ludwig, 2026-10-14, Q-F):** his personal account joins the organisation (M6); he opens the PR; mission §7.6 stands as written. Options B (platform account opens it) and C (publish under his own namespace) are not taken.
- **Q2 (open):** repository name and visibility for M4 (mission says `test/hello-world` under his personal
  account: GitHub does not allow a slash in a repo name; the repo is `<account>/hello-world`). |
  options: A★) `<account>/wom-test-hello-world` / B) `<account>/hello-world` | assumed: A (avoids
  a generic name; the mod id is in `mod.lua`, not the repo name).
- **Q3 (open):** `LICENSE` copyright holder and `ai_assisted` value for a mod whose screenshots are
  script-generated and whose README is agent-written. | options: A★) "World of Modcraft
  contributors", `ai_assisted = true` (honest, ADR-0061-compatible) / B) Ludwig's name, omitted |
  assumed: A.
- Umbrella Q-B and Q-C are decided; the contents above are no longer built on assumptions about them.

---
# Task 010 log  (append-only, updated continuously by the executing agent)
- 2026-10-14 spec written under task 054; nothing started.
- 2026-10-14 Q-B, Q-C, Q-F folded in from Ludwig's answers; Q1 closed; Q2, Q3 remain open.
