# ART-07B1 broadleaf and pine canopy kit

B1 owns tree, pine, canopy_broadleaf, canopy_conifer, root_skirt and deadwood_stump. This is an isolated art-source and native-state handoff, not normal-world adoption. No game, simulation, tuning, shared catalogue or queue files are edited. Owner visual acceptance remains pending.

The approved ART-02 Quiet river oak, scar paths, fractured rock and forest floor are reused. Pine required one new isolated bare structural-tree input, made with built-in imagegen and the pinned local Windows TRELLIS route. Canopies are authored branchlets and folded leaf/needle-bearing shoots attached to measured source surfaces. No concept board is reconstructed as a mesh.

The selected outputs are `build/art07/b1/v01/broadleaf-kit-v05`, `pine-kit-v03`, `review-v05` and `native-fixture-v04`. Earlier candidates remain for diagnosis: broadleaf first failed reduced-branch contacts; v02 had low root cuts and non-exporting cap materials; v03/v04 exposed cap UV and altered-LOD socket errors. Pine v01/v02 had the cap problems. Final geometry fixes resnap each altered host independently and give cut faces explicit coherent UV0 charts. Assertions were not relaxed.

## Tools and inputs

Repository/tool depot: `C:/Users/Matty/Dev/project-wroughtwild`. Worker: `C:/Users/Matty/Dev/project-wroughtwild-art07-b1`, branch `codex/art07-b1`. Frozen published game/data/native base: `56ce6bbe343012205690cf669491372958b80662`.

Use the depot's Blender 4.5.9, Godot 4.5 and pinned TRELLIS v0.6.0 packages. Python is `C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` with existing NumPy/Pillow. No install or download is needed. `generate-pine.ps1` verifies the runtime and model hashes from the existing TRELLIS manifest. GPU 0 required; resolution 1024, seed 42, BiRefNet retained cutout, PNG textures, eight threads. The GLB reports CUDA runtime commit `16f3109e82f3922033bfa62b83c42899678b7b6f`, build `2026-08-21T08:39:09Z`; record that actual value separately from the release target. Generation took 48.7023 seconds.

`run-job.ps1` isolates APPDATA, LOCALAPPDATA and Blender resources beside each log; it records exact executable/argument array, PID, exit and duration. Render/generation/benchmark jobs share `Local\Wroughtwild-Art07-GPU` and refuse existing Godot/Blender/TRELLIS processes. Coordinate other workers first. Never terminate an existing process; only the launched own PID is eligible for failure cleanup. Run benchmarks separately from imports, captures, generation, compilation and other native tests.

## Reconstruction

Use new output names, never overwrite selected masters or approved inputs. Exact executed arrays are in the handoff evidence job JSON. The following shows the contracts, using PowerShell variables for the explicit local paths:

```powershell
$b1 = 'C:/Users/Matty/Dev/project-wroughtwild-art07-b1'
$depot = 'C:/Users/Matty/Dev/project-wroughtwild'
$recipe = "$b1/tools/wroughtwild-art07/b1"
$py = 'C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$blender = "$depot/build/blender-tool/blender-4.5.9-windows-x64/blender.exe"
$godot = 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
# inspect_source.py: SOURCE FRESH_DIRECTORY broadleaf|pine
# build_kit.py: NORMALIZED_SOURCE_BLEND FRESH_DIRECTORY broadleaf|pine
# audit_blender.py: FRESH_REPORT_JSON BROADLEAF_DIRECTORY PINE_DIRECTORY
& "$recipe/run-job.ps1" -Program $blender -Arguments @('--background','--threads','8','--python-exit-code','1','--python',"$recipe/build_kit.py",'--',"$b1/build/art07/b1/v01/oak-inspection/broadleaf-source.blend","$b1/build/art07/b1/reproduction-oak-v01",'broadleaf') -Log "$b1/build/art07/b1/reproduction-oak-v01.log" -Gpu
& $py "$recipe/prepare_review.py" "$b1/build/art07/b1/v01/broadleaf-kit-v05" "$b1/build/art07/b1/v01/pine-kit-v03" "$b1/build/art07/b1/reproduction-review-v01"
# Review modes: --check, --capture, --motion, --benchmark; render methods forward_plus / gl_compatibility.
& "$recipe/run-job.ps1" -Program $godot -Arguments @('--path',"$b1/build/art07/b1/reproduction-review-v01",'--rendering-method','forward_plus','--audio-driver','Dummy','--','--capture') -Log "$b1/build/art07/b1/reproduction-capture-v01.log" -Gpu
```

Import a new project first with `--headless --editor --import --path PROJECT --quit`. All Blender recipes use eight CPU threads, packed textures and actual Cycles inspection views. `inspect_costs.py BUILD_ROOT FRESH_JSON` independently extracts GLB metadata, textures and current regression results and rehashes the 105-file approved grove package.

Rebuild the frozen native DLL with the read-only `tools/wroughtwild-workshop/build-native.ps1 -Revision 56ce6bbe343012205690cf669491372958b80662 -Output FRESH_B1_NATIVE_DIRECTORY`; it reuses the pinned existing godot-cpp ABI. Expand the exact same base's `game/` and `data/` archive, copy that DLL to the copied `game/bin`, then run `prepare_native.py REVIEW COPIED_GAME`. Native modes are the `res://b1/native_review.tscn` scene, optionally `-- --restore-partial` / `-- --restore-final`. Use `--fixed-fps 60 --audio-driver Dummy` and the same isolated APPDATA for flow/restarts. `run-current-checks.ps1 -Project COPIED_GAME -Logs FRESH_DIRECTORY` runs unchanged baseline suites; no paid gameplay is claimed from these fixtures.

