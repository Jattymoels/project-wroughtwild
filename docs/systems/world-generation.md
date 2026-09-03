# World Generation, Settlements and Travel

**Status:** Bounded hybrid generation accepted for prototype exploration;
the Wave 3 world pass answers "final terrain representation and
destructibility" — see
[Implemented](#implemented-the-3d-block-world-2-september-2026).  
**Related decisions:** D-001, D-003, D-005

## Purpose and player fantasy

Each save should present a different geography of opportunities. The player sees dangerous or desirable content before they can access it, establishes practical outposts and eventually connects the explored world to an ambitious main settlement.

## Prototype scope

- one bounded region or valley;
- seed-controlled terrain and resource placement where practical;
- a small biome vocabulary;
- guaranteed wood, iron, forge progression and trial access;
- one authored trial module;
- one placeholder class-hall location or marker;
- no infinite chunk generation;
- no production transport network.

A handcrafted greybox with deterministic resource variants is acceptable before full terrain generation if it tests the return loop sooner.

## Hybrid generation model

Procedural elements may include:

- terrain shape;
- biome selection and arrangement;
- elevation amplitude;
- resource distribution;
- routes and water;
- ordinary encounter placement.

Authored modules include:

- class halls;
- trials and boss arenas;
- settlements and merchants;
- major landmarks;
- critical progression events.

Placement rules must guarantee required progression content and reasonable reachability.

## World scaling

The world is partially or wholly unscaled. A powerful threat may appear close to the start and establish a future ambition. Clear signalling must distinguish “dangerous but possible” from “not yet intended.”

## Settlement arc

> Starting shelter → resource outposts → connected routes → ambitious main settlement.

Outposts exist near rare materials, trials or transport junctions. They reduce repetitive travel and create varied building contexts without requiring several equally large bases.

## Travel progression

Long-distance hauling should diminish over time through capability unlocks such as:

- carts and roads;
- boats and waterways;
- tracks or trains;
- portals;
- gliding or flight;
- automatic logistics between connected outposts.

Only walking and one simple convenience are required in the prototype. Later transport must preserve the value of discovering and connecting locations rather than becoming unrestricted map teleportation immediately.

## Technical risks

- save size and persistence of player modifications;
- terrain collision and navigation generation;
- lighting around arbitrary construction;
- world streaming;
- inaccessible critical modules;
- update compatibility for generated saves;
- pathfinding through player-built shapes;
- resource soft locks.

Terrain noise is not necessarily the dominant compute cost. Persistence, mesh/collision generation, navigation, entities and lighting require equal attention.

## Tunable parameters

| Parameter | Player effect |
| --- | --- |
| Region dimensions | Exploration scale and travel burden |
| Terrain amplitude | Traversal difficulty and vistas |
| Biome count/size | Variety and resource predictability |
| Resource density | Scarcity and outpost value |
| Landmark visibility | Strength of self-directed ambitions |
| Threat radius | Early danger and route choice |
| Travel speed | Hauling friction |
| Critical placement bounds | Reliability versus surprise |

## Prototype acceptance

- Required progression is present for every accepted test seed.
- The trial is visible or discoverable before the player is fully ready.
- Resource placement creates at least one meaningful travel decision.
- Save and reload preserve generated and player-built state.

## Implemented: the 3D block world (2 September 2026)

Wave 3 world slice 1 (owner direction: bounded but further out, biome
feel, verticality and caves, with block-breaking to follow). The world is
now a **full 3D block field** the sim generates deterministically per seed
(`sim/src/worldgen.cpp`, tuned entirely by `worldgen.json`):

- **Terrain:** 160×160 columns, 48 block levels. A rolling fbm base plus a
  second mountain layer — where a slow "cragginess" field runs high,
  ridged noise piles localized massifs with real cliffs. Strata under the
  biome surface block: dirt, then stone, bedrock at y=0.
- **Caves:** two intersecting 3D noise level-sets carve winding tunnels; a
  third opens caverns low in a column. Most tunnels keep a roof margin,
  but a tunable fraction of columns may breach the surface — natural
  entrances you find and drop into. Cave floors host resource nodes (iron
  runs richer underground — the reason to go down). The spawn clearing
  and the trial gate's ground are never carved.
- **Danger rings:** pack density multiplies with distance from spawn, so
  the heartland stays learnable and the map edge is genuinely hostile.
  The Wave 3 mob pass will hang harder compositions off the same rings.
- **Engine:** the sim also derives the render/collision geometry
  (`world_mesh`: per-chunk visible-block centres by kind plus exposed-face
  triangles), so the engine builds one MultiMesh per kind and one trimesh
  body per 16×16 chunk without re-walking a million blocks in script.
  Chunks exist so the digging slice can rebuild one patch, not the world.
- **Guarantees kept (D-003):** safe flat meadow clearing, minimum
  wood/stone/iron within the near radius, packs off the doorstep, the
  gate ≥ 70 m out in the wastes, all held across seeds by tests.

**Digging (slice 2, same day):** hold LMB on any generic terrain block to
dig it out over its `dig_seconds` (a progress bar fills under the
crosshair). Rules are data (`worldgen.json block_rules`): soil breaks fast
and yields nothing yet (digging buys ACCESS — mine down, open a cave, cut
a pit the horde falls into), stone breaks slow and pays the stone family
(rock faces are a quarry), bedrock never breaks. The engine keeps the dug
set, rebuilds only the touched 16×16 chunk(s) through the sim's
`world_mesh_chunk` (which applies the holes), and the save stores the
list — loading restores exactly the save's holes, filling back anything
dug since. Tool tiers wait until crafting wants them; the only cost is
time.

**Mobs in the world (slice 3, same day):** the caves are inhabited — Gloom
Crawler packs den on the same floors as the underground iron; Shrieker
packs in the forest and wastes recruit every idle mob in scream radius
(D-012's aggro chain); and the danger rings now also grow pack size and
crown one member with an elite modifier beyond the heartland (world.json
`elite_modifiers`: status-grammar counters with tripled drop bounties).

**Deliberately not yet:** building inside dug holes or caves (placement
still reads the pristine surface heights), a soil material family (dirt
yields nothing until something wants soil), water, falling-block physics,
and cave light rules (a lamp item; the dark is honest for now).

## Implemented: encroachment (Wave 4, D-018, 3 Sep 2026)

The base threat, built to two owner rules: **pressure, never demolition**
(a timber house is a house at every tier) and **a nuisance, never a
farm** (waiting in your base must not grow loot). Once the player has a
home - a shelter they have rested in - the sim's `Encroachment` settles a
**nest** on the fringe ring around it every `settle_seconds`, up to
`max_nests`, spaced from other nests and fresh scars. A standing nest
grows a tier every `growth_seconds` (a bigger pack; the top tier brings a
shrieker to call packs to your walls), refills its fallen every
`respawn_seconds`, and within `blight_radius_m` rest in the shelter pays
`uneasy_rest_multiplier` of its regen. Only `nest_loot_fraction` of
nest-born kills drop anything, and tearing a nest down (E, once nothing
defends it) drops nothing: it ends the nuisance and scars the spot for
`scar_seconds`. Numbers in `world.json` `encroachment`; nests are not
saved, so a loaded game starts quiet. The engine's `encroachment.gd`
feeds the sim a clock and the home, raises `nest.gd` mounds, fields their
packs (`Enemy.nest_id`) and routes their kills through the pack loot path
when the sim says that kill drops.

Next: burrowers that trench the ground between nest and home (the dig
system turned around - terrain is fair game, walls never are), and the
shut-door siege (packs massing at the door, the sortie as the moment).

## Open questions

- How class halls are signposted.
- When outposts become mechanically worthwhile.
- Whether cave dark needs its own light rules before torches exist
  (D-013's "menace is told by light" suggests yes).
