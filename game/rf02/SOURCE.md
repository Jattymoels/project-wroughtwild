# RF-02 sources and bindings

Original local art for meadow/woodland in the existing V6/LF game. No external
asset, reference-image pixels, paid service or new dependency.

- Editable Blender master:
  `D:/Wroughtwild/source-art/rf02-ground-grass/rf02-grass-master.blend`
- Original surface maps, deterministic paint recipe and provenance:
  `D:/Wroughtwild/source-art/rf02-ground-grass/`
- Rebuild recipes: `tools/wroughtwild-rf02/author_ground.py`,
  `build_grass.py`, `grass.json`. Run recipes from this repository. The Blender
  recipe reuses the tracked B2 `geometry.py` Mesh helper and curved-strip method.
- Small source receipts are adjacent: `surface-source.json`, `grass-source.json`.
  Four retained B2 near/middle GLBs were inspected once for their curves,
  rooted bounds and subdivisions. Their exact paths/hashes are in the receipt.
  The old master/package and supplied landscape originals were unchanged.
- Standard Blender Z-up to glTF/Godot Y-up conversion, metres, roots at zero.
  Two separate editable clumps: meadow 78 blades / 1,404 triangles; asymmetric
  edge 46 blades / 828 triangles. One opaque vertex-colour surface each.
  Short basal blades, tapered folds, curved stems, dark roots and restrained tips.
- RF01 retains its circular fit: radius 0.47 m, meadow height 0.38 m,
  edge height 0.2508 m. R7 still advances the pause-aware wind clock; period and
  maximum bend remain 5.5 s / 0.018 per metre. RF01's scatter, nine support samples,
  reservations and moving-footprint suppression are unchanged.
- Two 1024-square sRGB albedo maps plus two linear detail maps. Detail RG stores
  signed X/Z relief slope; B stores roughness. These are not standard normal maps.
  Lossless import with mipmaps; anisotropic sampling in the shader. No displacement.
  Periodic painting wraps primitive edges; rotated world-space scales and broad
  variation soften repetition. No retouching was applied to game captures.
- `ground.tres` documents texture scale, apparent detail and broad variation.
  `grass.tres` documents colour, normal treatment and transmitted light.
  Terrain builds a temporary native-biome mask once per loaded world.
  The optional shader hook defaults off, and nearest-cell eligibility keeps other
  biomes untouched. Native interpolated colours/stone weight and augmentation
  tint remain in the surface path.
- Global look resources, native terrain/collision/data, saves, RF01 placement,
  paid rules, other plants, visibility distances and batching are unchanged.

See [the worker result](../../docs/prototype/rf02-ground-grass-result-2026-09-15.md)
for evidence, limitations and exact playtest commands.
