# Survey: Rust WoW clients, and what makes this kind of software easy to use

- **Status:** Input for later client and launcher work. Nothing here is decided; nothing is adopted; no ADR is changed.
- **Last reviewed:** 2026-11-05
- **Author:** manager and surveyor, task 113, for Ludwig
- **Why:** Ludwig's goal, "så pass användarvänligt som möjligt".
- **Method:** Code and docs read at the commits below. **Nothing was built or run**, so every player walkthrough here is from reading, not from trying. GitHub figures are from its API on 2026-11-05. Not legal advice.

| Project | What it is | Commit | Licence |
|---|---|---|---|
| [benilla](https://github.com/samwhosung/benilla) | 1.12.1 client, Rust and Bevy, 932 stars | `a1079ce` | MIT or Apache-2.0 |
| [benilla-wotlk](https://github.com/Onixaz/benilla-wotlk) | 3.3.5a port of it, our game version, 71 stars | `271c320` | MIT or Apache-2.0 |
| [benilla-wasm](https://github.com/iamstupidplaceholder/benilla-wasm) | Browser port of benilla, 1.12.1 only | `983f1af` | MIT or Apache-2.0 |
| [leyline-workspace](https://github.com/orionopenwow/leyline-workspace) | Leyline's source, including a browser client built on benilla-wotlk | `9906e4f` | **No root licence: ideas only** |
| [Leyline](https://github.com/orionopenwow/Leyline) | Launcher (see `leyline-launcher-analysis`) | `747ecdd` | MIT |
| [WoWee](https://github.com/Kelsidavis/WoWee) | Our chosen client (ADR-0007), 1,024 stars. Only its licence and releases were read for this note | not pinned | **See below** |

## In short

1. **A licensing problem was found by accident, and it matters more than the rest of this note.** WoWee is not plain MIT, and our licensing decision assumes it is. See the next section.
2. **Why Rust:** none of them says. The visible reasons are one codebase for desktop and browser, and format readers that need no game engine (inference).
3. **Usability:** nobody has solved the whole path. The cheapest large gain: decide now that a player never needs a terminal or a config file, and write the error messages before the code.
4. **benilla-wotlk is the strongest alternative client seen, and this survey does not recommend switching.** The architecture (ADR-0014, ADR-0007) decides that today, not its quality. The licence finding raises the question.

## WoWee's licence does not match ADR-0007 and ADR-0049

**What the files say** (read 2026-11-05):
- `LICENSE` is headed "MIT License (with Additional Restriction)": "the Software may not be used, in whole or in part, as the basis for, or as a component of, any commercial video game or other commercial game product", without written permission.
- `NOTICE`: "The restriction was added on 2026-07-21. Code published before that date carried plain MIT terms and those terms stand for what was published under them".
- Music and audio are all rights reserved and "not to be copied ... or used in any derivative work" (`LICENSE`, `NOTICE`).

**What our decisions say:**
- ADR-0007 (2026-08-31) calls WoWee "an MIT-licensed native C++/Vulkan client".
- ADR-0049 makes the client fork AGPL-3.0: "WoWee is MIT, we tighten it". It also has fixes for upstream written "under MIT first".
- A word search of `docs/` finds no mention of the restriction. The ADRs were written after it was added.

**Why it matters (my reading; a lawyer should confirm):**
- **We are not commercial.** ADR-0104 rules out paid mods, so the restriction itself may not bite on our own use.
- **The conflict is with AGPL.** AGPL allows no further restrictions beyond its own, and it lets anyone use the code commercially. A work that must both carry a no-commercial-games clause and be under AGPL looks impossible to license cleanly. `libmodcraft`, also AGPL by ADR-0049, runs in the client.
- **The openness goal is affected too.** ADR-0006 designs for handover and ADR-0040 for open source. A restriction on the client passes on to whoever builds on the platform.
- **The audio cannot come along.** A fork has to remove WoWee's music and audio.

**Nothing has gone wrong yet.** The repository has no `client/` directory: no fork exists, and this is found before phase two.

**Options for Ludwig (a decision for before the phase-two mission; none taken):**

| | Option | For | Against |
|---|---|---|---|
| A ★ | Ask WoWee's copyright holders in writing, and have a lawyer read the answer: may an AGPL, non-commercial platform fork it, and on what terms? | Keeps ADR-0007 and ADR-0049 if the answer is yes | Contact is Ludwig's call; "Wowee Contributors" may be several people |
| B | Fork the last plain-MIT commit, from before 2026-07-21, without the audio | Clean under its own terms, per `NOTICE`; ADR-0049 stands | Loses everything since; fixes from upstream cannot be taken in; how much that is was not measured |
| C | Keep WoWee's terms for the client and amend ADR-0049 | Simple | Weakens "no closed World of Modcraft", and the clash with AGPL `libmodcraft` remains to solve |
| D | Use benilla-wotlk as the client | MIT or Apache-2.0; in Rust; shows a browser path | Large redesign of ADR-0014's client side; see below |

★ A, because it costs one message and tells us whether the others are needed. B is the fallback if no answer comes.

## Why Rust

- **Stated reasons:** none found in the READMEs, method documents or contributor guides. They state the fact, "written from scratch in Rust and Bevy" (`benilla/README.md:3`), and a principle, "Modern Bevy and Rust, performance woven in from the start" (`benilla/docs/METHOD.md:25`).
- **Sharing with the browser (the motive is inference; the numbers are counts):** benilla-wasm calls itself a "standalone source snapshot, not the development repository" (`README.md:6`). 653 lines mention `wasm32`, in 108 of 1,518 Rust files. It shares the protocol and file-format crates and adds browser-only ones. So the same code runs in both places, but it is not free.
- **AI assistance:** stated for benilla, "Working with an AI agent is expected" (`docs/CONTRIBUTING.md:204`).
- **A correction:** I first told Ludwig I had found few Rust clients. His impression of a trend was right. A GitHub search lists benilla, games on it such as `world-of-skatecraft` and `world-of-kartcraft` (descriptions read, code not), `benilla-wotlk` and `benilla-wasm`.

## benilla-wotlk against WoWee

- **State, in its own words:** "can authenticate, enter the world, and run the stock 3.3.5a interface, but parts of the data and gameplay layers still use 1.12.1 layouts or behavior." "Warden will come later." (`README.md:18-21`.) English client only (`README.md:47`).
- **Size and pace:** about 874,000 lines of Rust and 9,152 tests by count; version 0.1.0. 100 commits between 2026-10-28 and 2026-11-05 in this clone, 99 of them by one author.
- **Extending it:** upstream does not accept features the original client lacks (`docs/CONTRIBUTING.md:28-32`). They go in your own crate through `benilla_app::run_with`, which "promises no stable API", or in a fork. No kernel, ABI or mod API.

**The case for it:** on our version, runs the stock interface and addons, heavily tested by count, a clean permissive licence, a simple drop-in model, and the only 3.3.5a browser base seen (Leyline's browser client is a patch series on it, `leyline-workspace: client/patches/series.txt`).

**The case against it, and why this survey does not recommend it:** ADR-0014 makes the kernel a C++ in-process library, with hooks as plain C++ calls, and rejected an all-Rust design; ADR-0007 chose a fork for source access. A switch means redesigning that boundary. It is a port in progress, with 1.12 behaviour left and one main author. ADR-0019 keeps the kernel API free of WoWee types, but says this is "hygiene, not a plan to support other clients".

**What this survey did not do:** compare WoWee's own state or usability. So "keep WoWee" rests on the ADRs and not on a comparison. If option A above fails, that comparison is the next task.

## The player's path today

As far as docs and code show; nothing was run. "Terminal" counts moments needing a command line, by my count.

| Step | benilla | benilla-wotlk | Leyline browser | Leyline launcher | WoWee |
|---|---|---|---|---|---|
| Get it | No prebuilt downloads (`README.md:58-59`); its GitHub releases have no files. Install Rust and a C compiler, build | Build from source. A release workflow exists (`.github/workflows/release.yml`), but **GitHub lists no releases yet** | Open a URL. Needs WebGPU, such as recent Chrome or Edge | Download. Builds are unsigned, so SmartScreen's "Run anyway" | **Prebuilt for Windows, macOS, Linux, Android** (v3.1.54) |
| Game files | Environment variable or a folder beside the program | Drop-in: copy `benilla.exe` beside `Data/`; refuses to run elsewhere (`README.md:78-83`) | Streamed (part of the world only), or drag your folder onto the page for the whole world | Find your 3.3.5a folder; there is a help page | Not read |
| Connect | Realmlist button | `realmlist.wtf`, as Wow.exe | Sign in, Play now | Pick a realm, press Play | Not read |
| Mods | Copy addons by hand | Copy into `Interface/AddOns` | From Leyline's hub | Drop a zip, or Discover then Install | Not read |
| Update | `git checkout <tag>`, rebuild | Rebuild, or replace the file when releases exist | Not stated | Updater that never restarts a running game; it needs the owner's key setup (`launcher/README.md:53-57`) | Not read |
| Terminal | 4 or more | Build from source today; 0 for a drop-in once releases exist | **0** | **0 on Windows** | Not read |

benilla-wasm is left out of the table: it is 1.12.1 only, and its server owner builds or receives a bundle and runs it with Docker (`deploy/README.md`).

### Error messages, quoted

- **Good:** benilla's window lists where it looked and gives two fixes: "benilla needs a World of Warcraft 1.12.1 install and found none. It looked in: ..." (`crates/benilla-app/src/no_install.rs:56,61`).
- **Good:** Leyline names the file: "No common.MPQ found", "lichking.MPQ is missing", "One archive is not enough" (`docs/leyline/play.md:47,49`), and "No game client found here. Pick the folder that holds the game's .exe and its Data folder." (`launcher/src-tauri/src/clients.rs:282`).
- **Bad:** benilla-wotlk has no such window. Built from source it prints "benilla: no WoW install found — looked in ..." to the error stream and keeps booting (`crates/benilla-app/src/lib.rs:388-392`). The standalone build refuses to start, again with an error-stream message only (`lib.rs:297-304`). No window attribute or dialog library exists in its code, so on Windows a player may see little (inference).
- **Mixed:** Leyline's fallback "Something went wrong. Try again, or ask on the Discord." (`launcher/ui/friendly.js:8`) is kind. Messages written for players pass through, and the technical text goes only to the console, so a helper cannot see it from the window.
- **Weak everywhere:** nobody tells "server down" from "wrong version" from "wrong password" in one place. Leyline's advice for connection trouble includes deleting the Cache folder by hand (`docs/leyline/getting-started.md:67`). On a server with Warden, benilla disconnects after a timeout (`benilla/README.md:72-74`); no explanation to the player was seen (inference).

### A warning: game data on a server

Leyline's streamed mode serves part of the game's data from its own server, with a budget of 7,424 MB, a figure its document marks uncertain (`leyline-workspace: docs/GAME-DATA-ON-OUR-SERVER.md`, `stream/slices/mini.json`). To be fair: that document says the owner's direction is "no game data served from our Hetzner server", that this sampler runs until community realms carry players and has a killswitch, and that "No torrents and no whole-client downloads" is a standing rule. benilla-wasm's gateway likewise serves the server owner's own game files to browsers (`deploy/README.md:3-4`).

The ease of "open a URL and play" is partly bought this way, and **ADR-0005 rules it out for us.** The clean version is the own-files mode: drag your folder onto the page, read locally, never uploaded (`docs/leyline/play.md`).

## Proposals for World of Modcraft

### Cheap now: a spec or a document

1. **Make the player's path a measurable target.** Download to in-world with zero terminal and zero config-file edits, tested on a clean Windows machine. Fits ADR-0051 (which sets "under one hour" for modders) and ADR-0071. ADR-0113 never uses the word "player", so a player-guide layer needs adding.
2. **Write an error catalogue before the code.** Every entry: an id, one plain sentence, the fix, a link to docs, shown in a window and not in a log, with the technical detail one click away. Extends ADR-0051's error rule from modders to players; fits ADR-0113.
3. **Make validation speak plainly.** ADR-0005's check should read the build from the files, name a wrong version in words, and list what is missing. A "where your files usually are" table (Leyline's idea) concerns the user's own disk, but check it against ADR-0005's "no responsibility for locating game data".
4. **Keep config out of the player's hands.** ADR-0072 has the launcher own the login flow, and ADR-0071 removes realmlists. Specify a "put my settings back" path.
5. **Specify the install manifest** as Leyline does: every file listed, exact removal, a disabled folder, a staging area (`launcher/README.md:63,71`). Fits ADR-0043. We do not copy "every mod allowed" (`launcher/README.md:72`): ADR-0028 and ADR-0041 stand.
6. **One pre-flight check before Play:** server reachable, version matches, data valid, and one sentence saying which failed. Nobody does this well, so it is a place to be better than all of them. Launcher acceptance criterion.

### Launcher or client phase

7. **Prebuilt installers, and a decision on code signing.** WoWee already ships prebuilt downloads. SmartScreen's "Run anyway" is a poor first impression; ADR-0094 defers signing. It involves keys and cost, so it stays Ludwig's (CLAUDE.md rule 11).
8. **Signed self-update that never restarts a running game**, as Leyline designs it. Fits ADR-0094. Its key needs Ludwig's approval.
9. **Crash reports a player can reach.** benilla-wotlk writes a crash file but mentions it only in the error stream (`crash.rs:71`). The launcher should find it and offer "Share diagnostics" (ADR-0043).
10. **A short first-run tour**, skippable and repeatable from Help (`launcher/ui/guide.js`). Low priority.
11. **Keep developer setup out of player docs.** The benilla READMEs mix them. Fits ADR-0113.
12. **Browser play later, own files only.** Whether WoWee can run in a browser was not determined. ADR-0005 decides the shape.

## Not determined

WoWee's own player path and usability; whether WoWee builds for the browser; how much WoWee has changed since 2026-07-21; whether "Wowee Contributors" are one or several; behaviour with a wrong game version in the Rust clients; whether Leyline's browser page updates by itself; the exact stock-client error texts (they come from the game's own files); the games built on benilla.
