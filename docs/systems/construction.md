# Construction System

## Common building loads — INT-03D, 8 September 2026

Ordinary timber, field/split/dressed stone and all eight habitat ingredients and
finishes now have explicit 240-unit hauling caps. Each chest holds 960 units
shared across families. The measured 188-wood six-metre home plus workshop and
staging chest needs 225 wood, fitting one timber load. Ores, special items,
equipment, costs, yields, machine buffers and progression retain their rules.
Pickup/withdrawal caps never clamp crafted output, recovery or existing saves.
See [the measured candidate and ownership checks](../prototype/building-loads-2026-09-08.md).

## Corner seating and local placement refresh — INT-03C, 7 September 2026

Station previews and paid placement share a pose that clears adjacent wall skins
with the unchanged 0.96 × 2 × 0.96 m body. The closest horizontal offset stays
within half a registry cell; genuine wall-through-body, beam and ceiling
obstructions still refuse without spending a kit. Existing vertical contact
tolerance remains. `station_look.gd: placement_contact_gap_m` adds 0.002 m of
wall clearance to avoid exact-contact physics noise. Saved positions and station
keys retain the final pose; older stations are not moved on load.

Placed/removed pieces now restrict deferred scenery clearance to their changed
bounds. Existing terrain support changes still invalidate affected leyline meshes;
explicit save/generation refreshes remain complete. No native ownership, terrain,
cost, refund, source stock or schema changes are introduced. All seven fixture
types pass actual placement and restart checks, but the owner's original
disappearance remains unreproduced. [Evidence and limits](../prototype/placement-reliability-2026-09-07.md).

## Complete building restoration — INT-07C, 7 September 2026

Save restoration first imports the saved rules into an isolated validator and
places every recorded piece in its native structure registry. An unknown shape,
invalid lattice slot, overlapping footprint or out-of-range integer cell rejects
the complete candidate before changing live possessions, terrain or buildings.
This uses the existing D-017 lattice, not new-placement terrain, payment or unlock
checks: older legitimate buildings remain loadable. Schema 2 and door defaults
are unchanged. A damaged current file can recover its intact previous checkpoint;
the player sees which file was recovered. See the
[session reliability evidence](../prototype/session-reliability-2026-09-07.md).

## Reliable placement and returning home — INT-03B, 7 September 2026

New placement checks every element in the native shape footprint against the
current edited terrain, including the far end of long or tall pieces and full
pieces anchored on the fine grid. The existing exposure rule still applies to
each element: mine-wall lining and exposed edges remain legal. D-017's ordinary
piece-to-piece overlaps continue to use the native lattice rather than physical
mesh intersection. Loading does not revalidate or remove existing buildings
against these new-placement checks.

Ordinary station kits now check their unchanged body against player-built walls,
beams and ceilings as well as other props. Horizontal slabs on the station's
supporting plane retain their intended floor contact, including fine-grid floors.
The existing body dimensions and neighbour contact tolerance remain unchanged;
a refused placement spends no kit. This resolves INT-03A's built-ceiling limit.

Schema-2 block records optionally carry a boolean `door_open` for doors. The
whole payload validates this field before inventory, player pose or live nodes
change. Restoration assigns the state once and moves the visible leaf and its
collision together, retaining the saved axis and hinge. Repeated loads do not
toggle doors or pay for them again. Old records without the field retain their
historical closed default. Doors still seal shelter open or shut; an open leaf
remains a physical interaction target beside the passable doorway.

The focused terrain, station and door checks pass (174, 84 and 467 checks).
These establish the placement and persistence contracts; owner comfort review
remains pending. No new tuning, schema version or construction form is introduced.
The D-018 timber-demolition conflict stays outside this slice.
[Scope, verification and limitations](../prototype/home-placement-persistence-2026-09-07.md).

## Home/workshop usability — INT-03A, 7 September 2026

