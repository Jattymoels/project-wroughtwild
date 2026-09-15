# RF06B original wetland kit

Editable master: `D:/Wroughtwild/source-art/rf06b-fen-art/rf06b-wetland-master.blend`.
All five objects are separately editable meshes, rooted at zero, in metres.
Blender Z up exports through the standard glTF Y-up conversion.

Original direct Blender authoring using the retained B2 Mesh/tube/leaf helpers.
No external assets, image pixels, raw reconstruction, model downloads or paid service.
Thin folded leaves and compound fronds were authored directly because reconstruction
is poorly suited to their open silhouettes. Local image-to-3D was an available
option, not used for these forms. Existing global tree art is unchanged.

Recipe: `tools/wroughtwild-rf06b/build_kit.py`, parameters `art.json`.
Both are retained alongside the master. `source.json` records selected exports,
geometry counts, dimensions and SHA256 values. Runtime assets are five GLBs in
this folder's `assets/`. Materials preserve original per-vertex leaf/fibre colours;
small anchored wind uses the existing pause-aware R7 clock, with bounds included
in support and paid-building clearance. No gameplay collision in the exports.

The ordinary RF06 compositor uses `settings.json` for linked low cover, curved
rush fans, broad ferns, rare root accents and a lower winding passage band.
Supported fringe variants bridge narrow terrace edges. Actual biome/water,
chunk boundaries, excavation and paid ownership still constrain every footprint.
