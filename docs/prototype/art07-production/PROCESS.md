# Wroughtwild generation and Blender production process

This is the verified local route already used for ART-01–06. Follow it when
enacting an assigned ART-07 slice. The broad boards establish appearance;
individual production inputs and actual meshes establish the result.

## 1. Resolve existing tools and approved sources

Verified present on this machine when preparing this plan, 9 September 2026:

| Tool/input | Canonical path or repository-relative location |
| --- | --- |
| Repository/tool depot | `C:/Users/Matty/Dev/project-wroughtwild` |
| Local generator | `build/trellis-local/runtime/trellis-cli.exe` |
| Existing models | `build/trellis-local/models/` |
| Pinned model/runtime manifest | `tools/wroughtwild-trellis/install-manifest.json` |
| Blender | `build/blender-tool/blender-4.5.9-windows-x64/blender.exe` |
| Python with NumPy/Pillow | `C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` |
| Godot | `C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe` |
| Grove | `build/grove-art02/emberroot-handoff/` |
| Boar | `build/boar-art01/boar-handoff/` |
| Deep lifelines | `build/roster-art06c/lifeline-handoff/` |
| Red / White / Blue / Green | `build/workshop-art04/red-handoff/`, `build/workshop-white/white-handoff/`, `build/workshop-blue/blue-handoff/`, `build/workshop-green/green-handoff/` |

Verify paths/hashes before each job. A worktree does not automatically contain
the ignored tools or handoffs. Read them from this canonical depot and write new
outputs only in the worker's own ignored build tree. Do not duplicate the model
bundle into each checkout or silently consume a similarly named old candidate.
Another machine needs a specifically transferred/verified bundle or the documented
reconstruction, not a false claim that a clean clone contains these files.

The installed generator is **pwilkin/trellis.cpp v0.6.0**, the Windows CUDA port,
using the pinned `ilintar/trellis2-gguf` model revision. It is not a Microsoft
Python/WSL install. Record actual runtime metadata from each GLB as well as the
manifest; the earlier wolf exposed a release/build-commit difference. Read
[local setup](../../../tools/wroughtwild-trellis/README.md) for evidence, not as
an instruction to reinstall an already working tool.

## 2. Make a useful individual concept input

Inspect the selected board and existing source first. Reuse a good approved mesh
before generating another. For an organic host needing a new source, use the
built-in image generation/editing tool and the available imagegen skill. Keep
one subject, full silhouette, three-quarter view, neutral background and neutral
lighting. Separate topology-critical parts clearly. Produce side/back/top detail
views for **inspection consistency**, not an invented multi-view TRELLIS command.
Do not feed a habitat collage, cottage scene or seven-device board into one
generation job. Preserve the exact input and submitted prompt, version and hash.

Copy-ready organic input template; fill the bracketed subject fields from the
assigned catalogue entry, not new game rules:

```text
Wroughtwild production asset concept: [ONE HOST/COMPONENT]. Follow the selected
ART-07 [BOARD/PANEL] and [APPROVED RELATED SOURCE]. Full isolated object, neutral
grey background, entire silhouette visible with breathing room, clear grounded
base, no scene props, lettering, watermark or cropped branches. Earthy material
realism and recognisable natural structure. [SPECIFIC BRANCH/ROOT/ROCK/MEMBRANE
SILHOUETTE]. On the altered variant, deep open wounds follow the host structure:
dark broken margins and energy inside broad recessed channels, as if sustaining
the damaged host. Keep ordinary surfaces readable and largely unlit. Strong
large forms before fine detail. Show the supports/attachments needed to make
this physical object plausible. No new mechanical feature or gameplay ability.
```

Use separate ordinary/altered inputs only where the brief calls for variants.
Foliage needs a deliberate branch/canopy workflow: generate useful trunk/hero
structure, then author attached branch/leaf clusters in Blender. An indistinct
AI canopy blob is not an acceptable finished forest. Tilable ground/wood/stone
surfaces need a separate flat, neutral albedo brief, then tiled seam inspection;
do not bake photographed illumination or glowing cracks into ordinary albedo.

For frames, roofs, walls, hinges, sockets and moving mechanisms use **direct
Blender modelling at actual dimensions**. An organic core can use TRELLIS; the
supporting apparatus must have exact geometry. The complete cottage board is
never the source of a monolithic building export.

## 3. Run local TRELLIS and preserve its result

Established settings: resolution **1024**, seed **42**, GPU 0 required,
BiRefNet removal with retained cutout, PNG textures (`--webp off`), eight CPU
threads. These reproduce the approved working route; they are not a runtime
triangle budget. Record any deliberate change and compare the result.
Do not use GeometryOnly as a shortcut to the final textured asset: the earlier
tested branch skipped processing and produced millions of triangles.

