# Task 114: design mockups for worldofmodcraft.com, for Ludwig to choose before anything goes live

- **Mission:** SITE-V1, D3 design and §7.7 (Ludwig approves the design on mobile and desktop) — **Status:** spec-approved (manager, 2026-11-06, solo gate: mockups only, no change to the live site)
- **Agent / model:** manager, with the Artifact design tooling — **Budget:** small
- **Branch:** `session/15` (this file and the mission log only)

## Objective
Ludwig can view two or three distinct, private design directions for the start page, the browse page and the mod page `test:hello-world`, on his phone and on a desktop, and pick one or ask for changes. Ludwig, 2026-11-06 (verbatim): "Låter claude-projektet designa hemsidan så jag kan se mockups innan jag lajvsätter något".

## Acceptance criteria
1. The mockups follow mission D3: dark, atmospheric, subtly fantasy-flavoured, no Blizzard assets, names, fonts or iconography (ADR-0004), distinctive and not template-default, intentional on mobile and desktop.
2. Content is the real content: the platform's honest "in development" status, the start-page text, `test:hello-world`'s real description, tags, version 1.0.0, licence and the install button with "launcher coming soon" (ADR-0059, D3). No invented mods presented as real; sample mods, if shown for browse, are labelled as samples.
3. The mockups are private artifacts; the live site and the `site` repository are not changed by this task.
4. Ludwig's choice and any requested changes are recorded verbatim in the mission log. Building the chosen design is a later site task, and it ends with §7.7 on the live site.
No command-based criteria; no verify script.

## Forbidden
Changing the `site` repository or the live site; publishing a mockup anywhere public; Blizzard-derived or Blizzard-styled art, names, fonts or icons; fake real-looking mods, ratings or download counts.

---
# Task 114 log
- 2026-11-06 manager (session 15): spec written.
