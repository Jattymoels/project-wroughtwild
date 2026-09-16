# RF-07 highland recovery kit

Four original scripted Blender forms, in metres: curled tough tussock, woody
heath, prostrate cushion growth and settled shingle. These are cosmetic meshes;
native terrain, resources, collision, inventory and save records remain owners.

- Editable master: `D:/Wroughtwild/source-art/rf07-highland-recovery/rf07-highland-master.blend`.
- [Recipe](../../tools/wroughtwild-rf07/build_kit.py) and [art purposes](../../tools/wroughtwild-rf07/art.json).
- [Selected export dimensions and hashes](source.json); runtime GLBs in `assets/`.
- Recipe uses the existing `tools/wroughtwild-art07/b2/geometry.py` geometry helper.
  Run it from this checkout using SETUP's Blender with `--background --python-exit-code 1`.
- Recipe/art JSON, compact source report and the four exports are also beside the
  D: master. No external asset, network dependency or reference pixels were used.

Direct modelling suits open woody branches and thin blades. ENV-007 supplies
rock relationships and recovered-landscape intent, not geometry or textures.
Existing large stone ribs/outcrops keep their established regional anchor recipe;
the former scattered regional sedge/scree yields to supported chunk-local detail.

## Visible tuning

[settings.json](settings.json) explains every placement/support control. Fifteen
metre seeded pockets respond to nearby native rises and existing rock footprints;
2.5% exposed-root coverage rises to 94% in sheltered hearts. These are candidate
probabilities, not measured world coverage. Full footprints can be rejected by
terrain, approaches, water and paid-work clearance. Small cushions fill narrow
supported edges; fragments form parent/ledge-associated bands.

The [ground shader](ground.gdshaderinc) owns a deliberately quiet fixed palette:
`rf07_stone_dark` is cool weathered rock, `rf07_stone_light` is worn exposed stone,
`rf07_lichen` is restrained olive growth, and `rf07_soil` is darker accumulated
pocket soil. Source-colour uniforms perform the required colour conversion.
The mask's exact biome and original height limit this to highland top surfaces;
interpolated pocket values join adjacent cells. Roughness is matte and relief is
reduced locally so the broad shelves do not look like pale, granular snow.
[stone.gdshader](stone.gdshader) shares muted bedding and lichen between the
existing large outcrops and new shallow shingle. It displaces no vertices.

Resources prepare at actual world construction before movement is released.
MultiMeshes use the existing chunk lifetime, full triangle support and RF paid
floor/station clearance. Wind uses the existing pause-aware clock. No live
whole-world scan, per-frame resource load, new ecology, terrain profile or save
field is added. Legacy V1-V5 and non-highland eligibility remain unchanged.

## RF-09 material cleanup, 16 September 2026

RF-09 keeps these original meshes, seeded roots, support probes and reservations.
The large regional ribs/outcrops and shingle use `stone.gdshader`, now sharing
`mineral.gdshaderinc` with the ground. World-space nonperiodic weathering replaces
sine bands. The GLTF plant vertex colours are already linear; they are not decoded
again. Only the scoped shared leaf material changes; tree materials do not.

Visible tuning (shader uniforms, reconstructed material data, never save state):

- `rf07_mineral_dark` / `rf07_mineral_light`: cool slate to warm weathered mineral,
  authored as sRGB (.265,.29,.315) / (.57,.55,.50), converted once by source_color.
- `rf07_oxide` / `rf07_lichen`: sparse warm face weathering and olive upper-shelf
  growth. Irregular noise and surface orientation limit their coverage.
- `rf07_mineral_relief=.045`: 4.5 cm apparent weathering, normal response only;
  detail fades with pixel footprint. Geometry/collision do not move.
- `rf07_ground_mineral_gain=.76`: ground mineral is darker than standing outcrops.
- `rf07_pocket_fringe=.10`: existing pocket context begins its turf/litter blend
  early enough to join low plant edges and clear working ground. No extra roots.
- RF-02's retained turf/litter/detail maps tile at 2.4 m with a rotated second
  sample. They now bind on highland rock as well as grass/dirt during world entry.
- Shared `leaf_colour_gain=1.90`: lifted leaf reflectance with wrapped diffuse
  and retained backlight. Sky-facing normal blend is .64 for fen/impact and .52 for
  highland leaves, following the established RF-02 grass lighting pattern. No
  emission, global exposure or clock change.

The fen material interpolates its existing patch colour (exact eligibility and
original top height still gate it) and uses less dark turf/litter multipliers.
This connects material below the adopted fen/bank groups without shrinking real
source/work/route reservations or defeating narrow-terrace support rejection.
The RF-08 creeping mat receives the same leaf response; its masks, ground/scar
materials, digging checks and exposed-only pulse remain unchanged.
