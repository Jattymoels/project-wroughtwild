# LAND-04 force-host kit

Original directly authored Blender geometry for ordinary V12 force places. The
six meshes were created by `tools/wroughtwild-land04/build_hosts.py`; no
image-to-3D output, concept-image pixels, downloaded mesh or paid service was
used. The recipe reuses this repository's ART07 mesh/tube/leaf authoring helpers.
`source.json` records the selected exports, dimensions, triangle counts and hashes.

Editable master: `D:/Wroughtwild/work/land04-force-journeys/build/land04/source-art/force-hosts.blend`.
The retained recipe regenerates that master and the selected runtime GLBs. Blender
4.5.9 was used. Generated caches and the native DLL are local handoff outputs,
not source-controlled runtime packages.

Blue uses overlapping fen sheaths and thin mineral laminations on supported
native stepped pockets. The dry Rocky Hills fallback uses compact bracts.
White combines asymmetric loaded roots with mineral flakes along the place's
displacement direction. Green uses broad frond-bearing woodland root fans and
a separate low, small-leaved Steppe colony. That secondary colony has no source
or finite-creature owner. Its geometry and emission stop at both native dry gaps.

The native generator owns substantial terrain solids, contact and edit cells.
`journeys.gd` grounds thin roots/scales and foliage onto the current editable
surface, reserves source/route/home space, and rejects unsupported or wet spans.
The low skins and leaves have no separate collision shell. They use the existing
paid-building suppression metadata and are rebuilt after digging. Each anchor
fits inside one terrain chunk so its ground sampling and edit lifetime agree.

`kit.gd` prepares shared meshes/materials during actual entry and validated
Continue. Ground-conformed meshes are specific to their terrain patch; original
meshes and shader materials remain shared. There are no blocking disk resource
loads in the anchor-building callback. Native banks carry the distant silhouette;
close host forms use the existing terrain-cover visibility path.

Vertex colour separates bark, mineral, foliage and narrow pulse insets. White
travels across authored broken strips, Blue lingers in layers, and Green shares
branch-distance UVs through parent and child roots. These cues do not create
energy, stock or work. The existing paid devices retain all simulation rules.
Presentation values and their player-facing purposes live in `settings.json`;
geography values and purposes live in `data/tuning/worldgen-frontier-v12.json`.

The actual-game evidence and remaining appearance limitations are recorded in
`docs/prototype/land04-force-journeys-result-2026-09-17.md`. Mesh counts are not a
claim of artistic success or smooth performance.
