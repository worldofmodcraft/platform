# ADR-0022: AzerothCore C++ scripts and mod Lua are layered; scripts are ported to Lua on demand

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Architecture / Content
- **Related:** ADR-0021

## Context
Thousands of creatures and spells have C++ scripts (boss AI, SmartAI tables, spell scripts). Converting all of them to Lua records up front would mean rewriting a game's content, cutting us off from upstream fixes, and blocking the slice.

## Decision
The kernel hook chain runs *around* the C++ script with `before` / `after` / `replace`, same as mod-to-mod wrapping. Default for mods is `after`. `replace` must be declared in the manifest (surfaced as "replaces AI for N creatures") and is a **clean cut**: the C++ script is not instantiated for that entity. SmartAI tables are records and can be overlaid per field.

"Everything as one Lua layer" is the **destination**: a script is ported to Lua records when a mod actually needs to modify it; unported scripts stay in C++ and behave as always. Porting can be a community task listed on the site.

## Consequences
- Per-hook logging shows the layer (C++ / mod X).
- The roguelike's declarative ability framework becomes the canonical user of `replace` on spell scripts.
