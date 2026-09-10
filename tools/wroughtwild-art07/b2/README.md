# ART-07B2 — ground cover and forest floor

Six ordinary, unlit catalogue families: sapling/shrub, fern/bracken,
meadow grass, bramble/climber, moss/lichen and leaf/needle litter. The kit
has eleven plant variants at three detail levels, plus one unchanged ART-02
deadfall used solely as the climber's contextual support. It is a static
decorative study, not normal-world adoption or a new harvest/placement system.

## Sources and production

The shrub input was made with built-in imagegen using the exact adjacent
shrub-prompt.txt. The input is versioned under
docs/art/leyline-studies/2026-09-09/art07/b2/shrub-input-v01.png.
Local Windows TRELLIS v0.6.0 reconstructed that single object at 1024,
seed 42, GPU 0 required, BiRefNet with retained cutout, PNG, eight threads.
The installed runtime and ten model hashes were checked. The raw GLB reports
build commit 16f3109e82f3922033bfa62b83c42899678b7b6f, distinct from the
release target, preserved in provenance. No model or dependency was installed.

The ART-02 105-file handoff manifest is verified before use and again after
verification. The litter image and deadfall remain unchanged.
geometry.py is a bounded derivative of ART-02 build_grove.py's attached
leaf/tube approach. Fern pinnae, curved grass strips, rooted thorn stems,
support-fitted climber, moss tufts and litter chips are authored in Blender.
This does not reconstruct a board as one mesh.

The raw shrub has two connected components. The finished copy retains the
large rooted component and removes the detached 4,312-vertex component;
the original stays intact. UVs and both original image maps remain in the
packed source. Generated tip leaves are coarser than the individual concept;
small attached sprays supplement their silhouette.

## Coordinates and controls

All exports use metres, origin at the rooted base, Blender Z up.
Standard glTF conversion is Blender (x,y,z) to Godot (x,z,-y); do not apply
it a second time. Raw shrub coordinates subtract
(-0.0034347773, 0.0006426573, -0.4208771586), then scale uniformly by
1.6255600861, for a 1.35 m host. There is no designated creature facing.
The climber and unchanged support share an origin and must be placed together;
it is not a universal conforming vine. Moss/lichen/litter patches need fitted
ground support. Foliage has no harvest identity.

kit.json explains all exposed authoring values. Seven/eighteen metre
distance bands select near/middle/far. Detail changes preserve the rooted
plant and main stems, reducing leaf/blade subdivisions. A far fern replaces
individual pinnae with narrow shaped leaflets; transitions need owner review.
No numeric runtime budget is approved.

Ordinary leaves are opaque, two-sided geometry with vertex colour and
UV-driven veins. They have zero alpha-blended surfaces. Natural overlap and
double-sided shadows still cost raster work. The original shrub albedo uses
sRGB; its retained ORM uses linear data. No ordinary material emits.
There are no altered hosts in these six assignments, so scar/pulse controls
are deliberately absent. Pause-aware wind bends attached plant coordinates
by 18 mm per metre at a 5.5-second period. Ground dress and the supported
climber stay still.

The unchanged ART-02 floor input is not mathematically seamless. The Godot
floor samples mirrored coordinates in two rotated/scaled layers, blends
these at broad frequency and transitions into exposed dark humus on the
authored route. This removes colour jumps without editing the original.
Blender uses the same mirrored input for a simpler inspection floor; the
engine is authoritative for the final ground blend and wind.
The engine explicitly builds the floor mip chain before rendering, preventing
the distant shimmer seen in the initial no-mipmap import.
Each shrub LOD is reseated at Z=0 after simplification; each fern's independent
frond seed preserves its centreline regardless of leaf subdivision count.

## Delivered review

The receipt gives the absolute immutable handoff and manifest hash.
Use launch-review.ps1 to hash-check and copy the package before import.
Never import into the canonical package.

