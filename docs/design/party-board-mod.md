# Design: "Wayfarers' Wager" — a party board game mod

- **Status:** Draft — rests on the proposed ADR in `docs/tasks/098-proposed-adr.md`; not accepted. (The design itself needs no ADR change: the mod is built only on the platform's mod API. The proposed ADR only decides whether this mod drives the platform build order.)
- **Last reviewed:** 2026-10-28
- **Author:** doc-writer, task 098, for Ludwig
- **Working title:** Wayfarers' Wager (a placeholder; renaming is free). Mod id: `<ns>:wayfarers-wager`, namespace **[open]** (a personal namespace follows the GitHub username, ADR-0030:30; `mc:` is reserved for platform core mods, ADR-0003:10, ADR-0119:30-34).
- **Reading guide:** sections a to j follow the brief. Every statement about what the platform provides carries an ADR `file:line`. Anything the ADRs do not settle is marked **[design proposal]** (my suggestion) or **[open]** (nobody has decided). Nothing here claims that code exists: the platform is at the documentation stage, and "the ADR decides X" never means "X is built".

## In short (read this first)

- **What it is:** a party board game for 2 to 4 friends (or 1 human with bots). You roll a die, walk a 48-space board, fetch **lanterns** from lit Piers and carry them to the **Beacon** to earn **Stars**, and play a short **minigame** at the end of every round. Most Stars after 15 rounds wins.
- **The twists that are our own:** a carried lantern can be dropped, robbed (Tripwire, Snatch, Lantern Hook) or burn out; teams for the minigame come from the standings (leader against the rest, or a draft by the player in last place); in the last five rounds a **Rising Tide** floods the board; two game-specific bonus Stars (Lantern Courier, Snare Master). Details: section b.
- **Built only on the platform's mod API.** It changes no ADR. Where the API lacks something, section g.4 lists it as a gap (15 gaps, G1-G15).
- **Decided vs open:** every rule number is a **[design proposal]** to be tuned by simulation. Five questions need Ludwig (j.1: Q1 reference-mod role, Q2 bots, Q3 player count, Q4 game length, Q5 arcade mod relation), plus five rulings made overnight that he can overturn (j.1).
- **First build step:** "press Roll": one record type, one command, one RPC pair, one client panel, saved position, one counter (section i, step 1).

---

## 0. Where this comes from

Ludwig, 2026-10-28 (verbatim, Swedish): "vill att den första modden ska vara en Mario Party-liknande mod där man går omkring på ett spelbräde och samlar stjärnor och spelar mini games med andra spelare". "Mario Party-like" is used here **only as the name of a genre**: a turn-based board game for a few friends, with dice, a victory token you earn, and short minigames between turns. Everything in this document is original: names, characters, board themes, items, minigames, look and sound. No Nintendo names, characters, art, music or icons, and no Blizzard assets (ADR-0004:17).

Ludwig's later instruction: the mod must not affect ADRs, because the point of the mod API is that mods are built standalone from each other. So this is written as a **standalone mod built only on the platform's mod API**. Where the API does not yet offer something the mod needs, that is listed as a **gap the mod needs filled by the platform** (section g.4), not as an ADR change.

### Terms explained once
- **Mod:** a folder with records, Lua scripts and optional native plugins (ADR-0008:12-15). **Record:** a declarative description of "what exists" (here: a board, an item, a minigame), written as a Lua table or JSON and validated against a schema (ADR-0008:13).
- **Kernel:** the shared runtime library that loads mods (ADR-0003:9). **Ring 1/2/3:** three layers of its API (foundation, game surface, extensions; ADR-0020:10-13).
- **RPC:** a message between the game client and the server (ADR-0066:7). **KV store:** the mod's saved key/value data (ADR-0023:10).
- **Instance:** a private copy of a map owned by a mod (ADR-0024:9). **Overlay:** things the client draws on top of the world, such as lines and icons (ADR-0083:7).
- **Authoritative server:** the server decides what happened; the client only shows it and sends requests.
- **Walking skeleton:** the thinnest end-to-end slice that touches every layer, grown step by step (ADR-0050:11-15).
- **Seed:** the starting number of the random-number generator; the same seed gives the same dice and draws. **Headless:** run without graphics or a client, only the rules. **Invariant:** a rule that must always be true (for example "Brass is never below 0"), checked by the server.
- **Free-for-all (FFA):** every player for themselves. **Hunt, Draft:** the two team formats of c.1.
- **Ledger:** an append-only list of every Brass and Star change, so totals can be re-added and checked. **Ring buffer:** a log of fixed size that overwrites its oldest entries.
- **Write-through, phase boundary:** write-through means a change to the saved table is stored immediately (ADR-0023:10); a phase boundary is the moment the game changes state (for example roll to move).
- **IDL:** the single file that defines every platform function, from which code and documentation are generated (ADR-0020:17). **glTF/GLB:** the open 3D-model file format that mods must use (ADR-0004:17). **Phasing:** showing different players different versions of the world (ADR-0114:21).
- **AFK:** away from keyboard. **Soak test:** running the game for hours to find slow leaks and crashes. **Unsafe-tier plugin:** native code with full access to the game's internals (ADR-0012:19).
- **Turn, round, game:** a *turn* is one player's move on the board. A *round* is every player taking one turn, followed by one minigame. A *game* is a fixed number of rounds.

---

## a. Vision and the player's evening

**One sentence:** four friends gather at a table in the world, walk their characters around a miniature-style board, carry lanterns to the Beacon to earn Stars, rob each other on the way, and settle the evening's arguments in 30-second minigames.

**Why this fits the platform's audience:** the platform targets self-hosted servers used "mostly single-player or with a few friends" (ADR-0002:13). A party game needs the second case, or bots (e.6) for the first; it also needs a trusted client and no anti-cheat (ADR-0002:16 states the client is trusted).

### The evening, start to finish (default settings, 4 players, 15 rounds, about 45 minutes)
1. **Arrive (0-3 min).** Everyone is on the server (invite code, ADR-0046:12). One player types `/wager host` near a placed "Game Table" (or uses the lobby panel). The others type `/wager join` or click the table. Each picks a companion and a banner colour.
2. **Lobby (2 min).** Host chooses the board (Lantern Isles or Clockwork Orchard), the game length (10 / 15 / 20 rounds), and whether bots fill empty seats. Rules summary card is shown. All press Ready.
3. **Intro (1 min).** Camera flies over the board. Seat order is shuffled by `kernel.rng` (ADR-0091:7). Lanterns are lit on some Piers (b.4). Everyone stands on the Harbour Gate (start space) with 12 Brass (coins) and 0 Stars.
4. **Rounds 1 to 15 (about 3 min each).** Each player in turn: optionally use an item, press **Roll**, watch their character hop along the path, resolve the space they land on (or fetch, carry, lose or deliver a lantern). After the last seat, the round's **minigame** is chosen from the standings (c.1), everybody is carried to an arena, plays for 20 to 60 seconds, is paid Brass by placement, and is carried back.
5. **Rising Tide (rounds 11 to 15).** The water rises: four more Rim spaces flood each round and cost 2 steps to enter (rules b.7). The last five rounds are where games are won and lost.
6. **Finale (3 min).** After round 15 the two Honours are decided (+1 Star each to their winners). The result screen shows Stars, Brass, minigame wins and stats; the winner gets a title toast and an achievement (ADR-0096:9). Everyone is returned to where they stood before the game (ADR-0092:7, and gap G3).
7. **Afterwards.** The game's log is kept (replayable from its seed, ADR-0091:7). Lifetime stats are saved per character (ADR-0020:11 names per-character KV scope).

### Tone
Warm, cosy, a bit mischievous: lantern-light, paper maps, brass gadgets, small animals. Nobody is eliminated; everybody always plays every minigame. A lucky die or a rubbish roll is meant to be funny, not punishing.

### Design pillars
1. **Luck for laughter, skill for pride.** The die decides where you stand; minigames decide who has money for lantern fees; Stars need both.
2. **Never wait long.** Each single decision is capped at 30 s; with 4 players nobody waits more than about 2.5 minutes between their own actions (b.10 and e.4).
3. **Rules are data.** Every number below is a setting (ADR-0029:9: "every default is a setting"); every board, item, event and minigame is a record, so other authors can add more without touching this mod (c.5).
4. **The server is the referee.** The server rolls, moves, pays and decides (authoritative server). The client shows and asks.

---

## b. Core rules

All numbers are **[design proposal]** and are to be tuned by a headless simulator (a run with no graphics, only the rules) before play-testing (section i, step 4). They are all `config.schema` entries with bounds (ADR-0029:9). The rules were revised in fix round 1 on the manager's overnight ruling so that the rule set is our own (see b.13); Ludwig can change any of those choices in the morning (section j.1, "Rulings awaiting Ludwig").

### b.1 Players, seats, turn order
- 1 to 4 human players, 2 to 4 seats in total (questions Q2 and Q3 in the ADR proposal). A game with one human needs bots (e.6). Seats are numbered 1 to 4. With bots enabled, empty seats are filled up to a host-chosen minimum of 3 [design proposal].
- **Turn order:** at the start the seats are shuffled with `kernel.rng` (ADR-0091:7). No ties are possible. The order stays fixed for the whole game.
- **Game length:** 10, 15 or 20 rounds (default 15; bounds 5 to 30; question Q4).

### b.2 The dice
- The **Wayfarer die** is an 8-sided die (1 to 8, uniform), rolled on the server with the mod's own `kernel.rng` stream, so the same seed replays the same game (ADR-0091:7). `math.random` is forbidden in server Lua (`validate` warns; ADR-0091:7).
- Average roll 4.5. On Lantern Isles a lap of the 36-space Rim takes about 8 of your turns, about 6 if you use a bridge.
- A player **carrying a lantern** (b.4) moves the roll minus 1 (at least 1): the lantern is heavy. The penalty is decided once, when the move starts: a lantern picked up in mid-move does not shorten that move, and a delivery in mid-move does not lengthen it. Average carried move: (1+1+2+3+4+5+6+7)/8 = 3.6 spaces.

### b.3 Movement
- You move forward exactly as many steps as your die (or item) says, one space at a time. All edges are one-way; you never walk backward except by event (b.5).
- **Forks (crossroads):** where a space has two outgoing paths, the mover chooses on arrival (20 s; default is the main path).
- **Flooded spaces** (b.7) cost 2 steps to enter. If only 1 step is left you still enter and stop there.
- **Spaces you pass over have no effect, with these exceptions, where you pause and something happens:** a lit Pier with no lantern in your hand (pick-up offer, b.4); a dropped lantern lying on a space (free pick-up, b.4); the Beacon while carrying a lantern (delivery, b.4); a Tripwire (b.6).
- Several characters may stand on one space.

### b.4 Brass, lanterns and Stars (how a Star is earned)
- **Brass** is the coin. Everyone starts with **12 Brass** (setting).
- The **Beacon** is a fixed space on the board (Lantern Isles: Rim space R28). It is the only place a Star can be earned.
- **Stars are earned by carrying a lantern to the Beacon**, not bought. A **Star** is an eight-point compass star lantern (not the five-point shape).
- **Lit Piers.** At any time some Piers hold a lantern of the Lamplighter (a lantern-keeper figure). The number of lanterns is *seats minus 1*, bots included (4 seats: 3 lanterns, 3 seats: 2, 2 seats: 1; minimum 1). A lantern is always in exactly one of four states: **lit** (waiting at a Pier), **carried**, **dropped** (lying on a space) or **waiting** (out of play until it relights). At game start they are drawn with `kernel.rng`. They are drawn on the board by overlay (ADR-0083:7).
- **Picking up.** When you pass or land on a lit Pier while you hold no lantern, you may pick up its lantern by paying the **wick fee**. **Wick fee = 9 Brass + 5 Brass for each Star you already hold** (so the leader pays more: 9, 14, 19, 24 ...), paid to the bank and never refunded. You may decline. You may carry **one** lantern at a time. If you cannot pay, you cannot pick it up.
- **Carrying.** The carrier is marked with a glow visible to everyone (overlay) and moves at roll minus 1 (b.2).
- **Delivering.** Walking onto *or through* the Beacon with a lantern delivers it: **+1 Star** at once. The lantern becomes **waiting** and a new lantern lights at the start of the next round, on a random unlit Pier other than the one this lantern came from. Delivery needs walking: a swap (Swap Charm, Whirl) onto the Beacon does not deliver.
- **Burning out.** A lantern burns out **7 rounds** after it was picked up, wherever it is (carried or lying): at the start of the next round it becomes **waiting** (the carrier holds nothing), and relights at the start of the round after, as above. A lantern that is still lit at a Pier does not burn. The fee is lost. (Longest carry from any Pier to the Beacon on Lantern Isles is 18 spaces, 18 / 3.6 = 5 turns, so 7 rounds is a margin.)
- **How a carrier can lose the lantern (the ambushes; every one is a board mechanic):**
  1. **Ember space.** Landing on an Ember: the lantern is dropped on that space and lies there (the carrier also pays the Ember cost).
  2. **Tripwire.** A Tripwire (b.6) stops the carrier, costs Brass and makes the carrier drop the lantern on that space; the Tripwire's owner may pick it up **at once, for free** (a robbery).
  3. **Snatch.** If another player ends their move on the carrier's space, that player may Snatch: both roll the die; the higher roll takes the lantern, a tie leaves it with the carrier. One attempt per landing. Nobody pays. The Snatch is resolved **before** the snatcher's own space effect, so a snatcher who landed on an Ember drops the lantern at once.
  4. **Lantern Hook** (item, b.6): takes the lantern from a carrier within 4 spaces ahead of you.
  A **Ward** (b.6) cancels one of these against its owner.
- **A dropped lantern** lies on its space, and still burns (7-round rule). The first player to pass or land on it may take it for free (no wick fee) and carry it on.
- **Stars are never lost or taken** in version 1; only the lantern can be taken. A star-stealing event is a possible later addition [open].
- **Brass cannot go below 0.** A cost of 6 with 4 Brass costs 4.

### b.5 Spaces and their effects (Lantern Isles composition, 48 spaces)

| Space | Count | Effect on landing |
|---|---|---|
| Harbour Gate (start) | 1 | Nothing. |
| Beacon | 1 | Delivers a carried lantern (b.4); otherwise +2 Brass. |
| Lantern | 16 | +4 Brass. |
| Pier | 6 | If lit: pick-up offer (b.4). Otherwise +2 Brass. |
| Ember | 7 | -6 Brass; a carried lantern is dropped here (b.4). A Ward blocks both. |
| Wonder | 6 | Draw one event card (below). |
| Cache | 4 | Draw one item (b.6) if you have a free slot; otherwise +3 Brass. |
| Duel | 3 | Pick one opponent; both stake 4 Brass; a 15-second duel minigame (c.6) decides; the winner takes both stakes. With less than 4 Brass, you stake what you have and the other side stakes the same [design proposal]. |
| Stall | 2 | Shop: buy up to 2 of 3 randomly offered items (prices in b.6). |
| Whirl | 2 | Swap places with a random opponent chosen by `kernel.rng`. The swapped player does not resolve the space they are moved to. Lanterns stay with their carriers. |

Total 1 + 1 + 16 + 6 + 7 + 6 + 4 + 3 + 2 + 2 = **48**.

**Wonder events** (draw one, weight in brackets; **[design proposal]**):
1. *Windfall* (3): you gain 9 Brass.
2. *Pay the Piper* (2): you lose 6 Brass.
3. *Open Hands* (2): every player gains 3 Brass.
4. *Lantern Rain* (2): every player standing on a Lantern space gains 4 Brass.
5. *Headwind* (2): you move back 3 spaces and do not resolve that space.
6. *Tailwind* (2): you move forward 3 spaces and resolve that space.
7. *Wishing Well* (1): give any player 4 Brass; you gain an item.
8. *Surveyor* (1): you see which Piers will relight next.
9. *Mischief* (1): every player passes one random held item to the next seat in turn order.
10. *Rebate* (1): the player with the fewest Brass gains 7 Brass.
Total weight 17.

### b.6 Items

Each player holds up to **3 items** (setting). At most **one item may be used per turn**, and only before rolling. Items come from Cache spaces (random) and Stalls (buy).

| Item | Stall price | Effect |
|---|---|---|
| Steady Die | 6 | Your roll this turn is exactly 4 (3 if you are carrying a lantern, by the same minus 1). |
| Twin Dice | 9 | Roll two dice and move their sum (2 to 16; minus 1 if carrying). |
| Tripwire | 8 | Place it on the space you stand on. The first other player to pass or land on it stops there and loses 4 Brass to you; a carrier also drops the lantern there and you may take it at once, free. Used up when it triggers. One Tripwire on the board per owner. |
| Swap Charm | 12 | Swap places with any one player; you do not resolve the new space, and a swap never delivers a lantern. Lanterns stay with their carriers. |
| Ward | 7 | Cancel the next Ember, Tripwire, Snatch or Lantern Hook effect against you. |
| Pickpocket Glove | 12 | Steal 5 Brass from a player within 6 spaces of you. |
| Rain Check | 10 | Use before rolling: this turn, after you see your roll, you may roll once more and use the second result. |
| Lantern Hook | 16 | Take the lantern from a carrier within 4 spaces ahead of you; you now carry it. |
| Golden Wick | 20 | Your next pick-up costs no wick fee, you move at the full roll while carrying, and that lantern's burn time is 4 rounds longer. |

### b.7 The Rising Tide (final five rounds): a board-changing twist
In the last 5 rounds (setting `tide_rounds`, default 5) the water rises on Lantern Isles. At the start of each of those rounds, the next stretch of the Rim is **flooded**: 4 consecutive Rim spaces per round, 20 of the 36 Rim spaces in total, in an order shown from round 1 as a water-line preview on the overlay. Bridges, the Beacon island (R24 to R31) and the Harbour Gate stay dry. A flooded space costs **2 steps to enter** (b.3); everything else about it is unchanged. Effects: by the last round, crossing the Rim is about 1.5 times slower (a lap costs 56 steps instead of 36), bridges become more valuable, and carriers must hurry or take the dry route. Clockwork Orchard has its own twist (d.2). Neither doubles any payout.

### b.8 End of game and scoring
1. After the last round's minigame, the two Honours are decided and each gives +1 Star to its winner(s) (b.9).
2. **Winner:** the player with the most Stars. **Tie-breakers, in order:** more Brass; more minigame wins; shared victory.
3. Brass is not converted to Stars. Items are worth nothing at the end.

### b.9 Honours (bonus Stars, two, both specific to this game)
Both are always in play and shown on the card from the start (setting `honours_visible`, default on). A count of 0 never wins. Ties: all tied players win the Honour.

| Honour | Won by |
|---|---|
| Lantern Courier | Most lanterns delivered to the Beacon. |
| Snare Master | Most Tripwire catches (a catch is a player stopped by your Tripwire). |

### b.10 Timers and the pace of one turn
- Roll timer: **30 s**, then the server rolls for you (setting). Re-roll decision (Rain Check or Sable): 10 s. Choice timer (fork, target, shop, pick-up, Snatch): **20 s**, then the default choice is taken (documented per decision).
- Each single decision is capped at 30 s (a turn with an item, a roll, a fork and a pick-up has several decisions, so a whole turn can take longer).
- Hopping animation: about 0.4 s per space on the client.
- All timers use `now()`, the world clock (ADR-0025:14, in world-clock mode, which is the default for a local world, ADR-0025:16): they freeze with a pause (ADR-0025:18).
- **Estimates [design proposal, to be measured]:** one player's turn about 25 s; a minigame cycle (announce, transport, play, payout, return) about 80 s. A 4-player round is therefore about 4 x 25 + 80 = 180 s = 3 minutes. 15 rounds = about 45 minutes.

### b.11 Companions (optional flavour, cuttable for v1)
Each player picks a small companion with one tiny passive. **[design proposal]**
| Companion | Passive |
|---|---|
| Pip the moth | Ignores the first Ember of the game (no cost, no drop). |
| Bramble the hedgehog | Lantern landings pay +1. |
| Sable the heron | Once per game, may re-roll after seeing the roll. |
| Rue the fox | Sees which Piers will relight next, as in the Surveyor event. |
| Skip the otter | May decline a Whirl swap. |
| Dell the mole | Has 4 item slots. |

### b.12 Economy check: the arithmetic
Hand calculation for a 4-player, 15-round game; these are **estimates**, to be replaced by the simulator's numbers (section i, step 4). Recomputed in fix round 2 (items limited by the number of Stalls; Wonder events counted for every player they affect).

| Source of Brass, per player over 15 rounds | Calculation | Brass |
|---|---|---|
| Start | setting | 12 |
| Space landings (15 turns) | per landing (16 x 4 + 3 unlit Piers x 2 + Beacon 2 - 7 x 6) / 48 = 30 / 48 = 0.625; x 15 | 9.4 |
| Wonder events | Per draw, the expected Brass to one given player (the drawer is a random player, so the drawer's gain is divided by 4): Windfall (weight 3) 9 / 4 = 2.25; Pay the Piper (2) -6 / 4 = -1.5; Open Hands (2) +3; Lantern Rain (2) 4 x 16/48 = 1.33; Rebate (1) 7 / 4 = 1.75; the other five events 0 Brass (Wishing Well is a transfer). Weighted: (3 x 2.25 - 2 x 1.5 + 2 x 3 + 2 x 1.33 + 1.75) / 17 = 14.2 / 17 = 0.83 per draw. Draws per game: 4 players x 15 landings x 6/48 = 7.5. 0.83 x 7.5 | 6.2 |
| Minigame payouts | Rounds: 3 co-op (every 5th); a Hunt needs a 2-Star lead, which is rare before the late rounds, so about 1.5 Hunts; the other 10.5 rounds split about evenly: 5.25 Draft (odd rounds) and 5.25 free-for-all. Averages per player per round: free-for-all (6+4+2+0)/4 = 3.0; Draft 5/2 = 2.5; Hunt (0.4 x 10 + 3 x 0.6 x 4)/4 = 2.8; co-op tier average (2+4+6)/3 = 4.0. 5.25 x 3.0 + 5.25 x 2.5 + 1.5 x 2.8 + 3 x 4.0 = 15.75 + 13.1 + 4.2 + 12 | 45.1 |
| **Total in** | 12 + 9.4 + 6.2 + 45.1 | **72.7** |

| Sink of Brass, per player | Calculation | Brass |
|---|---|---|
| Wick fees | about 9 paid pick-ups per game (3 lanterns x about 2.5 cycles, plus lost ones), fee average 9 + 5 x 1.1 Stars held on average = 14.5, shared by 4 players: 9 x 14.5 / 4 | 32.6 |
| Items bought | Items are bought only at the 2 Stalls: a player lands on a Stall 15 x 2/48 = 0.63 times and buys at most 2 items, about 1.5 on average, so about 0.94 purchases at an average price of 11.1 (the 9 items sum to 100). Items from Cache spaces cost nothing. | 10.4 |
| **Total out** | 32.6 + 10.4 | **43.0** |

Expected unspent Brass per player at the end: 72.7 - 43.0 = about **30**. That is near the top of the target below (10-35, widened from 10-30 in fix round 2), so the first levers, if the simulator confirms it, are a higher wick-fee base, payouts lowered by 1, or a third Stall. Calibration targets for the simulator: median unspent Brass between 10 and 35; fewer than 10% of lit-Pier visits fail because the player cannot pay (the first fee, 9, is covered by the start Brass of 12); deliveries per game about 7 (3 lanterns x about 2.5 cycles each, with a cycle of about 6 rounds: pick-up wait 1.5 + carry 3.7 + relight 1) plus 2 Honour Stars; the winner holds about 3 Stars.

### b.13 What changed in fix round 1, and why (for Ludwig)
The first draft copied too many of the genre leader's signature rules at once (start coins, one star bought at a moving space, +/- coin spaces, last-turns doubling, space-colour teams, three bonus stars). The manager's overnight ruling replaced them: stars are earned by carrying a lantern; teams come from standings (c.1); the final-rounds twist is a rising tide; the numbers differ; there are two Honours specific to this game. These are rulings Ludwig may overturn; see j.1.

---

## c. Minigames

### c.1 Categories, and how teams are formed (from the standings)
**Standings** rank the players by Stars (most first), then Brass, then later seat order. The **leader** is rank 1. The **last place** is the lowest rank. Each round's category is chosen by these rules, **in this order** (all numbers are settings):

1. **All Hands (co-op):** every 5th round (`coop_every`, default 5). Everybody plays together against the clock.
2. **Hunt (1v3):** if the leader has at least **2 Stars more** than the second place (`hunt_margin`, default 2) and the previous round was not a Hunt: the leader plays **alone against the other three**.
3. **Draft (2v2), odd-numbered rounds, exactly 4 players:** the player in **last place picks a partner** (20 s; if no choice is made, the best-ranked other player is picked, a mild catch-up). The remaining two form the other team.
4. **Free-for-all, even-numbered rounds** (and odd rounds when the Draft does not apply).

| Players | Rule 2 (leader ahead by 2 Stars) | Rule 3 | Otherwise |
|---|---|---|---|
| 4 | Hunt 1v3 | Draft 2v2 on odd rounds | Free-for-all |
| 3 | Hunt 1v2: the leader against the other two **[open: scaled variants]** | not used | Free-for-all |
| 2 | not used | not used | **Duel** (1v1) every round except All Hands rounds |

Each minigame record states which categories it supports and for how many players (c.5). The minigame is drawn at random from the pool that fits the category and player count; none repeats until the whole pool has been used (`kernel.rng`, ADR-0091:7). Because teams come from the standings and not from where players stand, the board does not decide them.

### c.2 Payouts (settings; the defaults are balanced in b.12)
| Category | Payout |
|---|---|
| Free-for-all | 1st 6 Brass, 2nd 4, 3rd 2, 4th 0. Ties split the tied ranks' total, rounded down. |
| Draft 2v2 | Winning team 5 Brass each; losers 0. A draw gives 2 each. |
| Hunt 1v3 | The leader wins 10 Brass if they win; if the others win, each of them gets 4. |
| All Hands (co-op) | Bronze tier 2 Brass each, Silver 4, Gold 6. Tiers are defined per minigame. |
| Duel | From a Duel space: the winner takes the stakes (b.5). As a round minigame (2 players): winner 6 Brass, loser 2. |

### c.3 Minigame lifecycle
Every minigame goes through the same eight stages. The mod's turn engine owns the stages; the minigame's own script owns only stage 5. **[design proposal]**
1. **Select:** category from the standings (c.1); minigame from the pool. A Duel space starts the lifecycle too (stages 2 to 8, with the two duellists only).
2. **Announce:** a 5-second card shows the title, goal, and the controls.
3. **Transport:** players are admitted to the arena instance (ADR-0024:9). Their board positions are remembered (gap G3).
4. **Countdown:** 3, 2, 1. Controls are locked until zero.
5. **Play:** the minigame script runs. Server time limit 20 to 60 s, depending on the minigame.
6. **Resolve:** the minigame returns a result table (placements or team win, plus raw scores). The turn engine validates it (all seats present, no impossible numbers, ranks consistent) and records it.
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
A minigame is **one record plus one Lua script**, so a minigame needs no change to the turn engine, and other authors can add more. **[design proposal]** All the shapes below are sketches; the real record schema is written during build step 7 (section i) and validated by the compiler (ADR-0008:13, 19).

```lua
-- records/minigames/lantern_lunge.lua  (sketch, [design proposal])
return {
  type        = "<ns>:minigame",          -- a record type the mod defines (ADR-0030:26 `record_types.defines`)
  id          = "<ns>:lantern_lunge",
  description = "Catch the most falling lanterns.",   -- records carry a description (ADR-0034:12)
  category    = "ffa",                     -- ffa | team2v2 | solo1v3 | coop | duel
  players     = { min = 2, max = 4 },
  duration_s  = 30,
  arena       = "<ns>:courtyard_small",   -- an arena record: which instance template to use (ADR-0024:9)
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

**Extending without editing this mod:** another mod can ship more minigames as records of the type `<ns>:minigame` declared in its own mod. The turn engine picks them up at load; the type is the published contract (ADR-0030:26 `record_types.defines`/`modifies`). Minigame packs then ship as separate mods or a modpack (ADR-0044:9). **Capability tags are not suitable for this:** a tag selects one provider ("Two providers -> user picks in the launcher, else load order", ADR-0032:9), which is the opposite of "many packs add minigames".

Because mods that define record types must also declare a placeholder for them in the schema (ADR-0048:12), the mod ships `<ns>:placeholder_minigame` so that a game does not break when a minigame pack is uninstalled.

### c.6 The minigame concepts (14 original)

Notation: **Players** = category and count; **Length** = play stage only; **Controls** per c.4. "Needs" lists the platform surfaces beyond the basics (gaps are in g.4).

**Free-for-all (4 concepts)**

1. **Lantern Lunge.** *FFA, 2-4, 30 s, M.* Paper lanterns drift down over a courtyard; run under one to catch it; each catch scores a point; golden lanterns score 3. Most points wins. Needs: spatial query for "who is under the lantern" (ADR-0114:16).
2. **Burning Bridges.** *FFA, 2-4, 45 s, M + J.* A long rope bridge over a gorge; planks flare and fall away in a growing pattern; jump gaps to stay up. Last player standing wins; ties broken by time. Needs: placed objects that disappear (G6).
3. **Tidal Tiles.** *FFA, 3-4, 45 s, M.* The floor is a 5-by-5 grid of tiles; each 5 seconds a growing set of tiles floods and drops anyone standing on it. Safe tiles flash first. Last player standing wins. Needs: zones with enter/leave events (ADR-0114:16).
4. **Echo Pillars.** *FFA, 2-4, 40 s, M.* Colour pillars light up in a sequence that grows by one each round; players must step on the pillars in the same order within 4 s. Wrong step or too slow knocks you out of that round. Most rounds survived wins. Server draws the sequence with `ctx.rng`. Needs: zones (ADR-0114:16).

**2v2 (3 concepts)**

5. **Cart Relay.** *2v2, 4, 50 s, M + A.* Each team has a mine cart on its own track. One teammate pushes (hold A near the cart), the other runs ahead and clears rocks with A. Swap roles any time by switching places. First cart to the end wins; if time runs out, the cart farther along wins. Needs: moving a placed object along a path (G6).
6. **Bonfire Hold.** *2v2, 4, 60 s, M.* A glowing circle (the bonfire) moves around an arena every 15 s. A team scores one point per second while it has more members inside the circle than the other. Most points wins. Needs: area query plus overlay for the circle (ADR-0114:16, ADR-0083:7).
7. **Lantern Heist.** *2v2, 4, 45 s, M + A.* Each team guards 3 lanterns in its corner and steals the others'. Carry a lantern (A) home. Being touched by an opponent makes you drop it. Most lanterns at the end wins. Needs: proximity queries (ADR-0114:16).

**1v3 (2 concepts)**

8. **Giant's Garden.** *1v3, 4 (or 2v1 variant), 45 s, M + J.* One player is the Gardener, enlarged, stomping across a garden; the three others are seed-sprites, small and quick, who must plant 9 seeds at marked beds. The Gardener wins by squashing (touching) 3 sprites; the sprites win by planting all seeds. Needs: size change of a player (G7).
9. **Lighthouse Keeper.** *1v3, 4, 50 s, P.* One player aims a lighthouse beam with the mouse; the three others sneak across a harbour yard between crates. A runner caught in the beam for 2 s is out. The runners win if two of them reach the dock before time runs out; otherwise the keeper wins. The beam is drawn with overlay lines (ADR-0083:7). Needs: overlay, pointer input (G5).

**Co-op (3 concepts)**

10. **Bucket Brigade.** *Co-op, 2-4, 40 s, M + A.* The players stand in a chain from a well to a cauldron and pass buckets (A to hand over, positions given by markers). Water spilled when a player is not on their marker. Tiers by litres: Bronze 20, Silver 35, Gold 50. Needs: zones (ADR-0114:16).
11. **Bridge Builders.** *Co-op, 2-4, 45 s, A.* A beat appears on screen; everyone must press A in time together; each perfect beat extends a rope bridge by one plank. Tiers by planks: 10, 20, 30. Timing is judged with server timestamps (G12).
12. **Lightning Lanterns.** *Co-op, 3-4 (2-player variant: a single watch), 50 s, M.* Lightning strikes marked spots (warned 1.5 s before); players must shield lanterns on the field by standing on them for the last 3 s. Tiers by lanterns saved: 4, 7, 10. Needs: overlay warnings (ADR-0083:7).

**Duel (2 concepts, also usable as the Duel-space game)**

13. **Quickdraw Lanterns.** *Duel, 2, 15 s, A.* A lantern lights after a random delay (1 to 5 s from `ctx.rng`); the first to press A wins that point; pressing early loses the point; best of 3. Server timestamps the presses (G12).
14. **Stone Stack.** *Duel, 2, 25 s, A + M.* Stones swing across the top of the screen; press A to drop one onto your stack; the taller steady stack at the end wins. A falling stack scores zero. Needs: placed objects with simple physics, which may need to be faked with timed animations (G6).

### c.7 What the minigames cost to build
Cost groups: movement, zones and overlays only: 1, 3, 4, 6, 12. Plus the action key (G5): 7, 10. Plus the action key and server timing (G5, G12): 11, 13. Moving or vanishing placed objects (G6): 2, 5, 14. Player scale or pointer input (G7, G5): 8, 9. The first minigame in the build order is **Echo Pillars** (free-for-all, no dependence on movement speed, so G2 does not block it); the second and third come from different categories (Bonfire Hold for the Draft, Quickdraw Lanterns for a duel) to prove that the record shape works across categories. Lantern Lunge, where speed decides, waits for the standardisation primitive (G2) or is accepted as unfair in early play-tests.

---

## d. Boards

A board is one **record** (a graph of spaces), plus one art set. **[design proposal]** The shape (all sketches):

```lua
-- records/boards/lantern_isles.lua (sketch)
return {
  type = "<ns>:board", id = "<ns>:lantern_isles",
  description = "A ring of islands with two bridges.",
  spaces = {                       -- id -> type, position in the board instance
    r0  = { kind = "gate", pos = {x=0,y=0,z=0} },
    r1  = { kind = "lantern", pos = {x=4,y=0,z=0} },
    -- ...
  },
  edges = {                        -- one-way; a space with two out-edges is a fork
    { "r0", "r1" }, { "r6", "r7" }, { "r6", "a1", fork = true }, -- ...
  },
  piers = { "r2", "r13", "r19", "r35", "a3", "b6" },   -- where lanterns can be lit
  beacon = "r28",
  instance_map = "<a map the instancing step can use>",   -- [open]: see G4
}
```

### d.1 Board 1: Lantern Isles (the starter, 48 spaces)
- **Setting:** a ring-shaped archipelago of small islands joined by rope bridges, lit by thousands of paper lanterns at dusk. Soft blue water, warm orange light.
- **Layout:** the **Rim** is a ring of 36 spaces (R0 = Harbour Gate; the order runs clockwise). Two **bridges** of 6 spaces each cut across the middle, so the board has the shape of a ring with two chords.
  - **Rope Bridge** (A1 to A6): leaves the Rim at R6 and rejoins at R24. Seven steps instead of 18, so a big shortcut. Risky: Pier, 2 Embers, 1 Wonder, 1 Duel, 1 Lantern.
  - **Treasure Bridge** (B1 to B6): leaves the Rim at R33 and rejoins at R15. Safe but poor: 3 Lanterns, 1 Cache, 1 Stall, 1 Pier.
  - Forks therefore sit at R6 and R33 (the choice is asked on arrival, b.3).
- **Composition of the Rim (36):** Harbour Gate 1, Pier 4, Beacon 1, Lantern 12, Ember 5, Wonder 5, Cache 3, Duel 2, Stall 1, Whirl 2.
- **Where the key spaces sit:** the Beacon is R28. Rim Piers at R2, R13, R19, R35; the Rope Bridge has a Pier at A3 and the Treasure Bridge at B6. Shortest walk from each Pier to the Beacon: R19 9 spaces, A3 8, B6 14, R2 15 (via the Rope Bridge), R13 15, R35 18. The Beacon cannot be bypassed on the Rim: both bridges rejoin the Rim before it (R24 and R15), and the only way forward from R24 passes R28.
- **Total with bridges (b.5 table):** 48 spaces, 6 Piers.
- **The Lamplighter** is a lantern-keeper figure who tends the lit Piers; a lit Pier shows a glow and fireflies visible from afar (overlay icon, ADR-0083:7). The Beacon is a lighthouse on the Rim.
- **The Rising Tide** (b.7) floods 4 Rim spaces per round in the last 5 rounds; the water-line preview is drawn from round 1.
- **Landmarks (visual only):** a market on the south island, a lantern tower on the east.
- **Arena theming:** minigame arenas reuse the same visual set (courtyard, gorge bridge, harbour yard).

### d.2 Board 2: Clockwork Orchard (48 spaces, a board that changes)
- **Setting:** a mechanical orchard under a glass dome; brass trees, fruit-shaped lanterns, steam and cogs.
- **Layout, counted explicitly:** **Loop A 20 + Loop B 20 + Centre 4 + Gear Walk 4 = 48** (the Centre and the Gear Walk belong to neither loop). Each loop is a one-way ring. At space 5 of each loop there is a fork: continue round the loop, or enter the **Centre**, a 4-space corridor (C1 to C4) that holds the **Beacon** (at C2). Both loops feed C1. At C4 there is a fork: the **Open exit** goes straight back onto a loop, the **Gear Walk** (G1 to G4) goes the long way round to the *other* loop.
- **The twist:** every 3 rounds the **Great Gear** turns: it swaps *which loop the Open exit leads to* (and therefore which loop the Gear Walk leads to). It is announced one round ahead with an overlay arrow. **Both exits always exist, so every space stays reachable** (the connectivity rule of d.4 holds in every gear position); only the cost of reaching a given loop changes (Open exit: 1 step; Gear Walk: 5 steps with 4 spaces to resolve). The gear is a live edit of the board state (an `edges` change in KV, g.3).
- **The end-of-game twist, Creeping Vines:** same mechanic as the Rising Tide, different geometry: in the last 5 rounds 4 loop spaces per round are overgrown (20 of the 40 loop spaces) and cost 2 steps to enter; the Centre and the Gear Walk stay clear, so the middle becomes the highway.
- **Piers:** 6 "Presses" (3 on each loop), where lanterns are lit.
- **Composition (the same totals as Lantern Isles, so the economy stays comparable, b.5):** Loop A 20 = Orchard Gate 1, Press 3, Lantern 7, Ember 2, Wonder 2, Cache 1, Duel 2, Stall 1, Whirl 1. Loop B 20 = Press 3, Lantern 7, Ember 3, Wonder 2, Cache 2, Duel 1, Stall 1, Whirl 1. Centre 4 = Beacon, Ember, Lantern, Wonder. Gear Walk 4 = Lantern, Wonder, Ember, Cache. Totals: Gate 1, Press 6, Beacon 1, Lantern 16, Ember 7, Wonder 6, Cache 4, Duel 3, Stall 2, Whirl 2 = 48 ("Whirl" is called "Gear Swap" here, flavour only).
- **Default at a fork** while carrying a lantern is the shorter path to the Beacon.
- **Look:** warm brass and green, steam, ticking audio.

### d.3 Board ideas for later (not designed)
**Frostmarket Fair** (winter fair, an ice-skating loop) and **Dreamers' Library** (floating bookshelves). Their value here is to show that boards are records: a different graph and art with the same rules.

### d.4 How big a board is allowed to be [design proposal]
- 36 to 60 spaces; at most 8 forks; exactly one Beacon; at least 3 Piers. Checked by `validate` (ADR-0051:14 says the validate step runs the same pipeline as the site).
- A board is playable only if every space can reach every other space (graph strongly connected) in **every state the board can be in** (for the Great Gear, in each gear position), and the Beacon can be reached from every Pier. `validate` rejects boards that fail this, with an error naming the space (error quality is a requirement; ADR-0051:13).

---

## e. Multiplayer and sessions

### e.1 Who plays, and where
- **1 to 4 human players** per game, 2 to 4 seats in total (questions Q2 and Q3). With bots off, at least 2 humans are needed. The platform's audience is "mostly single-player or with a few friends" (ADR-0002:13), so bots (e.6) decide whether most users can play at all. Other players on the server can watch (e.3) but not play.
- **Everyone uses their own WoW character** as their pawn, since a character is part of the world's save file (ADR-0088:7). That the mod cannot create new player models is this document's own reasoning, not an ADR statement. The companion (b.11) is a visual extra that is optional for v1.
- **One game at a time** per server by default; setting `max_concurrent_games` (default 1, bound 1 to 4). Every game needs its own instances, and instance limits are settings with defaults safe for an ordinary PC (ADR-0024:9).
- **Where the board lives:** in a private instance (ADR-0024:9). The mod does not need the players to be near each other in the open world. Version 1 uses the command `/wager host` and the lobby panel to create the game and carry the players over (gap G3); a physical "Game Table" object players walk up to is a later polish step (G6).

### e.2 Lobby and joining
Commands are written `/wager ...` for short. ADR-0082:7 registers `/modname`, so the real command is `/wayfarers-wager ...`; whether a short alias such as `/wager` is possible is **[open]**.

1. A player with the permission `<ns>.wayfarers-wager.host` runs `/wager host` (commands are manifest-declared, namespaced, with permission levels and generated help; ADR-0082:7; permissions are namespaced strings with default roles; ADR-0031:9). Default role for `host`: `player` **[design proposal]**.
2. The lobby panel shows the seats, the board, the length, bots on or off, and a Ready button per seat. Others join with `/wager join <host name>` or by clicking the entry in the panel.
3. The host can kick a seat before start (`/wager kick <name>`). The permission for it is the same as `host`.
4. When every seat presses Ready (or the host presses Start after 30 s, with fewer than all Ready), the game moves to SETUP (g.5).
5. **Late joiners** cannot take a seat after start. They may join as spectators (e.3).
6. A host with the permission `<ns>.wayfarers-wager.admin` (default role `admin`) can abort any game.

### e.3 Spectators
Any player may type `/wager watch`. Spectators receive the same overlay and UI updates as seated players for the board (not the arena). Spectating requires that the board's overlays can be sent to chosen players only. ADR-0083:7 says elements are sent via RPC but not who can be addressed: **[assumption: overlay RPC can target chosen players; added to G8]**. Watching the arena while playing minigames is **[open]** (needs per-player visibility; ADR-0114:21 names phasing as a gap to be exposed).

### e.4 Pacing, timers and AFK handling
- Roll timer 30 s; choice timer 20 s; re-roll decision 10 s (b.10). No timer is ever longer than the setting.
- **AFK:** a player who lets a timer run out three turns in a row is marked *away*. Their turns are then played automatically: auto-roll, default choices, no item use, until they send any command or click.
- **Waiting rule:** the longest a player waits between their own actions is the other seats' turns plus a minigame cycle: 3 x 25 s + 80 s = about 155 s (2.5 minutes) with 4 players if everybody acts quickly (b.10).
- Timers use the world clock (ADR-0025:14, world-clock mode; ADR-0025:16 makes it the default for a local world, but a dedicated server defaults to wall-clock mode, where a pause only locks the server); in world-clock mode a pause stops them. Pausing disconnects players anyway (ADR-0025:18) so a paused game is saved and resumes (e.5).

### e.5 Disconnects, crashes, restarts
The kernel gives the mod a `player.logout` event with a reason and `server.pre_restart` / `world.saving` events (these are listed as gap-review items 8, entering the IDL declarations; ADR-0114:24). The mod's rules **[design proposal]**:
| Situation | Behaviour |
|---|---|
| A player disconnects on the board | Seat becomes *away* at once. Turn timer runs; if it is their turn they are auto-played. They can reconnect within 5 minutes (setting) and reclaim the seat with a full state snapshot (g.3). |
| A player disconnects during a minigame | They keep the score they had; the minigame goes on; they return to the board on reconnect. |
| 5 minutes pass | The seat becomes an **autopilot** seat (same as a board-only bot, e.6). Their Brass, Stars and items stay and count. |
| Only one human is left, in a game that started with two or more humans | A seat counts as human until its 5 minutes have passed. After that the remaining human plays on against autopilot seats; with `abort_if_alone` on (default off) the game instead ends after the current round with normal scoring. |
| Server restart queued (ADR-0103:7 countdown) | If the current turn can finish before the countdown ends, it is finished and the state saved; otherwise the engine saves at the last phase boundary and resumes there. If a minigame is running, the engine saves at the last phase boundary and aborts the minigame without payout (arena instances are destroyed). On resume the game restarts at MINIGAME_ANNOUNCE for that round. |
| Server crash | The game resumes from the last phase boundary, because the engine tags every phase boundary as a "save now" event (ADR-0074:7: mods can tag such events; without a tag the interval is 30-60 s and the KV store is write-behind, ADR-0023:10). |
| Mod removed | Players in the arena or board instance are moved to their last valid position (ADR-0092:7). |

**Resume:** after a restart, the game is `PAUSED_RESUMABLE` until all human seats are online again (or 10 minutes pass; then autopilot as above) **[design proposal]**.

### e.6 Bots for empty seats (question Q2)
- **Option B (leaning):** *board-only bots*. A bot rolls; picks up a lantern whenever it can pay the fee and keep 5 Brass spare; carries it by the shortest path to the Beacon; Snatches when it stands on a carrier's space; takes the shortest path at forks; uses an item at random; and picks the nearest target for Duels and Pickpocket. In minigames a bot gets a **simulated score**: a placement drawn from a distribution weighted by a setting `bot_skill` (default 0.5; at 0.5 the expected place is the middle). Bots are labelled "(bot)". The simulated placement uses `kernel.rng` so it is reproducible (ADR-0091:7).
- The same logic runs the **autopilot** for disconnected humans.
- **Bots in team and co-op minigames [design proposal]:** while any bot is seated, the Hunt and Draft rules of c.1 do not apply (Free-for-all is drawn instead), so no human is ever teamed with a bot. In All Hands (co-op) rounds only humans play, the tier thresholds are scaled by (humans / seats), and bots receive the tier payout the humans reached (so the ledger stays balanced). Duels need two humans or a bot with a simulated result.
- A bot is not a WoW character; it has no pawn in the arena. Board pawns for bots are overlay markers (ADR-0083:7) **[design proposal]**.
- Real bot players in minigames are **not** planned. (`mc:playerbots` as an unsafe-tier plugin is an early ring-3 milestone for soak tests (ADR-0052:13); the mod does not depend on it.)

### e.7 Fairness, trust and cheating
- The client is trusted and anti-cheat is out of scope (ADR-0002:16). The server still decides every roll, payment and result, so a modified client cannot simply write itself Brass; **what a client controls is its own movement** in arenas. Reaction minigames use server timestamps (G12).
- **Character differences:** a level-80 player has more speed and health than a level-10 one. In arenas everyone should have the same speed, no gear effects and no combat. That is gap G2 (open question Q18, `docs/open-questions.md:24`).
- **Rule of least surprise:** all rules a player can see on the card (b) are the ones the server applies; the log shows the seed and every roll (ADR-0034:10, ADR-0091:7).

---

## f. Presentation

### f.1 Camera
- **Board camera:** a raised three-quarter "table view" that frames the active player and the next 10 spaces, looking down at about 55 degrees. It eases between turns and cuts to a wide shot for a delivery at the Beacon and the finale.
- **Arena camera:** the player's normal third-person camera, except in minigames that need a top-down view (Tidal Tiles, Echo Pillars, Bonfire Hold), which switch to a fixed overhead camera.
- The platform names "camera" as a ring-2 client surface (ADR-0020:12) but gives no function list: gap G10.

### f.2 UI (all in the client UI framework, ADR-0020:12; the framework is decided after step 1, `docs/open-questions.md:7`)
```
+--------------------------------------------------------------------------+
| P1 [portrait] 12 Brass  2 Star | P2 ... | P3 ... | P4 ...    Round 7/15   |
+--------------------------------------------------------------------------+
|                                                                          |
|                       (the board in the world view)                      |
|                                                                          |
|   [Item 1] [Item 2] [Item 3]                         [   ROLL  (d8)   ]  |
|   Space info: "Pier (lit) - lantern, fee 14 Brass"    Timer: 24 s        |
+--------------------------------------------------------------------------+
```
- **Player cards** (top): portrait, Brass, Stars, held items (small icons), an "away" badge.
- **Roll button** (bottom right) with keyboard shortcut Space and the command `/wager roll` as a fallback (ADR-0082:7 says power users get commands).
- **Choice dialogs:** fork arrows drawn as overlay (ADR-0083:7), lantern pick-up dialog (fee, Yes/No), Snatch dialog, shop list, target picker.
- **Announcement cards:** minigame title, goal and controls; result table; Honours decided.
- **Colour-blind safety:** every colour is paired with a symbol (a carrier has a lantern icon beside their name; flooded spaces carry a wave icon, overgrown ones a leaf icon).
- **Text:** English only (ADR-0030:30).
- Whether mods can create *new* UI widgets or only use the framework's ones is **[open]** (ADR-0020:13 puts new widget types into ring 3; `docs/open-questions.md:7` Q1 is about UI ownership between mods).

### f.3 The board in the world
- The board is drawn with **overlays**: lines (paths), icons on each space, text labels, and an area highlight on the active player's reachable spaces (ADR-0083:7: "lines, areas, text, icons at positions"). A per-mod client toggle lets a player mute the overlays (ADR-0083:7 guardrail).
- Props (trees, lighthouse, lanterns) are **models** shipped as glTF/GLB (ADR-0004:17). How placed model objects are created in an instance is gap G6.
- **First version without models:** overlays and coloured ground markers only, so the board is playable before any model pipeline exists (section i, step 2).

### f.4 Audio (ADR-0084:7: OGG files, UI sounds, positional audio, a music channel with ducking, triggered by the server via RPC; "v1 may be naive")
- Music: one looped board track per board, one minigame loop per category, one result jingle. All original; no melody may be recognisable from another work (ADR-0061:7 applies the originality rule to AI-generated assets too).
- Sounds (about 25): die rattle and land, hop step (varies in pitch with the Brass total), Lantern chime, Ember hiss, Wonder shimmer, Star fanfare (our own motif: three rising bell notes), countdown ticks, minigame start/stop, UI clicks.
- Mix: music ducks under the Lamplighter's lines and the countdown.

### f.5 Assets list and rules
| Group | Count (v1) | Format (ADR-0004:17, 21 whitelist) |
|---|---|---|
| Board prop models (2 boards) | about 30 each | glTF/GLB |
| Space icons and UI | about 40 | PNG |
| Star lantern, Lamplighter, Beacon lighthouse | 2 | glTF/GLB |
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
| Saved game state | Per-mod KV in world/account/character scope, write-through | ADR-0020:11; ADR-0023:10 | Decided |
| Safe saves after a reload | Kernel-enforced restore-before-save barrier | ADR-0115:17 | Decided; the mod must run its restore phase on load |
| Save cadence and "save now" | Aggressive in world-clock mode; mods may tag events | ADR-0074:7 | Decided |
| Private board and arenas | `world.instance(map, { owner, persistent, template })` | ADR-0024:9 | Decided; open zones come later (ADR-0024:11) |
| Dice, draws, bot scores | `kernel.rng` per-mod and per-instance streams, seed logged | ADR-0091:7 | Decided |
| Commands `/wager ...` | Manifest-declared commands, namespaced | ADR-0082:7 | Decided |
| Who may host/abort | Namespaced permissions with default roles | ADR-0031:9 | Decided |
| Graceful denial | Denials are return values | ADR-0028:15 | Decided |
| Every number tunable | Schema-driven config, scope client/server | ADR-0029:9, :13 | Decided; in-game UI after step 1 (ADR-0029:12) |
| Client/server messages | RPC channels, versioned messages, server-side validation | ADR-0020:11; ADR-0066:7 | Decided (mod message typing: G13) |
| Board drawing | World-anchored overlays: lines, areas, text, icons | ADR-0083:7 | Decided |
| Sound | Mod audio API (OGG, music channel, server-triggered) | ADR-0084:7 | Decided; v1 may be naive |
| HUD, dialogs | Client UI framework | ADR-0020:12; `docs/open-questions.md:7` (framework does not exist yet, decided after step 1); ADR-0029:12 (settings generator renders in it after step 1) | Named; contents open (G9) |
| Camera, input | Client camera and input surfaces | ADR-0020:12; ADR-0028:9 (`client.input_hook` permission) | Named; contents open (G5, G10) |
| Win rewards | Achievements: records + events, kernel tracks and shows | ADR-0096:9, :10 | Decided |
| Other mods add minigames | Records of this mod's own record type; `extends` wrapper if code must be wrapped | ADR-0030:26; ADR-0021:9 | Decided (capability tags are unsuitable, c.5) |
| Pack as modpack | Modpack type | ADR-0044:9 | Decided |
| Group handling | Group create/invite/move/disband (gap review item 4) | ADR-0114:20 | Declared for the IDL, not defined |
| Zones, proximity | `world.query(shape)` and `zone.on_enter/on_leave` (item 2) | ADR-0114:16 | Declared for the IDL, not defined |
| Disconnects, restarts | `player.logout` with reason, `server.pre_restart`, `world.saving` (item 8) | ADR-0114:24 | Declared for the IDL, not defined |
| Position safety | Safe reposition when an instance vanishes | ADR-0092:7 | Decided |
| Timers | World clock `now()`; in world-clock mode (default for a local world) pause freezes time | ADR-0025:14, :16, :18 | Decided |
| Compute on observation | Store deadlines, compute at read | ADR-0080:7 | Principle |
| Observability | Automatic attributed logging; counters measure outcomes | ADR-0034:10, :12; ADR-0115:8-14 | Decided |
| Failure containment | A failing mod keeps running (:7); admin throttle per player/mod (:9) | ADR-0090:7, :9 | Decided |
| Distribution | Registry first; hash and signature verified | ADR-0073:7 | Decided |
| Backups | Mod-prefixed tables are part of world backups | ADR-0045:9 | Decided |
| Testing | `modcraft test` with a simulated player (cannot walk) | ADR-0052:10 | Decided |
| No paid content | Whole work distributed; funding links only | ADR-0104:7 | Decided; the mod is free |

The mod needs **no outside-the-game permission** (ADR-0028:9: `fs.*`, `net.outbound`, `process.spawn`, `client.input_hook` etc.), except possibly `client.input_hook` if the platform's input surface (G5) requires it. A mod installed via a server profile has those permissions off by default (ADR-0028:13), so the design avoids needing them.

### g.3 Data model sketch (KV store) — all keys are a **[design proposal]**
KV acts like a table (`mod.state.games[id] = {...}` is saved by write-through, ADR-0023:10). Scope is chosen per key (ADR-0020:11).

| Key (scope) | Fields | Notes |
|---|---|---|
| `games/<id>` (world) | `id`, `board`, `seed`, `rounds_total`, `round`, `phase` (state name, g.5), `active_seat`, `lit_count`, `tide_stage`, `gear_state` (Clockwork Orchard), `last_category` (for the Hunt rule, c.1), `created_at`, `rules_version` | One row per game. `seed` makes the game replayable (ADR-0091:7). |
| `games/<id>/lanterns` (world) | List of `{id, state = lit \| carried \| dropped \| waiting, pier, space, carrier_seat, picked_round, burns_out_round, relights_round}` | Exactly `lit_count` lanterns exist at any time (b.4); some may be `waiting`. |
| `games/<id>/seats/<n>` (world) | `character_guid`, `name`, `is_bot`, `companion`, `space` (space id), `brass`, `stars`, `items[1..4]`, `lantern` (id or nil), `connected`, `away`, `autopilot`, `stats = {earned, lost, moved, embers, duels, items_used, minigame_wins, lanterns_delivered, trip_catches, coop_score}` | `lanterns_delivered` and `trip_catches` feed the two Honours (b.9). |
| `games/<id>/edges` (world) | The live edge list | Needed only for boards with a Gear Turn (d.2). |
| `games/<id>/traps` (world) | `{space, owner}` | Tripwires. |
| `games/<id>/ledger` (world) | Append-only list of `{n, seat, kind, delta, before, after, reason, round}` | Every Brass and Star change. Source for the conservation self-check (g.7). |
| `games/<id>/log` (world, ring buffer) | Events: dice, moves, choices, minigame results | Mirror of what clients received. |
| `profiles/<guid>` (character) | `games`, `wins`, `stars_total`, `best_minigame_scores`, `titles` | Lifetime stats; they also feed achievements (ADR-0096:10). |
| `lobby/<host guid>` (world) | `seats`, `board`, `rounds`, `bots` | Dies when the game starts or after 10 minutes. |

**Record types the mod defines** (each with a description and a placeholder, ADR-0034:12, ADR-0048:12): `<ns>:board`, `<ns>:space_kind`, `<ns>:item`, `<ns>:event`, `<ns>:honour`, `<ns>:companion`, `<ns>:minigame`, `<ns>:arena`.

**Persistence discipline:** the engine writes the new state to KV **at every phase boundary** and tags each as a "save now" event (ADR-0074:7: mods can tag such events). The KV store is memory-cached with write-behind (ADR-0023:10), so without the tag the last durable state could be up to 30-60 s old (ADR-0074:7); with it, a crash resumes at the last phase boundary. The mod must also run its own restore phase on load before any write, because the kernel refuses writes until it has (ADR-0115:17). Game state is "in KV or gone" (ADR-0023:10). Read-after-write is never relied on across an asynchronous call (ADR-0115:38 says the persistence API makes it impossible or explicit).

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
| G8 | **Per-player visibility and targeted overlays** (spectators; each team sees its own markers; overlay RPC addressed to chosen players) | Phasing is gap item 5 (ADR-0114:21); ADR-0083:7 says overlays are sent via RPC but not to whom | Spectators and team-private info | All see everything |
| G9 | **Client UI widgets:** panels, buttons, icon rows, tooltips, countdowns | UI framework is named (ADR-0020:12) and is decided after step 1 (`docs/open-questions.md:7`; ADR-0029:12 covers only the settings renderer); Q1 (`docs/open-questions.md:7`) | The HUD | Overlay text and chat output |
| G10 | **Camera control from a mod:** set position, angle, ease, follow | "camera" named (ADR-0020:12) | The table view | Normal camera in v1 |
| G11 | **Client-visible countdowns tied to the server clock** | `now()` is the adjusted clock in world-clock mode (ADR-0025:14); nothing about sending server time to clients | Timers that look right to all clients | Send a duration in each RPC and count down locally; the server decides expiry |
| G12 | **Latency fairness for reaction games** | Nothing; the client is trusted (ADR-0002:16) | Quickdraw, Bridge Builders | Server timestamps on receipt; accept ping differences; use only in games where a few hundred ms do not decide the result, or compensate by measuring each client's round trip in the mod **[open]** |
| G13 | **Typed mod RPC messages:** how a mod declares message formats | RPC wire format is IDL-generated for the platform's packets (ADR-0066:7); mod declarations include `rpc` (ADR-0030:26) | The protocol in g.6 | Assume mod-declared channels carry typed tables; mark as an assumption until the surface is defined |
| G14 | **Two clients on one PC for testing** | Reference machine specs not yet recorded (`docs/open-questions.md:27`, Q21; ADR-0081:7) | Testing multiplayer alone | Bots (e.6) plus a second client on the same PC when the machine allows |
| G15 | **Headless test of movement-based minigames** | The simulated player cannot walk (ADR-0052:10) | Minigames are manual-test only | Engine and board logic are fully testable (g.7); minigames get scripted "scenario" tests that move players by teleport |

### g.5 Turn state machine
All transitions are decided by the server's engine. Each state names its **timer**, **what is saved to KV** and **who may act**. The minigame stages are one reusable **sub-machine** used by both the round's minigame and a Duel space.

```
MAIN TURN MACHINE
LOBBY --start--> SETUP --> ROUND_START --> TURN_BEGIN(seat) --> ITEM_WINDOW --> ROLL --> (REROLL_CHOICE)
                              ^                                                              |
                              |                                                              v
   TURN_END <-- RESOLVE_SPACE <-- LAND <-- MOVE (per step) ----+-- PICKUP_OFFER (lit Pier / dropped lantern)
      |            |  (SHOP, DUEL -> MINIGAME, EVENT, WHIRL,    +-- DELIVER (Beacon, carrying)
      |            |   EMBER drop, SNATCH_OFFER)                +-- TRIP_STOP (Tripwire: stop, pay, drop)
      |            +-- EVENT_MOVE (Headwind/Tailwind) -> MOVE   +-- FORK_CHOICE
      |
      +-- more seats? --> TURN_BEGIN(next seat)
      +-- no --> MINIGAME_SELECT --> [MINIGAME sub-machine] --> ROUND_END
                                                                   |
    (a Duel space starts the same sub-machine from RESOLVE_SPACE and returns to TURN_END, not to ROUND_END)
                          rounds left: --> ROUND_START   no: --> FINAL_HONOURS --> RESULTS --> ENDED

MINIGAME SUB-MACHINE (round minigame: all seats; Duel space: the two duellists)
ANNOUNCE --> TRANSPORT_OUT --> COUNTDOWN --> PLAY --> RESOLVE --> PAYOUT --> RETURN
   (script error or invalid result in PLAY/RESOLVE: abandon, pay the 3rd-place amount, log, continue at PAYOUT)

ANY STATE --(pre_restart / all humans gone)--> PAUSED_RESUMABLE --(resume)--> the saved phase
ANY STATE --(admin abort / fatal error)-----> ABORTED
```

| State | Who acts | Timer | Entered when | Saved to KV |
|---|---|---|---|---|
| LOBBY | Host and players | 10 min idle | `/wager host` | `lobby/<host>` |
| SETUP | Engine | none | All ready | `games/<id>`, seats; seed; seat order; lit Piers drawn |
| ROUND_START | Engine | none | New round | `round`; **burn out** carried or dropped lanterns whose `burns_out_round` has come (they become `waiting`); **relight** `waiting` lanterns due (each on a random unlit Pier other than its previous one); **advance the tide** (Rising Tide or Creeping Vines, b.7, d.2); **Gear Turn** on its round (d.2); choose the round's category (c.1) |
| TURN_BEGIN | Engine | none | Next seat | `active_seat` |
| ITEM_WINDOW | Active seat | 20 s | After begin | item use, ledger |
| ROLL | Active seat | 30 s | After items | roll value, seed position |
| REROLL_CHOICE | Active seat | 10 s | After a roll, only if Rain Check was used or the Sable passive is available | choice |
| MOVE | Engine | about 0.4 s per step (2 steps for a flooded space) | After roll | `space` per step |
| FORK_CHOICE | Active seat | 20 s (default: main path; shorter path to the Beacon when carrying) | Fork reached | choice |
| PICKUP_OFFER | Active seat | 20 s | Passing or landing on a lit Pier, or passing or landing on a dropped lantern, with no lantern held (and enough Brass for the fee at a Pier) | Brass (fee), lantern state |
| DELIVER | Engine | none | Walking onto or through the Beacon with a lantern | Stars, lantern relight, ledger |
| TRIP_STOP | Engine | none | Passing or landing on a Tripwire | Brass, lantern drop, possible robbery, trap removed |
| LAND | Engine | none | Steps used | `space` |
| RESOLVE_SPACE | Engine and seat | 20 s per choice | After landing: **Snatch first** (SNATCH_OFFER, if the space holds a carrier), then the space effect | Brass, items; sub-flows: SHOP, DUEL (starts the MINIGAME sub-machine), EVENT, WHIRL, EMBER (lantern dropped) |
| SNATCH_OFFER | Active seat | 20 s | Landing on a carrier's space | both rolls, lantern owner |
| EVENT_MOVE | Engine | about 0.4 s per step | Headwind or Tailwind drawn | `space`; Tailwind then runs LAND and RESOLVE_SPACE again |
| TURN_END | Engine | none | Space resolved | seat stats |
| MINIGAME_SELECT | Engine | none | All seats done | `phase`, minigame id |
| ANNOUNCE | Engine | 5 s | After select | minigame id |
| TRANSPORT_OUT | Engine | up to 10 s | After announce | stored origin positions |
| COUNTDOWN | Engine | 3 s | All in arena | none |
| PLAY | Minigame script | 20 to 60 s | After countdown | nothing (transient). **Resume goes back to ANNOUNCE** for the same minigame |
| RESOLVE | Engine | none | Time or goal | validated result |
| PAYOUT | Engine | none | After resolve | Brass, ledger, wins |
| RETURN | Engine | up to 10 s | After payout | positions restored |
| ROUND_END | Engine | none | All returned | `round + 1`, `last_category` |
| FINAL_HONOURS | Engine | 8 s | Last round ended | Stars |
| RESULTS | Players | 60 s | After honours | profiles, achievements |
| ENDED | none | none | After results | game archived |
| PAUSED_RESUMABLE | none | 10 min | Pre-restart or humans gone | everything |
| ABORTED | none | none | Abort or fatal | log kept |

**Invariants checked on every transition (and counted if they fail; ADR-0115:8-12):** Brass >= 0; Stars >= 0; total Stars equals lanterns delivered plus Honour Stars; exactly `lit_count` lanterns exist, each in exactly one of lit / carried / dropped / waiting (lit + carried + dropped may be **below** `lit_count`, by the number of `waiting` lanterns, from a delivery or burn-out until the next ROUND_START relights them; that is the only time it may be below); each player carries at most one lantern; every seat's `space` exists in the board graph; one item used per turn; at most one Tripwire per owner; the board is still strongly connected in its current gear and flood state.

### g.6 Server and client responsibilities, and the message protocol

**The server (authoritative)** owns: all state, the die and every random draw, movement along the graph, payments, item and event effects, timers, minigame selection and results, bots, saves. **The client** owns: input, drawing (overlays, models, UI), camera, audio, local countdown animation. The client never decides an outcome.

**Version-1 protocol [design proposal; message typing is gap G13]** — one RPC channel `wager`, messages carry `game_id` and a sequence number:
| Direction | Message | Content |
|---|---|---|
| client to server | `intent.roll` | seat |
| client to server | `intent.choose` | `decision_id`, option (fork path, pick-up yes/no, snatch yes/no, shop item, target) |
| client to server | `intent.use_item` | slot, parameters |
| client to server | `intent.ready` | lobby ready toggle |
| client to server | `intent.action` | minigame input: kind, client sequence number |
| server to client | `snapshot` | the whole visible game state; sent on join, on reconnect, after any gap in sequence numbers |
| server to client | `event` | `n`, type: `dice_rolled`, `pawn_moved`, `brass_changed(seat, before, after, reason)`, `lantern_changed(id, state, seat)`, `star_earned(seat)`, `decision_request(id, kind, options, duration)`, `minigame_announce`, `minigame_result`, `game_over` ... |
| server to client | `toast` | text and a sound id |

- Every `decision_request` has an id; a reply with a stale id is rejected **and counted with its reason** ("late: timer already expired", "duplicate", "wrong seat"), as ADR-0115:11 requires for silent early returns.
- The server validates every intent: sender is the seat's owner, state allows it, option is in the offered set (a server-side validation hook exists, ADR-0020:11).
- Rate: roughly 1 to 3 messages per second per client on the board, up to 20 per second during minigames; an admin can throttle a player's channel if needed (ADR-0090:9).
- The server may run with a **silent or garbage client** without crashing (ADR-0028:15: the site's smoke test runs mods with all permissions denied and rejects crashes; server mods tolerate a silent client).

### g.7 Observability and testing
**Counters (outcome, not intent; ADR-0115:8-14), per game and per session:** dice rolled (value histogram, with seed, input shown), Brass delta per cause with before/after read back from the ledger, lantern events (picked up with fee paid, dropped with cause, snatched with both rolls, delivered with turns carried, burned out) and Star totals reconciled against deliveries, early returns by reason (intent rejected, timer expired, item had no target in range), minigame durations, minigame errors, reconnects, autopilot turns. **Bookkeeping next to reality** (ADR-0115:13): the ledger total is compared with the seats' summed Brass each round; any difference is an error line naming the game and the last 5 ledger rows.
**Self-check command:** `/wager doctor` runs the invariants (g.5), prints a pass/fail list, and is available in the console's command palette (ADR-0112:13: the players tab binds buttons to registered commands).

**Tests (`modcraft test`, ADR-0052:10):** the simulated client can send and receive RPC but cannot walk, so:
1. *Engine tests* (no game at all): 1,000 seeded games per board with bot seats; check invariants, game length, Star counts, and that a winner exists (g.5 invariants). The simulator also outputs the economy statistics in section i, step 4.
2. *RPC tests:* a simulated client plays a scripted game over the `wager` channel, including stale, duplicate and garbage messages.
3. *Disconnect tests:* simulate `player.logout`, `pre_restart`, and resume from KV.
4. *Minigame scenario tests:* each minigame script is driven by a scripted `ctx` (positions set by the test, inputs injected) and must return a valid result; real movement is manual (G15).
5. *Permissions-denied smoke test* runs on the site automatically (ADR-0028:15).

---

## h. What building this mod first exercises in the platform

This section is factual. It lists which platform surfaces this mod uses early, and which surfaces the roguelike was planned to use that this mod does **not** use. It rewords no ADR. For the roguelike, the sources are the ADR sentences that name it.

### h.1 Surfaces this mod exercises (all from g.2 and g.4)
| Area | Surfaces exercised | Where defined |
|---|---|---|
| Mod format | Custom record types with placeholders; schemas; manifest `declares`; modpack | ADR-0008:13; ADR-0030:26; ADR-0048:12; ADR-0044:9 |
| Persistence | KV with write-through, restore-before-save barrier, save cadence, backups of mod tables | ADR-0023:10; ADR-0115:17; ADR-0074:7; ADR-0045:9 |
| Multiplayer | RPC with several clients at once; server-side validation; reconnect and snapshot; throttle | ADR-0020:11; ADR-0066:7; ADR-0090:9 |
| Instancing | Create, populate, destroy instances, many times per game; limits as settings | ADR-0024:9, :11 |
| Groups and movement | Group handling, group teleport with origin restore, scripted pawn movement | ADR-0114:20; `docs/open-questions.md:23`; G1, G3 |
| Spatial | Zones with enter/leave, proximity queries | ADR-0114:16 |
| Client | Overlays (heavily), UI framework, audio, camera, input | ADR-0083:7; ADR-0020:12; ADR-0084:7 |
| Services | `kernel.rng` with seeds, commands, permissions, config schema, achievements | ADR-0091:7; ADR-0082:7; ADR-0031:9; ADR-0029:9; ADR-0096:9 |
| Lifecycle | Logout reasons, pre-restart, saving events; pause and clock | ADR-0114:24; ADR-0025:14, :18 |
| Observability | Outcome counters, ledger reconciliation, self-check command | ADR-0115:8-14; ADR-0034:10 |
| Tooling | `validate`, `test`, docs, a soak run with the mod's own board bots (not the platform's playerbots soak, ADR-0052:12, which this mod does not depend on) | ADR-0051:14; ADR-0052:10; ADR-0113:13 |
| Extension | Another mod adding minigames without touching this one | ADR-0030:26; ADR-0021:9 |

### h.2 Step-1 shape, and what the mod does with it
ADR-0050:17 describes the shape of the first real feature: "a new record type, a server hook, RPC, a client panel, persistence, observability". The party mod's first real feature, "press Roll and the server moves your token on a test ring" (section i, step 1), has that shape. It is described here as a candidate feature of this mod; it is not a statement about the platform's build order.

### h.3 What the roguelike was to exercise that this mod does not
These are stated plainly. The party mod does **not** exercise, and so does not prove early:
- **Combat and damage hooks**, including the Lua-performance test the roguelike's damage hooks were to provide (ADR-0015:17).
- **Spell and aura scripting**, including `replace` on spell scripts (ADR-0022:18) and the wrapper chain around C++ scripts (ADR-0022:12).
- **Character lifecycle** (create/reset/rename/delete; ADR-0114:17, which names the roguelike's core loop as its blocker).
- **Loot, spawns and creature AI** as game content, and the spawn-state surface (ADR-0114:34).
- **Field-level merge under conflict** between two content mods (ADR-0009:15's example): the party mod's records are its own types, so it creates few merge conflicts. Merge is exercised only by tests.
- **Player progression** through levels, stats and equipment.
- **Daily seeds and shareable runs** as a feature (ADR-0091:7): `kernel.rng` is used, but only for dice and draws.
- **A very large content mod with many interacting systems**, which is the context in which the reference-mod rule (ADR-0051:16) was written.

### h.3a The arcade driver mod
The ADRs name three driver mods: roguelike, housing and arcade (ADR-0114:7). The arcade mod already pulls teams (ADR-0114:20), a clean match abort on restart (ADR-0114:24), zones and countdowns (ADR-0083:7), and open questions Q17 (group teleport) and Q18 (player-state snapshot) are scheduled "with the arcade/housing driver mods" and "when a minigame/arena mod demands it" (`docs/open-questions.md:23-24`). The party mod's minigames need the same surfaces (G2, G3, G8). Whether the party mod's minigame layer and the arcade mod share code, or are the same mod, is **[open]**; this document assumes they are separate mods that both build on the platform's surfaces.

### h.4 What the party mod proves that the roguelike would prove less of
Multi-client play from the first week; instancing as a daily tool, not an exotic one; the overlay and UI client surfaces under real use; mod-to-mod extension (minigame packs) in a record-type-defining mod; the restore barrier and resume after restart under a game state that has several actors. None of this changes an ADR.

---

## i. Build order: walking skeleton

The method is the platform's own: a thin slice through every layer first, then depth (ADR-0050:11-15). Each step has a task file, ends with a demonstration, and updates docs in the same branch. **Prerequisite (not part of this mod):** the platform's step 0 smoke test (ADR-0050:15) and a working mod loader with server-side Lua. This mod is pure Lua and records, so it does not wait for the native plugin loader of ADR-0050:16. Estimates are deliberately absent: hobby estimates miss by a factor of two (ADR-0050:21).

| Step | Build | Proof (must be shown, not claimed) | Gaps touched |
|---|---|---|---|
| 1 | **"Roll."** A mod with one record type, `/wager roll`, an RPC pair, a small client panel with a Roll button and the result, KV persistence of position on a 12-space test ring, and a histogram counter | Restart the server: position is kept. The log shows the seed and each roll. 1,000 simulated rolls are in 1 to 8 with a flat histogram | G9 (minimal) |
| 2 | **Board as data.** `<ns>:board` record (Lantern Isles, 48 spaces) with graph checks in `validate`; overlay drawing of spaces and lines; an overlay marker as the pawn, moving one hop per step | `validate` rejects a board with an unreachable space and names it. The client shows 48 icons and the path. | G1 (teleport fallback) |
| 3 | **Headless engine.** The state machine of g.5 without any client: spaces, Brass, lantern pick-up, carry, drop, Snatch and delivery, Stars, the Rising Tide, items stubbed, bot seats, ledger, invariants | 1,000 seeded 4-bot games finish; all invariants hold; the game is replayable from its seed | none |
| 4 | **Calibration.** Run the simulator; tune the numbers in section b | A report against the targets of b.12 (median unspent Brass 10 to 30; under 10% of lit-Pier visits failing on the fee; about 7 deliveries per game) plus win rate by seat order (first-seat advantage not above 3 points over a fair split) and game length in rounds. Numbers written back into section b | none |
| 5 | **One human plus bots.** `/wager host`, snapshot and events over RPC, timers, away and autopilot, resume after restart | Kill the server mid-game; it resumes at the same phase with the same state. The counters show the early returns with reasons | G9, G11 |
| 6 | **2 to 4 humans.** Lobby, join and ready, spectators, disconnect rules | Two clients play a full game; disconnect, reconnect and AFK each shown. Ledger reconciles | G14, G8 |
| 7 | **First minigame, end to end:** Echo Pillars (record, script, arena instance, transport, payout, return); a skill-neutral free-for-all, so G2 does not block it | Ledger shows the payout diff. Pull the plug mid-minigame: on restart, players are back on valid positions (ADR-0092:7) | G2, G3, G4, G5 |
| 8 | **More minigames across categories:** Bonfire Hold (2v2), Quickdraw Lanterns (duel), Bucket Brigade (co-op), Lighthouse Keeper (1v3). **A separate minigame-pack mod** with one minigame | The record shape works for all five categories; the pack mod loads and its minigame is drawn in a game, with the base mod unchanged | G5, G12, G13 |
| 9 | **Items, events, Honours, Companions, Duel, Whirl, Stall, the Rising Tide** | Each effect has an engine test and appears in the ledger | none |
| 10 | **Board 2** with the Gear Turn | `validate` passes; a headless game on Clockwork Orchard finishes | none |
| 11 | **Polish:** audio, camera, UI widgets as available, achievements, config panels, console admin panel | Settings change values live (ADR-0029:11); achievement toast shown | G6, G9, G10 |
| 12 | **Soak and docs:** a 6-hour soak run in which the mod's own board bots play games back to back on a real server (this is not the playerbots soak of ADR-0052:12); the guide "Your first party game mod" built from this mod | Soak output with leak flags clean; code blocks in the guide run in CI (ADR-0113:13) | none |

Steps 1 to 4 need **no** client features beyond a button, so they can start as soon as the loader and server-side Lua exist. Steps 7 and later need instancing and the gaps in g.4.

---

## j. Risks and open questions

### j.1 Questions for Ludwig (the same five as in the ADR proposal, `docs/tasks/098-proposed-adr.md`), and overnight rulings awaiting him
| # | Question | Effect on this document |
|---|---|---|
| Q1 | Does the party mod become the reference/first mod that drives the platform build order (A), stay a plain mod (B), or share that role with the roguelike (C)? | None on the design. Only decides whether ADR-0123 exists. |
| Q2 | Bots for empty seats: none (A), board-only bots (B, leaning), full bots (C)? | Section e.6 and build step 5 |
| Q3 | Player count: 2 to 4 (A, leaning), up to 6 (B), up to 8 (C)? | Sections b.1, c.1, c.2, b.4 (lit-lantern count) |
| Q4 | Default length: 10 (A), 15 (B, leaning), 20 (C) rounds? | Sections a, b.1, b.10 |
| Q5 | Relation to the planned arcade driver mod (ADR-0114:7): separate mods (A, leaning), the party mod's minigame layer becomes the arcade mod (B), decide later (C)? | Sections h.3a and c.5 |

**Rulings made overnight by the manager (not by Ludwig); he can change any of them in the morning.** They were made so that the rule set is our own and does not reproduce a published game's signature rules.
| # | Ruling | If Ludwig overturns it |
|---|---|---|
| (a) | Minigame teams come from the standings (leader vs the rest, or a draft by the last-place player, or free-for-all), not from space colours (c.1). | Replace c.1; the minigame records are unaffected. |
| (b) | Stars are earned by carrying a lantern from a lit Pier to the Beacon, with a wick fee, ambushes and burn-out (b.4), instead of buying a Star at a moving space. | Replace b.4 and the lantern parts of b.5, b.6, g.3, g.5; the rest stands. |
| (c) | The last five rounds bring a Rising Tide (Creeping Vines on the Orchard) instead of doubled payouts (b.7, d.2). | Replace b.7 and d.2's twist. |
| (d) | Numbers: 12 start Brass, Lantern +4, Ember -6, wick fee 9 + 5 per Star, payouts 6/4/2/0 and so on (b.12 shows the arithmetic). | Re-run the b.12 arithmetic and the simulator. |
| (e) | Two Honours only, specific to this game: Lantern Courier and Snare Master (b.9). | Edit b.9. |

### j.2 Risks
| # | Risk | Mitigation |
|---|---|---|
| R1 | **The mod depends on platform surfaces that do not exist yet** (g.4). Instancing is limited to dungeon shells at first (ADR-0024:11). | Steps 1 to 6 need almost none of them. Step 7 is where the platform must have delivered G2-G4; if not, that step waits (the manager decides). |
| R2 | **Movement-based minigames cannot be tested automatically** (ADR-0052:10). | Engine tests cover rules; minigames get scenario tests plus manual play-tests. |
| R3 | **Fun is unproven** until people play, and the lantern rules (b.4) are new and untested. | Steps 3-4 (simulation) catch broken economies; step 6 is the first real play-test. Rule numbers are expected to change. |
| R4 | **Rules, look and feel too close to the genre leader.** | The first draft was; the overnight rulings (j.1) replaced the signature rules. Originality checklist (j.4) at every rules, art and naming step; the Star is an eight-point lantern, not a five-point golden star; no characters or items resembling known ones. |
| R5 | **AI-generated art or sound might echo existing work.** | ADR-0061:7 forbids re-creations; human review at each asset batch; optional `ai_assisted` label (ADR-0030:26). |
| R6 | **Unequal characters make arenas unfair** (G2). | Prefer skill-neutral minigames first; request the standardisation primitive. |
| R7 | **Latency decides reaction games** (G12). | Few reaction games; server timestamps; compensate if needed. |
| R8 | **Four clients plus server on one PC** may exceed the reference machine (ADR-0081:7, specs unrecorded, `docs/open-questions.md:27`). | Instance limits as settings (ADR-0024:9); bots for solo tests; measure at step 6. |
| R9 | **Scope creep:** companions, a second board, 14 minigames, and so on. | Build order i: steps 1-8 give a complete small game; 9-12 add breadth. |
| R10 | **A mod that carries 14 minigames is large** for a first mod. | Minigames are separate records; ship 5 at first (step 8) and the rest as updates or packs (ADR-0044:9). |

### j.3 Open points (each marked [open] above)
1. Mod namespace and the final name of the mod (title page).
2. Which AzerothCore shell maps are suitable for the board and arenas (G4): a survey item.
3. Whether the party mod's minigame layer shares code with the arcade driver mod (h.3a).
4. Scaled variants of 1v3 minigames for 3 players (c.1).
5. A star-stealing event (b.4), spectating arenas (e.3), and reaction-time compensation (G12).
6. Whether mods may define new client UI widgets (f.2).

### j.4 Originality checklist (to run at every art, audio and naming step)
- [ ] No name, character, item, place or phrase from Nintendo's party games or any other published game.
- [ ] No Blizzard asset, name or motif (ADR-0004:17, ADR-0061:7).
- [ ] The Star silhouette, the dice, the spaces and their effects are our own (b.4, b.5).
- [ ] No rule combination that reproduces a published game's signature rules (all of: star price and relocation, space-colour team selection, final-turns doubling, a random pool of end-of-game bonus stars). The design keeps two game-specific bonus Stars (b.9); that is allowed because the rule forbids the combination.
- [ ] Music and sound effects are not recognisable as a known melody.
- [ ] Every asset has a recorded source and a licence that fits the mod's licence field (ADR-0061:7).
- [ ] "Mario Party" appears only as the genre reference, quoting Ludwig (section 0 and the ADR proposal Context).
