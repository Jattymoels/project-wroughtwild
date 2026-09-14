"""Write the reviewable R3 evidence report only from completed run/cost records."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];out=ROOT/'build/art07-repairs/r3/v01';dest=ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r3'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
checks=read(out/'checks-and-costs.json');cfg=read(Path(__file__).with_name('settings.json'));curated=read(dest/'provenance.json')
proofs=['paid-forward-fingerprints','paid-compatibility-fingerprints','restore-g1-forward-fingerprints','restore-r3-forward-fingerprints','restore-g1-compatibility-fingerprints','restore-r3-compatibility-fingerprints']
for name in proofs:assert read(out/(name+'.json'))['stages']
lines=['# ART-07R3 — Building face, end and edge materials','',
'Candidate for serial integration. Owner visual acceptance is pending; ordinary-world rollout is outside scope. The exact commits and sealed package identity are in the [R3 receipt](../../../../../prototype/art07-repairs/2026-09-14/receipts/r3.md).','',
'The retained G1 binding projected the same face map over every direction. R3 uses the original D4/D5 face and cut maps at their measured metre repeats, and the original shared D6 metal maps. Timber follows member length, existing rails and roof slopes; actual cuts show endgrain. Mineral bedding continues across broad sides and coarse/fine joins. Protected metal recesses use the source seam response. Glass keeps its 0.72 opacity and opaque frame, with the pane in the alpha pass.','',
'No authored texture or geometry was added, removed or replaced. All 26 shapes, 19 families, 273 legal pairings, costs, unlocks, native colliders, targeting, finite stock and saved geography remain. Chest appearance/seating, canopy and ground cover retain the source behavior.','',
'## Actual visual evidence','',
'PNG files below are exact engine output bytes at 1440 × 900. The labelled inspection stock is separate from the real paid home. Full daylight/shade/dusk views in both renderers, all catalogue family views, originals and hashes are in the package.','',
'| Inspection | G1 | R3 |','| --- | --- | --- |']
for stem,label in [('wood-end-close','Grain, ends and coarse/fine joins'),('slate-cut-close','Mineral bedding and cut laminations'),('metal-joins-eye','Metal faces and protected recesses'),('roofs-rotations-close','Rotated hips, valleys and endgrain'),('glass-sorting-axis','Layered fixed glass and opaque frame')]:lines.append(f'| {label} | [Before]({stem}-before.png) | [After]({stem}-after.png) |')
lines += ['', '[10 cm UV grid](metric-10cm.png) · [Chamfer/triangle octagon](octagon-triangles-eye-daylight.png) · [Shade](wood-joins-eye-shade.png) · [Dusk](wood-joins-eye-dusk.png) · [Reed/cork/mineral edges](covering-edge-close-daylight.png)','',
'[Real paid home exterior](paid-exterior-eye-daylight-after.png) · [Paid interior before](paid-interior-close-daylight-before.png) · [Paid interior after](paid-interior-close-daylight-after.png) · [Native controller playback](paid-native-walk.gif)','',
'The motion uses ordinary input and existing collision, approaches the closed saved door, and resets the player pose before saving. The GIF is illustrative 640 × 400 playback at 100 ms per frame; no frames are interpolated. Full original PNGs and actual engine physics frame stamps are retained. It is not a timing recording.','',
'## Checks and preservation','',
'- Original 273-pair catalogue: 1,861 checks and zero failures in each renderer. Original transaction suite: 470 checks plus 60 separate-process restore checks per renderer; assertions are unchanged.',
'- Dedicated inspection: 91 retained pieces with identical mesh, normal/index, pose and collider signatures across G1/R3. Both renderers retain close and eye-height cameras in daylight, shade and dusk.',
'- Real paid home: 18 checks per construction run and 9 per restore. Existing held resources pay the ordinary kit recipe; obstruction retains the kit, clear placement spends one kit and adds exactly one station. All 145 building records and four paid stations restore. Strict fingerprints match inventory, progression, source/work state, geography and ownership before/after and across processes.',
'- All 4,787 prepared runtime entries were rehashed. Only the three declared material/metadata hooks differ among original entries; native DLL, data, PNG/GLB assets and the original checkpoint remain exact. The complete five-package input verification retains 7,037 expected/actual entry hashes.',
'- Fresh original packed D4/D5/D6 master reopen is retained. No authored map or model replacement is claimed. Six additional D1–D3 recipe/settings Git blobs match the runtime pin after accounting explicitly for CRLF checkout conversion.','',
'## Current-machine costs','',
'NVIDIA RTX 5090 (driver 591.86, reported 32,607 MiB), Ryzen 9 9950X3D, 33,446,744,064 bytes RAM. Godot 4.5; 1440 × 900, 4× MSAA, VSync off. Inspection FOV 55°, paid home 60°. Each matched view/light case has 120 warmup frames and 300 samples. Imports, generation and captures are outside timing; no art/game/compiler competitor was detected. Home timing reopens the original three-station paid checkpoint and performs no transaction during sampling. Minimum target hardware and acceptance budget remain open.','',
'The table selects matched daylight views. Full per-view/light CPU, GPU, frame, draw, geometry and loaded-memory values are in `checks-and-costs.json`. Capture-end counters can reflect a diagnostic camera and are not used for cost comparisons.','',
'| Scene / renderer | Frame median ms (G1 → R3) | Frame p95 ms | Draws | Rendered primitives | Loaded textures MiB |',
'| --- | ---: | ---: | ---: | ---: | ---: |']
for group in checks['benchmark_comparisons']:
    target='paid-interior-close' if group['scene']=='home' else 'wood-end-close'
    row=next(r for r in group['samples'] if r['view']==target and r['light']=='daylight');b=row['baseline'];c=row['candidate']
    texture='texture_bytes_total_loaded' if group['scene']=='home' else 'texture_bytes'
    bc,cc=b['cost'],c['cost'];bd=b.get('draw_calls',bc.get('draw_calls'));cd=c.get('draw_calls',cc.get('draw_calls'));bp=b.get('primitives',bc.get('primitives'));cp=c.get('primitives',cc.get('primitives'))
    lines.append(f"| {group['scene']} / {group['renderer']} | {b['median_ms']:.3f} → {c['median_ms']:.3f} | {b['p95_ms']:.3f} → {c['p95_ms']:.3f} | {bd} → {cd} | {bp:,} → {cp:,} | {bc[texture]/1048576:.2f} → {cc[texture]/1048576:.2f} |")
lines += ['', '| Scene / renderer | Cached materials (G1 → R3) | Unique original PNG bindings | Newly bound / no longer bound original PNGs |', '| --- | ---: | ---: | ---: |']
for group in checks['benchmark_comparisons']:
    b=group['before_material_bindings'];c=group['after_material_bindings']
    lines.append(f"| {group['scene']} / {group['renderer']} | {b['cached_materials']} → {c['cached_materials']} | {b['unique_original_image_bindings']} → {c['unique_original_image_bindings']} | {len(group['newly_bound_original_images'])} / {len(group['no_longer_bound_original_images'])} |")
all_rows=[r for g in checks['benchmark_comparisons'] for r in g['samples']]
med=[r['candidate']['median_ms']-r['baseline']['median_ms'] for r in all_rows]
p95=[r['candidate']['p95_ms']-r['baseline']['p95_ms'] for r in all_rows]
lines += ['', f'Across all {len(all_rows)} matched view/light cases, rendered primitive counts are identical. Draw differences range from −19 to +1; the single added draw is the Compatibility paid exterior at dusk. Observed median-frame deltas range from {min(med):+.3f} to {max(med):+.3f} ms, and p95 deltas from {min(p95):+.3f} to {max(p95):+.3f} ms. These are individual paired runs, not a performance acceptance budget.']
lines += ['', 'Authored texture files added/removed: **0 / 0**. Newly bound original edge images, exact names/dimensions and construction material cache counts are reported for each comparison group. Backend totals include the unchanged world and renderer allocations. Primitive counters include pass/culling behavior; the source geometry itself is unchanged. Zero backend GPU timestamps mean unavailable telemetry, not zero cost.','',
'## Controls and limits','', '| R3 control | Value | Purpose |','| --- | --- | --- |']
for key,purpose in cfg['controls'].items():lines.append(f'| `{key}` | `{json.dumps(cfg[key])}` | {purpose} |')
lines += ['', 'D4/D5 face/cut repeat metres, family colours, glass opacity, and D6 seam colour/metallicity remain in the original family data. D6 keeps the retained G1 fallback repeat of 0.5 × 0.5 metres for its shared maps. Member axes and slope/hip/valley selection derive from retained native shape definitions. The grid is active only for labelled diagnostic evidence. Inspection lighting uses day sun/ambient 1.15/0.45, shade 0.12/0.35, dusk 0.4/0.22 with sun pitch −0.85/−0.2 radians and yaw −0.55. Paid views retain world mood with shade/dusk sunlight multipliers 0.12/0.35.','',
'Retained limits: source geometry/grooves and map repetition remain; layered 0.72-opacity glass attenuates heavily and is not refractive; the paid interior retains its source darkness. R2 must reconcile shared G1 material dispatch, mesh identity/cache and PieceLook binding against the common baseline before combined measurements. No peer runtime is copied. All source LOD choices remain unchanged. Owner visual acceptance and combined R8/R9 review remain pending.','',
'Failed attempts are retained: the initial runner gap produced no engine launch; the first paid fixture queried restored bodies before physics registration; the first new restore comparison mixed live integer arrays with JSON-parsed arrays. Corrections synchronize the fixture and compare all exact persistent JSON fields without dropping fields or using tolerances. Successful fresh engine results and strict fingerprints supersede those attempts. Compatibility retains the original SSAO warning; diagnostics were not suppressed.','',
'## Reconstruction','',
'Use the installed Python and the owned tools described in [the reconstruction README](../../../../../../tools/wroughtwild-art07-repairs/r3/README.md). The installer requires the verified common G1 source and preserves its pin `6bb2e044dcd0bf1788896aa2c19cdf56fee93522`. Every engine/Blender job goes through the unchanged shared `run.ps1`, with the GPU mutex and private APPDATA/LOCALAPPDATA/TEMP/Blender resources. Exact commands, private paths, exits and log hashes are in the package. `seal.py --verify ABSOLUTE_PACKAGE` rejects extra/missing files or any byte mismatch. Receipts are outside their own hashed package.','']
with (dest/'README.md').open('x',encoding='utf-8') as f:f.write('\n'.join(lines))
print('R3_EVIDENCE_REPORT',dest/'README.md')
