# ART-07C5 ore-bearing rock family

This is a source handoff and isolated copied-game review for the five existing ore
IDs. It does not install assets in the normal game. Owner visual acceptance is
pending. See the scoped C5 receipt for the sealed package hash and measured costs.

## Selected source and authority

The selected source is `kit-v08/c5-master.blend`: v07 geometry with the final
shared material detail and packed ORM. Its 90 GLBs are byte-identical to v07.
Collections distinguish SOURCE, FINISHED, RUNTIME and REVIEW. Original ART-02
albedo/ORM and B3 geometry remain packed; the selected runtime uses two newly
authored shared periodic stone maps, not stretched copies of the original atlas.
No new generation, model download, package, asset service or imagegen was needed.

B3's published `handoff-v02` is the dependency. `prerequisites.py` checks every
one of its 1,541 manifest entries, source hashes, all ten pinned model files and
the exact native/game relationship. Read `prerequisites.json` for the original
TRELLIS command array, input/cutout hashes and embedded GLB metadata. The source
was generated with local Windows TRELLIS v0.6.0, CUDA required, resolution 1024,
seed 42, retained BiRefNet cutout, PNG and eight threads. Its embedded build
commit is `16f3109e82f3922033bfa62b83c42899678b7b6f`, not inferred from a release tag.

The copied game/data baseline is `4b5d89b376765fbf4d46049aa099e0bb154a82da`.
B3's native DLL hash is
`6d8094fc95c0854f9100b161806a11d9fa3a67bb4f870080976bcd8d2e8f2279`.
There is no game/sim/data diff from its frozen native base
`f00d4b76274ef2a73c3b6f4a275d2bd3ca0f958d` to this baseline. Native authority is
reused, not rebuilt or replaced in the owner's checkout.

## Geometry, state and limits

The source is B3's repaired organic host, fitted to Blender 2.48 × 0.78 × 0.50 m.
Blender `(x,y,z)` maps once to Godot `(x,z,-y)`. The origin is horizontal centre
at the bottom; there are no attachment sockets. The initial base trim is 0.012 m.
Post-reduction coordinates are bounded to ±1.25 m X, ±0.40 m Y and 0–0.52 m Z.
The measured native fallback body is 2.6 × 0.6 × 0.9 m in Godot, centred 0.3 m
above its anchor, with existing seeded 0/90-degree yaw preserved. Every exported
stock/crack candidate fits that body; no collision is added to any model.

The **ordinary faceted-terrain ore is a zero-thickness picking ribbon**, about
3 m long and 0.48 m wide, lifted 0.018 m onto actual support (24 steps, 144
triangles). Its gaps track excavated support. The copied-game adapter returns to
the original visual for that path and tests exact geometry/collision restoration.
These raised source candidates cannot be adopted there without a separate
reviewed contact/body solution. A fallback fixture does not clear ordinary-world
adoption, saved-world appearance, habitat density or first-hour progression.

Stock variants are indexed by the current native remaining units, every two units:

| Ore | Full units | Heat to work | Era | Mineral structure |
| --- | ---: | ---: | ---: | --- |
| iron_vein | 8 | 0 | 1 | Dull ochre nodules and streaks |
| copper_vein | 8 | 2 | 2 | Green-brown folded bands in warm host |
| tin_vein | 6 | 2 | 2 | Irregular pale pockets in dark host |
| ember_iron_vein | 6 | 2 | 3 | Recessed ember fracture in heat-marked host |
| silver_vein | 6 | 2 | 3 | Narrow branching metallic seam |

All retain two units per harvest, one press, no required tool, existing identity
and material family. Iron ignores heat; the other four reject cold/level-one
work, accept native level-two heat, and become permanently workable after native
quench/heavy impact cracks them. Heat is transient; cracks/stock/anchors are
saved. The fixture invokes actual ResourceNode work, player pickup/inventory and
SaveManager, without granting ore. It directly sets test heat through native
`soak`; it does not establish a paid furnace/first-hour route. Its five resource
sites and review floor are authored fixtures. Building ownership remains covered
by the unmodified current placement/material/save suites, not these ore fixtures.

