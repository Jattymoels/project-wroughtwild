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
