# Analysis: Leyline as a possible starting point for our launcher

- **Status:** Input for later launcher work. Nothing here is decided; nothing is adopted.
- **Last reviewed:** 2026-11-05
- **Author:** manager, task 112, for Ludwig
- **Subject:** https://github.com/orionopenwow/Leyline at commit `747ecdd` (MIT; created 2026-10-25, 5 stars when read). Read only: nothing from it was built or run.
- **Measured against:** ADR-0043 (launcher), and ADR-0004, 0005, 0041, 0046, 0049, 0071, 0073, 0085.

## In short

**Recommendation: do not fork it. Build the launcher as ADR-0043 says, and borrow a short list of modules and ideas.** The decision rests on ADR-0043's shape (logic in a CLI, small v1), not on Leyline being poor: it is real, tested work, and it is worth reading when launcher work starts. Nothing forces the choice now, because ADR-0043's phase 0 has no launcher at all.

| Question | Answer |
|---|---|
| Same technology? | Yes: Tauri 2 with a Rust core, as ADR-0043 chose |
| Same target? | Largely: AzerothCore 3.3.5a, plus other versions through profiles |
| Licence allows reuse? | Yes for this repository: MIT code may go into our AGPL launcher, keeping its notice. See Caveats for the workspace repository |
| Thin shell over a CLI? | **No.** It is a large product; this is the main reason not to fork |
| Same trust model for mods? | **No.** Weaker than ADR-0041: a hash per artefact, no signature |

## Why World of Modcraft still has its own purpose

Leyline and this project overlap at the launcher and hosting, not at the core. **Leyline delivers addons and scripts; World of Modcraft is a modding platform where mods build on each other** (ADR-0001: "Forge/Fabric for Minecraft", "Skyrim modding for WoW").

| | World of Modcraft | Leyline (format 0.1, `mods/SPEC.md`) |
|---|---|---|
| What a mod is | Records, Lua and plugins, compiled by a kernel (ADR-0008) | A 3.3.5a addon and/or mod-ale Lua scripts |
| Extending another mod | `kernel.wrap` with `extends` declared in the manifest, chained in load order and logged with attribution (ADR-0021) | No equivalent found in the format (not a full read of the realm code) |
| Two mods changing one record | Merged per field; only a write to the same field conflicts, with a report (ADR-0009) | No record model in the format |
| Load order and dependencies | Computed from `depends`, `extends` and `load_after`; install order means nothing (ADR-0011) | Flat prerequisites and conflict checks (`ui/market.js`) |
| API | Three rings defined in one IDL (ADR-0020) | No kernel API; builds on addons and mod-ale |

This is also why the two can coexist: what we would borrow from Leyline is packaging around the platform, and none of it touches the kernel.

## What it is

Leyline is a mod launcher plus a peer-to-peer realm network: hosts run a realm on their own PC and reach players through a relay (`README.md`). The launcher is one part of the repository:

- **Stack:** Tauri 2, Rust, plain HTML/CSS/JS with no framework or bundler (`launcher/package.json`, `launcher/src-tauri/Cargo.toml`).
- **Size:** 47,941 lines of Rust (43,232 in `src-tauri/src`), 15,315 of JS and 10,923 of browser tests. 476 Rust tests. CI runs the Rust tests; its workflow does not reference the browser tests.
- **Runs on:** Windows, macOS and Linux; macOS and Linux run the Windows game through Wine (`launch.rs`).
- **Beyond a launcher:** forum and social features, the "Den" personal realm, Hero Key sign-in, an MCP server for AI agents (`src-tauri/src/`).

Paths below are under `launcher/src-tauri/src/` unless they say otherwise.

## Against our decisions

