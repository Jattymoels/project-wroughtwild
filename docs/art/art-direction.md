# Art Direction — "Weathered Frontier, Dark Thresholds"

**INT-05A, 7 September 2026:** [Forge readability](../prototype/forge-readability-2026-09-07.md)
uses the existing dark thresholds and authored room kit. Restrained shared
stone/iron silhouettes distinguish physical route seals, offerings, lifts,
secret catches and ward conduits. Warm ready marks remain dimmer than danger;
spent marks become cool worn metal and secrets stay matte. Compact current-route
words avoid filling the gallery with future choices. Exact hostile footprints
use a dark inward edge and warm clock-driven stroke beneath depth-tested cover;
player-owned fields remain distinct. This bounded pass does not settle the
owner's broader graphical finish or select a new art style.

Latest owner playtest, 6 September 2026: the graphics still fall below the desired
finish, described as resembling an old Newgrounds game. Earlier acceptance was
temporary; the existing style is not final visual approval. A small playable
visual target and more specific owner influences are proposed in the
[feedback record](../prototype/playtest-feedback-2026-09-06.md). The current lore,
readable daylight and weathered direction remain; no new visual style or asset
service is adopted by this observation.

Latest owner graphics request, 6 September 2026: the supplied reference brings
forward a pass on leylines and the five rare resources. Weathered, branching
dark fractures contain narrow cool light; rough organic/mineral hosts hold
distinct small cores and fine luminous detail. Ignore the reference character
and interface. This revises the earlier inert/dotted trace presentation while
preserving its native placement, accidental origin and gameplay contracts.
[Approved work and review](../prototype/leyline-resource-visual-2026-09-06.md).

Owner-approved Northstar, 6 September 2026 (D-030): **extreme augmentation**
already belongs to the forge, bench and Foundry, and now shapes the land and
living things. The frontier is a low-technology alien world devastated by a
meteorite shower carrying augmentation technology. The [accepted premise](../world-premise.md)
and [approved intensive](../prototype/cataclysm-world-intensive-2026-09-06.md)
establish one visual sequence: surviving local life and craft → directional
impact damage → exaggerated host properties → deliberate player reuse.

Rootvault exaggerates growth and stored tension; Lantern Fen concentrates light
and pressure; Glasswind expresses charge and attraction. Quiet remnants show
their former scale. These are accepted regional interpretations, not new damage
types or resource gates. Readable meadow daylight, open approaches and existing
danger colours remain authoritative. A decorative seam must not imitate an
attack tell. D-031 now approves one bounded pressure feeder. Its source is an
accidental strike through an old pre-cataclysm smithy; only the player's newly
built machinery contains and uses it. The owner accepts the current visual
finish for now; a later graphical pass is deferred.

Implemented V4 history provides three impact compositions, connected traces and
six supported ruins linked to existing discoveries. The [shared authored kit](cataclysm-kit-2026-09-06.md)
uses practical timber/reed/stone structures, worn forked channels, pale embedded
metal and short lamellae. Mostly inert details connect regional materials to
the Forge and contained workshop components. [Native placement and compatibility](cataclysm-generation-2026-09-06.md)
preserve all three older world profiles. Asset-plate and native test evidence
are separate from the intensive's normal-world visual/performance review;
implementation does not imply final human acceptance of the art.

Owner correction, 6 September 2026: the Strange Frontier concepts work, but the
rendered places are still too barren and amateurish. The [approved refinement](../prototype/frontier-art-refinement-2026-09-06.md)
prioritises connected natural silhouettes, clustered canopy/understory, wet
margins and broken ground, plus coherent surfaces and atmospheric depth. Preserve
clear gathering approaches and meadow daylight. More identical oversized props
or uniformly scattered grass do not meet that direction.

Owner continuation, 6 Sep 2026: following the Blender building study, the owner
selected land/nature fixtures. A six-role authored-mesh study now covers the
existing broadleaf tree, boulder and decorative shrub/fern/deadfall/stump roles.
Those local nature studies subsequently entered normal gameplay through the
habitat and regional art work. [Original assets, verification and limits](blender-nature-study-2026-09-06.md).
V4 adds shared augmentation details to common broadleaf trees and field boulders
only where the native influence field warrants them; older profiles and quiet
ground retain their plain resource presentation.

