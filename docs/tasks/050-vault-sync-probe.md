# Task 050: Prove that a note written from WSL reaches Obsidian on Windows and the phone

- **Mission:** tooling (task 047, part C, step 1) — **Status:** in-progress (spec-approved by Ludwig, in session, 2026-10-14)
- **Agent / model:** none. The manager runs the shell steps and Ludwig confirms what he sees. No production code is written.
- **Budget:** small (one sitting, about 15 minutes of Ludwig's time)
- **Branch / worktree:** task/047-arcane-practices (this file and its log only)

## Objective
We know, from observation instead of assumption, whether a file written from WSL into
`$WOM_VAULT` through `/mnt/d` (1) appears in Obsidian on Windows while Obsidian is running,
(2) reaches the phone through Self-hosted LiveSync, (3) updates on both when it is replaced with
temp-file-plus-rename (the write method 051 will use), and (4) stays hidden when its name starts
with a dot (051's temp files will). Task 051 is only dispatched if 1–3 hold. If one of them fails,
the design is reconsidered with Ludwig before any code exists.

**Why this is first:** the whole of part C rests on the draft's unverified assumption (MANAGER.md
§3.6) that Windows Obsidian notices files written through WSL's `/mnt/d` mount.

## Context to load (exhaustive)
- `docs/tasks/047-arcane-practices.md`
- Vault guide `Meta/Agentarbetssätt.md` §9 (in the vault; read-only): LiveSync pushes only while
  Obsidian runs on the PC.
- `docs/dev-environment.md` (WSL/Windows cooperation)

## File scope (declared)
- In the vault folder `$WOM_VAULT` (value given by Ludwig and kept out of git, pending Q-P;
  Ludwig 2026-10-14): create `WoM Sync Probe.md` and `.wom-probe-hidden.md`. Nothing else.
- In the repo: this file's log.

## Procedure and acceptance criteria
Preconditions: Obsidian is running on the Windows PC with the SELM vault open, and the phone app is
installed with LiveSync.

0. **Baseline.** The manager runs `stat -c '%n|%s|%Y' -- "$WOM_VAULT"/*.md` and pastes the output into
   the log. This uses metadata only and does not open or read the three hand-written notes.
1. **Create.** The manager writes `.wom-probe-tmp`, then renames it to `WoM Sync Probe.md` (`mv`, same
   directory). Content: frontmatter `generated: true`, plus the line `probe v1 written <UTC time> from WSL`.
   - **AC1a (Ludwig):** within about one minute, without restarting Obsidian, the note is visible in
     Windows Obsidian and shows `probe v1`. Ludwig reports the elapsed time.
   - **AC1b (Ludwig):** the note shows `probe v1` on the phone (after *Replicate now* if needed).
2. **Replace.** The manager writes `.wom-probe-tmp` again with `probe v2 …` and renames it over the
   existing note.
   - **AC2a / AC2b (Ludwig):** Windows Obsidian, and then the phone, show `probe v2` without a restart.
3. **Hidden file.** The manager writes `.wom-probe-hidden.md`, a dotfile with the text `must not sync`,
   and leaves it in place.
   - **AC3 (Ludwig):** it does **not** appear in Obsidian's file list on Windows or on the phone.
4. **Hand-written notes untouched.** The manager repeats step 0.
   - **AC4 (script-checkable):** the three hand-written notes have the same name, size and mtime as at
     baseline. Shown with `diff` of the two outputs.
5. **Cleanup.** Ludwig deletes `WoM Sync Probe.md` from inside Obsidian, so the deletion travels through
   LiveSync properly. The manager removes `.wom-probe-hidden.md`. That file never synced, so removing it
   through `/mnt/d` is safe.

Verification type: AC1–AC3 are **human** (Ludwig's eyes). AC4 is a two-command diff pasted into the log.
No `050-verify.sh` is shipped: this task has no reusable command-based criteria. Stated per
SPEC-CHECKLIST item 8.

## On failure
- AC1a fails, but the note appears after an Obsidian restart: WSL writes are not seen live. 051 would
  then need a Windows-side writer (for example `powershell.exe` writing the files) or a manual
  "reload" step. That design question goes to Ludwig. Nothing is built.
- AC1b fails while AC1a holds: this is a LiveSync problem, outside WoM's scope. Ludwig decides.
- AC3 fails: 051's temp files must live outside the vault folder. The rename stays on the same
  filesystem (`/mnt/d`).

## Forbidden here
- Reading, opening, copying, hashing or writing the three hand-written notes, `wiki/`, `inbox/`, or anything
  outside the project folder. `stat` (metadata only) is the only permitted access.
- Writing any file other than the two named above.
- Installing anything in WSL, including Obsidian.

## Dependency graph
Not a SITE-V1 component. Part C adds one tooling node, `vault-projection`, with one edge
repo → vault. Its contract is the note-format document 051 creates (`docs/tools/vault-projection.md`).
This task only tests the transport underneath that edge.

---
# Task 050 log
- 2026-10-14 manager: spec written; gate run (objective observable, criteria demonstrable, scope
  minimal, traps listed, no artefact justified). Waiting for Ludwig's approval.