| ADR | Ours | Leyline | Fit |
|---|---|---|---|
| 0043 | Launcher wraps the CLI and has no logic of its own | Logic lives in a library crate inside the app. No mod-management CLI; `main.rs` has only `mcp`, `den-play` and `play-test` subcommands | **Conflict.** Its core/UI split (`--no-default-features`) and the headless MCP interface are a good start, but not our shape |
| 0043 | Phased, small v1 | One core holds forum, social, Den, agents | **Conflict** |
| 0041 | Hash and signature per artefact, immutable versions, verified locally | Catalog mods: SHA-256 from the same origin as the file (`mods.rs`), and "no review queue, no signing yet" (`launcher/README.md:72`). Upstream addons are stricter: reviewed by a person, pinned to a release or commit, hashed per file, native code refused (`upstream.rs`, `mods/SPEC.md`) | **Weaker than ours.** No signature, and for catalog mods whoever controls the site controls the hash |
| 0073, 0085 | Registry first; `.wompack` | Its own folder or zip with `mod.json` (`mods/SPEC.md`). Flat prerequisites and conflict checks in the UI (`ui/market.js`); no version constraints or graph | Different |
| 0005 | Validate against a manifest of files and hashes; no links to downloads | PE version plus a list of expected file names (`clients.rs`, `pe_version.rs`); can import a client from a user-supplied zip URL or torrent (`clientimport.rs`, `clienttorrent.rs`) | **Weaker check, and a legal risk.** Torrent code is in the default build, behind a testing switch that is off by default (`Cargo.toml`, `clienttorrent.rs`) |
| 0071 | Native Windows server and portable database for players | "Den Lite", a native server with no Docker or database, not AzerothCore (`host/lite.rs`); Docker for sharing with friends (`host/docker.rs`) | **Different.** Same goal of no Docker for players, by another route |
| 0046 | Invite codes, Tailscale; no platform-operated relay for now | A Leyline-run relay (`README.md`, `hosting/relay/`) | **Different.** ADR-0046 leaves a relay possible later |
| 0049 | Launcher is AGPL | MIT | Compatible one way: we may take it in, keeping the notice |
| 0043 | `modcraft://install/<id>@<version>` | `leyline://install\|realm\|host\|join`, no version (`deeplink.rs`) | Same shape; add the version |
| 0004 | Own assets only | No Blizzard files in the tree (`THIRD-PARTY-NOTICES.md`; file search) | Fits |

## Worth borrowing

In the order I would look at them. Each is an idea first; copying code keeps the MIT notice (see Caveats on its holder).

1. **Safe unpacking** (`mods.rs`, `safe_rel`, `extract_zip`): refuses path escapes, symlinks and password-protected archives; caps on size and file count. Fits behind `.wompack` unpacking.
2. **Install manifest per client** (`mods.rs`): lists every installed file so removal is exact, and never overwrites an addon the launcher did not install.
3. **Consent for native code keyed to a file digest** (`mods.rs`): a changed DLL asks again. Worth comparing with ADR-0012's plugins, though Leyline's DLLs are game-injected files and not a C ABI.
4. **Deep-link parser** (`deeplink.rs`, 315 lines): strict, tested, and a link never installs anything by itself.
5. **Updater hardening:** manifest URLs must stay under the project's own release path, and the update finishes at next start (`update.rs`). The signature check at run time is Tauri's updater plugin (`app.rs`), with backup keys from `branding.json`; the Rust `verify_minisign` is called only from tests. Our pipeline already uses minisign (registry `pipeline.yml`).
6. **Small practical pieces:** PE version detection (`pe_version.rs`, 105 lines), and backing up `realmlist.wtf` before changing it (`clients.rs`).
7. **Testing the UI without a webview:** browser tests against a fake Tauri core (`launcher/tests/`), and core tests with no webview.
8. **CI habits:** actions pinned by commit, `--locked` (`.github/workflows/leyline-launcher.yml`). Our registry workflows already pin actions.
9. **Worth a look at the product level:** "the play bar is the whole play flow" (`README.md`) is a clean answer to ADR-0043's Play button. The upstream review flow (`upstream.rs`) is worth reading for legacy addons. `hosting/` was not read in depth.

## Do not take

- **The catalog trust model:** a hash from the same origin as the file, native code allowed after one click for catalog mods and local zips.
- **Torrent or URL import of game clients:** ADR-0005 keeps us out of locating game data.
- **Typing into the game window** (`denclick.rs`, Windows `PostMessageW`) and **login-screen Lua through a `patch-Z.MPQ`** (`hybrid.rs`): fragile, in my judgement, and they read badly from a security view.
- **Downloaded helper binaries checked only against a checksum from the same release** (`host/forge.rs`). Den Lite's source is not in this clone; it is in the public workspace repository under `labs/den-lite`.
- **Unsigned installers:** ADR-0094 defers code signing for us too, so this is no difference today, only a known cost.
- **Hard-coded services:** Leyline domains in `addresses.rs`, a table of links in `lib.rs`, and the CSP. `launcher/scripts/rebrand.py` handles renaming, but not the behaviour behind those services.

## Fork or not: both sides

**What favours forking:**
- The Rust core builds and tests without a webview, with 476 tests.
- Safe unpacking, the install manifest, a signed updater, Wine launch and deep links already work, or at least have tests (nothing was run here).
- The workspace source is public, so following upstream is possible.
- MIT lets us take it, and it could save weeks of shell and packaging work (my estimate, not measured).

**What decides against it:**
- **It would invert ADR-0043.** That ADR puts logic in the CLI so it exists without a launcher. Starting here makes the app the owner of the logic, and the CLI would have to be carved out of it.
- **Most of it is not what we would keep.** The modules listed above (`mods`, `update`, `deeplink`, `pe_version`, `clients`, `launch`) are about 5,000 of 43,232 lines, roughly 12 %, and `mods.rs` needs rewriting for our registry. This is a count by file, and it does not measure how tangled the rest is.
- **The trust model is the centre of ours.** ADR-0041 and the registry are what this platform has spent its first mission building.
- **A fork would carry a fast-moving product** that adds features we do not want. The history here cannot show its real pace, since this repository receives batch imports (24 commits, "Copy from WrathUnleashed <hash>").

