# Task 065: `entry.schema.json` enforces the `key_id` format that `signature-format.md` defines

- **Mission:** SITE-V1 (D1/D2 contract consistency) — **Status:** spec-ready, pending independent spec review
  (signing-adjacent contract; SPEC-CHECKLIST preamble) — written 2026-10-15, session 10. Not dispatchable before 064
  and 007b merge.
- **Repos:** registry (contract), then site (re-sync). **Agent / model:** implementer / sonnet. **Budget:** small–medium
  (≤ 2 agent-sessions: one per repo)
- **Branches / worktrees:** registry `task/065-entry-schema-key-id` / `~/wt/registry-task-065`; site
  `task/065-resync-entry-schema` / `~/wt/site-task-065`, both cut from their `origin/main` at dispatch.
- **Graph:** edges E8 (pipeline write-back) and E10 (site read side) via `entry.schema.json`; E9 (`signature-format.md`)
  is the source of the rule and is **not** changed. No new edges.

## Objective
`contracts/signature-format.md` ("Deriving `key_id`", lines 128–168 at `ac22c8f`) says `entry.json`'s `key_id` holds
exactly 16 uppercase hexadecimal characters (the reversed key-id bytes). `contracts/entry.schema.json` (line ~85–88)
only requires a non-empty string and its description defers the encoding. Found in task 007a's fix round 1
(2026-10-15): `key_id = "platform-2026-01\n"` is contract-valid today. After this task:
1. `entry.schema.json`'s `key_id` carries `"pattern": "^[0-9A-F]{16}$"` and its description cites
   `signature-format.md` "Deriving `key_id`" instead of deferring.
2. Every example and fixture that is meant to be valid uses a conforming `key_id`; every fixture meant to be invalid
   still fails, now for the reason it was written for. Known non-conforming values at `ac22c8f` (measured at the gate):
   `tests/registry/support.py` lines 34 and 93 (`"platform-2026-01"`, used as valid), `tests/contracts/test_contracts.py`
   line 337 (`"k"`), `tests/registry/test_append_only.py` line 216 (`""`, meant invalid — stays); the worked-example JSON
   in `contracts/append-only.rules.md` lines 360, 481, 498, 522 (`"platform-2026-01"`), which is also embedded in the
   T1 text pin `docs/tasks/057-pinned-sections.json`; site `fixtures/registry/mods/fixture.campfire-tales/entry.json`
   (3×) and `fixture.lantern-quests/entry.json` (1×) (`"FIXTURE0000000A"`, 15 characters, not hex). 66 occurrences of
   `E7A1B2C3D4E5F607` already conform. Pipeline code conforms (`tools/pipeline/signing.py` `pubkey_key_id`).
   **Manager's decision (spec review round 1, finding 3):** the four rules-document examples are updated (value only) and
   057's pin refreshed to match, because a contract document whose examples fail its own schema is a contradiction; this is
   the only edit to `append-only.rules.md`, and no rule text changes.
