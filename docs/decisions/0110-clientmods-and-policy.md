# ADR-0110: Client-only mods as a category; server clientmod policy

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Mod format / Client
- **Related:** ADR-0026, ADR-0087, ADR-0090

## Decision
`type = "clientmod"`: only client-scope surfaces (UI, camera, audio, overlay rendering) — no records, no server Lua, no RPC registration; the category is mechanically checkable (zero server declarations). Installed globally by the player (follows all profiles per ADR-0087); the server sees them in the handshake.

**Server control — stability first:** the server sets `clientmod_policy`: `allow_all` (default for local worlds), `whitelist` (only listed clientmods may be active in sessions against this server — tournament/stability mode), or `block_all`. Denied clientmods are deactivated *for that session only*; the player's global install and other servers are untouched. Honesty note: a clientmod crashes the *client*, never the server process — the whitelist protects against support burden ("the server is broken!" when it's a UI mod) and indirect disruption (reconnect spam). With our client the policy can also cover legacy FrameXML addons. Server stability and the owner's control come first.
