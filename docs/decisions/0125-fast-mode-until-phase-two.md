# ADR-0125: Fast mode until phase two — the manager merges green work and takes the ★ option

- **Status:** Accepted (2026-11-04, accepted by Ludwig)
- **Date:** 2026-11-04
- **Area:** Process/governance
- **Touches:** process/merge-authority, process/question-discipline, manager/doctrine
- **Supersedes:** —
- **Amends:** —
- **Amended by:** —
- **Related:** ADR-0054, ADR-0099, ADR-0116, ADR-0122

## Context
The doctrine reserves several decisions to Ludwig: MANAGER.md §7 requires his approval to merge
anything touching `docs/decisions/`, mission specs, signing/keys, CI security checks, deletion of
data or a takedown; §3.1 requires his approval for every new ADR; §2 and §8b make the manager
stop and ask on anything that would create or reinterpret a decision or change scope. This keeps
Ludwig in the loop but slows each cycle.

Ludwig, 2026-11-04 (verbatim, Swedish; mission log, "C, kör på det"): "C, kör på det. Kan vi även
uppdatera ADR så att du får mergea allt som blir grönt självt utan min input? Samt att
utgångspunkten är att du tar stjärna på alla förslag (men loggar allt i vault)? Vill snabba upp
utvecklingsprocessen lite tills vi kommer till fas två och ska börja med server / client".
Exceptions, his answer to the manager's question: "Takedowns, Nycklar och hemligheter".

## Options considered
- A. Keep the doctrine as it is.
- B. Lift the merge gate only (the manager merges green work, still asks on questions).
- C. Lift the merge gate and the question gate, keep two exceptions, expire at phase two.
  (This is what Ludwig asked for in the quoted message.)

## Decision
Option C. Until the first phase-two mission (server/client work) is issued:

1. **Merges.** The manager merges any task whose verification and independent review are green,
   without asking Ludwig. This includes CI security checks, signing/keys *code*, doctrine, mission
   specs and `docs/decisions/`.
2. **Questions.** On every question the manager takes the ★ option itself, instead of asking. This
   includes accepting new or changed ADRs and changing a mission's scope.
3. **Logging.** Every such decision is logged in the mission log (projected to the vault) the same
   day, with the options and the reason ★ was chosen.
4. **Exceptions that stay Ludwig's.**
   - **Takedowns** (ADR-0122; MANAGER.md §7: merging one without his written approval is an absolute
     stop condition).
   - **Anything touching credentials, tokens, secrets or private keys** (CLAUDE.md rule 11).
   - Unchanged: the absolute stop conditions of MANAGER.md §8, and the forbidden shortcuts
     (CLAUDE.md rule 5, MANAGER.md §3.7).
5. **Expiry.** On the day the phase-two mission spec is issued, or earlier on the day Ludwig revokes
   this ADR in writing. On expiry every retained rule applies again as written.

The existing rule text is not edited. CLAUDE.md and MANAGER.md (§2, §3.1, §7, §8, §8b) each gain a
short note starting "**Until phase two (ADR-0125):**", in the same way as the token-guard
suspension.

## Consequences
- Faster cycles: fewer stops for Ludwig's approval.
- Ludwig reads decisions after the fact in the vault; each one carries its options and the ★ reason.
- The verification and review gates stay: only the approval step is lifted, not the checking.
- Risk: a wrong ★ decision on an ADR or a mission spec is found later. Mitigation: item 3 makes
  every decision traceable, and Ludwig can revoke in writing at any time.
- No existing ADR text is amended; ADR-0122's takedown rule is expressly kept.

## Interacts with
ADR-0054 (manager model: the manager's authority is widened for the period above), ADR-0099 (CI
gates stay in force; their changes may be merged by the manager), ADR-0116 (ADR compliance and
review still apply), ADR-0122 (takedowns stay Ludwig's).
