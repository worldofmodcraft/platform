# ADR-0119: Reserved namespaces — a small platform-owned set, exempt from username binding

- **Status:** Proposed (option approved in principle by Ludwig, session 1 of SITE-V1; text pending his read)
- **Date:** 2026-09-02 · **Area:** Registry / Mod format
- **Touches:** registry, registry/ci, mod-format, site
- **Related:** ADR-0003, ADR-0030, ADR-0039, ADR-0058
- **Amends:** ADR-0030, ADR-0039

## Context
ADR-0030 and ADR-0039 both state that a mod's namespace **is** the owner's GitHub username, and
ADR-0058 §2 binds ownership to the numeric account id so that username recycling cannot capture a
namespace. Two namespaces the platform already relies on fit neither rule:

- `mc:` — the core-mod namespace named in ADR-0003. It is nobody's username, and if a person ever
  registered the GitHub account `mc`, the username rule would hand them the platform's own core
  namespace.
- `test:` — mission SITE-V1 publishes `test:hello-world` as the permanent pipeline canary. Under
  the username rule the registry CI must reject it, because `test` is not the publisher's username.

This surfaced as a concrete contradiction: the mission's acceptance criteria require the CI to
accept `test:hello-world`, while the CI's own ownership check must reject it. Special-casing it in
CI without a decision would be exactly the silent exception the ownership rule exists to prevent.

## Options considered
- A. Publish the canary under Ludwig's personal username namespace; leave `mc:` unresolved.
- B. Reserve a small, explicitly listed set of namespaces owned by the platform organisation.
- C. Special-case `test` in CI code with no decision recorded.

## Decision
**B.** A short, explicit **reserved list** exists in the registry, and reserved namespaces are
bound to the **organisation's** numeric account id rather than to an individual's:

1. The reserved set is data, not code: `registry/reserved-namespaces.json`, one entry per
   namespace with the reason it is reserved. Phase 1 contains exactly `mc` and `test`.
2. A reserved namespace's `owner` is the `worldofmodcraft` organisation's numeric account id
   (`provider = "github"`), following ADR-0058 §2 unchanged — the *binding mechanism* is identical
   to every other namespace; only the *derivation* of the name differs.
3. Registry CI treats a PR touching a reserved namespace as authorised when the PR author is a
   member of the organisation, and rejects it otherwise with a message naming this ADR.
4. Adding to the reserved set requires a PR to that file and is a decision, reviewed as one. The
   set stays small on purpose: it is an exception surface, and every entry is a name no
   individual can ever claim.
5. Everything else is unchanged: non-reserved namespaces are still derived from the GitHub
   username at first publish and owned by that account's numeric id.

### Amendments
- **ADR-0030** — "The namespace is the GitHub username (ADR-0039)" gains the exception: *except
  for namespaces on the reserved list, which are owned by the platform organisation.*
- **ADR-0039** — "Namespace = GitHub username" gains the same exception.

## Consequences
- The canary `test:hello-world` becomes legal without weakening the ownership check, and the CI
  path that authorises it is a documented rule with a test, not an `if` in a workflow file.
- `mc:` is protected before anyone can claim it — a squatting risk that existed silently until now.
- The registry CI needs organisation-membership information for reserved-namespace PRs. That is
  one extra API call on a rare path; non-reserved publishes are unaffected.
- A reserved namespace cannot be transferred to an individual later without a superseding ADR.

## Interacts with
ADR-0003 (the `mc:` name), ADR-0058 (ownership by numeric id — mechanism reused unchanged),
ADR-0059 (page ownership checks follow the same rule), mission SITE-V1 §D4 and §7.
