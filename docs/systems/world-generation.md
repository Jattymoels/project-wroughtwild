# World Generation, Settlements and Travel

## Building refresh — INT-03C, 7 September 2026

Construction edits carry their actual clearance bounds into deferred scenery
refresh. Unaffected regional instances, cover and ruin pieces are retained;
leyline tiles rebuild for nearby construction or changed terrain support.
Complete generation/save refreshes remain available as the equivalence reference.
This changes refresh work, not profile inputs, geography, retention distances,
finite stock or saved edits. [Placement evidence](../prototype/placement-reliability-2026-09-07.md).

## Save recovery and repeated travel — INT-07C, 7 September 2026

Normal loading validates the current whole-world candidate before restoration.
A missing, truncated or invalid current file may recover the validated
`.previous` checkpoint, including its matching inventory, terrain edits,
resource work, buildings, stations, machine ledger, loose loot and player pose.
Loading never merges the two checkpoints or reads uncommitted `.pending` data.
The HUD reports "Recovered previous save." A recognised future schema or unknown
generation profile refuses automatic recovery rather than silently rewinding.

Reading changes no save files. After recovery, the next normal save retains the
intact previous checkpoint instead of rotating the damaged current file over it;
this works across the short-lived SaveManager instances used by F5/F9.
Staging is flushed before replacement, and a failed write reports its reason.
If neither candidate validates, restoration refuses before changing live state.
Runtime failure after mutation begins does not attempt a second restore; this is
not a rollback system for engine failure or power loss. Schema 2, generation
inputs, finite stock, trial deposits and existing lifetime rules remain unchanged.
[Reproduction, repeated circuits and limits](../prototype/session-reliability-2026-09-07.md).

## Walking support under overload — INT-07G, 7 September 2026

A recent focus scan does not prove that streamed terrain preparation kept up.
After a moving scan, the [safety continuation](../prototype/frame-pacing-2026-09-07.md)
checks published chunks across the existing `terrain_safe_radius_m`. If any
are incomplete, the existing synchronous area-completion operation restores
that nearby buffer before backlog reaches the player. Hidden partial chunks
cannot satisfy the check. This uses the same safety radius and complete geometry,
collider, scenery and finite-stock contracts as teleports and restoration.

`safety_refills_total` is a transient diagnostic count, not a saved field or
tuning parameter. Overload recovery may spend longer in that frame: collision
safety is verified separately from comfortable rendering performance. Ordinary
phase budgets, detail and retirement radii, generation inputs and saves remain.

## Nearby refresh coordination — INT-07F, 7 September 2026

The [refresh continuation](../prototype/focus-scheduling-2026-09-07.md) gives
periodic terrain scanning/retirement its own frame, followed by a due resource
scan and then preparation. Terrain coordinates both existing streams. A delayed
scan retains its due timer; the transient order guarantees preparation a turn
even when scan timers are continuously overdue. A new world resets that order.
It is not persisted and introduces no numerical tuning or generation input.

The teleport guard and explicit area completion remain synchronous regardless
of whose turn it is. Immediate resource focus/restoration bypasses ordinary
separation. Detail masks still flush on scan frames. Complete publication,
finite stock, existing preparation budgets and distances remain authoritative.
Tests exercise both normal and overdue cadences and historical worlds; matched
timing and unresolved frame gaps are recorded in the work item.

## Nearby loading schedule — INT-07E, 7 September 2026

The [loading schedule](../prototype/stream-scheduling-2026-09-07.md) separates
triangle-shape preparation from terrain publication. A prepared shape belongs
to its hidden partial chunk and has no physics body. Only complete publication
installs the collider, suppresses building-overlapped cover and makes the chunk
visible/queryable. Cancellation frees the unpublished shape, meshes and sampler.

Ordinary streamed arrivals still reground resources, rare scenery and solid ruin
pieces immediately. Their cosmetic leyline tiles enter a coalescing queue, at
most one integer entry per existing tile. Each complete tile consumes one of
the existing terrain work slots; terrain preparation continues when that finite
queue drains. Execution reads current support and building footprints. Explicit
area preparation drains pending scenery, and edit/build/full-refresh paths
reconcile it using their existing immediate/deferred event boundaries. World
scenery replacement owns a fresh queue; it retains no old terrain references.

