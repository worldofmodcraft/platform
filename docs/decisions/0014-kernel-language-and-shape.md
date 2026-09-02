# ADR-0014: Kernel is a shared C++ in-process library; offline tooling is separate

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Architecture
- **Related:** ADR-0007, ADR-0012, ADR-0020, ADR-0043

## Options considered
- A. `libmodcraft` in C++ linked into both forks (hooks, Lua states, allocator, RPC); the compiler/validator/CLI/registry client as a separate offline tool (Rust is plausible; the launcher can reuse it).
- B. Everything in Rust, entering the C++ hosts via our own C ABI.

## Decision
**A**, with mitigations that recover B's main benefit:
- The C ABI header and all bindings are **generated from the IDL** (ADR-0020); a leaked C++ type is a generator bug visible in diffs.
- Kernel C++ is built with AddressSanitizer/UBSan in CI; the site's smoke test runs against a sanitizer build.
- Everything that can live outside the process (compiler, validator, registry client, telemetry aggregation) lives outside.
- The **first reference plugin is written in Rust** during step 0→1 so we experience the ABI as a foreign consumer.

## Consequences
- Hooks into AzerothCore and WoWee are plain same-language function calls.
- The launcher (Tauri, ADR-0043) can link the offline tooling directly.
