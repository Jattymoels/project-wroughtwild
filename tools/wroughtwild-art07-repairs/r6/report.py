"""Write the review summary from verified completed jobs, without forecast passes."""
import json
from stage import ROOT, OUT, TOOLS, write

dest = ROOT / 'docs/art/leyline-studies/2026-09-14/art07-repairs/r6'
evidence = json.loads((dest / 'evidence.json').read_text(encoding='utf-8'))
cfg = json.loads((TOOLS / 'surface.json').read_text(encoding='utf-8'))
lines = ['# ART-07R6 faceted ore surface', '',
    'Status: candidate ready for integration review. Owner visual acceptance: pending. Ordinary-world rollout: outside scope.', '',
    'C5 now supplies ore-specific material detail on the existing native faceted ribbon. Full/partial stock, native heat/cracking, excavation and exhaustion control its appearance. The raised fallback models remain unchanged. This is a bounded surface treatment; raised silhouettes and physically recessed altered scars need a separate terrain/body decision. See [measured source options](source-options.md).', '',
    'The runtime/data/native revision remains `6bb2e044dcd0bf1788896aa2c19cdf56fee93522`. All 4,787 original runtime entries were rehashed: 4,785 are unchanged, with changes confined to copied `game/c5/native_resource.gd` and `game/g1/art.gd`. New files live under copied `game/r6`. Original C5 maps, exports, normal scripts, data, legal construction combinations and paid saves retain their bytes.', '',
    '## Native and visual evidence', '',
    '| Renderer | Surface/work checks | Fresh-process partial restore | Failures |',
    '| --- | ---: | ---: | ---: |']
for renderer, row in evidence['surfaces'].items():
    restart = json.loads((OUT / 'runs/surface-v05' / ('surface-' + renderer + '-restart') / 'report.json').read_text())
    lines.append(f"| {renderer} | {row['checks']:,} | {restart['checks']:,} | {row['failures'] + restart['failures']} |")
lines += ['', 'Each renderer covers five genuine LF3 seed-77 ore sites, including a native slope/chunk edge and cave-floor copper/tin. Every candidate expanded vertex, picking triangle, transform, collision layer and mask equals its native baseline. Every inspected retained vertex has physical terrain support at the original 18 mm lift, within 0.002 m tolerance. Native excavation changes the ribbon; restoring that voxel reproduces the original geometry exactly.', '',
    'Maximum measured support error and visible height range are retained per site in [evidence.json](evidence.json). All five sites start at 144 triangles; excavation adds no candidate triangles. Native work pays exactly 8 iron, 8 copper, 6 tin, 6 ember-iron and 6 silver. Full/partial/exhausted and excavation images are separate from the authored C5 fallback fixture.', '',
    'The original C5 assertion expressions remain in their original order: 37 assertion-bearing source lines, with only private output/checkpoint paths and additive still captures. Each renderer passes 178 flow checks, 66 partial-restart checks and 52 exhausted-restart checks. This is harness-paced native work, not a claim of continuous human campaign completion.', '',
    '| Full G1 ownership probe | Exact entire snapshot equality | Resource records | Geography SHA-256 |',
    '| --- | --- | ---: | --- |']
for row in evidence['full_probe_comparison']:
    lines.append(f"| {row['renderer']} | {row['entire_snapshot_equal']} | {row['resources']} | `{row['geography_sha256']}` |")
lines += ['', 'The comparison includes every saved field, including native simulation, paid blocks/stations, resource records, leylines, contraptions and player/terrain state. It is separate from the small surface inspection fixture.', '',
    '![Actual Forward+ faceted iron at player height](iron_vein-full-player-forward.png)', '',
    '![Actual Compatibility partial iron, close detail](iron_vein-partial-close-compatibility.png)', '',
    '![Actual native controller traversal](native-walk.gif)', '',
    'Motion uses the unchanged player controller and real input/physics, moving past the partial iron work side. The GIF is illustrative 12 fps playback of 30 captured frames; physics also advances during capture, so playback is not a real-time clock. All stills are unmodified engine captures. Exact source paths, dimensions and hashes are in evidence.json; the seal includes all five ores, both camera distances, both renderers and restart images.', '',
    '## Measured cost', '',
    'Actual device: RTX 5090, NVIDIA 591.86, Ryzen 9 9950X3D (16 cores/32 threads), 33,446,744,064 bytes RAM, Windows 11 Home. Surface benchmark settings: 1280 × 720, 4× MSAA, VSync off. Each paired native/art scene samples 240 frame waits after 60 warmup frames, after generation and outside imports/captures. Timings are observed frame-wait wall time, not isolated GPU timestamps. The guard records no competing art/game/compiler process during these samples.', '',
    '| Renderer / ore | Native p50 / p95 / worst ms | R6 p50 / p95 / worst ms | Draws native → R6 | Texture bytes native → R6 |',
    '| --- | --- | --- | --- | --- |']
