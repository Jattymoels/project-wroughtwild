# Art Direction — "Bright Frontier, Dark Thresholds"

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
