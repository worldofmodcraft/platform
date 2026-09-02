# ADR-0094: Windows code signing deferred; the pipeline carries an empty signing slot now

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Distribution
- **Related:** ADR-0041, ADR-0043, ADR-0060

## Decision
Ship unsigned for now, with honest instructions for the SmartScreen prompt. The build pipeline is designed with a **no-op Authenticode signing step** (an if-statement in the workflow), so enabling signing later is a configuration change, not development. Context for the deferral: certificate authorities verify identity, not content — approval is not the realistic obstacle; the real consideration is that signing visibly binds Ludwig's name/organisation to the project, which belongs on the same side of the stable-release threshold as all other visibility (ADR-0060). Winget distribution (which also eases SmartScreen friction) is investigated when relevant, independent of the certificate. Launcher self-updates use Tauri's updater with signed updates under the existing key-discipline. The platform's own cryptographic chain (ADR-0041) is unaffected — this ADR is about OS trust UI only.
