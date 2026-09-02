# ADR-0049: Licensing — AGPL platform, MIT SDK with linking clause, any OSI licence for mods

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Legal
- **Related:** ADR-0006, ADR-0007, ADR-0012, ADR-0040

## Decision
- **AGPL-3.0:** server fork (mandatory, AzerothCore is AGPL), client fork (chosen — WoWee is MIT, we tighten it so no closed World of Modcraft can ever exist), `libmodcraft` on both sides, launcher, site generator, build pipeline, registry tooling.
- **MIT with an explicit linking clause:** the SDK — headers, IDL, generated bindings, mod templates, CLI library. Using the SDK via the published ABI does not make a mod a derivative of the kernel.
- **Mods:** any **OSI-approved licence** (open source is mandatory — ADR-0040), with two consequences: **unsafe-tier plugins** (which include AGPL headers) must be AGPL-compatible; packaged legacy addons must permit repackaging.
- Bug fixes intended for WoWee upstream are written and submitted under **MIT first**, then merged into our AGPL fork.
- A "Licensing explained" page on the site.

## Rationale
"Open" has two meanings: permissive (anyone may do anything) and copyleft (it stays open). Copyleft on what *we own* guarantees the platform can never be closed and eases handover; freedom of licence for mod authors avoids driving away contributors, while openness of published mods is already guaranteed by site policy rather than licence contagion.
