# ADR-0127: The client fork keeps WoWee's licence terms; `libmodcraft` becomes MIT

- **Status:** Accepted (2026-11-26; the client-licence choice decided by Ludwig, the parts it leaves open taken by the manager under ADR-0125)
- **Date:** 2026-11-26
- **Area:** Legal
- **Touches:** legal/licensing, client/fork, kernel/licence, audio
- **Supersedes:** —
- **Amends:** ADR-0049, ADR-0007
- **Related:** ADR-0006, ADR-0014, ADR-0040, ADR-0104, ADR-0125

## Context
During task 113 (survey of Rust clients, 2026-11-05) the WoWee repository's licence files were read. That note, `docs/design/rust-clients-usability-survey.md`, is the only record of their wording; **WoWee was not fetched again for this ADR**, so everything quoted below was read on 2026-11-05 and may have changed since.

What the survey recorded:
- `LICENSE` is headed "MIT License (with Additional Restriction)": "the Software may not be used, in whole or in part, as the basis for, or as a component of, any commercial video game or other commercial game product", without written permission.
- `NOTICE`: "The restriction was added on 2026-07-21. Code published before that date carried plain MIT terms and those terms stand for what was published under them".
- Music and audio are all rights reserved and "not to be copied ... or used in any derivative work" (`LICENSE`, `NOTICE`).

What our decisions assumed: ADR-0007 (2026-08-31) calls WoWee "an MIT-licensed native C++/Vulkan client". ADR-0049 makes the client fork AGPL-3.0 ("WoWee is MIT, we tighten it so no closed World of Modcraft can ever exist"), puts `libmodcraft` under AGPL "on both sides", and has upstream fixes written "under MIT first". The AGPL allows no further restrictions beyond its own, so a work that must carry WoWee's restriction cannot also be licensed AGPL as a whole. No fork exists yet (the repository has no `client/` directory), so nothing has been published in conflict.