`resource_build_budget_ms` defaults to 2 ms in `strange_stream.gd`: stop adding
resource scenes once this frame's creation time reaches the budget. One whole
node always completes, and the existing 12-node cap also applies. This is a soft
creation-work budget, not a limit on the entire frame or on an indivisible node.
Explicit immediate materialisation bypasses it for setup and restoration.
The terrain slot count remains one, and all detail/retirement radii, geometry,
finite stock, generation profiles and save schema remain unchanged.

## Travel presentation cost — INT-07D, 7 September 2026

The [travel optimisation](../prototype/travel-performance-2026-09-07.md) preserves
existing radii, scene detail and the terrain publication boundary. Resource
scenes retain one shared PackedScene while each actual node keeps its own stock,
collider and mutable materials. Common-resource emission shaders are prepared
when the node appears; aiming, heating and cooling change their glow strength
without compiling a new feature variant during interaction. Zero energy retains
the ordinary unhighlighted appearance. Rare-resource shader effects remain
separate and unchanged.

Leyline tiles now assemble the same unindexed vertices, normals, colours and UVs
in batches. Grounding, gaps, branches, building suppression and sampled-terrain
cache invalidation retain their existing rules. This changes neither geography
nor save data and introduces no production tuning values.

## Nearby ambience — INT-04B, 7 September 2026

The [ground and ambience slice](../prototype/footsteps-ambience-2026-09-07.md)
reads each existing profile's row-major biome surface for quiet air, foliage,
reed or exposed-stone textures. This adds no placement input, geography, resource
ledger or site marker. Marsh brushing never asserts actual water contact.
Existing enclosed shelter attenuates the outside; trials and disabled play are
silent. A world identity change or restore clears the previous place's sound.
Rare-site discovery below retains its separate finite-stock eligibility.

## Reading existing discoveries — INT-02A, 7 September 2026

The [exploration storytelling slice](../prototype/exploration-storytelling-2026-09-07.md)
reuses the V5/V6 smithy's native source, impact and discovery associations for
small inert craft remnants and worn path margins. Existing walls, source,
walking strip and resource positions remain authoritative. The ordinary ruin
body carries a short observational target line without a gathering action.
New remnants participate in the same grounding, excavation and building-hide
lifecycle as the established ruin kit.

Five rare-site clue families now use empty husks, slack shells, scars and host
grit rather than miniature collectible cores. Their native clue points stay
fixed. Periodic discovery sounds read the site's finite resource records:
unloaded stock can still signal a find; complete depletion silences the cue.
Empty scenery persists, and no presentation refresh can refill a resource.
Native work-stage descriptions feed the existing compact gathering display;
the pack's optional material guide links each component to its actual recipes.

## Wide Frontier successor — D-032, 6 September 2026

The owner-approved [Wide Frontier work item](../prototype/wide-frontier-intensive-2026-09-06.md)
introduces a finite `frontier_v6` measuring 1,024 × 1,024 m with 96 vertical
cells. Broad region identity is composed separately from local relief, so
wooded hills remain wooded. Four supported home clearings and a quiet starter
valley accompany larger biome interiors. Existing finite habitats, rare finds,
caves, Cataclysm scars and the accidentally struck old smithy remain the
discovery vocabulary. This is a size/composition expansion, not new extraction
or resource rules. Implementation evidence remains in the linked work item.

The exact former live inputs are frozen as `worldgen-frontier-v5.json`, and
V1–V5 helpers retain their prior behaviour. Only V6 reads live `worldgen.json`.
Existing saves retain their profile, seed, finite stock, partial work, terrain
edits, buildings and machine associations; no existing world is enlarged.

Normal fresh games select a random 31-bit seed; a chosen seed supports replay
and sharing. Generation is deterministic for `(profile, seed)`, not a curated
list of maps. Continue restores saved identity before generating terrain.
Review scenes retain their deterministic exported seed.

