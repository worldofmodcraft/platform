# ADR-0039: The registry is a git repository; namespace = GitHub username

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Registry
- **Related:** ADR-0006, ADR-0040, ADR-0042, ADR-0043

## Decision
Phase 1: a public repo `worldofmodcraft/registry` with one JSON entry per mod (source repo, versions, hashes, signatures, artefact locations). Publishing = pull request validated by the build pipeline. **Namespace = GitHub username**, so no account system is built; a later portal migrates to its own accounts using "log in with GitHub". The kernel/launcher fetch the registry via git (full history is public and auditable). Zero hosting cost.
