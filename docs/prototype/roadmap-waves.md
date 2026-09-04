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
owner direction (noted in the items spec). **The class gear pass (4 Sep
2026):** an offhand slot; bows, a quiver and the projectile modifiers
(damage, Fletching, Barbed Heads) for the Ranger; shields for the Warden;
a brand and a lantern for the Kindler; recipes at the bench and the
forge. Still ahead: the compare view.

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

**Encroachment slice 1 (landed 3 Sep 2026; retired 4 Sep 2026, D-024):**
once the player has a home
(a shelter rested in), packs settle into **nests** on its fringe ring,
one per `settle_seconds` up to a cap, spaced apart. A standing nest grows
a tier at a time (bigger pack; the top tier brings a shrieker), refills
its fallen, and blights rest within its radius (uneasy rest, a fraction
of the regen). The exploit guard: only a fraction of nest-born kills drop
anything, and tearing a nest down (E, once undefended) drops nothing —
it ends the nuisance and scars the spot. Rules in `sim/encroachment.h`,
numbers in `world.json` `encroachment`; nests are not saved. **Retired
4 Sep 2026:** the owner found nests "not rewarding" and unnatural to the
world; the code and data are gone (D-024), and the base threat waits on
a later reassessment of mob AI behaviours. The burrower and siege slices
that were to follow are shelved with it.

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
   leave burning ground.
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

7. **The pacing pass** *(landed 3 Sep 2026, D-020)*: long fights (mob life
   ×2.5, damage ×0.7), the quiet heartland (first ring at a third density,
   grazers by their own rule), the era-one modifier pool (`from_tier`),
   and **fire-setting** as the first capability gate — a campfire against
   rock, cold cracks what is hot, cracked rock digs by hand; charcoal for
   the alloy ores.
8. **Seams and the yard** *(landed 3 Sep 2026, D-021)*: masonry is the
   unlock, not stone — fieldstone lays footings and dry walls, timber
   wedges split seams (E drives, a heavy blow drives at once, a hot seam
   splits whole), the mason's yard dresses split stone; fire-setting
   reframed as one material response. Two rules: materials have
   responses, skills have properties; Baseline, Exploit, Synergy.
9. **Population and performance** *(landed 3 Sep 2026)*: a spatial mob
   grid (`mob_grid.gd`) answers every neighbour query (separation, screams,
   proliferation) so cost follows the crowd, not its square; packs sleep
   again when calm, unhurt and far (survivors return, the dead do not); a
   live-mob cap (`horde.max_live_mobs`); elk herds halved; hounds 5.5 m/s.
10. **Skills on the plate** *(landed 3 Sep 2026, D-022)*: skill tablets on
   the Foundry plate, ingots beside a tablet supporting that skill alone
   (tag-checked, `support_multiplier`), F opens the Foundry anywhere, the
   first dressed block a milestone.
