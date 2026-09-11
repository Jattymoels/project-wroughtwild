"""Verify installed tools/model bytes; no installs or downloads."""
import json,sys,subprocess
from pathlib import Path
from prerequisites import DEPOT,sha
out=Path(sys.argv[1]);assert not out.exists()
m=json.loads((DEPOT/'tools/wroughtwild-trellis/install-manifest.json').read_text())
for w in m['weights']:
    p=DEPOT/'build/trellis-local/models'/w['name']
    assert p.stat().st_size==w['bytes'] and sha(p)==w['sha256'],p
paths={'trellis':DEPOT/'build/trellis-local/runtime/trellis-cli.exe','blender':DEPOT/'build/blender-tool/blender-4.5.9-windows-x64/blender.exe','godot':Path('C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'),'input':Path('docs/art/leyline-studies/2026-09-09/art07/c4/ash-input-v01.png'),'prompt':Path(__file__).parent/'ash-prompt.txt'}
r={'base':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'model_manifest':m,'tools':{k:{'path':str(p.resolve()),'sha256':sha(p),'bytes':p.stat().st_size} for k,p in paths.items()}}
assert r['tools']['trellis']['sha256']=='e3d075612388a42fcb9bea73377feac4149e3a463cff2d2e11b24975e85d427d'
out.write_text(json.dumps(r,indent=2)+'\n');print('C4_PROVENANCE_OK',len(m['weights']))
