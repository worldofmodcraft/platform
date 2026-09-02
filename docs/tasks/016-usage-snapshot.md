# Task 016: Make token-guard checkpoints self-service

- **Mission:** SITE-V1 (cross-cutting, serves CLAUDE.md rule 0) — **Status:** spec-approved (Ludwig, 2026-09-03)
- **Agent / model:** manager (direct — local machine configuration, no repo code)
- **Budget:** small · **Branch:** task/016-usage-snapshot

## Objective
The manager can read the current subscription usage figure without asking Ludwig, so the token
guard's checkpoints stop depending on a human at the moments the loop is busiest. Claude Code
already pushes a JSON payload to the statusline command roughly every 300 ms and the HUD's quota
line is rendered from it; nothing persists it. This task persists it.

## Context
- CLAUDE.md rule 0 (the token guard), MANAGER.md §8
- `~/.claude/settings.json` (statusLine), the claude-hud plugin at
  `~/.claude/plugins/cache/claude-hud/claude-hud/0.8.0/`
- Prior finding (mission log, 2026-09-03): `external-usage.js` reads a snapshot path that does not
  exist in this install; nothing under `~/.claude` holds a usage figure.

## Approach, in Ludwig's specified order
1. Check whether claude-hud has a **built-in writer** for the snapshot `external-usage.js` reads
   (its docs/config). If it does, enable that rather than building anything.
2. Otherwise wrap the statusline: read stdin, write it atomically to
   `~/.claude/usage-snapshot.json` (temp file + `mv`), pipe the identical content to the existing
   claude-hud renderer. **The HUD must look exactly as it does now** — the snapshot is a side effect.
3. Checkpoints then read the snapshot, extract the 5-hour and weekly figures, and log them.
4. **Fallback ladder** if the payload carries no usable quota fields: (a) a community estimator
   (ccusage / claude-monitor) via Bash, with readings marked **estimates**; (b) Ludwig calls out
   at ~85 %.

## Staleness rule (part of the guard, not optional)
If `usage-snapshot.json` is missing, or its mtime is older than **10 minutes**, the reading is
**unknown** — which under CLAUDE.md rule 0 means stop and ask Ludwig. A stale figure must never be
reported as current.

## File scope
- `~/.claude/settings.json` (statusLine command only) and a wrapper script under `~/.claude/`
- In the repo: this task file, and a checkpoint-reading note in the mission log.

## Acceptance criteria
1. A snapshot file exists and is refreshed by normal HUD operation.
2. **A checkpoint reading is demonstrated with a real figure taken from the snapshot, logged, with
   no input from Ludwig.** (Ludwig's stated acceptance criterion.)
3. The HUD renders identically before and after — verified by comparing rendered output.
4. The staleness rule is implemented and demonstrated (a stale or missing file yields "unknown").
5. If the payload lacks quota fields, the fallback actually taken is recorded, and estimate-based
   readings are labelled as estimates wherever they are logged.

## Forbidden here
- Degrading or altering the HUD's appearance to make the snapshot easier.
- Reporting a stale snapshot as a current reading.
- Writing anything from the payload into the repository — it is session data, and may contain paths
  and identifiers that do not belong in a public repo.

---
# Task 016 log
- 2026-09-03 spec written before execution.
