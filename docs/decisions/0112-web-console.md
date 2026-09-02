# ADR-0112: The server web console

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Ops / Product
- **Related:** ADR-0029, ADR-0031, ADR-0034, ADR-0035, ADR-0073, ADR-0079, ADR-0082, ADR-0089, ADR-0090, ADR-0093, ADR-0102, ADR-0103, ADR-0107, ADR-0111

## Decision
The server core ships a **web console** on its HTTP surface (ADR-0073): the server's home for administration — full admin parity without booting WoW ("admin 101"). Governing architecture rule: **the console is a client, never a brain.** It renders exactly four existing surfaces — the control contract (ADR-0102), the config schemas (third renderer, ADR-0029), the observability data (ADR-0034/0035), and the command registry (ADR-0082) — plus the declarative panel schema below. Anything the console can do, chat/CLI can do: two renderings of one kernel surface, same permission checks, same logging, same attribution.

### Contents
1. **Dashboard:** uptime, players online, world clock/pause state, tick health, memory/CPU per process and per mod, recent warnings; reference-machine baseline drawn in ("140 % of reference memory").
2. **Settings:** all schemas (kernel, AC conf, every mod's server scope) with search, grouping, requires-restart marking, and the restart queue (ADR-0103) with its button.
3. **Operations:** pause, save now, restart with countdown broadcast, backup list with restore (incl. per-mod, ADR-0111), mod enable/disable queue, the throttle tool (ADR-0090) with its "who is spamming" data alongside.
4. **Players:** all connected — name, character, role, session time, latency, zone, instance, RPC rate; per-player detail view with action buttons (kick/ban, `.appear`/`.summon`-class GM teleports, throttle). The tab is **a command palette rendered as UI**: every button binds to an already-registered command — kernel's own tabs use the same panel schema mods get. A Ctrl+K palette searches *all* registered commands with generated help.
5. **Logs:** faceted filtering (mod, level, player, time, free text) over the JSON-lines logs; per-mod log level changeable here; **per-player timeline tabs** (pre-filter on entity attribution — "why did Kalle lose his sword at 21:40" becomes one search); **crash tab** with post-mortems + minidump references, diffable mod lists between crashes (local mod-pair suspicion), and bug-report export.
6. **Chat + terminal:** read view of all channels; write as the admin identity in any channel, whisper, announce (optionally tagged `[Console]` — transparency toward players, configurable). A full **terminal tab**: prompt, history, tab completion generated from command declarations, output — the control contract's `execute_command` behind an xterm-style view. GM actions from the console are logged as GM actions; `world.integrity` sees them (ADR-0089). No back door, just a better door.

### Mod admin panels
Mods declare admin panels in the manifest — **not free HTML** but the same declarative UI schema as everything else: views (tables, forms, buttons) bound to their commands and KV data; the kernel renders. "Spawn bot" is `command_button("playerbots","spawn",args_schema)` — the same command as `/playerbots spawn`, same role requirements, same log. This kills the XSS class structurally, makes every panel permission-checked and validated against declared commands. Escape hatch: an iframe-sandboxed own page served from the mod's folder — hard-separated, labelled, control-contract access only via a postMessage bridge with the same permissions. The declarative path wins by laziness.

### Security (condition, not feature)
Bind **only** loopback + Tailscale interface (never 0.0.0.0 by default); token auth even locally (launcher or `modcraft console` emits a one-time link); roles throughout (tabs render only what the token's role may see, ADR-0107); CSRF protection and Origin checks from day one. Remote admin over the internet is never an open port — Tailscale or SSH tunnel, documented, full stop.

### History & timing
Metric series rolls into a small local time-series file (30-day default, configurable); logs per ADR-0106. Contract + panel schema are designed now (into the IDL, free); console v1 (dashboard/settings/operations) after step 1 when the control contract is built anyway; panels arrive the ring-3 way with the first needing mod (roguelike run stats and playerbots spawn buttons are already queued as claimants). Chat remains complete forever — the console is convenience, never requirement.