## Metres, attachments and controls

Blender `(x,y,z)` exports to Godot `(x,z,-y)` exactly once; unit is one metre and origin is root base. Approved oak structure is 8 m high; pine raw structure is uniformly scaled by 8.984967229953718 to 9 m after centring and grounding. Crowns extend beyond those heights. Full measured bounds, post-import counts and hashes are in `costs-and-lineage.json` and `blender-audit.json`.

`kit.json` documents each control's purpose. Two crown seeds per species; 580 broadleaf or 680 pine branchlets, rooted 9 mm into the measured host. Leaves originate on their supporting bent twig, and each LOD resnaps its own host. Independent export audit checks every leaf root within 13 mm of a twig surface and every branchlet component within 26 mm of its trunk. No floating canopy mass is accepted.

Broadleaf leaf lengths .22–.33 m; pine needle-bearing shoot lengths .18–.29 m. Branchlets are five-sided tubes; crown variation changes lengths/directions and colour without game randomness. Broadleaf twigs .48–1.03 m, conifer .38–.78 m tapered with height. Near leaves have detailed folded/lobed strips, middle simpler folds, far one-row blades; all are opaque double-sided geometry. There is no alpha transparency overdraw, but geometry and double-sided shadow cost remain high. LODs switch at 18 and 55 m with one visible level. No crossfade or impostor is claimed.

Root seating: oak .65 m, pine .55 m burial on flat review ground. Stump cuts: oak 1.25 m and pine 1.0 m above source base, thus exposed tops .60/.45 m. Root skirts are matching clipped-source modules; use them as alternatives, not overlapped with the same full roots. Deadwood is an inert clipped segment with a grounded side origin, not another resource identity. Generated roots are not a watertight terrain-fitting system.

Source albedo/ORM remain unchanged in packed SOURCE collections. Runtime bark maps are 1024² derivatives, albedo sRGB and ORM linear. Packed 512² cut-wood colour uses its own planar UV0; no unrelated UV transfer. UV2 holds independent linear scar core/damage or leaf attachment wind weight. glTF's flipped V is decoded in the Godot shader. No new normal bake is delivered; reduced bark relies on source colour/ORM and geometry. The dark incised oak uses approved routes, .18 m damage half-width, .055 m core half-width and .10 m maximum geometric recession; measured 0.0999275 m with emission disabled. Wind tips move at most .055 m over 4.8 seconds while roots stay fixed. The four-second ambient scar pulse ranges .22–2.8, uses a pause-aware uniform, no bloom and no per-scar light. It signals ambient damaged life, not work success.

## Native scope and limitations

The separate native fixture subclasses only resource presentation and stump construction in a copied current game. Work, remaining stock, payout, source IDs, fall duration and saving are inherited. Six presses fell each tree; exactly fourteen wood or pine units are collected through actual pickup absorption. Partial progress and final inventory are checked in separate processes. Stumps are inert and session-only, as in current native behaviour; a depleted identity stays absent on a fresh load.

The native fixture conservatively compresses X/Z of the full visual to fit the unchanged .7×3×.7 m authored-fixture collider at walk height. Resulting factors are oak .2368311 and pine .1311680, with Y unchanged. This visibly narrows the crown and is a state-test presentation compromise, not approval for ordinary-world placement. Full-width editable/runtime candidates are retained for subsequent adoption work. The free-flight source review has no collision, harvesting or generated geography. No new placement kit, recipe, resource or harvesting rule is added; unchanged current placement checks establish failed-kit retention and exactly one usable success.

The canopies follow an old open-grown oak and an irregular conifer, not a dense forest stand. Source cavities and hollow reconstructed undersides remain; roots need the documented burial. Far candidates are still 65–70k triangles and all LODs remain loaded, so this is not an approved shipping memory or forest-density budget. No lower-spec device, sloped terrain, seasonal foliage or normal-world integration is certified. B2/B3 ground/rock and B4 habitat composition remain outside this slice.

## Review and handoff

`launch-review.ps1 -Package ABSOLUTE_HANDOFF -CopyTo FRESH_COPY -Renderer forward_plus -Mode check` verifies every canonical file, copies it, verifies again, imports the copy and checks actual rendering. Use `-Mode review -Visible` for an interactive window; WASD/mouse free flight, L lighting, M scar light, Space pause, R overview, Escape cursor. Repeat with `gl_compatibility` in another fresh copy. Canonical package is never imported.

The package contains packed masters, immutable pine raw/cutout, candidate GLBs in `review/assets`, isolated source and native reviews, recipes, hashes and actual evidence. Runtime binaries/masters/caches are local-only. Git carries recipes, original input, curated actual screenshots/motion, costs/lineage and the receipt. See `docs/prototype/art07-production/receipts/b1.md` for exact package and commit results. Technical checks do not imply owner visual acceptance.

All six exported stump/root/deadwood meshes also passed the direct GLB cut-face audit: no open cut edges and cut UV0 within its coherent 0–1 chart. This does not certify the reconstructed source underside as manifold.
