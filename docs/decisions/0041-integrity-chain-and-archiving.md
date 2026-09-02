# ADR-0041: Integrity chain; platform-side archiving of artefacts and source; nothing can be unpublished

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Registry / Security
- **Related:** ADR-0006, ADR-0039, ADR-0040

## Decision
- **Hash in registry:** SHA-256 of every artefact is written into the registry entry by the pipeline; the launcher verifies after download. Versions are immutable; existing hashes can never be updated, only new versions added (enforced by a CI check on registry PRs).
- **Signature:** every artefact is signed with the platform key; the public key is embedded in kernel/launcher; the format carries `key_id` for rotation.
- **Registry protection:** branch protection, no force-push, PRs only, validated by the pipeline.
- **Key management:** key in build secrets, usable only by the build workflow; hardware-key 2FA on the org account; written rotation procedure. Transparency log (Sigstore-style) is a possible phase-3 upgrade.
- **Archiving:** the pipeline uploads artefacts **and a tarball of the exact built commit** to platform-owned storage; the registry points at our copy, not the author's repo. Deleting a GitHub repo can never break an installation or a dependency. The pipeline also pings Software Heritage as an independent archive.
- **Statuses:** authors may mark a mod **deprecated** (shown; new dependencies warned) but cannot remove versions. Only legal grounds (Blizzard assets, stolen code) lead to **removed**: artefacts pulled, registry entry kept with status and reason so dependency resolution can explain the failure.
- Abandoned mods: anyone forks to their own namespace; the site links "maintained fork available". The platform never reassigns a namespace.
- Every install: fetch registry → look up version → verify entry signature → download → verify hash → verify signature → install. All local; no trust in hosting behaviour.
- The portal displays hash and commit link on every version page.
