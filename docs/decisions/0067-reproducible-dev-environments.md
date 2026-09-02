# ADR-0067: Reproducible dev environments — devcontainers for Linux targets, scripted Windows client build

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Process / Build
- **Related:** ADR-0040, ADR-0050, ADR-0071

## Decision
Everything Linux-buildable (server fork, kernel, tooling, site) builds in **devcontainers using the same frozen toolchain images as the build pipeline** — local build = pipeline build, killing "works on my machine" as an error class. The client fork builds natively on Windows via a pinned, scripted setup (`build-client.ps1`, winget/vcpkg-pinned deps); CI runs the same script on Windows runners so drift is detected. Windows cross-compile of the Vulkan client in containers is known swamp — only attempted if the Windows runner becomes a bottleneck.
