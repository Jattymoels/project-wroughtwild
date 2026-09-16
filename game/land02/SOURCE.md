# Scarwater art and reproduction

Original Project Wroughtwild work for LAND-02, 16 September 2026. No downloaded
asset, paid service or new dependency is used. The LAND-00 concept images and
owner references supplied composition direction; they are not game evidence or
copied terrain stamps.

Run `tools/wroughtwild-land02/build_kit.py` with the existing background Blender
4.5.9 installation. It reuses this repository's mesh/leaf construction helpers
from `tools/wroughtwild-art07/b2/geometry.py`. The recipe writes the nine runtime
GLBs here and one editable master:

`D:/Wroughtwild/work/land02-scarwater-basin/build/land02/source-art/scarwater-kit.blend`

`source.json` records each export's hash and purpose. `gallery-column` and
`gallery-fork` are tall and spreading variants with asymmetric braced roots,
trunks, branch fans and individual leaf sprays. They replace ordinary harvestable
trees only in the new Gallery biome; yields, work and finite ownership remain
ordinary wood. Three strata forms, two root banks and two underwood forms supply
supported near-ground structure. Their geometry is decorative; the native
terrain owns walking, collision and digging.

The shared kit is prepared during real V9 New World/Continue construction before
controls release. Chunk placement reuses its meshes/materials. The deep inset
pulse also uses one prepared mesh/material. No asset file loads on first arrival.

The terrain itself is authored by `sim/src/worldgen_frontier_v9.inc` and immutable
`data/tuning/worldgen-frontier-v9.json`, not a Blender landscape. Shared near/far
bedding follows the seed's displacement direction. A small broken branching
pulse follows the actual native floor; excavation removes segments whose original
floor was removed. Normal paid-building suppression applies to the middle
vegetation and pulse. Gallery ground reuses RF-02 woodland textures.

`settings.json` controls middle growth spacing, density, size, support tolerance,
root burial and visible distance. `atmosphere.tres` keeps the existing day/era
clock and provides readable shaded Gallery/rock values. Shader colour, bedding
spacing and pulse speed are presentation defaults, never resource/gameplay rules.
The source recipe describes the authored metre-scale dimensions. Native ridge,
cut, candidate, passage and bank dimensions are documented with their JSON inputs.

Source master and import caches remain local on D:. Commit the recipe and selected
GLBs, not `.blend`, DLLs, `.godot`, private saves or review packages.
