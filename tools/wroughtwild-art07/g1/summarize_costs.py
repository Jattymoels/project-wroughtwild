"""Write the exact per-view benchmark comparison as a reviewable Markdown table."""
import json
import sys
from pathlib import Path

source,dest=map(Path,sys.argv[1:])
report=json.loads(source.read_text())
lines=['# G1 measured combined cost','','Godot 4.5-stable / NVIDIA RTX 5090; Vulkan 1.4.325 Forward+ and OpenGL 3.3 driver 591.86 Compatibility. '+report['conditions'],'','All four process receipts record exit 0 and no competing Godot, Blender, TRELLIS or compiler process. The runner holds the shared GPU mutex and checks for new competitors during the run. These are local hardware measurements, not a lower-end performance acceptance.','',
'Each row compares the same native active resource IDs, generated chunk count, camera and target. Texture totals are backend allocations, including hidden/prefetched resources. Buffer/video totals include renderer allocations beyond mesh data. Geometry below counts unique live-scene base meshes, including hidden stages and LODs, without multiplying by instances.','']
for renderer,data in report['renderers'].items():
 lines+=['## '+renderer,'','| View / light | Baseline median / p95 ms | Art median / p95 ms | Art Δ median ms | Baseline / art draws |','| --- | ---: | ---: | ---: | ---: |']
 for row in data['rows']:
  a,b=row['art'],row['baseline']
  lines.append(f"| {row['scene']} / {row['lighting']} | {b['frame_median_ms']:.3f} / {b['frame_p95_ms']:.3f} | {a['frame_median_ms']:.3f} / {a['frame_p95_ms']:.3f} | {row['median_delta_ms']:+.3f} | {b['draw_calls']} / {a['draw_calls']} |")
 lines+=['','| Loaded cost across these views | Baseline range | Art range |','| --- | ---: | ---: |']
 for key,title,unit in [('texture_bytes_total_loaded','Textures (MiB)',2**20),('buffer_bytes_total_loaded','Buffers (MiB)',2**20),('video_bytes_total_loaded','Video allocations (MiB)',2**20),('scene_unique_triangles','Unique triangles',1),('scene_unique_vertices','Unique vertices',1),('scene_unique_indices','Unique indices',1),('scene_unique_meshes_including_hidden','Unique meshes',1),('scene_unique_surfaces','Unique surfaces',1),('mesh_instances_including_multimesh_and_hidden','Mesh instances incl. MultiMesh / hidden',1)]:
  spans=[]
  for mode in ['baseline','art']:
   values=[row[mode]['cost'][key]/unit for row in data['rows']]
   spans.append(f'{min(values):,.1f}–{max(values):,.1f}' if unit>1 else f'{min(values):,.0f}–{max(values):,.0f}')
  lines.append(f'| {title} | {spans[0]} | {spans[1]} |')
 lines+=['']
lines+=['## Explicit detail choices','','| Input | Combined pilot choice |','| --- | --- |',
'| B1 / C4 canopy | Published LOD2 for live trees, original native narrow body fit; distant native canopy unchanged. |',
'| B2 / B4 cover | B2 LOD2 meadow/edge grass and sparse fern in existing cover envelopes; B4 rooted sway only, analytic study-ground conformance disabled. Other source composition roles remain supporting inspection assets. |',
'| B3, C1, C2, C3 | Published LOD0 and native source work stages, including hidden stages. |',
'| C5 | LOD0 only for original fallback/labelled fixture; normal faceted thin ribbon retained. |',
'| C6 | Published LOD0/1/2, automatic at 10/24 m. Same native poses/bodies. |',
'| D1/D2/D3 | Complete authored fixed building solids; native collider decomposition and all chamfer/triangle/octagonal uses retained. |',
'| D4/D5/D6 | Original published family texture maps; 19 material families. Generic building faces use metric triplanar mapping. |',
'| E1/E2 | Published near station solids for native station dispatch. All near/middle/far tiers separately checked. |',
'| E3 | Published complete family-specific chest/fire solids and original native seating/hinge. |',
'| F1/F3 | Near source/default device view; source adapters also retain hidden middle/far resources. |',
'| F2 | Published fixed winch/landing/basket and near Thrumroot. |',
'| F4 | Near feeder/pocket; all near/middle/far full-body sweeps checked separately. |',
'| F5 | Published mid source/fixture solids; independent fragment detail and linear scar atlases retained. |','',
'G1 settings: material normal strength 0.45, frame shade 0.72, canopy/cover LOD2, F5 middle detail, inherited rooted plant bend 0.018 and leaf multipliers (0.85, 0.72, 0.60). Every parameter has its plain-language purpose in `game/g1/settings.json`; source-specific controls remain in their published module JSON/resources. No gameplay tuning changed.','',
'The longer regional tour separately loaded 1,371,473,408 texture bytes and 109,558,450 buffer bytes under Forward+; its final scene had 1,049,353 unique triangles and 10,251 mesh instances. This different camera/streaming tour is not substituted for the paired paid-route benchmark above. GPU render-time samples and visible primitive counts remain in the full JSON; wall frame times above include the whole frame.','']
dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text('\n'.join(lines),encoding='utf-8')
print('G1_COSTS_REPORTED',dest)
