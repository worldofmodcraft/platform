# ADR-0058: Publishing flow — mechanics, ownership by numeric account id, provider neutrality

- **Status:** Accepted
- **Date:** 2026-09-02
- **Area:** Registry / Site
- **Related:** ADR-0039, ADR-0040, ADR-0041, ADR-0059
- **Amends:** ADR-0030, ADR-0039 (namespace ownership: numeric account id supersedes the username string)

## Decision
1. **Flow:** creator's mod lives in a public **git** repo (any host; GitHub is the pragmatic phase-1 default). `modcraft publish` runs `validate` locally, tags a release, and opens a PR against `worldofmodcraft/registry` with the mod's JSON entry (id, version, commit hash, source URL). The pipeline fetches that exact commit, validates, builds, signs, archives artefacts + source tarball to platform storage, writes hashes into the entry and merges. Rejections return the full log in the PR.
2. **Ownership:** the namespace is bound to the **numeric GitHub account id** (never reused), not the username string: `owner = { provider = "github", id = ..., name_at_registration = "..." }`. The registry CI compares ids. This prevents namespace capture via username recycling.
3. **Namespace creation:** implicit at first approved publish, after an explicit confirmation shown by the CLI and documented on the site: *"This creates the namespace `X:` permanently bound to your GitHub account (id N). Namespaces are never reassigned."*
4. **Provider neutrality:** the registry format is provider-agnostic (`provider` field); the source requirement is "a public git repo", not "GitHub". Phase-3 portal accounts become the primary identity with GitHub as one linked login. Only the PR path is GitHub-specific and is replaced by portal upload later.
5. **CLI convenience:** `modcraft publish` authenticates once via GitHub device flow, stores the token locally, and drives fork/commit/PR through the API; manual PRs remain possible.
