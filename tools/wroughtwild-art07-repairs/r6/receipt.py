"""Write the final receipt only after a sealed candidate and checked source commit."""
import argparse
import json
import subprocess
from stage import ROOT, OUT, sha, write

parser=argparse.ArgumentParser()
parser.add_argument('implementation')
args=parser.parse_args()
assert len(args.implementation)==40
subprocess.run(['git','-C',str(ROOT),'cat-file','-e',args.implementation+'^{commit}'],check=True)
package=OUT/'handoff-v01'
manifest=json.loads((package/'manifest.json').read_text(encoding='utf-8'))['files']
info={'path':str(package),'manifest_sha256':sha(package/'manifest.json'),'files':len(manifest),'bytes':sum(row['bytes'] for row in manifest.values())}
evidence=json.loads((package/'evidence/review/evidence.json').read_text(encoding='utf-8'))
assert len(evidence['checked_jobs'])==21 and all(row['exit_code']==0 for row in evidence['checked_jobs'])
changes=json.loads((package/'changes.json').read_text(encoding='utf-8'))
preserved=json.loads((package/'evidence/verification/preservation.json').read_text(encoding='utf-8'))
reconstruction=json.loads((OUT/'verification/reconstruction.json').read_text(encoding='utf-8'))
assert reconstruction['runtime_bytes_equal']
limits=evidence['limits']+[
    'Physically recessed altered scars and the raised C5 silhouette are unapproved on the retained thin ribbon; they require a terrain seating/excavation/body decision.',
    'Five generated inspection sites are not an exhaustive all-site support survey. Earlier native edge support-ray failure is retained with the other failed fixture attempts.',
    'R8 must merge C5 changes with R2 resource reuse and retain independent R1/R7 resource dispatch changes. No parent repair runtime delta was consumed.'
]
result={
    'id':'r6','status':'ready_for_integration','source_commits':[args.implementation],
    'runtime_base':changes['runtime_base'],'parent_candidates':[],
    'delta_base':'Common G1 seal '+changes['delta_base_manifest'],
    'package':info,'changes':'changes.json',
    'findings':{'G2-V04':'Candidate material-only coverage for all five native faceted ore families, with exact native surface/body/stock and retained C5 fallback. Independent owner visual review pending.'},
    'checks':evidence['checked_jobs'], 'preservation':preserved,
    'master':changes['changed_source_masters'], 'reconstruction':reconstruction,
    'remaining_limits':limits,'owner_visual_acceptance':'pending','ordinary_world_rollout':'outside scope'
}
directory=ROOT/'docs/prototype/art07-repairs/2026-09-14/receipts'
write(directory/'r6.json',json.dumps(result,indent=2))
python='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
base='D:/project-wroughtwild-art07-g2/build/art07/g2/v01/sealed'
lines=['# ART-07R6 — faceted ore visual coverage','','Status: ready_for_integration. Owner visual acceptance: pending. Ordinary-world rollout: outside scope.','',
    '## Source and scope','',
    f'Worktree `D:/project-wroughtwild-art07-r6`, branch `codex/art07-r6`. Inspected published main: `{preserved["inspected_published_main"]}`. Prepared checkout: `{preserved["prepared_checkout_commit"]}`. Runtime/data/native pin: `{changes["runtime_base"]}`. The four wave-one publications and all consumed package payloads were verified before implementation; no parent runtime delta was consumed. Exact manifests and full verification output are sealed under `evidence/verification`.','',
    'Original G1 source: `D:/project-wroughtwild-art07-g2/build/art07/g2/v01/sealed`, manifest `fd5c592ef52185cc7d0737840e41af09dbb5bcea36b719539931e156f42865cd`. Original C5 source: `C:/Users/Matty/Dev/project-wroughtwild/build/art07/c5/worktree/build/art07/c5/v01/handoff-v01`, manifest `7b5f6338140c9d0500586fc55991b69e853e002ebc258641488728992e282494`. C5 published source/receipt commits: `b4bd986baa14e48f7ad871d0df204658f8429e40`, `0e16ed03167ac3002da11fcde591555eac5a2ef3`.','',
    'Owned Git paths are the R6 tools directory, R6 review directory and these two receipt files. Only copied `game/c5/native_resource.gd` (`_apply_visual`, `refresh_surface`, `sync_state`) and copied `game/g1/art.gd` (`resource` ember visual mapping) change existing runtime files. New material/map/controls and isolated fixtures live under copied `game/r6`. Changes.json records every before/after hash, function, setting and overlap. All 4,785 other original runtime entries retain exact bytes, including normal source, native DLL, construction data, maps and paid saves.','',
    '## Result and checks','',
    'C5 now shades the native three-metre ribbon without adding vertices, colliders, displacement or a raised slab. Existing terrain gaps, excavation and targeting stay authoritative. Partial mineral coverage follows native remaining/full units; worked host remains visible over the complete picking ribbon. Exhaustion hides the material before native retirement scaling; native collision retirement and deletion remain inherited. Stable generated resource IDs remain unchanged.','',
    'Both renderers passed 4,528 generated-site surface/work checks and 2,234 fresh-process partial-restore checks. Candidate mesh/body/pose values match baseline exactly. All five ore families pay exactly their original finite stock; measured support error is at most 0.000158 m from the native 0.018 m lift. The unchanged C5 assertion expressions pass 178 flow, 66 partial-restart and 52 final-restart checks per renderer. Full art-on/off paid snapshots and geography compare exactly.','',
    'Twenty-one final guarded jobs passed: surface-v05 (5), c5-v03 (6), probe-v04 (4), benchmark-v01 (4), reopen-v03 (2). The final surface pass retains native back-face culling; the earlier surface-v04 also passed but is not the final material. Probe-v04 disables live player mouse input and adds a full player-pose assertion after probe-v03 exposed camera drift; it preserves every original assertion. Each .log.json contains exact arguments, private APPDATA/LOCALAPPDATA/TEMP paths, PIDs, exit code, timing and log hash. User saves resolve under that job’s APPDATA/ART07G1; proof checkpoints are retained outside omitted user/cache folders. Failed fixture/master attempts and earlier smoke results remain visible and are not counted as final passes. Expected baseline Compatibility SSAO warnings are retained; no fatal diagnostic is accepted.','',
    'Actual device: RTX 5090/NVIDIA 591.86, Ryzen 9 9950X3D, 33,446,744,064 bytes RAM, Windows 11 Home. Benchmarks use 1280×720, 4× MSAA, VSync off, 240 frame-wait samples after 60 warmups per ore/mode/renderer; 4,800 measured samples total. Imports, generation and captures are outside the sampled intervals, with no competing guarded art/game/compiler process recorded. Per-scene p50/p95/worst, draw counts, primitives and texture memory are in the review/evidence.json. These are current-machine frame-wait costs, not minimum-hardware approval.','',
    'The review includes unmodified native faceted and authored fallback stills at player height and close range, plus actual controller traversal frames. The GIF is illustrative 12 fps playback, not a real-time recording. The selected changed master `evidence/sources/r6-surface-master-v03.blend` reopens in Blender 4.5.9 with 153 unchanged mesh/pose signatures and seven packed images. Its SHA-256 is `240a7684cbd2c198ae4e6aec91549c254104de221af7108e4c60a9117d739d13`. Original source masters/maps and all 90 fallback exports remain retained.','',
    'All new presentation values and their purposes are documented in the tools README and surface.json: grain 1.7 repeats/m, shading normal detail 0.006 m, stock transition 0.025 m, spent-host tint 0.6, native heat pulse 3.5 s, plus the shader finish/atlas controls. No gameplay parameter is added.','',
    '## Candidate and limits','',f'Package: `{info["path"]}`',f'Manifest SHA-256: `{info["manifest_sha256"]}`',f'Exact payload: {info["files"]:,} files, {info["bytes"]:,} bytes (manifest excluded). Receipt files are outside their own seal.','',
    '```powershell',f"$r6Python = '{python}'",f"& $r6Python tools/wroughtwild-art07-repairs/r6/package.py verify '{package.as_posix()}'",f"& $r6Python tools/wroughtwild-art07-repairs/r6/apply.py --baseline '{base}' --package '{package.as_posix()}' --out 'D:/project-wroughtwild-art07-r6/build/art07-repairs/r6/reconstruct-fresh'",'```','',
    'Run these from the assigned worktree. Reconstruction refuses an existing destination and verifies every baseline and delta hash. The recorded reconstruction run proved exact runtime byte equality with the seal. To reproduce engine evidence, use the job generator with fresh versions and launch its specifications through the unchanged shared runner via R6 launch.ps1; never rerun into an existing log directory.','']
lines += ['- '+limit for limit in limits]
lines += ['', '## Commits and publication','',f'Checked implementation commit: `{args.implementation}`. Resolve the subsequent receipt commit from Git history. Main integration and push were not performed by this worker. R8/publisher owns integration and publication.','',
    'Detailed visual review and cost tables: `docs/art/leyline-studies/2026-09-14/art07-repairs/r6/README.md`. Complete command/log provenance: sibling r6.json and the sealed evidence.','']
write(directory/'r6.md','\n'.join(lines))
print('R6_RECEIPT',info['manifest_sha256'],args.implementation)