The existing grove wrapper accepts **only `tree` or `rock`**; the roster wrapper
accepts **only its six creature IDs**. Do not pass invented new IDs to them.
For another organic asset, make a small slice-local logging wrapper around the
same verified CLI arguments. Use explicit depot paths so a worktree can reuse
the installed models. This command skeleton shows the actual supported flags;
the worker fills input/output paths and adds the provenance record:

```powershell
$artDepot = 'C:/Users/Matty/Dev/project-wroughtwild'
$artCli = Join-Path $artDepot 'build/trellis-local/runtime/trellis-cli.exe'
$artModels = Join-Path $artDepot 'build/trellis-local/models'
# Set these to the assigned PNG and a fresh directory in THIS worktree build/.
$artInput = (Resolve-Path -LiteralPath $InputImage).Path
$artOutput = [IO.Path]::GetFullPath($FreshOutput)
if (Test-Path -LiteralPath $artOutput) { throw 'Use a fresh output directory.' }
# Validate artOutput remains beneath this worker's resolved build root first.
New-Item -ItemType Directory -Path $artOutput | Out-Null
$artArgs = @('--image', $artInput, '--output', (Join-Path $artOutput 'source.glb'),
  '--models', $artModels, '--gpu', '0', '--require-gpu', '--res', '1024',
  '--seed', '42', '--bg-removal', 'birefnet', '--dump-bg',
  '--webp', 'off', '--threads', '8')
# Execute inside the GPU slot; record start/end, PID, exit status and hashes.
& $artCli @artArgs *> (Join-Path $artOutput 'generation.log')
if ($LASTEXITCODE -ne 0) { throw 'Generation failed; inspect this job log.' }
```

Run one GPU job at a time. A small synchronous cooperative mutex can guard the
command; every ART-07 worker uses the same name. Acquire without a long blocked
wait so a busy worker can continue CPU work and send progress. On abandonment,
inspect surviving child processes before retrying; do not presume the GPU is free.

```powershell
$artGpuMutex = [Threading.Mutex]::new($false, 'Local\Wroughtwild-Art07-GPU')
$artOwnsGpu = $false
try {
  $artOwnsGpu = $artGpuMutex.WaitOne(0)
  if (-not $artOwnsGpu) { throw 'ART-07 GPU slot busy; continue CPU work.' }
  # Run and await exactly this session's generation/render/benchmark here.
} finally {
  if ($artOwnsGpu) { $artGpuMutex.ReleaseMutex() }
  $artGpuMutex.Dispose()
}
```

This is a command pattern, not an installed queue or background automation.
Pre-existing Studio/playtest jobs do not take this mutex: inspect them read-only
and do not interrupt them. A released mutex is not proof of an unloaded GPU.
Record input PNG/cutout/GLB hashes, runtime/model revision, exact argument array,
duration, exit code and device. Raw export and input remain immutable.

## 4. Inspect before finishing

Import the raw GLB into a fresh Blender inspection. Uniformly normalize a copy
only after identifying actual facing and base. Record the transform from raw
coordinates to review coordinates and from review coordinates to game metres.
The roster's longest-dimension-two normalization is **studio units**, not a
universal gameplay scale. Grove and device scripts have different assumptions.

Render actual front/back/side/three-quarter/top/underside geometry in clay and
material. Check floating fragments, merged openings, disconnected branch ends,
impossible membrane supports, hidden undersides and duplicated parts. Count
actual triangulated faces after modifiers/import, degenerate faces and nonfinite
values. Do not call polygon count triangle count without checking topology.
Reject/regenerate a source that misses the brief; a successful export is not
evidence of attractive or usable geometry.

Useful inspected examples, not generic scripts to run unchanged on every asset:

- [Grove recipes](../../../tools/wroughtwild-grove/README.md): source, attached
  canopy, rock/root contact, normal baking, standalone walk and packed scene.
- [Roster source inspection](../../../tools/wroughtwild-roster/README.md):
  multi-angle comparison, raw metadata and reopening; normalize cautiously.
- [Deep lifelines](../../../tools/wroughtwild-roster/LIFELINES.md): real depth,
  attached UV channels and measured emission-off evidence.
- [Red device](../../../tools/wroughtwild-workshop/README.md): fitted body,
  closed recovered solids, distinct UVs and real native work-state presentation.

## 5. Finish the editable Blender master

Preserve raw source and accepted hand edits. Make separate source, finished,
runtime and review collections. In game metres the established export mapping
is Blender `(x,y,z)` → Godot `(x,z,-y)`; forward is Blender +Y / Godot -Z where
that convention applies. Verify imported dimensions and orientation rather than
applying the conversion twice. Keep base/hinge/attachment origins explicit.

For natural growth, connect branches/roots/canopy to measured parent surfaces.
For devices, retain separate pivoted moving parts and native connection sockets.
For lattice pieces, derive sizes/forms/traits from the current catalogue and
data, preserve coarse/fine alignment and do not enlarge collision for ornaments.
Keep finite resource work stages and source-owned fragments separate from
decorative ground dressing. Recovered solids need closed cut faces and their
own coherent UVs, not nearest-vertex UV transfers across unrelated charts.

