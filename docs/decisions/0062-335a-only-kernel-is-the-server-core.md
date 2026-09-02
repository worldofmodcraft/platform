# ADR-0062: The platform targets 3.3.5a only; the kernel fork is the only supported server core

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Architecture / Scope
- **Related:** ADR-0007, ADR-0016, ADR-0019

## Decision
World of Modcraft **is** its server core: mods talk to the kernel API, and no other server implementation can run them. The platform targets **WotLK 3.3.5a only**. WoWee's 1.12/2.4.3 support is dead weight for us — left untouched, unused, unsupported. No version-abstraction layer is built "for the future"; the only discipline kept is what exists anyway: the compiler's internal model is format-neutral (records → model → outputs, ADR-0016).

**Survey bench:** how much non-3.3.5a code WoWee carries and whether it interferes or lies still.
