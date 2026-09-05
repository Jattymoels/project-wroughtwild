# Weathered frontier: scenery grounding and a live field profile

Codex (OpenAI), 5 September 2026. The owner accepted the previous pass and
explicitly asked to merge it into main, continue scenery/shadow/performance
work, and move the art away from its cartoon feel without reaching their
V Rising/Valheim grimdark reference point.

Local `main` was fast-forwarded from `e8b8d55` to the reviewed `92313d5`.
This continuation updates D-013 with the owner's revised direction and makes
the weathered presentation the normal sandpit look. Historical visual flags
remain available. No remote push, contour-generation adoption, new roof
unlock, progression retuning or siege-policy decision is part of this work.

## Art result

The landscape uses olive/moss turf, cooler slate, loam and deeper bark/foliage.
Reduced pale fog and ambient fill give daylight more shape. Forest and fen
remain distinct, and the wastes retain their ember accent. This is a material
and lighting pass as well as a colour change; it is not a screen-wide darkening
filter. Threat VFX colours and their gameplay meanings are preserved.

The prop material previously treated authored sRGB vertex colours as linear,
making the palette look pale. The new look enables the proper conversion;
cover vertices are converted for their shader too. Seven-sided crowns, four
staggered branches, greater asymmetry and deeper foliage masses reduce mesh
cost and the uniform stacked-crown silhouette. Shadow bias/range changes
remove the thin bands visible on the isolated pine in the preceding report.

The three active resources are `weathered_look.tres`,
`weathered_woodland.tres` and `weathered_atmosphere.tres`. Each exposes and
explains its controls. The original `crafted_look.tres` remains available.

## Surface and save behaviour

`SurfaceSampler` indexes upward-facing collision/render triangles by column.
It returns the surface nearest a reference height within a bounded distance,
so a cave floor is not replaced by the surface above it. It works immediately
after a rebuild without waiting for a physics frame.

Cover roots sit 0.015 m below that surface. The sampler is recreated with each
dug/restored chunk. Mineral strips are replaced by 24 short spans over their
existing three-metre footprint, with a 0.24 m half-width and 0.018 m surface
lift. Missing support interrupts the ribbon instead of bridging a hole.
Collision picking follows the visible ribbon; it casts no redundant shadow.
Nearby chunk changes reproject the resource without changing its saved anchor,
visual seed, resource yield, wedge progress or crack state. A ground-bound
ribbon no longer scales away from the surface when partially harvested.

The old save loader could restore a depleted resource as a default cylinder.
Saves now optionally record its visual key, while old schema-2 saves recover
generated visuals from the stable generated node name. The schema version and
voxel/save representation are unchanged. Tests use their own file under
`build/`, never the player's ordinary or workshop save.

## Performance

Small resource meshes fade at 65 m, cover batches at 55 m and tree silhouettes
at 200 m, with an 8 m fade margin. These distances affect presentation only.
Chunk-local sampling and reused ribbon endpoints avoid repeated neighbour
queries during construction.

The initial weathered overlook issued 12,935 draw calls and about 4.85 million
rendered primitives. After scenery fades, the same view issued 5,657 calls and
4.12 million primitives. The short stationary frame median fell from 7.41 ms
to 4.17 ms on this RTX 5090 / Vulkan Forward+ PC. This is a local before/after,
not a lower-end hardware claim; captures also include shadow passes.

`field_route.tscn` runs the actual default world, player controller, pack
activation, AI and skill paths for 34 seconds at 1920×1080 with a 120 fps cap
and VSync disabled. It settles for two seconds, records sixteen seconds of
walking, then sixteen of movement/combat. A supplied 24-mob pack ensures load;
the fixture restores player life so the profile can finish. No gameplay tuning
is changed and no save is read or written. Frame intervals include pacing;
the physics monitor is sampled as exposed by Godot, not an isolated CPU/GPU
trace. The machine-readable manifest records every reported distribution.

The initial completed route covered 142.97 m over a repeated 13 m slope path,
peaked at 32 live enemies, cast 26 skills and received attacks on 49 frames.
Walk median/p95: 7.89/9.25 ms. Combat median/p95: 7.65/11.58 ms, maximum 37.16 ms.
A subsequent run after startup-query optimisation reproduced the same distance,
casts, peak population and damage-frame count. Walk median/p95: 7.91/9.21 ms;
combat median/p95: 7.67/11.50 ms, maximum 22.44 ms. Terrain startup was 8.56 s
(0.12 s map, 3.89 s chunks, 4.55 s resources); reducing that synchronous startup
cost remains worthwhile. These are two short runs, not a benchmark guarantee.
The route is longer than the preceding 13.85 m check, but does not
cover a diverse expedition, deep cave navigation or late-game combat.

## Verification and reproduction

From the repository root, using the existing Godot installation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Checks
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Grounding
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -Weathered
powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex_visual_review.ps1 -FieldRoute
```

The full headless pipeline passed: unit 397, art 11, integration 265, horde 43,
grammar 68, feel 17, faceted terrain 66, controller traversal 23, roof workshop
768 and woodland 16 checks, plus the normal-scene smoke run. The existing unit
fixture's off-tree/dummy-renderer diagnostics remain; assertions were not
weakened. No simulation source or tuning changed in this continuation.

The new rendered grounding fixture passes 13 checks, comparing 348 cover roots
and ribbon vertices against independent physics rays before digging, after
digging and after restoration. It also checks cave-floor selection and state
preservation. It requires the renderer because Godot's headless dummy backend
returns zero MultiMesh transforms. The save fixture passes 9 checks covering
the actual default look, isolated disk IO, an older save restoring a depleted
seam, exact geometry restoration and subsequent harvesting. The live field
fixture passes 7 checks; the revised woodland capture passes 18.

Captures and logs remain ignored in `build/codex-aesthetic/`; the committed
gallery source and helper reproduce them. The landscape comparison uses the
earlier contour-study world with fixed cameras for comparison; the field
route uses ordinary world generation. The historical camera names identify
anchors, not guaranteed biome membership after contour regeneration.

## Remaining limits

The result is intentionally more subdued, but still visibly a procedural
prototype. Characters remain capsules, close enemy labels can overwhelm a
combat screenshot, large terrain facets can show self-shadow patterns, and
tree crowns still need richer organic form. Foliage shadow bias is tuned to
the current render scale and needs review on other hardware/renderers.

Tree/boulder roots settle onto nearby surfaces at their anchors; digging out
their entire support does not introduce falling-resource physics. Mineral
ribbons stop where support is absent rather than migrating to another storey.
Thin ribbons can still intersect steep terrain between sampled vertices.
There is no claim of full cave/building/performance acceptance or 20–40 minute
progression-loop completion.

The next useful art pass is character/enemy silhouette and label readability,
then terrain shadow quality and more organic foliage at player height. The
next field review should traverse several biomes and an actual cave route,
with frame captures on slower hardware before any performance promise.
