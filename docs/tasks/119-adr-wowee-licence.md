# Task 119: ADR-0127, the client fork keeps WoWee's licence terms (Q23 = C), amending ADR-0049 and ADR-0007

- **Mission:** none (Ludwig's direct decision, 2026-11-26; recorded before phase two) — **Status:** spec-approved (manager, 2026-11-26, solo gate: documentation only)
- **Agent / model:** doc-writer (model per frontmatter). **Budget:** small
- **Branch / worktree:** `task/119-adr-wowee-licence` / `~/wt/task-119`, cut from platform `main` (`6145113`)

## Decision being recorded
Ludwig, 2026-11-26 (verbatim, answering Q23): **"C: Acceptera WoWees villkor"**. Option C from `docs/design/rust-clients-usability-survey.md` ("Keep WoWee's terms for the client and amend ADR-0049"). That note's "Against" column says the clash with an AGPL `libmodcraft` "remains to solve"; the manager solves it under ADR-0125 with the ★ below, recorded as the manager's, not Ludwig's.

**Manager's ★ (ADR-0125), for the parts C leaves open:**
- **Client fork licence:** WoWee-derived code in the client fork stays under WoWee's own `LICENSE` ("MIT License (with Additional Restriction)"), unchanged and with its `NOTICE`. Options: A★ keep it as it is; B relicense our own client changes AGPL (impossible on the combined work: AGPL forbids further restrictions).
- **`libmodcraft` and our own client-side code:** A★ **MIT** (with the SDK's linking clause, ADR-0049), so it can be linked into both the restricted client and the AGPL server; B dual MIT/AGPL (same effect, more text); C keep AGPL and never link it into the client (breaks ADR-0014's in-process kernel on the client side). Consequence stated plainly: the "no closed World of Modcraft can ever exist" guarantee no longer covers the kernel; it still covers the server fork (AGPL, mandatory) and the launcher, site generator, build pipeline and registry tooling.
- **Audio:** WoWee's music and audio are all rights reserved; the fork carries none of them, and phase two's client task removes them.
- **Upstream fixes:** contributed to WoWee under WoWee's own terms (replaces "under MIT first").
- **Not legal advice:** the ADR says that no lawyer has read this, and that the restriction ("commercial video game or other commercial game product") is compatible with ADR-0104 (no paid mods) by the manager's reading only.

## Acceptance criteria
1. `docs/decisions/0127-client-keeps-wowee-licence.md` from `TEMPLATE.md`: Status Accepted, Date 2026-11-26, `Amends: ADR-0049, ADR-0007`, one section per amended ADR. It quotes Ludwig's answer verbatim, quotes WoWee's `LICENSE`/`NOTICE` wording only as the survey note recorded it (2026-11-05; mark it as read then, not re-read), and separates Ludwig's decision from the manager's ★ parts, giving the options and reasons for each.
2. Amend protocol (README): ADR-0049 and ADR-0007 each gain exactly one `- **Amended by:** ADR-0127 (...)` header line, and nothing else changes in them.
3. `docs/decisions/README.md` lists 0127 under "Vision & governance" or "Architecture" (the writer picks one and says why in the log); `python3 -I -B tools/adr/build_index.py --write` then `--check` exits 0; the ADR test suite passes (command and output in the log).
4. `docs/design/rust-clients-usability-survey.md` and `docs/open-questions.md` (if it lists Q23 or the licence) record that Q23 is answered by ADR-0127; nothing else in them changes.
5. Consequences section lists: the openness guarantee narrowed for the kernel; ADR-0040/0006 still hold for mods; the client cannot be used in a commercial game without WoWee's written permission, and that restriction passes to anyone building on the client; audio excluded; what a phase-two client task must do (keep `LICENSE`/`NOTICE`, strip audio, licence headers).

## File scope
Platform: the new ADR; one header line each in ADR-0049 and ADR-0007; `docs/decisions/README.md`; `docs/decisions/INDEX.json` (generated); the two notes in criterion 4; this file's log. Anything else: stop and report.

## Forbidden
Changing the substance of any accepted ADR; contacting anyone; fetching WoWee's repository again (the 2026-11-05 reading is the record); touching any credential; pushing anything but the task branch.

---
# Task 119 log
- 2026-11-26 manager (session 16): spec written from Ludwig's answer.
