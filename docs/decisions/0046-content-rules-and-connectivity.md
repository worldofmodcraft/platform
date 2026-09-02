# ADR-0046: Content rules (minimal) and multiplayer connectivity (invite codes, Tailscale built in)

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Site / Launcher
- **Related:** ADR-0004, ADR-0031, ADR-0033

## Content rules
Removed: Blizzard data (including re-creations/upscales of Blizzard assets), illegal content, and **known malicious code** — defined narrowly as matching a published signature/advisory *or* confirmed by reproduction (exfiltration beyond declared permissions, encrypting/deleting files, installing outside its folder). Suspicion, heuristics and scary permission combinations produce **warnings only**. Adult content must be flagged and is hidden by default. Everything else is left to ratings and reports. Every removal has a public reason and can be appealed.

## Connectivity
Direct connection. The launcher generates an **invite code** (address:port + one-time account with a role + mod list, in one string). A "can the internet reach your server?" test button. **Tailscale support built in:** the launcher detects Tailscale, uses its address in the invite code when present, and provides a step-by-step guide when it is not; the interface is generic so other tunnels (ZeroTier, playit) can be added as guides. No platform-operated relay (possible later without architectural change). Connection failures are reported (opt-in) by step, not by peer.
