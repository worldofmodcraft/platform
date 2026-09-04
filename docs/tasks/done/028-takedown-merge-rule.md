# Task 028: Takedowns require Ludwig — the human gate as doctrine where it cannot yet be physics

- **Mission:** SITE-V1 (doctrine) — **Status:** spec-approved (manager, 2026-09-03)
- **Agent / model:** manager (doctrine edit, no production code)
- **Budget:** small
- **Branch / worktree:** task/028-takedown-merge-rule / `~/wt/platform-task-028`
- **Graph:** none. Governs how the manager may merge a PR that exercises edge **E4**'s takedown
  carve-out (`contracts/append-only.rules.md`).

## Approval
Ludwig, in session, 2026-09-03, verbatim: *"add a standing rule to the doctrine's 'always requires
Ludwig' list (§7): takedown PRs — the one mutation that removes value — are never merged by the
manager on its own authority, regardless of technical ability. My explicit written approval in the
session, referenced in the PR, before merge. Cheap, honest, and it restores the human gate as
doctrine where it can't (yet) be physics. Revisit with option 3's signed record when phase 3 brings
accounts beyond womcraft."*

## Why this exists
ADR-0041 requires that a published version can become `removed` on legal grounds. Task 006's
contract permits exactly that one in-place mutation, and Ludwig decided its authorisation is the
merge gate rather than a new signed-record format — the boring solution, using controls we already
have (ADR-0103).

The independent re-review of task 006 then checked that premise against reality and found it false:
`worldofmodcraft/registry` has one collaborator, `womcraft` (admin), which is also the identity the
manager session authenticates and merges as — `merged_by: womcraft` on registry PR #1. So the merge
gate does not currently distinguish "Ludwig decided" from "an agent merged", and the carve-out that
lets a version be relabelled `removed` sits behind a gate an agent can open.

The decision was sound; its premise was wrong. Rather than weaken the carve-out ADR-0041 mandates,
or add machinery no ADR specifies, the gap is closed where it actually is — in who may press merge.

## File scope (declared)
- `docs/manager/MANAGER.md` (§7 and §8's stop-condition list)
- `docs/tasks/028-takedown-merge-rule.md` (this file)

## Acceptance criteria
1. §7's "always requires Ludwig" list includes a takedown.
2. §7 states the mechanics without ambiguity: explicit written approval, given in session,
   referenced in the PR, **before** merge — and that this holds *regardless of technical ability*,
   which is the whole point, since the ability exists.
3. §7 records why the premise needed correcting (the merge gate is the `womcraft` account, which
   the manager also acts as) rather than merely asserting the rule, so a later session cannot
   "simplify" it back out on the grounds that only Ludwig merges anyway.
4. §7 names what replaces this rule and when: the phase-3 signed takedown record, at which point the
   guarantee stops depending on who holds an account. Replaced, not supplemented.
5. §8's absolute stop conditions include merging a takedown PR without that approval — so the
   failure is a halt-the-session event, not a judgement call.
6. `contracts/append-only.rules.md` (task 006, round 2, on `task/006-contracts`) references this
   rule, so contract and doctrine cannot drift apart. Cross-checked, not assumed.

## Forbidden here
- Changing the takedown carve-out's *shape* rules — those live in the contract and are task 006's.
- Editing `docs/decisions/` (MANAGER.md §3.1). This rule is doctrine, not a new ADR; if it ought to
  become one, that is Ludwig's call and a separate task.
- Raising required approvals or adding CODEOWNERS on the registry. Ludwig considered and declined
  that option: with one human maintainer, an approval he cannot give himself would make the
  protection escape hatch routine — task 013's reasoning, unchanged.

---
# Task 028 log

- 2026-09-03 spec approved (manager, solo; small doctrine edit with Ludwig's verbatim approval above).

## Acceptance criteria — demonstrated

**1-4. §7 now carries the rule.** Real output, not a description of it:
```
$ grep -n "takedown" docs/manager/MANAGER.md
92:Default (pending Ludwig's answer, OPEN-QUESTIONS §Q4): the manager may merge a task branch **only when all of the following hold** — review checklist fully green, all acceptance criteria demonstrated, tests pass in the worktree, docs updated, task log complete. Anything touching `docs/decisions/`, mission specs, signing/keys, CI security checks, deletion of data, or **a takedown** always requires Ludwig's explicit approval before merge, regardless of checklist state.
94:**Takedowns are never merged on the manager's own authority** (Ludwig, 2026-09-03). A takedown is
99:something the gate can currently prove. Therefore, **regardless of technical ability**: a takedown
105:supplemented, when the checker can require a signed takedown record in the PR — the phase-3 upgrade
113:- Absolute stop conditions (halt session, do not attempt to fix): signing key or secrets exposed in any output; an agent modified files outside its worktree; main differs from expected; registry history rewritten; **a takedown PR merged without Ludwig's written approval** (§7).
```
Line 92 is the always-requires-Ludwig sentence, now including a takedown. Lines 94-105 are the
paragraph giving the mechanics ("regardless of technical ability", written approval in session,
referenced in the PR, before merge), the corrected premise (the merge gate is the `womcraft`
account, which the manager also acts as), and the replacement condition (the phase-3 signed
takedown record replaces this rule rather than supplementing it). Line 113 is criterion 5.

**5. §8's stop-condition list.** "a takedown PR merged without Ludwig's written approval (§7)" now
sits beside secrets exposure, out-of-worktree modification, unexpected main, and rewritten registry
history — the company it belongs in.

**6. Cross-reference to the contract.** Task 006's round-2 fix brief instructs the contract to
reference this doctrine rule; the contract side is being written on `task/006-contracts` and is
verified there, not asserted here. Recorded as a dependency to confirm before that branch merges.

## Status
Criteria 1-5 applied in this branch; criterion 6 is confirmed on the other branch before it merges.