Loose materials, gear, selected pages and death packs now save beside finite
resource state and the existing identity. Successful load replaces only that
world's recorded drops; explicit successful New World creation clears its old
set. No generation profile, terrain, placement input or source yield changes.
See the [INT-07A persistence contract](../prototype/loose-drop-persistence-2026-09-07.md)
for old saves, validation and trial boundaries.

V6 exports `home_sites`, `starter_quiet_radius_m`, `hostile_boundary_m` and
`starter_first_siege_night`. Native composition protects complete ordinary and
later-era patrol segments from the quiet catchment, including a gathering-noise
buffer. V6's first eligible home siege is night three; older profiles retain
night two. Players may leave the heartland whenever they choose. This is
opening pacing, not invulnerability or a requirement to wait thirty minutes.

Nearby exact terrain now retires distant unedited mesh, collision and samplers
and rebuilds from authoritative voxels on return. Excavated chunks and their
seam neighbours remain pinned to preserve visible edits; resource records keep
partial work and depletion independently. The native full volume still exists,
so this change does not provide infinite generation or constant total memory.

The [INT-07B preparation pass](../prototype/world-performance-2026-09-07.md)
retains that exact world. V6 cave noise caches repeated lattice work within one
column, preserving arithmetic and thresholds; V6 clearance skips an intermediate
walk whose parents were discarded before the existing final walk. Historical
helpers and tuning inputs remain frozen. Neither optimisation consumes RNG or
adds persistent state.

Nearby chunks retain the same payload/sampler/mesh/cover/collision work and
publication boundary; INT-07E above now splits collision preparation from
publication and queues cosmetic trace refresh. Configure collision flags before
uploading faces. A streamed leyline tile may keep its existing mesh when the exact terrain chunk
identities over its complete sampling footprint are unchanged. Those transient
integer IDs retain no nodes or samplers; replacement chunks invalidate them.
Building and full refreshes always rebuild. Bounded stage diagnostics explain
preparation stalls without changing the established radii or detail.

## Pressure workshop successor — D-031, 6 September 2026

The [owner-directed leyline/resource graphics pass](../prototype/leyline-resource-visual-2026-09-06.md)
changes presentation within existing profiles: exposed intervals receive dark
branching surface fissures and contained light; rare hosts gain material and
stock-state detail. It changes no native trace points, exposure flags, terrain,
resource identity, quantity or collision. Buried/broken intervals remain absent,
and building/excavation refresh suppresses unsupported surface geometry. The
finite source's appearance reads the ledger and cannot replenish it.

Preserved **`frontier_v5`** worlds retain a finite 512 × 512 m landscape. Ordinary
resources, existing rare hauls and approaches reuse the frozen V4 composition.
One Ventlung-linked ruin is identified as an old **pre-cataclysm blacksmith's
smithy**. A small asteroid struck its hearth margin, accidentally sending an
exposed trace through a pressure pocket. This is destroyed old civilisation;
only the player constructs a working extraction device and forge.

V5 exports one `pressure_pockets` record with a stable ID, native position,
approach, work position and ruin/strike/trace/discovery associations. It contains
no stock. The contraption ledger owns the finite 24 strokes against the exact
profile, seed and generated ID. Inspection and geometry cannot initialize or
replenish them. There are four impact records, ten traces and six ruins; the
small smithy strike adds no new region, threat, era or raw resource.

`worldgen-frontier-v4.json` freezes the previous live inputs byte-for-byte;
V4 helpers remain separate from the V5 composition. V4 and earlier saves gain
no pressure pockets or rewritten geography. V5 now uses `worldgen-frontier-v5.json`;
the D-032 successor is the only profile using live `worldgen.json`.
The generation matrix verifies 64 V5 seeds and 16 complete historical profile/
seed fingerprints. [Rules, tuning and evidence](../prototype/pressure-workshop-2026-09-06.md).

## Implemented cataclysm composition — D-030, 6 September 2026

The preceding **`frontier_v4`** retains the finite 512 × 512 metre extent,
48 vertical cells and three discovery regions. The owner-approved [intensive](../prototype/cataclysm-world-intensive-2026-09-06.md)
makes extreme augmentation the shared cause of the land, surviving structures,
creatures and craft. Its [world premise](../world-premise.md) is accepted;
the separately approved D-031 scope above brings forward one extraction loop.

