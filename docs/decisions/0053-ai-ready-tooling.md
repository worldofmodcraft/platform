# ADR-0053: AI-ready mod development

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Developer experience
- **Related:** ADR-0020, ADR-0030, ADR-0051

## Decision
The same artefacts that make manual modding easy are published in machine-readable form; the AI layer is thin:
- `modcraft new` generates **`AGENTS.md`** (cross-tool standard) with `CLAUDE.md` as a symlink: the platform rules in AI-facing form (this is World of Modcraft, not retail WoW or Eluna; the API is only what `docs/api/` defines; never invent functions; log via `mc.log`; declare everything; run `modcraft validate --json` after every change and fix until clean).
- The finite, IDL-defined API means `validate` catches hallucinated functions; generated Lua type annotations give editors and AI tools signatures; every doc example is CI-tested so there is no wrong code to learn from.
- The site publishes **`llms.txt`** — the full API reference as one text file per kernel major.
- **Machine-readable feedback loop:** `modcraft validate --json`, `modcraft dev --json-log`, local smoke tests. Later: a `modcraft mcp` server exposing validate, schema lookup, log reading and the dev server as tools.
- AI-assisted mods are expected to be lower quality on average; health panels, permission transparency and the "tolerates denial" test carry that, not the platform's reputation.
- `ai_assisted` in the manifest is **optional tri-state**: true / false / omitted (shows nothing).
