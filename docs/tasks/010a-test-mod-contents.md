# Task 010a: `test:hello-world` mod contents (split from task 010)

- **Mission:** SITE-V1, deliverable **D4** (contents half) — **Status:** spec-approved (manager, 2026-10-25 night, after an
  independent spec review: PASS-WITH-AMENDMENTS, all folded in below; split decided as choice C9)
- **Repo:** platform. **Agent / model:** implementer / sonnet. **Budget:** small (≤ 1 agent-session)
- **Branch / worktree:** `task/010a-test-mod-contents` / `~/wt/task-010a`, cut from platform `origin/main`
- **Depends on:** 008a and 057 only (both merged). Not on 058, 065, 008b or 055.
- **Base text:** `docs/tasks/010-test-mod.md` sections "Findings", "Contents the task produces" and acceptance criteria 1-4, 8
  and 11 apply **as amended here**; where they conflict, this file wins. Criteria 5-7, 9, 10 (runbook `first-publish.md`,
  M4-M7 text, rehearsal) are deferred to **010b**.

## Decisions folded in
- C1: the mod's repository will be `<account>/wom-test-hello-world`. C2: LICENSE copyright "World of Modcraft contributors";
  `ai_assisted = true`. (010's Q2/Q3 closed.)

## Context (≤ 10)
This file; `docs/tasks/010-test-mod.md` (as above); mission D4; ADRs 0119, 0059 §2, 0030, 0049, 0061, 0121; registry files:
`contracts/{entry,page,manifest}.schema.json`, `tools/validation/{scan_assets.py,manifest.py}`, `tools/registry/{cli,ownership_cli}.py`,
`tools/pipeline/build_version.py` (read via `git -C /home/ludwig/registry show origin/main:<path>` or a `git archive`).

## Amendments to 010's text (from the spec review)
1. **Screenshot lists:** `mod.lua` `screenshots` = `welcome.png`, `gallery.png`; `page.json` `screenshots` = the same two (subset;
   equal allowed). `spare.png` is in the tree and in neither list.
2. **Placeholders:** ship `tools/test-mod/fill_placeholders.py` with `mod --account A` (rewrites `mod.lua` `source`) and
   `entry --commit H`. Unfilled tokens must pass the schemas: `https://github.com/OWNER-PLACEHOLDER/wom-test-hello-world` and
   forty `0` characters. `registry-pr/` lives outside the `hello-world/` tree (so the zero commit never enters the archive). The
   script refuses an all-zero or non-40-hex commit and asserts zero tokens remain.
3. **Tool invocations:** `python3 scan_assets.py DIR` (not `-I`; it imports its sibling `magic`); import `read_manifest` (no
   manifest CLI); pin `tests/contracts/schema_check.py`. The verify script `git archive`s registry `origin/main` into a
   `mktemp -d` and prints the commit; it never uses `/home/ludwig/registry`'s working tree.
4. **PNG determinism:** the generator pins `zlib.compress` level 9, no timestamps, fixed dimensions; same-run double generation is
   byte-identical; against the committed PNGs compare decompressed IDAT scanlines / sha256 of raw pixels, not file bytes.
5. **Criterion 3 additions:** staged as `mods/test.hello-world/{entry,page}.json`, the files pass `cli.py classify` (class
   `reserved-namespace`), `cli.py schema`, `cli.py append-only` (empty old root); `ownership_cli` accepts with
   `--author-id 37807560 --membership-status 204` and rejects R7 with 404 (negative control); `entry.owner` equals
   `reserved-namespaces.json`'s `test.owner`, read from the file; the entry has exactly four version keys.
6. **Criterion 1 addition:** `git init` + commit the tree in a temp dir, run `build_version.py --allow-local-source --entry
   <filled entry> --version 1.0.0` with a throwaway `minisign -G -W` key kept in the temp dir; exit 0.
7. **README check:** a script check for a heading, list, table, fenced block, link and an image reference that is one of the
   three PNGs, and the words "permanent pipeline canary".
8. **Criterion 4 rewritten:** a grep finds each token exactly where intended with an asserted non-zero count; after
   `fill_placeholders.py` on a copy with account `sample-owner` and commit forty `a` characters, zero tokens remain and criteria
   1 and 3 still pass.

## Acceptance criteria — `docs/tasks/010a-verify.sh`
010's criteria 1, 2, 3, 4 as amended above; 8 [human] visual review (Ludwig, or the manager on his behalf, recorded); 11:
the script exists, is executable, mutation-tested for 1, 3, 4, passes in a fresh clone from GitHub; own-change checks on fixed
SHAs, live guards on HEAD (REVIEW-CHECKLIST items 8, 12). Every `docs/tasks/*-verify.sh` exits 0, one at a time.

## File scope
`docs/test-mod/hello-world/**`, `docs/test-mod/registry-pr/{entry,page}.json`,
`tools/test-mod/{make_screenshots.py,fill_placeholders.py,tests/**}`, `docs/tasks/010a-test-mod-contents.md` (log),
`docs/tasks/010a-verify.sh`. Not `first-publish.md`, not `site-v1-manual-steps.md`.

## Forbidden
Anything Blizzard-derived; a real key committed; touching the registry repo; credentials of any kind; runbook text.

---
# Task 010a log
- 2026-10-25 manager (session 11 night): split from 010 (choice C9); spec review PASS-WITH-AMENDMENTS folded in; approved.