Native generation composes three regional impact anchors, curved connecting
traces, irregular regional margins, shallow bowls, broken rims and trace channels.
Six supported ruins link that history to existing opportunities: five first
primary rare discoveries and the Forge gate. A constrained Forge foundation is
reserved first; regional dwellings prefer homeward ground. Complete foundations
are at least 10 × 10 m with gentle shoulders and a central three-metre walking
strip. Arrival routes and separate short discovery routes avoid the authored
wall margins. Rare work circles exclude ruins and impact fragments. Existing
hauls, site-count budgets, class-independent gathering and era gates are unchanged.

Stable impact, trace and ruin IDs use independent deterministic seed streams.
Godot receives `impacts`, `leylines`, `ruins`, regional history tags and a row-major
`augmentation_field` normalized to `[0,1]`. The three main traces connect the
impacts; six local branches connect ruins. Segments can be broken, buried or
exposed. The field guides local presentation and protects the starter clearing;
it is not a power meter, damage field or source of stock. Ruin records include
their cause, damage direction, foundation, entrance and linked discovery route.
Simulation owns those relationships; Godot owns their grounded authored meshes.

The exact former live V3 inputs are now frozen in `worldgen-frontier-v3.json`,
with its placement helpers isolated from V4. `legacy_v1`, `frontier_v2` and
`frontier_v3` retain their original geography, resource identities and quantities.
Profile-less saves still mean legacy; loading an old profile does not insert
ruins, impacts or new terrain. V4 now uses its dedicated frozen snapshot.

The native `cataclysm-world` target passes 25,959,555 checks across 64 seeds,
including exact complete fingerprints for all three historical profiles on four
baseline seeds, deterministic regeneration, routes, foundations, finite stock,
clear workplaces and progression supplies. Existing native generation and
simulation suites also pass. The [native review](../art/cataclysm-generation-2026-09-06.md)
records tuning, evidence and limits; integrated visual, save, collision and frame
time review is tracked by the intensive separately. Generation tests do not
certify the final visual finish or every possible seed.

## The Strange Frontier — D-029, 6 September 2026

The previous `frontier_v3` profile introduced 512 × 512 metres with broad
Rootvault Wildwood, Lantern Fen and Glasswind Uplands regions. Regional masks shape the terrain,
transition areas and ordinary population before finite rare sites are composed.
Every supported seed has reachable opportunities for all five rare finds;
exceptional sites are optional. Starter supplies, material habitats and the Forge
remain nearer home. Extra area does not multiply population at the old density.
See the [approved work item](../prototype/rare-world-intensive-2026-09-06.md).

At that intensive, both older profiles were frozen. `frontier_v2` reads
`worldgen-frontier-v2.json` through `worldgen_frontier_v2.inc`; `legacy_v1`
retains its existing snapshot. Profile-less saves still mean legacy. Loading
either profile does not add new sites or resize terrain. Recipes and fixtures
remain available, including rare components from completed repeatable trials.

Region IDs, site-instance IDs and resource IDs are deterministic and independent
of scene creation order. A rare record carries separate presentation labels,
properties, work stages and a use preview. Basic contextual work is sufficient;
each finite first haul supports its useful recipe without another unlock.

For V3 and V4, the complete native voxel field remains authoritative. Godot creates
nearby exact mesh/collision in stages over a coarse distant surface. Travel
activation is bounded; edited ground and explicit `Terrain.ensure_area` calls
preserve exact collision for restored positions and review teleports. Resource
records persist separately from nearby scenes: unloading retains partial work,
depletion removes the record, and saving includes distant and future-era records.
Legacy and V2 retain their eager terrain/resource creation path. Stream distances
and work budgets live in `game/art/strange_stream.tres`; generation values and
their purposes live in each profile's selected worldgen table.

## Approved resource habitats and world identity — 6 September 2026

