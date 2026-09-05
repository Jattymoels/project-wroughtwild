# Blender furnishing mesh and collision study

Owner continuation, 6 September 2026: "When done, then go through all the
furnishing", following the building and land/nature studies. This pass covers
the complete existing functional furnishing catalogue: workbench, mason's yard,
basic forge, improved forge, chest and campfire. No new furnishing gameplay,
recipes, costs, save data or third-party art dependencies were introduced.

The local Blender MCP now offers `build_furnishings_study`. Its reviewed recipe
authors portable GLBs and a Blender source scene using the station palette:
weathered timber, darker structural joinery, dressed/soot-stained stone, quiet
forged iron and restrained embers. The chest has separate body/lid meshes and a
rear hinge. The closed lid fits the original collision box instead of overhanging
it. The two workstations carry small decorative hand tools; the improved forge
retains its distinct taller hood and iron bands.

Affected systems are authoring/export and isolated Godot visual/physics review.
D-013's revised weathered frontier direction, D-010's engine-owned time/space,
existing construction addressing and the accepted station silhouettes remain
the basis. The current D-026 crafting work is unaffected. The source reads
`construction.json`, `station_site.tscn`, `piece_mesh.gd` and `station_look.gd`.
Art controls, with plain-language purposes, live in
[`furnishings.json`](../../tools/wroughtwild-blender/furnishings.json).

## Assets and review files

Latest reviewed output, ignored by Git:
`build/blender-study/df9a298ee40b48c0bc1f6d9dfc25cbaf/`.

| Asset | Triangles | Meshes | Material surfaces |
| --- | ---: | ---: | ---: |
| Workbench | 1,004 | 1 | 3 |
| Mason's yard | 872 | 1 | 5 |
| Basic forge | 2,400 | 1 | 5 |
| Improved forge | 2,924 | 1 | 5 |
| Chest | 1,776 | 2 | 5 |
| Campfire | 1,028 | 1 | 3 |

- `furnishings-study.blend`: hidden SOURCE collection at actual game pivots,
  plus a visible catalogue display. The chest lid node is `chest_lid_hinge`.
- `furnishings-catalogue.png`, `furnishings-workshop.png`: Blender renders.
- Six visual GLBs with embedded colour textures and six existing-body proxies.
- Four `*_fit_collision.glb` station candidates, described below.
- `godot-review/furnishings-godot.png`: actual Godot 4.5 Forward+ imports.
- `godot-review/furnishings-collision.png`: green existing bodies, amber candidates.
- `report.json`: source paths, bounds, pivots, collision contracts and geometry hashes.

## Collision finding and proposal

Every current StationSite uses a **0.96 x 2.0 x 0.96 m box** centred at local
(0, 1, 0), even though the workbench and mason's work surfaces are only 0.95 m
high. The study preserves and tests that body as its compatibility baseline.
The visibly empty space above a bench therefore still blocks the player and
physics rays in the current game.

**Proposal, not adopted:** retain the same horizontal obstruction and simple
solid box, but lower its height to the relevant surface/silhouette:

| Station | Existing height | Candidate height | Purpose |
| --- | ---: | ---: | --- |
| Workbench | 2.0 m | 0.95 m | Clear the air above the working surface |
| Mason's yard | 2.0 m | 0.95 m | Same; small workpieces/tools remain decorative |
| Basic forge | 2.0 m | 1.575 m | Match the lintel's top |
| Improved forge | 2.0 m | 1.96 m | Match the taller hood |

The candidates remain solid beneath the furniture and inside the hearth; this
proposal does not introduce leg-by-leg collision or a new body composition.
Review player jumping/stepping, above-table projectiles and interaction targeting
before applying it to normal StationSite instances. No game collider was changed.

The chest keeps its construction size **1.0 x 0.7 x 0.8 m** and local centre
(0, -0.15, 0); its floor is Y -0.5 m. The campfire retains its **0.8 x 0.25 x
0.8 m** low box centred at (0, -0.125, 0); its floor is Y -0.25 m. Review displays
lift these sources to their floor; runtime integration must retain the original
cell anchors. The low fire pile has no new masonry ring or material requirement.

## Verification

- Blender completed through the actual MCP stdio protocol. A second fresh process
  reproduced all **16 GLBs byte for byte**, including embedded textures.
- Geometry checks reject non-finite coordinates and degenerate triangles, and
  verify floor anchors and station/chest horizontal fit before export.
- **302 furnishing checks passed** in Godot 4.5. The checker runs the actual
  `PieceMesh.collision_for` function for chest/fire and reads StationSite's source
  dimensions independently of the generated report. It checks materials/textures,
  imported bounds, pivots, invisible primitive bodies and the chest hinge.
- Player capsule sweeps (radius 0.42 m, height 1.92 m) and rays cover all four
  rotations: existing bodies block walking, alongside routes stay clear, the fire
  is clear above 0.30 m, and station candidates remove above-surface obstruction.
- Shared-tool regressions passed: **34 building checks**, **90 nature checks**,
  **5 MCP protocol tests** and the companion plugin manifest validator.
- Both Blender views and the actual Godot beauty/collision views were inspected.
  An initial pair of overlapping metal faces was corrected before final export.

The sandbox prevented Godot from writing its global editor settings/shader cache
and reading the Windows certificate store; these did not prevent local imports,
physics checks or rendered screenshot export. The checker returned zero.

Reproduce using the commands in the
[`Blender bridge README`](../../tools/wroughtwild-blender/README.md#furnishings).
All generated models/renders and the portable Blender distribution remain under
ignored `build/`; only authoring scripts/configuration and documentation are source.

## Limits and remaining work

This is an authored asset study, not normal-game integration or production art.
The chest hinge has no animation clip or runtime animation wiring. Hand tools are
non-interactive details; embers are static, with fuel/lighting/burn-out integration
still required. Material atlasing, LODs and a furnished-room performance review
remain ahead. Tests do not exercise inventory panels, storage/fuel economics,
actual character stepping/jumping or saves. No native simulation checks were
needed because no game or simulation source changed in this pass.

Beds, chairs, standalone tables, shelving and lamps would extend the current
furnishing catalogue; none is silently added as a new functional game item here.
The four fitted station bodies remain explicit proposals for the next review.
