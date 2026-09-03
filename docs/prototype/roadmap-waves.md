# Prototype Roadmap — Waves

**Status:** Owner-directed plan (31 August 2026)
**Owner direction being implemented:** the world is an **open sandpit** — no
quest-hub town to return to (unlike Diablo/PoE). Moment-to-moment feel is
Valheim/Minecraft: walk out of nothing, harvest, build, get jumped. The mob
layer and itemisation head toward Path of Exile/Diablo (packs in the world,
drops with modifiers). Dungeons are where the roguelite innovation lives —
build/boon interaction and story — but they come after the sandpit feels
right. Catalysts remain a farmable currency class (ADR-0002 owner direction).

Each wave lands as merge-sized slices with headless verification; a wave is
"done" when the owner has played it and directed the next.

## Wave 1 — The Sandpit  *(in progress)*

Start with nothing in a seed-generated bounded world and survive/build up.

- Seed-generated terrain: bounded blocky heightfield, biomes, elevation
  (D-003); guaranteed placements — safe spawn clearing, reachable wood /
  stone / iron, the trial gate placed far and visible.
- Biomes with identity: meadow (safe start), forest (wood, prowlers), rocky
  hills (stone/iron, height), ember wastes (danger, the gate).
- Roaming mob packs by biome that drop materials on death (loot tables in
  data; PoE-style density comes in Wave 3).
- Start with nothing: hand-craft a **workbench kit** from gathered wood,
  place it, craft a **forge kit** at the workbench, place that; stations are
  placed objects now, not pre-built sites.
- **Power/fuel gate:** forge processes consume fuel (wood, or charcoal made
  from wood) — the first rung of the facility-and-power ladder from
  crafting-and-skills.md.
- New placeable material family: stone.

Out of scope for wave 1: dig-anywhere voxel terrain (excluded by D-001),
day/night, weather, hunger, mob respawning waves.

## Wave 1.5 — First-Person Feel *(landed 31 Aug 2026; D-012)*

Combat goes first-person and the horde becomes trainable, so the feel
question is answerable in greybox before Wave 2 commits itemisation to it.

- First-person camera as the default (third-person toggle kept for greybox
  debugging), crosshair, melee reach feedback and basic hit feedback.
- "Stupid zombie" open-world chasing per D-012: mobs press persistently and
  bunch while the player stays close (training works), with separation
  steering so trains form physically; running genuinely away breaks the
  chase after a dangerous disengage — no eternal aggro, no instant leash.
- A first cone-shaped area strike so a trained bunch already pays off.
- Re-examine dash: in first person, movement itself may be the defence
  (Zombies has no dodge); i-frames may not survive this wave.
  **Outcome:** dash kept as a movement burst, invulnerability removed
  (`combat_realtime.json`); the boss breath is dodged spatially. Also
  landed: crosshair aim feedback, hitmarker, damage flash, and stray-pull
  (damaging an idle mob wakes it).

### Art direction — first pass *(landed 1 Sep 2026; D-013)*

"Bright frontier, dark thresholds" ([art/art-direction.md](../art/art-direction.md)):
a vibrant Minecraft-warm overworld whose light and saturation drain toward
danger — PoE's use of darkness without its gore. Landed in engine: the
master palette as single source of truth, the texture generator rebuilt
around it, and `BiomeMood` — sun, fog and ambient crossfade to the biome
underfoot, so the Ember Wastes feel wrong before the first pack appears.
Blocky terrain/buildings, chunky low-poly props, smoother low-poly
characters later; polygon budget is a non-issue at this scale (the
constraint is authoring time). Second pass: trees, boulders and iron veins
became procedural faceted meshes (`prop_mesh.gd`) — crooked trunks,
warped-icosahedron canopies and rocks in palette vertex colours,
deterministic per position — per the owner's note that props must not read
as Minecraft; only terrain and buildings stay blocky.

### World-feel pass *(landed 1 Sep 2026)*

