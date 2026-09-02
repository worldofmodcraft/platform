# World of Modcraft — Decision Log

This directory is the platform's memory. One file per decision, numbered and dated.
Files are **immutable in substance**. Two — and only two — ways to change the record:

1. **Supersede** (the decision was wrong or is replaced): write a new ADR; set the old one's
   status to `Superseded by ADR-NNNN`. The old file's substance is never edited.
2. **Amend** (the decision stands but gains requirements/refinements): write a new ADR whose
   header carries an explicit `Amends:` list naming every affected ADR, with one section per
   amendment; then add a metadata line `- **Amended by:** ADR-NNNN (<one-line summary>)` to
   each affected ADR's header. Cross-reference metadata is the only thing ever added to an
   accepted ADR — its substance remains untouched. Nothing may live only in the amending ADR's
   body without the back-reference: a reader of any ADR must see, from its header alone, that
   amendments exist. (Reference example: ADR-0115.)

Editing the substance of an accepted ADR is forbidden in both cases.

Every ADR has: Status, Date, Area, Related, Context, Options considered, Decision,
Consequences, Interacts with. Short ADRs may fold sections together.

Design documents in `docs/design/` synthesise these decisions per area and list which ADRs
they implement. Deferred topics live in `docs/open-questions.md`.

**How the AI must use this log:** read the index below at the start of every session; open the
ADRs relevant to the task before proposing or writing anything; never contradict an accepted
ADR silently — propose a superseding ADR instead.

## Index

### Vision & governance
- [0001](0001-platform-is-the-goal.md) The platform is the goal; the roguelike is the first mod
- [0002](0002-target-audience.md) Target audience: self-hosted, single-player and small groups
- [0003](0003-naming.md) Naming (World of Modcraft, `modcraft`, `mc:`, `modcraft://`)
- [0004](0004-own-assets-only.md) Own assets only; never Blizzard data
- [0005](0005-game-data-is-the-users-responsibility.md) Game data is the user's; platform validates only
- [0006](0006-openness-and-handover.md) Openness is the defining trait; designed for handover
- [0056](0056-english-throughout.md) English throughout
- [0057](0057-warcraftxl-related-project.md) WarcraftXL: related project, different path

### Architecture
- [0007](0007-fork-wowee-and-azerothcore-monorepo.md) Fork WoWee and AzerothCore; monorepo
- [0008](0008-mod-anatomy-and-record-compiler.md) Mod = records + Lua + plugins; kernel compiles records
- [0009](0009-field-level-merge.md) Field-level merge
- [0010](0010-no-sandbox-total-observability.md) No sandbox; total observability
- [0011](0011-load-order-and-dependencies.md) Load order computed; install order does not exist
- [0012](0012-native-plugins-two-tiers.md) Native plugins via C ABI, stable/unsafe tiers
- [0013](0013-id-allocation-registry-ranges.md) Namespaced IDs, registry-assigned numeric ranges
- [0014](0014-kernel-language-and-shape.md) Kernel: C++ in-process library; separate offline tooling
- [0015](0015-lua-dialect.md) Lua 5.4 everywhere; FrameXML isolated
- [0016](0016-overlay-client-data-from-the-start.md) Overlay data format from the start
- [0017](0017-world-db-base-plus-delta.md) World DB: pristine base + compiler-owned delta
- [0018](0018-components-on-top-with-facade.md) Components on top, behind a facade
- [0019](0019-client-agnostic-kernel.md) Client-agnostic kernel API
- [0020](0020-api-rings-and-idl.md) Three API rings; one IDL
- [0021](0021-extending-other-mods.md) Extending other mods only through the kernel
- [0022](0022-cpp-scripts-vs-mod-lua.md) C++ scripts vs mod Lua: layered; ported on demand
- [0023](0023-lua-state-on-reload.md) Lua state on reload: KV or gone
- [0024](0024-instancing-api.md) Kernel-owned instancing
- [0025](0025-world-clock-toggle.md) Per-world clock mode (wall / world) and pause
- [0032](0032-capability-tags.md) Capability tags
- [0033](0033-asset-overlay.md) Asset overlay

