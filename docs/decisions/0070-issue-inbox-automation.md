# ADR-0070: Automated issue triage into the task inbox

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Process / Automation
- **Related:** ADR-0035, ADR-0054, ADR-0068

## Decision
A GitHub Actions workflow (the **official** `anthropics/claude-code-action` only; other frameworks don't reliably support subscription auth) runs on new issues, authenticating with a subscription OAuth token (`claude setup-token` → `CLAUDE_CODE_OAUTH_TOKEN` secret; regenerate after logout/plan changes — runbook note). The triage instance has a narrow mandate: read the issue and relevant code/logs, write an analysis comment and a **draft task file** (doctrine format: reproduction, suspected area, suggested agent/model, budget, acceptance criteria) as a PR into `docs/tasks/inbox/`. It **never writes production code, merges, or spawns agents** — issue text is untrusted input, and a code-writing trigger would be prompt injection as architecture. The manager triages the inbox per doctrine §8b; Ludwig approves before anything is built.

Timing: built cheaply after SITE-V1 (runs on subscription quota — shared with interactive use); the launcher's bug-report export (ADR-0035) gains "create a well-formed issue" as a future target. `docs/tasks/inbox/` is the only entry path for externally generated tasks.
