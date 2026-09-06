# Strange Frontier: natural ground and readable atmosphere

Owner-directed visual continuation, 6 September 2026: the new discoveries were
interesting, but the normal-world images still looked barren and artificial.
This pass gives the terrain a material identity and lets the composed regional
shapes read at player height. Authored regional composition and Blender forms
are handled by the accompanying scene/asset pass.

## Scope and compatibility

Only weathered `frontier_v3` worlds select `wildland_look.tres` and
`wildland_atmosphere.tres`. Explicit historical looks and both older generation
profiles keep their prior resources. Loading an older profile into the same
scene restores its original sky and contact-shading settings. The underlying
terrain field, heights, mesh positions, collision, resource placement, harvest
rules, threat palettes and saved world identity are unchanged by this pass.

`Terrain` selects the resources. `BiomeMood` still owns the existing day/era
colour transition and sun angle; it reads the selected atmosphere's biome
values. Neither resource introduces another clock or a weather simulation.

## Ground and stone

`wildland_terrain.gdshader` uses the existing neighbour-blended material colours
as its foundation. Broad irregular weathering sits above smaller broken turf
and soil detail, so surfaces belong to continuous landforms rather than a tile
per block. Exposed loam interrupts grassy areas; dry turf appears in restrained
patches; soft moss catches on upward stone shelves. The rock treatment uses
broken bedding and matte mineral highlights instead of drawn dark fracture
outlines.

Fine apparent relief modifies the lighting normal only. It does not displace
terrain or change its silhouette, player grounding or collision. Pixel
footprints fade fine grit before it can shimmer at distance. World-space
coordinates keep colour and material detail coherent across chunks and digs.

| Setting | Initial value and purpose |
| --- | --- |
| `patch_metres` | 21 m: tie local surface detail into larger continuous ground patches. |
| `colour_variation` | 0.48: give the broad fields visible variety while keeping stronger colour accents for finds and threats. |
| `soil_exposure` | 0.70: mix exposed loam into recognisable worn grassy pockets. |
| `stone_moss` | 0.24: let horizontal stone collect a little moss without turning every cliff green. |
| `loam_colour`, `moss_colour`, `dry_colour` | Earth/olive/straw accents used inside the existing weathered palette. |
| `grain_metres` | 0.075 m: give near ground granular interest, filtered at distance. |
| `bump_height_m` | 0.018 m of apparent fine relief, with unchanged geometry. |
| `rock_bump_m` | 0.04 m of calmer mineral relief so light describes stone weathering. |
| `rock_roughness` | 0.78, varied gently by weathering: subdued mineral response, never mirror-like wet terrain. |

The new material retains the existing cover and scree budgets. Its shader does
not add a second geometry pass, a texture dependency or generated surface nodes.

## Light, atmosphere and sky

The lighting resource uses a little less ambient fill and more readable direct
sun. Short-range ambient occlusion seats roots, stones and objects on the
ground. The proven directional shadow bias stays in place while local ambient
occlusion supplies close contact depth. The meadow stays warm; open uplands stay
cooler; forest and fen remain
watchful while thinner distance fog reveals their middle-distance shapes.

The sky now has a blue upper gradient, a softer warm horizon and quiet cloud
banks. Cloud shape is a static procedural presentation field, with no weather
state or gameplay shadow. The existing day and era tint applies to the sky,
clouds, fog and directional light.

| Setting | Initial value and purpose |
| --- | --- |
| `ambient_energy` | 0.34: maintain readable shade while direct sunlight supplies shape. |
| `shadow_distance` | 105 m: concentrate shadow detail on nearby vegetation and authored forms. |
| `shadow_bias`, `shadow_normal_bias` | 0.08 / 1.5: retain stable terrain self-shadowing; ambient occlusion supplies close contact depth independently. |
| `contact_radius_m` | 1.35 m: local contact depth under roots, stones and furnishings. |
| `contact_intensity`, `contact_power`, `contact_detail` | 1.35 / 1.20 / 0.65: restrained contact shading rather than dark outlines over the whole scene. |
| `sky_fog_fraction` | 0.08: separate the far terrain without bleaching the sky. |
| Biome fog density | Meadow 0.0013, uplands 0.0016, forest 0.0032, fen 0.0038, wastes 0.012: retain local mood with clearer middle-distance silhouettes. |
| `cloud_coverage`, `cloud_opacity`, `cloud_scale` | 0.61 / 0.40 / 7.6: a higher noise threshold leaves more open sky; lower opacity and smaller shapes keep the clouds subordinate to the landscape. |
| `cloud_colour`, `ground_sky_colour` | Warm pale clouds and muted earth beneath the horizon; the existing day tint darkens them. |
| `sky_update_seconds` | 0.25 s: update gradual sky colour changes without requesting a new lighting cubemap every display frame. |

