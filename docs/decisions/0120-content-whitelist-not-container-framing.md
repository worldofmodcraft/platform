# ADR-0120: The asset guarantee is content whitelisting, not container framing

- **Status:** Accepted · **Date:** 2026-09-03 · **Area:** Content / Registry / Build pipeline
- **Touches:** registry, registry/ci, validation, mod-format
- **Related:** ADR-0004, ADR-0040, ADR-0046, ADR-0061
- **Amends:** ADR-0004

## Context
ADR-0004 says the site "scans uploads by magic bytes and rejects Blizzard formats regardless of
file extension". Building that scanner (task 002) showed the wording admits a class of file the
decision plainly intends to exclude.

Two constructions, both demonstrated against a working implementation, not hypothesised:

- A **valid PNG** — correct signature, `IHDR`, `IDAT`, `IEND`, no trailing bytes — carrying an
  extra private ancillary chunk (`zBLZ`) whose declared-length data is a complete, magic-intact
  DBC file. Accepted.
- A **valid Ogg page** whose lacing-declared payload *is* a DBC file's bytes. Accepted.

Both are well-formed by their own container specifications: PNG and Ogg permit arbitrary bytes
inside private chunks and codec payloads. A scanner that verifies framing therefore answers "is
this a syntactically valid container?" while ADR-0004 needs "does this carry only permitted
content?". Successive spec wordings — "identify by magic bytes", then "well-formed instance of a
whitelisted format" — were each satisfied by files carrying a byte-for-byte Blizzard file.

Note also what a checksum would and would not do: verifying chunk CRCs does **not** close this.
An attacker computes the correct CRC over their own payload. CRCs detect corruption, not smuggling.

## Options considered
- A. **Whitelist chunk and payload types** — accept only known-safe structural elements.
- B. **Re-encode on ingest** — decode every asset and re-emit it, discarding anything that is not
  pixel or sample data.
- C. **Accept framing-only** and document the residual hole.

## Decision
**A.** The guarantee is stated positively and enforced structurally: *an accepted asset contains
only content of types the platform has explicitly permitted.* Concretely:

1. **PNG:** only `IHDR`, `PLTE`, `IDAT`, `IEND`, plus a short named safe list. Every entry on that
   list carries a written reason for its inclusion. Unknown, private or unlisted chunks are
   rejected — including ancillary chunks that are harmless in other contexts.
2. **Ogg:** the payload must parse as Vorbis or Opus headers. A page whose payload is not a
   recognised codec stream is rejected.
3. **Rejection messages tell the author what to do**, naming the offending element and the remedy
   (for example: "re-export without private chunks or embedded metadata"). A rejection the author
   cannot act on is a defect, not a security measure.
4. This tightening is deliberate and will reject some legitimate files — colour profiles, text
   metadata, unusual-but-valid chunks. That cost is accepted: authors can re-export, whereas a
   smuggling channel through the platform's own content guarantee cannot be undone once used.

**C was rejected** because documenting a demonstrated smuggling hole is not available to a platform
whose entire content policy exists to avoid exactly this exposure. **B is not adopted now** — it
conflicts with authors owning their assets untouched (ADR-0004's consequence that mods ship their
*own* assets) — but is recorded as the available hardening if the whitelist proves leaky.

### Amendment to ADR-0004
ADR-0004's "the site scans uploads by magic bytes and rejects Blizzard formats regardless of file
extension" is **necessary but not sufficient**. The full requirement: magic-byte typing decides
what a file *is*; content whitelisting decides what it may *contain*. Both must pass.

## Consequences
- The validator gains per-format structural knowledge (PNG chunk types, Ogg codec headers) rather
  than treating formats as opaque once identified. More code, and more to maintain per format.
- Adding a format to the whitelist now requires deciding what *inside* it is permitted, not only
  its signature.
- Some legitimate assets will be rejected. The rejection message carries the remedy.
- Formats added later inherit the rule: no format is accepted until its permitted interior content
  is defined.

## Interacts with
ADR-0004 (amended), ADR-0040 §3 (validation pipeline order), ADR-0046 (content rules),
ADR-0061 (AI-generated assets — unchanged: provenance is not this component's job).