Matched cut faces use plane cuts at `-1.22 + 2.44 * remaining/full` metres, hole
fill and independent planar cap UVs. Mineral fields continue through those faces.
All LODs are independently audited after fresh GLB import. Small inherited edge
defects remain in all 90 exports (up to 21 boundary edges after a 1 µm weld);
this is not a watertight-solid certification.
No voxel-repaired candidate is selected: the v06 reduction broke the visible
surface despite passing counts. v01's regular markings and v02–v05's budget,
degenerate/bounds failures are retained as diagnostic outputs, not delivered art.

## Materials and tuning

`kit.json` documents each editable control. Dimensions preserve the fallback
body margin; seed 42 stabilises only source detail. Near/mid/far caps of
6,000/2,600/900 triangles preserve gross form and bound each displayed state;
8/20 m LOD distances apply only in the source review. The native fixture selects
LOD0, not a new world streaming policy. Thirty stock/crack states × three LODs
produce 90 exports. Iron has no invented crack state; all other ores have both.

The 0.055 m incision and 0.07 m half-width form broad damage, with an independently
measured inward displacement above 0.038 m in every applicable source. Ember's
channel is structural even cold; other ores receive it only in cracked variants.
The centreline follows the sampled top surface with `0.10*sin(5*x)+0.04` m lateral
variation; normal-directed displacement keeps the route attached. Mineral relief
is 0.007 m for copper, 0.012 m otherwise. These are authoring choices, not damage
or mining tuning.

Colour/host tint/roughness/metallicity values in `kit.json` are per-ore linear
material controls. Named C5 vertex colour channels carry mineral mask (R), scar
depth mask (G) and travel coordinate (B). Original and cap UVs remain present.
The selected albedo is sRGB; ORM is linear (non-colour). Shared 1024-square maps
use mipmaps and no duplicated embedded runtime textures. `prepare.py` removes
only image bufferViews; every retained geometry/accessor byte is asserted equal.
The shader explicitly implements the material; Blender and Godot lighting are
not claimed pixel-equivalent. Engine triplanar sampling removes atlas stretching.

Authoring uses six periodic noise octaves, ten seeded sine components per octave,
for a neutral tiling surface. The shader's 1.7 repeats/m sets grain scale; its
0.012 m derivative bump controls fine roughness, not the required geometric scar.
Triplanar weight exponent 4 softens face transitions. Mineral blend 0.88 retains
some host colour; dark rim factor 0.78 distinguishes the broken edge. Shader
roughness clamps the host to 0.7–1.0. Two-sided opaque rendering covers remaining
small edge defects; there is no transparent overdraw, bloom or per-scar light.

Heat movement uses the explicit 3.5 s clock, travel range 0.30–1.00 and scar
emission amplitude 0.65. The native heat boolean authorises it; inherited native
tint/emission still communicates existing state. The scene tree pause stops the
native process; the study's Space handler pauses its explicit shader clock.
Ordinary cold specimens do not emit. H explicitly poses only the full ember
specimen in the static display. This is labelled study heat, not successful work.

## Reproduce in this worktree

Use existing tools; do not install or fetch anything. Run from the C5 worktree.
Every destination below must be fresh. Argument arrays, exact executed paths,
PIDs, exit codes and durations are recorded alongside each job's log.

