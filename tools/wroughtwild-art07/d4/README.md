# ART-07D4 — timber, reed and cork sources

Seven ordinary, opaque material families, based on the selected
[building sheet](../../../docs/art/concepts/environment/2026-09-09-frontier/03-building-family.png).
These are reusable material sources and an isolated swatch inspection, not
ordinary-world adoption or replacement D1/D2 construction modules.

`materials.json` is the small source recipe and its control documentation.
`surfaces.py` authors original deterministic periodic fields without photographs,
lighting, emission or copied concept pixels. It does not need an organic mesh,
imagegen conditioning image or TRELLIS job. The existing generator/model depot
is verified in the receipt; its organic pipeline remains appropriate to other
slices. No package, model or external asset is installed for D4.

## Stable material and texture contract

Names are `d4_<family>_<face|edge>_<albedo|normal|orm>.png`.
Families: `wood`, `pine`, `bog_oak`, `ash_wood`, `resinheart`, `woven_reed`,
`corkbark`. Each has a 1024² face and 512² edge set. Albedo is **sRGB**;
normal and ORM are **linear**. Normal is tangent-space OpenGL **+Y**, strength 1.
ORM has R=255 (no baked AO), G=roughness, B=0 (nonmetal). Alpha is absent;
reed gaps and cork pores are opaque material colours. All families have emission
disabled; resin pockets change roughness only. Do not multiply these authored
colours by the old biome tint a second time.

| Family | Face repeat U × V | End/edge repeat | Direction |
| --- | --- | --- | --- |
| All five timbers | 0.5 × 2 m | 0.5 × 0.5 m | V follows member length; cut ends use edge |
| Woven reed | 0.4 × 0.4 m | 0.4 × 0.4 m | U runs along horizontal weft; V along vertical stakes |
| Corkbark | 0.3 × 0.3 m | 0.3 × 0.3 m | Face pores undirected; edge V crosses strata |

Use local **metres divided by repeat metres** for UVs. Apply object scale before
export; rotate the UV grain axis with the member. For beams V follows length,
for posts and vertical boards V follows height. Faces perpendicular to that
axis receive the edge material. Do not triplanar-blend end grain onto long faces.
Keep tangent handedness consistent on opposite faces; the authoring recipe uses
a right-handed UV frame. Fine pieces crop the same density: a half beam has half
the UV span, rather than stretching a whole texture into a smaller member.

For a continuous run, anchor UV phase in that run's local metric coordinates.
For separate boards, vary phase by whole texels and mirror only with correct
tangents. Avoid identical knots on each neighbouring board. The repeat is finite;
large uninterrupted walls will show repetition. Model pegs, straight joins,
frames, worn corners and silhouette damage in the owning geometry slice. These
maps deliberately contain no plank-joint seam, peg or frame that would impose
an incorrect dimension or duplicate a physical part.

Reed/cork retain `only_for_trait: covering`; they do not become blocks, beams,
doors or storage. Their small rectangular cut/tiling coupons in the review are
**inspection samples, not new legal fine covering pieces**. The native light
panel envelope is 1 × 1 × 0.16 m; its eventual integral frame and opaque coverage
belong to the geometry owner. Materials confer no inventory, protection or stock.

## Rebuild and inspect

Run from this worktree, using the **existing** depot tools:

```powershell
$d4Python = 'C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$d4Blender = 'C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe'
$d4Godot = 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
& $d4Python tools/wroughtwild-art07/d4/surfaces.py build/art07/d4/NEW/textures
& $d4Python tools/wroughtwild-art07/d4/verify.py build/art07/d4/NEW/textures
./tools/wroughtwild-art07/d4/gpu-slot.ps1 -Program $d4Blender -JobArguments @('--background','--threads','8','--python-exit-code','1','--python','tools/wroughtwild-art07/d4/blender_materials.py','--','build/art07/d4/NEW/textures','build/art07/d4/NEW/blender') -Log build/art07/d4/NEW/blender.log
./tools/wroughtwild-art07/d4/gpu-slot.ps1 -Program $d4Blender -JobArguments @('--background','--threads','8','--python-exit-code','1','--python','tools/wroughtwild-art07/d4/blender_materials.py','--','--reopen','build/art07/d4/NEW/blender/d4_materials.blend','build/art07/d4/NEW/reopened') -Log build/art07/d4/NEW/reopen.log
& $d4Python tools/wroughtwild-art07/d4/prepare_review.py build/art07/d4/NEW/textures build/art07/d4/NEW/blender build/art07/d4/NEW/review
./tools/wroughtwild-art07/d4/gpu-slot.ps1 -Program $d4Godot -JobArguments @('--headless','--path','build/art07/d4/NEW/review','--editor','--import') -Log build/art07/d4/NEW/import.log
& $d4Python tools/wroughtwild-art07/d4/configure_imports.py build/art07/d4/NEW/review
./tools/wroughtwild-art07/d4/gpu-slot.ps1 -Program $d4Godot -JobArguments @('--headless','--path','build/art07/d4/NEW/review','--editor','--import') -Log build/art07/d4/NEW/mipmap-import.log
./tools/wroughtwild-art07/d4/gpu-slot.ps1 -Program $d4Godot -JobArguments @('--path','build/art07/d4/NEW/review','--rendering-method','forward_plus','--','--capture') -Log build/art07/d4/NEW/forward.log
```

Repeat the final call with `gl_compatibility`; use `--motion` for 96 actual
rendered camera-sweep frames and `--benchmark` in **separate** fixed-view runs.
The captured motion is camera inspection; the construction materials do not
animate. Keys 1–7 inspect a family, 0 shows the whole board, Escape exits.
The GPU wrapper takes the shared ART-07 mutex, refuses existing GPU art/game
jobs, and restores isolated APPDATA/Blender paths. Confirmed `--headless` Godot
checks may coexist with captures, but are refused for benchmarks. Never kill
another worker to run it. The short `build/art07/d4/u` APPDATA path and `D4`
custom user directory avoid long Windows shader-cache paths. Use a short fresh
review path (the checked copy is `build/art07/d4/r03`) when nesting would exceed
Windows path limits. External runtime-loaded PNGs require the explicit mipmap
configuration and second import above: Godot's default 2D import is insufficient.

`native-checks.ps1 -FreshOutput build/art07/d4/NEW/native` compiles and runs the
current unmodified world-material and core simulation tests, with the existing
compiler and strict flags. Run these separately from performance benchmarks.
`verify.py` checks source hashes, map structure, tangent normals, opaque/zero
metal/AO contracts, tiled boundary statistics, physical density and current
covering gates. Existing design `catalogue.py` and `session_plan.py` remain
read-only checks. The receipt records the actually executed commands and limits.

Packed source has 26 simple closed inspection envelopes, 312 actual triangles,
and 14 reusable material slots. Blender `(x,y,z)` exports to Godot `(x,z,-y)`;
all dimensions are metres, each proxy origin is its centre. This is an inspection
layout, not a new lattice pivot contract. Geometry has no LOD variants: the same
12-triangle boxes support near/middle/far mapping review; textures use mipmaps.

No game, tuning, catalogue, normal save, shared helper or previous package is
modified. Final handoff and selected evidence are identified in
[the D4 receipt](../../../docs/prototype/art07-production/receipts/d4.md).