Ordinary station-kit previews use the placed station's shared current-tier mesh
and existing 0.96 × 2 × 0.96 m body for prop/station fit. The art keeps its ground
pivot, including all four rotations; retained forge selections refresh after an
upgrade or load. The body itself, payment and stable station identity are unchanged.
This corrects the earlier oversized generic preview and neighbour rejection.
INT-03B above adds clearance against player-built geometry while retaining the
same body and intended floor contact.

Retained corner posts refresh their material from the native adjoining-family
result. Catalogue door/post/beam shading uses the same material role as placed
pieces and world ghosts. Native joins, dimensions and ownership remain unchanged.

The player measures an actual walkable step surface, then sweeps the existing
capsule at the required rise. A tight ceiling need only fit that rise, while the
existing 0.55 m maximum and 1.92 m capsule remain. The home guide's optional detail
recommends three wall panels above the walking floor and a flush doorway; this is
practical headroom advice, not an additional shelter rule. Complete paid examples,
walking checks and limitations: [work item](../prototype/home-workshop-usability-2026-09-07.md).

## Pressure feeder — D-031, 6 September 2026

The feeder is one additional kit in the existing picker. Its model, preview and
collision bounds share the same local art. E opens attach/load/charge/wind/start/
pause/cancel/collect controls. A Stormglass lever can request the same bounded
batch; the signal supplies no energy. The hopper, tension drum, pressure chamber
and output tray show the separate owners of materials and work.

[INT-06A](../prototype/workshop-usability-2026-09-07.md) separates visible clay
and fuel shares using the actual recipe/fuel tables; fuel alone no longer looks
like clay. The two existing connections use distinct matte finishes while
retaining their paths, radii and collision. A cached readout refreshes on the
existing half-second cadence and meaningful inventory/connection changes.
Clock-only visual updates reuse the readiness sample from the actual tick.
These representations add no item owner, light, collider or production rule.

Attachment requires a physically present, player-built basic forge within 8 m;
an optional pressure pocket must also be within 8 m. A global station unlock or
old decorative hearth is insufficient. All four device/forge feet and both short
connections are checked against actual geometry. Changed/missing support, moved
forge, obstruction, trials or inactive distance pause the exact reserved cycle.
Reattaching requires cancellation or completion first.

Station saves record `player_built` and stable `station_key` separately from
their global recipe unlock. Old saves without these fields retain their stations
but grant no new physical ownership evidence; placing another forge supplies it.
The world-scoped schema-2 machine ledger stores source stock, attachments, hopper,
tray, drive, escrow, queued cycles, exact fractional progress and explicit pause.
SaveManager validates it against the saved profile/seed before changing player
or world state. Missing V5 ledgers reject; context-free historical fixtures remain
loadable in older profiles. Source initialization occurs only on fresh world
binding, and repeat binding of the same identity preserves stock.

X or the panel dismantles once, returns all owned contents and intact rare
cores, applies existing common-frame refunds and visibly vents unused drive.
It never refills the source. [Work item and tuning](../prototype/pressure-workshop-2026-09-06.md).

## Rare-resource fixtures — D-029, 6 September 2026

The Strange Frontier adds six crafted fixtures through the existing kit picker:
Lanternheart Lamp, Cargo Winch, ordinary Winch Landing, Stormglass Lever,
Magnetic Sorter and Ventlung Bellows. They are workbench products, not additional
wall materials or structural forms. Placement tests their full authored bounds;
E opens their contextual controls and X dismantles them through the normal build
interaction. Previews, catalogue cards and placed fixtures share the same art.

The cargo winch has two supported fixed endpoints, one clear span and one
authoritative inventory. Winding provides energy; a linked Stormglass pulse
requests a trip. Blocked spans pause without losing cargo. Removing an endpoint
recovers or recalls the same cargo; saving preserves exact travel progress.
Signals do not supply energy. The sorter separates only hand-loaded items using
the configured ferrous property set. Bellows apply the existing impact response
to a nearby work target. There is no offline or trial-time machine production.

