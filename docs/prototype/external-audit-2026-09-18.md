# Wroughtwild external audit — 18 September 2026

**Status:** independent, read-only audit of the repository at `7b049bb`
(branch `claude/serene-euler-ycj67f`, shallow clone from 15 September). It
records findings and proposals. It changes no scope, decision or boundary;
every recommendation below is a proposal until the owner selects it.

The audit covers seven questions the owner asked: comparison with similar
games, feasibility, scaling to larger or infinite worlds, physics, look and
feel, scope, and what is missing. Code was read directly; claims cite
`file:line`. Screenshots were viewed, not summarised from their captions.
The rules tests were built and run on this Linux machine.

## Summary

Wroughtwild is a single-player, first-person, voxel-terrain sandbox ARPG in
Godot 4.5 with an engine-neutral C++ rules core. In roughly three weeks of
visible history it has reached a breadth most solo prototypes never reach:
gathering, refining, octagonal building, three classes, a 96-identity Foundry
buildcraft system, a three-run Forge arc with ten repeatable tiers, a
seven-wave Living Frontier campaign with a human boss, four-force extraction
devices, validated save recovery, comfort settings, audio, six rigged
creatures and a portable Windows build.

| Measure | Value |
| --- | --- |
| GDScript | 628 files, 96,181 lines (about 41,000 of them tests) |
| C++ rules and binding | 43 `.cpp` + 27 `.inc` + 21 headers, about 34,000 lines |
| Shaders | 88 files |
| Documentation | 490 Markdown files, 73,177 lines |
| Godot headless checks | 139 engine launches per run (`game/run_headless_checks.sh`) |
| Rules test checks passing here | 493,555 across eight suites, 0 failures; the ninth suite fails 24 fingerprint checks (see Feasibility) |
| Fresh-world entry time | 46–51 s on an RTX 5090 (`land05-closeout-result-2026-09-17.md`) |
| Walking frame time, same machine, 720p | median 10.9 ms, worst 24.8 ms |

Strengths worth protecting: the sim/presentation split (numbers never live in
GDScript), deterministic per-fight hit streams, staged and validated saves,
lattice building revalidated on load, the Foundry plate as an original
buildcraft idea, the four-force augmentation premise, and roots that
physically connect sources to workplaces.

The six largest risks, in order of how much they would cost to leave alone:

1. **Combat and movement feel** sit well below every comparable: hits are
   instant range checks, there is no hitstop, stagger, active-frame window,
   defensive verb or open-world enemy navigation.
2. **Visual coherence.** Four asset generations coexist with no chosen
   rendering style; the four forces are indistinguishable without labels.
3. **World architecture is finite by construction.** Infinite generation is
   a rewrite of the composition layer and data model, not a parameter.
4. **Process and compatibility overhead at prototype stage.** Fifteen frozen
   world profiles, byte-exact fingerprints and adoption records are maintained
   so that one person's development saves keep loading.
5. **Portability.** The rules tests do not compile on Linux GCC 13 with the
   Makefile's `-Werror`; byte-exact terrain fingerprints recorded on Windows
   fail here; there is no CI, no Linux or macOS native library and no licence.
6. **Market.** Co-op is excluded by boundary in a genre whose comparables sell
   on co-op, and the codebase's single-player assumptions make retrofitting
   expensive.

## 1. Similar games and positioning

There is no competitor research in `docs/research/` (only
`engine-ai-integrations.md`), so this section is the auditor's reading.

| Comparable | Overlap with Wroughtwild | What they have that Wroughtwild lacks | What Wroughtwild has that they lack |
| --- | --- | --- | --- |
| Enshrouded | Voxel terrain, free building, action ARPG combat, skill tree; the closest match | Co-op, animated weapon combat with stamina, parry and dodge i-frames, cohesive lighting and atmosphere, gliding traversal | Persistent Foundry buildcraft depth, finite rare finds, repeatable trial tiers |
| Valheim | Biome-gated progression, boss summons as trials, building, stylised look | Co-op, structural integrity, stamina/parry/block, weather, sailing, a single consistent art rule (low-res textures under modern lighting) | Deeper crafting identity, eras that change the same world, trial suspension and banking |
| Vintage Story | Slow, knowledge-gated crafting; "useful friction"; single-player friendly | Seasons, temperature, food spoilage, ore prospecting, chiselling, mature mod ecosystem | Trials, boons and ARPG build expression |
| Minecraft expert modpacks | Production gates, earned automation, "see it before you can have it" | A large automation vocabulary and offline production | Authored world premise, combat trials |
| Hades | Repeatable runs, boons, banked rewards, telegraphed attacks | Hitstop, dash i-frames, animation-driven hitboxes, cancels, feedback density | Persistent world, building and crafting between runs |
| Path of Exile | Persistent build depth, statuses (chill/freeze, ignite, bleed), crafting catalysts | Reliable status application, boss resistance rules, skill VFX identity | Ingots-on-a-plate buildcraft with class rails is original, not a passive tree clone |
| Core Keeper, Terraria, Necesse | Expedition-and-return loop, base as progression | Co-op, biome bosses as clear ambitions, fast onboarding | 3D first-person embodiment, physical building |

**Position.** The seam the design targets, a survival builder with genuine
ARPG buildcraft and roguelite trials, is real, and Enshrouded has shown the
voxel plus ARPG plus building combination has an audience. Nobody currently
ships Path-of-Exile-depth buildcraft inside a survival builder; that is the
ownable claim. The four-force augmentation premise (`docs/world-premise.md`)
is a stronger and more specific setting than most of the table.

