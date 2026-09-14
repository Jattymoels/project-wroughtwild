# ART-07R6 source and envelope choices

R6 retains the G1 game/data/native pin
`6bb2e044dcd0bf1788896aa2c19cdf56fee93522`. The C5 source seal is
`7b5f6338140c9d0500586fc55991b69e853e002ebc258641488728992e282494`.
The full-input verification includes every C5 entry, the original G1 runtime,
G2 review and all four published predecessor packages. R6 consumes no repair
delta from those predecessors; their publication releases the wave.
The C5 source/receipt worker commits were
`1ae07672d313e3f4ae82e5832ca51bc04fe65e60` and
`a740e4dbd89c106a0b945a01c87cfad24fba7321`; the recorded published commits are
`b4bd986baa14e48f7ad871d0df204658f8429e40` and
`0e16ed03167ac3002da11fcde591555eac5a2ef3` in
`docs/prototype/art07-production/publication-2026-09-11-batch5.json`.

The existing choices are:

| Choice | Existing contract | R6 disposition |
| --- | --- | --- |
| C5 kit-v08, using v07 geometry | Organic B3 host, approximately 2.48 × 0.50 × 0.78 m in Godot axes, bounded by the existing 2.6 × 0.6 × 0.9 m fallback body; 90 stock/crack/LOD exports | Retained byte-for-byte for fallback bodies. A projected field atlas reuses the original vertex mineral/scar data for the faceted material. |
| Native `GroundedSeam` | Three-metre ribbon, maximum 0.48 m width, 24 spans, up to 144 triangles; 0.018 m support lift, no closed volume; missing support or a >0.5 m step interrupts its bands | Retain every vertex, collider triangle, transform and native gap. Apply an ore-specific material only. |
| A raised C5 slab on ordinary faceted terrain | Its height is about 28 times the native lift and its width is about 1.6 times the maximum ribbon width. The native ribbon supplies neither a matching body nor carved seating volume | Unapproved. Requires an explicit decision selecting any changed collision/target envelope or terrain seating/excavation behavior. R6 implements neither. |

C5 v01–v06 diagnostic candidates are not new approved alternatives: C5 records
regular marking, budget/bounds/degenerate failures, and a voxel reduction that
damaged the visible surface. R6 uses the selected packed master and shared C5
albedo/ORM instead of reviving those rejected candidates.

The faceted treatment uses the existing source colours, roughness and metallic
response and the actual selected C5 mineral/scar vertex fields projected from
the top of each full cold/cracked model. One 512 × 1280 RGBA atlas contains ten
512 × 128 rows: mineral, scar, normalised source height and source coverage.
The material reads the mineral/scar/coverage channels; it never displaces a
vertex. The source geometry and existing albedo/ORM remain byte-identical. A
new packed-master copy adds only that derived atlas and editable controls.
Relief and cracks are shading only; there
is no displaced surface, additional shell, depth offset, raised rim or scatter.
It does not claim the same volumetric silhouette as the fallback source.
The selected altered direction's physically recessed scar is likewise not
claimed for this thin native ribbon. Approving such a recess would require the
terrain-seat/excavation decision described above; the material-only option leaves
that geometry unapproved and available for owner review as a measured limit.

Current native stock divided by the full definition selects how much mineral
remains. Worked host still covers the native picking ribbon, so the material
does not invent a smaller target. Exhaustion hides the ribbon before the native
retirement scale animation can detach it from a slope. Native deletion and
collision retirement remain inherited. The full definition, rather than the
stock present at `_ready`, keeps a partially loaded resource visibly partial.

`ember_iron_vein` is the resource family, while `ember_vein` is its actual native
visual key. R6 adds that key to isolated G1 dispatch. Stable generated IDs such
as `wnv6_…` are never rewritten into art-family IDs.

Presentation tuning and its purposes are in
`tools/wroughtwild-art07-repairs/r6/surface.json`; inherited C5 colours and
material values remain in the unchanged copied `game/c5/kit.json`. No gameplay
tuning, shape, recipe, body, terrain rule or saved field is introduced.

Owner visual acceptance and ordinary-world rollout remain separate. The final
receipt reports only the actual checks and evidence completed for this candidate.
