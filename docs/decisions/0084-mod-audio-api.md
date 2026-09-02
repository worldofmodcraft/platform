# ADR-0084: Mod audio API

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Ring 2 / Client
- **Related:** ADR-0004, ADR-0020

## Decision
Mods can play their own OGG files (already whitelisted) via a client API: UI sounds, positional world audio, a music channel with ducking of game music; the server can trigger via RPC ("play the gong for everyone in the instance"). v1 may be naive (play/stop/volume); 3D panning later. References to the player's existing sound data also work.

**Survey bench:** WoWee's audio system — mixer, channels, positional support, or rudimentary?
