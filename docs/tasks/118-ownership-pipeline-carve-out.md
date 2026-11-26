# Task 118: `contracts/ownership.md` gains `R12`, the pipeline identity's carve-out for T1 and T3 (edge E16)

- **Mission:** SITE-V1, deliverable **D2** (umbrella `docs/tasks/008b-pipeline-workflow.md`) — **Status:** draft (manager, 2026-11-26; security contract: independent spec review before delegation, MANAGER.md §2b)
- **Repo:** registry. **Agent / model:** doc-writer (model per frontmatter). **Budget:** medium (≤ 3 agent-sessions)
- **Branch / worktree:** `task/118-ownership-pipeline-carve-out` / `~/wt/registry-task-118`, cut from registry `origin/main` (`e213cbc`)
- **Graph:** node N3, edge **E16** (author identity -> N3). **Blocks:** the 008b-3a fix round, then 008b-3b.
- **Why it exists:** 008b-3a's security review (2026-11-07, finding F1, confirmed by the manager) found that `ownership.md` has no pipeline carve-out: `R3` and `R7` call `R11` "the single exception", and `append-only.rules.md` ("Fail closed", the bullet under "Shape layer and authority layer") binds every checker to reject every T1/T3 PR until `ownership.md` carries one. Task 057 booked this as a sibling task that was never written. Spec defect, the manager's.

## Objective
`contracts/ownership.md` declares a new verdict rule **`R12`**: a PR whose whole diff is exactly one T1 (`pending -> published`) or exactly one T3 (`pending -> rejected`) element in exactly one `entry.json` is authorised only when its author is the pipeline identity, and that authorisation lifts `R3` and `R7` for that PR. Every other PR that contains a T1 or T3 mutation is rejected by `R12`, whoever opened it. The fail-closed bullet in `append-only.rules.md` is updated to point at `R12`. Nothing else in either contract changes in substance.

