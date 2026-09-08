# Wroughtwild boar — ART-01 authoring and review

This bounded study preserves the owner's TRELLIS boar and authors its Red scar
surface, fitted skin, movement and distance candidates. It is a separate Godot
project, with no game autoloads, native extension or normal-save access.
See the [work item](../../docs/prototype/boar-living-scars-2026-09-09.md).

## Inputs and tools

- Original source and SHA-256 are pinned in [boar-study.json](boar-study.json).
  The exact original image/prompt is unidentified; do not invent provenance.
- Blender 4.5.9 LTS with its bundled NumPy. Existing local executable:
  `build/blender-tool/blender-4.5.9-windows-x64/blender.exe`.
- Godot 4.5, Forward+ for actual rendered checks. Headless import/checks work
  separately; a headless pass cannot prove a visible shader result.
- The existing workspace Python/Pillow runtime encodes previews and packages
  files. No new package, paid generation or hosted service is required.

Use fresh output directories. The builders reject an existing output directory.
Set `BLENDER_USER_RESOURCES` to an ignored study directory when running Blender;
the Godot runner redirects `APPDATA` to the selected review's own `user/` folder.
Keep concurrent processes and ordinary saves intact.

## Build order

Run Blender with `--background --threads 8 --python-exit-code 1 --python`, followed
by one script below and its arguments after `--`:

1. `build_surface.py -- tools/wroughtwild-boar/boar-study.json NEW_SURFACE`
2. `build_rig.py -- NEW_SURFACE NEW_RIG`
3. `build_far.py -- NEW_SURFACE NEW_RIG NEW_FAR`
4. `audit_source.py -- NEW_FAR/boar-candidate.blend NEW_RIG/rig-report.json NEW_AUDIT.json`

`build_surface.py` checks the original hash, normalizes without changing anatomy,
projects authored curves onto each flank, and incises at most 4 mm. It bakes
object position into the original UV atlas, then evaluates scars per texel.
Interpolating vertex masks across broad plates produced unacceptable glowing
triangles and is deliberately not the final method. The original embedded WebP
bytes are preserved under their real extension; the PNG transcodes preserve RGB
pixels exactly. No repainting of the source colour is performed.

`build_rig.py` joins duplicate positions, simplifies the near/mid candidates,
bakes normal detail, fits sixteen bones, normalizes at most four skin influences,
and authors six clips. Dense 100 Hz source sampling keeps planted feet through
the short release. A muzzle lift keeps the original low tusks clear of the floor.
The near/mid topology is generated triangles with fitted weights, not manually
retopologized quads. Ordinary collapse of this source stalls near 35k; its first
far export is superseded by the next step, not accepted as a 10k result.

`build_far.py` makes a 14 mm voxel volume, reduces it to 10k triangles and rebakes
four 1024 maps into a new atlas. It transfers the existing fitted skin. Fine source
gaps close and thin detail softens; compare it at distance. It saves the final
editable Blender handoff containing source, near, mid, far, masks and rig. All
images are packed. Its visible near mesh is the default when reopened.

The native melee windup is read from current tuning; the presentation release
uses the existing 0.22 seconds. These are review poses. Later Enemy adoption must
drive them from native events and avoid applying a second torso tilt or invented
attack clock. In-place walking does not establish travel speed or terrain IK.

## Godot review

```powershell
& tools/wroughtwild-boar/prepare_review.ps1 `
  -Surface NEW_SURFACE -Rig NEW_RIG -Far NEW_FAR -Output NEW_REVIEW
& tools/wroughtwild-boar/run_review.ps1 -Godot GODOT_EXE -Project NEW_REVIEW -Mode Import
& tools/wroughtwild-boar/run_review.ps1 -Godot GODOT_EXE -Project NEW_REVIEW -Mode Check
& tools/wroughtwild-boar/run_review.ps1 -Godot GODOT_EXE -Project NEW_REVIEW -Mode Capture
& tools/wroughtwild-boar/run_review.ps1 -Godot GODOT_EXE -Project NEW_REVIEW -Mode Benchmark
& tools/wroughtwild-boar/run_review.ps1 -Godot GODOT_EXE -Project NEW_REVIEW -Mode Review -Visible
```

The review binds the scar shader explicitly. The GLBs intentionally provide an
ordinary PBR fallback: Blender's node graph does not carry the travelling light
through glTF. A plain imported GLB therefore has no animated emission until the
provided shader and textures are bound. This avoids exporting whole-body glow.

Mask RGB channels are **core, damaged host, branch travel**; alpha is reserved.
They are linear data. Base colour uses `source_color`; normal/ORM/scar maps do
not. The config's linear core colour is converted for the `source_color` uniform.
Near/mid share 2048 textures and the 16-bit authoring scar. Far uses its separately
baked 1024 maps. The review retains lossless textures and generated mipmaps;
compression and memory reduction remain production integration work. Automatic
Godot mesh LODs are disabled so comparisons measure the explicitly selected mesh.

Controls: Space pause; M off/steady/breathing/travelling; A pose; L day/shade;
P 2.5/4-second period; B 25/50% minimum; D detail; S status override; arrows orbit
and distance; R reset camera. No bloom or per-scar light is used. One shared
material has stable independent instance phases. A process-driven cosmetic clock
stops with the review pause and with normal scene-tree processing; shader `TIME`
is not used. Status inputs demonstrate priority on this adapter only. The game's
existing `StandardMaterial3D` status code is not assumed to accept it unchanged.

`Check` verifies textures, skins/normalized influences, exact clip durations,
sampled finite bones, planted/swing hoof targets, pause/resume and distinct
instance phases. The Blender audit checks actual deformed near-mesh soles and
whole-mesh floor clearance. Capture checks are still required for gaps, silhouette,
tusk/plate clearance and surface quality; passing numeric tests is not art approval.

`Capture` creates same-camera day/shade light alternatives, pose and cardinal
views, 3.2/8/18 m LOD comparisons, and two 8-second loops at 24 sampled frames/sec.
Eight seconds closes both gait and pulse cycles. Frame sampling is not a runtime
FPS claim. `Benchmark` measures actual frame/render times without screenshots,
with 60 warmup and 180 measured frames per case; one and 24 actors correspond to
a hero and the current trial living-enemy limit. Its static/animated comparison
measures animation update overhead with a skin still bound, not isolated GPU skin
cost against an unskinned mesh. No normal world or simulation is profiled here.

## Package and preservation

Run the existing Python/Pillow executable with:

```text
tools/wroughtwild-boar/package_preview.py SURFACE RIG FAR REVIEW NEW_PACKAGE
```

The local handoff contains a packed editable `.blend`, all three GLBs, textures,
the isolated Godot project/import recipe, evidence, loops and a hash manifest.
It excludes imported caches and user data. Import and check that new package
again before delivery. Selected evidence, recipes and reports are versioned;
generated working assets remain under ignored `build/`, as the roadmap specifies.
Long-term source promotion and ordinary game adoption remain separate steps.

Run `validate_handoff.py REVIEW OUTPUT.json` with the same Python/NumPy/Pillow
runtime to inspect actual GLB streams, skin weights, counts, clocks, fallback
materials, embedded PNG headers and preserved source hashes. The source-rig
report intentionally retains its failed far-collapse result; this validator
records the separately rebaked 10k export actually delivered to Godot.
