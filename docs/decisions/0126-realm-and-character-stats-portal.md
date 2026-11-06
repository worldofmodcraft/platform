# ADR-0126: An opt-in realm and character stats portal at stats.worldofmodcraft.com (phase 3)

- **Status:** Accepted (2026-11-06, decided by Ludwig)
- **Date:** 2026-11-06
- **Area:** Site / Backend
- **Touches:** site/stats-portal, backend/server-directory, privacy/telemetry, legal/assets
- **Supersedes:** —
- **Amends:** ADR-0004, ADR-0036, ADR-0078
- **Related:** ADR-0002, ADR-0041, ADR-0060, ADR-0077, ADR-0107, ADR-0112

## Context
Ludwig, 2026-11-06 (verbatim, Swedish): "En sak jag insåg är att jag gärna vill ha en "webbportal" varje server/realm, där man kan klicka på varje server/realm för att se dekaraktär för att se dess stats, samma med karaktärer (exempelvis vilken server/realm de finns på, inventory de har etc.). Ska inte kräva att konto skapas, utan varje serveradmin ska själv kunna opt-in att all denna data tillhandahålls till "worldofmodcraft" och publiceras på sidan under en separat meny".

The manager raised four points: player consent and GDPR, ADR-0036's rule that character names are never sent, ADR-0004's ban on Blizzard data (item icons come from the game client), and that a central collector is a server-side service where the platform so far hosts nothing (the site is static, GitHub Pages; archives are GitHub Releases, ADR-0041). Ludwig's answers, verbatim:

- "1. För spelarna är det opt-out. Detta är digitala avater och träffas inte av GDPR. 2. Det finns redan stora hemsidor likt wowforge etc. som gör detta så borde inte vara några problem att visa dessa bilder. 3. Datan skickas till mig där detta publiceras på worldofmodcraft.com"
- "1. Detta är bara serverdata. Givetvis ska inte e-post, namn eller något annat som avser spelaren i verkligheten publiceras. Enbart stats avseende karaktären. 2. Låter vettigt att låta det ligga på en subdomän, typ stats.worldofmodcraft.com. 3. Det ska ju finnas en hostserver oavsett (för moddarna som publiceras, de backas ju upp av mig). Det kommer inte finnas några personuppgifter säger jag ju. Inga personuppgifter ska delas, enbart serverdata avseende realmen och karaktärerna"
- "Gör dessa ändringar"

## Options considered
- A. Each server shows its own public page through its web console (ADR-0112); the platform only lists and links. Manager's lean at the time; least data held centrally.
- B. Servers send the data to a platform service, published centrally on a subdomain. **Chosen by Ludwig.**
- C. No portal.

## Decision
1. **What:** `stats.worldofmodcraft.com`, a separate menu from the mod portal: a page per realm, and a page per character (its realm, stats, inventory and similar in-game data). No visitor account is needed.
2. **Who opts in:** each server admin opts the realm in; until then nothing is sent. **Players are included by default and can opt out**; an opted-out character is not sent, and its published page is removed.
3. **The boundary, absolute:** only in-game data about realms and characters is sent or published. Never account names, e-mail, IP addresses, real names, chat, or anything else that concerns the person behind a character. The masking happens on the server, before sending, as ADR-0036 already does for diagnostics.
4. **Where:** the data is sent to a service Ludwig runs and is published under the subdomain, kept apart from the registry and the archive.
5. **Item icons:** the portal may show the game's own item icons and similar images, **only on `stats.worldofmodcraft.com`**. Nothing else changes about ADR-0004: no Blizzard data in mods, the registry, the archive, the mod portal or the platform's own files.
6. **When:** phase 3, with the server directory (ADR-0078). Not part of any current mission.

## Amendments

### ADR-0004 (own assets only)
Exception for one surface: `stats.worldofmodcraft.com` may display the game client's item icons and similar images to present realm and character data (Decision 5). The rule stands everywhere else, including every repository of the organisation, which never stores them.

### ADR-0036 (opt-in diagnostics sharing)
ADR-0036's "never sent: character names" still holds for diagnostics. The stats portal is a separate channel with its own opt-in (Decision 2): it sends character names and in-game data, and never account names, chat, IP or anything about the person (Decision 3).

### ADR-0078 (public server directory)
The directory's opt-in gains a second, separate switch: publish realm and character stats. Its heartbeat endpoint is the natural home for the data feed, but the feed carries more than a heartbeat and has its own size and rate limits, to be designed with the backend.

## Consequences
- **The platform's first hosted service.** Until now the site is static and archives are GitHub Releases; the portal needs a service that receives data. Where it runs, its cost and its operation are to be decided when phase 3 starts (ADR-0077 for storage; ADR-0079 contract-first for its API).
- **Separation:** a subdomain keeps a complaint about the portal's images away from the registry and the archive that every mod depends on. Hosting the portal on separate infrastructure from the organisation's GitHub would strengthen that; not decided here.
- **Risks recorded, as raised by the manager and answered by Ludwig:**
  - Personal data: Ludwig's position is that the portal holds none, because only in-game data is published. The manager's note: a character name can count as pseudonymous personal data where the server can link it to an account; the boundary in Decision 3, the opt-out and real deletion keep that link off the portal. Not legal advice.
  - Blizzard images: other large fan sites do the same (Ludwig). The remaining risk sits with the subdomain only.
- **Needed when built:** a schema for the feed (contract-first, ADR-0079); the server-side masking; opt-out that removes published pages; rate limits; and a privacy note on the portal stating the boundary.

## Interacts with
ADR-0002 (audience), ADR-0041 (archives stay on GitHub Releases), ADR-0060 (public but unannounced), ADR-0107 (who sees what on a server), ADR-0112 (the web console the admin opts in from).
