# ADR-0059: Mod pages are generated; page content is separate from versions and immediately editable

- **Status:** Accepted
- **Date:** 2026-09-02
- **Area:** Site
- **Related:** ADR-0030, ADR-0041, ADR-0058

## Decision
1. Every merge to the registry triggers the static site build. Each mod gets a page generated from three sources: the registry entry (versions, hashes, tier, status), the manifest presentation fields, and the **archived** source (README, screenshot files) — never the live repo, so pages survive repo deletion.
2. **Two kinds of content:** *version-bound* (changelog, technical manifest fields, the README as of that release — frozen forever) and *page content* (description, screenshots, tags, current README, links, deprecated flag — editable any time) stored in `registry/mods/<ns>.<name>/page.json`.
3. `modcraft page update` opens a PR touching only `page.json`; same ownership check (numeric id), asset scan on new screenshots, no version, no build. **Approved page changes publish immediately**; git history is the audit trail. The phase-3 portal edits the same file via web UI.
4. **Browse:** generated index pages per tag/category plus "recently updated"; client-side search (Pagefind) with filters on tag, permissions, tier and type. Downloads/ratings sorting arrives with phase-3 data.
5. Health panels, ratings and counters are phase-3 JSON fetched client-side; the site itself stays static.
