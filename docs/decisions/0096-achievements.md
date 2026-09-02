# ADR-0096: Achievements — a kernel service on the Steam model, wearing Blizzard's UI

- **Status:** Accepted · **Date:** 2026-09-02 · **Area:** Ring 2 / Content
- **Related:** ADR-0016, ADR-0018, ADR-0026, ADR-0032, ADR-0089

## Decision
The kernel owns a complete achievement service (`mc:achievements`, a core mod) from the start — Steam model: platform owns presentation, tracking and storage; mods declare content.

- **Mods write records + events only:** an achievement record (name, description, icon, hidden/visible, points, criteria) — zero UI code, zero tracking code.
- **Two tracking backends behind one facade** (the ADR-0018 pattern): criteria matching Wrath's ~70 built-in types compile to real DBC records via the overlay and are tracked by AC's AchievementMgr (free, proven); everything else ("win three arcade tournaments") is tracked by the kernel via event counters (the simple path, covering ~90 %) or Lua evaluators, persisted in KV. **The mod author never sees which backend applies.**
- **Blizzard's achievement panel is the UI, rebuilt inside:** in our client fork, the achievement C API (`GetAchievementInfo` etc.) reads from the kernel service's merged truth — same move as `GetSpellInfo` over the overlay (ADR-0026). The player presses Y and sees everything: vanilla and all mods, custom categories per mod, kernel-driven progress and toasts, in the UI they know. The shell is *extended* in our fork (mod attribution in tooltips, filter row, layout fixes for many categories), not paralleled. FrameXML achievement addons keep working and see more data (goes into compatibility testing).
- **Format frame:** an achievement looks like a Wrath achievement (name, icon, points, up to ~10 criteria rows) — the frame *is* the Steam-like uniformity; a mod with wholly custom trophy presentation builds its own panel via the UI framework as the exception.
- **Scope and coupling:** achievements are per world (ADR-0088-consistent); a cross-world meta-profile is a possible phase-3 portal feature (open questions). `requires_clean = true` on a record makes the service consult `world.integrity` (ADR-0089) — no mod writes that logic. `provides = {"achievement_source"}` lets mods grant across mods without hard dependencies.

Achievements thereby become a fourth early-stabilisable ring-2 surface: all three driver mods can declare achievements on day one without building infrastructure.

**Survey bench:** how hard-coded criteria types are in AC's AchievementMgr; where the client reads criteria progress in the protocol; whether achievement DBCs are in WoWee's parser.
