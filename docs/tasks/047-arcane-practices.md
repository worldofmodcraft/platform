# Task 047: Adopt Project Arcane's practices without weakening WoM doctrine (umbrella)

- **Mission:** tooling, outside SITE-V1's dependency graph (requested directly by Ludwig, 2026-10-14) — **Status:** draft
- **Agent / model:** none. This is an umbrella; the work is done by tasks 048–052.
- **Budget:** n/a (each sub-task carries its own)
- **Branch / worktree:** task/047-arcane-practices / ~/wt/task-047 (task files and mission-log entry only)

## Objective
WoM is developed with the same thinking as Project Arcane, and every project note is mirrored into
Ludwig's Obsidian vault continuously. Nothing in WoM's doctrine gets weaker as a result.

## Origin
Draft `docs/tasks/inbox/DRAFT-adopt-arcane-practices.md` and the reference copy
`docs/tasks/inbox/arcane-reference/` (Arcane commit `a622dd3`). Both were written 2026-10-14 by a
Claude session outside the manager, at Ludwig's request. **Both are untracked in `~/wom` and are not in
this branch on purpose**, because the platform repo is public (see Q-P below). The draft's "Decided by
Ludwig" section is binding and is not asked again.

## Split (dependency order)
`.claude/settings.json` is touched by 050-052's guard, by A (spawn-depth env) and by B (hooks), and
`docs/manager/MANAGER.md` by C3 and A. Overlapping files are sequenced, never run in parallel (MANAGER.md §6).

| Order | Task | Draft part | Depends on |
|---|---|---|---|
| 1 | 050 vault sync probe (manual, no code) | C | Ludwig approves spec |
| 2 | 051 vault projection generator | C | 050 passed, Q-C2, Q-P |
| 3 | 052 vault triggers and guard hook | C | 051 merged, Q-C1 |
| 4 | 048 doctrine (draft items 2–6, token-guard text) | A | Ludwig's answers Q2–Q6, Q-T |
| 5 | 049 safety hooks in bash (draft item 1) | B | Q1, 048 merged |

## Corrections to the draft's claims about WoM doctrine (manager, 2026-10-14)
1. "WoM has the same rules (§3.7, §3.2)": only partly. WoM forbids `--force` and direct commits to main.
   It does **not** forbid `reset --hard`, `rm -rf` or deleting branches, and §6 *requires* deleting
   branches, including an unmerged branch of a derailed task (`branch -D`). Arcane's block list would
   collide with §6.
2. Arcane's test gate (no commit while the suite is red) collides with §2c rule 5: the breaking fixture
   is written and shown failing *before* the fix. WoM also has no single "the suite"; OPERATIONS.md
   records `006-verify.sh` as red on main today by design.
3. "After every merge to main … a `post-merge` hook in the main checkout": WoM merges happen on GitHub
   (`gh pr merge`), so `post-merge` only fires when main is pulled locally. Verified 2026-10-14: local
   `main` was 4 merges behind `origin/main`, and `~/wom` is checked out on `task/046-start-here`, not main.
4. Arcane's `vault-guard` covers file tools only; shell writes pass. Every WoM agent has Bash.
5. Arcane's own hooks README says its SubagentStop handover block "arrives after the subagent has
   delivered its final report, so it is a notice, not enforcement". That weakens draft item 6.
6. The draft omits two WoM requirements a spec must carry: the dependency-graph statement (ADR-0117,
   SPEC-CHECKLIST item 7) and the runnable verification artefact (§2c). Added in 050–052.

## Ludwig decisions recorded in session
- 2026-10-14: **token guard lifted.** Ludwig: "Glöm token kontrollen, du kan framgent ignorera den
  regeln och alla subagents också." Effective immediately for the manager and all subagents. The
  written rule (CLAUDE.md rule 0, MANAGER.md §8) still says otherwise. Bringing the text in line is Q-T,
  handled in task 048.

## Questions for Ludwig
See the mission log, section "For Ludwig — task 047 (2026-10-14)": Q1–Q6 (the draft's items 1–6),
Q-T, Q-P, Q-C1, Q-C2.

---
# Task 047 log
- 2026-10-14 manager: read the draft, the reference folder and the vault guide §9; checked the draft's
  claims against repo and vault (findings above). Split into 048–052. Spec gate run on 050, 051 and 052;
  048 and 049 stay draft until Q1–Q6 are answered.
- 2026-10-14 Ludwig, in session: "Allt enligt stjärna, godkänner spec 050". Q1–Q6, Q-T, Q-P, Q-C1 and
  Q-C2 are all answered ★ as listed in the mission log's "For Ludwig — task 047". Spec 050 approved.
  Manager note for Q-C1: checked in a temp repo, `git fetch origin main:main` does not fire `post-merge`
  (`git pull` does). So under ★A the manager step is the trigger that updates main's notes, and the
  hook covers Ludwig's own pulls.
- 2026-10-14 independent spec review of 051/052: NOT PASS, 11 findings. Revision pending; the reworked
  051 text was not saved.