Dismantling returns every rare core and the normal fraction of common recipe
inputs, plus stored contents. All quantities, links and transfers are native
simulation state validated before save restoration. Limits and their player
purposes are in `data/tuning/contraptions.json`.

**Status:** Accepted direction; prototype details provisional  
**Related decisions:** D-001, D-003, D-005, D-008

## Purpose and player fantasy

Construction lets the player express progression physically. The game supplies materials, shapes and functional objects; the player decides whether an enchanting space becomes a tower, cellar, library or something unforeseen.

Creative limitation is intentional. The player begins with a narrow vocabulary and earns new materials, cuts and finishes through exploration, skill and facilities.

## Prototype scope

- one consistent grid size;
- six to eight interoperable shapes;
- wood and one stone or metal-clad material family;
- place, preview, rotate and remove;
- no structural-integrity collapse;
- storage consumption by material family;
- mouse and keyboard only.

Suggested initial shapes:

- full block;
- half slab;
- beam/post;
- stair;
- roof slope;
- 45-degree wedge;
- diagonal wall;
- inner or outer transition corner.

Curves, freeform terrain carving, large blueprints and physics-based destruction are excluded.

## Core rules

Owner-approved bounded expansion, 6 September 2026: the
[world material intensive](../prototype/world-intensive-2026-09-06.md) adds eight
finished families: Slate, Shellstone, Rustclay Brick, Woven Reed, Resinheart,
Corkbark, Vitrified Basalt and Cinderglass. Their raw ingredients are not catalogue
families. Only Light Wall Panel and Fixed Glazed Window are new forms; both occupy
the existing wall face, seal shelter and block movement/projectiles. The frame
belongs to each crafted product. `covering` admits light panels and pitched roofs;
every previously eligible pitched-roof family retains that trait, and
`stonecut_blocks` remains the unlock. Reed and cork have `only_for_trait: covering`
and cannot become ordinary blocks, doors or storage. `glazing` similarly restricts
Cinderglass to fixed windows. Other costs/refunds/addresses remain unchanged.
See the [art and verification report](../art/world-material-intensive-2026-09-06.md).

1. A harvested material is stored as a family, not as every possible placeable geometry.
2. Selecting a family opens the shapes currently unlocked for that family.
3. Placing a shape consumes an amount derived from its volume or standard recipe cost.
4. Removing a player-placed shape returns a configurable portion of its material.
5. Placement uses forgiving snapping and clearly previews invalid collision.
   Pieces are addressed by **lattice element**, never by "which cell and
   where inside it" (D-017): a block occupies a cell, a wall or floor a
   face two cells share, a post or beam an edge four cells share. The one
   placement rule is *the nearest free element of the piece's kind to the
   point you are looking at*; orientation comes from the element, so only
   oriented blocks turn with R. Two pieces conflict only when they want the
   same element, which is what lets a cube fill either side of a wall, a
   post stand where walls meet, and a beam ride a slab's rim.
6. Functional stations operate without requiring decorative architecture.
7. More advanced craft skills and facilities may unlock additional cuts and finishes.

## System relationships

| Receives from | Receives | Supplies |
| --- | --- | --- |
| World | Raw material families and building locations | Player-created shelter, workshops and landmarks |
| Crafting | Refined materials, advanced cuts and functional stations | Demand for bulk outputs and infrastructure |
| Progression | Tool, skill and facility unlocks | Visible evidence of capability growth |
| Transport | Access to materials from distant outposts | Stations, roads and route infrastructure |

## Tunable parameters

| Parameter | Player effect |
| --- | --- |
| Grid size | Balance between Minecraft-like constraint and detail |
| Placement range | Building pace and need for scaffolding |
| Rotation increments | Shape flexibility and interface complexity |
| Material cost per shape | Construction ambition and resource demand |
| Removal refund | Experimentation freedom versus commitment |
| Shape element | Which kind of lattice element a shape occupies (block, wall, floor, post, beam) |
| Snap tolerance | Precision versus frustration |
| Unlock skill level | Pacing of architectural vocabulary |

