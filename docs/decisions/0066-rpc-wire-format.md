# ADR-0066: RPC wire format is IDL-generated compact binary with numbered fields; JSON debug mirror

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Architecture / Network
- **Related:** ADR-0020, ADR-0065

## Decision
Our packets between fork-server and fork-client use a compact binary format **generated from the IDL**: message types declared there with protobuf-style field numbers (new fields = new numbers; unknown fields ignored) so old clients survive additions. A debug flag mirrors every message as JSON to the log — readability exactly when needed and only then. Per-channel byte accounting is generated from the same source. Fallback if own serialization misbehaves: the IDL schema rides on MessagePack without changing message definitions.

**Survey bench:** custom-packet size limits/practice in the 3.3.5a protocol; whether the worldserver tick loop tolerates our send paths.
