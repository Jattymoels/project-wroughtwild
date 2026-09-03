# Construction System

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

- Final prototype grid size.
- Minimum coherent diagonal/transition set.
- Whether rare natural shapes exist as exact decorative objects.
- Whether stations unlock shapes globally or only while nearby.
