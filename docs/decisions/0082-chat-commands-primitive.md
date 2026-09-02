# ADR-0082: Chat commands are a ring-1 primitive with namespacing

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Ring 1 / UX
- **Related:** ADR-0030, ADR-0031, ADR-0034

## Decision
Mods declare commands in the manifest (under `declares`); the kernel registers `/modname ...` with auto-generated help from the declaration, tab completion in our client, permission level per command (ADR-0031 roles), and load-order collision resolution with a warning. Bare `/modname` lists subcommands. `.` commands remain admin/legacy. Free-form chat parsing by mods is rejected (two mods parsing the same line is chaos); menu/UI-only is rejected as amputating power users. Every command invocation is logged with mod attribution.

**Survey bench:** where client- and server-side command parsing live in WoWee/AC; how the `.` command table is built.
