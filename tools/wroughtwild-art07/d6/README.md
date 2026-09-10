# ART-07D6 — worked metal material sources

Four original ordinary metal finishes and dimensioned joint samples. This is a
material handoff for geometry owners, not ordinary-world adoption. Only iron,
bronze, steel and silver are owned here. Base game/native revision:
`f00d4b76274ef2a73c3b6f4a275d2bd3ca0f958d`.

## Material contract

Each family shares **one** 1024² RGB albedo, normal and ORM set across every
member and fastener. `d6_<family>_<albedo|normal|orm>.png`: albedo is sRGB;
normal/ORM are linear. Tangent normals use OpenGL +Y. ORM is R=1 (no baked AO),
G=roughness, B=1 (metal). Body metallic factor is one; the seam factor reduces
metallic response for oxide/patina/tarnish. No alpha, glow, pulse or light source.
Godot explicitly binds the blue metallic and green roughness channels. Blender
uses Non-Color for both data maps. Mipmaps are enabled before the second import.

Two materials per family (`body`, `seam`) reuse those same three images. Seam
colour is multiplied by the documented tint; it is applied to physically inset
joint backing, not baked lighting. All final engine surfaces use shared external
images; embedded GLB preview materials are replaced on the imported mesh itself.
The GLB's embedded preview is not the material binding authority. The packed
Blender source and the explicit Godot binding are the complete library.

UVs are local metres divided by **0.5 m**, with a right-handed planar tangent
frame on each face. Cube default UVs are removed. Fine objects must crop the same
density, not rescale a complete tile onto each object. Align neighbouring plates
to their own run; rotate dressing with the manufactured part. Integer-period
fields have continuous wrap. No copied concept pixels or photographic light is
present. Periodic repetition will remain visible on extensive uninterrupted walls.

`materials.json` explains all family controls: reflectance, roughness, shallow
hammer depth, protected seam response, rivet radius and arris width. Iron has
broad dark hammer scale and domed pins; bronze has soft cast edges and a broader
collar; steel has narrow straight splices and hex heads; silver has small peened
pins and twin chased bands. These are visual controls, never game tuning.
No magical injury is authored on ordinary construction. Submillimetre hammer
normal detail is explicitly **not** a deep structural scar.

## Geometry and limits

Ten inspectable objects: four girder samples, four joint coupons, two arch
samples. All parts remain inside their stated envelope, with seated fasteners
and physical backed gaps. Blender XYZ exports once to Godot XZ−Y, in metres.
Object origin is the envelope centre; review translations are staging only.

- Girder envelope: native 2 × .4 × .3 m (Godot XYZ), I-profile **proxy** for
  material inspection. Native girder collision remains its existing box.
- Bronze/silver arch: native 1 × 1 × .25 m envelope, smooth-opening **proxy**.
  Native PieceMesh uses stepped strips; this sample does not replace that mesh
  or authorize a new opening/collision. Iron/steel arches are intentionally absent.
- Joint coupon: .5 × .5 m plate; measured depth .087 m iron, .084 m bronze/silver,
  .0795 m steel. It is not a new legal piece or craftable component.
- Girder flanges .054 m; web .075 m thick; paired .031 m protected backing and
  .018 m plates. Splice widths .22/.28/.12/.18 m differentiate manufacturing.
  Body bevels .004/.006/.0015/.003 m retain the envelope while rounding arrises.
  Rivet radius .029/.025/.018/.014 m; dome depth .012 m iron / .009 m others.
  Silver .009 m chased bands sit on its splice. Arch radius .46 m, 40 strips;
  .216 m body and inset .016 m lug plates stay within .25 m depth.

There is one 13,608-triangle source/review mesh set at all distances, ten meshes
with two material surfaces each. There is no arbitrary decimation or promised
runtime LOD budget. Mipmaps reduce texture detail at distance. These joint-heavy
proxies are examples for source reuse; full-scene adoption needs its own budget.
Twelve shared maps cost 36 MiB raw RGB / 48 MiB RGBA8 base / 64 MiB with full
RGBA8 mip chains (driver counters are recorded separately). GLB and external
images duplicate **disk** data for portability, not intentional GPU sets.

Native `metal`, `malleable`, `joinery`, unlocks and costs remain data-owned.
Silver cannot become a door; iron and steel cannot become arches. Decorative
fasteners add no component recipe or cost. There are no stateful objects in the
material gallery. Existing failed/successful kit placement is checked separately
in a frozen current game using its unmodified regression scenes and isolated saves.

