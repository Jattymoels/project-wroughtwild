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

## Wave 2 — Items and Modifiers *(intensive itemisation pass)*

The PoE side: more bases and slots, the modifier/tier pool, rarity, how
crafted vs dropped vs tempered items relate. Catalyst currency types grow
here. Balance sims extended to itemisation.

## Wave 3 — Mobs, Packs and Their Drops

Mob families and pack composition per biome, elite/champion modifiers on
mobs, drop tables tied to those modifiers, density tuning toward the
Diablo/PoE "clear a pack, get a reward" cadence — in the open world, not an
instance.

## Wave 4 — Dungeon and Roguelite Iteration

The innovation layer: run structure, boon/build interaction depth, secrets,
story-through-runs, dungeon modifiers the player chooses (risk dials). The
existing trial is the seed of this wave.

## Standing constraints

- Rules stay in `sim/` (engine-neutral, tested headless); the engine renders
  and times them (ADR-0003 / D-010).
- Every tunable lands in `data/tuning/*.json` with a `design_purpose`.
- The vertical-slice loop (gather → forge → order → armour → trial →
  catalyst → boss → unlock) must remain completable at the end of every wave.