The survey offered Ludwig four options (A ask the copyright holders, B fork the last plain-MIT commit, C keep WoWee's terms and amend ADR-0049, D use benilla-wotlk). Ludwig's answer to Q23, 2026-11-26, verbatim (Swedish): **"C: Acceptera WoWees villkor"**.

**Not legal advice.** No lawyer has read WoWee's terms or this ADR. Every statement below about what the licences permit is the manager's reading only.

## Options considered
**Ludwig's decision (not reopened here):**
- A. Ask WoWee's copyright holders in writing and have a lawyer read the answer.
- B. Fork the last plain-MIT commit, without audio.
- **C. Keep WoWee's terms for the client and amend ADR-0049. Chosen by Ludwig.**
- D. Use benilla-wotlk as the client.

**Parts C leaves open, taken by the manager under ADR-0125 (★ = chosen; options and reasons logged in the mission log the same day):**

*Licence of the client fork*
- A ★. WoWee-derived code stays under WoWee's own `LICENSE`, unchanged, with its `NOTICE`. Reason: it is what C means, and we have no right to change it.
- B. Relicense our own client changes as AGPL. Rejected: on the combined work the AGPL forbids the further restriction, so the result could not be distributed.

*Licence of `libmodcraft` and our own client-side code*
- A ★. **MIT**, with the SDK's linking clause (ADR-0049), so one library can be linked into both the restricted client and the AGPL server. Reason: MIT is compatible with both.
- B. Dual MIT/AGPL. Same practical effect, more text to maintain.
- C. Keep AGPL and never link it into the client. Rejected: it breaks ADR-0014, where the kernel is one in-process library linked into both forks.

*Audio*
- A ★. WoWee's music and audio are all rights reserved; the fork carries none of them.
- (No alternative: the survey records no permission to use them.)

*Upstream fixes*
- A ★. Contributed to WoWee under WoWee's own terms (replaces "under MIT first").
- B. Keep writing them under MIT first. Rejected: the code we would be fixing is not plain MIT any more.

## Decision
1. **Ludwig's decision:** the client fork keeps WoWee's licence terms (option C of the survey; Q23).
2. **Client fork:** WoWee-derived code in the client fork stays under WoWee's `LICENSE` ("MIT License (with Additional Restriction)"), unchanged, and WoWee's `NOTICE` is kept with it.
3. **`libmodcraft` and our own client-side code:** MIT, with the SDK's explicit linking clause (ADR-0049). The combined client as distributed is still subject to WoWee's restriction.
4. **Audio:** the fork carries none of WoWee's music or audio. The phase-two client task removes them.
5. **Upstream fixes** are contributed to WoWee under WoWee's own terms.
6. **Server, launcher and tooling are unchanged:** the server fork stays AGPL-3.0 (AzerothCore requires it); the launcher, site generator, build pipeline and registry tooling stay AGPL-3.0.
7. **Reading of ADR-0104 (manager's, not legal advice):** WoWee's restriction ("commercial video game or other commercial game product") does not conflict with ADR-0104 (no paid mods, no paywalls), because the platform distributes only free work. This has not been confirmed by a lawyer or by WoWee's copyright holders.

## Amendments

### ADR-0049 (licensing)
- The bullet "AGPL-3.0: ... client fork (chosen — WoWee is MIT, we tighten it so no closed World of Modcraft can ever exist), `libmodcraft` on both sides ..." changes as follows:
  - **Client fork:** not AGPL. WoWee's own terms (Decision 2).
  - **`libmodcraft`:** MIT with the SDK's linking clause, not AGPL (Decision 3). The same applies to our own client-side code.
  - **Still AGPL-3.0:** the server fork, launcher, site generator, build pipeline and registry tooling.
- "Bug fixes intended for WoWee upstream are written and submitted under MIT first" becomes: submitted under WoWee's own terms (Decision 5).
- The MIT SDK, the licence rules for mods, and the "Licensing explained" page stand. That page must describe the licence split above.
- The premise "WoWee is MIT" is withdrawn. ADR-0049's rationale about copyleft on "what we own" now holds for the server fork and tooling, not for the kernel or the client.

### ADR-0007 (fork WoWee and AzerothCore)
- "an MIT-licensed native C++/Vulkan client" is corrected: WoWee is MIT with an additional restriction, and its audio is all rights reserved (as read 2026-11-05).
- "Bug fixes we want upstreamed to WoWee are written under MIT first (ADR-0049)" becomes: written under WoWee's own terms (Decision 5).
- The decision itself (fork WoWee and AzerothCore, one monorepo) stands.

## Consequences
- **Openness guarantee narrowed.** ADR-0049's "no closed World of Modcraft can ever exist" no longer covers the kernel, which is MIT and could be taken closed by a third party. It still covers the server fork (AGPL, mandatory) and the launcher, site generator, build pipeline and registry tooling. ADR-0006's handover goal is affected in the same way for the client side.
- **Mods are unaffected.** ADR-0040 (all mod source open, verified builds) and ADR-0006 as applied to mods still hold. Mod licence rules in ADR-0049 are unchanged. **Open question:** ADR-0012 says unsafe-tier plugins include "AzerothCore/WoWee internal headers". The licence inherited by client-side unsafe-tier plugins, which would include WoWee headers under WoWee's restricted terms and not AGPL, is not decided here. It is booked for the phase-two client work (`docs/open-questions.md`). Server-side unsafe-tier plugins are unchanged (AGPL).
- **No commercial games on the client.** The client cannot be used in a commercial video game or commercial game product without WoWee's written permission. The restriction passes to anyone who builds on our client fork, including a future owner after handover. It is not our restriction and we cannot lift it; only WoWee's copyright holders can.
- **Audio excluded.** No WoWee music or audio in the fork. The client has no bundled music until we supply our own (ADR-0004, ADR-0061).
- **Code published before 2026-07-21** is recorded by `NOTICE` as plain MIT for what was published under those terms. This ADR relies on that only as read on 2026-11-05 and makes no use of it.
- **Unconfirmed:** no lawyer has read this ADR or WoWee's terms, and WoWee's holders have not been contacted. Option A of the survey (ask them) stays open to Ludwig at any time; a different answer would need a new ADR.
- **A phase-two client task must:** keep WoWee's `LICENSE` and `NOTICE` in the fork unchanged; strip all WoWee music and audio; put the MIT licence header (with the linking clause) on our own client-side files and `libmodcraft`, and no AGPL header on them; keep WoWee-derived files under WoWee's terms; re-read WoWee's `LICENSE` and `NOTICE` at fork time and record the commit; update the site's "Licensing explained" page; and replace AGPL headers and licence files where ADR-0049's old text put them on client code.
- `docs/open-questions.md` Q23 and the survey note record that Q23 is answered by this ADR.

## Interacts with
ADR-0004 (own assets only: audio and game data), ADR-0006 (openness and handover), ADR-0014 (the in-process kernel keeps working), ADR-0040 (mods stay open), ADR-0049 and ADR-0007 (amended), ADR-0061 (AI-generated assets could replace the audio), ADR-0104 (no paid mods), ADR-0125 (the ★ choices).
