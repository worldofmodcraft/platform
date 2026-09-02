# ADR-0089: GM play — self-discipline, always logged; `world.integrity` as a neutral read API

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Ring 2 / Product
- **Related:** ADR-0031, ADR-0034, ADR-0096

## Decision
No mechanical barrier between owning and playing: self-discipline governs (your world, your business). GM commands are **always logged** as attributed state changes — for debugging, the observability layer's purpose, not for morality. The bookkeeping already exists, so **`world.integrity`** is exposed as a pure ring-2 *read* API over it: whether GM commands have affected player state in this world/run/instance, when, by whom. The kernel never judges and attaches no labels; all meaning is added by mods, opt-in (an achievement mod may require clean runs — ADR-0096's `requires_clean`; a world where no mod asks never notices the API exists). Same pattern as capability tags: neutral primitive, ecosystem decides meaning.

**Survey bench:** how AC binds GM level to account vs character.
