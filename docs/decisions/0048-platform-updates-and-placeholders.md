# ADR-0048: Platform packages; uninstalled-mod placeholders

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Launcher / Data
- **Related:** ADR-0013, ADR-0040, ADR-0042

## Platform updates
Kernel, server fork and client fork are **artefacts in the same registry**, built and signed by the same pipeline (inheriting WoWee's three-OS container builds). A **platform package** = (kernel, server fork, client fork) tested together; users update packages, never parts. Package patch versions (1.4.1) allow a client-only hotfix. Servers advertise their package at handshake; mismatched clients are asked, never updated automatically; approval can be remembered per profile. Multiple package versions may be installed side by side per profile.

## Placeholders for missing mods
Every record type has **subtypes** (`item.sword`, `item.chest_cloth`, `mount`, `spell.damage`…) and the kernel ships a **placeholder record per subtype** (`mc:placeholder_sword` → a vanilla starter sword by path, neutral stats, description "Item from missing mod kelsi:weapons"). When a mod is missing, references are redirected to the placeholder while the **original id is retained**, so reinstalling restores everything. Items are grey/unknown only when the *type itself* is unknown (defined by the missing mod). Mods defining their own record types must declare a placeholder in the schema. Values of *modified* records revert to whatever remains in load order.
