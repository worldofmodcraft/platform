# ADR-0090: Runtime mod failure — never auto-disable; deduplicate, flag, and give admins a throttle

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Observability / Ops
- **Related:** ADR-0010, ADR-0028, ADR-0034, ADR-0037

## Decision
A mod erroring every tick keeps running (maybe 90 % of it works; auto-disabling mid-session can destroy more than the bug and violates "user's responsibility + total visibility"). Instead: log deduplication by traceback signature (log 1st, 10th, 100th occurrence + counter), overlay/health flagging ("mod X: 40 000 errors this session"), and `/mods disable X` always available to the user.

**Admin stability tool:** admins can throttle or block per player and per mod surface — `.throttle <player> [mod/channel] <rate>`, `.block <player> <mod/channel>` plus launcher UI — implemented on chokepoints the kernel already owns (RPC validation hook, command registry, permission denial per channel). Denials are return values, never exceptions (mods already survive this per ADR-0028's smoke test). Scope: a **stability tool** against runaway clients/mods, not a moderation system — kick/ban exists for people problems. Observability points at who and what ("player X: 400 RPC/s on kelsi.arcade") so the tool is used surgically.