### Compatibility
- [0026](0026-eluna-break-framexml-kept.md) Eluna break; FrameXML kept; overlay-aware legacy API
- [0027](0027-blizzard-client-debug-only.md) Blizzard client: debugging only

### Mod format, permissions, configuration
- [0028](0028-permissions-transparency.md) Permissions: declared, displayed, not negotiated
- [0029](0029-mod-config-schema-driven.md) Everything configurable; schema-driven config
- [0030](0030-manifest.md) Manifest and folder structure
- [0031](0031-roles-and-permissions-on-server.md) Server roles and namespaced permissions
- [0044](0044-modpacks.md) Modpacks first-class
- [0048](0048-platform-updates-and-placeholders.md) Platform packages; placeholders for missing mods

### Observability & telemetry
- [0034](0034-observability-contract.md) Observability contract
- [0035](0035-tracing-defaults-and-tools.md) Tracing defaults and tools
- [0036](0036-telemetry.md) Opt-in diagnostics sharing
- [0037](0037-mod-health-and-flagging.md) Mod health, conflict detection, flagging
- [0038](0038-flag-deletion-is-covered.md) (reserved; folded into 0036/0037)

### Registry, site, launcher
- [0039](0039-registry-as-git-repo.md) Registry as git repo; namespace = GitHub username
- [0040](0040-verified-builds.md) Verified builds; all source open; signed
- [0041](0041-integrity-chain-and-archiving.md) Integrity chain; archiving; nothing unpublished
- [0042](0042-updates-and-versioning.md) Updates, versioning, rollback, server profiles
- [0043](0043-launcher.md) Launcher: Tauri shell over CLI; phases
- [0045](0045-backups.md) Rolling, configurable, verified backups
- [0046](0046-content-rules-and-connectivity.md) Content rules; connectivity (invite codes, Tailscale)
- [0047](0047-world-migration-and-kernel-majors.md) World migration; parallel kernel majors
- [0049](0049-licensing.md) Licensing: AGPL platform, MIT SDK, any OSI for mods

### Process & developer experience
- [0050](0050-build-order-walking-skeleton.md) Build order: walking skeleton + vertical slice
- [0051](0051-modder-first-evening-and-dev-mode.md) Mod author's first evening; dev mode
- [0052](0052-testing-and-soak.md) Testing and soak
- [0053](0053-ai-ready-tooling.md) AI-ready mod development
- [0054](0054-documentation-first-and-manager-model.md) Documentation first; survey first; manager model
- [0055](0055-wowee-defects-tracked.md) WoWee polish tracked


