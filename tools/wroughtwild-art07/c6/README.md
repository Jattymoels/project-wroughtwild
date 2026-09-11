# ART-07C6 — ruin surfaces and retained approaches

Bounded outcome: source/contact variants for `ruin_wall`, `ruin_threshold`,
`workshop_approach` and `trail_transition`, plus an isolated current-game review.
The ordinary checkout and every other slice are read-only.

Authority: D-013/D-030 surface language, D-031 accidental smithy impact,
D-032 retained geography, and published LF3-R1 physical approaches. No game
tuning, placement rule, recipe, loot, save field or generator change is proposed.
Assumption: these are visual candidates; source publication is not ordinary
world adoption or owner visual acceptance.

Plan: verify B3/B4 packages; measure actual current native envelopes/approaches
and inspect original Blender sources; finish a bounded shared-texture kit;
reopen packed sources and check a fresh copy in both renderers; record physical
walking, unchanged ownership/placement checks and separate costs; package and
commit only this slice for the dedicated publisher.

Local runner derives from B3. Package verification and texture sharing reuse
the published B4 approach. Native preparation derives from C4, with C6's
explicit current revision and verified binary equivalence.

## Selected delivery and boundaries

`kit-v06` contains 19 variants and 57 GLBs. `review-v07` applies them only in a
copied native game. The adapter keeps the original mesh, layer mask, transform,
visibility parent, collision and refresh reference. A child visual replaces its
rendering; no source identity, route, loot, recipe, save schema or gameplay rule
changes. One existing old-smithy wall gets an ambient physical scar. Later LF
clamps, triple stamps, feed rods and pointing marks stay quiet and recognisable.
The adapter unpairs an original render RID before switching its layer mask and
restores its original world scenario immediately afterward. This avoids the
[Godot layer-change light-culling bug](https://github.com/godotengine/godot/issues/121989)
without altering scene nodes, camera masks, lights, geometry or physics. The
installed engine remains unchanged. Earlier v04 rendered diagnostics and the
native-only comparison are retained; v06 is checked independently. Final v07
corrects only the supplementary stills' captions and uses labelled inspection
sun for their LOD/emission comparisons. Full native captures are rerun there;
checks, walks, pulse motion and benchmarks retain the unchanged v06 behaviour.

Earlier geometry v01–v05 is diagnostic: flattened root-bank relief and excessive
moss were rejected; exported coplanar faces were simplified and native bounds
restored after simplification. Selected roots use uniformly scaled B3 fragments
plus small directly modelled branches sampled against masonry. Native faceting
and sparse terrain composition remain apparent. Day/shade/dusk use the original
sun direction; the additional **inspection-sun** pair rotates the review light
to show the same face before and after. That fixture is labelled in the images.

`kit.json` explains every exposed authoring/review control. Native metres map
once as Blender `(x,y,z)` → Godot `(x,z,-y)`. Native origins and instance bases
remain authoritative. Portals retain original solids and central clearances.
The measured 48 mm wall incision survives each exported LOD. Its linear vertex
channel controls cosmetic light through an explicit pause-aware clock, without
shader TIME, bloom, new lights, stock/work signals or attack tells. Opaque shared
materials use sRGB albedo and linear roughness/metal data. No normal map is added.

Four 512-square periodic stone/wood/soil/metal maps and two inherited 1024-square
root maps are deduplicated across native glTFs: about 16 MiB theoretical RGBA8
with mipmaps. GLBs retain embedded textures as portable source exports. Native
surface merging retains material boundaries. Mid/far variants simplify detailed
roots and the scar; simple existing modules deliberately keep their geometry.

## Reproduce with existing tools

Run from the C6 worktree. All output names must be fresh. The checked release
root is `build/art07/c6/v01`; the following uses a separate reconstruction root.
`build.py` validates each native source against published commit
`4b5d89b376765fbf4d46049aa099e0bb154a82da` and verifies the B3 master before use.
Prerequisite paths and pinned hashes are in `prerequisites.py`; a clean clone
does not include those ignored local packages or the tool depot.

```powershell
$c6Python='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$c6Blender='C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe'
$c6Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
$c6Depot='C:/Users/Matty/Dev/project-wroughtwild'
$c6Tools="$PWD/tools/wroughtwild-art07/c6"
$c6Root="$PWD/build/art07/c6/reconstruction-01"
& $c6Python "$c6Tools/prerequisites.py" "$c6Root/prerequisites.json"
& $c6Python "$c6Tools/prepare_native.py" "$c6Root/current"
& "$c6Tools/run-job.ps1" -Program $c6Blender -Arguments @('--background','--threads','8','--python-exit-code','1','--python',"$c6Tools/build.py",'--',$c6Depot,"$c6Root/kit-v06") -Log "$c6Root/logs/build.log"
& "$c6Tools/run-job.ps1" -Program $c6Blender -Arguments @('--background','--threads','8','--python-exit-code','1','--python',"$c6Tools/render_master.py",'--',"$c6Root/kit-v06/c6-master.blend","$c6Root/blender-v06") -Log "$c6Root/logs/render.log"
& "$c6Tools/run-job.ps1" -Program $c6Blender -Arguments @('--background','--threads','8','--python-exit-code','1','--python',"$c6Tools/audit.py",'--',"$c6Root/kit-v06","$c6Root/audit.json") -Log "$c6Root/logs/audit.log"
& $c6Python "$c6Tools/prepare_review.py" "$c6Root/current" "$c6Root/kit-v06" "$c6Root/review"
& "$c6Tools/run-job.ps1" -Program $c6Godot -Arguments @('--headless','--editor','--path',"$c6Root/review/game",'--import') -Log "$c6Root/logs/import.log"
& "$c6Tools/run-job.ps1" -Program $c6Godot -Arguments @('--headless','--editor','--path',"$c6Root/current/game",'--import') -Log "$c6Root/logs/current-import.log"
& "$c6Tools/run-current-checks.ps1" -Project "$c6Root/current/game" -Logs "$c6Root/current-checks"
& "$c6Tools/run-native-checks.ps1" -Project "$c6Root/review/game" -Logs "$c6Root/native-checks"
foreach($c6Stage in @('check','capture','walk','motion','benchmark')) {
  & "$c6Tools/run-stage.ps1" -Project "$c6Root/review/game" -Logs "$c6Root/$c6Stage" -Stage $c6Stage
}
& $c6Python "$c6Tools/verify.py" "$c6Root/review" "$c6Root/verification.json"
& $c6Python "$c6Tools/encode.py" "$c6Root/review" "$c6Root/media"
```

Checks use test grants/checkpoints and isolated user folders; their fixture routes are
not a paid first-hour playthrough. The walk fixture enables the ordinary player
controller and moves with supported physics, using existing jump input at ledges.
Only its initial position is seeded. It records actual camera frames and floor
contacts. Captures and motion are separate from the 180-warmup/600-sample fixed
view benchmarks, with VSync off at 1440×900. Renderer/process/device conditions
and exact executed argument arrays are recorded in job JSON files. A busy mutex
stops that launch without touching the running worker. Retry fresh/unstarted logs
after it finishes. Do not run a benchmark alongside other heavy work.
`run-window.ps1 -Project PROJECT -LogPrefix PREFIX` makes a bounded 48-second
attempt to acquire the shared slot, then runs capture/walk/motion/benchmark as
separate jobs inside that window. Each child job still checks active processes;
any rendered `ERROR:` stops the window. It creates no queue or automation.

`prepare_baseline.py CURRENT KIT FRESH_OUTPUT` creates the identical capture
fixture with C6 visual installation replaced by original-reference recording.
It diagnoses native Forward+ errors without adding C6 meshes, materials or layers;
its images are explicitly labelled native baseline and are not candidate evidence.

## Open the handoff

`package.py ROOT REVIEW FRESH_PACKAGE` assembles the selected release layout,
recipes, original current archive/DLL, evidence and hash manifest. It omits test
saves, engine caches and diagnostic surveys from the runnable game. Release
assembly expects the exact named files/folders used by this checked slice.

```powershell
& $c6Python "$c6Tools/verify_package.py" ABSOLUTE_PACKAGE ABSOLUTE_FRESH_COPY
& "$c6Tools/launch-review.ps1" -Package ABSOLUTE_PACKAGE -CopyTo ANOTHER_FRESH_COPY -Renderer forward_plus -Visible
```

The launcher verifies/copies before import and uses its own APPDATA/LOCALAPPDATA.
Use `gl_compatibility` for the other renderer. Tab cycles all nine views; WASD/QE
moves the camera; B changes before/after; L changes light; M switches scar emission;
Space pauses/resumes the explicit cosmetic clock; 0 selects automatic detail;
7/8/9 force near/mid/far; Escape releases the mouse. Camera/light controls are
review-only. Open `models/c6-master.blend` from a copy for SOURCE, FINISHED,
RUNTIME and REVIEW collections. Do not save into the canonical handoff.

Final paths, manifest hash, costs, diagnostic limitations and publication status
are recorded in `docs/prototype/art07-production/receipts/c6.md`. GPU results on
the RTX 5090 do not clear ordinary-world adoption or a new habitat's performance.
