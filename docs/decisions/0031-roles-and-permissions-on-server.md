# ADR-0031: Server roles and namespaced permissions

- **Status:** Accepted
- **Date:** 2026-09-01
- **Area:** Ring 1 / Authorization
- **Related:** ADR-0029, ADR-0046

## Decision
The kernel introduces **roles** (`owner`, `admin`, `moderator`, `player` by default; servers may add more) and **permissions as namespaced strings** (`mc.config.edit`, `kelsi.housing.place_anywhere`). Mods declare their permissions with default roles in the manifest (same pattern as `declares`; `validate` warns when many lack descriptions). AzerothCore GM levels 0–3 are mapped to roles for legacy commands. The launcher shows all permissions per role. Invite codes (ADR-0046) carry a role. Permission denials are ordinary "no" log lines, not security events.