11. **The stone accomplishment pass** *(landed 4 Sep 2026; the owner:
   "a must")*: seams are lines through the stone now, flush with the
   blocks they cross and stepping with their heights, and the ore veins
   take the same line in the metal's colour (the owner: "flush with the
   exposed stone generated rather than a pebble look ... more of a
   pattern/line through the stone"); the wedge sinks and leans as it is
   driven; a split throws a fist of stone off the seam; the first dressed
   block is a beat on the HUD. Still open: **a first-hour job for fire**
   waits on a decision, because the class kits changed who can quench
   (only the Kindler and the Warden start with cold; a Ranger cracks hot
   rock only with a blow) - the candidates are an iron vein that wants
   heat, or a hard seam. **Melee's space control** *(landed 4 Sep 2026)*:
   a strike or a sweep staggers the mob it hits (`stagger_seconds`: it
   halts and loses its wind-up), shoves it along the blow (`push_m`; the
   area strike 1.2 m, the sweep's "shove the line, own the space") and
   braces the swinger (`swing_armour` for `swing_seconds`, on the same
   clock as the Plate reading's armour on cast); a boss takes half the
   stagger and none of the push (`grammar.json hooks.melee`); all three
   resolve through the grammar, so gear and the plate can grow them.
   **The bench kept alive** *(landed 4 Sep 2026)*: a bundle of eight
   wedges from three timber, and a **timber frame** (ten timber) that the
   forge's and the yard's kits are built on, so the bench stays in the
   chain for every station. The owner (4 Sep): unsure wedges should be a
   big thing to craft, "okay for now"; and would like the bench to make
   "world/nature building things ... decorations, or things to help with
   farming" - recorded here as the next bench slice, with two candidates:
   decorative pieces that need no system (a fence rail, a lantern post, a
   planter box) and a garden bed that grows a fibre or a food once a
   farming loop exists. The owner (4 Sep) likes the current tuning: the
   damage pass is closed.
12. **The working** *(proposed 3 Sep 2026, D-023; owner answers 4 Sep;
   slices 1 to 10 - the frame, every ingot reads every skill, typed
   currency, the flow with kinds in the detached cells and the first
   forms, kinds as variants with the reactions' hooks, links and Arc, the
   Marrow's and the Quicksilver's forms, rails as the class's surround
   from the start with a specialisation at the trial, the metal of an
   ingot - landed 4 Sep 2026)*:
   the plate worked around sockets - subjects (skill tablets, the
   Vanguard), supports whose reading the subject decides, corners that
   hold ingots or typed currency as augments (a Catalyst makes Scald),
   links between sockets, class and manner rails; trade currency split
   into kinds that aim a craft. Slice order in
   [systems/foundry.md](../systems/foundry.md).

Owner tuning note (3 Sep): "everything is way too fast/powerful ... to
feel good you have to start with less damage/more danger" — era one's
target is slow, poor and dangerous. Released the same evening as D-020's
pacing pass (the numbers above); combat damage on the player's side is
still untouched.

## Wave 6 — The World Made Whole *(owner direction 4 Sep 2026)*

The owner, with the Foundry order done and the class kits in: "I would
rather spend some intensives on making the actual world feel more
complete ... what other options can we have to 'slow down' the
progression. That could be making the biomes bigger, making trees harder
to cut down, but they fell as one - make the colours and feel just more
expansive." Six slices proposed and accepted (4 Sep), in this order; the
owner on the fifth: "imperative there is almost like a forced - go back
and continue your shelter, and get lost in that for a bit"; on the
sixth: "would definitely need chests/storage solutions". Fire stays
parked and the wedge stays as it is ("maybe once we get down the line of
automation").

1. **Trees fall as one; boulders crack** *(landed 4 Sep 2026)*: a tree is
   six presses of E, each leaning the trunk further from you, then it
   comes down whole from the base and pays fourteen wood at once with a
   stump left behind; a boulder cracks a chunk of three fieldstone off
   every third press and rolls over on the last. Meadow trees are sparser
   and bigger (`worldgen.json` nodes, `drive_presses` on any node). Engine
   unit %s, sim %s.
2. **Iron is a walk** *(landed 4 Sep 2026)*: iron leaves the near
   guarantee (`min_nodes_near`) and is guaranteed within a ring of ninety
   metres instead (`far_radius_m`, `min_nodes_far`), placed beyond the
   near radius when a seed comes up short, so the first forge is a walk
   into the hills and back. Sim 3684.
3. **A wider valley** *(landed 4 Sep 2026)*: 320 m a side (from 224;
   400 chunks), the height noise at two thirds and the moisture noise at
   three fifths of their frequency so biomes and hills are broader, the
   massifs' fields slower, the near radius 55 m, iron within 120 m, the
   danger rings at 110 m and 220 m, the gate past 160 m, packs off the
   doorstep to 50 m. Performance check: the 120-frame headless smoke run
   took 1.94 s before and 2.583 s after (world build included). Sim 4745.
4. **The expansive pass** *(landed 4 Sep 2026)*: a rim of massifs
   climbing over the outer 34 cells to 16 blocks more, ridged by the
   massif noise (`worldgen.json` mountains `rim_width_cells`,
   `rim_extra_scale`), so the valley reads as a valley from anywhere;
   ground cover per biome in one MultiMesh per chunk and kind - tufts and
   flowers on the meadow, ferns in the forest, reeds in the fen, dead
   grass on the ash, a rare tuft in the hills (`ground_cover.gd`, placed
   by a hash of the cell so a rebuilt chunk grows the same); three tree
   silhouettes by biome - the broadleaf, the forest's pine, the wastes'
   bare snag (`prop_mesh.gd`); the mood table carrying each biome's sky
   and aerial haze (the far distance dissolving into the sky, most in the
   hills, least under the trees) with the five palettes warmed, darkened
   or bleached apart. The river from the hills to the fen stays the
   add-on. Sim 4791, engine unit 365.
5. **Day and night** *(landed 4 Sep 2026)*: a twelve-minute day
   (`world.json` `day`) in dawn, day, dusk and night by fraction, the
   night the last third - about four minutes, long enough to build
   through. Dusk is the warning: the notice points home by the eight
   winds and the HUD counts down to the night, then to dawn. Night: the
   sky, the fog and the sun go blue and faint (`biome_mood.gd`, the sun
   swinging from dawn to dusk and sitting low after), every mob wakes
   from `night_aggro_multiplier` further and a pack stays awake further;
   out in the open the cold takes `exposure_life_per_round` down to
   `exposure_floor_fraction` of max life and no further - it never kills,
   it sends you home - and a shelter's rest pays
   `shelter_night_regen_multiplier`; a carried lamp lights the way. The
   sim owns the clock (`daycycle.h`; `advance_time`, `day`, `day_rules`;
   saved as `day_clock`). Sim 4813, engine unit 371, integration 233.
6. **Hauling** *(landed 4 Sep 2026)*: the pack takes from the ground
   only up to a cap per family (`world.json` `hauling`: timber sixty, the
   ores thirty, forty for anything unlisted; forged goods and gear never
   capped, so only the haul is bounded). A full family leaves its chips
   where they lie - no magnet - and the HUD says so once in a while; the
   holdings strip reads "Timber 32/60". The chest is a construction piece
   (`construction.json` `chest`: six timber, joinery, a lidded box low in
   its cell) whose store the sim keeps under the piece's element key;
   E opens the chest panel (`chest_panel.gd`: a row per family, store and
   take by stack, bounded by the chest's 240 units and the pack's cap),
   and breaking the chest spills what it held where it stood. Saved with
   the economy (`stores`). Sim 4835, engine unit 377, integration 244. The
   owner's storage ask (D-005 arriving early) is met; the outpost around
   the chest is the player's to build.

## Wave 7 — Density and Fear *(owner direction 4 Sep 2026)*

**Owner, 4 Sep 2026 (late):** "the combat is in the right direction, I
think the problem is navigating where those improvements are seen/felt
... I want the cake and to eat it too: Path of Exile map-like mob
densities early on as well, but then the improvement of feeling
confident against them quickly feels like you're unkillable too early
... I need that friction of stretching it out to be better conducted."
The diagnosis agreed: the problem is ordering, not combat. Forge 2
arrives in the first hour, era 1 packs never step up, and density was a
global dial by danger ring, so here and there felt the same. Minecraft's
trick is that density is a property of place and hour; PoE's is that you
choose it. Three slices, all accepted:

1. **Density as place, hour and noise** *(landed 4 Sep 2026)*: pack
   density is the biome's own (`worldgen.json` biomes `pack_density`;
   the meadow a straggler at 0.0006, the hills 0.0025, the forest 0.004,
   the fen 0.011, the wastes 0.013, the caves 0.014) and the danger rings
   keep only their teeth (size bonus, elite chance). The deep biomes
   patrol (`patrols`): worldgen gives each of their packs a route from
   its den `patrol_length_m` toward the spawn, stopping short of the
   doorstep, and at night `mob_packs.gd` walks the pack's position out
   over the first half of the night and home over the second, its
   members roaming toward wherever the pack should be (`enemy.gd`
   `roam_to`). Noise (`combat_realtime.json` `noise`): a press, a wedge
   blow, a boulder cracking, a tree falling, a hit landing either way,
   each with a radius that wakes every idle mob and dormant pack inside
   it; a source inside a closed room carries `muffle` of its radius. The
   HUD says "Something heard that." when a pack wakes to it. Sim %s,
   engine unit %s, integration %s.
2. **The world a beat ahead** *(landed 4 Sep 2026)*: the second forge's
   upgrade wants three **bog iron** (`crafting.json`), and only the fen
   drops it - the lurkers most kills, the wisps sometimes - so the
   tempering and the iron armour behind forge 2 are fetched from the place
   that is already denser than you. Every elite carries a **bounty**
   (`world.json` `elite_modifiers` `bounty`: an Ember Catalyst six times
   in ten, a Preserving Catalyst four), so catalysts come mostly off the
   crowned, who den in the far rings; the families keep their own rare
   catalyst drops because the typed currency (D-023 slice 3) needs a
   family's kind to fall from the family, so "elites only" became "elites
   mostly". The heartland's mobs hit harder (whelp 6, hound 4, husk 8).
   Each era carries an **armour ceiling** (`eras.json`
   `armour_reduction_cap`: a quarter in the valley, nearly half once the
   deep wakes, most of it in the ash tide), applied in `mitigateDamage`
   through the combat host, so early gear buys control and life, never a
   wall. The **train** (`combat_realtime.json` horde `train_*`): a bite
   that follows bites from other mobs inside the window lands 20 percent
   harder per earlier mouth, to 60 - `player_combat.gd` remembers who bit
   when, the HUD's hit line says "the train x1.2". Trials stay the maps.
   Sim 4495, engine unit 384, integration 252.
3. **The horn and the siege**: the shrieker's throat as a tool that calls
   every pack in radius (voluntary density on the player's terms); at
   dusk a howl, some nights hounds come to the lamp, circle and scratch a
   timber door and leave at dawn; era 2's husks break timber, so the hut
   becomes stone; death respawns at home.

Rejected: scaling by day index. It would stretch the curve but breaks
D-019's rule that the world changes on the player's milestones, never
the clock.

**Drops under density (owner, 4 Sep 2026; not now):** with real density
the drop tables become the next problem - "will the player be
over-inundated with crap, or useless early stuff". The direction to keep
in view: the main items come from trials and world mobs drop only
foundational things; and PoE's community-driven item filters are a
design flaw to design around, never a feature to copy. Few, meaningful
drops by design.

## Wave 4 — Dungeon and Roguelite Iteration

**Owner, 4 Sep 2026:** "this will be a big iteration intensive, keep as
high priority but not now - it needs to be more like a WoW dungeon or a
late game PoE map but shorter to allow for boon mechanics." So: an
authored run with rooms and a shape, not the current door-choice ladder;
shorter than a map, long enough for boons to compound.

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
