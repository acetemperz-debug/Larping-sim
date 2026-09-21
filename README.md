# LARPing Simulator

A satirical Roblox tycoon about spending enormous amounts of real money to appear
to have enormous amounts of money.

You start broke in your parents' spare room with £50, a folding desk and a
motivational poster. You post content pretending to be rich. The content earns
followers. The followers buy your course. The course money pays for a
Lamborghini rental that expires in twelve minutes. Repeat, but more expensive.

**You never build a real business.** Almost every pound you earn goes straight
back out on rentals that expire, and the game is balanced so that you are
permanently, ridiculously broke. That is the joke.

---

## Running it

This is a [Rojo](https://rojo.space) project — Luau source you sync into Roblox
Studio. There is no `.rbxl` in the repo; the entire map is generated at runtime,
so a fresh sync gives you a playable game with nothing to model by hand.

### Windows

Double-click **`START-HERE.cmd`**.

It finds Rojo, downloads it into this folder if you don't have it, installs the
Roblox Studio plugin, and starts the sync server. Then in Studio: open a new
baseplate, **Plugins → Rojo → Connect**, allow the localhost prompt, press
**Play**.

If you'd rather just get a place file to double-click:

```powershell
.\START-HERE.ps1 -Build
```

(PowerShell blocking the script? `powershell -ExecutionPolicy Bypass -File .\START-HERE.ps1`)

### macOS / Linux, or if you already have Rojo

```bash
rojo serve          # then connect from the Rojo plugin in Studio
# or
rojo build -o LarpingSimulator.rbxl
```

Press **Play**. You will spawn in the spare room.

### Controls

| Action | How |
| --- | --- |
| Post content | Stand on a glowing pad, press **E** |
| Open a shop | Walk to a kiosk, press **E** |
| Courses / podcasts / downline / travel / rebrand | Button rail on the right, or the kiosks in any area |
| Launch your course | 🚀 on the button rail |
| Close a panel | **Q**, or the ✕ |

---

## The loop

```
post content ──► followers ──► sell courses ──► cash
     ▲                                            │
     └──────── rent things that make you ─────────┘
               look rich (and expire)
```

Four stats drive everything:

- **Cash** — what you actually have. Usually not much.
- **Followers** — audience size. Gates areas, courses, podcasts and rebranding.
- **Clout** — how rich you *look*. Comes from whatever you own or are currently
  renting. Multiplies the reach of every post.
- **Suspicion** — rises when you rent your whole personality, repeat yourself,
  or buy obviously fake props. At 100% you get exposed and lose a third of your
  followers, a quarter of your cash, and every active rental.

### Progression

Nine areas, each unlocked by follower count, each more expensive and less real
than the last: the spare room → the city → a car rental forecourt → a luxury
apartment → mansion district → a private jet terminal → a Dubai-style district →
a superyacht marina → a rented private island.

Then **Rebrand** (prestige): delete every video, lose everything, come back with
a permanent multiplier and a more impressive noun. Bedroom Guru → Side Hustler →
Entrepreneur → CEO → Multi-Millionaire → Mogul → Visionary → Thought Leader →
Billionaire Mentor.

### Systems

- **Rentals** — cars, property, jets, yachts, offices, security details, hired
  crowds, paid autograph queues, a helicopter you step out of for nine seconds.
  All on a timer. The meter keeps running while you are logged off.
- **Courses** — twelve tiers from *How To Become Successful* (£9) to the
  *Billionaire Inner Circle* (£250,000). The lessons are always "Mindset", "Wake
  Up Earlier", "Network", "Work Harder", "Buy My Advanced Course".
- **Podcasts** — you pay to appear, then answer one question. The most viral
  answers are also the ones that get clipped and used against you.
- **The pyramid** — past 100K followers your students stop buying courses and
  start selling their own. Each one sends a cut upward forever, and generates
  suspicion, because forty people running the identical grift with the identical
  slides is eventually noticeable.
- **Automation** — hire a social media manager and the posting happens without
  you. At that point you have stopped making the content and started managing
  the lie.
- **Random events** — algorithm boosts, viral reels, hater reaction videos, lost
  rental deposits, refund waves, payment processor freezes, and the occasional
  full-length documentary about you.
- **The endgame** — *Rent Billionaire Lifestyle, £10,000,000*. Mega yacht,
  private jet, mansion, supercar convoy and a full security detail,
  simultaneously, for ten minutes. Then you go home on the bus.
- **Leaderboards** — most followers, most cash, highest clout, most courses
  sold, and the only one that tells the truth: **Money Spent Pretending To Be
  Rich**.

---

## Project structure

```
START-HERE.cmd              Windows: double-click this
START-HERE.ps1              the setup script it runs
default.project.json        Rojo mapping
src/
  shared/                   ReplicatedStorage.Shared — data, read by both sides
    Balance.lua             every tunable number, and why it is that number
    Items.lua               the full LARP catalogue (18 categories)
    Courses.lua             course + mentorship ladders
    Areas.lua               map layout and content-spot yields
    Captions.lua            the generated social posts
    Podcasts.lua            shows, questions, answers
    Events.lua              random and exposure events
    Milestones.lua          follower milestone cards
    Prestige.lua            rebrand tiers
    Npcs.lua                customer archetypes and their lines
    Format.lua              number and currency formatting
    Net.lua                 remote definitions
  server/                   ServerScriptService.Server
    init.server.lua         boot order
    PlayerData.lua          profiles and persistence
    State.lua               derived stats (clout, multipliers) and replication
    Economy.lua             purchases
    Content.lua             posting, virality, suspicion from renting
    CourseService.lua       sales ticks and launches
    Suspicion.lua           decay, exposure events, getting exposed
    RandomEvents.lua        the event roller
    Pyramid.lua             the downline
    PodcastService.lua      appearances and answers
    Rebrand.lua             prestige
    Leaderboards.lua        five global ordered-datastore boards
    WorldBuilder.lua        generates the entire map from Areas.lua
    NpcService.lua          wandering customers
    Interactions.lua        proximity prompt wiring
    Actions.lua             the single client request router
    Simulation.lua          the one heartbeat that drives everything
  client/                   StarterPlayerScripts.Client
    init.client.lua         wires the streams to the HUD
    Theme.lua               the design system
    Hud.lua                 stat bar and button rail
    Panels.lua              every modal
    Feed.lua                the social feed
    Toasts.lua              notifications, milestones, announcements
    Request.lua             one call into the server
```

All game logic is server-side. The client sends an action string and an id, and
draws what it is told.

---

## Extending it

Nearly everything is data.

**A new item** — add a table to the right category in `src/shared/Items.lua`.
It shows up in that category's kiosk automatically:

```lua
{
    id = "car_hovercraft",
    name = "Hovercraft Rental",
    desc = "It does not hover. It is a boat. Film it from the front.",
    price = 85000,
    clout = 14000,
    rental = true,
    duration = 300,
    sus = 5,
    req = { followers = 200000 },
}
```

**A new area** — add an entry to `src/shared/Areas.lua` with its spots and
shops. `WorldBuilder` will generate the island, the pads, the kiosks and the
travel entry. Add a matching `Decor.<id>` function in `WorldBuilder.lua` if you
want it to look like anything.

**A new random event** — add a table to `src/shared/Events.lua`. The `apply`
field is data, not code: `followersPct`, `cashPct`, `cloutPct`, `suspicion`,
`clearRentals`, `buff`.

**Rebalancing** — read the header of `src/shared/Balance.lua` first. The clout
curve, the revenue exponent and the content-spot yields multiply together, so
changing one in isolation will not do what you expect. The numbers there were
tuned against an offline simulation of a full playthrough.

---

## A note on the satire

Everything here parodies internet-guru culture as a genre. Luxury brands are
deliberately fictional (*Rolecks*, *Richard Millions*, the *Royal Tree*, the
*Forbz* cover, *Top 30 Entrepreneur Under 30*), and no real person, company or
publication is referenced or depicted. The game is about a type, not a target.

It also does not teach anyone how to do any of this. The courses are empty, the
screenshots are fake, the awards have entry fees, and the player is the butt of
every joke.