WASD/mouse is review flight, L cycles day/shade/dusk, Space pauses motion,
0 selects automatic detail, 1/2/3 force near/mid/far, R resets the overview,
Escape releases/captures the cursor. The automatic check separately walks a
real 0.32 m-radius, 1.8 m-tall CharacterBody through 16 m of supported route.
The review's eye is 1.65 m, speed 2 m/s. These are study controls, not edits
to gameplay bodies or movement.

Automatic modes: --check, --capture, --motion, --benchmark.
Both forward_plus and gl_compatibility use 1280×900, 4× MSAA, no bloom.
Benchmarks disable VSync, use 90 warmup/300 sampled frames per case, and
exclude capture readback. Zero Compatibility GPU time means unavailable.
Captured motion uses a deterministic 12 Hz clock; the smaller GIF/WebP
samples every other actual frame. It does not establish gameplay FPS.

## Reconstruction

Run commands from the B2 worktree. All outputs must be fresh; existing
hand-edited masters are authoritative and must never be overwritten.
Canonical depot: C:/Users/Matty/Dev/project-wroughtwild.
Python: C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe.
Blender: depot build/blender-tool/blender-4.5.9-windows-x64/blender.exe.
Godot: C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe.

1. generate-shrub.ps1 -Output FRESH_RAW runs the pinned local generator.
   For exact reconstruction of this candidate, reuse the packaged raw GLB;
   cross-machine bitwise generation is not promised.
2. Blender --background --threads 8 --python-exit-code 1 --python
   tools/wroughtwild-art07/b2/inspect_source.py -- RAW/source.glb FRESH_INSPECTION.
3. Blender with the same flags and build_kit.py --
   INSPECTION/shrub-source.blend DEPOT FRESH_KIT.
4. Python prepare_review.py KIT DEPOT FRESH_REVIEW; run a headless
   --editor --import --path REVIEW --quit, then actual rendered modes above.
5. Blender audit.py -- KIT FRESH_AUDIT.json; Python
   verify.py KIT REVIEW DEPOT FRESH_VERIFICATION.json.
6. Python encode_motion.py REVIEW FRESH_MOTION.
7. package.py B2_BUILD_ROOT FRESH_PACKAGE packages the selected version map
   recorded in that script. Adjust a copied recipe deliberately for a new
   version; never overwrite the selected source.

run-job.ps1 records the exact executable, argument array, PID, exit code,
duration and isolated APPDATA in each .job.json. It holds the shared GPU
mutex for render/generation jobs and checks for existing processes; a bounded
55-second acquisition attempt can yield to another worker. Blender sources
render on CPU with eight threads. Benchmarks run without these competing jobs.
Only this runner's own failed process can be stopped.
render-batch.ps1 holds that same slot across the serial two-renderer captures
and motion jobs. A separate Benchmark phase records its own slot interval;
per-process logs inside a batch inherit that outer GPU lock.

Current-game regressions use frozen game/data/native commit
f00d4b76274ef2a73c3b6f4a275d2bd3ca0f958d, not the live checkout or DLL.
build-native.ps1 -Revision SHA -Output FRESH_NATIVE builds against the existing
approved godot-cpp ABI. Archive game data from the same SHA, copy only that
built DLL to the copied game's bin, import, then run-current-checks.ps1
-Project COPIED_GAME -Logs FRESH_LOGS. The package includes the exact source
snapshot ZIP and checked DLL for this isolated regression.

## Boundaries

The handoff has packed editable sources, runtime candidates, exact raw input,
standalone review, evidence, reproduction recipes and hashes. Git contains
recipes, the original input PNG, curated actual evidence and receipt only.
Raw/build/master outputs, dependency bundles, imports and normal saves are
not committed. Main integration/push belongs to the dedicated publisher.

This study has no inventory or interactive kit. Existing failed-placement
retention and exactly-once success are tested in the unchanged current game,
not invented for cosmetic plants. No finite resource, geography, save, recipe,
trait gate, combat rule or ordinary-world scatter is changed.
Owner visual acceptance, runtime adoption, lower-spec performance, terrain
conformance on arbitrary slopes and world-scale budgets remain separate.