**What would change my mind:** if we drop the CLI-first rule in ADR-0043, or if launcher time becomes the project's main constraint. Either is a decision for you, and it can wait until the CLI exists.

## Caveats

- **Claims in its docs drift from its code.** `launcher/README.md:7` says "No telemetry", while `lib.rs` documents an anonymous install count and `settings.rs:79` defaults `count_installs` to true. Read the code, not the prose.
- **Code quality was not judged line by line.** Volume and style suggest heavy AI assistance (inference: comments quote owner instructions, large volume over a short time). The tests and hygiene look serious, but nothing was run.
- **Licence, two points.** `LICENSE` names "WrathUnleashed contributors", while `launcher/src-tauri/Cargo.toml` and `tauri.conf.json` say Leyline contributors: keep the notice as written. **The workspace repository `orionopenwow/leyline-workspace` is public, but GitHub detects no licence for it (checked 2026-11-05).** Take code from this MIT repository, not from there, until that is clear.
- **Game data and torrents, added after task 113.** The tree has no Blizzard files, but Leyline's streamed mode serves part of the game's data from its own server. Its `leyline-workspace: docs/GAME-DATA-ON-OUR-SERVER.md` calls this temporary with a killswitch, says the owner's direction is no game data on that server, and states the rule "No torrents and no whole-client downloads", with P2P carrying only its own open content. That sits awkwardly with the testing switch in `clienttorrent.rs`, but the torrent section below should be read with it. See `rust-clients-usability-survey`.
- **Not read in depth:** `hosting/` (relay and kit), `realm/`, `stream/`, the workspace repository, and whether the `terrain` crate is clean-room as it states.
- **Not determined:** whether the updater and deep-link plugins work with the listed Tauri capabilities (`Cargo.toml` has no deep-link plugin dependency); whether any Windows build is code-signed.
- **Snapshot:** everything is as of `747ecdd`, and the project changes daily. Re-read before relying on any detail.

## Ideas raised by Ludwig (2026-11-05, not decided)

### Torrent for mods
- **Fits well:** ADR-0041 verifies hash and signature after download, so the source of the bytes does not matter; a tampered file is refused.
- **Two rules:** the launcher fetches only what the registry names, by id and hash, with no field for pasting an arbitrary magnet link. Seeding is opt-in, because a seeder's IP address is visible to the swarm.
- **Not urgent:** mods are small and GitHub Releases is enough for now (ADR-0103). Worth reconsidering if large asset mods or hosting limits appear; ADR-0077's disaster mirror is the related decision.
- **Not for the game client:** Blizzard no longer sells 3.3.5a (ADR-0005), so such a feature points in practice at unauthorised copies. "It is up to the user" is a weak defence for a feature built for that purpose, and a takedown could hit the organisation and the registry that all mods come from. Legal counsel, not this note, would have to say more. Recommendation: leave it out; ADR-0005 stands.

### Relay for hosting
Described from Leyline's docs (`hosting/README.md`, `docs/leyline/network.md`, `be-a-node.md`); the code was not read.

- **How it works:** the host's PC opens one outbound connection to the relay, with no open ports. A stock 3.3.5a client sets `realmlist` to the relay, which has a raw TCP port per realm. Players do not see the host's home address. The relay applies per-IP limits and checks invites before admitting anyone. Volunteers can run extra relay nodes.
- **Why it matters:** it removes the largest step in playing with friends, and that is our audience (ADR-0002).
- **Already an open question:** Q3 in `docs/open-questions.md` defers a platform-operated relay until telemetry shows connection failures are common.
- **Against ADR-0046:** today's answer is invite codes and Tailscale, with "no platform-operated relay (possible later without architectural change)". Tunnels are a generic interface there, so a relay can join without a rewrite.
- **Costs of running one:** a running expense and operations, when the platform so far hosts nothing; responsibility for traffic passing through, including abuse; a single point of failure for whoever depends on it.
- **Recommendation:** make the relay a program anyone can run on a small VPS, offered beside Tailscale. Players get the same simple flow, and the project need not operate a service from day one. A platform-run relay can remain a later choice. This belongs to the launcher and server phase; if adopted, it needs an ADR amending ADR-0046. Leyline's `hosting/` code (in the MIT repository) is the reading material.

## If you want to take this further

- **Next step when launcher work starts:** a short task that reads items 1 to 5 above and specifies our versions behind the CLI, with their licence notice.
- **Possible contact:** the projects overlap, and bug fixes or the safe-unpack code could flow both ways. Nothing has been sent to them; that is your call. ADR-0060 (public but unannounced) applies, and it allows private, targeted contacts.