Grid size, placement range, per-shape material cost, per-shape element and
removal refund are
data in `data/tuning/construction.json`, loaded by the `sim/` library; the
engine layer reads them and applies placement payment and refunds through
the rules library rather than computing them in scene scripts.

## Implemented: the building lattice (Wave 4 slice 1, 3 Sep 2026)

The owner's playtest showed four placement failures that were one bug: the
old scheme chose the *cell* from the camera ray and the *position inside
the cell* from the rotation key, two independent choices that only agreed
by luck. The replacement is `sim/lattice.h`:

- **Elements.** Every element of the cubic grid has one canonical address:
  a volume is its cell; a face is the cell on its positive side plus the
  normal axis (the face on cell *c*'s min-x side is `face x @ c`); an edge
  is the cell whose min corner it leaves plus its axis. Shapes declare the
  element kind they occupy (`element` in `construction.json`).
- **The rule.** `lattice::candidates(slot, point, normal)` ranks the
  elements of a kind around a surface hit by distance to the crosshair,
  after nudging the point 2 cm along the surface normal so a floor or a
  wall face resolves to its open side. The engine filters that list by
  what only it knows — the sim's occupancy, terrain solidity (a block
  cannot go into rock; a face with rock on both sides has nothing to stand
  against, but a face between rock and open air is a mine lining), and a
  physics overlap against props, stations and mobs — and takes the first
  survivor. A block gets a single candidate (the cell on the open side);
  faces and edges get the four planes or lines boxing the point in.
