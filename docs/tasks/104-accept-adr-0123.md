# Task 104: accept ADR-0123 (the reference mod is chosen by task file) and record Ludwig's answers to Q1-Q5

- **Mission:** none (decision record) — **Status:** spec-approved 2026-11-03 (manager, session 14; Ludwig's approval, verbatim: "Party mos becomes the reference mod. Star on all questions")
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