### Rounds 3–6 (development practice, runtime reality, product surfaces)
- [0060](0060-public-but-unannounced.md) Public but unannounced until stable release (Ludwig's sole call)
- [0061](0061-ai-generated-assets.md) AI-generated assets permitted (originality rule)
- [0062](0062-335a-only-kernel-is-the-server-core.md) 3.3.5a only; the kernel fork is the only server core
- [0063](0063-forks-via-git-subtree.md) Forks via git subtree with history
- [0064](0064-upstream-merge-cadence.md) Upstream merges milestone-gated
- [0065](0065-idl-lua-table-format.md) IDL: own minimal Lua-table format
- [0066](0066-rpc-wire-format.md) RPC wire: IDL-generated binary + JSON debug mirror
- [0067](0067-reproducible-dev-environments.md) Reproducible dev environments
- [0068](0068-task-ledger-as-files.md) Task ledger as files; Issues as future inbox
- [0069](0069-trunk-based-releases.md) Trunk-based; platform packages as signed tags
- [0070](0070-issue-inbox-automation.md) Automated issue triage into the task inbox
- [0071](0071-windows-native-server-for-players.md) Native Windows server + portable DB for players
- [0072](0072-login-keep-protocol-hide-concepts.md) Login: keep the protocol, hide the concepts
- [0073](0073-mod-delivery-registry-first.md) Mod delivery: registry first, HTTP sidechannel for the rest
- [0074](0074-save-cadence.md) Save cadence: aggressive & configurable in world mode
- [0075](0075-all-locales-accepted.md) All client locales accepted
- [0076](0076-worlds-one-active-schema-per-world.md) Worlds: one active; per-world schemas; process = world
- [0077](0077-disaster-mirror.md) Disaster mirror of platform storage
- [0078](0078-public-server-directory.md) Public server directory (phase 3)
- [0079](0079-contract-first-backend.md) Contract-first backend
- [0080](0080-lazy-evaluation-principle.md) Compute on observation (lazy-evaluation principle)
- [0081](0081-reference-machine.md) Reference machine: Ludwig's PC
- [0082](0082-chat-commands-primitive.md) Chat commands as ring-1 primitive
- [0083](0083-world-overlay-rendering.md) World-anchored overlay rendering (ring 3)
- [0084](0084-mod-audio-api.md) Mod audio API
- [0085](0085-wompack-format.md) `.wompack` package format
- [0086](0086-auto-pause-when-empty.md) Auto-pause when empty
- [0087](0087-client-settings-two-tier.md) Client settings: personal global, mod per-profile
- [0088](0088-characters-per-world.md) Characters are per world
- [0089](0089-gm-play-and-integrity.md) GM play: self-discipline, logged; world.integrity read API
- [0090](0090-runtime-failure-and-throttling.md) Runtime failure: never auto-disable; admin throttle
- [0091](0091-kernel-rng.md) kernel.rng seeded randomness
- [0092](0092-safe-reposition.md) Safe reposition for invalid locations
- [0093](0093-native-crash-minidumps.md) Native crash minidumps + persistent ring buffer
- [0094](0094-code-signing-deferred.md) Code signing deferred; pipeline slot ready
- [0095](0095-name-risk.md) Name kept; renaming kept cheap
- [0096](0096-achievements.md) Achievements: kernel service in Blizzard's UI


### Round 7 + web console (build practice II, product policy, the server console)
- [0097](0097-roguelike-kit-reaudit.md) Roguelike kit re-audit → v17 before step 1
- [0098](0098-repo-layout-and-org-responsibilities.md) Monorepo layout; org repo responsibilities (distribution end)
- [0099](0099-ci-gates.md) CI gates: path-filtered + nightly full, stop-the-line
- [0100](0100-cli-distribution.md) CLI distribution: static binaries, bundled with launcher
- [0101](0101-db-engine-in-platform-package.md) DB engine pinned in the platform package
- [0102](0102-control-channel-soap-then-contract.md) Control channel: SOAP now, contract later
- [0103](0103-restart-is-the-unit.md) Restart is the unit; prefer boring solutions (constitution rule)
- [0104](0104-no-paid-mods.md) No paid mods; funding links welcome
- [0105](0105-config-precedence.md) Configuration precedence
- [0106](0106-log-rotation.md) Log rotation (10 sessions + crashes)
- [0107](0107-observability-access-by-role.md) Observability access layered by role
- [0108](0108-day-boundary.md) day_boundary and kernel day services
- [0109](0109-kernel-http.md) kernel.http outbound API
- [0110](0110-clientmods-and-policy.md) Clientmods category; server clientmod policy/whitelist
- [0111](0111-per-mod-restore.md) Per-mod backup restore
- [0112](0112-web-console.md) The server web console
- [0113](0113-documentation-as-a-product.md) Documentation as a product
- [0114](0114-api-gap-review.md) API gap review: missing surfaces, read principle, automations
- [0115](0115-roguelike-lessons.md) Lessons inherited from the roguelike project (amends 9 ADRs)
- [0116](0116-adr-compliance.md) ADR compliance: gates first, indexed selection, bidirectional review
- [0117](0117-dependency-graph-and-contracts.md) Dependency graph before code; edges name contracts
- [0118](0118-upstream-strategy.md) Upstream survival: thin patch surface, drift radar, contribute back

## Template for new ADRs
See [TEMPLATE.md](TEMPLATE.md).