The furnishing continuation covers chest, campfire, workbench, mason's yard and
both forge tiers. The adopted station meshes now receive restrained contained
augmentation detail on the workbench, yard and forge tiers. The original studies
record existing-body collision checks and separate station-height fit proposals;
the Cataclysm pass does not adopt a new gameplay body or station interaction.
[Furnishing assets, collision findings and limits](blender-furnishings-study-2026-09-06.md).

The owner then selected mobs. The Blender pass now covers the existing twelve
actors, with simple rigs, preview clips and an explicit comparison against their
current capsules. Their reviewed meshes are now integrated through the normal
spawn and `CreatureMotion` path. Existing combat clocks drive the poses; imported
clips do not change attacks or bodies. Status materials and boss tells remain
dominant. [Original study](blender-mobs-study-2026-09-06.md) and
[actor/craft implementation, checks and remaining body-fit limits](cataclysm-actor-craft-2026-09-06.md).

## Current owner revision — 5 September 2026

Latest clarification: the improved workshop **building** look, including its
octagonal construction, is approved for normal play along with the stations.
Ordinary buildings now share the timber boards, darker framing/undersides and
calm stone treatment. The chamfer/slab/roof catalogue is adopted as recorded in
[the normal-building report](codex-normal-building-2026-09-05.md), superseding
the earlier lab-only statements below. The demonstration house is still a
review scene; the parts, materials and save support are available in normal play.

The owner accepted the crafted terrain/tree/workshop pass for merging into
`main`, then requested a less cartoon-like direction, further toward grimdark
than that pass but lighter than their V Rising/Valheim reference point.
This deliberately revises D-013's original storybook saturation and cubic-only
terrain presentation. The older brief below is retained as history.

The current target is **an earthy, weathered frontier with readable daylight**:
olive and moss greens, slate and loam, restrained warm sun, stronger shape
shadows and less pale aerial wash. Forest/fen feel watchful; the wastes retain
their ember accent. Blood, gore and an everywhere-dark exposure are not needed.
Resources and danger signals must remain distinguishable at player height.

The normal sandpit now uses the smoother editable terrain and the revised
palette/atmosphere. `--legacy-look`, `--frontier-look`, `--faceted-look` and
`--crafted-look` retain explicit historical comparison modes. The contour
generation and modular-roof catalogue remain isolated studies; ordinary world
generation, construction unlocks and resource economics are unchanged.

Presentation values live in `game/art/weathered_look.tres`,
`weathered_woodland.tres` and `weathered_atmosphere.tres`. Prop vertex colours
are authored as sRGB and converted correctly in the new material. The main
terrain tones are olive `(0.285, 0.365, 0.20)`, forest moss
`(0.16, 0.235, 0.155)` and weathered slate `(0.35, 0.365, 0.37)`.
Threat VFX retain their established palette. See the
[implementation and field evidence](codex-weathered-frontier-2026-09-05.md).

The owner's subsequent screenshot feedback asks for **surface interest without
returning to the old block distinction**. Smooth silhouettes must not become
blank moulded surfaces: use broken stone bedding, mineral fractures, granular
loam, worn turf and sparse physical fragments. The first character silhouette
pass replaces capsules while preserving their gameplay bodies and threat
colours. These are procedural prototype forms, not finished animated art.
See [surface and character follow-through](codex-surface-character-2026-09-05.md).

The next owner review favours the live meadow image but rejects the cliff's
abrupt rock/soil/turf delineation and the loose stones' amateurish appearance.
The follow-through now blends actual adjacent surface materials, keeps their
cores recognisable, and uses fewer, smaller, partly buried irregular slabs.
Uniform pyramid scatter and loud drawn fracture outlines are not the target.
See [material-join refinement](codex-material-joins-2026-09-05.md).

The owner then invited non-environment work while noting that the world remains
barren: almost everything rising above tiny grass is a tree or stone. This is
a content/composition gap as well as a material issue. The owner then approved
all four follow-ups: first-person presence, environment variety, recognisable
places and equipment comparison. The implemented middle layer uses brush,
fern beds, short rotten deadfall and stumps in habitat patches and clearings.
Existing cairns, altars and rifts gain worn edges and distinct inlays; trees
immediately around them become bare snags with unchanged harvest behaviour.
Small rotten debris is decorative, without new yields. See the
[four-part continuation](codex-frontier-continuation-2026-09-05.md) for evidence,
tuning and remaining prototype limitations.