The [world intensive](../prototype/world-intensive-2026-09-06.md), D-027,
introduced three complete resource habitats in `frontier_v2`, retained in its
successors. It keeps the weathered valley and composes finite deposits on
reachable, supported terrain: the Shellcut Escarpment provides raw slate and shellstone, Rustwater
Hollow provides clay and weaving reeds, and Resinheart Grove provides logs and
independent corkbark deadfall. These are source ingredients, not extra entries
in the finished construction catalogue. Trial caches use these same ingredients.

World identity is `(generation_profile, seed)`. Saves without a profile select
`legacy_v1`; unknown profiles reject before mutable game state changes. The
pre-intensive algorithm is frozen in `sim/src/worldgen_legacy_v1.inc`, with
all its placement inputs in `data/tuning/worldgen-legacy-v1.json`: terrain,
caves, biome and density ordering, node definitions, packs, guarantees,
landmarks and elite selection order. Live combat or frontier tuning cannot
move a legacy world's resources, terrain or encounters. The engine's generation
cache, mesh queries and node/biome definitions select the same profile. The
historical tuning-driven `generate` function remains for controlled probes;
runtime uses validated `generateProfile`.

Each habitat is committed only when its complete resource cluster and approach
are valid. Native terrain is preferred; the defined meadow-edge fallback keeps
all three material ambitions available when a natural biome has no safe site.
A surface flood search reserves an open, supported route from spawn with at
most one block of rise per cell. Deposits avoid that route, existing resources,
the starter resource ring, the gate and landmarks. Definition order does not
change placement: habitat IDs, source IDs and fixed seed salts select a stable
order. New resource instance IDs identify the habitat, source and deposit;
legacy IDs preserve existing scene/save names. A presentation label is carried
separately from the raw material family.

The bounded `worldgen.json` habitat tuning has these purposes:

| Setting | Player effect |
| --- | --- |
| `radius_m` | Keeps each place a small recognisable gathering composition (12 m quarry/fen, 13 m grove). |
| `min_distance_m`, `max_distance_m` | Makes discovery a walk from home while remaining reachable (65–145 m). |
| `resource_spacing_m` | Leaves working and movement space between finite deposits (2.5 m quarry/fen, 3 m grove). |
| `max_surface_step_cells` | Limits the guaranteed approach and resource footprints to ordinary walkable rises (1). |
| `resources[].count` | Sets finite initial building supply (8 deposits of each of the two sources). |
| `seed_salt` | Keeps each site's seeded variation independent of definition order; it is part of profile identity. |
| `biome`, `fallback_biome` | Prefers a resource's natural setting while retaining a reachable fallback. |
| Node `units`, `units_per_harvest`, `drive_presses` | Controls total supply and the pace of contextual work. No new tool or elemental gate. |

`HabitatSites` adds shared, noncolliding authored accents, shallow moving fen
water and restrained foliage/mote movement. The actual resource nodes retain
the harvesting/collision authority. Decorative placement keeps approaches and
work areas clear and refreshes after excavation; rebuilding a profile replaces
the old habitat presentation. Construction material art is shared with previews
and the catalogue; see [construction](construction.md).

Verification: `make -C tests/sim world-intensive` checks complete pre-intensive
world fingerprints for seeds 1, 7, 24 and 91, then reachable, grounded habitats,
stable resource identities, clear approaches, starter guarantees and the
material/form matrix across 64 seeds (including widely separated large seeds).
It passes 595,376 checks. The original D-027 review of
`game/tests/world_intensive.tscn` on its then-default world passed 5,939 headless
checks covering profile switching, missing/unknown profiles,
resource grounding, finite/partial harvesting state, depleted resources,
excavation, placed materials and atomic disk save restoration. Optional rendered
execution writes player-height daylight/dusk views, approach sequences and
frame measurements under `build/intensives/world/`. The fixture also exercises
contextual work for all six source types and requires visible shallow fen water.
The final rendered pass adds malformed-save rejection checks and 49 gameplay
captures, passing 6,043 checks with no failures. Matched dense-grove median/p95
frame time changes are +0.06%/+1.82% on the review machine; the larger canopy
increases primitive count and still requires lower-spec hardware review.
See [habitat review](../art/world-habitat-intensive-2026-09-06.md).

No swimming, flooding, infinite resource regeneration, new discovery currency,
additional recipe gate or timber-demolition change belongs to this intensive.