Scars need broad dark injury and physical recession that survives with emission
disabled. Model depth or a demonstrated geometric cut is required; a bright mask
or small bump alone fails the selected direction. Follow actual surface paths,
branch into growth roots, avoid bridges across cavities, and measure meaningful
depth on the delivered scale. **Do not copy ART-06C's 0.032 studio-unit incision
blindly onto a tree or device.** Choose/document asset-specific dimensions and
confirm them with before/after sections or BVH rays. Preserve the original
albedo/ORM source; damaged margins, energy mask and travel coordinates are
separate. Albedo is colour; ORM/normal/scar data use linear sampling.

Use a pause-aware engine shader for moving light, without relying on bloom or
a light per scar. Blender off/peak stills prove form; Godot video proves motion.
Ordinary hosts get a quiet material. Device/source pulses read native events
or progress rather than a free-running success loop. Actual attacks retain
their existing warning language and authority.

Author detail levels from a good source: preserve silhouette, important cavities,
scar routes and contacts; simplify small geometry into baked material detail.
Measure triangles, surfaces/draw calls, texture dimensions/bytes, transparency
overdraw and shadow costs. Treat dense sources as high-detail masters. Avoid
universal arbitrary decimation ratios or fabricated performance budgets.

Run background Blender with bounded CPU threads, isolated user resources and
failure propagation. Set paths from the worker's reviewed inputs:

```powershell
$artBlender = Join-Path $artDepot 'build/blender-tool/blender-4.5.9-windows-x64/blender.exe'
$artPriorBlenderResources = $env:BLENDER_USER_RESOURCES
try {
  $env:BLENDER_USER_RESOURCES = Join-Path $WorkerBuild 'blender-user'
  & $artBlender --background --threads 8 --python-exit-code 1 --python $SliceScript -- $Source $FreshOutput
  if ($LASTEXITCODE -ne 0) { throw 'Blender job failed; inspect its own log.' }
} finally { $env:BLENDER_USER_RESOURCES = $artPriorBlenderResources }
```

This is a pattern; the slice script must exist and its argument contract must
be inspected. Never claim an example placeholder command was executed.
Pack images into the final `.blend`, save, close and reopen it in another
Blender process. Check actual exported GLBs separately. Manual edits are not
automatically reverse-translated into a generation script; preserve them in the
authoritative master and document their reproducible lineage.

## 6. Validate in an isolated Godot project

Create a fresh review/output folder and its own APPDATA/user directory. Restore
environment variables after launch. Use `Start-Process -WindowStyle Hidden`
unless the owner asks for a visible review; record the launched PID and act only
on it. No broad `taskkill`/Stop-Process by executable name. Do not load the
owner's normal world or replace the live native DLL.

Static kits: review metres, contacts, normal maps, dark/lit materials, wind and
near/middle/far transitions in day/shade/dusk. Stateful kits: use actual native
resource, station or machine state in a copied game/checkpoint, including failed
placement, work pause/blockage, exact contents, depletion and separate-process
reload. Existing scenario helpers may guide input setup; label test grants and
posed scenes honestly and do not count them as paid first-hour gameplay.

For native studies, freeze **one explicitly recorded current commit** for both
game/data and simulation. Older helpers default to historical commits: supply
the reviewed revision explicitly. `tools/wroughtwild-workshop/build-native.ps1`
and `tools/wroughtwild-route/prepare.ps1` accept `-Revision`; their remaining
hard-coded ART-04/05 assets/checkpoints still need deliberate task-local adaptation.
Do not run the old route prepare command and claim it is a current ART-07 test.
The recipe baseline at planning is `1eda3c512aefadbc00638c1b4fbde8096dd8ae09`;
new sessions inspect later history and record the exact revision they use.

Run fresh import and actual Forward+/Compatibility renders. A headless parse
does not prove rendered appearance. Test pause and renderer-specific shader
errors, exact simple collision bounds, and relevant interaction regressions.
Benchmark separately from generation/capture, at fixed camera/settings and
comparable settled scene/load. Report p50/p95/worst frame, draws, primitives and
texture memory where measurable, plus device/settings and remaining uncertainty.
Do not claim lower-spec approval from an RTX result or change enemy caps to
mask expensive models.

## 7. Package and show the actual result

The handoff contains packed editable source, runtime candidates, isolated review
launcher, manifest, reproduction instructions and evidence. Hash every delivered
file before engine import. Verify a fresh copy so the canonical handoff stays
unchanged when Godot writes caches. Keep imports, caches and working builds out
of Git. Record selected vs rejected versions, source hashes, texture colour
spaces, LOD/pivot/state contracts and observed performance limits in the receipt.

Render the best actual model views in chat with absolute media paths. A concept
image cannot substitute for the delivered model. Finish only the assigned slice,
commit its scoped checked work and hand its SHA/package path to the publisher.
