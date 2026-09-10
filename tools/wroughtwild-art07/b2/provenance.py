"""Exact inspected source/tool metadata; no asset mutation."""
import sys,json,hashlib,struct,subprocess
from pathlib import Path
depot,root,out=[Path(p).resolve() for p in sys.argv[1:]];wt=Path(__file__).resolve().parents[3]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
manifest=json.loads((depot/'tools/wroughtwild-trellis/install-manifest.json').read_text())
weights=[]
for row in manifest['weights']:
    p=depot/'build/trellis-local/models'/row['name'];actual=sha(p);assert actual==row['sha256'];weights.append({'file':str(p),'sha256':actual,'bytes':p.stat().st_size})
raw=root/'v02/shrub-raw/source.glb';b=raw.read_bytes();n=struct.unpack_from('<I',b,12)[0];doc=json.loads(b[20:20+n])
files=[raw,root/'v02/shrub-raw/source_cutout.png',wt/'docs/art/leyline-studies/2026-09-09/art07/b2/shrub-input-v01.png',depot/'docs/art/concepts/environment/2026-09-09-frontier/02-habitat-kits.png',depot/'docs/art/leyline-studies/2026-09-09/grove-art02/forest-floor.png',depot/'build/grove-art02/emberroot-handoff/review/deadfall.glb',depot/'build/trellis-local/runtime/trellis-cli.exe',depot/'build/blender-tool/blender-4.5.9-windows-x64/blender.exe',Path('C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe')]
result={'base_commit':'f00d4b76274ef2a73c3b6f4a275d2bd3ca0f958d','worktree':str(wt),'branch':'codex/art07-b2','generator_asset_metadata':doc['asset'],'installed_manifest':manifest,'verified_weights':weights,'files':[{'path':str(p),'bytes':p.stat().st_size,'sha256':sha(p)} for p in files],'raw_source_triangles':288638,'raw_source_uv_limit':'Five uncharted faces retained with point-collapsed UVs by generator; original immutable.','generation':json.loads((root/'v02/shrub-raw/generation.log.job.json').read_text()),'scope':'No other ART07 dependencies consumed. Approved ART02 source is read-only; current native/game regression pinned separately.'}
out.write_text(json.dumps(result,indent=2));print('B2_PROVENANCE_OK')