Owner-approved presentation continuation, 5 Sep 2026: the weathered view adds
deterministic habitat patches of shrubs, fern beds, short rotten deadfall and
stumps. Placement uses existing biome and surface data, samples collision
triangles and excludes steep/unsupported footprints, resource work areas, the
spawn clearing and progression sites. Chunk rebuilds regenerate the same cover
from the edited surface. No generation guarantees, resource yields or save
schema changed. Existing landmark meshes gain worn edges and inlays; nearby
resource trees present as bare snags to open sightlines while retaining their
identities, collision and wood. This is presentation, not new world content or
rewards. [Details](../art/codex-frontier-continuation-2026-09-05.md).

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
- **Danger rings:** the rings give a pack its teeth by distance (a size
  bonus, an elite chance); they no longer touch density. Density is the
  biome's own (Wave 7 slice 1, 4 Sep 2026): each biome's `pack_density`
  is what it is wherever the biome lies, so the meadow is a straggler, the
  forest edge has stragglers, and the fen, the wastes and the caves are
  dense from day one - the danger is a place with a visible edge, not a
  radius. Every hostile pack carries its biome to the engine.
- **Landmarks (Wave 8 slice 2, the lock):** `worldgen.json` `landmarks`
  places one landmark per def deep in its biome - the surface cell
  nearest the biome's centroid among those at least
  `min_distance_from_spawn_m` out, uncarved and unoccupied - carried to
  the engine with its look (`landmark.gd`: a cairn with a standing stone,
  a ring of drowned slabs, a black rift with an ember light). The cairn
  takes the Tyrant's heart and the altar the Warden's eye; the rift
  waits.
- **Biomes as material (Wave 8 slice 2):** the forest stands in pines,
  the fen in bog oak, the wastes in ash snags - node types of their own
  (`pine`, `bog_oak`, `ash_snag`), felled like any tree, each paying a
  timber family of its own colour. The meadow and the hills keep the
  plain tree.
- **Foreign routes (Wave 8 slice 3, the mingling):** every patrolling
  pack also knows the nearest den of another biome within a patrol and a
  half (`has_foreign`, `foreign_x/z`, `foreign_biome`); once an era's
  patrols cross biomes the night walks it there instead of toward the
  spawn, so the families literally mingle.
- **Night patrols (Wave 7 slice 1):** a biome marked `patrols` (the
  forest, the fen, the wastes) gives each of its packs a route:
  `patrol_length_m` from its den along the line to the spawn, stopping
  two cells short of the doorstep radius. The engine walks the pack out
  over the first half of the night and home over the second, so dusk is
  the hour you meet the wastes coming the other way.
  Runtime patrol height follows the surface at the current horizontal route
  position, rather than interpolating endpoint heights through hills. Each
  surface member grounds its body footprint on current terrain support, including
  excavation; cave members keep their interior floor. This changes no generated
  den, route, density or save identity. [INT-02C evidence](../prototype/frontier-population-2026-09-08.md).
- **Engine:** the sim also derives the render/collision geometry
  (`world_mesh`: per-chunk visible-block centres by kind plus exposed-face
  triangles), so the engine builds one MultiMesh per kind and one trimesh
  body per 16×16 chunk without re-walking a million blocks in script.
  Chunks exist so the digging slice can rebuild one patch, not the world.
- **The expansive pass (4 Sep 2026, Wave 6 slice 4):** the rim - over
  the outer `rim_width_cells` the land climbs up to `rim_extra_scale`
  blocks more, ridged by the massif noise, a ring of mountains around the
  valley and never a wall; the spawn clearing stays inside. Ground cover
  per biome (`ground_cover.gd`: tufts, flowers, ferns, reeds, dead grass)
  in one MultiMesh per chunk and kind on the surface blocks, placed by a
  hash of the cell. Tree silhouettes by biome: the broadleaf, the
  forest's pine, the wastes' snag. The mood dial (`biome_mood.gd`) now
  carries each biome's sky colours and aerial haze.