The next implemented presentation slice is creature motion: distance-driven
gaits and poses tied to the existing combat clocks. See
[motion evidence and next priorities](codex-creature-motion-2026-09-05.md).

## Historical brief — 1 September 2026

Status: accepted direction (D-013). Owner's brief (1 Sep 2026): a compromise
between Minecraft's *"always looking over your shoulder within dark places or
enemy areas but otherwise light and happy"* and PoE/Diablo's *"completely
grimdark macabre"* — and blockish, to go with the world.

## The one-sentence direction

**The overworld is a bright, generous frontier; danger is told by light
draining out of the world, not by gore.**

By day in safe country the game reads like a storybook: saturated grass,
warm sun, long views. As you walk toward threat — the Ember Wastes, a
dungeon threshold, deep forest — saturation drains, fog thickens, the sun
goes amber and weak. The *place* feels wrong before the first enemy
appears. That is the whole compromise in one rule: **Minecraft's palette,
PoE's use of darkness.** We never need severed heads; a horizon the colour
of cold ash does the work.

## Pillars

1. **Light is information.** Bright = safe, dim = dangerous, ember-glow =
   fire danger, cold blue = frost mechanics. Players should be able to
   read threat level from a screenshot with the UI off.
2. **Saturation is the mood dial.** Safe biomes sit near full saturation;
   hostile ones desaturate toward grey-brown with one accent colour left
   burning (the wastes keep their ember orange). Never fully monochrome.
3. **Chunky, not childish.** Blocky terrain, chunky props, readable
   silhouettes — but weathered surfaces, honest shadows and no outlines or
   googly-eye cuteness. Think "hand-carved", not "toy".
4. **Menace without gore.** Enemies are ash, stone, ember and bone-white —
   elemental and wrong, not wet. Violence feedback is flash, shatter,
   scorch and dust, never blood decals.
5. **One palette to rule them all.** Every texture, enemy tint, fog colour
   and VFX colour comes from the master palette below. Cohesion in a
   procedural/greybox game comes almost entirely from palette discipline.

## "How many polygons can a blocky game afford?" (owner question)

Short answer: **polygon count is not the constraint — authoring time is.**
A desktop GPU comfortably draws several million triangles per frame; our
whole 96×96 block terrain is a few hundred thousand at worst, batched into
a handful of MultiMesh draw calls (already done). "Blocky world" is an art
*choice*, not a performance ceiling, and it does NOT force blocky
everything:

- **Terrain / buildings:** stay cubes with 16×16 pixel textures. This is
  the grid the player builds on; blockiness here is legibility.
- **Props (trees, boulders, stations):** chunky low-poly, ~100–1,000
  triangles each, flat or palette-textured. Crooked silhouettes beat cubes.
  *Implemented for nodes:* `game/scripts/prop_mesh.gd` grows trees (~84
  flat facets: crooked hexagonal trunk + three warped-icosahedron canopy
  lobes), boulders and rust-shot iron veins procedurally, flat-shaded with
  palette vertex colours, deterministic per world position. Owner note
  (1 Sep 2026): props must NOT read as Minecraft — the blocky look stays
  on terrain and buildings only.
- **Characters (player hands, enemies, boss):** free to be smooth-ish
  low-poly, ~1,000–5,000 triangles — Valheim's characters are in this
  range and read beautifully next to its chunky world. Faceted "crystal"
  shading (flat normals) keeps them in-family with the blocks.

The blend of blocky world + non-blocky creatures is exactly the
Minecraft-mod / Valheim / Cube World lineage the brief points at, and it is
the cheapest style a solo dev can keep consistent.

## Master palette

Single source of truth. The texture generator
(`game/assets/textures/generate_textures.py`) and the biome mood table
(`game/scripts/biome_mood.gd`) both draw from it; new art must too.