**Risks against the table.** The genre is crowded and its audience buys
co-op. Every comparable is visually coherent, whether stylised or realistic;
Wroughtwild is not yet. And the design pitch promises transport networks,
outposts, class halls and a main settlement (`docs/DESIGN.md`, "World and
settlements") that do not exist, so the current build competes on its first
act only.

## 2. Feasibility

**Verified working.** Eight of the nine rules suites pass on this Linux
machine once warnings are allowed:

| Suite | Result |
| --- | --- |
| `sim_tests` | 224,380 checks, 0 failures |
| `leyline_tests` | 213,482 checks, 0 failures |
| `laboratory_experiment_tests` | 54,286 checks, 0 failures |
| `resonance_tests` | 632 checks, 0 failures |
| `living_frontier_wave2_tests` | 601 checks, 0 failures |
| `pairing_tests` | 72 checks, 0 failures |
| `laboratory_tests` | 55 checks, 0 failures |
| `central_tests` | 47 checks, 0 failures |
| `living_frontier_wave3_tests` | 17,716 checks, **24 failures** |

**Verified failing.**

- `tests/sim/Makefile:3` uses `-Werror`; GCC 13.3 rejects an unused variable
  at `sim/src/worldgen_frontier_v10.inc:129` and an unused function at
  `sim/src/worldgen_frontier_v8_landscape.inc:666`. The suite has evidently
  only been built with the Windows MinGW toolchain.
- The 24 wave-3 failures are all the same check: "published terrain,
  resources, packs, sites and all owned anchors remain byte exact"
  (`tests/sim/test_living_frontier_wave3.cpp:115`) for about half the seeds.
  The generation path makes over 200 `std::sqrt`, `std::floor`, `std::sin`
  and similar calls across the `worldgen_*.inc` files, so bit-exactness
  across compilers and C libraries is not guaranteed. The most likely cause
  is floating-point or libm differences between the Windows toolchain that
  recorded the fingerprints and GCC 13; this was not root-caused here. The
  consequence is that "the same seed recreates the same geography" currently
  holds per build, not across platforms, which matters for cross-platform
  saves and for any future shared world.
- There is no `.github` directory or other CI. `game/bin/wroughtwild_sim.gdextension`
  declares Linux and macOS libraries that have never been built; the
  extension CMake file is written around MinGW.
- No licence file exists; the README says all rights are reserved.
- The C++ Makefile recompiles the entire `sim/` library into every one of
  nine test binaries. A full build took 13.5 minutes on eight cores here.

**The largest avoidable cost: fifteen frozen world profiles.** `sim/src/worldgen_profiles.cpp:11-13`
lists fifteen profile ids across about 7,400 lines of `.inc` files, guarded by
per-cell fingerprints (`tests/sim/worldgen_fingerprint.inc`). Profile-string
branching appears in 32 game scripts, 19 places in `game/scripts/terrain.gd`,
10 in the extension and 16 in `sim/src/tuning.cpp`. This exists so the owner's
own development saves keep loading. Save compatibility across a prototype's
generator versions is a released-game obligation; early-access survival games
routinely reset worlds between major versions. Proposal: declare a save-reset
policy for the prototype, keep the current profile and one previous, and
delete the rest with their tests. This also removes the biggest obstacle to
changing the generator (see Scaling).

**Documentation weight.** 73,000 lines of Markdown against about 82,000 lines
of production code. Most of it is process record: worker prompts, handoffs,
adoption commits, evidence folders. The README's "Current phase" is a
2,000-word changelog. `AGENTS.md` is 44 KB of dated owner corrections. The
design truth (`DESIGN.md`, `docs/systems/`, `docs/decisions/`) is sound but
buried. Proposal: move dated work-item records under `docs/archive/` and keep
`docs/prototype/` to the living status sheet, acceptance criteria and open
questions.

**Repository layout.** `game/` has 49 directories at its root named by work
item (`b1`, `c5`, `land04`, `rf06b`, `art07_d1`), and 88 shaders scattered
among them. A second developer would have no way to find the ore shader
without grep. Proposal: reorganise by domain (`terrain/`, `flora/`,
`creatures/`, `devices/`, `ui/`) once the current wave is closed.

**Velocity versus evidence.** The 15 September standing approval ("approve
everything until I say otherwise", `AGENTS.md:32`) produced five LAND slices
in two days. Of 229 acceptance-criteria items, 182 are ticked and 47 are open;
nearly every open item reads "owner accepts" or "human playtest". The project
is not short of features. It is short of hours of play. The playtest notes of
17 September (`playtest-progression-extraction-building-notes-2026-09-17.md`)
found four real problems in one session; that is the best return on time in
the whole record.

## 3. Scaling to larger worlds and infinite generation

**Current representation.** A dense `uint8` voxel field, column-contiguous,
1,024 × 1,024 × 96 one-metre cells (`sim/include/wroughtwild/worldgen.h:233,263-266`;
`data/tuning/worldgen-frontier-v13.json:14-17`). Caves are carved per column by
3D value noise (`sim/src/worldgen_frontier_v6_base.inc:238-266`). Meshing is
exposed-face emission per 16-column chunk with a surface-nets-style vertex
blend from v7 on (`game/scripts/terrain.gd:14`; `wroughtwild_sim.cpp:3151-3195`).
Collision is one trimesh per chunk (`terrain.gd:414-440`).

**Generation is whole-world, up front.** The base height, moisture and cave
noise is a pure function of seed, x and z (`v6_base.inc:3-18,148-163,253-263`),
which is the good news. Everything above it assumes it can see the whole map:

- a hard assertion that V6–V13 are exactly 1,024 × 1,024 × 96 at 1 m
  (`sim/src/tuning.cpp:1647-1648`);
- rim massifs from distance to the map edge; spawn at the map centre; the
  gate at the farthest matching cell by full-map scan (`v6_base.inc:165-228`);
- landmarks at biome centroids over the whole map (`v6_base.inc:498-515`);
- a spawn-rooted whole-map flood (`worldgen_frontier_v2.inc:40-72`) rebuilt
  at least 19 times per generation for habitat, region, ruin and host
  approaches, each allocating map-sized arrays;
- one lake sited against every home, region, landmark, gate and spawn
  (`worldgen_frontier_v8_lake.inc:9-52`); ruin routes to the gate;
- whole-map augmentation, cut, occupancy and parent arrays
  (`worldgen_frontier_v8_landscape.inc:118,137,253,614`).

**Streaming exists but the world does not stream.** `terrain_chunk_stream.gd:3`
says it plainly: "The full native world always exists." The extension keeps
the whole map, copies all 96 MiB of blocks into a `PackedByteArray`
(`wroughtwild_sim.cpp:2764-2767`), and `terrain.gd:258` duplicates it again,
so roughly 288 MiB of voxel copies sit resident at 1 km. Chunks are meshed on
demand in five staged phases, retired beyond 176 m and regenerated on return
(`game/art/strange_stream.gd:12-16,124-149`). A whole-map horizon mesh of
about 132,000 triangles is built synchronously in GDScript at setup
(`strange_stream.gd:294-358`). Every resource record, mob pack and site is
registered at setup (`resource_stream.gd:14,55-60`; `mob_packs.gd:16,79`;
`cataclysm_sites.gd:31-45`).

**Saves** store deltas for digs, buildings and stations (`save_manager.gd:111-141`)
but `resource_nodes` dumps every generated record whether touched or not
(`resource_stream.gd:85-89`), so save size scales with world area.

**Precision.** Single-precision floats, absolute world vertices, no origin
shifting. Fine to about 4 km; at 16 km vertex and contact jitter of about 2 mm
becomes visible. `surface_sampler.gd:44` already works around this locally.

**Verdict by target.**

| Target | Parameters only? | What breaks |
| --- | --- | --- |
| 2 × 2 km | No: the extent assertion needs a new profile. Then about 4× memory (over 1 GiB of copies), roughly 22 s generation, a 500k-triangle horizon | Content does not scale: fixed counts of regions, homes and one lake around one centre |
| 4 × 4 km | Marginal | 1.5 GiB per block copy, three copies; about 90 s generation; 19 floods over 16 M cells; the same fixed content spread thinner |
| 16 × 16 km or infinite | No | New data model and composition layer |

**Minimum refactor for chunk-on-demand generation**, if chosen:
(1) replace `WorldMap.blocks` with a column provider built on the already-pure
noise; (2) split composition into a bounded region-tile pass with a tile-local
anchor and flood; (3) in the extension, a tile cache instead of `cached_world`,
no shipping of `blocks`, dig edits keyed by chunk rather than flat world index
(`wroughtwild_sim.cpp:3111-3120`), chunk-local vertices; (4) in `terrain.gd`,
drop the block duplicate and the bounds-clamped lookups (`terrain.gd:97-115`)
for a per-chunk edit overlay; (5) unclamped chunk origins and a ring or
clipmap horizon; (6) placers registering per tile; (7) resource records saved
as deltas; (8) per-tile fingerprints. This is weeks of work and it touches
exactly the kernels the fifteen frozen profiles forbid changing.

**Design question first.** The features that make this world feel authored
are inherently finite: one spawn valley, one gate, one lake, four home cores,
five finite rare finds, singleton ids like `scarwater_0` and `dry_steppe_0`,
journeys that route to a source. Infinite noise wilderness would dilute them.
The eras model ("the world changes state in eras and never adds a zone",
`docs/systems/progression-eras.md`) also fights an unbounded world: which
region's era? Two honest options:

- **Bigger finite (recommended to evaluate first).** A 2–4 km world composed
  of several authored regions with a presented edge (sea, impassable massif).
  Keeps every current design feature, needs the memory and generation work
  above but not the data-model rewrite.
- **Composed tiles in a noise sea.** Keep the current 1 km composition as a
  tile type with its own anchor, generate pure-noise wilderness between
  tiles, place tiles on a jittered lattice. Journeys stay within a tile;
  cross-tile routes come later. This is the only credible path to "infinite"
  that preserves the design, and it is the full refactor.

`AGENTS.md` currently excludes infinite generation from the prototype. This
audit does not change that; it records what the choice would cost.

## 4. Physics

**Engine defaults.** `game/project.godot` has no physics or rendering
section, so Godot 4.5 uses GodotPhysics3D, not Jolt, at a 60 Hz tick with
physics interpolation off, and the Forward+ renderer.

**Player.** `CharacterBody3D` with a capsule (`player.gd:2`; `player.tscn`),
first person by default with a third-person spring arm on V (`player.gd:31,988`).
Gravity, jump (5 m/s, coyote and buffer, `player.gd:13-19`), 5 m/s walk, no
sprint, no stamina. A custom step-up handles 0.55 m steps and tight ceilings
(`player.gd:723-764`, tested in `game/tests/home_headroom.gd`). Swimming is a
scripted spring toward the surface at 0.7× speed (`player.gd:672-694`), not
buoyancy. All of this runs in `_physics_process` at 60 Hz while mouse look
runs per input event, so body and camera translation step on 120 Hz and
144 Hz displays. Godot 4.5 has 3D physics interpolation; enabling it is a
project setting and worth a trial.

**Combat contact.** Melee has no hitbox or animation window: `_use_strike`
picks the nearest enemy in front by planar distance and facing dot
(`player_combat.gd:904,1194`); cones are radius plus arc (`:825`). Projectiles
are `ShapeCast3D` sweeps that respect cover (`skill_projectile.gd:109`;
`enemy_projectile.gd:89`). Enemy bites use windup, range, vertical gap, arc and
a line-of-sight ray (`enemy.gd:850-864`). Dash has zero invulnerability by
decision D-012 (`data/tuning/combat_realtime.json:193-197`, "position is the
defence"). Present feedback: a 0.12 s enemy flash, a short shove, hit marker,
damage compass, landing dip. Absent: hitstop or time scaling (no use anywhere
in `game/scripts`), camera kick, active-frame windows, player stagger or
knockback, block, parry, stamina, death physics.

**Enemy AI.** A hand-rolled string state machine (idle, chase, windup,
release, recover, flee; `enemy.gd:89,672-861`), straight-line chase plus a
spatial-hash separation grid (`enemy.gd:972,958`; `mob_grid.gd`) and a
one-block hop. No `NavigationAgent3D` anywhere in `game/scripts`. A navmesh
exists only in the authored Forge dungeon (`forge_dungeon.gd:556-598`). In the
open world, mobs walk into cliffs, pile against walls and halt at shorelines
(`enemy.gd:1277-1286`). Sixty live mobs are capped; guard, ward and swarm verbs
scan the whole group per call (`enemy.gd:1108,1123`).

**Building.** 1 m grid with a 0.5 m registry (`grid_placement.gd:31,35`).
Validation checks lattice occupancy, terrain exposure against the dug block
field and a shape query against mobs, props and stations (`grid_placement.gd:541-600`).
There is no structural rule; walls extend "over nothing" by design
(`grid_placement.gd:623`), consistent with the boundary that excludes complex
integrity simulation. Every piece is its own `StaticBody3D`, never merged;
1,310 pieces measured at 34.8 ms worst placement after fixes
(`placement-reliability-2026-09-07.md`). Per-piece bodies grow the broadphase
linearly.

**Everything else is kinematic or scripted.** The only `RigidBody3D` in the
game is a cosmetic seam chunk freed after 2.6 s (`resource_node.gd:549`).
Pickups integrate their own gravity and magnetism (`pickup.gd:155-230`); the
winch basket is lerped; water is a table lookup with no volume or buoyancy.
The C++ layer holds no physics. For a deterministic prototype this is a
reasonable choice, and it explains why the world feels less physical than
Valheim or Enshrouded.

**Proposals.** (1) Trial Jolt: one project setting, usually faster and more
robust with trimesh terrain and thousands of static bodies. (2) Enable 3D
physics interpolation and re-check the camera. (3) Open-world navigation: the
column data already lives in C++, so a coarse walkability grid with local A*
or a flow field toward the player is cheaper and fits voxels better than
runtime navmesh baking. (4) Decide the defensive verb: either i-frames on
dash, or a stamina-costed block or parry; footwork alone reads as "no
defence" in first person. (5) Merge placed-piece collision per building
region once a home exceeds a few hundred pieces.

## 5. Look and feel

**What is on screen now** (viewed: `docs/prototype/land05-evidence-2026-09-17/green.png`,
`blue.png`, `white.png`; `land02b-evidence-2026-09-16/rooted-canopy.png`;
`rf05-evidence-2026-09-15/03-shore-outlook.png`; `captures/lf1/ember-foundry.png`;
`docs/prototype/references/population-2026-09-08/seed-77-native-hostiles-night.png`).

The palette is coherent and muted; the scenes read as places. The lighting is
flat and even, there is no anti-aliasing in production, and silhouettes are
hard. Terrain is smooth-shaded voxel with tiled soil and grass textures. The
lake is a flat cyan plane with a visibly stepped shoreline, one blown-out
specular streak and no reflection or depth tint. The "Green" host is rows of
brown extruded ribbons lying on the ground with thin green seams; the "Blue"
host is pale flat fans on rock ledges that read as paper; "White" is grey
stepped rock with orange lumps that reads as rust, not white. The ART-07
broadleaf tree and the porcupine are the two things on screen that look
finished. Night turns the ground navy while the sky keeps its daytime clouds.
The player is a procedural blocky humanoid with blocky first-person hands.

The UI is the most finished layer: `ui_theme.gd` builds one consistent
ink-and-parchment theme, and the Foundry panel is dense but legible. The
top-right holdings strip and floating yellow notices are hard to read over
bright sky, and the help hint is nearly invisible.

The owner's own earlier remark, an "old Newgrounds-like impression"
(`playtest-feedback-2026-09-06.md:16`), is still fair for most frames.

**Intent versus screen.** The premise is strong and unusually well written.
The concept boards under `docs/prototype/land00-visuals-2026-09-16/` are
photoreal AI paintings of layered forest, fractured cliffs and reflective
water, and `land02-visual-pipeline-diagnosis-2026-09-16.md` already admits
the procedural slab stacks cannot reach them. The deeper problem is that no
rendering style has been chosen. `docs/art/art-direction.md` is a chronology
of corrections (gloomy rivers, then green undulating Valheim, then four
forces, then "form before colour") rather than a rule an artist could apply.
Four asset generations coexist: voxel terrain with tiled textures; ART-07
trees, rocks and creatures produced by AI concept image, local TRELLIS
image-to-3D and Blender cleanup (25,000–150,000 triangles each); LAND hosts as
deliberately stylised scripted Blender tubes and fans; and a procedural
player. Photo-textured meshes next to flat-colour fans next to voxel ground
cannot read as one world whatever the concept says.

**Rendering setup.** Forward+, `ProceduralSky`, one shadowed directional
light, filmic tonemapping, thin fog, ambient from sky (`game/scenes/sandpit.tscn`);
SSAO and per-biome sun, fog and sky moods for V10+ (`game/art/wildland_atmosphere.gd`).
Not enabled anywhere in production: glow, SDFGI or SSIL, screen-space
reflections, volumetric fog, MSAA, TAA or FXAA, a night sky, weather, any
particle system beyond one habitat mote emitter. Several of these are
checkbox settings in Godot 4.5.

**Performance versus what is drawn.** On an RTX 5090 at 1280 × 720 the game
walks at a median of 10.9 ms and a worst frame of 24.8 ms, and a fresh world
takes 46–51 s to enter. An older build ran at about 28 fps on a Radeon
integrated GPU. A 5090 should render this scene in well under 3 ms; the cost
is CPU-side GDScript streaming, ground-cover construction and publication, as
the LAND-05 trace itself attributes. The entry time is a launch-blocking
number for a 1 km world and deserves a dedicated pass before any world
growth.

**Animation and feedback.** Newer TRELLIS creatures have authored idle, walk,
windup and release clips; older mammals are driven procedurally by
`game/art/creature_motion.gd`. Foot sliding and collider mismatches are
recorded limits. Hit reactions are a flash and a scale-fade death. There are
no damage numbers, no screen shake, no weather, and `sim/src/daycycle.cpp`
reaches the visuals only as a tint.

**Proposal: one global pass before any more kits.** Write a one-page shading
rule (the auditor would suggest stylised: strong directional light, saturated
per-biome palettes, unified matte foliage and rock shading, emissive force
seams), then enable TAA or MSAA and glow, add a real night sky, a reflective
lake with depth tint and shoreline blend, and re-tint every existing kit to
the rule. This touches every frame, costs far less than remodelling and would
let mixed-fidelity assets read as one world. Protect the augmented
recognisable animals and the physically connected roots; those are ownable.

## 6. Scope

The original first slice was "deliberately small": one class, one region, a
few shapes, one craft chain, one forge upgrade, one trial and boss
(`docs/DESIGN.md`, "Prototype boundary"). Decisions D-027 through D-032 then
approved bounded expansions, and the intensives and Living Frontier waves
added far more. All of it is documented and approved, and all of it is scope
growth.

What is built is genuinely broad (see Summary). What the pitch promises and
the build does not yet contain: resource outposts, a transport network,
authored class halls and specialisation trials, trading beyond the order
board, production beyond one pressure feeder and one winch, and a main
settlement. The settlement arc "Shelter → outposts → transport → settlement"
has only its first step.

The status sheet is candid that the open items are almost all human
judgement: whether the first half-hour creates ambitions, whether travel and
building feel good, whether trials are the right length, whether the world is
exciting to build in. Two days of standing approval produced more slices than
the owner has had hours to play. The scope recommendation is therefore not
"cut features" but "stop adding until the owner's next four sessions of play
have been turned into fixes."

## 7. What is missing

Ranked by how much each gap would change a player's opinion of the game.

1. **Combat feel.** Hitstop, active-frame or hurtbox melee, player stagger
   and knockback, a defensive verb, reliable readable statuses (the owner's
   17 September notes ask for chill that slows before freezing and capped
   low-damage bleed and ignite). This is the largest single gap against Hades,
   Enshrouded and Valheim.
2. **Open-world enemy navigation.** Packs that path around walls, cliffs and
   water instead of piling onto them.
3. **Visual coherence, water, night and weather.** Section 5.
4. **Entry time and CPU-side hitching.** 46–51 s into a 1 km world, worst
   frames still around 25 ms on top-end hardware, unresolved "large freeze"
   reports.
5. **First hour affordances.** Onboarding is text-first; stations are small
   dark boxes; the world itself signals little. The owner's four found
   problems (early Foundry spike, stone throughput for houses, empty and
   potentially inescapable caves, rotation through Tab) are all first-hour
   problems and are correctly diagnosed in the 17 September notes.
6. **The mid-game the pitch sells.** Outposts, transport, class halls,
   automation vocabulary. The owner's "Stoneheart frame" earned-extractor
   proposal is the right shape for the next step: it makes exploration change
   how work is done rather than making a number larger.
7. **Co-op.** Excluded by boundary; recorded here as the largest market risk.
   The codebase assumes one player everywhere (21 `get_first_node_in_group("player")`
   lookups, a static mob grid, a client-side fight seed, whole-world JSON
   saves). If co-op is ever wanted, that decision should be made before
   content grows further, because each new system deepens the assumption.
8. **Engineering hygiene.** CI, Linux and macOS builds, `-Werror` portability,
   cross-platform generation determinism, a licence, a save-reset policy,
   domain-based asset layout, a faster C++ test build.

## 8. Recommended order (proposal, not a decision)

1. **Play, then fix the four found blockers**: Foundry power pacing,
   stone-to-house throughput via the earned extractor, cave escape, direct
   rotation. These are the owner's own findings and need no new evidence.
2. **Combat feel sprint** (about two weeks): hitstop, stagger, active frames,
   one defensive verb decision, coarse open-world navigation.
3. **Visual coherence pass** (two to three weeks): shading rule, lighting and
   post, water, night sky, re-tint kits. No new kits until it lands.
4. **Engineering week**: Jolt and physics-interpolation trial; fix the two
   `-Werror` failures and add a Linux CI job that builds the rules tests;
   decide the save-reset policy and prune profiles; archive dated docs;
   measure and attack entry time.
5. **World model decision** after 1–4: bigger finite with several composed
   regions, or composed tiles in a noise sea. Bigger finite is recommended to
   evaluate first because it fits the eras model and keeps every finite
   design feature.
6. **Decide co-op**, even if it is implemented years later.

## How this audit was produced

The repository was read at `7b049bb`. Three parallel code reviews covered
world generation and streaming, physics and gameplay, and visuals; their
load-bearing claims were then spot-checked against the cited lines. The
rules tests were compiled with GCC 13.3 on Ubuntu 24.04 using the repository
Makefile with `-Werror` removed, and every built suite was run against
`data/tuning`. No Godot binary was available here, so the 139 headless engine
checks were not run and no live-play claims are made beyond the committed
screenshots and timing reports.

---

# Part 2 — Owner responses and follow-up, 18 September 2026

The owner read Part 1 and replied with four points: (1) what Jolt adds,
whether it is worth it and how big the rewrite is; (2) combat mechanics feel
fine after tuning, but the experience is empty: you press buttons and things
happen blindly, with no feedback to anything pressed; (3) finite is fine,
provided there is enough biome diversity, transport and non-boring generation
that it does not become a slog; (4) building and the new biomes feel good, but
many small poor assets pull the look down and make the larger barren biomes
feel worse. This part answers each. Section 2.5 replaces the recommended order
in Part 1 §8. Everything remains a proposal until the owner selects it.

## 2.1 Jolt: what it adds, what it costs

**What it is in Godot 4.5.** Since Godot 4.4 the Jolt Physics library ships
inside the engine as a module. It is selected with one project setting,
`physics/3d/physics_engine`, from its default GodotPhysics3D to "Jolt Physics".
The node API is unchanged: `CharacterBody3D`, `StaticBody3D`, shapes,
`move_and_slide`, `test_move`, `intersect_ray`, `intersect_shape` and
`ShapeCast3D` are all server-agnostic. So this is not a rewrite. No script has
to be restructured.

**What this game uses** (grep over `game/`, tests excluded): `move_and_slide`
in 10 files, `test_move` 16 uses (the step-up at `player.gd:723-764` and the
mob hop), `intersect_ray` 78 uses in 27 files, `intersect_shape` 26 uses in 8
files, `cast_motion` 7, `ShapeCast3D` 8, one `ConcavePolygonShape3D` per
terrain chunk with `backface_collision = true` (`terrain.gd:418`), box,
capsule, sphere and convex shapes, and one cosmetic `RigidBody3D`
(`resource_node.gd:549`). There is no `Area3D`, no joint, no `SoftBody3D`, no
`WorldBoundaryShape3D` and no `HeightMapShape3D`. That is close to the
smallest physics surface a 3D game can have, and the Jolt module supports all
of it. Checked in the 4.5-stable module source: `backface_collision` is read
and applied as a double-sided mesh shape
(`modules/jolt_physics/shapes/jolt_concave_polygon_shape_3d.cpp`), so the
two-sided terrain contract survives.

**What Jolt would add here.**

1. Steadier movement on triangle-mesh terrain. Jolt's enhanced internal edge
   removal is on by default for the simulation and for motion queries
   (`physics/jolt_physics_3d/simulation/use_enhanced_internal_edge_removal`
   and `.../motion_queries/use_enhanced_internal_edge_removal`, both default
   true), and mesh shapes get an active-edge threshold (default 50°). These
   suppress the ghost contacts that make GodotPhysics character bodies snag
   and jitter on the internal edges of trimeshes. One limit: the check works
   per body pair, so it helps inside a chunk; the seam between two chunk
   bodies is a body-to-body edge and gets less help.
2. Speed and headroom. Jolt's broadphase and mesh collision are faster, and
   the budget grows with every placed piece (one static body each, 1,310
   measured), chunk body, mob and query. Caveat: no report measures the
   physics step itself; the documented hitches are GDScript ground-cover
   construction and publication, which Jolt does not touch. Building a
   chunk's trimesh (`set_faces`, timed at `terrain.gd:419-421`) stays
   synchronous on the main thread under both engines.
3. Real rigid bodies later. Point 3 of the owner's reply asks for transport.
   Carts, cargo, falling trees and ragdolls are rigid-body and joint work,
   where Jolt is far more stable and GodotPhysics is weakest. If any of that
   is coming, switch before building it.

**Costs and risks.**

- Behaviour deltas. Floor detection on slopes, the 0.55 m step-up and its
  `safe_margin` recovery, the mob hop and the swimming spring will all move
  slightly. Jolt uses a convex collision margin
  (`collisions/collision_margin_fraction`, default 0.08) and its own recovery
  (`motion_queries/recovery_iterations` 4, `recovery_amount` 0.4). Budget a
  day of retuning in `player.gd` and `enemy.gd`.
- One code-level dependency. `terrain.gd:159-163` maps a ray hit to a voxel
  cell through the hit's `face_index`. Under Jolt, `face_index` is only
  filled when `physics/jolt_physics_3d/queries/enable_ray_cast_face_index` is
  on, which stores per-triangle data on every mesh shape. Either enable it,
  or rely on the position-and-normal fallback that `strike_world` already
  has (`player.gd:948-950`); check digging, cracking and placement picking
  either way.
- Tests. Of the 139 headless checks, those that walk real routes and compare
  positions or distances may need tolerance changes. That is re-baselining,
  not a correctness risk.
- Determinism. The Jolt integration's own README says it "is not able to
  make such guarantees". Nothing is lost: combat determinism lives in the
  C++ hit stream, and GodotPhysics never promised it either.
- Body cap. `physics/jolt_physics_3d/limits/max_bodies` defaults to 10,240.
  Per-piece static bodies plus chunk bodies could reach it in a very large
  base; raise the setting, or merge piece collision per building region
  (Part 1 §4).
- Shape casts are more accurate under Jolt but cost scales with cast
  distance. Projectile sweeps are short; fine.

**Verdict.** Worth a one-day trial now, and a definite yes before any
rigid-body transport work. It will not fix the current stutters. The trial:
flip the setting, enable ray face indices, play the step-up, cave, lake and
home routes, run the headless checks, keep whichever engine passes and note
the deltas. Reverting is the same one line. Size: one line of configuration,
a day of verification, up to a day of retuning.

**Pair it with physics interpolation.** `physics/common/physics_interpolation
= true` (3D support since Godot 4.4) removes the 60 Hz stepping of body and
camera on 120 Hz and 144 Hz displays that Part 1 §4 noted. After any teleport
(world entry, Continue, trial gates) call `reset_physics_interpolation()` on
the player so the first frame does not smear. Also small: a setting plus a
handful of calls.

## 2.2 Combat: why it feels empty, and a feedback layer that leaves the numbers alone

The owner's description matches the code exactly.

**Diagnosis.**

1. The hit happens on the frame of the press. `_cast` calls `_use_strike`
   directly (`player_combat.gd:445`), which spends the cooldown, picks
   targets, deals damage and shoves, all in one call (`:904-948`). The hand
   swing is a separate cosmetic clock of 0.28 to 0.48 s
   (`game/art/combat_feel.gd`, `first_person_look.gd`) that starts at the
   same moment, so the swing decorates a hit that has already landed. There
   is no anticipation, no moment of contact and nothing to time. This alone
   produces "blind".
2. Combat is silent. No combat script plays a sound: not
   `player_combat.gd`, `enemy.gd`, `boss.gd`, `first_person_hands.gd`, the
   skill effects or the projectiles. The only audio in the game is
   footsteps, ambience, work and device cues (`environment_ambience.gd`,
   `player_footsteps.gd`, `game/art/footstep_sound.gd`,
   `interaction_sound.gd`, `strange_sound.gd`). Casting, hitting, killing,
   whiffing, being hit and enemy windups make no sound. In first person,
   sound carries at least half of perceived weight.
3. Reactions are faint. An enemy hit is a 0.12 s white flash and a
   sim-sized shove; death is `queue_free()` on the same frame
   (`enemy.gd:1232-1258`) with no fall and no corpse unless the mob is an
   elite with a burst. Being hit is a HUD red flash and a compass bearing.
   The only camera-side response to anything is an 18 mm hand recoil over
   90 ms (`impact_recoil` in `first_person_look.gd`).
4. Nothing tells the player whether a press will land. The crosshair turns
   red over an enemy and names it (`hud.gd:508`), but red means "looking
   at", not "within reach of this skill". The strike then picks the nearest
   enemy in front within reach, which may not be the one under the
   crosshair.
5. Cooldowns are text. Slots show "ready" or a countdown
   (`action_bar.gd:86-92`). A press on cooldown is silently ignored; a skill
   becoming ready makes no sound.
6. A miss resolves into the world with no swing, sound or cost
   (`player.gd:933-955`).

**What exists to build on.** The `hit_landed(total, kills, types)` signal
(`player_combat.gd:947`), `hit_taken` and `damage_bearing` signals;
`Enemy.stagger` and `Enemy.shove` sized by the sim (`enemy.gd:472,492`);
`Enemy.take_damage(flash)`; `FirstPersonHands.present_skill` with
per-delivery profiles (strike, rend, sweep, reap, nova, arrow, frost, ember,
drive) in `combat_feel.tres`; `SkillCastEffect`, `SkillBurst` and `PulseRing`
meshes; the `InteractionSound.play(root, at, cue)` helper that synthesises WAV
cues in code (`game/art/interaction_sound.gd:56,112`), so first-pass combat
sounds need no asset files; `ResourceNode._play_harvest_punch` as an accepted
example of a punchy per-hit response.

**The plan.** Organised by the four moments of a press. Rule: nothing in
`sim/` or `data/tuning/combat_realtime.json` changes; every item is
presentation, matching the owner's "mechanics are fine" and the existing
"Cosmetic only" header on `combat_feel.gd`.

*Moment 0, before the press: can I hit?*

- A reach-aware crosshair: evaluate the primary strike's
  `_nearest_enemy_in_front(reach)` each frame (the enemies group is already
  scanned) and show a distinct "in reach" state, with a bracket on the
  target's name and a faint outline or tint on the enemy that would actually
  be hit.
- A ready ping when a cooldown completes; a dull clack and slot nudge on a
  rejected press.

About two days.

*Moment 1, the press: anticipation.*

- Let the swing cause the hit. Split `_use_strike` into `begin` (spend, lock
  the target set, start the swing and its sound) and `land` at a fixed
  fraction of the swing (for example 40 %, roughly 120 to 140 ms for a
  0.34 s swing), where the existing selection, `deal` and `_space_control`
  code runs. Confirm reach at `land` with a small tolerance so a target that
  stepped away produces a whiff. Heavy Strike gets a longer wind; its
  existing 1.2 s recovery then reads as heavy rather than slow.
- Cast sounds per delivery profile, two or three variations each, first
  synthesised through `InteractionSound`.

Two to three days. Risk: headless tests that call `use_skill` and assert
damage on the same frame need a `contact_fraction = 0` test override, which
keeps them exact.

*Moment 2, contact: weight.*

- Hit-pause on the hands only: freeze the swing for two or three frames at
  contact. Do not use `Engine.time_scale`; it would also freeze enemy clocks,
  statuses and the day cycle.
- A camera impulse, not a shake: 0.5 to 1° of pitch and roll with an 80 ms
  return on a hit dealt, scaled by damage fraction; 1.5 to 2° along
  `damage_bearing` on a hit taken. The landing dip at `player.gd:661`
  ("weight without screen shake") is the model.
- Impact sounds by damage type layered on a body thud, and a distinct kill
  sound.
- Enemy reaction: turn the paid shove into a short knock-back arc, a flinch
  pose on procedural rigs (`game/art/creature_motion.gd`) and a flinch clip
  on the image-to-3D rigs, and pooled hit motes coloured by damage type (one
  `GPUParticles3D` per type).
- Hit marker: scale with the total from `hit_landed`, colour by type, larger
  on kills, with an optional damage-number toggle.
- Status application (chill, ignite, bleed) gets a visible tick and a sound.
  The owner wants statuses to feel reliable, and reliability is partly
  legibility.

Three to four days.

*Moment 3, aftermath: consequence.*

- Death: hold the body one to two seconds (a tip-over tween for procedural
  rigs; real ragdolls become practical after Jolt), then fade; loot pops
  into the existing pickup magnet.
- Whiff: swing sound plus air swish and hand overshoot; no cooldown refund,
  so the sim stays untouched.
- Taking damage: a directional vignette pulse along the compass bearing, a
  hurt grunt, a low-life heartbeat layer; the Harry slow shows as heavy
  footsteps.

Two to three days.

Total: eight to twelve working days for the whole layer. Moments 0 and 2
alone remove most of "empty" in four to six days. Asset needs: about 25 short
sounds (synthesised first) and four particle materials. First-person melee
references worth studying: Dark Messiah of Might and Magic for weight,
Enshrouded for wind-up and impact frames, Hades for hit-sound and marker
cadence.

## 2.3 A bigger finite world that is not a slog

**What exists.** Seven biomes chosen by height and moisture
(`biomeFor(table, cell.height, moisture)` in
`sim/src/worldgen_frontier_v6_base.inc`), with the spawn biome forced inside
a 150 m radius; three authored regions, the Scarwater basin, the Dry Steppe
patch, one lake and four home cores. There are no rivers: the word does not
occur anywhere in `sim/src`. Mountains are a cragginess field plus the rim.
Walking is 5 m/s with no sprint, so the current world is about 3.5 minutes
edge to edge and a 4 km world would be 13 minutes. Hauling is 240 units per
material family.

One tuning fact explains part of the barren feeling: Dry Steppe's node table
is identical to Meadow's (`tree 0.009, boulder 0.008, stone_seam 0.004,
pack_density 0.0006`, `data/tuning/worldgen-frontier-v13.json`). The Steppe is
a Meadow with less grass and a different colour, plus its authored Red hosts.
Ember Wastes is the only biome with real hostile density (0.013 with patrols)
and Rocky Hills the only one with dense stone.

**A. Structure the land so it reads.** In order of value per line of code:

1. Drainage. Compute flow accumulation over the height field and carve
   rivers, streams and lake chains. Rivers give direction, mark biome
   boundaries, cut valleys that are natural routes, and become waterways
   later. This is the largest single "non-boring" gain available and it is
   entirely absent.
2. Ridge lines and passes. The cragginess field already exists; shape it
   into continuous ridges with deliberate gaps so travel has route choice
   and vistas.
3. Biome placement by the owner's proposed weighted adjacency on a coarse
   grid (about 128 m cells), constrained by height, moisture, temperature
   and river distance, with uninfluenced recovered ground as an explicit
   member of the distribution.
4. A point-of-interest budget per square kilometre (ruins, impacts, hosts,
   vistas, shelters), placed by Poisson-disc sampling, with one rule: from
   every home core at least one ambition is visible.
5. Tall unique silhouettes (giant host trees, meteor spires) visible over
   500 m to navigate by.

**B. Biome diversity that is content, not tint.** Each biome needs its own
node table, ground cover set, one or two creatures, one resource and a
reason to go. First cheap step: give Dry Steppe its own table (stone seams
and quarry layers, dry snags, husk and bone finds, ram and tortoise packs).
That is a numbers-only tuning change.

**C. Transport as earned capability.** The spec already lists carts and
roads, boats, tracks, portals and gliding (`docs/systems/world-generation.md`,
"Travel progression") and asks that transport preserve the value of
discovering and connecting places. Tying it to the four forces fits the
premise and the owner's earned-extractor pattern:

- Tier 0: a travel sprint (about 7 m/s) that drops when a hostile is within
  aggro range, so "position is the defence" stays intact in combat. The
  cheapest slog reduction available.
- Tier 1: roads and a hand cart. Roads are built from bulk stone, which gives
  the owner's stone-throughput problem a demand sink; the cart raises the
  hauling cap several times on road.
- Tier 2: a tamed Valley Elk as pack animal. Elk are already everywhere and
  the owner wants fewer ambient ones; give the survivors a use.
- Tier 3, force based: White impulse gates that launch between discovered
  White sources (fast travel that must be found and connected); Green root
  bridges across fissures and rivers; Blue stasis crates that carry more
  finite finds without loss; Red powered carts or rails toward automation.
- Boats on rivers and the lake once rivers exist. DESIGN excludes boats "in
  this slice" only.

**D. Engineering prerequisites for 2 km** (from Part 1 §3): a new profile
without the extent assertion, after pruning old profiles; keep blocks native
and expose column queries instead of copying 96 MiB three times; run the
existing centre-anchored composition per region tile with its own anchor;
parallelise the floods; replace the whole-map horizon with a clipmap; save
resource records as deltas; an entry-time budget of ten seconds. A dense 2 km
field is 384 MiB native only; 4 km is 1.5 GiB and needs column compression or
on-demand generation from the pure noise. Recommend 2 × 2 km as the next
world, 4 km only after on-demand columns.

**E. Order.** Rivers, biome tables and the Steppe fix first (about a week,
generator and tuning, testable in `tests/sim`); then sprint, roads and cart
(one to two weeks); then the 2 km profile (two to three weeks); then force
transport tiers as content waves.

## 2.4 Look and feel: cull the small assets, fill the barren biomes

**Register.** `external-audit-evidence-2026-09-18/asset-register.csv` lists
every runtime mesh under `game/` (tests and experiments excluded): 382
meshes, 4.34 million unique triangles, 767 MB on disk, with triangle counts,
texture presence, vertex colour, rigging and animation counts per file.

| Kit folder | Meshes | Triangles | Textured | Flat colour | Note |
| --- | --- | --- | --- | --- | --- |
| `assets/authored` | 117 | 1,071,067 | 54 | 63 | creatures (21 rigged), cataclysm ruins, strange fixtures and finds |
| `c1`, `c3` | 21 | 1,188,232 | 16 | 5 | bog oak and resinheart trees at 219,000 triangles each at LOD0 |
| `r1` | 6 | 462,003 | 6 | 0 | pines and broadleaf at 98,000 to 131,000 at LOD1 |
| `land02b` | 4 | 274,142 | 2 | 2 | gallery column 146,640 and arch 122,088 |
| `c5` | 30 | 179,236 | 0 | 30 | ore veins, all 5,974 to 5,976 triangles: one generator, several colours |
| `land02` to `land05` | 28 | 139,944 | 0 | 28 | force hosts, ribbons, fans, strata |
| `rf02`, `rf06b`, `rf07`, `rf08` | 12 | 29,173 | 0 | 12 | reclaimed-frontier plants and shingle |
| everything else | 164 | 992,148 | mixed | mixed | building materials, stations, devices, boulders, grass |

Three things stand out.

1. Four meshes hold more than a fifth of all triangles: the c1 and c3 tree
   LOD0s at 219,000 each and the land02b column and arch at 146,000 and
   122,000. Stylised games run trees at 2,000 to 20,000; these are ten to a
   hundred times heavier, and visible LOD transitions are already recorded
   in the ART-07 receipts. They are not the "crappy" ones, but they are the
   ones that cost.
2. The small flat-colour set is exactly what the owner is reacting to.
   Twenty-six meshes under 400 triangles with no texture: the strange
   fixtures (lamp 88, landing 88, bellows 104, lever 104, winch 156, basket
   244, sorter 280), the rare finds (empty husk 40, arm 64, lanternheart 140,
   thrumroot shell 266, low outcrop 272, vent case 342), four fire ember
   meshes at 72, deadfall 158, stump 256, three strata pieces at 160, two
   grass LODs and the root link. Most are gameplay objects seen close up,
   and they sit in the same frame as a 219,000-triangle photo-textured tree.
   The full list is in the CSV under `textured_materials = 0`.
3. Two shading languages. 233 textured PBR meshes, mostly from the
   image-to-3D pipeline, and 149 flat-colour meshes from scripted Blender
   and procedural generators never sit together under one light.

**Triage proposal.** Grade each CSV row keep, replace or remove:

- Remove or hide: flat-colour props under about 300 triangles that carry no
  gameplay (ember meshes, deadfall, stump variants, unused grass LODs). In a
  barren biome, empty beats bad. Fewer, better objects.
- Replace as one batch under one material rule: the 13 strange fixtures and
  finds, the 30 ore veins, fires and stumps. One Blender session, one rule
  (matte two- or three-tone vertex colour plus an emissive force seam,
  consistent silhouette scale). These are the objects the player must find
  and use, so they deserve the most consistency, not the least.
- Decimate and re-LOD the four giants to about 30,000 at LOD0, 8,000 at LOD1
  and 1,000 at LOD2 with cross-fade transitions, and atlas their textures.

**Barren biome recipe.** What makes Valheim's Plains or Enshrouded's deserts
feel vast rather than empty is not prop count:

- the ground carries the detail: macro colour variation from two noise
  octaves on albedo, a micro detail normal, and dense wind-blown grass where
  the biome allows;
- three to five large silhouettes per square kilometre (15 to 30 m rock
  formations, dead giant trees, meteor spires) instead of three hundred
  small props;
- atmospheric depth: height fog and haze that read distance, a warm and cool
  split, dust in the wind;
- sky and light per biome (the `biome_mood` hooks exist), a real night sky,
  cloud shadows;
- sound: wind gusts and distant calls;
- one visible reason to cross, on every horizon.

For Dry Steppe specifically: its own node table (B above), tall grass tufts
in wind, mesa banding using the strata pieces at landform scale rather than as
160-triangle props, husk and bone finds, ram packs.

The global lighting and post pass from Part 1 §5 stands and should land
before any new kit is produced.

## 2.5 Revised order, given the owner's answers

1. Combat feedback, Moments 0 and 2 first (about a week). The owner's most
   felt problem, and zero sim risk.
2. Asset triage plus the barren-biome recipe, with Dry Steppe as the pilot
   (about a week). No new kits until done.
3. Rivers and per-biome node tables (about a week), verified in the headless
   sim tests.
4. Jolt and physics-interpolation trial (one day), before any rigid-body
   transport work.
5. Travel sprint, roads and cart; then the 2 km profile.

The Part 1 engineering items (Linux build, CI, save-reset policy, document
archive) remain. The save-reset decision gates item 3: it decides whether
rivers can go into the shared base kernel or must be layered as yet another
profile on top of the frozen ones.

## How Part 2 was produced

Jolt facts come from the Godot 4.5-stable engine source
(`modules/jolt_physics/jolt_project_settings.cpp` and
`shapes/jolt_concave_polygon_shape_3d.cpp`) and the Jolt integration README;
the Godot documentation site was unreachable from this environment. Physics
API usage, combat hooks, sound usage and tuning values were read directly from
the repository. The asset register was generated by parsing every glTF and
GLB under `game/` for accessor counts, materials, skins and animations; the
script is not committed, the CSV is.

---

# Part 3 — Why entry is slow, why frames jar on a good PC, and what the full vision costs

The owner asked, in effect: what is the large-scale implication of the
vision (many mobs, better visuals, real feel, a larger world), why is the
initial load so long for a game this size, how do other games avoid that (a
bigger install? shader caching?), and why do better-looking games with far
more assets run smoothly while this one still hitches on a good PC, which
makes adding anything feel risky. This part answers from the repository's
own numbers. Proposals remain proposals.

## 3.1 Where the entry time goes

`Sandpit._build_world` (`game/scripts/sandpit.gd:102-180`) runs entirely on
the main thread, in one call, with no frame painted in between and no
progress indication. In order: set the profile; `creature_resources.prepare`
and `scenery_resources.prepare` (art preparation for every creature and
scenery kit, whether or not it is near the spawn); the LAND kit prepares;
`terrain.build` (native generation of the whole 1 km world, three 96 MiB
copies of the block field, exact chunks within 128 m, a whole-map horizon
mesh built in GDScript, a whole-map detail mask); then `HabitatSites`,
`StrangeSites`, `CataclysmSites`, `PressurePocket`, `LeylineSource` and
`FrontierSites` each instantiate every site in the world; then all mob packs
register; then landmarks, the board, the peddler and six flocks.

The history of that call, from the project's own reports:

| Date | Build | Measured setup | Source |
| --- | --- | --- | --- |
| 7 Sep | V6, before the art adoptions | 8.96 s, then 5.72 s after INT-07B | `world-performance-2026-09-07.md` |
| 15 Sep | V6 seed 1 with adopted A1/A2 art | 34.4 s | `play03-underground-result-2026-09-15.md:64` |
| 17 Sep | V13 seed 77 | 51.6 s, then 46.2 s | `land05-closeout-result-2026-09-17.md` |

Native world generation has stayed at about 5.5 s throughout. The extra
forty seconds arrived with content: art preparation at entry, whole-world
site instantiation, larger kits, more textures. That is the mechanism behind
the owner's hesitation: in the current shape, every addition is paid at
entry, for the whole world, before control is released. No report breaks the
46 s into phases; the first fix is a timer around each step of
`_build_world` printed as a table, because a load time cannot be reduced
without knowing its parts.

## 3.2 How shipped games avoid this

Five mechanisms, each answering one of the owner's guesses.

1. **Cook offline; the install carries GPU-ready data.** Textures ship in
   GPU block-compressed formats with mipmaps, meshes ship as binary vertex
   buffers with LODs and merged batches, and nothing is parsed or converted
   at run time. So yes, a bigger install is part of the answer: it trades
   disk for CPU. Godot does this at import into `.godot/imported` and packs
   the result into the PCK; whether it helps depends on the import settings
   chosen (see 3.4). Meshes here already load pre-imported
   (`authored_assets.gd:13` uses `load` on imported scenes, and no script
   parses glTF at run time), which is right.
2. **Nothing whole-world happens at start.** Shipped open worlds prepare
   only the area around the spawn before releasing control, then stream the
   rest as the player moves: chunks, sites, actors and their art. Loading
   runs on worker threads behind a screen that paints progress. Here every
   site, pack, resource record and horizon triangle in the 1 km world is
   created before the first frame, on the main thread.
3. **Shaders are compiled ahead of first use.** GPU pipelines are compiled
   per GPU and driver, so they cannot ship fully compiled; games warm them
   behind the loading screen, ship pipeline caches where the API allows, or
   rely on the store (Steam distributes Vulkan and D3D12 pipeline caches
   collected from other players' hardware). Godot 4.4 added ubershaders that
   pre-compile pipelines to reduce first-use stutter in Forward+, Godot 4.5
   added a shader baker option at export, and Godot saves its own pipeline
   cache under `user://` so second launches are faster than the first. The
   88 separate shader files in this project multiply the pipelines to
   compile; a handful of parametrised shaders would cut that. No script here
   warms materials at load.
4. **Generation runs on workers and is cached.** Minecraft writes generated
   regions to disk and never regenerates them; Valheim regenerates zones
   from the seed as you walk, cheaply, and stores only changes; Enshrouded
   streams voxel chunks from disk. Here the deterministic 5.5 s generation
   reruns on every launch on the main thread, and the result is never saved
   (no file access in `sim.gd`, `terrain.gd` or `terrain_chunk_stream.gd`).
   A per-seed cache of the block field, run-length compressed by column, and
   of the composition would turn a repeat entry into a read.
5. **The main thread does almost nothing heavy.** Meshing, cover placement,
   AI, physics and asset decoding run as jobs; the main thread submits.
   GDScript is interpreted and single-threaded and runs an order of
   magnitude or more slower than C++, so the pattern in Godot is: hot paths
   in the GDExtension (already present for terrain faces), `WorkerThreadPool`
   or `Thread` for generation, `ResourceLoader.load_threaded_request` for
   assets, and the main thread only adding finished results to the tree.

## 3.3 Why a good PC still jars

A game that looks better and runs smoother is GPU-bound: its CPU cost per
frame is small and flat, and a bigger GPU or a lower resolution makes it
faster. Wroughtwild is bound on the main thread, in script. The evidence is
in `land05-closeout-result-2026-09-17.md`: an RTX 5090 at 1280 × 720 walks at
a median of 10.9 ms, and the worst frames were 25 ms of GDScript ground-cover
construction, then collision publication and native payload copies. That GPU
would draw this scene in well under 3 ms; the remaining time is CPU work that
no graphics setting can touch. The same applies to entry: 46 s is not
loading, it is computing.

So fidelity is not the variable. Where the work runs is. That is also the
answer to the hesitation: additions that land on the GPU (more triangles
within reason, better lighting, particles, post-processing) are close to free
on this hardware; additions that add main-thread GDScript work per chunk, per
mob or per piece are the expensive kind, and today most content does the
latter.

## 3.4 Asset budget facts

The register in `external-audit-evidence-2026-09-18/asset-register.csv` and
a header scan of every texture give:

| Measure | Value |
| --- | --- |
| Textures under `game/` (PNG plus glTF-embedded) | 723, totalling 753 megapixels |
| Textures at 2048² or larger | 86 (32 in `assets/authored`, 28 in `f5`) |
| Committed texture import files | 44 of 352 PNGs; all 44 are `compress/mode=0` (lossless), 19 without mipmaps |
| PNGs with no import file in the repository | 308 (settings are whatever the owner's editor chose locally) |
| VRAM if every texture is lossless with mipmaps | about 4.0 GB |
| VRAM if block-compressed (BC7) with mipmaps | about 1.0 GB |
| VRAM if BC1 for opaque albedo | about 0.5 GB |
| Scene imports with automatic LOD generation on | 94 of 98 |

Godot has no texture streaming for 3D: every texture referenced by a loaded
scene is fully resident. At the committed settings the texture set alone
approaches the memory of a mid-range GPU, and uploading lossless textures at
load takes four to eight times the bandwidth of compressed ones. The fix is
an import-settings pass, not an art pass: VRAM Compressed with mipmaps for
everything used in 3D, 2048² only for hero assets seen close, atlases for the
small props, and a written texture budget (about 1.5 GB total is a sensible
ceiling for a 6 GB minimum-spec GPU). Automatic LODs being on for most meshes
is good, but LODs reduce triangles drawn, not memory or load time; the four
meshes above 120,000 triangles still need decimating at source.

## 3.5 What the vision costs in the current shape

| Vision item | What it multiplies today | What it would cost after the shape fixes below |
| --- | --- | --- |
| Many more mobs | Full-group scans in guard, ward and swarm verbs (`enemy.gd:1108,1123`), per-mob straight-line chase with no navigation, 60 live cap | Grid-local queries and time-sliced AI make cost near-linear; navigation is the real remaining work |
| Better visuals | Unique shaders (pipeline compilations), lossless textures (VRAM, upload), 100,000-plus-triangle meshes | Mostly GPU time, which has headroom; textures within budget |
| Nice feel | Almost nothing: sounds, particles, camera impulses and hit-pauses are cheap | Same |
| Larger world | Entry time and memory linear in area: whole-world generation, three block copies, horizon mesh, every site and pack instantiated | Entry constant in area (spawn region only), memory per loaded tile, world cached per seed |

The honest implication: the vision is feasible on a good PC, but not by
adding to the current shape. Doubling the world today doubles a 46 s entry
and triples 288 MiB of copies; doubling mobs squares the verb scans; adding
kits adds shaders and lossless textures. After the shape fixes, the same
additions mostly land on the GPU and on worker threads, and the hesitation
can go.

## 3.6 Fix list, ordered by payoff for effort

Entry time:

1. Time each `_build_world` step and print a table. Hours.
2. A loading screen that paints progress, with the build split across
   frames or moved to a thread. Days. Changes how the wait feels
   immediately, and is the scaffold for everything below.
3. Prepare creature and scenery art lazily, when a kit is first needed
   within the stream radius, instead of all of it at entry. Days.
4. Instantiate sites, packs and landmarks per stream tile instead of for the
   whole world. Days to a week, and it is the same change the 2 km world
   needs.
5. Cache the generated world per seed and profile on disk, run-length
   compressed by column, so a repeat entry is a read. Days.
6. Run generation on a worker thread and build the horizon mesh in C++ at
   generation time, cached with the world. Days.
7. Re-import textures as VRAM Compressed with mipmaps, commit every import
   file, and decimate the four giant meshes. Days, mostly waiting on imports.
8. Warm materials behind the loading screen; try the 4.5 shader baker at
   export; consolidate the 88 shaders. Days.

Frame hitches:

1. Move per-chunk ground-cover construction into the GDExtension next to
   the face meshing, and upload each MultiMesh with one buffer set instead
   of per-instance transforms. A week. This is the measured worst frame.
2. Use a coarser collision mesh than the visual mesh for chunks (greedy or
   decimated faces); `set_faces` cost scales with triangle count and cannot
   leave the main thread in Godot. Days.
3. Route every group query in `enemy.gd` through `MobGrid` and time-slice
   AI updates so far mobs think less often. Days.
4. Merge placed-piece collision and meshes per building region once a home
   exceeds a few hundred pieces (Part 1 §4). Days.
5. The Jolt and physics-interpolation trial (Part 2 §2.1). One day.

## 3.7 Budgets to build against

A frame at 60 fps is 16.7 ms and at 120 fps 8.3 ms. A workable split for
this game on a mid-range PC: main-thread script under 3 ms, physics under
2 ms, render submission under 3 ms, everything else on worker threads or the
GPU. Entry under 10 s cold and under 3 s from cache. Textures under 1.5 GB
resident. Measure with the Godot profiler and the `Performance` monitors,
including the pipeline-compilation counters the LAND-05 report already
consulted, and keep one representative walk (the seed 77 outlook route)
as the standing benchmark so every content addition is checked against the
same numbers.

Rule of thumb for the hesitation: add content freely when it is cooked,
streams with the world, and puts its per-frame cost on a thread or the GPU.
Pause when it adds main-thread GDScript work per frame, per chunk or per
mob. Today most additions do the second; after the fixes above, most will do
the first.

## How Part 3 was produced

The setup sequence was read from `game/scripts/sandpit.gd`; entry timings
come from the three project reports cited; import settings were counted from
the committed `.import` files; texture dimensions were read from PNG headers
and glTF-embedded image headers under `game/`, excluding tests and
experiments; VRAM figures are arithmetic on those dimensions with a
one-third mipmap allowance. Godot engine behaviour (no 3D texture streaming,
pipeline compilation on first use, 4.4 ubershaders, 4.5 shader baker,
pipeline cache under `user://`) is stated from engine knowledge and should be
checked against the 4.5 documentation when acted on, since that site was
unreachable from this environment.

## 3.8 What the fixes unlock, and the next ceiling behind each

The owner asked whether that level of optimisation allows more mobs, more
density, more biome diversity, more generation amplitude, and later better
combat visuals and interactions. Yes to all, with one caveat: each item has a
different next ceiling once the current one is removed. Knowing the next
ceiling is what turns hesitation into a budget.

| Vision item | Current limiter | Removed by (3.6) | Next ceiling | What to do when it is reached |
| --- | --- | --- | --- | --- |
| Many more mobs | Every live mob runs its full state machine in `_physics_process` every tick (`enemy.gd:663`); quadratic group scans; a 60 live cap (`mob_packs.gd:29`) | Grid-local queries, time-sliced thinking | Skinned triangles: the new roster is 62,000 to 154,000 triangles per creature (porcupine 154,400; stone husk 109,998; three at 80,000; stag, shrieker, boar and wolf at 62,000 to 68,000), against 11,000 to 24,000 for the older mobs | Decimate creatures to about 8,000 to 20,000 with LODs and far imposters; far mobs move on the height field without physics; beyond a few hundred live, batch steering in the extension |
| Density of cover, props and trees | Per-chunk GDScript construction (the measured worst frame) | Construction in the extension, one buffer upload per MultiMesh | GPU overdraw of alpha-tested foliage plus shadow passes; trees at 25,000 to 220,000 triangles each, one `StaticBody3D` per tree (`resource_node.gd:2`) | Distance fade and LOD on cover, no shadow casting for grass, trees decimated to 5,000 to 20,000, collision as a simple cylinder |
| Biome diversity | Nothing at run time; each authored region adds whole-map floods at entry (19 today) | Per-tile composition | Texture and shader budget per kit (Part 3 §3.4) | Shared material rules and atlases per biome; a handful of parametrised shaders |
| Generation amplitude | Vertical range is 96 cells: base 24 plus scale 28 plus crag 25 plus rim 24 is clamped at `depth - 2` (`v6_base.inc:175`); the dense field doubles in memory with depth | Not on the list: needs run-length or interval columns instead of the dense `uint8` field | Traversal and reachability: the step-up is 0.55 m and the floor limit 45°, so steep ground becomes wall, and the generator throws when homes, sites or supply routes are unreachable (`v6_opening.inc:62,104,123,169`) | Compose passes, switchbacks and ledges as part of amplitude, give mobs slope rules, and let the horizon LOD carry tall features seen from far away |
| Combat visuals and interactions | Almost nothing; combat is silent and instant | Part 2 §2.2 | Pipeline variants from new effect shaders (first-use stutter); simultaneous ragdolls | Warm materials at load; cap ragdolls at about ten; particles and camera impulses are effectively free |

Two items are not covered by the performance list and deserve their own
work: amplitude is a voxel-representation and traversal problem, and mobs in
the hundreds are a creature-mesh and time-slicing problem before they are an
AI problem. Everything else in the vision becomes GPU work once the main
thread stops doing it, and the GPU is the part of the machine that currently
sits idle.

Order still holds: shape fixes first, then content. After them, a content
addition is safe when it is cooked, streams, and costs GPU or worker time;
the owner can add mobs, density and biomes against the budgets in §3.7
instead of against a feeling.

## 3.9 How much of this, and when: sequence versus tandem

The owner asked what share of ordinary game development goes to this kind of
work, whether these problems are already solved in the field, and whether to
focus on them first or run them alongside gameplay and combat work.

**How studios treat it.** Performance is a budget owned continuously and
worked in bursts, not a phase. Frame time, memory and load time are set as
numbers early, checked at every milestone, and hardened in a dedicated pass
before each one; the last stretch before shipping usually carries the
heaviest optimisation. Day to day it is a small share of most people's time
and a large share of a few people's. The distinction that matters is between
architecture and optimisation. Architecture is where work runs: threads,
streaming, data layout, what is cooked offline, what exists per tile versus
per world. Optimisation is making a given piece faster. Architecture is
decided in pre-production, before most content exists, because content
inherits it; it is cheap then and very expensive later. Optimisation is the
opposite: cheap late, wasteful early. Indie teams that defer the first kind
usually pay with a late rewrite of streaming or world loading.

**Are these problems solved?** Yes, as patterns. Chunk streaming, background
loading behind a progress screen, cooked and compressed assets, LODs and
instancing, spatial hashing, time-sliced AI, run-length voxel columns,
flow-field navigation and per-seed world caches are all standard, with
public references. Godot 4 adds known gaps with known workarounds: no 3D
texture streaming, pipeline compilation on first use, GDScript speed, a
single-threaded scene tree. So the risk is not research. It is a predictable
number of weeks of plumbing, which is exactly the kind of work that is
well-specified, testable with numbers, and suited to agent workers.

**Which kind Wroughtwild has.** Almost entirely the first kind. Whole-world
preparation at entry, hot paths in main-thread script, a dense block field
copied three times, a body per placed piece, every mob thinking every tick:
these are shapes, not slow functions. The entry time growing from 6 s to 46 s
as art and content were adopted is the shape taxing content already. The
project is at the last cheap moment for architecture: the vision calls for
adding content at scale, and every addition made before the shape changes
either inherits the tax or gets redone.

**Recommendation: a bounded shape sprint now, in tandem with combat feel,
then a budget discipline.**

1. A shape sprint of about two to three weeks covering the entry list and
   the first two hitch items in §3.6: timing table, loading screen,
   per-tile art and site preparation, cover construction in the extension,
   texture import pass, world cache. Architectural, number-checked,
   agent-suited.
2. In parallel, the combat feedback layer from Part 2 §2.2. It touches
   `player_combat.gd`, `first_person_hands.gd`, `hud.gd` and enemy
   presentation, none of which the shape sprint touches, and it is the work
   that most needs the owner's judgement. Different files, different
   workers, same weeks.
3. Not in tandem: more mobs, denser cover, new biomes, new kits or the 2 km
   world before the sprint lands. Each would be paid at entry and in
   main-thread script today and re-plumbed per tile afterwards.
4. After the sprint, performance becomes a budget, not a project: one
   standing benchmark route (the seed 77 outlook walk), entry time and frame
   percentiles recorded at each integration, the §3.7 numbers as the gate,
   and one hardening week before each owner playtest milestone. Roughly a
   tenth of effort thereafter, concentrated rather than spread.

The owner's scarce resource is their own playtest hours and design
judgement, not agent time. Put the agents on the shape work, which is
specified and measurable, and keep the owner on combat feel and progression,
which are not.