- **Occupancy.** `lattice::Structure` is a set keyed by element; place
  fails when the element is taken. Placed pieces never physically block
  each other — the registry decides — so a wall standing on a cube's face
  is legal (it overlaps the cube's skin by half its thickness, on purpose).
- **Corner trims.** Walls end or meet on vertical edges; where the walls
  touching an edge are not exactly two collinear ones, and no real post
  stands, the engine draws a slim post there. A long run stays a wall, a
  corner reads as a corner, a lone panel is framed, all without the player
  placing anything. Trims are presentation only: never saved, never
  collide, never cost.
- **Saves** (schema v2) store each piece as element + shape + family +
  rotation step; loading clears the registry and re-places every piece, so
  what stands is exactly what was saved.

What changed for the starting shapes: the wall panel and the floor slab
are both 0.25 m thick and centred on their plane (a floor's rim and a
wall's top meet cleanly); the pillar stands on an edge; the beam runs along
one.

## Implemented: vocabulary and footprints (Wave 4 slice 2, 3 Sep 2026)

- **The registry runs at half cells** (`lattice_divisions: 2`). A
  full-size piece anchors at a registry element aligned to the build grid
  and covers a *footprint* of registry elements: a cube eight fine
  volumes, a wall four fine faces, a post or beam two fine edges. Pieces
  conflict when footprints share an element, and any covered element finds
  (or removes) the whole piece. This is one rulebook for two scales: a
  half-scale "fine" piece is simply a piece whose footprint is one registry
  element (the `fine` flag; the fine shapes themselves are the next slice).
  Corner trims are computed on the fine lattice, so a full-size wall's end
  is two stacked half-cell trims — visually the same post.
- **Eight shapes**, all but one from the start: cube, wall panel, pillar,
  beam, **floor slab** (un-gated: a flat roof is what makes a shelter),
  **stairs** (an oriented block, two half-steps rising toward its back),
  **door** (a wall piece two cells tall — the player is 1.92 m — whose
  leaf swings on E, dropping its collision while open; R flips the hinge
  side; its footprint takes the face above it so nothing can straddle the
  opening), and the **roof wedge** (a 45° prism filling a cell, the
  trial's completion reward in place of the old slab: it widens what can
  be built without gating shelter). The half-block step is gone; stairs
  replace it.
- **Forms** (`form`: box, stairs, wedge, door) are how the engine builds a
  shape: `PieceMesh` makes the mesh and collision (stairs are two boxes,
  the wedge a six-point convex hull, the door a leaf on a hinge pivot), and
  `PlacedBlock` no longer scales a unit cube.

## Implemented: fine mode (Wave 4 slice 2b, 3 Sep 2026)

**G** swaps the selection for its half-scale twin (`fine: true`,
`fine_of`): half cube, half wall, half post, half beam, half slab. A fine
piece occupies one registry element, so it may stand anywhere on the
half-cell lattice — a half post on the edge through the middle of a
block's top, a half wall patching a gap, a shelf of half slabs — and it
conflicts with full-size pieces through the same footprint lookup. Shapes
without a twin (stairs, door, wedge) stay full size in fine mode. Twins
never appear on Tab: the palette stays eight shapes plus a scale toggle.
Detail costs more than bulk on purpose (eight half cubes outprice a cube).

## Implemented: shelter (Wave 4 slice 3, 3 Sep 2026)

The health-regeneration route the owner asked for, and the first reason
to build. `lattice::enclosure` flood-fills open registry volumes six ways
from the player's cell; a step is blocked by an occupied volume, an
occupied face between the two volumes, or terrain. The room is a
**shelter** when the fill closes before `max_room_cells` build cells
without reaching open sky or the world's edge. Doors count as walls open
or shut (Valheim's rule: you can rest with the door ajar). Terrain is the
world's business, so a dug-out hollow with a slab over its mouth is a den,
and a walled yard with no roof is not.

The engine probes once a second (`player_combat.gd`, a free check while
nothing is built) and, sheltered and `settle_rounds` after the last hit,
pays `regen_life_per_round` per `round_seconds`. Out in the open nothing
regenerates: the early deprivation the owner asked for stays, and a mob
that breaks in stops the rest. Numbers live in `world.json` `shelter`; the
HUD's life line reads "sheltered" or "resting +N/s".

Owner revision, 5 Sep 2026: outdoor nighttime health drain is disabled for now
by setting `world.json` `day.exposure_life_per_round` to zero. The optional
rate/floor controls remain available, but current play does not lose health
to exposure or show cold warnings. Night still pays
`shelter_night_regen_multiplier` times the normal sheltered regeneration.
The life line shows night and the way home outside, and resting indoors.

**The chest (Wave 6 slice 6, hauling):** a block piece with a form of its
own (`construction.json` `chest`: six timber, joinery, a lidded box that
sits low in its cell). Its store lives in the sim under the piece's
element key (`store_deposit`, `store_withdraw`, `store_remove`; saved as
`stores`), holds `chest_units` (`world.json` `hauling`) of anything
together, and E opens the chest panel to move stacks either way. The pack
is what makes it matter: what you haul from the ground stops at a cap per
family (`carry_cap`, `carry_cap_default`; gear and forged goods never
capped), a full family's chips stay on the ground, and the walk home is
where the load goes. Break the chest and it spills where it stood.

**The siege and the house (Wave 7 slice 3):** some nights the hounds come
to the lamp and scratch at what they press against; the piece shakes and
the HUD says so. In the valley a shut timber door holds - they scratch,
they do not break. Once the deep wakes the husk breaks timber
(`eras.json` `breaks_timber`): after `timber_break_hits` (`world.json`
`siege`) scratches a timber piece gives and is gone, so the hut becomes
stone, which is the masonry unlock earning its keep. Stone and iron never
give. Death sends you home, the last shelter you rested in.

**Biome timbers (Wave 8 slice 2):** three more building families with
every trait of Timber and a colour of their own - `pine` (the forest,
pale), `bog_oak` (the fen, dark), `ash_wood` (the wastes, bone-pale),
each paid in its own felled timber, tinted over the plank texture
(`construction.json` `tint`), hauled at Timber's cap and burning at
Timber's heat. Q cycles them like any carried family. A house says where
you have been.

## Implemented: freedom outside the cell (owner playtest fixes, 3 Sep 2026)

The owner's first building playtest: "within the 1 block building feels
nice but there's still some tension outside of that". Six notes, three
causes:

- **Reaching into air.** Placement only worked from a surface the ray
  hit, so extending a beam or a wall over nothing meant hitting a tiny
  end face or the ground far below. Now the view ray is sampled from the
  player outward; once it has passed within a registry cell of something
  built, the first acceptable element that *touches* the structure
  (`Structure::near`, its footprint's box grown by one registry cell) wins.
  Aim along a beam's line and it continues; aim past a wall's edge and the
  wall extends; aim past a pillar's side and the next post lands on the
  cube top beside it. The surface hit stays the fallback.
- **The piece you build on decides the grid.** A hit on a fine piece, or on
  any piece standing off the build grid, generates candidates on the
  registry lattice, so a full cube sits on a half cube and a wall rises
  from a half wall. Full-size pieces are no longer forced to the build
  grid at all; the grid remains the default because terrain and grid
  pieces are what you usually build on.
- **Stepping up.** The player had no step-up (CharacterBody3D climbs slopes,
  never a vertical step), so stairs and half cubes were walls. The player
  now tests the blocked stride from `STEP_HEIGHT` (0.55 m) higher and,
  with ground within a step below the far end, lifts onto it; a capsule
  riding a block's edge counts as grounded for this. Mobs hop; the player
  steps.
- **Door collision** was under a hinge pivot node, which Godot ignores, so
  doors had no collision: walked through, unreachable by E and X. The
  shape is a direct child now and switches off while the leaf is open.
- **Floor slabs** are faces and live at cell boundaries (a ceiling, an
  upper floor); on the ground they are carpet, as the owner saw. Raised
  half-height floors are half cubes in fine mode. Shapes now carry a
  one-line `hint` the HUD shows on selection to say such things.

## Implemented: material families and traits (D-018, 3 Sep 2026)

Building families are data (`construction.json` `materials`): each is
**paid in a source item** (timber in wood, stone in stone, iron in
ingots), **looks like itself** (a 16×16 texture per family, triplanar on
every piece and on the corner trims of that family's walls), and
**carries traits** that say what it can be worked into. Shapes may
`requires_traits`; a family without them is refused, and the HUD says why
("needs joinery"). Q cycles the families whose source you carry.

The ladder, as the owner framed it ("a conical beam only usable through an
alloy that makes it malleable"): the family's *properties* gate the
*forms*, not a tech tree. Today's traits:

| Family | Source | Traits | What it unlocks |
| --- | --- | --- | --- |
| Timber | wood | timber, joinery | everything basic; doors (joinery) |
| Stone | stone | masonry, heavy | the cut-stone roof wedge (masonry, plus the boss's stonecut mastery) |
| Iron | iron ingot | metal, joinery, malleable | the two-cell **girder** (metal); iron doors |

`malleable` is deliberately unused: it is the trait the next family (an
alloy of two ores) will carry, and the trait curved and conical forms
will require, so that chain exists in data before the pieces do. `heavy`
is the hook for a later rule about what may sit on what. Adding a family
is one data entry plus a texture; adding a gated form is a shape with
`requires_traits`. The girder also introduced `cells_long` (a footprint
that runs along its edge), the same footprint model as the two-cell door.

Next for building: the owner's next playtest; base threats (see the
roadmap: pressure, not demolition); an alloy family with the first
malleable form.

## Interface requirements

Owner-approved usability pass, 5 Sep 2026: Tab in build mode opens a visual
catalogue with separate material selection, grouped shapes, existing fine twins,
held kits, costs and unlock hints. Oriented shapes have left/right inspection
buttons and a front arrow shared with the world ghost. The crosshair explains
placement failures and suggested remedies; the displayed address is revalidated
before charging. Ordinary construction rules and schema-2 saves remain unchanged.
[Controls, tuning and verification](../art/codex-building-usability-2026-09-05.md).

- Material selection and shape selection must be separate concepts.
- The palette must support filters, favourites and recently used shapes eventually.
- Prototype controls must display rotation, removal and material cost clearly.
- Nearby storage integration is desirable after the basic placement loop works.

## Fieldstone and the low form (3 Sep 2026, D-021)

**Fieldstone** is loose rock from boulders: a family with the `rough`
trait and `only_for_trait: rough`, so only the **footing** (block element)
and the **dry wall** (wall element) accept it. Both use form `low`: a box
that sits at the bottom of its element's extent, half a cell tall. A dry
wall still occupies its face, so a roofed pen counts as shelter — the
wooden house on a stone footing is the house the first hour builds.
Dressed **stone** comes from the mason's yard (see
[progression-eras.md](progression-eras.md)).

## The campfire (3 Sep 2026, D-020)

One shape is fuel, not building: the **campfire** (form `fire`) requires
the `fuel` trait, so it is laid in timber or charcoal, burns for its fuel's
`burn_seconds` at its fuel's heat, heats the rock and nodes beside it, and
is gone with no refund. Charcoal is a building family only for shapes that
require fuel (`only_for_trait`). See fire-setting in
[progression-eras.md](progression-eras.md).

## Failure cases

- Too many shapes make the palette harder than the construction itself.
- A universal optimal block may make advanced shapes cosmetic clutter.
- Low refunds discourage experimentation.
- Functional stations may encourage an ugly optimal warehouse unless creative building remains intrinsically enjoyable.
- Navigation must remain valid around diagonals and small openings.

## Prototype acceptance

- A player can create a recognisable shelter and forge area from the small palette.
- The same material quantity can be expressed through several unlocked shapes.
- Placement feels predictable without structural engineering.
- Construction creates meaningful demand for gathered and crafted resources.

## Open questions

**Owner adoption, 5 Sep 2026:** the improved building look explicitly includes
the octagonal build. Chamfer Block and Triangular Slab now appear in the normal
palette at the cube/slab costs (2/1). Roof Slope, Roof Hip and Roof Valley cost
one material, require joinery and retain the existing `stonecut_blocks` unlock.
The earlier study IDs remain stable; no save schema or lattice address changes.
This supersedes the lab-only catalogue status in the historical notes below.
Continuous timber boards, darker framing/ceilings and restrained stone now
apply to ordinary placed and restored pieces. Beams use a 0.4 m square section
(half beams 0.2 m) so they show beneath 0.25 m ceiling slabs without coplanar
flicker; mesh and collision agree. Existing saved beams adopt those dimensions.
See [normal-building evidence](../art/codex-normal-building-2026-09-05.md).

**Codex experiment, 5 Sep 2026 (not Claude):** a lab-only triangular `corner`
block now tests chamfered rooms on existing volume addresses. Placement,
convex collision and schema-2 save restoration work with its fixture loaded.
The continuation now clips shelter passages against the prism: its empty half
can be sheltered, its solid half cannot, and edge-only contact does not leak.
Partly empty fine volumes count as whole volumes toward the existing size cap.
Placement still reserves the whole cell. Corner forms must be oriented square
blocks/floors matching their grid extent; floor corners have four yaw poses.
A larger workshop uses a thick band of prisms for diagonal inner and outer
walls and triangular floor/ceiling corners. Its hipped roof/framing are lab
dressing. No normal catalogue entry or unlock was added.
See [current findings and limits](../art/codex-aesthetic-intensive-2026-09-05.md).

The owner-authorised [next lab pass](../art/codex-crafted-frontier-2026-09-05.md)
adds `roof_slope`, `roof_hip` and `roof_valley` forms to an isolated catalogue.
They are oriented square blocks, no taller than the grid extent; the concave
valley has two convex collision halves. They retain full-block occupancy and
the ordinary save representation. The playable scene isolates its save file;
no normal shape, material cost or progression unlock has changed.

- Final prototype grid size.
- Minimum coherent diagonal/transition set.
- Whether rare natural shapes exist as exact decorative objects.
- Whether stations unlock shapes globally or only while nearby.