Collecting and moving get their juice before itemisation piles on top:
harvests and mob kills scatter physical material chips that bounce, rest,
and vacuum into a nearby player (grant-on-absorb, with an aggregated HUD
ticker); resource nodes squash on each harvest, visibly shrink with
remaining yield and shrink away when spent; the crosshair names its target
and glows harvestables; jumping gains coyote time, input buffering and a
slightly higher arc (a placed 1 m block is comfortably hoppable), with a
camera dip on hard landings; the sandpit gets distance fog and filmic
tonemapping. Also fixed: spawned enemies no longer spend a physics frame at
their parent's origin. `game/tests/feel.tscn` drives the loop headless.

### Grammar spike *(landed 1 Sep 2026; playable ahead of Wave 2)*

One full grammar sentence is playable end to end, so the freeze-shatter
combo can be felt before Wave 2 commits to the vocabulary: **Frost Orb**
(key 3 — orb delivery, fork propagation, chill payload) builds toward a
freeze (three hits bare), and striking a frozen mob with the cone strike
(key 1) triggers the **shatter hook** — an execute plus a cold nova that
chains down a frozen train. Three tag-targeted mods toggle on F1–F3 as
scaffolding (Forked Lattice, Deep Frost, Wide Shatter) to feel each word
scale; Wave 2 moves mods onto gear, points and boons. Numbers live in
`data/tuning/grammar.json`, the resolver (increased-vs-more) in
`sim/src/grammar.cpp`, and `game/tests/grammar.tscn` drives the whole
sentence headless.

## Wave 2 — Items and Modifiers *(kicked off 1 Sep 2026)*

**Owner direction (1 Sep 2026):** after the first 3D playtest, continue with
the build waves; Wave 2 focuses on items and modifiers **and** on the
in-game interface — inventory, action bar and crafting pop-ups were "quite
difficult to test with", so the interface is the test instrument this wave
is built on. Specs: [systems/items-and-modifiers.md](../systems/items-and-modifiers.md)
(D-014, proposed) and [systems/interface.md](../systems/interface.md)
(D-015, proposed).

### Interface track *(first slice landed 1 Sep 2026)*

Life bar with defences, an action bar with key caps and cooldown sweeps, the
build chip, a right-aligned holdings strip, the pack screen (**I**: tiles per
material and currency, worn gear with its rolled properties, vitals, and the
spike mods as toggles until gear carries them; wear armour from here), work
panels as have/need-coloured cards inside a scroll area, and an **H** help
overlay replacing the permanent hint paragraph. One code-built Theme from
the master palette. Next: item cards with rarity colour and per-modifier
sentences, and a compare view, as soon as the items spec is accepted.

### Itemisation track *(D-014 accepted 1 Sep 2026; implementation under way)*

Owner answers: weapon / chest / charm; plain / keen / wrought **plus
uniques** with legendary or weird interactions; any modifier may drop
(catalysts target, they do not gate); upskilling points wait for a later
wave. **First slice landed 1 Sep 2026:** the unified modifier pool in
`items.json` (ten modifiers, three slots, three rarities, four bases with
implicit modifiers), rolled items that feed both derived stats and the
active modifier set, trial rooms dropping keen/wrought gear, pack items
in the save, and item cards in the pack screen. Uniques are deferred by
owner direction (noted in the items spec). Still ahead: the compare view.

### Spell-grammar track *(landed 2 Sep 2026; D-016)*

