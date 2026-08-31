# World Generation, Settlements and Travel

**Status:** Bounded hybrid generation accepted for prototype exploration  
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

## Open questions

- Whether the first slice needs generated terrain at all.
- Final terrain representation and destructibility.
- How class halls are signposted.
- When outposts become mechanically worthwhile.
