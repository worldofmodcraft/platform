# ADR-0100: `modcraft` CLI distribution — static binaries, bundled with the launcher

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Distribution / DevEx
- **Related:** ADR-0014, ADR-0048, ADR-0051

## Decision
One static binary per OS (the Rust offline-tooling choice pays off), built and signed by the same pipeline, distributed three ways: download page on the site; **bundled with the launcher** (exposed + added to PATH on request — players who become modders already have it); winget/homebrew when relevant. `modcraft self-update` against the registry with the same signature chain.
