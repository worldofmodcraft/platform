# Open Questions (deferred, not forgotten)

Each entry: what, why deferred, what would trigger deciding it.

| # | Question | Deferred because | Decide when |
|---|----------|------------------|-------------|
| Q1 | **UI ownership between mods** — two mods want the same client UI surface (e.g. a minimap button). Who wins where? | Client UI framework does not exist yet | After step 1 shows the real client UI |
| Q2 | **Kernel 1.0 criteria and the stability promise** (proposed: ring 1 unchanged through one minor; ≥2 external mods; migration corpus green) | Not important during 0.x where everything may break | When the first external mod exists |
| Q3 | **Platform-operated relay/tunnel** for NAT traversal | Tailscale guide covers it; relay is an operating cost | If telemetry shows connection failures are common despite the guide |
| Q4 | **Full ECS migration** of the object model | Years of work; facade (ADR-0018) hides the boundary | Only if the facade proves insufficient for real mods |
| Q5 | **Instance export between servers** ("portable rooms") | It is world export in miniature | When world export exists (launcher phase 2) |
| Q6 | **Extending the legacy FrameXML API** with overlay-only fields | Legacy layer should stay legacy | If many addon-mods request it |
| Q7 | **World editor** strategy (WoWee's experimental editor vs. own) | Not needed for steps 0–1 | Before custom zones (ring 3) |
| Q8 | **Roguelike: one large mod or a modpack of separable mods** | Roguelike design decision, not platform | When the design kit moves under the platform |
| Q9 | **Graphical record editor** (JSON-writing) for non-programmers | Format already allows it; audience later | After external mods exist |
| Q10 | **Cloud sync of backups** to user storage | Small add-on to rolling backups | After ADR-0045 is implemented |
| Q11 | **Transparency log (Sigstore-style)** for signatures | Overkill in hobby phase; `key_id` keeps the door open | If the platform grows beyond a handful of authors |
| Q12 | **Custom zones / open-zone instancing / vmaps from glTF** | Heavy C++ work | Ring 3 milestone after step 1 |
| Q13 | **Session record/replay as tests** | Fragile against protocol changes | When our own regression tests need it |
| Q14 | **Day/night follows world time or wall time** default | Small per-world setting | When the clock (ADR-0025) is implemented |
| Q15 | **Exact Claude Code subagent/model configuration** for the manager model | Must be verified against current documentation | When the manager guide is written (roster now exists in docs/manager/agents/; verify at first run) |
| Q16 | **Multi-provider identity** (namespaces beyond GitHub accounts) | Registry format is already provider-agnostic (ADR-0058) | When the phase-3 portal introduces its own accounts |
| Q17 | **Group teleport primitive** — `instance:admit(players)` / `instance:evict(player, return_to)` with guaranteed origin restore even across crashes | Needs a real instance-mod to shape it | With the arcade/housing driver mods (extends ADR-0024; pairs with ADR-0092) |
| Q18 | **Player-state snapshot/restore primitive** scoped to an instance stay ("everyone is level 60 with equal gear in this match") | Ring 3 rule: driven by real need | When a minigame/arena mod demands it |
| Q19 | **Cross-world achievement meta-profile** (opt-in sync of unlocks to a portal account) | Breaks the world boundary; needs phase-3 accounts | Phase 3, if wanted (ADR-0096) |
| Q20 | **Winget distribution** of the launcher | Eases SmartScreen friction without a certificate | Around stable release (ADR-0094) |
| Q21 | **Reference machine specs** — Ludwig to supply CPU/RAM/GPU/disk/OS + WSL-vs-native measurement mode | Awaiting specs | Fill docs/reference-machine.md when provided (ADR-0081) |
| Q22 | **Console spectator view** — world map with player dots via overlay data in a console panel | Ring 3 seed, someone builds it | If/when a mod or the community wants it (ADR-0112) |

## Deferred to the roguelike design kit
- Which of the 21 locked roguelike decisions change now that WoW-specific limits (DBC fields, client patches) are gone.
- Migration path for the existing M0 server (reference only per ADR-0050).