for row in evidence['costs']:
    old, new = row['baseline'], row['candidate']
    values = lambda v: ' / '.join(f"{v[key]:.3f}" for key in ['median_ms', 'p95_ms', 'worst_ms'])
    lines.append(f"| {row['renderer']} / {row['kind']} | {values(old)} | {values(new)} | {int(old['draw_calls'])} → {int(new['draw_calls'])} | {int(old['texture_bytes']):,} → {int(new['texture_bytes']):,} |")
lines += ['', 'The surface adds one shared 512 × 1280 RGBA field atlas (2,621,440 uncompressed bytes), one material per visible ore and no mesh/collider or draw surface. Texture totals also include the shared original C5 albedo/ORM loaded by this material. Current-machine results do not establish minimum-hardware acceptance or a population-wide loading budget; R2/R8 handle combined loading/integration.', '',
    '## Source, controls and reproduction', '',
    'Selected source: C5 kit-v08 / v07 geometry. Original C5 seal: `7b5f6338140c9d0500586fc55991b69e853e002ebc258641488728992e282494`. Common G1 seal: `fd5c592ef52185cc7d0737840e41af09dbb5bcea36b719539931e156f42865cd`. The atlas projects original top-surface mineral/scar fields from five full cold/cracked models; ten rows include duplicate iron cold data. Atlas SHA-256: `213d88f508dc2f3d5313d78c8c27286fea009f0537f5b44124956f0df6025dbf`.', '',
    'The selected changed master is `evidence/sources/r6-surface-master-v03.blend` inside the seal. Blender 4.5.9 reopened it in a separate guarded process, verified all 153 original mesh/pose signatures and seven packed images, and retained the editable controls. The original master and failed first packed copy are retained separately; the failed copy is not the selected master. Original C5 runtime LOD0 remains selected for fallback, with all 90 original stock/crack/LOD exports preserved.', '',
    '| Presentation control | Value | Purpose |', '| --- | --- | --- |']
for key, value in cfg['shader'].items():
    lines.append(f"| `{key}` | {value} | {cfg['purposes'][key]} |")
lines += ['', 'Additional shader-resource finish values and atlas clamps are enumerated in [the tools README](../../../../../../tools/wroughtwild-art07-repairs/r6/README.md). Native dimensions, source colours, roughness, metallic response, units and heat/work rules remain inherited. No gameplay tuning is introduced.', '',
    'The tools README documents reconstruction. Exact launch arguments, private user directories, elapsed time, exit code and log hash are in evidence.json and each run’s `.log.json`. All engine/Blender jobs go through unchanged `tools/wroughtwild-art07-repairs/run.ps1`, optionally using the R6 bounded mutex queue. `user://` resolves under each private job’s APPDATA/ART07G1; persisted proof checkpoints are copied outside user/cache folders into the job output.', '',
    'Successful final groups: `surface-v05`, `c5-v03`, `probe-v04`, `benchmark-v01`, `reopen-v03`. Earlier successful smoke/C5/surface-v04 runs and failed or deferred attempts are retained as historical evidence, not counted as fresh final passes. Surface-v05 retains native back-face culling. The surface-v01 indexed/expanded-face and boundary fixture issue, surface-v02 cave-site selection failure, surface-v03 native edge support-ray failure, probe-v02 scene hierarchy failure, probe-v03 live mouse camera drift, and first master reopen orphan-atlas failure remain visible in the evidence. The final read-only probe disables player mouse input and adds an exact player-pose assertion without changing any original assertion. The surface fixture retains strict physical support assertions and selects native interior cave sites; it is not an exhaustive all-generated-site support survey.', '',
    'R8 must merge the bounded C5 surface branch with R2 loading/resource reuse, and preserve independent R1/R7 dispatch entries. Do not integrate by copying overlapping files in last-writer order. The receipt records the exact candidate seal and checked commits. The worker does not integrate or push main.', '']
write(dest / 'README.md', '\n'.join(lines))
print('R6_REPORT written from verified completed evidence')
