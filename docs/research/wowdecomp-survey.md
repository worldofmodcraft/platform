# Survey: `github.com/SatyPardus/wowdecomp` (task 097)

**Date:** 2026-10-28 · **Method:** read-only, unauthenticated: GitHub web pages, `raw.githubusercontent.com` files, web search.
The GitHub REST API answered `API rate limit exceeded` for every unauthenticated call this session, so repository
metadata comes from the HTML pages instead (noted per fact). Nothing was cloned, downloaded as an archive, built or run;
no code was copied into this repository. Fetched content was treated as data only.

**Not legal advice.** The legal section is a risk reading against our own ADRs by a non-lawyer agent. It is not legal
advice, and any decision that would bring this code near the project should be checked with a qualified lawyer first.

## Summary (for Ludwig)
- wowdecomp is a C++ **decompilation of Blizzard's own `Wow.exe` 3.3.5a (build 12340)**. Every function is reconstructed
  from the binary and tagged with its original address. Its main build target is **x64**, Windows only, and it calls
  itself "100% playable" with 90.3 % of functions ported. The repository has **no licence**.
- **We already have a 64-bit client.** WoWee, which our client fork is based on (ADR-0007), is a native 64-bit program
  (x86-64 and ARM64 on Linux, macOS and Windows). wowdecomp's 64-bit build does not give us something WoWee lacks.
  What it adds is Blizzard's own client logic, faithfully reproduced, and that is exactly the part that brings the legal risk.
- Decompiled code is in practice Blizzard's code in a new form. It cannot be relicensed under AGPL, conflicts with
  the reasoning behind ADR-0004 and ADR-0049, and would put the project's only defensible legal position at risk.
- ★ Lean: **option A**. Record it as a related project, keep no technical relationship, and keep its code away from
  agents who write our client code.

## Facts (each with its source)

