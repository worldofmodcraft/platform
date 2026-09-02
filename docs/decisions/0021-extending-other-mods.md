# ADR-0021: Mods extend/replace other mods only through the kernel

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Mod format
- **Related:** ADR-0011, ADR-0022, ADR-0030

## Decision
Monkey-patching by overwriting another mod's tables is not supported. A mod uses `kernel.wrap("kelsi:housing", "place", { before | after | replace = fn })` and must declare `extends = { ["kelsi:housing"] = { "place", ... } }` in its manifest. The kernel chains wrappers in load order, logs every call with attribution, and forces load-after-target. The launcher shows at install time exactly what is modified and requires the target mod to be installed first.
