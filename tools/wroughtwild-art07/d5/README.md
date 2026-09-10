# ART-07D5 — mineral, glass and fuel finishes

Eight reusable ordinary material sources and an isolated material inspection.
This handoff does not adopt assets into the game or replace D1/D2 lattice modules.
The selected ART-07 building and station boards guide colour and source identity.

`surfaces.py` authors deterministic periodic fields, without copied image pixels,
photographic lighting, emission or a new organic mesh. The local TRELLIS v0.6.0
depot and all ten pinned model hashes were verified, but generation is unnecessary
for these surfaces and directly dimensioned samples. No tool or model is installed.
The task-local inspection, packaging, GPU and native-check helpers derive from D4
at `f00d4b76274ef2a73c3b6f4a275d2bd3ca0f958d`; the originals are read-only.

## Material contract

`materials.json` documents each art control and its purpose. Names are
`d5_<id>_<face|edge>_<albedo|normal|orm>.png`. Each family has one 1024² face
and one 512² edge set. Albedo is sRGB; tangent-space OpenGL +Y normals and
ORM are linear. ORM R=255, G=roughness, B=0: no baked illumination or metal.
All maps are RGB; pane opacity 0.72 is a material control, never baked into RGB.
The pane alpha blends in both engines; the frame stays opaque. No refraction,
screen-space distortion, bloom, emitted light or animated success cue is used.
Subtle tangent normals perturb the glass reflection, not geometry behind it.

| Family | Face repeat U × V, metres | Edge repeat | Identity |
| --- | --- | --- | --- |
| Stone | 2 × 1 | 1 × 1 | Regular dressed beds and small chips |
| Fieldstone | 2 × 1 | 1 × 1 | Dry irregular contacts and lichen |
| Slate | 2 × 1 | 1 × 0.25 | Thin cleaved faces and laminated edges |
| Shellstone | 2 × 2 | 1 × 1 | 37 uneven whole/partial shell impressions |
| Rustclay brick | 1 × 1 | 1 × 1 | Staggered firing marks and pale joints |
| Vitrified basalt | 1 × 1 | 1 × 1 | Glossy fused islands over matte rock |
| Cinderglass | 1 × 1 | 0.5 × 0.5 | Smoky pane; opaque mineral frame |
| Charcoal | 0.25 × 0.25 | 0.25 × 0.25 | Porous angular fuel and ash |

UVs are local metres divided by repeat metres, U horizontal and V upward on
wall faces. Top/end faces use the edge material with right-handed tangents.
Fine pieces crop the same density. Continuous runs must share their metric UV
origin; separate pieces can shift phase by whole texels. Fossils vary within a
finite 2 m tile, not infinitely: large walls still repeat. Do not retint these
authored colours with the old biome tint. Normal relief is microstructure only;
there are no magical scars in these ordinary materials. Physical bevels and
overlapping slate edges remain visible independently of normal maps.

Source identity follows current recipes: split stone → dressed stone; raw slate
and raw shellstone → dressed equivalents; raw clay → fired brick; furnace slag
→ vitrified basalt; shards → cinderglass; charred wood → charcoal fuel.
No recipe, item, ownership, harvesting stage or finite source mesh changes.

## Geometry and interaction limits

40 closed inspection meshes use metres and the established Blender `(x,y,z)` →
Godot `(x,z,-y)` export. Origins are sample centres, not new placement pivots.
Six families have surface/cut/repeat coupons; slate uses seven overlapping strips.
Charcoal has nine angular fuel chunks and no wall coupon. The fixed-window sample
uses the current 1 × 1 × 0.16 m envelope, 0.075 m frame, 0.026 m crossed muntins
and 0.0384 m pane. Frame and pane share the product, with no extra material cost.
Normal depth is deliberately modest; it does not substitute for structural scars.

The static Godot review checks a ray against the whole fixed-window collision
envelope. Its opaque striped target behind the pane exposes alpha/reflection.
It has no player, inventory, work simulation, placement or native save. Current
native regression checks run separately; they must not be represented as paid
playthroughs of this source study. Failed placement and exactly-one-object kit
transactions remain the unchanged game's responsibility at eventual adoption.
Fieldstone retains `rough`, charcoal `fuel`, and glass `glazing` restrictions.

The same geometry is used near/middle/far, with mipmapped textures; no proposed
LOD budget or new construction shape is introduced. A camera sweep is inspection
motion only. Glass uses standard alpha blending without sorted overlapping panes
in this board; complex multi-window buildings and lower-spec hardware need later
review. These material sources do not claim world-performance acceptance.

## Reproduction

Run from the isolated worktree. Existing tools:

```powershell
$d5Python = 'C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$d5Blender = 'C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe'
$d5Godot = 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
& $d5Python tools/wroughtwild-art07/d5/surfaces.py build/art07/d5/NEW/textures
& $d5Python tools/wroughtwild-art07/d5/verify.py build/art07/d5/NEW/textures
./tools/wroughtwild-art07/d5/gpu-slot.ps1 -Program $d5Blender -JobArguments @('--background','--threads','8','--python-exit-code','1','--python','tools/wroughtwild-art07/d5/blender_materials.py','--','build/art07/d5/NEW/textures','build/art07/d5/NEW/blender') -Log build/art07/d5/NEW/blender.log
& $d5Python tools/wroughtwild-art07/d5/prepare_review.py build/art07/d5/NEW/textures build/art07/d5/NEW/blender build/art07/d5/NEW/review
./tools/wroughtwild-art07/d5/gpu-slot.ps1 -Program $d5Godot -JobArguments @('--headless','--path','build/art07/d5/NEW/review','--editor','--import') -Log build/art07/d5/NEW/import.log
& $d5Python tools/wroughtwild-art07/d5/configure_imports.py build/art07/d5/NEW/review
```

Reimport after configuring mipmaps, then invoke Godot with `--rendering-method
forward_plus` or `gl_compatibility`, followed by `-- --capture`, `-- --motion`,
or `-- --benchmark`. Benchmarks are separate fixed-view jobs without image capture.
1–8 inspect a family, 0 shows the board, Escape exits. The GPU wrapper refuses
other art/game jobs, takes `Local\Wroughtwild-Art07-GPU`, and restores isolated
APPDATA/Blender settings. Never interrupt another worker or owner playtest.

`blender_materials.py -- --reopen MASTER.blend FRESH_DIR` reopens packed maps and
imports the adjacent exported GLB in a new scene, checking actual triangulation.
`native-checks.ps1 -FreshOutput build/art07/d5/NEW/native` runs current unmodified
world-material and core tests with the existing compiler and strict warnings.
`package.py VERSION FRESH_HANDOFF REVIEW` packages source/recipes and clean review.
Copy the handoff before importing it; verify its manifest before and after copy.
Keep fresh review paths short on Windows. The receipt records executed versions,
actual hashes, checks, costs, limitations and publication status.
