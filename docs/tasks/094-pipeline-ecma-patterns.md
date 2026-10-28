# Task 094: pipeline modules match schema patterns with ECMA-262 semantics (reuse `ecma_pattern`)

- **Mission:** SITE-V1 (D2 hardening) — **Status:** draft 2026-10-28 (manager, session 13); needs spec review before approval
- **Agent / model:** implementer (model per frontmatter) — **Budget:** small
- **Branch / worktree:** `task/094-pipeline-ecma-patterns` / `~/wt/registry-task-094` — **registry** repo; after 008c (registry #27) merges

## Why
Two reviewer findings from 008c (2026-10-28): (1) 008a's `tools/pipeline/build_version.py` `_PAT_SEMVER` is matched with Python `re`,
whose `\d` accepts non-ASCII digits (`re.fullmatch(build_version._PAT_SEMVER, '1.0.1٣')` is truthy — observed read-only by the 008c
fix-round agent); (2) 008c's `write_back.py` translates only `\d`, leaving Python-vs-ECMA `\s` differences (U+FEFF accepted by `\S`;
U+001C-U+001F and U+0085 refused). The registry already has a full ECMA-262 translator, `tools/registry/schema.py` `ecma_pattern`
(used by the CI gate at schema.py:127). The pipeline should use the same semantics as the gate.

## Objective (draft)
`build_version` and `write_back` match every pattern from `contracts/entry.schema.json` via `ecma_pattern` (or one shared helper built
on it), so the pipeline and the registry gate accept exactly the same strings.

## Acceptance criteria (draft)
1. Red first: tests with `1.0.1٣` for `build_version` and U+FEFF inside `source_archive` for `write_back` fail at the base, pass after.
2. Over-refusal fixed: U+001C and U+0085 inside `source_archive` accepted after (ECMA accepts them), shown red-first.
3. Equivalence: for every pattern the pipeline loads, a generated set of strings (ASCII + the code points above + Arabic-Indic digits)
   gets the same verdict from the pipeline helper and from `schema.py`'s `ecma_pattern` path.
4. Mutations: dropping the translation reddens 1 and 3. `NNN-verify.sh` per MANAGER.md §2c, run in a fresh GitHub clone.
5. 008a and 008c verify scripts still green (one at a time, quiet machine).

## Open for the spec review
- Import direction `tools/pipeline` -> `tools/registry` (does 008a/082 forbid it?), or move `ecma_pattern` to a shared module (wider scope).
- File scope (expected: `build_version.py`, `write_back.py`, their tests, `094-verify.sh`, this file).

---
# Task 094 log  (append-only)
- 2026-10-28 manager (session 13): drafted from 008c's review (findings 1 and the residual-\s decision) and fix-round observation.
