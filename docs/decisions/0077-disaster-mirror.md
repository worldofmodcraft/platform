# ADR-0077: Scheduled disaster mirror of platform storage

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Registry / Governance
- **Related:** ADR-0006, ADR-0041, ADR-0058

## Decision
A scheduled job (default weekly; target, frequency and contents configurable like everything else) pushes the registry repo, artefact index and source archives to a second host (Codeberg/GitLab or S3-compatible bucket) — read-only, disaster recovery only. Documented in the handover plan; provider neutrality (ADR-0058) makes repointing a DNS/URL change. Verified by the backup principle: a quarterly job clones from the mirror and runs registry validation against it. SITE-V1's D5 documentation notes the mirror job as phase 1.5.