## Reproduction and review

Use existing depot tools from PROCESS.md. No imagegen conditioning input or
organic TRELLIS job is needed for directly modelled worked metal. `provenance.py`
verifies the pinned local model bundle and immutable source files in all seven
retained approved packages, records tool/source hashes and consumes no organic
geometry. Do not reinstall or run an older slice's recipe over its source.

From this worktree (choose fresh output names):

```powershell
$d6Python='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$d6Blender='C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe'
$d6Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
& $d6Python -B tools/wroughtwild-art07/d6/surfaces.py build/art07/d6/NEW/textures
& $d6Python -B tools/wroughtwild-art07/d6/verify.py build/art07/d6/NEW/textures build/art07/d6/NEW/texture-checks.json
& $d6Python -B tools/wroughtwild-art07/d6/provenance.py build/art07/d6/NEW/provenance.json
./tools/wroughtwild-art07/d6/gpu-slot.ps1 -Program $d6Blender -JobArguments @('--background','--threads','8','--python-exit-code','1','--python','tools/wroughtwild-art07/d6/blender_materials.py','--','build/art07/d6/NEW/textures','build/art07/d6/NEW/blender') -Log build/art07/d6/NEW/blender.log
& $d6Python -B tools/wroughtwild-art07/d6/prepare_review.py build/art07/d6/NEW/textures build/art07/d6/NEW/blender build/art07/d6/REVIEW
./tools/wroughtwild-art07/d6/gpu-slot.ps1 -Program $d6Godot -JobArguments @('--headless','--path','build/art07/d6/REVIEW','--editor','--import') -Log build/art07/d6/NEW/import.log
& $d6Python -B tools/wroughtwild-art07/d6/configure_imports.py build/art07/d6/REVIEW
./tools/wroughtwild-art07/d6/gpu-slot.ps1 -Program $d6Godot -JobArguments @('--headless','--path','build/art07/d6/REVIEW','--editor','--import') -Log build/art07/d6/NEW/mips.log
./tools/wroughtwild-art07/d6/gpu-slot.ps1 -Program $d6Godot -JobArguments @('--path','build/art07/d6/REVIEW','--rendering-method','forward_plus','--','--capture') -Log build/art07/d6/NEW/forward.log
```

Repeat with `gl_compatibility`. `--motion` produces 96 actual camera-sweep
frames, no asset animation. `--benchmark` runs a separate settled fixed camera,
132 warmup frames and 600 measured frames, VSync off, 1600 × 900, 4× MSAA.
Keyboard 1–4 selects a family, 0 overview, Escape exits. Material state never
advances, so there is no pause-sensitive material clock or native success pulse.

`gpu-slot.ps1` derives from D4's scoped launcher. It acquires
`Local\Wroughtwild-Art07-GPU` and refuses existing Blender/Godot/TRELLIS renders.
Verified `--headless` Godot checks may coexist with captures; benchmarks refuse
those too. Retry later if busy;
never kill another session. CPU Blender renders also take the slot. APPDATA and
Blender resources are isolated and restored. Do not benchmark alongside compiling.

`native_checks.py` derives D4's native command list and compiles current untouched
world/core tests with `-Wall -Wextra -Werror`. `build-native.ps1` derives D1's
explicit-depot build, freezes the revision above and reuses only approved
godot-cpp headers/library. `freeze_game.py OUTPUT NATIVE` archives the same game
and data; only its custom user directory is set before tests. Run
`placement_transactions.tscn`, then a separate process with
`-- --placement-restore-only`, and `home_station_placement.tscn`.

Package with `package.py VERSION TEXTURES REVIEW FRESH_HANDOFF`. Copy the package
to a fresh directory, verify every manifest hash **before** engine import, reopen
`source/d6_materials.blend` via `blender_materials.py -- --reopen MASTER OUT`,
and import `review/project.godot` afresh in both renderers. Reopen checks all
packed images, metric UVs, bounds, actual triangulation and a fresh GLB import.
Six-direction material/clay views show the actual geometry.

Only recipes, concise reports and curated evidence belong in Git. Masters,
runtime PNGs/GLBs, caches, native binaries and isolated saves stay local. The
[D6 receipt](../../../docs/prototype/art07-production/receipts/d6.md) gives exact
selected paths, hashes, measured costs and publication status. Owner visual
acceptance and ordinary-world adoption remain separate.
