# ADR-0073: Mod delivery to clients — registry first, HTTP sidechannel for the rest

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Architecture / Distribution
- **Related:** ADR-0041, ADR-0042, ADR-0046

## Decision
worldofmodcraft.com (the registry + platform artefact storage) is the **default distributor**: a server's mod list references id + version + hash, and clients fetch published mods from the registry exactly as for a normal install. The **HTTP sidechannel** — a minimal file server in the server package (kernel-owned, same or side process) serving signed artefacts — exists only for what the registry does not have: the server's own unpublished mods, dev versions, private friend-mods; a server admin may also point list entries at any other host. Handshake in the game protocol carries only mod list + hashes + port. Hash + signature verification is identical regardless of source, so no channel needs to be trusted. Invite code and port test must cover the second port.

**Survey bench:** whether the worldserver process tolerates an HTTP thread without disturbing the tick loop (else: side process under the launcher's supervisor).
