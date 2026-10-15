# Task 048: Write Ludwig's chosen Arcane practices into the doctrine

- **Mission:** tooling (task 047, part A) — **Status:** spec-approved (manager, 2026-10-15, after independent spec review rounds 2–3; merge requires Ludwig, §7) 
- **Agent / model:** doc-writer / per agent frontmatter (ROUTING.md)
- **Budget:** medium (many small edits to about 20 files, one verify script; no single file is large)
- **Branch / worktree:** task/048-doctrine-arcane / ~/wt/task-048
- **Sequencing:** after 052 is merged (052 also edits `.claude/settings.json` and `MANAGER.md` §5 item 4). Then 048, then 049. Never in parallel.
- **Merge authority:** this task edits CLAUDE.md, MANAGER.md and the review/spec checklists. It is **doctrine, so Ludwig approves the merge (MANAGER.md §7)**, whatever the review checklist says.

## Objective
The doctrine, the agent definitions and `.claude/settings.json` carry exactly the practices Ludwig chose
on 2026-10-14 ("Allt enligt stjärna", every option marked ★ in the mission log section "For Ludwig —
task 047"), and the token-guard text records his suspension. Nothing existing is weakened: every
change is an addition.

## Decisions encoded (all answered ★ by Ludwig, 2026-10-14)
| Id | Decision | Where it lands |
|---|---|---|
| Q2 ★A | Subagent nesting off: `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1` in `.claude/settings.json` `env`, plus `disallowedTools: Agent` in every agent definition | settings.json, 10 agent files, MANAGER.md §3b, ROUTING.md |
| Q3 ★A | The reviewer forms its findings from spec + diff **before** it reads the task log | `reviewer.md`, REVIEW-CHECKLIST.md |
| Q4 ★B | Soft size cap: 5 source files / 300 changed lines / 10-file reading list. Exceeding any needs a written justification in the task file at the spec gate | SPEC-CHECKLIST.md, TASK-TEMPLATE.md, MANAGER.md §2b |
| Q5 ★A | `maxTurns` per agent in frontmatter; hitting it is a budget stop (§8) | 10 agent files, MANAGER.md §8, ROUTING.md |
| Q6 ★B | No new handover file. A script, run by the manager after every subagent, checks that the task log got a new dated entry | MANAGER.md §5 (the script itself is task 049) |
| Q-T ★B | Token-guard text kept, marked suspended; the night-only waivers recorded as historical | CLAUDE.md rule 0, MANAGER.md §8 |

(Q1 is task 049. Q-P, Q-C1, Q-C2 belong to tasks 051/052.)

## Verified facts this spec rests on
- **Official docs, read by a claude-code-guide agent 2026-10-14:** `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`
  exists from v2.1.217; **the default is 3**, so subagents can spawn subagents today; `1` turns nesting
  off (https://code.claude.com/docs/en/env-vars.md). `maxTurns`, `disallowedTools`, `effort` and
  `permissionMode` are documented subagent frontmatter fields; when `maxTurns` is reached the output is
  returned marked partial, from v2.1.246 (https://code.claude.com/docs/en/sub-agents.md). Installed
  version: 2.1.300 (`claude --version`, 2026-10-14).
- **Not documented:** the default `maxTurns` when the field is omitted. The numbers below are explicit for
  every agent, so nothing relies on the default.
- **Unverified (§3.6b), confirmed by AC8 and AC9:** (a) that the tool to disallow is named `Agent` in
  this version. The doc-writer checks the name in the sub-agents doc and in a live session before writing
  it into ten files; if it is `Task`, the spec is amended first. (b) That the env var takes effect only
  after a session restart (assumed: the environment is read at startup).

## Proposed `maxTurns`
Ludwig chose per-agent caps (Q5 ★A). The numbers are the manager's proposal and are approved together with
this spec. No measured turn counts exist yet, so each is a first estimate with a reason. They are reviewed
after the first three budget-stops or ten finished runs, whichever comes first, and changed only by a
doctrine task, never silently.

| Agent | maxTurns | Reason |
|---|---|---|
| scaffolder | 30 | mechanical generation from a template; needing more means the spec is ambiguous, so it should stop |
| doc-writer | 50 | reads sources, writes several files, updates the log |
| surveyor | 60 | bulk reading is its job; read-only, so a high cap carries little risk |
| debugger | 60 | reproduce, isolate, report; no edits |
| debugger-strong | 80 | escalation tier; re-tests the prior investigation's assumptions first |
| reviewer | 80 | re-runs verify scripts and mutation-tests them (REVIEW-CHECKLIST item 8) |
| qa-engineer | 80 | writes many fixtures and runs them |
| implementer | 100 | the largest ordinary task: code, tests, docs, verify script, log |
| implementer-strong | 120 | escalation tier: the same work plus reading the failure history |
| core-surgeon | 120 | fork internals; the tier where an early stop is cheapest to recover from |

**Meaning of a hit:** the run returns partial output. The manager handles it exactly like a §8 budget
overrun: stop, read the log, report to Ludwig, no silent retry. A hit is information about the spec or the
cap, never something to push through.

## Context to load (exhaustive)
- ADRs (INDEX.json lookup 2026-10-14): 0056 English everywhere, 0103 boring and restartable, 0115 measure
  outcomes, 0116 ADR compliance gates, 0117 dependency graph and contracts. The diff touches nothing under
  `docs/decisions/`.
- Files: `CLAUDE.md`, `docs/manager/MANAGER.md` (§2b, §3b, §5, §8), `REVIEW-CHECKLIST.md`, `SPEC-CHECKLIST.md`,
  `TASK-TEMPLATE.md`, `ROUTING.md` (all in `docs/manager/`), `.claude/agents/*.md`, `.claude/settings.json`,
  `docs/tasks/047-arcane-practices.md`, `docs/tasks/052-vault-triggers-and-guard.md` (to merge on top of its
  edits), the mission log sections "For Ludwig — task 047 (2026-10-14)" and "Token guard lifted by Ludwig".
- Arcane reference (read in place; untracked, never copied into git): `~/wom/docs/tasks/inbox/arcane-reference/`
  (`CLAUDE.md`, `agents/verifier.md`, `agents/implementer.md`, `settings.json`).

## Size (Q4, applied to this task)
Source files (non-documentation, non-test): **0**. Changed source lines: 0. `.claude/settings.json` takes one
`env` key; `048-verify.sh` is excluded by the rule. Reading list: 13 entries, **over the cap of 10**.
**Justification:** the edit set is a dozen doctrine files, each of which must be read in full so the new text
does not contradict the old. Splitting would put two tasks on the same files (MANAGER.md, the agents) and
force sequencing without reducing what must be read. Ludwig's spec approval accepts this justification.

## Design

### 1. Size caps (Q4 ★B) — the rule text
SPEC-CHECKLIST gets a new item 5b and TASK-TEMPLATE gets a `Size` section. The rule, as it must read:
- A task is *within the soft cap* when it has **at most 5 source files, at most 300 changed lines, and at
  most 10 files in its reading list** (its "Context to load" section).
- **Counting:** source files and changed lines count code and configuration the task creates or modifies.
  **Tests, fixtures and `NNN-verify.sh` scripts are excluded from both counts.** Documentation files are
  excluded from the source-file and line counts (assumption, see Questions) but still count toward the
  reading list. Lines = added + deleted, from `git diff --numstat`.
- **Exceeding any one number is allowed only with a written justification in the task file, under a `Size`
  heading, at the spec gate.** It is a warning that needs a reason, not a hard stop (Ludwig chose ★B over
  A). A spec over the cap without the justification fails the gate.
- Splitting stays the default answer; the justification must say why splitting is worse.

### 2. Nesting off (Q2 ★A)
- `.claude/settings.json`: add `"env": {"CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH": "1"}`. This is the only
  `settings.json` change in this task; merge it on top of what 052 put there.
- Each of the ten agent files gets `disallowedTools: Agent` in its frontmatter. The four agents with an
  explicit `tools:` allowlist that already omits `Agent` (debugger, debugger-strong, reviewer, surveyor) get the
  line too: the allowlist alone is not what Ludwig chose.
- MANAGER.md §3b gains one paragraph: nesting is off by configuration, so "one manager, flat roster" is
  enforced rather than described; a mission that needs a second manager starts a second session.

### 3. Blind review (Q3 ★A)
- The new `reviewer.md` paragraph reads: (1) read the task file's Objective, File scope and Acceptance criteria and
  `git diff main...HEAD`; **(2) write down findings from those alone, before opening the task log, and put
  them first in the verdict under the heading "Findings formed before reading the log"**; (3) only then
  read the log, reconcile, and mark each finding confirmed / retracted / new.
- REVIEW-CHECKLIST.md gets **one preface line added above item 1 and nothing else**: the independent pass
  (spec + diff, findings written down) comes before the log is opened, so item 7 (log truthful) is checked
  after it. Item 7 itself is untouched. One sentence gives the reason: the log is the author's account, and a
  reviewer anchored on it inherits its blind spots.
- `reviewer.md`: the method is added as a **new paragraph after the existing body**; no existing sentence is
  edited or removed.
- Stated limit: the order cannot be proven mechanically. It is made visible by the heading, and the manager
  returns any verdict that lacks the section.
- Observation, not changed here: `reviewer.md` says the reviewer writes the verdict into the task log, but
  its `tools:` allowlist has no Write or Edit. The verdict therefore reaches the log through the manager.
  The new section travels in the same way. Flagged for Ludwig, not fixed (outside this decision).

### 4. Turn caps (Q5 ★A)
Each agent file gets `maxTurns: N` from the table. MANAGER.md §8 gains one bullet: reaching `maxTurns` is a
budget stop, handled like an exceeded effort budget. ROUTING.md gets the table.

### 5. Log-entry check, no handover file (Q6 ★B)
MANAGER.md §5 gains: after every subagent run the manager runs `tools/manager/check-log-entry.sh`; a
non-zero exit means the run is not accepted until the agent, or a fresh one, writes the entry. **The script
is built in task 049**, so it does not exist when 048 merges. The doctrine text therefore says: "until task 049
merges, the manager counts the dated entries in the task log before and after the run by hand and logs both
counts". The path is cited with that caveat, as §8b.5 requires. No `docs/handover/` file is introduced and
Arcane's `require-handover` SubagentStop hook is not adopted (Arcane's own hooks README says it arrives after
the final report: a notice, not enforcement).

### 6. Token guard text (Q-T ★B)
- **CLAUDE.md rule 0 and MANAGER.md §8 keep their text unchanged.** One marker line is added at the top of
  each block: `**SUSPENDED by Ludwig 2026-10-14 until he revokes it** ("Glöm token kontrollen, du kan
  framgent ignorera den regeln och alla subagents också", mission log, 2026-10-14). The text below is
  retained and takes effect again the moment he revokes the suspension.`
- While suspended, the manager and agents skip the usage checkpoints. No one deletes or edits the rule.
  Revocation is Ludwig's alone, in writing; the marker is then removed by a small task that cites his words.
- **Waivers of 2026-10-14/15, recorded as historical, not standing.** MANAGER.md §8 gets a subsection
  "Waivers recorded as historical", citing its source as `session/8-status:docs/tasks/MISSION-worldofmodcraft-site-v1-log.md`,
  section "Ludwig's rulings, 2026-10-14 evening" (an unmerged branch: view with `git -C ~/wom show
  session/8-status:docs/tasks/MISSION-worldofmodcraft-site-v1-log.md`; if it has merged by then, cite the file on main).
  Three entries, each quoting the log verbatim (read 2026-10-15) and ending "expired; not a precedent; the
  section's text is unchanged and in force":
  (a) **§7:** "Overnight §7 waiver (2026-10-14/15 only): the manager may merge PRs that touch CI security checks
  (registry CI, tasks 007/039) when the independent review is PASS and verification is green. Still Ludwig-only:
  signing and keys, takedowns, `docs/decisions/`, mission specs, and doctrine."
  (b) **§8:** "Overnight §8 waiver: a blocked chain is parked, with its question written under "For Ludwig", and
  independent chains continue. The session halts fully at five open Ludwig items."
  (c) **§5:** "2026-10-14, Ludwig: "Ignorera din kontextgräns för inatt". The manager's planned-handover
  thresholds (MANAGER.md §5, 30 % soft / 40 % hard) are suspended for tonight only. ... Compaction caution (§5.5)
  still applies".
  The doc-writer re-reads the log at those lines and copies exact text; if it differs from the above, the
  log wins and the difference is noted in the task log.

## File scope (declared)
`CLAUDE.md` (rule 0 marker only), `docs/manager/MANAGER.md` (§2b pointer to the size rule, §3b, §5, §8
including the waivers subsection), `docs/manager/REVIEW-CHECKLIST.md`, `docs/manager/SPEC-CHECKLIST.md`,
`docs/manager/TASK-TEMPLATE.md` (a `Size` section), `docs/manager/ROUTING.md` (maxTurns table, nesting off),
`.claude/agents/{core-surgeon,debugger-strong,debugger,doc-writer,implementer-strong,implementer,qa-engineer,reviewer,scaffolder,surveyor}.md`
(frontmatter lines `maxTurns` and `disallowedTools`; `reviewer.md` body also), `.claude/settings.json` (the
`env` key only), `docs/tasks/048-verify.sh`, this file's log.

## Acceptance criteria
Script-verified by `docs/tasks/048-verify.sh` (its output pasted in the log) unless marked **live** or **human**.
1. **Nothing weakened.** Against main (with 052 merged), `git diff main...HEAD --numstat` shows zero deleted
   lines in CLAUDE.md, REVIEW-CHECKLIST.md, SPEC-CHECKLIST.md, ROUTING.md, MANAGER.md and every agent body.
   The only allowed deletions are frontmatter lines that the table replaces, and there are none expected;
   any other deletion must be named in the log and approved. The token-guard blocks are byte-identical to
   main's apart from the added marker line.
2. **Nesting off in settings.** `.claude/settings.json` parses as JSON, `env.CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`
   is `"1"`, and 052's PreToolUse entry is still present (positive control).
3. **All ten agent files** have `disallowedTools: Agent` and an integer `maxTurns` equal to the table. The
   script counts exactly ten files and fails on any other number (a loop over zero files is a failure,
   §2c rule 1).
4. **Token-guard marker.** CLAUDE.md rule 0 and MANAGER.md §8 each contain the `SUSPENDED by Ludwig 2026-10-14`
   line, and the original sentence "Ludwig's Claude Max subscription is shared" is still present after it.
5. **Waivers.** MANAGER.md §8 has the "Waivers recorded as historical" subsection with three entries naming
   §7, §8 and §5, each containing the word "expired" and a verbatim quotation. A script check compares each
   quoted fragment to the source text on `session/8-status` (or main) and fails if a fragment is absent there.
6. **Size caps.** SPEC-CHECKLIST.md has item 5b with the numbers 5, 300 and 10 and the sentence that tests,
   fixtures and verify scripts are excluded; TASK-TEMPLATE.md has the `Size` section.
7. **Blind review text.** `reviewer.md` and REVIEW-CHECKLIST.md both contain "Findings formed before reading
   the log" and say it comes first in the verdict.
8. **Live, tool name (before the agent files are edited):** the sub-agents doc and a live `claude` session
   confirm the tool is named `Agent`; the log pastes the evidence. Closes unverified (a).
9. **Live, after merge, in a fresh session (manager + Ludwig):** (i) a probe implementer is told to spawn a
   subagent and the attempt is refused, denial shown; (ii) a copy of an agent with `maxTurns: 2` is run and
   returns partial output. Both show the fields do something, not merely parse. If (i) shows nesting still
   works, the env var needs a restart or is not honoured, and the task reopens.
10. **Mutation proof.** `048-verify.sh --mutate` re-runnably turns checks 1-7 red, one mutation each: delete
    a line from MANAGER.md (the forbidden-deletion path of check 1); set the env value to "3"; remove
    `disallowedTools` from one agent; change one `maxTurns`; **delete one agent file (count becomes 9) and,
    separately, copy one to make 11: the count==10 check must redden both ways**; drop the marker line;
    drop one waiver entry; alter one quoted waiver fragment (source comparison must redden); drop the `300`;
    drop the blind-review phrase.
    The unmodified tree passes (positive control) and the script passes in a fresh clone (§2c rule 4).
11. **Human:** Ludwig approves the merge (§7). AC8-9 are not script-verified, and the log says so.

## Forbidden here
- Deleting, rewording or weakening any existing rule, in particular rule 0 and §8: the marker line is the
  only change to those blocks. "Keep the text" means byte-identical.
- Editing `docs/decisions/`, the hook scripts (task 049) or the vault files (task 052).
- Writing the check-log-entry script here, or stating in doctrine that it exists before 049 merges.
- Choosing `maxTurns` numbers other than the table's, or leaving an agent out because its number "does not
  matter".
- Recording the night waivers as standing, or in a form a later manager could cite as precedent.
- Starting before 052 is merged: rebase onto main after 052 and edit on top of its changes.
- Rewording or removing any existing sentence of `reviewer.md` or REVIEW-CHECKLIST item 7 (additions only).
- Stating in doctrine that nesting "is off" before AC9(i) has shown it live; until then it says "configured off".

## Dependency graph and sequencing
Node: the doctrine and agent-definition layer. No new edge: the task changes what the manager and agents are
told and bounds their runs, and invokes no new component contract. The Q6 text names the task 049 script as a
forward reference, which is a sequencing note, not a contract edge. Order: **052 → 048 → 049**.

## Deliverables
The edited files, `048-verify.sh` with its output pasted in the log, the AC8/AC9 evidence, the log current.

## Questions  (agent-maintained; see MANAGER.md 8b)
- Q (for Ludwig): rule 0 says only Ludwig can lift the token guard "explicitly, in writing, for a specific
  moment", but his words ("Glöm token kontrollen, du kan framgent ignorera den regeln och alla subagents
  också") are open-ended ("framgent"). The marker therefore says "until he revokes it" (Q-T ★B), which is the
  reading he approved, but it sits in tension with rule 0's own sentence. | options: A keep both texts as they
  are and let the marker govern / B add one sentence to rule 0 saying a lift may be open-ended when Ludwig says
  so / C replace the suspension with a dated one he renews | assumed: A | built on assumption: the marker
  line only.
- Q: Are documentation files excluded from the Q4 "source files / changed lines" counts? | options: A excluded
  / B counted | assumed: A (otherwise every doctrine task exceeds the cap) | built on assumption: the Size rule
  text and this task's Size section.

---
# Task 048 log  (append-only, updated continuously by the executing agent)
- 2026-10-14 manager: spec finalised from the drafts, task 047, task 052 and the Arcane reference. Decisions
  Q2-Q6 and Q-T are Ludwig's ★ answers. Not started; waits for 052 merged and the spec gate.

---
# Task 048 log
- 2026-10-15 doc-writer (night run): agent frontmatter (disallowedTools, maxTurns) and the reviewer.md blind-review
  paragraph are done. `.claude/settings.json` has the `env` key; JSON syntax forced one `}` → `},` change.
  These are **uncommitted in the worktree on purpose**.
- **Blocked:** two Bash edit batches touching CLAUDE.md, MANAGER.md and the checklists were **denied by the Claude
  Code auto-mode classifier ("Instruction Poisoning")**. The agent did not retry and sought no other route
  (CLAUDE.md rule 11's denial principle, applied). The manager did not make the edits itself and changed no
  permission rule; doing either would launder the denial.
- **Parked for Ludwig.** The doctrine edits need either Ludwig making or approving them in an interactive
  session, or a permission decision that is his alone. 049 is stacked on 048 and is parked with it.
- 2026-10-15: Ludwig chose option A ("Stjärna på allt"). The manager wrote the doctrine additions in the interactive
  session with Ludwig present, commit after 043fc2a. `git diff --numstat origin/main` shows 0 deleted lines in
  CLAUDE.md, MANAGER.md, REVIEW-CHECKLIST.md, ROUTING.md, SPEC-CHECKLIST.md and TASK-TEMPLATE.md. Waiver quotes were
  copied from main's mission log. `048-verify.sh` is delegated next.

- 2026-10-15 doc-writer: `docs/tasks/048-verify.sh` written (commit a2c0cb1). Run in a fresh clone (`git clone` of the worktree, `origin/main` as base), `--mutate`, exit 1 because of one real AC5 gap, below. AC1-AC4, AC6, AC7 pass; AC10 mutations all redden (positive control = clean tree, 3 FAIL lines, all c5b). **AC8, AC9 (live) and AC11 (human) are not script-verified.** Doctrine not touched.
  - **AC5 FAILS against the committed doctrine:** the spec wants the word "expired" in each of the three waiver entries; MANAGER.md puts it only in the subsection preamble ("each is **expired; not a precedent...**"). Quotations themselves match main verbatim. Fix is a doctrine edit (manager/Ludwig), not made here.
  - Note AC7: REVIEW-CHECKLIST says the independent pass "comes first"; it does not literally say findings come first in the verdict (reviewer.md does). Script checks the checklist for "comes first".
  - Tail of the fresh-clone run:
```
== clean tree: 3 failing check line(s)
== mutations: each runs on a temp copy; the expected check must show a FAIL line that the clean tree did not have
ok   mutation 'delete a line from MANAGER.md' -> red: FAIL c1: docs/manager/MANAGER.md has 1 deleted/changed lines vs origin/main
ok   mutation 'alter one char inside the rule-0 block' -> red: FAIL c1: CLAUDE.md has 1 deleted/changed lines vs origin/main
ok   mutation 'env value set to 3' -> red: FAIL c2: settings env: AssertionError: env value is not the string 1
ok   mutation 'remove 052's PreToolUse entry' -> red: FAIL c2: PreToolUse entry missing: KeyError: 'PreToolUse'
ok   mutation 'remove disallowedTools from one agent' -> red: FAIL c3: debugger lacks 'disallowedTools: Agent' in frontmatter
ok   mutation 'change one maxTurns' -> red: FAIL c3: reviewer maxTurns is not 80 (got: maxTurns: 81)
ok   mutation 'delete one agent file (count 9)' -> red: FAIL c3: agent file count is 9, expected 10
ok   mutation 'copy one agent file (count 11)' -> red: FAIL c3: agent file count is 11, expected 10
ok   mutation 'drop the CLAUDE.md marker line' -> red: FAIL c4: CLAUDE.md has no SUSPENDED marker
ok   mutation 'drop the MANAGER.md marker line' -> red: FAIL c4: docs/manager/MANAGER.md has no SUSPENDED marker
ok   mutation 'drop one waiver entry (§8)' -> red: FAIL c5a: entries found for sections ['5', '7'], expected 5, 7, 8
ok   mutation 'alter one quoted waiver fragment' -> red: FAIL c5c: §8 quotation not found verbatim in the source log: 'Overnight §8 waiver: a blocke
ok   mutation 'drop the 300' -> red: FAIL c6: 5b does not name '300 changed lines'
ok   mutation 'drop blind-review phrase (reviewer.md)' -> red: FAIL c7: reviewer.md lacks 'Findings formed before reading the log'
ok   mutation 'drop blind-review phrase (checklist)' -> red: FAIL c7: REVIEW-CHECKLIST lacks 'Findings formed before reading the log'
== mutations: all reddened
== AC8, AC9 (live) and AC11 (human) are not covered by this script
```
- 2026-10-15 manager, after review round 1 (3 blocking findings):
  - (1) "Nesting is off" in MANAGER §3b and ROUTING is reworded to "configured off", pending AC9's live proof.
  - (2) **AC8 evidence, collected AFTER the agent files were edited** (an order deviation, stated plainly): in
    this manager session (Claude Code 2.1.300, `claude --version` → `2.1.300 (Claude Code)`), the subagent tool
    available to the manager is named **`Agent`**, which the session's own tool list shows. The sub-agents doc
    agrees: "In version 2.1.63, the Task tool was renamed to Agent." So `disallowedTools: Agent` names the real
    tool. The edit order does not change the result.
  - (3) Scope: commit 93e84c1 carries the **spec-approved** 048 and 049 task files onto this branch, replacing their
    drafts on main. That is ledger maintenance by the manager (task files travel with the work), not task output.
    Ludwig can ask for it to be split out.
  - Non-blocking: the §2b grammar is fixed, and sources are added for the version facts.
  - Doctrine files still show 0 deleted lines vs main.
