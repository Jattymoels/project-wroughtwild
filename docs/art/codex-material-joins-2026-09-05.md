# Material joins and restrained ground detail

Owner-directed continuation from `79c801d`, 5 September 2026.
Implemented by **Codex (OpenAI)** on local main.

## What changed

The owner preferred the normal gameplay meadow view, but found the comparison
cliff's rock/dirt/grass transitions low quality and the loose stones amateurish.
The main problem was separate material assignments: texture variation could
not blend the boundaries between those assignments.

The native mesh presentation now optionally accepts the engine resource's
sRGB palette. Every shared lattice corner averages the colours of exposed
solid cells among its eight neighbours. Face centres mix that average with
55% of their own material, retaining a recognisable core. Colours are linear
for lighting; alpha carries the stone-detail weight, not transparency. The
shader blends rock/earth detail using that weight, so its pattern also crosses
the join. Smaller, rotated noise octaves replace the stronger square grain;
rock fractures are interrupted and fade before becoming distant aliasing.

The eight-cell stencil matches the existing chunk invalidation footprint. A
palette changes no mesh positions, normals, collision faces, source cells,
block yields, world-generation tuning or save schema. Historical comparison
modes omit the palette. The palette is an engine-layer presentation argument,
not a dependency from the simulation rules into engine art.

Loose stones now have broad irregular tops, sloping sides and partly buried
bases. Three deterministic outlines share meshes. The total base density is
0.09 (previously 0.28), width 0.24 m (0.34 m), height 0.055 m (0.10 m). They
remain non-colliding decoration, distinctly smaller than gathering boulders.

The character meshes receive gloves, belts, a shoulder strap, guard breastplates
and collars, and a horned boss silhouette. Status and telegraph materials remain
intact. The flock's prism blocks become swept wings and split tails with an
offset wingbeat. Orbit/count are unchanged; birds remain purely decorative.

## Controls and reproduction

`weathered_look.tres` adds `blend_materials=true`; palette colours retain their
plain-language resource names. `grain_metres=0.05` controls grain scale. The
stone density/width/height values above have updated resource explanations.
The historical turf slope thresholds apply to unblended materials; blended
terrain uses its real material neighbours. The 55% face-core mix is the fixed
mesh interpolation kernel, rather than a gameplay parameter.

`flock.gd` exposes wingspan 0.8 m, wingbeat 1.2 Hz and wingtip lift 0.22 m,
with inline explanations. Colour and shader motion are presentation only.

Build the extension with the documented CMake build. The PowerShell visual
review helper provides:

- `-Checks`: full headless regressions, including the new material tests.
- `-Weathered`: material tests, five fixed-camera terrain images and woodland.
- `-Grounding`: renderer-backed scenery/dig/restore checks and save compatibility.
- `-Characters`: presentation checks and a paused studio of actual actor meshes.
- `-FieldRoute`: real player movement and combat in normal world generation.

The previous five terrain captures were preserved under
`build/codex-aesthetic/material-control`; current images are in
`landform-weathered`. These share the contour study's fixed terrain and camera.
The `field-route` images use normal generation. The gallery identifies both.

## Verification

Native build succeeded. The full headless suite passed: unit 397, art 11,
integration 265, horde 43, grammar 68, feel 17, faceted terrain 66, traversal 23,
roof workshop 768, woodland 16, save compatibility 9, presentation 29 and
material transitions 74. Inherited unit off-tree/dummy-renderer diagnostics
remain; the other suites were clean. Rendered woodland passed 18 checks.

The new 74-check suite verifies unchanged collision/source cells; a colour per
vertex; shared material/chunk corner agreement before digging, after a corner
dig and after restoration; exact restoration; and three distinct low-profile
stone meshes with outward nondegenerate faces. Rendered grounding passed 16
checks, ray-testing 420 plant/stone origins in each of three terrain states.

The isolated rendered field route passed all 7 checks: 142.97 m travelled,
32 peak enemies, 26 casts and 49 damage frames. At 1920×1080 Forward+ on the
RTX 5090, capped at 120 fps, walking median/p95 frame intervals were
7.811/9.331 ms; combat was 7.663/11.606 ms. The preceding `79c801d` run measured
7.851/9.214 ms and 7.662/11.594 ms respectively. These are short paced samples,
so small differences should not be treated as GPU performance changes.

Terrain startup increased from 8,023 to 8,437 ms (about 5%); mesh construction
rose from 4,187 to 4,638 ms with the shared material sampling. Resource placement
was 3,677 ms. The blend currently accepts this measurable startup cost; no
asynchronous loading or generation changes were introduced.

## Remaining limits

The cliff's overall shelf geometry remains voxel-derived. Material blending
improves the join; it does not create erosion, overhangs or geological fractures
in the actual cliff silhouette. Grazing-angle shadow facets remain visible.
The art is still procedural prototype art, and character limbs remain rigid.
The small stone origins are grounded, but their edges can intersect steep banks.
The short profiling route is not a complete playthrough or a hardware survey.
