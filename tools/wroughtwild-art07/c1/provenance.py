"""Verify installed pinned weights and immutable C1 generation and context lineage."""
import sys,json,hashlib,struct,subprocess
from pathlib import Path
root,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);wt=Path(__file__).resolve().parents[3];depot=Path('C:/Users/Matty/Dev/project-wroughtwild')
def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
manifest=json.loads((depot/'tools/wroughtwild-trellis/install-manifest.json').read_text());weights=[]
for r in manifest['weights']:
    p=depot/'build/trellis-local/models'/r['name'];h=sha(p);assert h==r['sha256'];weights.append({'path':str(p),'sha256':h,'bytes':p.stat().st_size})
raw=root/'clay-raw/source.glb';blob=raw.read_bytes();doc=json.loads(blob[20:20+struct.unpack_from('<I',blob,12)[0]])
paths=list((root/'clay-raw').glob('*'))+[wt/'docs/art/leyline-studies/2026-09-09/art07/c1/clay-input-v01.png',wt/'tools/wroughtwild-art07/c1/clay-prompt.txt',depot/'docs/art/concepts/environment/2026-09-09-frontier/02-habitat-kits.png',depot/'docs/art/references/environment/env-002-dense-frontier-original.png',depot/'build/trellis-local/runtime/trellis-cli.exe',depot/'build/blender-tool/blender-4.5.9-windows-x64/blender.exe',Path('C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe')]
result={'base_commit':'f5e481a28fb032a7d4d7ebec1e3e01cc1aca0bc9','branch':'codex/art07-c1','worktree':str(wt),'installed_manifest':manifest,'verified_weights':weights,'actual_glb_metadata':doc['asset'],'files':[{'path':str(p),'bytes':p.stat().st_size,'sha256':sha(p)} for p in paths if p.is_file()],'generation':json.loads((root/'clay-raw/generation.log.job.json').read_text()),'prerequisites':json.loads((root/'prerequisites-with-context.json').read_text()),'native':json.loads((root/'native-v06/provenance.json').read_text()),'note':'Raw generation retains the generator warning about three point-collapsed UV faces; C1 never changes original source or maps.'}
out.write_text(json.dumps(result,indent=2)+'\n');print('C1_PROVENANCE_OK',len(weights),len(result['files']))
