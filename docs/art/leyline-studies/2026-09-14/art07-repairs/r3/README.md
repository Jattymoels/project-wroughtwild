# ART-07R3 — Building face, end and edge materials

Candidate for serial integration. Owner visual acceptance is pending; ordinary-world rollout is outside scope. The exact commits and sealed package identity are in the [R3 receipt](../../../../../prototype/art07-repairs/2026-09-14/receipts/r3.md).

The retained G1 binding projected the same face map over every direction. R3 uses the original D4/D5 face and cut maps at their measured metre repeats, and the original shared D6 metal maps. Timber follows member length, existing rails and roof slopes; actual cuts show endgrain. Mineral bedding continues across broad sides and coarse/fine joins. Protected metal recesses use the source seam response. Glass keeps its 0.72 opacity and opaque frame, with the pane in the alpha pass.

No authored texture or geometry was added, removed or replaced. All 26 shapes, 19 families, 273 legal pairings, costs, unlocks, native colliders, targeting, finite stock and saved geography remain. Chest appearance/seating, canopy and ground cover retain the source behavior.

## Actual visual evidence

PNG files below are exact engine output bytes at 1440 × 900. The labelled inspection stock is separate from the real paid home. Full daylight/shade/dusk views in both renderers, all catalogue family views, originals and hashes are in the package.

| Inspection | G1 | R3 |
| --- | --- | --- |
| Grain, ends and coarse/fine joins | [Before](wood-end-close-before.png) | [After](wood-end-close-after.png) |
| Mineral bedding and cut laminations | [Before](slate-cut-close-before.png) | [After](slate-cut-close-after.png) |
| Metal faces and protected recesses | [Before](metal-joins-eye-before.png) | [After](metal-joins-eye-after.png) |
| Rotated hips, valleys and endgrain | [Before](roofs-rotations-close-before.png) | [After](roofs-rotations-close-after.png) |
| Layered fixed glass and opaque frame | [Before](glass-sorting-axis-before.png) | [After](glass-sorting-axis-after.png) |

[10 cm UV grid](metric-10cm.png) · [Chamfer/triangle octagon](octagon-triangles-eye-daylight.png) · [Shade](wood-joins-eye-shade.png) · [Dusk](wood-joins-eye-dusk.png) · [Reed/cork/mineral edges](covering-edge-close-daylight.png)

[Real paid home exterior](paid-exterior-eye-daylight-after.png) · [Paid interior before](paid-interior-close-daylight-before.png) · [Paid interior after](paid-interior-close-daylight-after.png) · [Native controller playback](paid-native-walk.gif)

The motion uses ordinary input and existing collision, approaches the closed saved door, and resets the player pose before saving. The GIF is illustrative 640 × 400 playback at 100 ms per frame; no frames are interpolated. Full original PNGs and actual engine physics frame stamps are retained. It is not a timing recording.

## Checks and preservation

- Original 273-pair catalogue: 1,861 checks and zero failures in each renderer. Original transaction suite: 470 checks plus 60 separate-process restore checks per renderer; assertions are unchanged.
- Dedicated inspection: 91 retained pieces with identical mesh, normal/index, pose and collider signatures across G1/R3. Both renderers retain close and eye-height cameras in daylight, shade and dusk.
- Real paid home: 18 checks per construction run and 9 per restore. Existing held resources pay the ordinary kit recipe; obstruction retains the kit, clear placement spends one kit and adds exactly one station. All 145 building records and four paid stations restore. Strict fingerprints match inventory, progression, source/work state, geography and ownership before/after and across processes.
- All 4,787 prepared runtime entries were rehashed. Only the three declared material/metadata hooks differ among original entries; native DLL, data, PNG/GLB assets and the original checkpoint remain exact. The complete five-package input verification retains 7,037 expected/actual entry hashes.
- Fresh original packed D4/D5/D6 master reopen is retained. No authored map or model replacement is claimed. Six additional D1–D3 recipe/settings Git blobs match the runtime pin after accounting explicitly for CRLF checkout conversion.

## Current-machine costs

NVIDIA RTX 5090 (driver 591.86, reported 32,607 MiB), Ryzen 9 9950X3D, 33,446,744,064 bytes RAM. Godot 4.5; 1440 × 900, 4× MSAA, VSync off. Inspection FOV 55°, paid home 60°. Each matched view/light case has 120 warmup frames and 300 samples. Imports, generation and captures are outside timing; no art/game/compiler competitor was detected. Home timing reopens the original three-station paid checkpoint and performs no transaction during sampling. Minimum target hardware and acceptance budget remain open.

The table selects matched daylight views. Full per-view/light CPU, GPU, frame, draw, geometry and loaded-memory values are in `checks-and-costs.json`. Capture-end counters can reflect a diagnostic camera and are not used for cost comparisons.

| Scene / renderer | Frame median ms (G1 → R3) | Frame p95 ms | Draws | Rendered primitives | Loaded textures MiB |
| --- | ---: | ---: | ---: | ---: | ---: |
| inspection / forward_plus | 0.436 → 0.421 | 0.485 → 0.456 | 11 → 11 | 2,200 → 2,200 | 367.66 → 403.71 |
| home / forward_plus | 3.102 → 3.085 | 3.507 → 3.567 | 1040 → 1040 | 5,818,869 → 5,818,869 | 1307.77 → 1311.77 |
| inspection / gl_compatibility | 0.677 → 0.683 | 0.754 → 0.775 | 37 → 37 | 2,200 → 2,200 | 208.27 → 235.27 |
| home / gl_compatibility | 5.098 → 4.987 | 5.795 → 5.766 | 2553 → 2553 | 5,818,869 → 5,818,869 | 1288.49 → 1291.49 |