```powershell
$artRoot = 'C:/Users/Matty/Dev/project-wroughtwild/build/art07/c5/worktree'
$artPy = 'C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$artBlender = 'C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe'
$artRecipe = "$artRoot/tools/wroughtwild-art07/c5"
$artOut = "$artRoot/build/art07/c5/rebuild-01"
& $artPy "$artRecipe/prerequisites.py" $artOut
& "$artRecipe/run-job.ps1" -Program $artBlender -Arguments @('--background','--threads','8','--python-exit-code','1','--python',"$artRecipe/build.py",'--',"$artOut/kit-v07") -Log "$artOut/build.log"
& "$artRecipe/run-job.ps1" -Program $artBlender -Arguments @('--background','--threads','8','--python-exit-code','1','--python',"$artRecipe/finish.py",'--',"$artOut/kit-v07","$artOut/kit-v08") -Log "$artOut/finish.log"
& "$artRecipe/run-job.ps1" -Program $artBlender -Arguments @('--background','--threads','8','--python-exit-code','1','--python',"$artRecipe/audit.py",'--',"$artOut/kit-v08","$artOut/audit-v08.json") -Log "$artOut/audit-v08.log"
& "$artRecipe/run-job.ps1" -Program $artBlender -Arguments @('--background','--threads','8','--python-exit-code','1','--python',"$artRecipe/render.py",'--',"$artOut/kit-v08/c5-master.blend","$artOut/blender-v08") -Log "$artOut/render-v08.log"
& $artPy "$artRecipe/prepare.py" "$artOut/kit-v08" "$artOut/review-v03"
& "$artRecipe/run-stage.ps1" -Project "$artOut/review-v03/game" -Logs "$artOut/import" -Stage Import
& "$artRecipe/run-current-checks.ps1" -Project "$artOut/baseline/game" -Logs "$artOut/current-checks"
& "$artRecipe/run-stage.ps1" -Project "$artOut/review-v03/game" -Logs "$artOut/native-v04" -Stage Native
& "$artRecipe/run-stage.ps1" -Project "$artOut/review-v03/game" -Logs "$artOut/capture-v03" -Stage Capture
& "$artRecipe/run-stage.ps1" -Project "$artOut/review-v03/game" -Logs "$artOut/benchmark-v01" -Stage Benchmark
```

Import the baseline before running its checks. `probe.gd` is the read-only native
envelope inspection; copy it to `baseline/game/c5/` and run it with `--script`.
`inspect_source.py` and `inspect_runtime.py` provide additional actual geometry
inspection. The original diagnostic scripts are task-local B3 derivatives;
their original helpers and handoffs were never edited.

GPU stages acquire `Local\Wroughtwild-Art07-GPU`, inspect Win32 process command
lines read-only and refuse active rendering/generation. Threadless exited entries
and explicitly headless Godot checks are distinguished from GPU jobs. Windows
may require read permission for this inspection. Never terminate other sessions
to acquire the slot. Benchmark separately from captures/generation; the RTX
result is not a habitat or lower-spec performance gate. Existing desktop GPU
applications remain untouched and limit the measurements' generality.

## Verify and open the sealed package

The receipt gives the canonical package and manifest SHA-256. Never import that
canonical directory directly; import a verified fresh copy. This example uses the
actual selected package and a new destination:

```powershell
$artRoot = 'C:/Users/Matty/Dev/project-wroughtwild/build/art07/c5/worktree'
& "$artRoot/tools/wroughtwild-art07/c5/launch-review.ps1" -Package "$artRoot/build/art07/c5/v01/handoff-v01" -FreshTarget "$artRoot/build/art07/c5/owner-review-01" -Renderer forward_plus -Visible
```

Omit `-Visible` for a hidden process; add `-Native` for the automated native work
fixture (it exits after the sequence). Compatibility uses `-Renderer
gl_compatibility`. The launcher verifies every file, copies to an absent target,
imports there, isolates APPDATA/LOCALAPPDATA beneath `launch/`, takes the GPU
mutex and waits for only its own process. It restores the environment afterwards.
The same script and verifier are also inside the package under
`tools/wroughtwild-art07/c5/`. The local tool executables remain prerequisites.

Static study controls: click for mouse look, WASD/QE fly, Escape releases the
mouse, R overview, L day/shade/dusk, C clay, M emission on/off, H explicitly posed
ember heat, Space pause/resume, 0 automatic LOD and 1/2/3 force near/mid/far.
There are 15 visible specimens (full, worked, last/cracked rows). The study has no
collision objects and grants no inventory. Native state validation is separate.

Only recipes, receipts, source provenance and curated rendered evidence go to
Git. Packed masters, runtime exports, copied game/DLL, logs, caches and fixture
saves stay in ignored local build directories. A clean clone therefore needs
the verified handoff transfer or the existing local source/tool depot to rebuild.