## Decisions (manager ★ under ADR-0125, 2026-11-26; logged in the mission log)
- **A★ a new rule `R12`**, not an extension of `R11`. B: widen `R11` to "platform or pipeline identity". Reason: `R11` has a different identity, a different diff shape and Ludwig's merge gate (I8, MANAGER.md §7); folding the two would make every `R11` sentence carry two cases, and `032-verify.sh`'s precedence checks work per declared pair.
- **Identity:** `(provider: "github", id: 342916936)`, the user id of `worldofmodcraft-pipeline[bot]`, read from the public API on 2026-11-07 (008b-3a log, umbrella F4). **Not** the App id `5327993`; the contract names both numbers and says which is which, because confusing them is the obvious mistake. Matched on `pulls.user.id` and provider (`I1`, `I6`), never on the login string or `GITHUB_ACTOR*`.
- **Where a checker reads it:** `config/pipeline-identity.json` at the PR's **merge-base** revision, never the PR's own revision (same reasoning as `I4`), in the same shape as `config/r11-identity.json`. **Until that file exists and holds a non-null id, `R12` authorises nobody** (fail closed), exactly as `R11` reads today. This task does not create the file: the 008b-3a fix round creates it with `null`, 008b-3b sets the id. Precedent: `R11`'s "The mechanism, marked rather than assumed" paragraph.
- **Exactly one element.** A: exactly one T1 or exactly one T3 per PR (008b-3a criterion 5, the umbrella's design). B: any number of T1/T3 in one PR. A★: one build produces one write-back, and a mixed or multiple PR is the "splice" attack 057 recorded.
- **Disjoint identities:** a checker whose configured pipeline identity equals `R11`'s identity must stop with a configuration error rather than give a verdict (008b-3a finding F5). Declared as a new checker rule **`I9`**.

## Acceptance criteria
1. [script] `R12 (MUST)` is declared once, in its own paragraph, in a new section placed after the takedown section and before `## Questions`. It states: the identity and its source file (merge-base revision); the diff condition (exactly one element in exactly one `entry.json` that `append-only.rules.md` classifies as T1 or as T3, and **no other change in the PR**: no other file, no other element, no `page.json`, nothing under `contracts/`, `config/`, `.github/` or `tools/`); that the two conditions are jointly sufficient; that a PR containing a T1 or T3 mutation that `R12` does not authorise is rejected **by `R12` itself**, whoever opened it; how "contains a T1 or T3 mutation" is decided, and that if it cannot be evaluated the PR is rejected (fail closed, ADR-0121); and that `R12` authorises nobody until the identity is configured.
2. [script] **Precedence at both ends** (the document's own convention): `R12`'s paragraph carries `Precedence: R12 over R3, R7`; `R3`'s and `R7`'s paragraphs each name `R12` beside `R11`, and the words "the single exception" (or any equivalent claim that `R11` is the only one) no longer appear in them. The taxonomy rows for `R3` and `R7` name both `R11` and `R12`.
3. [script] The taxonomy table has exactly one `R12` row: when it rejects (a T1/T3 PR by another identity; a T1/T3 mutation in a PR that is not exactly one T1 or one T3 and nothing else) and what the message says (the namespace, the author's real `(provider, id)`, and that only the pipeline identity may write back a build result, as one transition per PR).
4. [script] `I9 (MUST)` is declared: a configured pipeline identity equal to `R11`'s identity is a configuration error and the checker stops without a verdict.
5. [script] The `R11` and `R12` interaction is explicit in both paragraphs: a PR mixing a takedown (T2) with a T1 or T3 is rejected by both `R11` and `R12`; the pipeline identity has no takedown power and the platform identity has no write-back power.
6. **Attack attempts**, added to the existing "Attack attempts" section in its existing form, each with its answer: (a) an author writes their own T1 (self-publish through write-back); (b) the pipeline identity's PR adds a new version beside a T1; (c) the pipeline identity's PR splices a takedown into a write-back; (d) the pipeline identity's PR edits `page.json` or `config/pipeline-identity.json` itself; (e) an account named `worldofmodcraft-pipeline` without `[bot]`, or a user who registers a look-alike login, opens a T1; (f) a checker is configured with the App id `5327993` instead of the bot user id; (g) a PR edits `config/pipeline-identity.json` to its own id and adds a T1 in the same PR (answer: merge-base revision, and the diff condition).
7. [script] `append-only.rules.md`: the "Fail closed" bullet and the "pipeline's carve-out (a sibling task)" sentence now name `ownership.md`'s `R12`; the fail-closed default for a checker that does not implement `R12` stays in force. No other line of that file changes.
8. [script] `docs/tasks/032-verify.sh` passes on the branch. Only its pin lists may change (`CROSSREF_ALLOWED`, `LOWERCASE_MUST_ALLOWED`, and any other list that pins sentences), and each changed pin shows the old and new sentence in the diff; **no check is removed, disabled or weakened**, and its mutation script (`032-mutations.sh`) still passes. Any other closed script that turns red because of this change: stop and report, do not edit it.
9. [script] `docs/tasks/118-verify.sh` (registry, new, executable) checks criteria 1-5 and 7-8 against the branch with one labelled check per claim (MANAGER.md §2c rule 3), runs from a fresh clone, and is mutation-tested: delete `R12`'s precedence line; restore "the single exception" in `R3`; replace the bot id with `5327993`; drop "merge-base" from the identity source; drop `R12`'s taxonomy row; delete `I9` — each shown red, then restored byte-identically.
10. **Facts carry their basis (guardrail 6b/6c):** any statement about how GitHub reports a bot's `pulls.user.id` for a PR opened by an App installation is either verified from public documentation with the URL and date, or marked unverified inline at the point it is made, naming that the 008b-2 dry run (live) confirms it.

Script-verified: 1-5, 7-9. Not script-verified: 6 and 10 (reviewer reads them).

## Size (5b)
Source files: none (contracts are documentation; `032-verify.sh` edits are pins in a verify script). Changed lines: about 150-250 of contract prose. Reading list: 9 items. Within caps.

## Context to load (exhaustive; 9 items)
1. Registry `contracts/ownership.md` — all of it; above all "How to read this document" (lines 30-100), `R3` (113-130), `I1`/`I6`/`I4`, `R7` (621-663), the taxonomy (664-695), the takedown section and `R11`/`I8` (981-1073).
2. Registry `contracts/append-only.rules.md` — "The permitted in-place mutations" (T1, T3; from line 293) and "Shape layer and authority layer" / "Fail closed" (about lines 598-610).
3. Registry `docs/tasks/032-verify.sh` — what `T1`-`T16` check and the pin lists (`CROSSREF_ALLOWED` from line 841, `LOWERCASE_MUST_ALLOWED` near 695); and `docs/tasks/032-mutations.sh`.
4. Registry `config/r11-identity.json` (the shape to mirror).
5. Platform `docs/tasks/008b3a-ownership-carve-out.md` — objective, criterion 5, and the log entry of 2026-11-07 (F1-F6, the bot id).
6. Platform `docs/tasks/008b-pipeline-workflow.md` — decision Q-D (lines ~140-145) and M5.
7. Platform `docs/tasks/057-version-lifecycle-contract.md` — lines 80-90, 180-195, 205-210 (the sibling task, the splice attack).
8. Platform ADR-0121 (version lifecycle) and ADR-0058 §2 (ownership by numeric id).
9. Platform `docs/manager/MANAGER.md` §2c (verify scripts) and §3.6 (6b, 6c).

## File scope (declared; anything else = stop and report)
Registry: `contracts/ownership.md`; `contracts/append-only.rules.md` (the one bullet and sentence of criterion 7); `docs/tasks/032-verify.sh` (pin lists only); `docs/tasks/118-verify.sh` (new); `docs/tasks/118-ownership-pipeline-carve-out.md` (a copy of this file, with the log). Nothing under `tools/`, `tests/`, `config/`, `.github/`.

## Forbidden (beyond MANAGER.md §3.7)
- Touching any token, key or credential; reading the App's private key. The bot id is already recorded; do not query GitHub for it again.
- Weakening or removing any `032-verify.sh` check; editing any other closed verify script.
- Pushing anything but the task branch; opening the PR is the manager's.
- Cloning from `~/registry` (a shared checkout): work only in the given worktree; for a fresh clone, clone from `https://github.com/worldofmodcraft/registry.git` (session 15's §8 incident).

## Merge gate
Independent review (reviewer agent) against REVIEW-CHECKLIST.md and this file; manager re-runs `118-verify.sh` and `032-verify.sh` from a fresh clone; then the whole sweep (`tools/dev/sweep.py`) on the branch head, from a clone with a local `main` equal to the merge-base, through a neutral script file (OPERATIONS.md). Merge under ADR-0125.

## Questions  (agent-maintained; see MANAGER.md 8b)
- (none open.)

---
# Task 118 log  (append-only)
- 2026-11-26 manager (session 16): spec drafted from 008b-3a's F1 and session 15's "Next session starts here" item 1.
