# ADR-0072: Login — keep the auth protocol, hide the concepts

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Architecture / UX
- **Related:** ADR-0042, ADR-0046

## Decision
The authserver and Blizzard's SRP6 login dance stay (minimal surgery in the gnarliest protocol area). The launcher generates accounts and keys per world/invitation; the user never sees "account", "password" or "realmlist" as WoW archaeology — the invite code (ADR-0046) carries everything. Users may well see a friendly identity concept ("your character identity on Kalle's server"); they just never run `account create` in a worldserver console. Replacing auth with a modern token handshake in our fork stays possible later — the launcher already owns the whole flow, so the underside can be swapped invisibly — but ripping out working legacy now is exactly the temptation the doctrine forbids.

**Survey bench:** auth/world coupling in AC; where WoWee's login/glue code lives.
