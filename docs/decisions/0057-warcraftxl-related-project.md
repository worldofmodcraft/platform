# ADR-0057: WarcraftXL is a related project on a different path; not needed

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Ecosystem
- **Related:** ADR-0007, ADR-0019, ADR-0027

## Context
WarcraftXL (github.com/WarcraftXL, GPL-3.0, by iThorgrim — also associated with mod-ale) is an SKSE-style framework: a DLL loaded into the running Blizzard 3.3.5a client with a hook engine, curated offsets, typed bindings and an event bus. Client-only: mods live in one player's client and nothing is shared unless a server knows about it.

## Decision
With a source-available client fork, WXL is not needed: our hooks are ordinary code. WXL is documented in the survey's "related projects" section; its wiki may serve as a file-format reference (marginal — WoWee parses the same formats). The kernel stays client-agnostic (ADR-0019) so a WXL-based backend for the Blizzard client *could* be written by others; we do not build or support it. Contact with the WXL author is worthwhile once we have something running to show.
