# Design: "Wayfarers' Wager" — a party board game mod

- **Status:** Draft — rests on the proposed ADR in `docs/tasks/098-proposed-adr.md`; not accepted. (The design itself needs no ADR change: the mod is built only on the platform's mod API. The proposed ADR only decides whether this mod drives the platform build order.)
- **Last reviewed:** 2026-10-28
- **Author:** doc-writer, task 098, for Ludwig
- **Working title:** Wayfarers' Wager (a placeholder; renaming is free). Mod id: `<ns>:wayfarers-wager`, namespace **[open]** (a personal namespace follows the GitHub username, ADR-0030:28; `mc:` is reserved for platform core mods, ADR-0003:10, ADR-0119:30).
- **Reading guide:** sections a to j follow the brief. Every statement about what the platform provides carries an ADR `file:line`. Anything the ADRs do not settle is marked **[design proposal]** (my suggestion) or **[open]** (nobody has decided). Nothing here claims that code exists: the platform is at the documentation stage, and "the ADR decides X" never means "X is built".

## 0. Where this comes from

Ludwig, 2026-10-28 (verbatim, Swedish): "vill att den första modden ska vara en Mario Party-liknande mod där man går omkring på ett spelbräde och samlar stjärnor och spelar mini games med andra spelare". "Mario Party-like" is used here **only as the name of a genre**: a turn-based board game for a few friends, with dice, a victory token you buy, and short minigames between turns. Everything in this document is original: names, characters, board themes, items, minigames, look and sound. No Nintendo names, characters, art, music or icons, and no Blizzard assets (ADR-0004:17).

Ludwig's later instruction: the mod must not affect ADRs, because the point of the mod API is that mods are built standalone from each other. So this is written as a **standalone mod built only on the platform's mod API**. Where the API does not yet offer something the mod needs, that is listed as a **gap the mod needs filled by the platform** (section g.4), not as an ADR change.

### Terms explained once
- **Mod:** a folder with records, Lua scripts and optional native plugins (ADR-0008:12-15). **Record:** a declarative description of "what exists" (here: a board, an item, a minigame), written as a Lua table or JSON and validated against a schema (ADR-0008:13).
- **Kernel:** the shared runtime library that loads mods (ADR-0003:9). **Ring 1/2/3:** three layers of its API (foundation, game surface, extensions; ADR-0020:10-13).
- **RPC:** a message between the game client and the server (ADR-0066:7). **KV store:** the mod's saved key/value data (ADR-0023:9).
- **Instance:** a private copy of a map owned by a mod (ADR-0024:9). **Overlay:** things the client draws on top of the world, such as lines and icons (ADR-0083:7).
- **Authoritative server:** the server decides what happened; the client only shows it and sends requests.
- **Walking skeleton:** the thinnest end-to-end slice that touches every layer, grown step by step (ADR-0050:11-15).
- **Turn, round, game:** a *turn* is one player's move on the board. A *round* is every player taking one turn, followed by one minigame. A *game* is a fixed number of rounds.

---

## a. Vision and the player's evening

**One sentence:** four friends gather at a table in the world, walk their characters around a miniature-style board, spend coins to buy Beacon Stars, and settle the evening's arguments in 30-second minigames.

**Why this fits the platform's audience:** the platform targets self-hosted servers used with a few friends (ADR-0002:13). A party game needs exactly that: 2 to 4 people, a trusted client, and no anti-cheat (ADR-0002:16 states the client is trusted).

### The evening, start to finish (default settings, 4 players, 15 rounds, about 45 minutes)
1. **Arrive (0-3 min).** Everyone is on the server (invite code, ADR-0046:12). One player types `/wager host` near a placed "Game Table" (or uses the lobby panel). The others type `/wager join` or click the table. Each picks a companion and a banner colour.
2. **Lobby (2 min).** Host chooses the board (Lantern Isles or Clockwork Orchard), the game length (10 / 15 / 20 rounds), and whether bots fill empty seats. Rules summary card is shown. All press Ready.
3. **Intro (1 min).** Camera flies over the board. Seat order is drawn by `kernel.rng` (ADR-0091:7). The three secret Honours for this game are drawn but hidden (rules b.9). Everyone stands on the Hearth (start space) with 10 Brass (coins) and 0 Stars.
4. **Rounds 1 to 15 (about 3 min each).** Each player in turn: optionally use an item, press **Roll**, watch their character hop along the path, resolve the space they land on. After the fourth player, the round's **minigame** is chosen, everybody is carried to an arena, plays for 20 to 60 seconds, is paid Brass by placement, and is carried back.
5. **Festival turns (rounds 11 to 15).** The board announces the Lantern Festival: Lantern spaces pay double, Ember spaces cost double (rules b.7). The last five rounds are where games are won and lost.
6. **Finale (3 min).** After round 15 the three Honours are revealed (+1 Star each to their winners). The result screen shows Stars, Brass, minigame wins and stats; the winner gets a title toast and an achievement (ADR-0096:9). Everyone is returned to where they stood before the game (ADR-0092:7, and gap G3).
7. **Afterwards.** The game's log is kept (replayable from its seed, ADR-0091:7). Lifetime stats are saved per character (ADR-0020:11 names per-character KV scope).

### Tone
Warm, cosy, a bit mischievous: lantern-light, paper maps, brass gadgets, small animals. Nobody is eliminated; everybody always plays every minigame. A lucky die or a rubbish roll is meant to be funny, not punishing.

### Design pillars
1. **Luck for laughter, skill for pride.** The die decides where you stand; minigames decide who has money; stars need both.
2. **Never wait long.** A player's own decision is capped at 30 s; nobody sits idle for more than about 90 s (b.10 and e.4).
3. **Rules are data.** Every number below is a setting (ADR-0029:9: "every default is a setting"); every board, item, event and minigame is a record, so other authors can add more without touching this mod (c.5).
4. **The server is the referee.** The server rolls, moves, pays and decides (authoritative server). The client shows and asks.

---

## b. Core rules

All numbers are **[design proposal]** and are to be tuned by a headless simulator before play-testing (section i, step 4). They are chosen to be easy to read at the table and are all `config.schema` entries with bounds (ADR-0029:9).

### b.1 Players, seats, turn order
- 2 to 4 players (question Q3 in the ADR proposal). Seats are numbered 1 to 4. With bots enabled (question Q2), empty seats are filled up to a host-chosen minimum of 3 [design proposal].
- **Turn order** is drawn once at the start, by `kernel.rng` (ADR-0091:7): each player draws a number from 1 to 100; the highest goes first. Order stays fixed for the whole game.
- **Game length:** 10, 15 or 20 rounds (default 15; bounds 5 to 30; question Q4).

### b.2 The dice
- The **Wayfarer die** is an 8-sided die (1 to 8, uniform). It is rolled on the server with the mod's own `kernel.rng` stream, so the same seed replays the same game (ADR-0091:7). `math.random` is forbidden in server Lua (`validate` warns; ADR-0091:7).
- Average roll 4.5. With the 48-space Lantern Isles board this is about one lap every 10 turns.
- Items can change the die (b.6).

### b.3 Movement
- You move forward exactly as many spaces as you rolled, one space at a time. All edges on the board are one-way, so there is no walking backward except by event (b.5).
- **Forks (crossroads):** where a space has two outgoing paths, the mover is asked to choose when they arrive at it (20 s timer; default is the main path).
- **Passing the Star:** if you walk *through* or *onto* the pier that currently holds the Beacon Star and you hold at least the Star price, you stop there and are asked "Buy a Star for 20 Brass?" (b.4). Then you continue with the steps you have left.
- Spaces you pass over have **no effect**, except the active Star pier and any Tripwire (item).
- Several characters may stand on one space (they stand in a small semicircle).

### b.4 Currency, Stars and how they are bought and moved
- **Brass** is the coin. Everyone starts with **10 Brass** (setting).
- **Beacon Star** is the victory token (shown as an eight-point compass star lantern, deliberately not a five-point star shape). Most Stars at the end wins.
- **Price: 20 Brass** (setting). The Star is sold by the Lamplighter, a lantern-keeper figure standing at the active pier.
- **One Star is on the board at a time.** It sits on one of the six Piers. At game start the pier is drawn with `kernel.rng`.
- **When it is bought**, the Star disappears and re-appears on a different pier, drawn at random excluding the previous pier and excluding the piers within 6 spaces ahead of the buyer (so the buyer cannot trivially buy twice in a row) [design proposal].
- **If someone declines** or cannot afford it, the Star stays.
- **Stars are never lost or taken** in version 1 (no theft, no penalty). A star-stealing event is a possible later addition [open].
- **Brass cannot go below 0.** A penalty of 3 with 2 Brass costs 2.

### b.5 Spaces and their effects (Lantern Isles composition, 48 spaces)

| Space | Count | Effect on landing | Colour group |
|---|---|---|---|
| Hearth (start) | 1 | Nothing. | Warm |
| Lantern | 17 | +3 Brass (+6 during the Lantern Festival). | Cool |
| Pier | 6 | +3 Brass if no Star is here. One pier holds the Beacon Star (b.4). | Cool |
| Ember | 7 | -3 Brass (-6 in the Festival). A Ward item blocks it. | Warm |
| Wonder | 6 | Draw one event card (table below). | Warm |
| Cache | 4 | Draw one item (b.6) if you have a free slot; otherwise +2 Brass. | Cool |
| Duel | 3 | Pick one opponent; both stake 5 Brass; a 15-second duel minigame (c.4) decides; the winner takes both stakes. A player with under 5 Brass stakes what they have; the stake is then equal on both sides [design proposal]. | Warm |
| Stall | 2 | Shop: buy up to 2 items from a shop of 3 random items (prices in b.6). | Cool |
| Tide | 2 | Swap places with a random opponent chosen by `kernel.rng`. The swapped player does not resolve the space they are moved to. | Warm |

Total 1 + 17 + 6 + 7 + 6 + 4 + 3 + 2 + 2 = **48**.

The **colour group** matters at the end of the round: a player's colour is that of the *last space they landed on* (Warm or Cool). It decides who plays with whom (c.1).

**Wonder events** (draw one, weights in brackets; **[design proposal]**):
1. *Windfall* (3): you gain 8 Brass.
2. *Pay the Piper* (2): you lose 5 Brass.
3. *Open Hands* (2): every player gains 2 Brass.
4. *Lantern Rain* (2): every player standing on a Cool space gains 3 Brass.
5. *Headwind* (2): you move back 3 spaces and do not resolve that space.
6. *Tailwind* (2): you move forward 3 spaces and resolve that space.
7. *Wishing Well* (1): give any player 3 Brass; you gain an item.
8. *Surveyor* (1): you see which pier the Star will move to next.
9. *Mischief* (1): all players pass one random held item to the player on their left.
10. *Rebate* (1): the player with the fewest Brass gains 6 Brass.
Total weight 17.

### b.6 Items

Each player holds up to **3 items** (setting). At most **one item may be used per turn**, before rolling (setting). Items come from Cache spaces (random) and Stalls (buy).

| Item | Stall price | Effect |
|---|---|---|
| Steady Die | 5 | Your roll this turn is exactly 4. |
| Twin Dice | 8 | Roll two dice and move their sum (2 to 16). |
| Brass Magnet | 6 | This turn, passing a Lantern or Pier pays +1 Brass (landing still pays normally). |
| Tripwire | 7 | Place it on the space you stand on. The first other player to pass it stops there and loses 3 Brass to you. One Tripwire on the board per owner. |
| Swap Charm | 10 | Swap places with any one player; you do not resolve the new space. |
| Ward | 6 | Block the next Ember, Pay the Piper or Tripwire effect against you. |
| Pickpocket Glove | 12 | Steal 5 Brass from a player within 6 spaces of you. |
| Rain Check | 9 | After rolling, you may roll again once and use the second result. |

### b.7 Lantern Festival (final five rounds)
For the last 5 rounds (setting `festival_rounds`, default 5), Lantern and Ember amounts double, and minigame payouts are 1.5 times (rounded down) [design proposal]. A toast announces it so nobody is surprised.

### b.8 End of game and scoring
1. After the last round's minigame, three **Honours** are revealed and each gives +1 Star to its winner(s) (b.9).
2. **Winner:** the player with the most Stars. **Tie-breakers, in order:** more Brass; more minigame wins; shared victory.
3. Brass is not converted to Stars. Items are worth nothing at the end.

### b.9 Honours (the bonus Stars)
At game start, three Honours are drawn without replacement from the pool of eight, with `kernel.rng`. They are hidden by default (setting `honours_visible`, default off). Ties: all tied players win the Honour.

| Honour | Won by |
|---|---|
| Gilded | Most Brass earned in total (not held). |
| Champion | Most minigame wins. |
| Wanderer | Most spaces moved. |
| Unlucky Soul | Most Ember landings. |
| Gambler | Most Duels played. |
| Collector | Most items used. |
| Steadfast | Fewest Brass lost to spaces, events and other players. |
| Team Player | Highest total co-op score share. |

### b.10 Timers and the pace of one turn
- Roll timer: **30 s**, then the server rolls for you (setting).
- Choice timer (fork, target, shop): **20 s**, then the default choice is taken (documented per decision).
- Hopping animation: about 0.4 s per space on the client.
- All timers use `now()`, which is the world clock (ADR-0025:14): they freeze with a pause (ADR-0025:18) and do not count downtime.
- One full round on the board with 4 players: 4 turns at about 25 s plus the minigame cycle at about 80 s, about 3 minutes (estimate [design proposal], to be measured).

### b.11 Companions (optional flavour, cuttable for v1)
Each player picks a small companion with one tiny passive. **[design proposal]**
| Companion | Passive |
|---|---|
| Pip the moth | Ignores the first Ember of the game. |
| Bramble the hedgehog | Lantern landings pay +1. |
| Sable the heron | Once per game, reroll. |
| Rue the fox | At each round start, sees the next minigame's name. |
| Skip the otter | May decline a Tide swap. |
| Dell the mole | Has 4 item slots. |

---

## c. Minigames

### c.1 Categories and how teams are formed
At the end of every round, each player has a colour (Warm or Cool, b.5). The split decides the minigame category:

| Players | Split of colours | Category |
|---|---|---|
| 4 | 2 and 2 | **2v2** team minigame |
| 4 | 3 and 1 | **1v3** (one against three) |
| 4 | 4 and 0 | **Free-for-all** (everyone for themselves) |
| 3 | 3 and 0 | Free-for-all |
| 3 | 2 and 1 | **2v1**: the pair plays a handicapped variant of a 1v3 minigame **[open: scaled variants]** |
| 2 | any | **Duel** (1v1), best of the minigame's own rules |
| any | rounds 5, 10, 15 | **Co-op** "Festival of Friends": the round's colour split is ignored, everybody plays together against the clock (this replaces the colour rule for those rounds) |

The category list is a **[design proposal]**. The minigame is drawn at random from the pool of minigames that fit the category and the player count; none repeats until the whole pool has been used (drawn with `kernel.rng`, ADR-0091:7).

### c.2 Payouts (setting, all values are defaults)
| Category | Payout |
|---|---|
| Free-for-all | 1st 10 Brass, 2nd 6, 3rd 3, 4th 0. Ties split by rank average, rounded down. |
| 2v2 | Winning team 8 Brass each; losers 0. A draw gives 4 each. |
| 1v3 | The solo player wins 15 Brass if they win; if the trio wins, each gets 6. |
| Co-op | Bronze tier 3 Brass each, Silver 6, Gold 10. Tiers are defined per minigame. |
| Duel | Winner takes the stakes (see Duel space) when played from a Duel space; as a round minigame (2 players) 10 Brass to the winner, 3 to the loser. |

### c.3 Minigame lifecycle
Every minigame goes through the same eight stages. The mod's turn engine owns the stages; the minigame's own script owns only stage 5. **[design proposal]**
1. **Select:** category from the colour split; minigame from the pool.
2. **Announce:** a 5-second card shows the title, goal, and the controls. The Rue companion's owner sees it one stage early (b.11).
3. **Transport:** players are admitted to the arena instance (ADR-0024:9). Their board positions are remembered (gap G3).
4. **Countdown:** 3, 2, 1. Controls are locked until zero.
5. **Play:** the minigame script runs. Server time limit 20 to 60 s, depending on the minigame.
6. **Resolve:** the minigame returns a result table (placements or team win, plus raw scores). The turn engine validates it (all seats present, no NaN, ranks consistent) and records it.
7. **Payout:** Brass is awarded by c.2, with a before/after diff recorded (ADR-0115:8-9, measuring outcomes).
8. **Return:** players go back to the board; the arena instance is destroyed (ADR-0024:9 lifecycle owned by the mod).

An error inside a minigame's script never kills the game: the turn engine abandons the minigame, pays everyone the 3rd-place amount, and logs the error with the mod and minigame attribution (ADR-0090:7 says a failing mod keeps running; ADR-0034:10 says errors carry traceback and attribution).

### c.4 Controls vocabulary
To keep every minigame learnable in 5 seconds, the mod uses a small set of inputs. **[design proposal]**
- **M** Move: the player's normal movement keys. The mod standardises everybody's movement speed in arenas (gap G2).
- **J** Jump: the normal jump key.
- **A** Action: one mod-defined action key (default `E`) (gap G5).
- **P** Pointer: mouse position and click (for aiming; gap G5).

### c.5 A minigame is a small mod-defined unit
A minigame is **one record plus one Lua script**, so a minigame needs no change to the turn engine, and other authors can add more. **[design proposal]** All the shapes below are sketches; the real record schema is written during build step 6 (section i) and validated by the compiler (ADR-0008:13, 19).

```lua
-- records/minigames/lantern_lunge.lua  (sketch, [design proposal])
return {
  type        = "wager:minigame",          -- a record type the mod defines (ADR-0030:26 `record_types.defines`)
  id          = "wager:lantern_lunge",
  description = "Catch the most falling lanterns.",   -- records carry a description (ADR-0034:12)
  category    = "ffa",                     -- ffa | team2v2 | solo1v3 | coop | duel
  players     = { min = 2, max = 4 },
  duration_s  = 30,
  arena       = "wager:courtyard_small",   -- an arena record: which instance template to use (ADR-0024:9)
  controls    = { "M" },
  script      = "server/minigames/lantern_lunge.lua",
  scoring     = "highest_score_wins",
}
```
```lua
-- server/minigames/lantern_lunge.lua  (sketch)
-- The turn engine calls these; the script never touches Brass or the board.
function M.setup(ctx)  ... end   -- ctx.players, ctx.rng (a per-minigame kernel.rng stream), ctx.arena
function M.start(ctx)  ... end   -- countdown finished
function M.tick(ctx)   ... end   -- optional, budgeted (ADR-0034:14 per-hook timers)
function M.finish(ctx) return { placements = {...}, scores = {...} } end
```
**Rules for minigame scripts:** only the arena and `ctx` are touched; results go through `finish`; randomness through `ctx.rng` (ADR-0091:7); all logging through the kernel logger (ADR-0034:12).

**Extending without editing this mod:** another mod can ship more minigames in two ways. (a) Records of the type `wager:minigame` declared in its own mod, picked up by the turn engine at load, with the type as a published contract (ADR-0030:26 `record_types.modifies`/`defines`). (b) Capability tags: this mod `wants` and other mods `provide` a tag such as `party_minigame` (ADR-0032:8). A tag is an IDL-defined interface, and the community registers new tags via the site (ADR-0032:8), so this is a process step for the authors, not an ADR change **[open: who registers the tag and when]**. Minigame packs then ship as separate mods or a modpack (ADR-0044:9).

Because mods that define record types must also declare a placeholder for them in the schema (ADR-0048:12), the mod ships `wager:placeholder_minigame` so that a game does not break when a minigame pack is uninstalled.

### c.6 The minigame concepts (14 original)

Notation: **Players** = category and count; **Length** = play stage only; **Controls** per c.4. "Needs" lists the platform surfaces beyond the basics (gaps are in g.4).

**Free-for-all (4 concepts)**

1. **Lantern Lunge.** *FFA, 2-4, 30 s, M.* Paper lanterns drift down over a courtyard; run under one to catch it; each catch scores a point; golden lanterns score 3. Most points wins. Needs: spatial query for "who is under the lantern" (ADR-0114:16).
2. **Burning Bridges.** *FFA, 2-4, 45 s, M + J.* A long rope bridge over a gorge; planks flare and fall away in a growing pattern; jump gaps to stay up. Last player standing wins; ties broken by time. Needs: placed objects that disappear (G6).
3. **Tidal Tiles.** *FFA, 3-4, 45 s, M.* The floor is a 5-by-5 grid of tiles; each 5 seconds a growing set of tiles floods and drops anyone standing on it. Safe tiles flash first. Last player standing wins. Needs: zones with enter/leave events (ADR-0114:16).
4. **Echo Pillars.** *FFA, 2-4, 40 s, M.* Colour pillars light up in a sequence that grows by one each round; players must step on the pillars in the same order within 4 s. Wrong step or too slow knocks you out of that round. Most rounds survived wins. Server draws the sequence with `ctx.rng`. Needs: zones (ADR-0114:16).

**2v2 (3 concepts)**

5. **Cart Relay.** *2v2, 4, 50 s, M + A.* Each team has a mine cart on its own track. One teammate pushes (hold A near the cart), the other runs ahead and clears rocks with A. Swap roles any time by switching places. First cart to the end wins; if time runs out, the cart farther along wins. Needs: moving a placed object along a path (G6).
6. **Hearth Hold.** *2v2, 4, 60 s, M.* A glowing circle (the hearth) moves around an arena every 15 s. A team scores one point per second while it has more members inside the circle than the other. Most points wins. Needs: area query plus overlay for the circle (ADR-0114:16, ADR-0083:7).
7. **Lantern Heist.** *2v2, 4, 45 s, M + A.* Each team guards 3 lanterns in its corner and steals the others'. Carry a lantern (A) home. Being touched by an opponent makes you drop it. Most lanterns at the end wins. Needs: proximity queries (ADR-0114:16).

**1v3 (2 concepts)**

8. **Giant's Garden.** *1v3, 4 (or 2v1 variant), 45 s, M + J.* One player is the Gardener, enlarged, stomping across a garden; the three others are seed-sprites, small and quick, who must plant 9 seeds at marked beds. The Gardener wins by squashing (touching) 3 sprites; the sprites win by planting all seeds. Needs: size change of a player (G7).
9. **Lighthouse Keeper.** *1v3, 4, 50 s, P.* One player aims a lighthouse beam with the mouse; the three others sneak across a harbour yard between crates. A sprinter caught in the beam for 2 s is out. Sprites win if two reach the dock before time runs out. The beam is drawn with overlay lines (ADR-0083:7). Needs: overlay, pointer input (G5).

**Co-op (3 concepts)**

10. **Bucket Brigade.** *Co-op, 2-4, 40 s, M + A.* The players stand in a chain from a well to a cauldron and pass buckets (A to hand over, positions given by markers). Water spilled when a player is not on their marker. Tiers by litres: Bronze 20, Silver 35, Gold 50. Needs: zones (ADR-0114:16).
11. **Bridge Builders.** *Co-op, 2-4, 45 s, A.* A beat appears on screen; everyone must press A in time together; each perfect beat extends a rope bridge by one plank. Tiers by planks: 10, 20, 30. Timing is judged with server timestamps (G12).
12. **Stormwatch.** *Co-op, 3-4 (2-player variant: a single watch), 50 s, M.* Lightning strikes marked spots (warned 1.5 s before); players must shield lanterns on the field by standing on them for the last 3 s. Tiers by lanterns saved: 4, 7, 10. Needs: overlay warnings (ADR-0083:7).

**Duel (2 concepts, also usable as the Duel-space game)**

13. **Quickdraw Lanterns.** *Duel, 2, 15 s, A.* A lantern lights after a random delay (1 to 5 s from `ctx.rng`); the first to press A wins that point; pressing early loses the point; best of 3. Server timestamps the presses (G12).
14. **Stone Stack.** *Duel, 2, 25 s, A + M.* Stones swing across the top of the screen; press A to drop one onto your stack; the taller steady stack at the end wins. A falling stack scores zero. Needs: placed objects with simple physics, which may need to be faked with timed animations (G6).

### c.7 What the minigames cost to build
Minigames 1, 3, 4, 10, 11, 13 need only movement, timers, zones and overlays. Minigames 2, 5, 14 need moving or vanishing placed objects. Minigames 8 and 9 need player scale and pointer input. The first minigame in the build order is Lantern Lunge (i, step 7). The second and third come from different categories (Hearth Hold for 2v2, Quickdraw Lanterns for a duel) to prove that the record shape works across categories.

---

## d. Boards

A board is one **record** (a graph of spaces), plus one art set. **[design proposal]** The shape (all sketches):

```lua
-- records/boards/lantern_isles.lua (sketch)
return {
  type = "wager:board", id = "wager:lantern_isles",
  description = "A ring of islands with two bridges.",
  spaces = {                       -- id -> type, position in the board instance
    r0  = { kind = "hearth", pos = {x=0,y=0,z=0} },
    r1  = { kind = "lantern", pos = {x=4,y=0,z=0} },
    -- ...
  },
  edges = {                        -- one-way; a space with two out-edges is a fork
    { "r0", "r1" }, { "r6", "r7" }, { "r6", "a1", fork = true }, -- ...
  },
  star_piers = { "r4", "r13", "r22", "r31", "a3", "b6" },
  instance_map = "<a map the instancing step can use>",   -- [open]: see G4
}
```

### d.1 Board 1: Lantern Isles (the starter, 48 spaces)
- **Setting:** a ring-shaped archipelago of small islands joined by rope bridges, lit by thousands of paper lanterns at dusk. Soft blue water, warm orange light.
- **Layout:** the **Rim** is a ring of 36 spaces (R0 = Hearth; the order runs clockwise). Two **bridges** of 6 spaces each cut across the middle, so the board has the shape of a ring with two chords.
  - **Rope Bridge** (A1 to A6): leaves the Rim at R6 and rejoins at R24. Seven steps instead of 18, so a big shortcut. Risky: Pier, 2 Embers, 1 Wonder, 1 Duel, 1 Lantern.
  - **Treasure Bridge** (B1 to B6): leaves the Rim at R33 and rejoins at R15. Safe but poor: 3 Lanterns, 1 Cache, 1 Stall, 1 Pier.
  - Forks therefore sit at R6 and R33 (the choice is asked on arrival, b.3).
- **Composition of the Rim (36):** Hearth 1, Pier 4, Lantern 13, Ember 5, Wonder 5, Cache 3, Duel 2, Stall 1, Tide 2.
- **Total with bridges (b.5 table):** 48 spaces, 6 Piers.
- **The Lamplighter** stands at the active Pier with a lit star-lantern; fireflies mark the pier from afar (overlay icon, ADR-0083:7).
- **Landmarks (visual only):** a lighthouse in the middle, a market on the south island, a lantern tower on the east.
- **Arena theming:** minigame arenas reuse the same visual set (courtyard, gorge bridge, harbour yard).

### d.2 Board 2: Clockwork Orchard (48 spaces, a board that changes)
- **Setting:** a mechanical orchard under a glass dome; brass trees, fruit-shaped lanterns, steam and cogs.
- **Layout:** a **figure-eight** of two loops of 20 spaces each (40 spaces) that share a 4-space centre crossing, plus 4 "gear spaces" on the arms (the 48 total keeps b.5 totals).
- **The twist:** every 3 rounds the **Great Gear** turns and **re-routes one fork**: the exit from the crossing swaps between loop one and loop two, announced one round ahead with a clear overlay arrow. This makes route planning matter and uses the same fork mechanism as Lantern Isles (b.3), only with an extra event "Gear Turn" (round % 3 == 0) that edits one edge in the live state.
- **Star piers:** 6 "Honey Presses" instead of piers.
- **Composition:** the same counts as Lantern Isles so the economy stays comparable (b.5 table), except Tide spaces are renamed "Gear Swap" (flavour only).
- **Look:** warm brass and green, steam, ticking audio.

### d.3 Board ideas for later (not designed)
**Frostmarket Fair** (winter fair, an ice-skating loop) and **Dreamers' Library** (floating bookshelves). Their value here is to show that boards are records: a different graph and art with the same rules.

### d.4 How big a board is allowed to be [design proposal]
- 36 to 60 spaces; at most 8 forks; 4 to 8 star piers. Checked by `validate` (ADR-0051:14 says the validate step runs the same pipeline as the site).
- A board is playable only if every space can reach every other space (graph strongly connected). `validate` rejects boards that fail this, with an error naming the space (error quality is a requirement; ADR-0051:13).

---

## e. Multiplayer and sessions

### e.1 Who plays, and where
- **2 to 4 human players** per game (question Q3). The platform's audience is a few friends on a self-hosted server (ADR-0002:13); other players on the server can watch (e.3) but not play.
- **Everyone uses their own WoW character** as their pawn, since characters belong to the world and the mod cannot create new player models (ADR-0088:7 says a character is part of the world's save file). The companion (b.11) is a visual extra that is optional for v1.
- **One game at a time** per server by default; setting `max_concurrent_games` (default 1, bound 1 to 4). Every game needs its own instances, and instance limits are settings with defaults safe for an ordinary PC (ADR-0024:9).
- **Where the board lives:** in a private instance (ADR-0024:9). The mod does not need the players to be near each other in the open world. Version 1 uses the command `/wager host` and the lobby panel to create the game and carry the players over (gap G3); a physical "Game Table" object players walk up to is a later polish step (G6).

### e.2 Lobby and joining
1. A player with the permission `<ns>.wager.host` runs `/wager host` (commands are manifest-declared, namespaced, with permission levels and generated help; ADR-0082:7; permissions are namespaced strings with default roles; ADR-0031:8). Default role for `host`: `player` **[design proposal]**.
2. The lobby panel shows the seats, the board, the length, bots on or off, and a Ready button per seat. Others join with `/wager join <host name>` or by clicking the entry in the panel.
3. The host can kick a seat before start (`/wager kick <name>`). The permission for it is the same as `host`.
4. When every seat presses Ready (or the host presses Start after 30 s, with fewer than all Ready), the game moves to SETUP (g.5).
5. **Late joiners** cannot take a seat after start. They may join as spectators (e.3).
6. A host with the permission `<ns>.wager.admin` (default role `admin`) can abort any game.

### e.3 Spectators
Any player may type `/wager watch`. Spectators receive the same overlay and UI updates as seated players for the board (not the arena). Spectating requires that the board's overlays be sent to named recipients (ADR-0083:7: elements are sent via RPC, so recipients are the mod's choice). Watching the arena while playing minigames is **[open]** (needs per-player visibility; ADR-0114:21 names phasing as a gap to be exposed).

### e.4 Pacing, timers and AFK handling
- Roll timer 30 s; choice timer 20 s (b.10). No timer is ever longer than the setting.
- **AFK:** a player who lets a timer run out three turns in a row is marked *away*. Their turns are then played automatically: auto-roll, default choices, no item use, until they send any command or click.
- **Waiting rule:** the longest a player waits between their own actions is the sum of the other seats' turn times plus a minigame cycle: about 90 s if everybody acts quickly.
- Timers use the world clock (ADR-0025:14); a pause stops them. Pausing disconnects players anyway (ADR-0025:18) so a paused game is saved and resumes (e.5).

### e.5 Disconnects, crashes, restarts
The kernel gives the mod a `player.logout` event with a reason and `server.pre_restart` / `world.saving` events (these are listed as gap-review items 8, entering the IDL declarations; ADR-0114:24). The mod's rules **[design proposal]**:
| Situation | Behaviour |
|---|---|
| A player disconnects on the board | Seat becomes *away* at once. Turn timer runs; if it is their turn they are auto-played. They can reconnect within 5 minutes (setting) and reclaim the seat with a full state snapshot (g.3). |
| A player disconnects during a minigame | They keep the score they had; the minigame goes on; they return to the board on reconnect. |
| 5 minutes pass | The seat becomes an **autopilot** seat (same as a board-only bot, e.6). Their Brass, Stars and items stay and count. |
| Only one human is left | The game ends after the current round and the remaining human is declared the winner if ahead, otherwise normal scoring. Setting `abort_if_alone` (default on). |
| Server restart queued (ADR-0103:7 countdown) | The mod finishes the current turn if there are under 60 s left, otherwise saves and aborts the minigame without payout (arena instances are destroyed; the minigame is repeated on resume). The game state is in KV (g.3) so it survives. |
| Server crash | The game is resumed from the last saved turn boundary (g.3: the state is saved every turn; ADR-0074:7 gives a 30-60 s default save cadence plus "save now" tags). |
| Mod removed | Players in the arena or board instance are moved to their last valid position (ADR-0092:7). |

**Resume:** after a restart, the game is `PAUSED_RESUMABLE` until all human seats are online again (or 10 minutes pass; then autopilot as above) **[design proposal]**.

### e.6 Bots for empty seats (question Q2)
- **Option B (leaning):** *board-only bots*. A bot rolls, buys a Star whenever it can, takes the main path at forks, uses an item at random, and picks the nearest target for Duels and Pickpocket. In minigames a bot gets a **simulated score**: a placement drawn from a distribution weighted by a setting `bot_skill` (default 0.5; at 0.5 the expected place is the middle). Bots are labelled "(bot)". The simulated placement uses `kernel.rng` so it is reproducible (ADR-0091:7).
- The same logic runs the **autopilot** for disconnected humans.
- A bot is not a WoW character; it has no pawn in the arena. Board pawns for bots are overlay markers (ADR-0083:7) **[design proposal]**.
- Real bot players in minigames are **not** planned. (`mc:playerbots` as an unsafe-tier plugin is an early ring-3 milestone for soak tests (ADR-0052:13); the mod does not depend on it.)

### e.7 Fairness, trust and cheating
- The client is trusted and anti-cheat is out of scope (ADR-0002:16). The server still decides every roll, payment and result, so a modified client cannot simply write itself Brass; **what a client controls is its own movement** in arenas. Reaction minigames use server timestamps (G12).
- **Character differences:** a level-80 player has more speed and health than a level-10 one. In arenas everyone should have the same speed, no gear effects and no combat. That is gap G2 (open question Q18, `docs/open-questions.md:24`).
- **Rule of least surprise:** all rules a player can see on the card (b) are the ones the server applies; the log shows the seed and every roll (ADR-0034:10, ADR-0091:7).

---

## f. Presentation

### f.1 Camera
- **Board camera:** a raised three-quarter "table view" that frames the active player and the next 10 spaces, looking down at about 55 degrees. It eases between turns and cuts to a wide shot for the Star purchase and the finale.
- **Arena camera:** the player's normal third-person camera, except in minigames that need a top-down view (Tidal Tiles, Echo Pillars, Hearth Hold), which switch to a fixed overhead camera.
- The platform names "camera" as a ring-2 client surface (ADR-0020:12) but gives no function list: gap G10.

### f.2 UI (all in the client UI framework, ADR-0020:12; the framework is built after step 1, ADR-0029:12)
```
+--------------------------------------------------------------------------+
| P1 [portrait] 12 Brass  2 Star | P2 ... | P3 ... | P4 ...    Round 7/15   |
+--------------------------------------------------------------------------+
|                                                                          |
|                       (the board in the world view)                      |
|                                                                          |
|   [Item 1] [Item 2] [Item 3]                         [   ROLL  (d8)   ]  |
|   Space info: "Pier - Star 20 Brass"                  Timer: 24 s        |
+--------------------------------------------------------------------------+
```
- **Player cards** (top): portrait, Brass, Stars, held items (small icons), an "away" badge.
- **Roll button** (bottom right) with keyboard shortcut Space and the command `/wager roll` as a fallback (ADR-0082:7 says power users get commands).
- **Choice dialogs:** fork arrows drawn as overlay (ADR-0083:7), buy-a-Star dialog with Yes/No, shop list, target picker.
- **Announcement cards:** minigame title, goal and controls; result table; Honours reveal.
- **Colour-blind safety:** every colour is paired with a symbol (Warm = flame icon, Cool = drop icon).
- **Text:** English only (ADR-0030:30).
- Whether mods can create *new* UI widgets or only use the framework's ones is **[open]** (ADR-0020:13 puts new widget types into ring 3; `docs/open-questions.md:7` Q1 is about UI ownership between mods).

### f.3 The board in the world
- The board is drawn with **overlays**: lines (paths), icons on each space, text labels, and an area highlight on the active player's reachable spaces (ADR-0083:7: "lines, areas, text, icons at positions"). A per-mod client toggle lets a player mute the overlays (ADR-0083:7 guardrail).
- Props (trees, lighthouse, lanterns) are **models** shipped as glTF/GLB (ADR-0004:17). How placed model objects are created in an instance is gap G6.
- **First version without models:** overlays and coloured ground markers only, so the board is playable before any model pipeline exists (section i, step 3).

### f.4 Audio (ADR-0084:7: OGG files, UI sounds, positional audio, a music channel with ducking, triggered by the server via RPC; "v1 may be naive")
- Music: one looped board track per board, one minigame loop per category, one result jingle. All original; no melody may be recognisable from another work (ADR-0061:7 applies the originality rule to AI-generated assets too).
- Sounds (about 25): die rattle and land, hop step (varies in pitch with the Brass total), Lantern chime, Ember hiss, Wonder shimmer, Star fanfare (our own motif: three rising bell notes), countdown ticks, minigame start/stop, UI clicks.
- Mix: music ducks under the Lamplighter's lines and the countdown.

### f.5 Assets list and rules
| Group | Count (v1) | Format (ADR-0004:17, 21 whitelist) |
|---|---|---|
| Board prop models (2 boards) | about 30 each | glTF/GLB |
| Space icons and UI | about 40 | PNG |
| Star lantern, Lamplighter | 2 | glTF/GLB |
| Minigame arenas | 4 shared courtyards/arenas | glTF/GLB (or reused instance shells, G4) |
| Music and sounds | 8 music, 25 sound effects | OGG |
- **All original.** AI-generated art or audio is allowed under the originality rule (ADR-0061:7); the optional `ai_assisted` manifest flag can label it (ADR-0061:7). The uploader is responsible for rights (ADR-0061:7).
- **No Blizzard assets are shipped** (ADR-0004:17); referencing existing paths in the player's own data is allowed (ADR-0004: Consequences, line 20 says mods can reference vanilla assets).
- **No Nintendo lookalikes:** no plumber, no mushrooms, no five-point golden star, no pipes, no dice-block heads. The art direction note: warm lantern-light, brass, paper, small animals.

---

## g. Technical design on our platform

This section says which platform surfaces the mod **uses**, cites the ADR for each, and lists the **gaps**: things the mod needs that no ADR defines yet. Gaps are requests the mod would make to the platform, not changes to ADRs. "Settled" means "an ADR decides it will exist", not "it is built".

### g.1 Mod anatomy (folder layout per ADR-0030:12-25)
```
wayfarers-wager/
  mod.lua                 manifest: id, version, depends, permissions (none outside the game), declares (hooks, rpc, record types, roles/permissions, tables), tags, ai_assisted
  records/
    boards/               lantern_isles.lua, clockwork_orchard.lua
    spaces/ items/ events/ honours/ companions/
    minigames/            one record per minigame (c.5)
    arenas/               instance templates (g.4 G4)
  server/
    init.lua              wires events, commands, RPC handlers
    engine/               turn state machine, dice, ledger, scoring (pure Lua, no game API: testable)
    minigames/            one script per minigame (c.5)
    bots.lua              board bots and autopilot (e.6)
  client/
    init.lua              UI, overlays, camera, audio hooks
  assets/                 glTF/GLB, PNG, OGG only (ADR-0004:21)
  config.schema.lua       every number in section b (ADR-0029:9)
  tests/                  engine tests with a simulated client (ADR-0052:10)
  AGENTS.md  README.md  LICENSE
```
The `declares` list is mandatory and checked by the site and by the kernel at run time (ADR-0030:28).

**Design rule for the mod itself [design proposal]:** the *engine* (dice, movement along the graph, ledger, scoring, the turn state machine) is plain Lua with no calls into the game; the game API is touched only by a thin *adapter* layer (move a pawn, show an overlay, send RPC). That keeps the rules testable without a client (g.7) and portable to other front ends later.

### g.2 Platform surfaces used (each with its ADR)
| Need | Surface | ADR (file:line) | Status of the surface |
|---|---|---|---|
| Declare boards, items, minigames as data | Records + schemas, mod-defined record types | ADR-0008:13, :19; ADR-0030:26 (`record_types.defines`) | Decided |
| Missing-mod safety for our record types | A placeholder record per type | ADR-0048:12 | Decided; the mod must ship one |
| Game logic | Server Lua 5.4, own state per mod | ADR-0015:12, :14 | Decided |
| Saved game state | Per-mod KV in world/account/character scope, write-through | ADR-0020:11; ADR-0023:9 | Decided |
| Safe saves after a reload | Kernel-enforced restore-before-save barrier | ADR-0115:17 | Decided; the mod must run its restore phase on load |
| Save cadence and "save now" | Aggressive in world-clock mode; mods may tag events | ADR-0074:7 | Decided |
| Private board and arenas | `world.instance(map, { owner, persistent, template })` | ADR-0024:9 | Decided; open zones come later (ADR-0024:11) |
| Dice, draws, bot scores | `kernel.rng` per-mod and per-instance streams, seed logged | ADR-0091:7 | Decided |
| Commands `/wager ...` | Manifest-declared commands, namespaced | ADR-0082:7 | Decided |
| Who may host/abort | Namespaced permissions with default roles | ADR-0031:8 | Decided |
| Graceful denial | Denials are return values | ADR-0028:15 | Decided |
| Every number tunable | Schema-driven config, scope client/server | ADR-0029:9, :13 | Decided; in-game UI after step 1 (ADR-0029:12) |
| Client/server messages | RPC channels, versioned messages, server-side validation | ADR-0020:11; ADR-0066:7 | Decided (mod message typing: G13) |
| Board drawing | World-anchored overlays: lines, areas, text, icons | ADR-0083:7 | Decided |
| Sound | Mod audio API (OGG, music channel, server-triggered) | ADR-0084:7 | Decided; v1 may be naive |
| HUD, dialogs | Client UI framework | ADR-0020:12; ADR-0029:12 | Named; contents open (G9) |
| Camera, input | Client camera and input surfaces | ADR-0020:12; ADR-0028:9 (`client.input_hook` permission) | Named; contents open (G5, G10) |
| Win rewards | Achievements: records + events, kernel tracks and shows | ADR-0096:9, :10 | Decided |
| Other mods add minigames | `provides`/`wants` capability tags; `extends` wrapper | ADR-0032:8; ADR-0021:9 | Decided; the tag is a process step (c.5) |
| Pack as modpack | Modpack type | ADR-0044:9 | Decided |
| Group handling | Group create/invite/move/disband (gap review item 4) | ADR-0114:20 | Declared for the IDL, not defined |
| Zones, proximity | `world.query(shape)` and `zone.on_enter/on_leave` (item 2) | ADR-0114:16 | Declared for the IDL, not defined |
| Disconnects, restarts | `player.logout` with reason, `server.pre_restart`, `world.saving` (item 8) | ADR-0114:24 | Declared for the IDL, not defined |
| Position safety | Safe reposition when an instance vanishes | ADR-0092:7 | Decided |
| Timers | World clock `now()`, pause freezes time | ADR-0025:14, :18 | Decided |
| Compute on observation | Store deadlines, compute at read | ADR-0080:7 | Principle |
| Observability | Automatic attributed logging; counters measure outcomes | ADR-0034:10, :12; ADR-0115:8-14 | Decided |
| Failure containment | A failing mod keeps running; admin throttle per player/mod | ADR-0090:7 | Decided |
| Distribution | Registry first; hash and signature verified | ADR-0073:7 | Decided |
| Backups | Mod-prefixed tables are part of world backups | ADR-0045:9 | Decided |
| Testing | `modcraft test` with a simulated player (cannot walk) | ADR-0052:10 | Decided |
| No paid content | Whole work distributed; funding links only | ADR-0104:7 | Decided; the mod is free |

The mod needs **no outside-the-game permission** (ADR-0028:9: `fs.*`, `net.outbound`, `process.spawn`, `client.input_hook` etc.), except possibly `client.input_hook` if the platform's input surface (G5) requires it. A mod installed via a server profile has those permissions off by default (ADR-0028:13), so the design avoids needing them.

### g.3 Data model sketch (KV store) — all keys are a **[design proposal]**
KV acts like a table (`mod.state.games[id] = {...}` is saved by write-through, ADR-0023:9). Scope is chosen per key (ADR-0020:11).

| Key (scope) | Fields | Notes |
|---|---|---|
| `games/<id>` (world) | `id`, `board`, `seed`, `rounds_total`, `round`, `phase` (state name, g.5), `active_seat`, `star_pier`, `star_price`, `festival_from`, `created_at`, `rules_version`, `honours = {3 ids}` | One row per game. `seed` makes the game replayable (ADR-0091:7). |
| `games/<id>/seats/<n>` (world) | `character_guid`, `name`, `is_bot`, `companion`, `colour_group`, `space` (space id), `brass`, `stars`, `items[1..4]`, `connected`, `away`, `autopilot`, `stats = {earned, lost, moved, embers, duels, items_used, minigame_wins, coop_score}` | Counters feed Honours (b.9). |
| `games/<id>/edges` (world) | The live edge list | Needed only for boards with a Gear Turn (d.2). |
| `games/<id>/traps` (world) | `{space, owner}` | Tripwires. |
| `games/<id>/ledger` (world) | Append-only list of `{n, seat, kind, delta, before, after, reason, round}` | Every Brass and Star change. Source for the conservation self-check (g.7). |
| `games/<id>/log` (world, ring buffer) | Events: dice, moves, choices, minigame results | Mirror of what clients received. |
| `profiles/<guid>` (character) | `games`, `wins`, `stars_total`, `best_minigame_scores`, `titles` | Lifetime stats; they also feed achievements (ADR-0096:10). |
| `lobby/<host guid>` (world) | `seats`, `board`, `rounds`, `bots` | Dies when the game starts or after 10 minutes. |

**Record types the mod defines** (each with a description and a placeholder, ADR-0034:12, ADR-0048:12): `wager:board`, `wager:space_kind`, `wager:item`, `wager:event`, `wager:honour`, `wager:companion`, `wager:minigame`, `wager:arena`.

**Persistence discipline:** the engine writes the new state to KV **at every phase boundary** (not each tick), because the restore-before-save barrier refuses writes before restore has run (ADR-0115:17), and because aggressive saves are the platform default (ADR-0074:7). Game state is "in KV or gone" (ADR-0023:9). Read-after-write is never relied on across an async boundary (ADR-0115:38 says the persistence API makes it impossible or explicit).

### g.4 Gaps: things the mod needs that no ADR defines yet
Each is stated as a gap with the nearest ADR text. **None of these is an invented API.** Each is worded as "the mod needs this from the platform", for the manager to route to the platform's own backlog.

| # | The mod needs | What the ADRs say | Impact if missing | Workaround for step 1 |
|---|---|---|---|---|
| G1 | **Scripted pawn movement:** move a player's character along a list of points, with a hop animation, while the server stays in control | "movement" appears in the ring-2 list (ADR-0020:12); no function is defined | The board's central animation | Teleport per space, with an overlay marker that animates |
| G2 | **Standardise players in an arena:** equal speed, no gear effects, no combat, restore afterwards | Open question Q18, "player-state snapshot/restore primitive" (`docs/open-questions.md:24`) | Unequal characters make minigames unfair | Accept unfairness in v1; only use minigames that do not depend on speed (Echo Pillars, Quickdraw) first |
| G3 | **Group teleport with guaranteed origin restore** | Open question Q17 (`docs/open-questions.md:23`); group management is gap item 4 (ADR-0114:20); safe reposition is decided (ADR-0092:7) | Carrying players to the board and arenas, and back | Record each player's position in KV and move them with ordinary teleport, relying on ADR-0092:7 for crashes |
| G4 | **Instances on suitable maps:** step 1 supports only dungeon shells already in AzerothCore's instance system; open zones come in step 2; custom zones are an open question | ADR-0024:11; `docs/open-questions.md:18` (Q12) | The board and arenas must be built on borrowed maps | Use a flat shell map and draw everything with overlays; which shell maps are suitable is a survey item **[open]** |
| G5 | **Mod-defined key binding / action button / pointer input** | "input" is a ring-2 client surface (ADR-0020:12); a `client.input_hook` permission exists (ADR-0028:9) | The `A` and `P` inputs (c.4) | Use UI buttons and the normal jump/movement keys; `/wager a` as a command fallback |
| G6 | **Placing, moving, removing model objects (GameObjects) in an instance** from a mod, with a glTF/GLB model | glTF/GLB is the model format (ADR-0004:17); "loot & spawns" is in ring 2 (ADR-0020:12); placed objects are components in KV for housing (ADR-0018:17); no contract for models in instances | Props, the Game Table, carts, vanishing planks | Overlays only (f.3) |
| G7 | **Player scale change** | Nothing | Giant's Garden | Defer that minigame; use Lighthouse Keeper for 1v3 |
| G8 | **Per-player visibility** (spectators; each team sees its own markers) | Phasing is gap item 5 (ADR-0114:21) | Spectators and team-private info | All see everything |
| G9 | **Client UI widgets:** panels, buttons, icon rows, tooltips, countdowns | UI framework is named (ADR-0020:12) and arrives after step 1 (ADR-0029:12); Q1 (`docs/open-questions.md:7`) | The HUD | Overlay text and chat output |
| G10 | **Camera control from a mod:** set position, angle, ease, follow | "camera" named (ADR-0020:12) | The table view | Normal camera in v1 |
| G11 | **Client-visible countdowns tied to the server clock** | `now()` is the adjusted clock (ADR-0025:14); nothing about sending server time to clients | Timers that look right to all clients | Send a duration in each RPC and count down locally; the server decides expiry |
| G12 | **Latency fairness for reaction games** | Nothing; the client is trusted (ADR-0002:16) | Quickdraw, Bridge Builders | Server timestamps on receipt; accept ping differences; use only in games where a few hundred ms do not decide the result, or compensate by measuring each client's round trip in the mod **[open]** |
| G13 | **Typed mod RPC messages:** how a mod declares message formats | RPC wire format is IDL-generated for the platform's packets (ADR-0066:7); mod declarations include `rpc` (ADR-0030:26) | The protocol in g.6 | Assume mod-declared channels carry typed tables; mark as an assumption until the surface is defined |
| G14 | **Two clients on one PC for testing** | Reference machine specs not yet recorded (`docs/open-questions.md:27`, Q21; ADR-0081:7) | Testing multiplayer alone | Bots (e.6) plus a second client on the same PC when the machine allows |
| G15 | **Headless test of movement-based minigames** | The simulated player cannot walk (ADR-0052:10) | Minigames are manual-test only | Engine and board logic are fully testable (g.7); minigames get scripted "scenario" tests that move players by teleport |

### g.5 Turn state machine
All transitions are decided by the server's engine. Each state names its **timer**, **what is saved to KV** and **who may act**.

```
LOBBY --start--> SETUP --> ROUND_START --> TURN_BEGIN(seat) --> ITEM_WINDOW --> ROLL
   ^                                                                              |
   |                                                                              v
   |   TURN_END <-- RESOLVE_SPACE <-- LAND <-- MOVE (per step: PASS_CHECK, FORK_CHOICE)
   |      |
   |      +-- more seats? --> TURN_BEGIN(next seat)
   |      +-- no --> MINIGAME_SELECT --> MINIGAME_ANNOUNCE --> TRANSPORT_OUT --> COUNTDOWN
   |                                                                                |
   |        ROUND_END <-- RETURN <-- PAYOUT <-- RESOLVE <-- PLAY <-----------------+
   |           |
   |           +-- rounds left --> ROUND_START
   |           +-- no --> FINAL_HONOURS --> RESULTS --> ENDED
   |
   +-- any state --(pre_restart / all humans gone)--> PAUSED_RESUMABLE --(resume)--> the saved state
   +-- any state --(admin abort / fatal error)-----> ABORTED
```

| State | Who acts | Timer | Entered when | Saved to KV |
|---|---|---|---|---|
| LOBBY | Host and players | 10 min idle | `/wager host` | `lobby/<host>` |
| SETUP | Engine | none | All ready | `games/<id>`, seats; seed; seat order; star pier; Honours |
| ROUND_START | Engine | none | New round | `round`; Festival flag |
| TURN_BEGIN | Engine | none | Next seat | `active_seat` |
| ITEM_WINDOW | Active seat | 20 s | After begin | item use, ledger |
| ROLL | Active seat | 30 s | After items | roll value, seed position |
| MOVE | Engine | about 0.4 s per space | After roll | `space` per step; fork asks |
| FORK_CHOICE | Active seat | 20 s (default: main path) | Fork reached | choice |
| PASS_CHECK | Engine and seat | 20 s | Active Star pier passed with Brass of at least the price | Brass, Stars, new pier |
| LAND | Engine | none | Steps used | `space`, `colour_group` |
| RESOLVE_SPACE | Engine and seat | 20 s per choice | After landing | Brass, items; sub-flows: SHOP, DUEL, EVENT, TIDE |
| TURN_END | Engine | none | Space resolved | seat stats |
| MINIGAME_SELECT | Engine | none | All seats done | `phase` |
| MINIGAME_ANNOUNCE | Engine | 5 s | After select | minigame id |
| TRANSPORT_OUT | Engine | up to 10 s | After announce | stored origin positions |
| COUNTDOWN | Engine | 3 s | All in arena | none |
| PLAY | Minigame script | 20 to 60 s | After countdown | none (transient) |
| RESOLVE | Engine | none | Time or goal | validated result |
| PAYOUT | Engine | none | After resolve | Brass, ledger, wins |
| RETURN | Engine | up to 10 s | After payout | positions restored |
| ROUND_END | Engine | none | All returned | `round + 1` |
| FINAL_HONOURS | Engine | 8 s | Last round ended | Stars |
| RESULTS | Players | 60 s | After honours | profiles, achievements |
| ENDED | none | none | After results | game archived |
| PAUSED_RESUMABLE | none | 10 min | Pre-restart or humans gone | everything |
| ABORTED | none | none | Abort or fatal | log kept |

**Invariants checked on every transition (and counted if they fail; ADR-0115:8-12):** Brass >= 0; Stars >= 0; total Stars equals the number of purchases plus Honours; exactly one Star pier; every seat's `space` exists in the board graph; one item used per turn.

### g.6 Server and client responsibilities, and the message protocol

**The server (authoritative)** owns: all state, the die and every random draw, movement along the graph, payments, item and event effects, timers, minigame selection and results, bots, saves. **The client** owns: input, drawing (overlays, models, UI), camera, audio, local countdown animation. The client never decides an outcome.

**Version-1 protocol [design proposal; message typing is gap G13]** — one RPC channel `wager`, messages carry `game_id` and a sequence number:
| Direction | Message | Content |
|---|---|---|
| client to server | `intent.roll` | seat |
| client to server | `intent.choose` | `decision_id`, option (fork path, buy yes/no, shop item, target) |
| client to server | `intent.use_item` | slot, parameters |
| client to server | `intent.ready` | lobby ready toggle |
| client to server | `intent.action` | minigame input: kind, client sequence number |
| server to client | `snapshot` | the whole visible game state; sent on join, on reconnect, after any gap in sequence numbers |
| server to client | `event` | `n`, type: `dice_rolled`, `pawn_moved`, `brass_changed(seat, before, after, reason)`, `star_moved`, `decision_request(id, kind, options, duration)`, `minigame_announce`, `minigame_result`, `game_over` ... |
| server to client | `toast` | text and a sound id |

- Every `decision_request` has an id; a reply with a stale id is rejected **and counted with its reason** ("late: timer already expired", "duplicate", "wrong seat"), as ADR-0115:11 requires for silent early returns.
- The server validates every intent: sender is the seat's owner, state allows it, option is in the offered set (a server-side validation hook exists, ADR-0020:11).
- Rate: roughly 1 to 3 messages per second per client on the board, up to 20 per second during minigames; an admin can throttle a player's channel if needed (ADR-0090:7).
- The server may run with a **silent or garbage client** without crashing (ADR-0028:15: the site's smoke test runs mods with all permissions denied and rejects crashes; server mods tolerate a silent client).

### g.7 Observability and testing
**Counters (outcome, not intent; ADR-0115:8-14), per game and per session:** dice rolled (value histogram, with seed, input shown), Brass delta per cause with before/after read back from the ledger, Star purchases (price paid, balance after), early returns by reason (intent rejected, timer expired, item had no target in range), minigame durations, minigame errors, reconnects, autopilot turns. **Bookkeeping next to reality** (ADR-0115:13): the ledger total is compared with the seats' summed Brass each round; any difference is an error line naming the game and the last 5 ledger rows.
**Self-check command:** `/wager doctor` runs the invariants (g.5), prints a pass/fail list, and is available in the console's command palette (ADR-0112:13: the players tab binds buttons to registered commands).

**Tests (`modcraft test`, ADR-0052:10):** the simulated client can send and receive RPC but cannot walk, so:
1. *Engine tests* (no game at all): 1,000 seeded games per board with bot seats; check invariants, game length, Star counts, and that a winner exists (g.5 invariants). The simulator also outputs the economy statistics in section i, step 4.
2. *RPC tests:* a simulated client plays a scripted game over the `wager` channel, including stale, duplicate and garbage messages.
3. *Disconnect tests:* simulate `player.logout`, `pre_restart`, and resume from KV.
4. *Minigame scenario tests:* each minigame script is driven by a scripted `ctx` (positions set by the test, inputs injected) and must return a valid result; real movement is manual (G15).
5. *Permissions-denied smoke test* runs on the site automatically (ADR-0028:15).

