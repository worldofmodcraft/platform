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
   `entry --account A --commit H` (C24: the entry's `source_url` carries the same URL token). Unfilled tokens must pass the schemas: `https://github.com/OWNER-PLACEHOLDER/wom-test-hello-world` and
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
- 2026-10-25 implementer (sonnet; run under task 010a): built from platform origin/main 2b2872c (the branch was first cut at 3f2408b; fast-forwarded before any commit, spec file identical). Registry tools: `git archive origin/main` of the local registry clone, commit 4356583fb2360592a680f40bee396f9f23df35a4 (not fetched; registry working tree never touched).
  **Produced:** `docs/test-mod/hello-world/{mod.lua,README.md,LICENSE,assets/screenshots/{welcome,gallery,spare}.png}`; `docs/test-mod/registry-pr/{entry,page}.json`; `tools/test-mod/{make_screenshots.py,fill_placeholders.py}`; `tools/test-mod/tests/{test_make_screenshots.py,test_fill_placeholders.py,check_tree.py}`; `docs/tasks/010a-verify.sh`. Content commit (PIN_FINAL) `1ea5ba4ee3db687a19b412b267b1b96fd0d4bb8f`; the commit after it only records this log.
  **Design notes.** (a) Screenshots: integer-only art (no trig), PNG filter Sub, zlib level 9, single IDAT, no ancillary chunks, 1280x720; `--check DIR` compares sha256 of decoded raw rows, never file bytes (amendment 4). (b) Placeholders: `OWNER-PLACEHOLDER` (in `mod.lua` `source` and `entry.json` `source_url`) and forty `0` (entry `commit`); both are schema-valid values. (c) `fill_placeholders.py entry` takes `--account` as well as `--commit` (a deviation from the spec's `entry --commit H`): the entry's `source_url` carries the same URL token, and amendment 8 requires zero tokens afterwards. Booked as Q1 below. (d) `check_tree.py` holds the criterion 1-4 logic so that `010a-verify.sh` can run it on mutated copies; keys: `minisign -G -W` in a temp dir, never printed, deleted on exit.
  **[script] results (all run by me, foreground, from the worktree root):**
  - Criterion 1: `scan_assets.py DIR` exit 0, 6 files accepted; positive control (planted DBC-magic file) exit 1; `read_manifest` + `manifest.schema.json` with MIT; id `test:hello-world`; both listed screenshots exist, PNG magic, CRC-checked chunks, IEND at the very end; README has heading, list, table, closed fence, link, image reference to a shipped PNG, and "permanent pipeline canary". Build: `git init` + commit of the tree, `build_version.py --allow-local-source --entry <filled> --version 1.0.0` with a throwaway key -> exit 0, tarball + minisig + result.json, 6 files accepted by the pipeline's own scan. PASS.
  - Criterion 2: committed PNGs decode to the generator's pixels (sha256 of raw rows); two generator runs byte-identical; no file named like an extracted game asset; no Blizzard magic. PASS. **What this does NOT prove:** that the art is visually original or acceptable (it cannot; that is criterion 8), nor that a different zlib build reproduces the committed file bytes (it will not necessarily; pixels are the contract).
  - Criterion 3: `page.json` and `entry.json` validate (`schema_check.validate`); entry has one `pending` version with exactly four keys; `entry.owner` equals `reserved-namespaces.json` `namespaces.test.owner` read from the file; `page.json` screenshots are a subset of `mod.lua`'s; `spare.png` is in the tree and in neither list. Staged as `mods/test.hello-world/{entry,page}.json`: `cli.py classify` exit 0 class `reserved-namespace`; `cli.py schema` exit 0; `cli.py append-only` (empty old root) exit 0; `ownership_cli.py --author-id 37807560 --membership-status 204` exit 0; the same with `404` exit 1, rule R7 (negative control). PASS.
  - Criterion 4: OWNER token found exactly in `mod.lua` (1) and `entry.json` (1), zero token exactly in `entry.json` (1), asserted non-zero; after `fill_placeholders.py` on a copy (account `sample-owner`, commit forty `a`) zero tokens remain and criteria 1 (static and build) and 3 pass on the copy; the script refuses an all-zero commit, a non-hex commit and the placeholder as account (exit 2, file untouched). PASS. (The runbook command naming is 010b.)
  - Criterion 11: `010a-verify.sh` exists, executable (mode 100755 in git); mutation-tested: 24 mutations (11 for criterion 1, 3 for 2, 6 for 3, 4 for 4 incl. a fill-script mutant that neither fills the commit nor asserts), every one exits 1 with a named FAIL line. Own-change checks on PIN_BASE `2b2872c382c1728b500b9684757f99162b407464` .. PIN_FINAL; live guards on HEAD. Every other `docs/tasks/*-verify.sh` run one at a time on this tree (048 049 051 052 053 056 [--no-fetch] 059 061 063 068 072 076 078 079 080): all exit 0.
  **[human] criterion 8 (visual review): NOT DONE.** I looked at the three PNGs (welcome: concentric rings round a warm disc on a teal-indigo gradient; gallery: six gradient tiles each with a diamond; spare: diagonal warm stripes on a cool gradient) and see abstract geometry with no game motif. That is the author's view, not the review the criterion asks for; Ludwig or the manager on his behalf must record it. Regenerate to look: `python3 tools/test-mod/make_screenshots.py --out /tmp/shots`.
  **Not done / deferred:** criteria 5-7, 9, 10 (010b). No `docs/test-mod/README.md` or tools index entry (outside the declared file scope); the manager may want one line in a docs index.
  **Questions (book for Ludwig, bundled):** Q1 `entry --commit H` vs `entry --account A --commit H`: options A★) keep `--account` required on `entry` (as built; one command fills everything the entry needs) / B) make `mod --account` also rewrite a sibling `entry.json`. Q2 PIN_BASE stays `2b2872c` after a squash merge only if the commit survives in main's history (it does for merge commits, as with 079/078).
- 2026-10-25 implementer: pushed `task/010a-test-mod-contents`; fresh clone from GitHub (https://github.com/worldofmodcraft/platform, branch HEAD 351933a) ran `docs/tasks/010a-verify.sh` -> exit 0 ("010a-verify: ALL OK", 88 live checks + 24 mutations red + own-change + mode checks; registry commit 4356583fb2360592a680f40bee396f9f23df35a4). PR opened, not merged.