The sky's ambient/reflection cubemap uses a cheap gradient at 128-pixel
resolution. Cloud noise runs only for the visible background. This follows
Godot's documented separation between background and cubemap sky passes;
the sky avoids a `TIME`-driven per-frame cubemap update.
[Godot 4.5 sky shader reference](https://docs.godotengine.org/en/4.5/tutorials/shaders/shader_reference/sky_shader.html).
The apparent material relief uses analytic world-space noise gradients,
projected onto the surface tangent plane and transformed into view-space
normals. Fragment pixel derivatives are used only to fade distant grain.
[Godot 4.5 spatial shader reference](https://docs.godotengine.org/en/4.5/tutorials/shaders/shader_reference/spatial_shader.html).

Actual player-height captures and matched performance measurements belong to
the combined `frontier_polish_review` before/after review. These tuning choices
are presentation defaults; screenshots alone do not establish frame-time cost
or certify that a region is enjoyable to explore.

The first rendered review exposed a dotted triangle grid in the ground relief,
and overly large clouds dominated the fen approach. A fixed Uplands diagnostic
removed bump, SSAO and directional shadows separately: only removing bump
eliminated the grid. Continuous analytic noise gradients replaced screen-space
height reconstruction; the corrected rendered view is clean with both relief
and contact shadows enabled. Smaller, sparser clouds now fade away near the
horizon. The five-mode `wildland_diagnostic` scene preserves that review setup;
it passed 11 scene checks with no renderer errors, and its images were inspected.

The existing `weathered_save` check now exercises both directions of v3/v2 save
loading in one live scene. It checks the original sky, every modified SSAO/fog
property and the actual cached terrain shader; reentry must select v3 art again.
Separate day/night/era samples ensure the new sky keeps the existing clock,
era tint and sun movement without mutating native player/world state.
The focused Godot 4.5 headless run passed **21 checks, 0 failures**, including
the twelve new lifecycle checks, with no stderr output.

## Targeted performance correction

The first final Uplands static sample exceeded the 10% investigation threshold:
p95 was 1.558 ms versus the original 1.357 ms. Four independent repeat windows
were 1.551 / 1.548 / 1.624 / 1.390 ms. The original before/after data remains
intact; that result was investigated rather than omitted.

The shader now skips the fine grain's eight corner hashes and gradient work
when its existing distance filter is exactly zero. The grain already contributes
nothing at those pixels, so the material's colour, normal and roughness output
is unchanged. Near grain, broader relief and lighting keep the same calculations.

The targeted `--polish-perf-check` rerun uses the same fixed Uplands camera,
1440×900 Forward+, and four 600-frame windows. It returned p95 values
**1.387 / 1.348 / 1.340 / 1.367 ms**, or at worst **2.2% above** the original
baseline. Median frame times were **1.154–1.163 ms**, **4.2–5.0% above** the
original 1.108 ms. Both pre- and post-optimization targeted views submitted
980 draws and 1,008,163 primitives. The screenshot was inspected and remains
clean. The scene passed 8 checks, with no renderer errors.

The pre-optimization targeted manifest and images are preserved under
`build/frontier-polish/perf-investigation/pre-grain-skip`; current targeted
evidence is under `build/frontier-polish/perf-check`. These settled static
measurements isolate this correction; they do not replace the combined walking
and streaming review or predict performance on other hardware.

The final combined pass subsequently recorded a Fen p95 of 2.223 ms against
the original 1.807 ms, while an earlier pass of that final composition was
1.829 ms. A separate `--wildland-fen-perf` diagnostic investigated the flagged
sample without changing presentation. It follows the same prior Uplands pose,
then fixes the exact Fen camera and completed terrain/resource set. Four
600-frame windows run with regional dressing shown, four hidden, and four
shown again; each window has 90 warmup frames.

| Fen phase | Median range | p95 range | Draw calls |
| --- | --- | --- | --- |
| Dressing shown initially | 1.380–1.388 ms | 1.837–1.852 ms | 1,717 |
| Dressing hidden | 1.297–1.321 ms | 1.728–1.791 ms | 1,608 |
| Dressing shown again | 1.366–1.379 ms | 1.814–1.842 ms | 1,717 |

Across these window summaries, showing the composition added approximately
0.066 ms to the mean median and 0.069 ms to the mean p95, around 5.0% and 3.9%
relative to the hidden view. It submitted 109 more draws and approximately
373,000 more primitives. These are means of window summaries, not percentiles
of one combined frame population. The 2.223 ms primary sample remains recorded;
it did not recur in the eight shown windows, and its exact cause is unproven.
The diagnostic passed 9 scene checks with empty stderr, and both visibility
states were visually inspected. Evidence is under `build/frontier-polish/fen-perf`.