- **Day and night (4 Sep 2026, Wave 6 slice 5):** the world keeps a
  clock (`daycycle.h`, `world.json` `day`): a twelve-minute day in four
  phases, the night the last third. The mood dial darkens the sky, the
  fog and the sun toward the night's blue and swings the sun over the
  valley; every mob wakes from further and packs stay awake further; a
  shelter mends you faster through it. **Owner revision, 5 Sep 2026:** the
  original outdoor cold health drain is disabled for now (exposure rate zero).
  Night and dusk notices no longer warn of cold damage; the other night
  settings remain unchanged.
- **Felling and cracking (4 Sep 2026, Wave 6 slice 1):** any node may
  want `drive_presses` of E per harvest. A tree is six presses that lean
  it further from you, then the whole tree comes down from the base and
  pays fourteen wood at once, leaving a stump (`resource_node.gd`
  `_fell`); a boulder cracks a chunk of three fieldstone off every third
  press and rolls over on the last. Meadow trees are sparser and bigger.
- **Guarantees kept (D-003):** safe flat meadow clearing, minimum
  wood and stone within the near radius, packs off the doorstep, the
  gate ≥ 70 m out in the wastes, all held across seeds by tests. **Iron
  is a walk (4 Sep 2026, Wave 6 slice 2):** no iron is guaranteed near;
  three veins are guaranteed within `far_radius_m` (ninety metres),
  placed beyond the near radius when a seed comes up short, so the first
  forge is a journey into the hills and back.

**Seams (3 Sep 2026, D-021):** `stone_seam` nodes (three guaranteed inside
the near radius, densest in the hills) are worked with a `tool_item` (the
timber wedge) over `drive_presses` presses, or at once by a heavy blow.
*Look (4 Sep 2026, the stone accomplishment pass):* a seam is a fracture
line through the exposed stone - a dark torn band with a pale vein
wandering along it, three cells long along a row or a column, flush with
the blocks it crosses and stepping with their surface heights
(`prop_mesh.gd` `_strip`, the node sampling `height_at` for the cells it
crosses); the ore veins are the same line in the metal's colour with a
knuckle of ore where it breaks the surface. The wedge sinks and leans as
it is driven; a split throws a fist of stone off the seam.
Boulders pay fieldstone by hand; iron is hands' work; the alloy ores keep
`heat_to_work` and are worked while hot or once cracked. Cracked strata
pay split stone.

**Fire-setting (3 Sep 2026, D-020):** hands dig soil only. Stone wants a
campfire against it (`construction.json` campfire, laid in timber or
charcoal) and then cold: the blocks and nodes within `fire_setting.reach_cells`
of a burning fire are hot for `hot_seconds`, cold landing within
`quench_radius_m` cracks every hot block whose heat met its kind's
`heat_to_crack`, and cracked rock digs by hand at `dig_seconds`. Nodes carry
`heat_to_work` (boulders and iron 1, the alloy ores 2). Cracks are saved;
heat is not. See [progression-eras.md](progression-eras.md).

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

## Implemented: the bigger world and the fen (3 Sep 2026)

The map is 320 cells a side since Wave 6 slice 3 (4 Sep 2026; from 224
and 160 before it; 400 chunks), with the height and moisture noise slowed
so every biome and hill is broader, and the danger rings pushed out to
110 m and 220 m, the gate past 160 m. Before that it was 224 cells a side
(from 160; 196 chunks) with the danger rings
widened to match (75 m, 150 m) and the gate at least 100 m out. A fifth
biome, **the fen**, takes the lowest wet band (heights start at the base
height, so `height_max` 15 with `moisture_min` 0.55; listed before the
forest so wet low ground is fen and wet high ground forest), on a new
`marsh` surface with its own mood. Four families joined, all data
(`world.json` enemies with `tint`, `size_scale` and `immune_statuses`;
`combat_realtime.json` behaviours `lurker`, `skirmisher`, `knight`):

| Family | Home | Nature |
| --- | --- | --- |
| Bog Lurker | fen | slow, thick, bleed-proof: a wall you walk around |
| Marsh Wisp | fen | fast skirmisher that keeps six metres and pecks |
| Cinder Wisp | wastes | burning skirmisher, ignite-proof: fire resistance matters outside the trial |
| Hollow Knight | wastes | armoured melee with a long windup, ignite-proof: cold and bleed are the answers |

