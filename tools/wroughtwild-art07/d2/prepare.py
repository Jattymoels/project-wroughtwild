"""D2 frozen current-native review and verified read-only D1 input."""
import argparse, hashlib, json, subprocess, zipfile
from pathlib import Path

BASE='0f35e87c6a23e3197bec968fa4443c8e134317b3'
IDS=['codex_roof_slope','codex_roof_hip','codex_roof_valley','door','roof_wedge','girder','arch']
D1='build/art07/d1/worktree/build/art07/d1/v02/core-lattice-handoff-v01'
D1_HASH='a3e92f9692e05eae547290cd6520242f91dfbda31d9236eb6d12842f0453b85a'
def sha(p):
    with p.open('rb') as f: return hashlib.file_digest(f,'sha256').hexdigest()
def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--depot',type=Path,required=True); ap.add_argument('--output',type=Path,required=True); a=ap.parse_args()
    worker=Path(__file__).resolve().parents[3]; out=a.output.resolve(); depot=a.depot.resolve()
    assert out.is_relative_to(worker/'build/art07/d2') and not out.exists()
    package=depot/D1; manifest=package/'manifest.json'; assert sha(manifest)==D1_HASH
    entries=json.loads(manifest.read_text())['files']
    for rel,e in entries.items():
        p=package/rel; assert p.resolve().is_relative_to(package) and p.stat().st_size==e['bytes'] and sha(p)==e['sha256'],rel
    refs=['data/tuning/construction.json','game/scripts/piece_mesh.gd','game/scripts/placed_block.gd','game/scripts/piece_look.gd','game/scripts/save_manager.gd','sim/include/wroughtwild/lattice.h','docs/art/concepts/environment/2026-09-09-frontier/03-building-family.png','docs/prototype/art07-production/receipts/d1.md']
    assert all((depot/r).is_file() for r in refs), 'Required source missing'
    binaries=[depot/'build/blender-tool/blender-4.5.9-windows-x64/blender.exe',Path('C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe')]
    out.mkdir(parents=True)
    provenance={'base_revision':BASE,'prerequisite':{'path':str(package),'manifest_sha256':D1_HASH,'verified_files':len(entries),'published_main_commit':'58d3223'},'inputs':{str(depot/r):sha(depot/r) for r in refs},'binaries':{str(p):sha(p) for p in binaries},'process':'Direct dimensioned Blender modelling; imagegen/TRELLIS and model weights not consumed.'}
    (out/'prerequisites.json').write_text(json.dumps(provenance,indent=2)+'\n')
    subprocess.run(['git','-C',str(worker),'archive','--format=zip','--output='+str(out/'frozen.zip'),BASE,'game','data','sim','tests/sim'],check=True)
    with zipfile.ZipFile(out/'frozen.zip') as z: z.extractall(out/'snapshot')
    cat=json.loads((worker/'docs/art/concepts/environment/2026-09-09-frontier/asset-catalogue.json').read_text())
    entries={s['id']:s for s in cat['shapes'] if s['id'] in IDS}
    c=json.loads((out/'snapshot/data/tuning/construction.json').read_text())
    for s in c['shapes']:
        if s['id'] in IDS:
            assert all(s[k]==entries[s['id']][k] for k in ['size_m','material_cost','element'])
            assert s.get('form','box')==entries[s['id']]['form']
    (out/'assigned.json').write_text(json.dumps([entries[k] for k in IDS],indent=2)+'\n')
    print('D2_PREREQUISITES_OK',provenance['prerequisite'],flush=True)
if __name__=='__main__': main()
