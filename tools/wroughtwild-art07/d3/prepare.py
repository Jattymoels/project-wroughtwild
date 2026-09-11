"""Verify the published D1 dependency and freeze one current native/game revision."""
import argparse, hashlib, json, subprocess, zipfile
from pathlib import Path

BASE = '0f35e87c6a23e3197bec968fa4443c8e134317b3'
IDS = ['half_cube','half_wall','half_pillar','half_beam','half_slab','light_panel','glazed_window']
D1 = 'build/art07/d1/worktree/build/art07/d1/v02/core-lattice-handoff-v01'
D1_HASH = 'a3e92f9692e05eae547290cd6520242f91dfbda31d9236eb6d12842f0453b85a'
def sha(p):
    with p.open('rb') as f: return hashlib.file_digest(f,'sha256').hexdigest()
def write(p,x): p.write_text(json.dumps(x,indent=2)+'\n')

ap=argparse.ArgumentParser(); ap.add_argument('--depot',type=Path,required=True); ap.add_argument('--output',type=Path,required=True)
a=ap.parse_args(); depot=a.depot.resolve(); out=a.output.resolve(); worker=Path(__file__).resolve().parents[3]
assert out.is_relative_to(worker/'build/art07/d3') and not (out/'snapshot').exists()
out.mkdir(exist_ok=True,parents=True)
package=depot/D1; manifest=package/'manifest.json'
assert sha(manifest)==D1_HASH
entries=json.loads(manifest.read_text())['files']
for rel,e in entries.items():
    p=package/rel; assert p.resolve().is_relative_to(package)
    assert p.stat().st_size==e['bytes'] and sha(p)==e['sha256'],str(p)
subprocess.run(['git','merge-base','--is-ancestor','58d3223',BASE],cwd=worker,check=True)
refs=['AGENTS.md','data/tuning/construction.json','game/scripts/piece_mesh.gd','game/scripts/piece_look.gd','game/art/material_library.gd','game/art/material_library.tres','game/art/building_look.gd','docs/art/concepts/environment/2026-09-09-frontier/03-building-family.png','docs/prototype/art07-production/receipts/d1.md','tools/wroughtwild-art07/d1/build.py','tools/wroughtwild-art07/d1/reopen.py','tools/wroughtwild-art07/d1/checks.gd','tools/wroughtwild-art07/d1/run-job.ps1']
inputs={str(depot/p):sha(depot/p) for p in refs}
for p in ['build/blender-tool/blender-4.5.9-windows-x64/blender.exe','build/trellis-local/runtime/trellis-cli.exe','tools/wroughtwild-trellis/install-manifest.json']:
    inputs[str(depot/p)]=sha(depot/p)
godot=Path('C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'); inputs[str(godot)]=sha(godot)
write(out/'prerequisites.json',{'base_revision':BASE,'d1_package':str(package),'d1_manifest_sha256':D1_HASH,'verified_package_files':len(entries),'inputs':inputs,'generation':'Direct dimensioned Blender modelling; no imagegen or TRELLIS job needed. Existing pinned runtime inspected, no download.'})
archive=out/'frozen.zip'
subprocess.run(['git','archive','--format=zip','--output='+str(archive),BASE,'game','data','sim','tests/sim'],cwd=worker,check=True)
with zipfile.ZipFile(archive) as z: z.extractall(out/'snapshot')
catalogue=json.loads((worker/'docs/art/concepts/environment/2026-09-09-frontier/asset-catalogue.json').read_text())
assigned=[next(s for s in catalogue['shapes'] if s['id']==k) for k in IDS]
native=json.loads((out/'snapshot/data/tuning/construction.json').read_text())
for e in assigned:
    s=next(s for s in native['shapes'] if s['id']==e['id'])
    assert s['size_m']==e['size_m'] and s['material_cost']==e['material_cost']
write(out/'assigned.json',assigned)
print('D3_PREREQUISITES_OK',len(entries),'D1 files;',sum(len(e['allowed_materials']) for e in assigned),'legal pairs; frozen',BASE)