2b. **One deliberate assertion reversal (manager's sign-off, spec review round 1, finding 2):**
   `tests/registry/test_hardening.py` lines 48–53,
   `test_f1_signature_and_key_id_carry_no_pattern_so_a_trailing_newline_is_contract_valid`, asserts that `key_id =
   "platform-2026-01\n"` is accepted, because at the time no rule existed. This task creates that rule from
   `signature-format.md`, so the test is split: `signature` keeps its accepted assertion unchanged; `key_id` moves to a new
   test asserting rejection, citing task 065 and `signature-format.md` "Deriving `key_id`". This is a contract change, not a
   weakening (the resulting suite rejects strictly more), and it is the only assertion that changes direction.
3. The site's vendored `schemas/entry.schema.json` equals the registry's after the change, via the site's own
   `npm run sync-schemas -- <registry checkout>` (task 041's mechanism), and `npm run check-schemas` passes.
   **Measured at the gate:** the site copy already differs from registry `main` (task 057 changed the registry copy
   after 041's sync), so this re-sync also carries 057's version-object states to the site.
4. `signature` (multi-line minisign text): assessed, not invented. If `signature-format.md` states a shape a JSON Schema
   pattern can express exactly, propose it in the log as a question for the manager; do not add it in this task.

## Context to load (exhaustive)
This file; registry `contracts/entry.schema.json`, `contracts/signature-format.md` ("Deriving `key_id`" and the
verification rules list), `contracts/examples/entry/`, `tests/contracts/test_contracts.py`, `tests/registry/support.py`,
`tests/registry/test_append_only.py`, `docs/tasks/057-corpus.py` + `057-verify.sh` (V1 Ajv agreement);
site `scripts/sync-schemas.mjs`, `schemas/README.md`; platform `docs/manager/MANAGER.md` §2c, §3.5, `OPERATIONS.md`.

## Acceptance criteria — `docs/tasks/065-verify.sh` (registry), whose output the log pastes
1. **Red first:** a test asserting `"platform-2026-01"`, `"e7a1b2c3d4e5f607"` (lowercase), `"E7A1B2C3D4E5F60"` (15),
   `"E7A1B2C3D4E5F6071"` (17) and `"E7A1B2C3D4E5F607\n"` are rejected for a `published` and a `removed` version — committed
   before the schema change and shown failing on that commit.
2. On HEAD those are rejected by `tests/contracts/schema_check.py`, 007a's strict check and Ajv (057 V1 corpus extended);
   `E7A1B2C3D4E5F607` accepted by all three.
   The trailing-newline value is asserted explicitly against **both** `tests/contracts/schema_check.py` and 007a's
   strict check, so a regression of task 064 shows red here.
3. Fixture and example value changes are value substitutions only; the single assertion reversal is objective item 2b.
   No other assertion is removed, weakened or reversed (§3.5); the diff of each test file is shown in the log.
4. Every registry verify script passes on HEAD: 007a, 007b, 032, 034, 057 (including its T1 pin, refreshed), 062 (which
   runs the closed 006 checks over their pinned ranges), 064, and 066 if merged.
5. Every JSON example embedded in `contracts/append-only.rules.md` that is meant to be a valid `entry.json` validates
   against the schema: if no such check exists, `065-verify.sh` adds one (extract, validate, count > 0 — a zero count fails).
6. `--mutate`: the pattern removed; lowercase allowed; `{16}` loosened to `{16,}` — each reddens a criterion-1 test.
7. Site PR: the synced `schemas/entry.schema.json` contains the `key_id` pattern (checked); the site's own Ajv 2020
   `strict:true` rejects every criterion-1 value and accepts `E7A1B2C3D4E5F607` against the synced schema;
   `npm run check-schemas -- <registry checkout at the merged commit>` passes and against registry `main` before 065
   fails (shown); `scripts/validate-fixtures.mjs` and `npm run build` pass with the updated site fixtures, and no site test,
   snapshot or verify script still asserts `FIXTURE0000000A` (searched, with the search's positive control shown before the
   change).

## File scope (declared)
Registry: `contracts/entry.schema.json`, `contracts/examples/entry/*` (only if a value must change),
`contracts/append-only.rules.md` (the four example values only), `docs/tasks/057-pinned-sections.json` (pin refresh for
that change only), `tests/contracts/test_contracts.py`, `tests/registry/support.py`, `tests/registry/test_hardening.py`
(item 2b only), new tests under `tests/`, `docs/tasks/057-corpus.py` (new cases), `docs/tasks/065-*.md`, `065-verify.sh`.
`docs/contracts/README.md` (line 27 lists `signature-format.md`) needs no edit unless it describes `key_id`'s shape —
check and log.
Site: `schemas/entry.schema.json` (via the sync script, no hand edit), `schemas/README.md` ("taken on" line),
`fixtures/registry/mods/*/entry.json` (`key_id` value substitution only).

## Forbidden here
Changing `signature-format.md` or any rule text (in any contract) other than `key_id`'s shape in the schema; adding a
`signature` pattern (objective item 4); hand-editing the site's schema copy; touching signing keys or secrets (CLAUDE.md
rule 11); weakening any test; any assertion reversal other than item 2b.

## Before dispatch (manager)
Cut the registry branch from `origin/main` **after 064 and 007b have merged** (064 also edits `057-corpus.py`); fetch and
fast-forward the site checkout first (`/home/ludwig/site` was 5 commits behind `origin/main` on 2026-10-15, and the sync
scripts exist only there); re-run the independent spec review only if anything above changes.

## Merge
Registry PR: independent review, then **Ludwig's approval** (signature/key contract — MANAGER.md §7 "signing/keys",
read conservatively). Site PR merges after the registry PR, with the manager's authority once its review passes.

## Dependencies
After **064** (the trailing-newline case relies on ECMA `$` in the Python validators) and **007b** (its tests likely
reuse `tests/registry/support.py`, whose `key_id` value this task changes). Before merging: run `062-verify.sh` and
007b's tests on the PR branch merged onto `main` (OPERATIONS.md, session 9).

---
# Task 065 log
- 2026-10-15 manager (session 9): booked from 007a fix round 1.
- 2026-10-15 manager (session 10): spec written; facts measured at the gate (non-conforming fixture values; site copy
  already stale after 057). Awaiting independent spec review; dispatch after 064 and 007b merge.
- 2026-10-15 manager: independent spec review round 1: FAIL, 7 findings (site fixtures `FIXTURE0000000A`; the
  `test_hardening.py` assertion that must reverse; `append-only.rules.md` examples + 057 pin; sequencing and site fetch;
  site-side Ajv negatives; explicit `\n` assertions on both validators; 006 coverage). All addressed in the spec: findings
  2 and 3 decided by the manager as recorded in objective items 2 and 2b; finding 7 answered — 006's checks run through
  `062-verify.sh` over their pinned ranges (task 062). Round 2 pending.