Owner steer (2 Sep 2026): PoE's many-skills-with-interacting-grammars over
Diablo/Last-Epoch gear-defined archetypes — so "the weapon decides
delivery" was dropped before it shipped. **Skills are found, not worn:**
seven skills in `skills.json` (the starting four plus Ember Bolt, Rend and
Frost Nova as mob-dropped **skill pages**), a free four-slot bar on keys
1–4 (Shift dashes wherever Dash sits), assignment in the pack screen, the
loadout in the save. Three statuses (chill/freeze, **ignite**, **bleed**
with its walking tax), two hooks by tag (**shatter** — which now novas a
frozen boss and thaws it rather than executing, `executes_boss` tunable —
and **proliferate**), nine more tag-targeted modifiers, the Ember Wand,
and per-kill world drops: materials, rolled keen gear and pages on
independent seed streams (a gear pickup remembers only its kill; the sim
re-rolls the identical item on claim). Balance oracle untouched: encounters
still fight with the starting kit. Details in the skill-grammar spec's
[Implemented](../systems/skill-grammar.md#implemented-the-wave-2-grammar-slice-2-september-2026)
section.

**Owner playtest verdict (1 Sep 2026):** "I like the gameplay loop so far."
Base building was barely exercised in that run; its improvement and
optimisation pass is parked as a later, quick item (construction.md open
questions stay open) rather than a Wave 2 concern.

The PoE side: more bases and slots, the modifier/tier pool, rarity, how
crafted vs dropped vs tempered items relate. Catalyst currency types grow
here. **Design space: [systems/skill-grammar.md](../systems/skill-grammar.md)**
— the delivery/propagation/payload/hook grammar, tag-targeted mods,
increased-vs-more, the status matrix and the "your build decides how you
train" principle. **Carries the D-012 mechanics vocabulary:** modifiers grant damage
*mechanics*, not just numbers — cone/cleave area, ground effects (fire
patch, frost floor) the train is led through, damage-over-time tag-and-run
(bleed, poison, ignite), chill/freeze choke-making, attack/cast speed for
drill-through single-target play. Each mechanic is a different way of
moving in first person. Balance sims extended to itemisation.

## Wave 3 — Mobs, Packs, Drops and the Open World

**Owner direction (2 Sep 2026):** after the spell grammar, spend real time
on mobs, drops and the open world — "not infinite, but more so the feel of
the generation, biomes, make it further out, allow verticality/caves", plus
"some sort of mechanic for breaking the generic blocks too not just
trees/stones".

### World track — slice 1 landed 2 Sep 2026

The world is a full 3D block field: 160×160×48, a mountain layer for real
verticality, strata (dirt/stone/bedrock), carved cave systems with natural
breach entrances and richer iron on cave floors, danger rings scaling pack
density with distance from spawn, and chunked render/collision the sim
derives (`world_mesh`) so digging can later rebuild one patch. Guarantees
(safe clearing, nodes in reach, far gate) hold across seeds by test. See
[systems/world-generation.md](../systems/world-generation.md).

**Slice 2 (same day): breaking blocks.** Hold LMB digs any generic block
out over its tuned dig_seconds (`worldgen.json block_rules`); stone pays
the stone family, soil buys access, bedrock refuses. The engine records
the holes, rebuilds only touched chunks via the sim's `world_mesh_chunk`,
and the save restores the exact set. Tool tiers deferred — the mechanic's
cost is time. Owner's ask ("some sort of mechanic for breaking the
generic blocks") answered; pit traps against the D-012 train now emerge
free.

### Mob track — first slice landed 2 Sep 2026

Landed: the **Shrieker** (sickly-yellow aggro-chainer that hangs back and
screams every few seconds, waking every idle mob in radius — D-012's
Zombies-wave builder; kill it first or fight the biome) and the **Gloom
Crawler** (cave dweller denning on the same floors as the underground
iron). **Elite modifiers** (world.json) that interact with the D-016
statuses instead of only multiplying numbers: Unfreezable, Cinder-Blooded
(death fire burst), Stonehide, Hastened — each paying an extra loot pass
and tripled gear/page chances, so elites are why you hunt the far rings.
Danger rings now also grow pack size and crown elites only beyond the
heartland; cave packs den underground; gear pickups remember the elite id
so the boosted claim survives the walk back. Trial rooms do not roll
elites yet (the dungeon pass owns that).

Still ahead in this track: density tuning toward the "clear a pack, get a
reward" cadence once the owner has felt the current pressure; more
families per biome as the grammar wants counters; extending the balance
oracle to elite encounters. Grammar balance tuning starts now that mobs
push back.

**Owner playtest verdict (2 Sep 2026):** "I really like the combat at the
moment." Held steady during playtesting, tune later: player damage feels
high (but fun); page/gear drops progress too fast at the start — wants
early deprivation that eases as mobs thin; density is right ("overwhelmed
easy which is a great feeling") though ash hounds hit too hard for their
speed and pack size; a health-regeneration route is needed. Fixed on the
spot: invisible damage from cave dwellers through the floor
(`vertical_reach_m`), and mobs stuck on one-block steps (they hop now,
`jump_speed_mps`). Caves look good. **Next intensive after this playtest
round: building mechanics** — placement still feels "off", above all
sub-block pieces (a post on a block or wall) inside the cell grid.

### Building intensive — slice 1 landed 3 Sep 2026 (D-017)

The owner's four placement screenshots were one bug: the ray chose the
cell, R chose the position inside it, and they only agreed by luck. The
fix is a different addressing scheme, not a patch: pieces occupy **lattice
elements** — a block a cell, a wall or floor a face two cells share, a
post or beam an edge four cells share — and placement is one rule, *the
nearest free element of the piece's kind to the crosshair*
([systems/construction.md](../systems/construction.md)). Walls join walls,
posts stack, a cube fills either side of a wall, and corners grow their
own post trims. `sim/lattice.h` owns the geometry and the occupancy
registry; the engine filters candidates by terrain and props (a face
between rock and open air is a mine lining, a block never goes into rock)
and mirrors the registry with nodes. Saves are schema v2 (element-keyed).

**Slice 2, vocabulary (landed 3 Sep 2026):** the registry now runs at
half cells and pieces cover footprints of registry elements (one rulebook
for two scales, and the door's two-cell height); eight shapes — cube,
wall, pillar, beam, floor slab (un-gated), stairs, a two-cell door that
swings on E, and the roof wedge as the trial reward in place of the slab;
forms (stairs, wedge, door) get real meshes and collision.

**Slice 2b, fine mode (landed 3 Sep 2026):** G swaps the selection for
its half-scale twin (half cube, wall, post, beam, slab) — the same rule at
half the cell, the owner's "post on a block" at sub-block scale, with no
new occupancy logic and no palette growth.

**Slice 3, shelter (landed 3 Sep 2026):** the sim flood-fills the room
around the player (stopped by placed faces and volumes and by terrain);
a roofed room under `max_room_cells` with no path to the sky is a shelter,
and resting there `settle_rounds` after the last hit regenerates
`regen_life_per_round` — the owner's regen ask, and the first reason to
build on day one. A dug hollow with a slab over its mouth counts.

**Owner building playtest (3 Sep 2026):** "within the 1 block building
feels nice", tension outside it. Fixed the same day: reaching into empty
air (the view ray snaps to elements touching what is built), the piece you
build on decides the grid (a full cube on a half cube), a player step-up
for stairs and half cubes, door collision (a Godot pivot mistake), and
per-shape hints (floor slabs live between cells).

**Material families (landed 3 Sep 2026; D-018):** timber, stone and iron
as data with a source item, a texture and traits; shapes require traits
(doors need joinery, the wedge masonry, the new two-cell girder metal);
Q cycles the families you carry; refusals are explained in the HUD. The
`malleable` trait waits for an alloy family and the first curved form.

**Owner steer on base threats (3 Sep 2026):** mobs breaking walls is out —
"starting out poor ... a wood house shouldn't be easily broken down", and
the threat should not vanish at higher tiers either. Threat around a base
must be *pressure*, not demolition; and it must not become a farm ("an
exploit to just wait in your base for the mobs to get larger").

**Encroachment slice 1 (landed 3 Sep 2026):** once the player has a home
(a shelter rested in), packs settle into **nests** on its fringe ring,
one per `settle_seconds` up to a cap, spaced apart. A standing nest grows
a tier at a time (bigger pack; the top tier brings a shrieker), refills
its fallen, and blights rest within its radius (uneasy rest, a fraction
of the regen). The exploit guard: only a fraction of nest-born kills drop
anything, and tearing a nest down (E, once undefended) drops nothing —
it ends the nuisance and scars the spot. Rules in `sim/encroachment.h`,
numbers in `world.json` `encroachment`; nests are not saved. Next
slices: burrowers that trench the ground between nest and home (the dig
system, turned around), and the shut-door siege: packs massing at the
door, the shrieker calling more, the sortie as the moment.

Still ahead for building: the owner's next playtest, an alloy family.
Deliberately out: structural-support rules, wall damage.

## Wave 5 — Eras and the Foundry *(direction accepted 3 Sep 2026; D-019)*

The answer to "a talent tree has nothing to push against in a procedural
world" ([systems/progression-eras.md](../systems/progression-eras.md)):
the world is the campaign. Slices, in order:

1. **The first era transition** *(landed 3 Sep 2026)* on the Forge
   Tyrant's fall: an era state in the sim driven by world effects
   (`eras.json`); copper and tin veins surface in the deep when the strata
   crack (nodes carry an era; the engine reveals them with a notice and a
   light shift); bronze as the alloy family (malleable, tough) and the
   arch as the first curved form; hounds run in bigger packs and whelps
   leave burning ground; encroachment switches on only from era two.
2. **The Foundry** *(landed 3 Sep 2026)*: a 3×3 plate that widens with the
   era, eight ingot verbs, ten pairs and lines of three, twelve milestone
   sources (first kills, first smelts, the mine, the Tyrant, the era, the
   first bronze), re-forging for one iron at the forge; the panel opens
   from a built forge. Refinement and wrought forms wait for the next pass.
3. **Items as mechanics** *(landed 3 Sep 2026)*: tier breakpoints on seven
   modifiers (a third tier each), `tier_cap` per base (iron two, bronze
   three), held-back rolls shown greyed with what unleashes them, drop
   tiers rising with the era and with elites, and the Preserving Transfer
   at the forge.
4. **Skill mastery** *(landed 3 Sep 2026)*: use-milestones per skill unlock
   per-skill perks through a `skill:<id>` tag; the Shatter spell; crafted
   gear rolls modifiers; pack Drop and Discard (owner's second-arc notes).
   Still ahead: the third era, more trial floors, life in the world beyond
   hostiles, and the wider modifier vocabulary.
5. **The bigger world** *(landed 3 Sep 2026)*: 224 cells a side, the fen
   as a fifth biome, and four new families (bog lurker, marsh wisp, cinder
   wisp, hollow knight) as data with their own looks and immunities.
6. **Era three, the deeper floor, life** *(landed 3 Sep 2026)*: the trial
   gains floors (the Deeper Forge, the Ash Warden) and its completion wakes
   the Ash Tide - ember-iron, silver, steel, further-calling shriekers,
   wisp escorts, commoner elites; the peddler, grazing elk and birds.

Owner tuning note (3 Sep): "everything is way too fast/powerful ... to
feel good you have to start with less damage/more danger" — era one's
target is slow, poor and dangerous; numbers still held until asked.

## Wave 4 — Dungeon and Roguelite Iteration

The innovation layer: run structure, boon/build interaction depth, secrets,
story-through-runs, dungeon modifiers the player chooses (risk dials). The
existing trial is the seed of this wave. **With D-012:** horde/wave rooms
(the CoD Zombies mode distilled — survive escalating waves, spend between
them), and the deliberate AI contrast: dungeon enemies may grow smarter
than the open world's stupid zombies, making dungeons feel dangerous in a
different way, not just denser.

## Standing constraints

- Rules stay in `sim/` (engine-neutral, tested headless); the engine renders
  and times them (ADR-0003 / D-010).
- Every tunable lands in `data/tuning/*.json` with a `design_purpose`.
- The vertical-slice loop (gather → forge → order → armour → trial →
  catalyst → boss → unlock) must remain completable at the end of every wave.
