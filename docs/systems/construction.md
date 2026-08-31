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
| Snap tolerance | Precision versus frustration |
| Unlock skill level | Pacing of architectural vocabulary |

Grid size, placement range, per-shape material cost and removal refund are
data in `data/tuning/construction.json`, loaded by the `sim/` library; the
engine layer reads them and applies placement payment and refunds through
the rules library rather than computing them in scene scripts.

## Interface requirements

- Material selection and shape selection must be separate concepts.
- The palette must support filters, favourites and recently used shapes eventually.
- Prototype controls must display rotation, removal and material cost clearly.
- Nearby storage integration is desirable after the basic placement loop works.

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
