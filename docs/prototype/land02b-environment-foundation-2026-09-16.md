# LAND-02B environment foundation

Implemented production decision, 16 September 2026. See the
[result and game pictures](land02b-scarwater-production-result-2026-09-16.md).

The world is a three-dimensional editable block field, not a heightmap. The
demonstrated limitations are project choices: V9's broad ridge height functions,
midpoint-only surface crossings, averaged normals and a coarse height-only
horizon remove fractured forms before art can describe them. Godot's mesh,
physics and PBR facilities do not require those restrictions.

V10 retains the one-metre gameplay/ownership grid and adds bounded continuous
density samples around Scarwater. Seeded tilted rock volumes and intersecting
joints participate in generation. Feature-preserving surface extraction consumes
the same occupancy and density, retaining exact per-triangle editable owners.
One triangle stream supplies rendering, collision and surface queries. Removed
cells override the density locally; regenerated density is not a second save
owner. Existing profiles keep their published generator and extraction paths.

The distant landmark consumes the same surface, with exact-chunk masking.
Material scale, rock relief, canopy structure, water and lighting were revised
in the ordinary scene. Shared resources prepare at entry. Later biomes can reuse the density
and extraction path without a global resolution increase or a new terrain engine.

Source leads: `sim/src/worldgen_frontier_v10.inc`, `sim/include/wroughtwild/worldgen.h`,
`game/extensions/wroughtwild_sim/src/wroughtwild_sim.cpp`,
`game/scripts/terrain_chunk_stream.gd`, and `game/land02b/`.

## Source-backed corrections

| Observed restriction | Implementation and ownership |
| --- | --- |
| V9's broad ridge and maximum-old-hill terrace raised both routes into a retaining wall | Independent V10 tilted, rotated, chamfered volumes, diagonal crown cuts, separated joints and eroded toe. Routes stay at the bank until the actual workshop climb; original cave air sets the required lip height |
| Midpoint crossings and averaged normals lost the planes | Regularised QEF extraction reads eight cell-centre samples per corner. Disconnected solid components receive distinct vertices. A 2 cm dual-cell interior margin avoids exact collapse |
| Applying the cliff solver to a quantised gentle step produced a roughly 46-degree face | Intact gentle roofs average continuous top crossings; steep, cave and edited faces retain density extraction. Controller movement rules are unchanged |
| Height-only distant terrain could not represent the fracture silhouette | Exact distant Scarwater triangles prepare once at entry. UV2 tags each triangle's owner chunk; the stream masks that owner when nearby/edited detail replaces it. Fragment-position masks were inappropriate for slanted triangles that cross chunk boundaries |
| Painted bands and small-scale noise obscured material form | Shared shader body, a neutral mineral map at about 8.7 m per repeat, broad weathering, roughness and restrained filtered relief. V10 two-sided rendering matches the established backface-enabled terrain contact |
| R1 `native_tree.gd` erased the selected Gallery mesh after the base resource installed it | V10 bypasses that old replacement after installing the generated/authored assembly and reduced solid-wood contact. Existing resource IDs, finite work/yields, fall and saves remain |
| Fixed sun direction and simple water flattened the basin | V10 day-compatible sun azimuth follows the seeded basin. Cool fill, warmer sun, shadows and shallow/deep fixed-water response describe the planes without a new weather or water system |

## Contact and persistence

The same native triangles feed rendering, `SurfaceSampler`, concave physics and
per-face `source_cells`. A ray therefore removes the owner of the visible hit.
Original cave air, later protected foundations and removed cells override
inconsistent generated density. Existing local rebuild and diagonal-neighbour
invalidation update contact and appearance together; edited chunks remain exact.
The eight-cell stencil does not require a larger edit halo.

Density is regenerated from profile/seed, not saved as another owner. Fresh New
World selects the separate immutable V10 file. V9/older/LF keep published inputs
and extraction paths; no save schema, economy or coloured LF acquisition changes.
Four 14 m home cores, lake original beds and finite pressure identity remain.

## Reusable consequences and limits

Later profiles can reuse the density carrier, component-aware extraction,
owner-based distant handoff and material path. Scarwater selects a bounded local
field/envelope; this is not a new global framework or resolution increase.
Sub-cell appearance does not create a new mining unit. Outer country retains
the existing coarse horizon, and deep cave generation remains its earlier path.

Tree meshes, contact shapes and texture prepare and remain shared at real world
entry. Reduced contact represents the generated root/bole; upper authored
branches and foliage are visual. Exact distant geology adds entry work and
retained geometry. No broad performance or minimum-hardware claim follows from
the scoped checks. The result records the remaining planar faces, repeated
crowns and outer-country limits separately from owner aesthetic approval.
