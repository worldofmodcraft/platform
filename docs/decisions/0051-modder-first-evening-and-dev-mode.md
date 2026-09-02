# ADR-0051: The mod author's first evening; kernel dev mode

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Developer experience
- **Related:** ADR-0017, ADR-0023, ADR-0030, ADR-0053
- **Amended by:** ADR-0115 (validate lint additions)

## Decision
Target: from "I want to make a mod" to "my change is visible in game" in **under one hour** for a records+Lua mod. Both experienced developers (primary) and less experienced people (possibly using AI tools) are audiences.
- `modcraft new <ns>:<name>` → a working mod (manifest, example record, a server hook, a client panel showing "Hello"). First act is editing, not creating.
- **Dev mode** (`modcraft dev`): file watching, incremental recompilation, hot reload without losing the session for warm changes; cold changes reported ("requires restart — press R"). Starts a minimal server + client with the mod and a GM character at max level with everything unlocked.
- **Error quality is a Definition-of-Done requirement** for the kernel: every error names mod, file, line, what went wrong and what to do — never a kernel-internal stack trace.
- `modcraft validate` runs the *same* pipeline as the site locally — nobody gets a site rejection they could not have seen at home.
- `modcraft publish` creates the release and the registry PR.
- **Reference mod:** the roguelike is written as the complete, commented example; every API function is used there. Style rule: clear over clever.
- Generated API docs with one runnable, CI-tested example per function; Lua type annotations for editor autocomplete; the plugin template repo with three-OS CI.
- **Records-only mods** (no Lua) must be fully supported to widen the audience; a graphical record editor (writing JSON) is a later possibility the format already allows.
