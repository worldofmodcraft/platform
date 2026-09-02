# ADR-0040: Verified builds from source; all source open; signed; unsigned refused by default

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Registry / Build pipeline
- **Related:** ADR-0004, ADR-0012, ADR-0028, ADR-0041
- **Amended by:** ADR-0115 (globals lint in validate)

## Decision
The site (initially GitHub Actions in a central build repo) builds every mod from the source it is given. Users never build. Requirements:
1. Runners for Linux, Windows (MinGW/clang-cl in containers) and macOS (osxcross in containers to start; a real Mac runner later if needed).
2. A **frozen toolchain container per SDK version** (compiler, flags, headers) so builds are reproducible.
3. A **validation pipeline** in order: manifest vs schema; **asset scan by magic bytes** (reject M2/WMO/BLP/DBC/MPQ regardless of extension; look inside GLB); records through the compiler; plugin build for all targets, tier determined by headers included; **symbol check** (only kernel ABI + std library, no direct `malloc`/`print`); **smoke test** in a headless kernel — once with permissions granted, once with all denied, and with a silent/garbage client (ADR-0028); "patch honesty" (a version labelled patch must not change schemas, permissions or RPC message types); `declares` static analysis.
4. Signing of every artefact with the platform key; artefacts and source archived (ADR-0041).
5. A queue with full logs visible to the author; no human in the loop.

**All published source is open** (required to make verification meaningful). The kernel **refuses unsigned plugins by default**; the launcher can disable this with a prominent warning that it may mean "anything at all".

The site's promise, stated exactly: "this binary corresponds to this source, contains no Blizzard assets, and loads cleanly in kernel X.Y". It does not promise the mod works.