The owner's frame: "always worthwhile making the world larger to allow
for more mob variants". Behaviours are data, so a family is a few lines
and a look.

## Implemented: life beyond hostiles (3 Sep 2026)

- **The peddler** stands by the order board at the spawn clearing and
  sells for kinds and changes one kind for another (`crafting.json` `market`, D-023 slice 3): a Preserving
  Catalyst, charcoal, ore, wood. The first thing the currency buys; steep
  next to gathering so infrastructure stays the dependable route.
- **Valley elk** graze the meadow and the forest: the `grazer` behaviour
  `flees` (the state machine turned around: within aggro range they bolt,
  beyond give-up they settle, they never bite) and they drop hide.
- **Birds** wheel over the trees near spawn (`flock.gd`), presentation
  only, so the sky is never still.

## Retired: encroachment (built 3 Sep 2026, D-018; retired 4 Sep 2026, D-024)

The owner (4 Sep 2026): nests were "not rewarding" and did not "feel
natural to the world"; mob AI behaviours are to be reassessed later. The
module, the engine scripts, the tuning block and the era flags are gone.
What follows records what was built, for that reassessment.

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

The slices that were to follow (burrowers trenching the ground between
nest and home, the shut-door siege) are shelved with it.

## Open questions

Owner's next art review, 5 Sep: the GDExtension mesh view accepts an optional
engine palette and supplies shared linear vertex colours plus a stone-detail
weight. Each lattice corner averages the exposed solids among its eight cells;
face centres retain more of their own material. The stencil stays within the
existing dig/chunk invalidation halo. Geometry, source-cell picking, generation
and save data are identical with or without a palette. Tests compare shared
colours across materials/chunks before digging, after a corner dig and after
restoration. Decorative stones now use three lower, less frequent slab forms.

The owner's follow-up surface-detail pass adds decorative stone fragments and
repairs ground-cover distance fading: each MultiMesh origin is now centred on
its own plants, with local instance transforms preserving their world positions.
The sampler caches triangle coefficients using local offsets to preserve precision
at map edges. Tree presentation shares 48 seeded mesh variants per biome;
resource positions, individual rotations, collisions and save anchors stay intact.
No generator, harvest yield or save schema changes accompany this optimisation.

**Owner-approved continuation, 5 Sep 2026:** the normal sandpit now presents
the same generated/save voxel field through the softer terrain and an earthy,
less cartoon-like palette (revised D-013). Decorative plants sample the actual
collision triangles, and seams/ore ribbons follow those surfaces, including
nearby cave floors. Unsupported ribbon sections stop at holes; picking follows
the ribbon. A nearby dig or restoration refreshes their geometry without
moving the resource's saved anchor or resetting its harvest/crack state.
The source voxel field, yields and unlocks stay unchanged. See
[evidence and limitations](../art/codex-weathered-frontier-2026-09-05.md).

**Codex experiment, 5 Sep 2026 (OpenAI, not Claude):** optional map fields
`height_warp_metres` (default 0, finite/non-negative) and
`height_warp_frequency` (default 0.018, finite/positive) bend the height-noise
coordinates and control the breadth of those bends. Zero amplitude preserves
existing generation. A copied fresh-world fixture tries 24 metres of warp
with stronger relief; it never loads player saves. Normal tuning is unchanged.
Separately, `--faceted-look` presents the existing solid field as rounded
facets with matching collision and exact source-voxel picking. It does not
change the generated voxel field or saved excavation representation.
See [Codex's report](../art/codex-aesthetic-intensive-2026-09-05.md) for controls,
generation checks and the presentation's resource-grounding limitations.

The subsequent `--crafted-look` candidate preserves those triangles and
collision, adds shared occupancy-gradient lighting normals and branching tree
presentation, and passes a short actual-controller slope/chunk traversal.
See [review and measured limits](../art/codex-crafted-frontier-2026-09-05.md).

- How class halls are signposted.
- When outposts become mechanically worthwhile.
- Whether cave dark needs its own light rules before torches exist
  (D-013's "menace is told by light" suggests yes).
