"""Freeze the inspected revision and verify depot prerequisites without modifying them."""
import argparse, hashlib, json, subprocess, zipfile
from pathlib import Path

IDS = ['cube','wall_panel','pillar','beam','floor_slab','stairs','codex_corner','codex_corner_floor','foundation','dry_wall']
BASE = '56ce6bbe343012205690cf669491372958b80662'
def sha(p):
    with p.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()
def write(p, obj):
    p.write_text(json.dumps(obj, indent=2)+'\n', encoding='utf-8')
def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--depot', type=Path, required=True); ap.add_argument('--output', type=Path, required=True)
    a=ap.parse_args(); depot=a.depot.resolve(); out=a.output.resolve()
    worker=Path(__file__).resolve().parents[3]
    assert out.is_relative_to(worker/'build/art07/d1') and not (out/'snapshot').exists()
    out.mkdir(parents=True, exist_ok=True)
    paths=['build/grove-art02/emberroot-handoff','build/boar-art01/boar-handoff','build/roster-art06c/lifeline-handoff','build/workshop-art04/red-handoff','build/workshop-white/white-handoff','build/workshop-blue/blue-handoff','build/workshop-green/green-handoff']
    packages=[]
    for rel in paths:
        p=depot/rel; m=p/'manifest.json'; data=json.loads(m.read_text(encoding='utf-8-sig'))
        entries=data.get('files', data)
        if isinstance(entries,dict): entries=[dict(path=k,**v) for k,v in entries.items() if isinstance(v,dict) and 'sha256' in v]
        # Verify the immutable editable sources, not mutable engine import caches.
        selected=[e for e in entries if str(e.get('path','')).endswith(('.blend','.glb')) and any(s in e['path'] for s in ['editable/','sources/','source'])]
        assert selected, (p,'No source entries')
        for e in selected:
            f=p/e['path']; assert sha(f)==e['sha256'].lower(), str(f)
        packages.append({'path':str(p),'manifest_sha256':sha(m),'verified_sources':selected,'consumed_geometry':False})
    install=depot/'tools/wroughtwild-trellis/install-manifest.json'; manifest=json.loads(install.read_text())
    for e in manifest['weights']:
        f=depot/'build/trellis-local/models'/e['name']; assert f.stat().st_size==e['bytes'] and sha(f)==e['sha256'], str(f)
    binaries=[depot/'build/trellis-local/runtime/trellis-cli.exe',depot/'build/blender-tool/blender-4.5.9-windows-x64/blender.exe',Path('C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe')]
    provenance={'base_revision':BASE,'packages':packages,'install_manifest_sha256':sha(install),'trellis':manifest,'binaries':{str(p):sha(p) for p in binaries},'generation':'Not used: all ten D1 modules require direct dimensioned modelling.'}
    refs=['data/tuning/construction.json','game/scripts/piece_mesh.gd','game/scripts/piece_look.gd','game/art/building_look.gd','docs/art/concepts/environment/2026-09-09-frontier/03-building-family.png','tools/wroughtwild-blender/scripts/build_study.py','tools/wroughtwild-workshop/build-native.ps1']
    provenance['inputs']={p:sha(depot/p) for p in refs}
    write(out/'prerequisites.json',provenance)
    archive=out/'frozen.zip'
    subprocess.run(['git','-c','safe.directory='+depot.as_posix(),'-C',str(depot),'archive','--format=zip','--output='+str(archive),BASE,'game','data','sim','tests/sim'],check=True)
    with zipfile.ZipFile(archive) as z: z.extractall(out/'snapshot')
    c=json.loads((out/'snapshot/data/tuning/construction.json').read_text())
    catalogue=json.loads((worker/'docs/art/concepts/environment/2026-09-09-frontier/asset-catalogue.json').read_text())
    entries={s['id']:s for s in catalogue['shapes'] if s['id'] in IDS}
    for s in c['shapes']:
        if s['id'] in IDS:
            assert s['size_m']==entries[s['id']]['size_m'] and s['material_cost']==entries[s['id']]['material_cost']
    write(out/'assigned.json',[entries[k] for k in IDS])
    print('D1_PREREQUISITES_OK',len(packages),'packages; pinned weights verified; frozen',BASE,flush=True)
if __name__=='__main__': main()
