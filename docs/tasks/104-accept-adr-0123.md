# Task 104: accept ADR-0123 (the reference mod is chosen by task file) and record Ludwig's answers to Q1-Q5

- **Mission:** none (decision record) — **Status:** done 2026-11-03 (manager, session 14; Ludwig's approval, verbatim: "Party mos becomes the reference mod. Star on all questions")
- **Agent / model:** doc-writer — **Budget:** small
- **Branch / worktree:** `task/104-accept-adr-0123` / `~/wt/task-104` (platform)

## Ludwig's answers (2026-11-03)
Q1 **A** (the party mod becomes the reference/first mod that drives the kernel API; the roguelike stays a planned mod); Q2 **B** (board-only bots; in
minigames a simulated score; with a bot seated only free-for-all and duel minigames); Q3 **A** (2-4 players); Q4 **B** (15 rounds default); Q5 **A**
(separate from the arcade driver mod; both build on the platform's surfaces).

## Deliverables
1. `docs/decisions/0123-<slug>.md` (slug from the title, kebab-case): the text of `docs/design/party-board-mod-proposed-adr.md` with the PROPOSAL banner removed,
   `Status: Accepted`, `Date: 2026-11-03`, the Decision section stating option A (quote Ludwig verbatim), the Questions section replaced by a short "Answers"
   section listing Q1-Q5 as above. Amendment text for 0001:16 and 0050:17, :28 **unchanged** from the proposal. TEMPLATE.md shape; README amend rules.
2. Header metadata lines exactly as the proposal's "Metadata lines added on acceptance" in `docs/decisions/0001-platform-is-the-goal.md` and
   `docs/decisions/0050-build-order-walking-skeleton.md` — no other edit to either file (substance is never edited).
3. `docs/decisions/README.md`: one index line for 0123 in the right section. `docs/decisions/INDEX.json`: regenerated with `python3 tools/adr/build_index.py --write`.
4. `docs/design/party-board-mod-proposed-adr.md`: replace the PROPOSAL banner by a one-line pointer "Accepted as ADR-0123 on 2026-11-03: see docs/decisions/0123-…".
5. `docs/design/party-board-mod.md`: status line no longer "rests on the proposed ADR"; section j's questions marked answered (Q1-Q5 as above); every place that
   said "[open]" for these five questions updated to the decision. No other design change.
6. Booked (not done here): the five ADR lines that still give the roguelike a platform role (0051:16, 0113:14, 0097:1,7, 0098:15, 0115:44) — a follow-up question
   for Ludwig; list them in this task's log.

## Acceptance criteria
1. `python3 tools/adr/build_index.py --check` exits 0 (index complete, amend protocol consistent, INDEX.json fresh); paste the output.
2. `git diff origin/main...HEAD -- docs/decisions/0001-*.md docs/decisions/0050-*.md` shows exactly one added header line each.
3. The amendment sentences in 0123 are byte-identical to the proposal's (diff shown).
4. Scope: only the files in Deliverables + this task file. No verify script runs while the registry 039a sweep holds the machine; the manager runs the
   platform `*-verify.sh` that read docs/decisions (e.g. 001/003 index checks if they have scripts) after it.

---
# Task 104 log
- 2026-11-03 manager (session 14): created on Ludwig's approval; dispatched.
- 2026-11-03 doc-writer: executed deliverables 1-5 (verify scripts not run, per brief).
  - Created `docs/decisions/0123-reference-mod-chosen-by-task-file.md`: proposal text, banner removed, Status Accepted, Date 2026-11-03, Decision = option A with Ludwig's words verbatim, Questions replaced by "Answers" (Q1 A, Q2 B, Q3 A, Q4 B, Q5 A). Quote kept as written ("Party mos"; "mos" noted in the ADR).
  - Headers of 0001 and 0050: one added line each; README index line added under "Process & developer experience"; INDEX.json regenerated (123 entries); design docs updated (banner pointer; status line; last reviewed 2026-11-03; e.6, b.1, h.3a, j.1 table with answers, j.3 item 3).
  - AC1: `python3 tools/adr/build_index.py --check` exit 0. Final line: "CHECK OK: INDEX.json matches the ADR files and both invariants hold." Header: "Scanned 123 ADR file(s)... Parsed OK: 123. Skipped (fatal): 0. Touches coverage: 7/123" (the 116 "missing Touches" lines are the pre-existing advisory list, not failures).
  - AC2: `git diff origin/main...HEAD -- docs/decisions/0001-*.md docs/decisions/0050-*.md` (after commit) is the two added lines:
```
--- a/docs/decisions/0001-platform-is-the-goal.md
+++ b/docs/decisions/0001-platform-is-the-goal.md
+- **Amended by:** ADR-0123 (the driving reference mod is named by task file, not fixed to the roguelike)
--- a/docs/decisions/0050-build-order-walking-skeleton.md
+++ b/docs/decisions/0050-build-order-walking-skeleton.md
+- **Amended by:** ADR-0123 (step 1 and step 8 name "the reference mod", not the roguelike)
```
  - AC3: Context, Options, Amendments, Consequences and Impact sections of 0123 compared with the proposal at HEAD (`git show HEAD:docs/design/party-board-mod-proposed-adr.md`) via `diff`: no output, i.e. byte-identical (amendment text for 0001:16, 0050:17, 0050:28 included).
  - Deliverable 6 (booked, not done; follow-up question for Ludwig): ADR lines that still give the roguelike a platform role: 0051:16 (reference mod = roguelike, every API function used there), 0113:14 (example chain level c), 0097:1,7 (roguelike kit re-audit gate before step 1), 0098:15 (repo-layout comment "roguelike (reference mod)"), 0115:44 ("reference mod v17 will be English-commented"). Also ADR-0001 title and :19 still say "first mod" = roguelike (titles are never edited). Options for Ludwig: A amend these by a further ADR; B leave them (roguelike is a planned mod, lines read as its own kit); C amend only 0097 and 0051.
  - Note: the party-board-mod-proposed-adr.md "Status: Proposed" metadata line was left as is (brief asked only for the banner replacement).
- 2026-11-03 manager (session 14): `tools/adr/build_index.py --check` re-run: CHECK OK. The two Amended-by lines checked (one each, exactly the proposal's metadata).
  Cross-script check: the platform `*-verify.sh` that read docs/decisions (010a, 080) run on this head in a fresh clone: 010a exit 0 (ALL OK), 080 exit 0. Ludwig's
  approval is the task's spec line. Status done; merged by the manager on Ludwig's approval of the ADR (2026-11-03).
