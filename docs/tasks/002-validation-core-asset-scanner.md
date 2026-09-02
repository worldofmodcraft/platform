# Task 002: Asset scanner — file typing by magic bytes, whitelist enforcement, GLB payload walk

- **Mission:** SITE-V1 — **Status:** draft (spec-approved once Ludwig confirms the working location, mission log Q5)
- **Agent / model:** implementer / sonnet  (escalation path: implementer-strong, two-strike rule only)
- **Budget:** medium (≤ 3 agent-sessions)
- **Branch / worktree:** task/002-asset-scanner in the registry working copy
- **Graph:** implements node **N4** (`validation-core`), asset-scanning half only. Declares edges
  **E5/E6** (`contracts/validation-report.schema.json`). Touches no other edge.

## Objective
A standalone, offline-runnable scanner exists that walks a directory tree, identifies every
file's real type by **magic bytes**, accepts only whitelisted types, and rejects Blizzard formats
by name — including payloads embedded inside GLB containers. It emits a machine-readable report
against the E5/E6 contract and exits non-zero on any rejection. It is the component that makes
ADR-0004 ("never a single byte of Blizzard data") mechanical rather than aspirational, so it is
written and tested before anything that calls it.

## Context to load (exhaustive)
- ADRs: **0004** (own assets only; whitelist; magic bytes not extensions), **0040** §3 (validation
  order; look inside GLB), **0041** (what the pipeline promises), **0061** (AI-generated assets are
  permitted — the scanner must not try to judge provenance), **0116** (why this becomes a gate),
  **0103** (boring, restartable), **0115** §1 (measure outcomes: counters read reality)
- Files: `docs/architecture/depgraph.md` (N4, E5/E6), `docs/tasks/MISSION-worldofmodcraft-site-v1.md`
  §3 key facts, §4 D2 step 3, §5.2 forbidden shortcuts, §7.1 acceptance
- Survey docs: none required (no existing code to survey)

## File scope (declared)
Inside the registry working copy only:
- `tools/validation/scan_assets.py` (or `.mjs` — the agent picks one runtime and states why in the log)
- `tools/validation/magic.py` — the signature table, data-driven, one row per format
- `contracts/validation-report.schema.json`
- `tests/validation/**` — fixtures and tests
- `docs/validation/asset-scanner.md` — what it accepts, what it rejects, how to run it
Anything outside this list = stop and report.

## Acceptance criteria
Each is demonstrated by a command whose output is pasted into the task log.

1. **Whitelist accepted.** A tree containing valid PNG, OGG, glTF (`.gltf` JSON), GLB, `.md`,
   `.json`, `.lua`, `.txt` scans clean, exit code 0.
2. **Blizzard formats rejected by magic bytes, under innocent extensions.** Files carrying
   DBC (`WDBC`), MPQ (`MPQ\x1a`), BLP (`BLP2`), M2 (`MD20`/`MD21`) and WMO (`MVER`+`MOHD`)
   signatures, each named `screenshot.png`, are every one rejected, and the report names the
   detected format (not merely "unknown"). Exit code non-zero.
3. **GLB interior is walked.** A structurally valid GLB whose BIN chunk embeds a BLP payload is
   rejected with the embedded format named and the chunk offset reported. A GLB whose embedded
   payloads are all whitelisted passes. *(Mission §5.2 forbids skipping this; a scanner that
   passes criterion 2 but not this one is not done.)*
4. **Extension is never trusted, in both directions.** A real PNG named `data.dbc` is
   **accepted** (content is what counts); a real DBC named `art.png` is rejected. Both demonstrated.
5. **Truncated and hostile input fails closed.** Empty file, 3-byte file, a GLB with a chunk
   length exceeding the file size, a GLB with a chunk length that overflows when summed, and a
   deeply nested directory are each handled with a named error and a non-zero exit — never a
   traceback, never a silent pass, never an unbounded read. No `except: pass` anywhere.
6. **Report matches the contract.** Output validates against `contracts/validation-report.schema.json`
   and includes, per rejected file: path, detected format, matched signature offset, and reason.
   The summary counts **files actually inspected** (ADR-0115 §1 — a counter that reads reality),
   and any file skipped for any reason is counted with its reason, never silently dropped.
7. **Runs offline and deterministically.** No network access; same input tree → byte-identical
   report. Demonstrated by two consecutive runs diffed.

## Forbidden here
Beyond MANAGER.md §3.7, task-specific traps:
- Deciding file type from the extension anywhere in the code path (mission §5.2).
- Skipping or stubbing the GLB-internal scan.
- A blacklist-shaped design: the accept set is a **whitelist** (ADR-0004); unknown formats are
  rejected, and "unknown" is a rejection reason, not a pass.
- Reading whole files into memory to find a signature at offset 0 — read the header only; the
  scanner must survive a large file without exhausting memory.
- Judging asset provenance or "AI-ness" — out of scope and contrary to ADR-0061.
- Inventing magic-byte values from memory: every signature row cites its source in a comment. If
  a signature cannot be verified from a real sample or a citable specification, it is marked in
  the log as an assumption, not quietly shipped.

## Deliverables
Scanner + signature table + contract schema + tests/fixtures + `docs/validation/asset-scanner.md`
+ this file's log section current.

## Questions  (agent-maintained; MANAGER.md §8b)
- (none yet)

---
# Task 002 log  (append-only, by the executing agent)
- (not started — awaiting spec approval)
