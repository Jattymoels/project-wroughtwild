# Surface definition and character silhouettes

Owner-requested continuation, 5 September 2026. Implemented by **Codex (OpenAI)**.
Parent: `d8c00da`, already on local main. No remote push or save migration.

## Outcome and scope

The supplied photo showed broad grey and orange-brown surfaces with little
detail. The normal weathered look now adds world-space mineral plates, warped
stone bedding, granular soil, worn turf and small physical stone fragments.
The soil is less orange. Existing smooth terrain geometry, exact digging
selection and collisions remain unchanged. No generation or progression rules
were introduced. Roof and contour studies remain isolated.

A significant cause of empty ground was the earlier cover-distance optimisation:
MultiMesh instances remained at world origin while their plants were stored at
world coordinates. Nearby grass could therefore fade out. Batches now sit at
their plants' mean position and store local transforms; rendered grounding tests
check both their actual world positions and the fade origin.

Capsules are replaced by one-surface procedural forms: clothed player/peddler,
four-legged whelps/hounds, six-legged crawlers, shield-bearing guards/knights,
small suspended wisps and a larger Tyrant. Existing family tints, elite colour,
freeze/burn/hit feedback and boss breath material remain. The first-person body
still renders only its shadow; third-person uses the same silhouette. Collision
shapes, attack ranges, life and damage are unchanged. Elite enlargement now
preserves the family's original visual scale.

## Presentation controls

All new adjustable values include plain-language purposes in their resources.

| Resource / value | Current value | Effect |
| --- | --- | --- |
| weathered_look.surface_contrast | 0.55 | Broken material colour, stone fractures and soil grain; zero disables new shader detail |
| strata_metres | 0.32 m | Average stone bedding spacing, independent of the voxel grid |
| grain_metres | 0.11 m | Fine grain scale, filtered at distance |
| scree_density | 0.28 | Base per-cell chance, multiplied by the existing sparse/lush patch distribution |
| scree_width / height | 0.34 / 0.10 m | Small decorative chips, below harvestable boulder size |
| weathered_woodland.variant_count | 48 per biome | Shared branch meshes shorten construction and reduce duplication |
| weathered_atmosphere.shadow_bias / normal_bias | 0.08 / 1.5 | Reduce self-shadow stippling on terrain and foliage |
| character_look.name_font_size / pixel_size | 32 / 0.006 | Source glyph size and world-space scale |
| name_reference_distance | 6 m | Cap close projected label size |
| name_distance / name_focus_degrees | 24 m / 16° | Hide distant or peripheral overhead names |

Fragments are non-colliding, non-harvestable decoration. They use the same actual
triangle sampling as grass and refresh when their chunk is rebuilt. Existing
resource ribbons still carry the gathering interaction. Shader detail remains
world-anchored across chunk boundaries and excavation.

## Startup work

Removed disposable legacy trees and seam meshes built immediately before their
weathered replacements. Shared 48 deterministic tree variants per biome, keeping
per-resource rotation and state. Cached barycentric coefficients for repeated
surface queries; local offsets avoid cancellation at the far edge of the map.
Ground-cover biome entries are prepared once per chunk rather than per cell.

## Validation and evidence

Final checks passed: unit 397, art 11, integration 265, horde 43, grammar 68,
feel 17, faceted terrain 66, traversal 23, roof workshop 768, woodland 16
headless / 18 rendered, save compatibility 9, presentation 29 and rendered
grounding 16. Grounding independently ray-checks 593 plant/fragment roots at
each of the original, dug and restored states. The existing unit suite emits
its inherited off-tree/dummy-renderer diagnostics; other suites were clean.

The final isolated field route passed 7 checks: 142.97 metres, 32 peak enemies,
26 skill casts and 49 frames receiving damage. Measured on the local RTX 5090,
Godot 4.5 Forward+, 1920×1080, 120-fps cap:

| Measurement | Parent pass | Final pass |
| --- | --- | --- |
| Terrain construction | 8,560 ms | 8,023 ms |
| Chunk construction | 3,886 ms | 4,187 ms |
| Resource construction | 4,550 ms | 3,712 ms |
| Walk frame median / p95 | 7.912 / 9.209 ms | 7.851 / 9.214 ms |
| Combat frame median / p95 | 7.671 / 11.500 ms | 7.662 / 11.594 ms |
| Combat maximum frame | 22.441 ms | 36.919 ms |

This is a modest ~6% overall startup reduction while adding decoration and
restoring visible cover; the resource phase is ~18% faster. The earlier 7.2s
intermediate result preceded final scenery/precision changes and is not the
shipped timing. Frame p95 is effectively unchanged; the worse single combat
spike remains a limitation. Frame intervals include pacing and are not isolated
GPU measurements. No other review process ran during this final route.

Reproduce from the repository root with `tools/codex_visual_review.ps1`:

- `-Checks`: existing full headless suite, including 29 presentation checks.
- `-Grounding`: renderer-backed grass/chip/seam checks before dig, after dig and
  after restoration, plus the existing old-schema-2 resource save regression.
- `-Weathered`: five fixed-camera terrain views and four-biome tree studio.
- `-Characters`: presentation regressions, then actor mesh/material studio with AI paused.
- `-FieldRoute`: full normal generated world, real controller, AI and skill casts.

The presentation tests cover outward mesh winding, single-surface mesh budgets,
preserved enemy collider dimensions, damage/freeze feedback, boss telegraph
material, trade interaction, near/far/behind-camera labels and 231 barycentric
samples on a sloping triangle at the far map edge, including exact vertices.

The gallery is `build/codex-aesthetic/index.html`. Terrain images under
`landform-weathered` use the unchanged contour **study**, with the same camera as
the owner's photo. `field-route` images use normal world generation and actual
play. `characters/silhouettes.png` is a paused studio, not an animation demo.
Historical spawn/overlook/forest images from the parent were preserved in
`weathered-smooth-control` before editing. Generated images/builds remain ignored.

## Known limits and next useful work

- Character forms remain rigid procedural prototypes. Separate limb animation,
  stronger family-specific anatomy and authored cloth/armour detail are still
  needed; this is a silhouette/readability pass.
- Terrain's large voxel-derived shelves remain. New surface detail cannot
  replace geological shape variety; a generator change would need its own work
  item because it affects routes and saves.
- Shallow self-shadow triangles remain at grazing sun angles. A trial of normal
  perturbation produced thin artefacts and was removed; the shipped shader adds
  colour detail and uses actual small geometry for relief. Stronger bias softens
  very shallow shadow contacts.
- The narrow stone fractures can alias at very long distance; grain is filtered.
- Ground decoration is sampled at its origin; a fragment edge can intersect a
  steep bank. Fragments do not imply an additional collectible material.
- Startup remains synchronous and material shaders cost more than the previous
  near-flat colour. The short route is not a broad hardware or balance benchmark.
