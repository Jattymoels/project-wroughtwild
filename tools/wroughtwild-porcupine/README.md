# MOB-01 porcupine production recipe

The approved ART-06C Cinder Archer is fitted to its actual anatomy. It reuses
native ranged movement/mark/fire behavior and A2's manually sampled driver.
No combat or save rule is added.

## Reproduce

Use the existing Blender 4.5.9 executable and a **new** output directory:

```powershell
& 'C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe' -b --python-exit-code 1 --python tools/wroughtwild-porcupine/build_rig.py -- 'D:/Wroughtwild/source-art/mob01-porcupine/input-art06c' 'D:/Wroughtwild/source-art/mob01-porcupine/NEW_VERSION'
python tools/wroughtwild-porcupine/cook_runtime.py 'D:/Wroughtwild/source-art/mob01-porcupine/NEW_VERSION'
```

Selected version: `D:/Wroughtwild/source-art/mob01-porcupine/rig-v04`.
`porcupine-rigged.blend` contains the dense weighted original host, one runtime
reduction, twelve head-bound attachments and four actions on `Porcupine rig`.
NLA tracks are muted in the saved rest view; select a `Porcupine__idle`, `walk`,
`windup` or `release` action to edit. All source maps are packed.

Original inputs remain immutable. Dense geometry/UVs are unchanged; only the
runtime surface is collapse-decimated, with duplicate faces removed by Blender
validation. This is generated triangle topology, not manual retopology. The
runtime has 149,968 host triangles plus 4,432 attachment triangles. No normal
map is invented. `rig-report.json` records source receipts, seventeen pivots,
four paws, normalized weights and actual saved pose checks. The helper's `hoof`
suffix names rigid paw anchors; it does not change the animal's feet.

## Art controls (`rig.json`)

Source units use ART-06C's two-unit studio scale, not game metres.

| Controls | Purpose |
| --- | --- |
| `runtime_host_triangles` | One production density retaining face, quills and physical channels. |
| `weight_smoothing_passes` | Diffuse region joins along connected skin while locking skull/paws. |
| `stance_sink_units` | Relax short legs for planted two-bone poses without stretching. |
| `brace_sink_units` | Lower the body during shot commitment. |
| `body_brace_radians`, `chest_brace_radians`, `head_tuck_radians` | Brace shoulders and lower the nose for the native tell. |
| `quill_brace_radians`, `quill_recoil_radians` | Raise the grown comb, then recoil on native release. |
| `body_recoil_radians`, `recoil_units` | Small visual recoil; never displace collision or projectile origin. |
| `breath_units`, `idle_seconds` | Slow breathing and head motion. |
| `walk_bob_units`, `step_span_units`, `step_lift_units`, `stance_fraction` | Four-beat walk with planted sweep and lifted return. |
| `tail_sway_radians` | Restrained attached tail response. |
| `walk_seconds` | Source clip duration; runtime phase follows travel. |
| `release_clip_seconds` | Source duration matching existing 0.22 s cosmetic recovery. |

Windup duration comes from current `combat_realtime.json`. Bone pivots, weight
regions and the small idle head nod are fitted anatomy in the recipe. Runtime
`mobs/manifest.json -> cinder_archer.porcupine` documents uniform size, yaw,
ground/forward offset, stride and cull margin. Stride is 0.95 m per pre-family
cycle: fast travel can slide at the preserved native speed. No terrain IK.

Original 2048x2560 albedo/ORM atlases and scar map are copied with hash receipts.
`porcupine.gdshader` preserves texture-multiplied dark injury and connected pulse,
adding native status priority. Eyes/whiskers receive only status tint and never
emit. Four-second pulse, 32% residual, 2.4 peak and 0.2 crest are ambient anatomy.

## Focused checks

After headless Godot import, from this worker:

```powershell
./tools/wroughtwild-porcupine/run_check.ps1 -Capture
./tools/wroughtwild-porcupine/run_check.ps1 -Scene res://tests/mob01_restore.tscn -Log restore
```

Capture acquires `Local\WroughtwildArtRender` without waiting; `RENDER_BUSY` means
nothing launched. It uses private D: application data, the verified mouse opt-out
and a temporary `display/window/size/no_focus=true` override only if none exists.
The fixture asserts visible mouse/unfocusable window. `finally` removes only the
runner's own override and releases its mutex. Tests have a process timeout.
Headless source/import/restore needs no GPU lock. `assemble_motion.py` uses
bundled Python/Pillow to assemble 100 actual viewport frames into a 3.34 s GIF.

Normal play uses `game/project.godot` without a MOB/ART flag. See the
[result and integration handoff](../../docs/prototype/mob01-porcupine-result-2026-09-15.md).