| Scene / renderer | Cached materials (G1 → R3) | Unique original PNG bindings | Newly bound / no longer bound original PNGs |
| --- | ---: | ---: | ---: |
| inspection / forward_plus | 34 → 93 | 39 → 66 | 27 / 0 |
| home / forward_plus | 3 → 8 | 3 → 6 | 3 / 0 |
| inspection / gl_compatibility | 34 → 93 | 39 → 66 | 27 / 0 |
| home / gl_compatibility | 3 → 8 | 3 → 6 | 3 / 0 |

Across all 78 matched view/light cases, rendered primitive counts are identical. Draw differences range from −19 to +1; the single added draw is the Compatibility paid exterior at dusk. Observed median-frame deltas range from -0.111 to +0.078 ms, and p95 deltas from -0.290 to +0.081 ms. These are individual paired runs, not a performance acceptance budget.

Authored texture files added/removed: **0 / 0**. Newly bound original edge images, exact names/dimensions and construction material cache counts are reported for each comparison group. Backend totals include the unchanged world and renderer allocations. Primitive counters include pass/culling behavior; the source geometry itself is unchanged. Zero backend GPU timestamps mean unavailable telemetry, not zero cost.

## Controls and limits

| R3 control | Value | Purpose |
| --- | --- | --- |
| `normal_strength` | `0.45` | Inherited G1 microrelief strength; does not change shape or collision. |
| `frame_shade` | `0.72` | Inherited G1 frame shade, now also distinguishes existing timber rails. |
| `end_normal_threshold` | `0.75` | Selects cut map where the normal faces along the timber member; no endgrain blend onto long faces. |
| `board_width_m` | `0.25` | Inherited quarter metre D1/D3 physical board spacing; variation follows the same run across coarse/fine joins. |
| `board_phase_texels` | `97` | Adjacent physical boards shift longitudinal grain by this whole-texel step within the original 1024-pixel face tile. |
| `face_resolution_px` | `1024` | Original D4 map size used to keep phase shifts on whole texels. |
| `recess_min_m` | `0.001` | Minimum measured inward skin depth that receives protected metal seam response. |
| `recess_edge_guard_m` | `0.012` | Keeps protected seam patina away from outer arrises; no added geometric seam. |
| `door_rails_y_m` | `[-0.78, 0.53]` | Existing D2 horizontal rail centres; material orientation follows the retained geometry. |
| `door_rail_half_width_m` | `0.035` | Existing D2 half width between strap grooves. |
| `coarse_rail_width_m` | `0.065` | Existing D1 end-rail width on cube and wall; rail grain runs horizontally. |
| `fine_rail_width_m` | `0.032` | Existing D3 half cube/wall rail width; does not scale texture density. |
| `panel_frame_width_m` | `0.045` | Existing native/D3 integral panel batten width; frame orientation only. |
| `window_frame_width_m` | `0.075` | Existing native/D3 opaque window frame width; no body or pane change. |
| `seam_roughness_add` | `0.12` | Additional roughness at protected existing metal recesses; oxide/patina remains distinct from the metal body. |
| `projection_axis_threshold` | `0.95` | Stabilizes near-axis broad-plane projection across existing bevel normals. |
| `roof_face_min_up` | `0.2` | Separates roof covering planes from cut side/underside faces. |
| `alternate_axis_threshold` | `0.8` | Selects a nonparallel tangent reference for end maps. |
| `recess_face_threshold` | `0.9` | Limits protected metal seam tint to front-facing recesses. |
| `inspection_grid_m` | `0.1` | Diagnostic grid pitch in metres; used only in labelled UV evidence. |
| `inspection_line_fraction` | `0.035` | Diagnostic grid line fraction; not enabled in normal candidate rendering. |

D4/D5 face/cut repeat metres, family colours, glass opacity, and D6 seam colour/metallicity remain in the original family data. D6 keeps the retained G1 fallback repeat of 0.5 × 0.5 metres for its shared maps. Member axes and slope/hip/valley selection derive from retained native shape definitions. The grid is active only for labelled diagnostic evidence. Inspection lighting uses day sun/ambient 1.15/0.45, shade 0.12/0.35, dusk 0.4/0.22 with sun pitch −0.85/−0.2 radians and yaw −0.55. Paid views retain world mood with shade/dusk sunlight multipliers 0.12/0.35.

Retained limits: source geometry/grooves and map repetition remain; layered 0.72-opacity glass attenuates heavily and is not refractive; the paid interior retains its source darkness. R2 must reconcile shared G1 material dispatch, mesh identity/cache and PieceLook binding against the common baseline before combined measurements. No peer runtime is copied. All source LOD choices remain unchanged. Owner visual acceptance and combined R8/R9 review remain pending.

Failed attempts are retained: the initial runner gap produced no engine launch; the first paid fixture queried restored bodies before physics registration; the first new restore comparison mixed live integer arrays with JSON-parsed arrays. Corrections synchronize the fixture and compare all exact persistent JSON fields without dropping fields or using tolerances. Successful fresh engine results and strict fingerprints supersede those attempts. Compatibility retains the original SSAO warning; diagnostics were not suppressed.

## Reconstruction

Use the installed Python and the owned tools described in [the reconstruction README](../../../../../../tools/wroughtwild-art07-repairs/r3/README.md). The installer requires the verified common G1 source and preserves its pin `6bb2e044dcd0bf1788896aa2c19cdf56fee93522`. Every engine/Blender job goes through the unchanged shared `run.ps1`, with the GPU mutex and private APPDATA/LOCALAPPDATA/TEMP/Blender resources. Exact commands, private paths, exits and log hashes are in the package. `seal.py --verify ABSOLUTE_PACKAGE` rejects extra/missing files or any byte mismatch. Receipts are outside their own hashed package.
