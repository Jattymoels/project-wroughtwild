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

## Wave 3 — Mobs, Packs and Their Drops

Mob families and pack composition per biome, elite/champion modifiers on
mobs, drop tables tied to those modifiers, density tuning toward the
Diablo/PoE "clear a pack, get a reward" cadence — in the open world, not an
instance. **With D-012:** fewer mobs on screen than PoE but more dangerous;
aggro chaining ("shriekers" that pull nearby strays into the stream) builds
the Zombies wave feeling out in the world; speeds tuned so training stays
skilful rather than trivial.

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