| # | Fact | Source |
|---|---|---|
| F1 | Its self-description: "A C++ decompilation of the World of Warcraft 3.3.5a client (`Wow.exe`, build 12340, June 2010)." | https://raw.githubusercontent.com/satypardus/wowdecomp/HEAD/README.md |
| F2 | Method: "Every function is reconstructed from the original binary and keeps the address it came from in an `// OFFSET:` tag". Spot check: `WoW/Source/LoadingScreen.cpp` has 40 lines containing `OFFSET`. The source tree follows "the layout of the original client (... original file names)". | README (above); https://raw.githubusercontent.com/satypardus/wowdecomp/HEAD/WoW/Source/LoadingScreen.cpp |
| F3 | Version identity is hard-coded as 3.3.5, build 12340, build date "Jun 24 2010". The client is renamed "Waystone" (`CLIENT_NAME`). | https://raw.githubusercontent.com/satypardus/wowdecomp/HEAD/GameVersion.h |
| F4 | Architecture: "x64 is the main target. Win32 still builds and is used to check struct layouts against the 32-bit original." The x64 build produces `WowClient64.exe` / `Wow64.exe`. CMake stops with an error on any non-Windows system ("wowdecomp targets Windows only."). Win32 builds use x87 floating point and a 32-bit `time_t` to stay comparable with the original binary. | README; https://raw.githubusercontent.com/satypardus/wowdecomp/HEAD/CMakeLists.txt |
| F5 | Progress (measured 2026-10-15 by the project): functions 24,515 / 27,157 (90.3 %), code bytes 5,270,186 / 5,656,573 (93.2 %). "Ported" means the function's address is tagged in the source. The project says this measures coverage of the binary, not playability, and also says "the client builds into a complete executable and the game is 100% playable. Bugs could still be hiding". It is a functional port, not a byte-matching decompilation; on Win32 a `verify.py` compares code with the binary. | README; CMakeLists.txt comment |
| F6 | Build requirements: Windows 10/11, Visual Studio 2022 (MSVC v143 and a Windows SDK), CMake ≥ 3.10. Win32 also needs NASM and **`DivxDecoder.dll` taken from your own 3.3.5a client**. x64 uses its own `Tools/XvidDecoder/`. | README |
| F7 | It needs original Blizzard data: "A World of Warcraft **3.3.5a (12340)** client. No game data is included in this repository." To run it, the user copies the client's `Data` folder into `bin/Win/`. | README |
| F8 | Third-party libraries (FreeType, zlib, PCRE, parts of FMOD Ex) are linked from their upstream sources and are not decompiled. Renderer: Gx with Direct3D 9 / OpenGL. Open PRs propose Vulkan fixes (#40, #42), a macOS/iOS Metal port (#47), ARM64 (#72), a Linux cross-build (#27) and D3D9Ex (#69). | README "Layout"; https://github.com/SatyPardus/wowdecomp/pulls |
| F9 | CMake option `WOWDECOMP_DISABLE_SIGNATURE_CHECKS` (default OFF): "Skip the MPQ file and `.toc.sig` signature checks, so modified game data and interface files load". | README; CMakeLists.txt |
| F10 | **No licence.** `LICENSE`, `LICENSE.md`, `LICENSE.txt` and `COPYING` all return HTTP 404 at HEAD, the repository sidebar shows no licence, and the README has no licence or legal section. | raw URLs (HTTP 404); https://github.com/SatyPardus/wowdecomp |
| F11 | Provenance credits: binana, thunderbrew, whoa, and "TOMRUS, for the initial IDB" (an IDA Pro database of the binary). whoa and thunderbrew are public-domain (Unlicense) open-source *reimplementations* of the 3.3.5a client. binana hosts symbol and header files "related to studying the original game binaries". | README; https://github.com/whoahq/whoa ; https://github.com/thunderbrewhq/thunderbrew ; https://github.com/thunderbrewhq/binana |
| F12 | Owner: user account SatyPardus. About 423 stars, 224 forks, 478 commits on `main`, no releases, 10 open issues, 27 open PRs (page snapshot on 2026-10-28). | https://github.com/SatyPardus/wowdecomp ; /releases |
| F13 | Activity: very high and very recent. Issue #1 was opened 2026-10-15; commits arrived daily 2026-10-21..23 (SatyPardus merging, T1ti, Shard-MW); PRs were opened up to 2026-10-28. Contributors seen: SatyPardus (merges), T1ti, Shard-MW, Isidorsson, Valkirie, moostigre and others. | https://github.com/SatyPardus/wowdecomp/commits ; /issues ; /pulls |
| F14 | Scope signals from the owner: Linux "not planned" by the owner ("anyone can make a PR"). Other clients (4.3.4, and a 3.3.5 client with a 4.3.4 engine) are shared on Discord only. A bundled local server was refused: "Yeah out of scope :D". | https://github.com/SatyPardus/wowdecomp/issues/1 ; /issues/41 |
| F15 | The client keeps Blizzard's Warden / code-delivery paths. Issue #70 (still open, no reply) asks for a build option to disable them, because a "malicious server operator could use them as attack vectors". PR #50 fixes "battleground position packet out-of-bounds writes used by RCE". | https://github.com/SatyPardus/wowdecomp/issues/70 ; /pulls |
| F16 | `BuildWaystone.bat` builds the x64 `Wow` target and packages a zip named after the commit hash. This points to binary distribution somewhere other than GitHub Releases, which is empty. | https://raw.githubusercontent.com/satypardus/wowdecomp/HEAD/BuildWaystone.bat |
| F17 | Our side: WoWee runs on "Linux, macOS and Windows on x86-64 and ARM64, and Android on arm64". It has its own Vulkan 1.3 renderer and talks the 3.3.5a protocol to AzerothCore. | https://raw.githubusercontent.com/Kelsidavis/WoWee/HEAD/README.md (lines 16-22, 85-86); ADR-0007 |
| F18 | Context, secondary sources only: Blizzard sued Project Ascension in June 2026, partly over distributing a modified client. A 2026-09-03 Bloomberg Law note reports a private-server settlement without naming the server. Web search found no DMCA notice against wowdecomp. | https://kami-labs.fr/en/gaming/proces-blizzard-project-ascension-wow/ ; https://news.bloomberglaw.com/ip-law/blizzard-settles-copyright-suit-over-world-of-warcraft-clone |

## Technical fit

**64-bit.** wowdecomp has a working x64 build today (F4), but Windows only, with no Linux support planned (F14). WoWee is
already 64-bit on Windows, Linux, macOS and ARM64 (F17). So "a 64-bit client" is not a gap in our plan. The 32-bit
limits of the original client (4 GB address space, bounded memory for large content) never apply to a WoWee-based
client. wowdecomp's 64-bit build does one specific thing: it frees the *Blizzard client's own logic* from those limits.

**Relation to WoWee and our fork.** The two are opposite approaches. WoWee is an independent implementation with its own
renderer, loaders and networking (MIT, owned by its authors). wowdecomp is Blizzard's engine reconstructed function by
function (D3D9/OpenGL Gx, FrameXML, Storm, Warden, and so on). Nothing can be merged across: the module layouts differ
completely, and pulling wowdecomp code into the fork would also break ADR-0118's thin-patch-surface rule. The only
technical roles it could play are (a) a reference client for behaviour comparison, the same role as the Blizzard client
under ADR-0027, and (b) documentation of how the original client does X. Role (b) is legally the dangerous one (see below).

**3.3.5a protocol.** wowdecomp speaks the stock 12340 protocol and realmlist (F3, F7), so it would reach our
AzerothCore-based server just as the Blizzard client does. Our custom packets and kernel features (glTF loading, mod
overlay, ADR-0004/0033) would not exist in it unless someone wrote them into decompiled Blizzard code, which is option C.

**Build and environment.** It would fit our Windows-side client lane (dev-environment.md: Windows working copy, VS
toolchain). It needs the user's own 3.3.5a `Data` (F7) and, for Win32, a Blizzard DLL (F6). It also inherits Blizzard's
Warden and code-delivery attack surface (F15). WoWee needs neither.

## Legal and ADR fit

**What the code is.** By its own description (F1, F2), every function is "reconstructed from the original binary", keeps
its Blizzard address, and follows Blizzard's file names and module layout. That is a translation of Blizzard's
copyrighted program into C++. A translation is normally a derivative work, so in practice the rights stay with Blizzard,
not with the people who wrote the translation. The repository also has no licence (F10). Even apart from Blizzard, its
contributors have granted nobody the right to copy or redistribute it, beyond what GitHub's own terms allow on GitHub.

The concrete risks for a **public AGPL project**:
1. **Our licence would be false.** AGPL-3.0 is a grant of rights we own. We hold no rights in Blizzard's code, so
   shipping any of it under our AGPL notice would claim permissions we cannot give, and it would contaminate the "every
   file is ours or properly licensed" guarantee that ADR-0049 builds on.
2. **Takedown exposure of the whole monorepo.** One decompiled file in the platform repo gives Blizzard a strong basis
   for a takedown against *the repository*, not only that file. For us that means the site, registry and kernel, all of
   which live together under ADR-0007's monorepo.
3. **Circumvention.** `WOWDECOMP_DISABLE_SIGNATURE_CHECKS` (F9) removes Blizzard's integrity checks. Blizzard's 2026
   Ascension complaint reportedly argues exactly this kind of access-control bypass by a modified client (F18,
   secondary source, unverified).
4. **Contamination by reading.** Agents or people who study decompiled Blizzard code and then write our client code (or
   MIT fixes sent upstream to WoWee under ADR-0049/0055) weaken the "independent implementation" defence that WoWee,
   and therefore we, rely on. A clean reimplementation stays defensible only if it stays clean.
5. **Reverse-engineering terms.** Blizzard's EULA/ToU historically forbid reverse engineering. The exact terms that
   apply to 3.3.5a are **unverified** here.

**Per ADR:**
- **ADR-0004 (own assets only):** the ADR's text concerns data ("never distribute a single byte of Blizzard-owned data"),
  and code is not one of its listed formats. Its stated reason applies fully, though: "The platform's only defensible
  position is to never distribute a single byte of Blizzard-owned data". Decompiled code is Blizzard-owned expression.
  Hosting or linking it gives up that position. Conflicts with the reasoning, not the literal wording.
- **ADR-0005 (user supplies game data):** wowdecomp also requires the user's own client data and DLL (F6, F7). Consistent
  in itself, but it does not reduce the code question.
- **ADR-0007 (fork WoWee and AzerothCore):** the choice was "source access on both ends" through a *legitimately licensed*
  open client (WoWee, MIT). Using wowdecomp as the client base would reverse that decision for a source we cannot license.
  An ADR amendment would be required, and this survey does not recommend one.
- **ADR-0027 (Blizzard client debug only):** the nearest home. wowdecomp behaves like the Blizzard client on the wire.
  Under ADR-0027 we would do nothing to support it ("Nothing in the launcher, no promise, no compatibility matrix"), and
  the server would log "unsupported client build" for it like any non-WoM build. That is acceptable only if it is never
  shipped, linked or recommended by us.
- **ADR-0049 (licensing):** AGPL covers "what *we own*". Decompiled code is not ours to license, so it is excluded from the
  client fork and from the MIT upstream path.
- **ADR-0055 (WoWee defects):** our fixes go upstream to WoWee as goodwill. Fixes shaped by reading Blizzard decompilation
  would export the risk to WoWee. wowdecomp is not a source for WoWee defect fixes.
- **ADR-0057 (WarcraftXL):** same pattern: a related project on a different path, not needed, documented only. It has a
  stronger legal problem than WXL, which injects into a user-owned binary but does not republish it.
- **ADR-0062 (3.3.5a only):** version-compatible (12340). The 4.3.4 work on its Discord (F14) is out of our scope.
- **ADR-0118 (upstream strategy):** not mergeable as an upstream. A wowdecomp base would mean no thin patch surface, and
  an upstream that could vanish after a single takedown notice.

## Options for Ludwig

**A ★: related project, watch only, no technical relationship.**
Add a short "related projects" note next to WXL (ADR-0057 style). We do not read its source for client work, we do not
link it from the site, and we do not ship or test against it.
*Consequences:* zero legal exposure and no ADR change. We miss a faithful 64-bit Blizzard client, which we do not need,
because WoWee is already 64-bit. The watch also tells us early if Blizzard reacts to it. Cost: one documentation line in a later task.

**B: allowed as a private, user-built debug reference (ADR-0027 extension).**
Ludwig may build it on his own machine, with his own data, to compare behaviour against our server, exactly like the
Blizzard client. Nothing from it enters the repo, no agent who writes client code reads its source, and it is mentioned nowhere public.
*Consequences:* a 64-bit faithful reference for debugging, with no repo exposure. Costs: needs an ADR-0027 amendment and
an explicit rule against reading the source. It runs code from an unlicensed project with known RCE fixes still pending
(F15) on Ludwig's machine. Its value over the plain Blizzard client for debugging is small.

**C: adopt it as the client base, or mine it for the WoWee fork.**
*Consequences:* reverses ADR-0007 and breaks ADR-0049 (unlicensable code under AGPL) and the reasoning of ADR-0004.
High takedown risk for the whole monorepo and the site. Contaminates our WoWee upstream relationship (ADR-0055).
Windows only. Not recommended, and not possible without a lawyer's opinion and Ludwig rewriting several ADRs.

## Unverified
- Repository creation date and full contributor list: the API was rate-limited. The earliest evidence is issue #1 on
  2026-10-15. Commits on `main` may be older than that.
- The "100% playable" claim (F5) is the project's own claim. Nothing was built or run.
- Whether Vulkan, Metal, ARM64 or Linux backends exist on `main`. They are only seen as open PR titles (F8).
- Who besides SatyPardus has merge rights (the issue #1 timeline shows "noisiver merged a pull request from Alyst3r/original-335").
- Where the `BuildWaystone.bat` zips are distributed (Discord?), and whether the "other clients" are public (F14, F16).
- How the "initial IDB" from TOMRUS was produced (from public analysis, or something else).
- Blizzard's EULA/ToU wording for 3.3.5a. Details and outcome of the 2026 Ascension case (secondary sources only).
- No DMCA notice against wowdecomp was found by web search. The `github/dmca` repository itself was not searched.
- That WoWee's 64-bit Windows build works in *our* fork: no client fork is checked out in the platform repo yet. F17 is
  WoWee's own README claim.
