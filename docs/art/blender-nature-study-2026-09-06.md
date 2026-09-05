# Blender land and nature fixtures — 6 September 2026

Author: Codex (OpenAI). Owner direction: "After this, go with the land/nature
fixtures", following the Blender bridge and building study.

This implements the next authored-mesh study under the current D-013 weathered
frontier direction. D-003/world placement, D-010 collision authority and the
existing decorative habitat rules remain in force. The six existing roles are
represented once each: broadleaf tree, field boulder, shrub, fern bed, rotten
deadfall and stump. No new resource, harvest reward, collider rule, save field,
world generator or third-party dependency is introduced.

The tree has a tapering bent trunk, transported branch frames (avoiding twists
at vertical tangents), rooted foot and connected leaf sprays with sky gaps.
The boulder has irregular weathered planes, broken moss coverage and a buried
foot. Brush and curved pinnate ferns occupy the current habitat radii. Jagged,
recessed heartwood distinguishes the small rotten debris from harvestable trees.
Each fixture exports as one mesh and one vertex-colour material. The landscape
surface and turf are display aids, not a replacement for editable terrain.

Presentation colours come from `habitat_look.gd`, `weathered_look.tres` and
`weathered_woodland.tres`, including its foliage darkening. Parameters and plain
language purposes are in [`nature.json`](../../tools/wroughtwild-blender/nature.json).
There are no new gameplay tuning values.

| Fixture | Triangles | Collision policy |
| --- | ---: | --- |
| Broadleaf tree | 10,264 | Existing trunk box: 0.7 × 3.0 × 0.7 m, centre y=1.5 |
| Field boulder | 1,428 | Existing resource box: 1.4 × 1.0 × 1.2 m, centre y=0.5 |
| Shrub | 558 | Decorative; existing 0.65 m habitat radius |
| Fern bed | 1,364 | Decorative; existing 0.5 m habitat radius |
| Short deadfall | 158 | Decorative; existing 0.85 m habitat radius |
| Stump | 256 | Decorative; existing 0.4 m habitat radius |

The MCP now exposes `build_nature_study` alongside the building recipe. The
[tool README](../../tools/wroughtwild-blender/README.md) gives the commands.
Both recipes run through the real stdio protocol without a live Blender window.

Validation: all six geometry/colour builds repeat deterministically, with finite
vertices, no degenerate faces and the four decorative footprints in bounds.
Godot 4.5 passes **90 nature checks**, including single-mesh/material import,
linear vertex-colour preservation, ground pivots, original collision dimensions,
and real player-sized capsule sweeps. The trunk/boulder block movement, the
canopy and decorative cover leave paths clear. The original **34 building
checks** and **five MCP protocol tests** also pass.

Two integration details were caught during verification. Convex generation
slightly approximates decimal box dimensions; the nature post-import script
retains the existing primitive BoxShape3D contracts instead. The visual review
uses the game's Forward+ renderer: Godot's vertex-colour conversion flag is not
effective in Compatibility, which produced a dark preview. See the
[Godot material reference](https://docs.godotengine.org/en/4.5/classes/class_basematerial3d.html#class-basematerial3d-property-vertex-color-is-srgb).
The exported glTF colours remain linear, without a compensating palette change.

Reviewed local artifacts:
`build/blender-study/4edb355cba98473a959dc83e4235c986/` contains
`nature-study.blend`, six visual GLBs, two collision GLBs, `report.json`,
`nature-landscape.png`, `nature-ground-detail.png` and
`godot-review/nature-godot.png`. Outputs and portable Blender stay ignored.
Sandbox warnings about OS certificates, editor settings and GPU cache locations
remain environmental; local logs, asset generation, imports and tests finish.

Limits: this is an asset study, not normal-world integration. Wind, animation,
biome variants and a dense-forest performance pass are outstanding. The boulder
and trunk retain broad existing box collision rather than following every
visible facet/root. Integration must use the existing resource bodies and
harvesting/grounding lifecycle, and preserve non-colliding habitat placement.
No game-wide suite was run because only authoring/review tools and documentation
changed; concurrent gameplay work was left untouched.
