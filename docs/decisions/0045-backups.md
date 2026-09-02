# ADR-0045: Rolling, user-configurable, verified backups per world

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Launcher / Data safety
- **Related:** ADR-0010, ADR-0017, ADR-0029, ADR-0042

## Decision
Beyond pre-update backups: automatic rolling backups per world — on every server stop and every N hours of uptime, keeping the last K — with **frequency, retention and verification all user-configurable** via the standard settings schema (sensible defaults, e.g. 7 daily + 4 weekly). Backups are incremental over the delta (kernel tables, characters, mod-prefixed tables; the pristine base DB is never backed up), **verified by restoring into an empty schema in the background**, and restorable from the launcher with a "restore to" button; `modcraft backup` for manual use. A backup is an export without the mod list — one mechanism. Cloud sync to user-owned storage is a later opt-in.