| Token | Hex | Used for |
| --- | --- | --- |
| `meadow_grass` | `#62963E` | meadow surface |
| `meadow_grass_light` | `#8CBC56` | grass accent pixels, safe-zone VFX |
| `forest_floor` | `#2E5429` | forest surface |
| `forest_loam` | `#563C26` | forest accent, roots |
| `stone` | `#74747A` | rocky hills surface, boulders |
| `stone_dark` | `#565860` | stone shadow accent |
| `dirt` | `#6A4C30` | cliff filler, paths |
| `dirt_dark` | `#523A26` | dirt accent |
| `bark` | `#5C4026` | tree trunks |
| `bark_dark` | `#402C1A` | bark accent |
| `leaf` | `#306A2A` | tree crowns |
| `leaf_dark` | `#204C1C` | leaf accent |
| `ash` | `#342E2E` | wastes surface — near-greyscale on purpose |
| `ember` | `#EC6E1E` | THE danger accent: wastes glow, fire VFX, melee mobs |
| `cinder_red` | `#C72E1A` | ranged fire mobs, damage flash |
| `iron_rust` | `#C4742C` | iron veins, forge glow |
| `frost` | `#8CD2F0` | chill/freeze VFX, frozen mobs |
| `frost_deep` | `#4682B4` | frost accents, fast mobs |
| `sky_day` | `#598CD9` | sky top, safe |
| `haze_day` | `#C2D0DE` | horizon/fog, safe |
| `haze_forest` | `#8CA88C` | forest fog |
| `haze_ash` | `#61504A` | wastes fog — the "wrongness" colour |
| `sun_warm` | `#FFF5E0` | sun in safe country |
| `sun_ember` | `#FF9E66` | sun over the wastes |

Rules of thumb: one accent colour per surface, never two; danger accents
(`ember`, `cinder_red`) are *earned* — they only appear where fire can hurt
you; `frost` belongs to the player's kit until frost enemies exist.

## Biome moods (implemented)

`BiomeMood` crossfades sun colour/energy, fog colour/density and ambient
level toward the biome the player stands in (~2 s blend). This is the
direction made playable:

| Biome | Feel | Sun | Fog |
| --- | --- | --- | --- |
| Meadow | storybook safe | warm, bright (1.35×) | thin, pale blue |
| Rocky Hills | crisp, exposed | neutral white (1.2×) | very thin, cool |
| Deep Forest | closed-in, watchful | green-filtered, dim (1.0×) | green, medium |
| Ember Wastes | oppressive, burnt | amber, weak (0.75×) | heavy grey-brown |

Dungeon interiors (Wave 4) push one step past the wastes: near-dark with
ember or frost as the only strong colour — the PoE end of the dial, still
bloodless.

## Texture rules

- 16×16, nearest-neighbour filtering, generated deterministically by
  `generate_textures.py` (pure stdlib; rerun after palette edits).
- Each texture = one palette base tone + per-pixel brightness jitter + one
  accent token at low frequency. No gradients, no noise octaves — the
  chunky read comes from restraint.
- New surfaces must take their base and accent from the palette table.

## Out of scope for now (deliberately)

Day/night cycle, weather, character models, animated foliage, post-FX
beyond fog/tonemap, and any texture above 16×16. Each becomes worth doing
only after the block world reads coherently with what is here.

## Codex comparison experiment

**Codex experiment note, 5 Sep 2026:** the owner authorised an opt-in aesthetic
comparison. [Results and reproduction](codex-aesthetic-experiments-2026-09-05.md)
document continuous terrain materials, tapered cover and a procedural prop
winding repair. Authored and implemented by **Codex (OpenAI), not Claude**.
The material candidate is experimental; this accepted direction remains the
default. The prop repair restores the intended exterior faces in both looks.

The owner-authorised [Codex continuation](codex-aesthetic-intensive-2026-09-05.md)
adds opt-in faceted terrain, fresh-world contour comparisons and an octagonal
workshop study. The gallery now separately demonstrates the prop winding
repair; it did not redesign tree silhouettes or terrain cliffs. No default
art rule is superseded. The workshop's hipped roof is decorative lab geometry.

The [next experimental pass](codex-crafted-frontier-2026-09-05.md) adds
`--crafted-look`: shared terrain lighting normals, gradual turf blending and
branching biome trees. A separate playable workshop uses real modular roof
pieces and an isolated save. Its framing, station detail and lights remain
lab dressing; D-013 is still the default direction.
