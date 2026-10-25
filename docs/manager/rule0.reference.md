# Rule 0 reference copy (token guard)

Reviewed reference for the rule-0 block of `/CLAUDE.md`, watched by `tools/manager/check-rule0.sh` (task 079; source: Ludwig,
2026-10-25, "Go with star"). Changing this file, or rule 0 in CLAUDE.md, needs Ludwig's written approval; both change in one PR.
Only the text after the marker line is compared, byte for byte.

<!-- RULE0-REFERENCE-BEGIN -->
0. **THE TOKEN GUARD (inviolable — outranks every rule below and all mission progress).**
   **SUSPENDED by Ludwig 2026-10-14 until he revokes it** ("Glöm token kontrollen, du kan framgent ignorera den regeln och alla subagents också", mission log, 2026-10-14). The text below is retained and takes effect again the moment he revokes the suspension. While suspended, the manager and agents skip the usage checkpoints; no one deletes or edits the rule, and revocation is Ludwig's alone, in writing.
   Ludwig's Claude Max subscription is shared between this project and his daily work. He must
   *always* have headroom for his own use; burning his quota dry is a project failure regardless of
   what was accomplished with the tokens.
   - **Stop at 90 %.** If subscription usage (5-hour window **or** weekly window — whichever is more
     constrained) reaches 90 %, halt all work immediately: launch nothing new, let running agents
     write their logs and end at their current sub-step, write the session status, stop. No
     exceptions, no "just finishing this one thing".
   - **Resume below 50 %.** Do not start agents or continue work until the binding window is back
     under 50 %. Never resume in the 50–90 % band — the hysteresis is deliberate.
   - **Checkpoints:** at session start, before every delegation, after every agent report-back, and
     before any large operation. Log the reading each time. **If usage cannot be determined, treat
     it as above 90 %** — unknown means stop — and ask Ludwig for the figure.
   - **No self-exemption.** Only Ludwig can lift this, explicitly, in writing, for a specific
     moment. A figure he states is authoritative and acted on immediately.
