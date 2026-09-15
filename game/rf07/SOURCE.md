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
