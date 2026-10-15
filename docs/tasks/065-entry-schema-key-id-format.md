# Task 065: `entry.schema.json` enforces the `key_id` format that `signature-format.md` defines

- **Mission:** SITE-V1 (D1/D2 contract consistency) — **Status:** draft (booked 2026-10-15, session 9)
- **Repo:** registry. **Agent / model:** to be decided at the spec gate (contract change: independent review; site schema copies re-synced per task 041)
- **Budget:** small

## Objective
`contracts/signature-format.md` ("Deriving `key_id`", lines ~128–168 at `e009ef0`) says `entry.json`'s `key_id` holds
exactly 16 uppercase hexadecimal characters, while `contracts/entry.schema.json` gives `key_id` only `minLength: 1` (its
description defers the encoding to signature-format.md). Found in task 007a's fix round 1 (2026-10-15): a T1 write-back
with `key_id = "platform-2026-01\n"` is contract-valid today. After this task the schema carries the pattern, the
examples and 057's fixtures agree with it (057's fixtures use `E7A1B2C3D4E5F607`), and the site's vendored copy is
re-synced. Whether `signature` (multi-line minisign text) needs a stricter shape is assessed here too, without inventing
a rule `signature-format.md` does not state.

## Dependencies
After 007a merges (007a then picks the pattern up through the schema, with no code change). Touches an accepted
contract, so merge needs the independent review; ask Ludwig if anything beyond aligning the schema with
signature-format.md is proposed.
