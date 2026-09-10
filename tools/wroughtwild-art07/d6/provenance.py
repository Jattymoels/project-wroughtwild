"""Read-only depot/source audit. Organic packages are retained, not D6 inputs."""
import hashlib,json,sys
from pathlib import Path
root=Path(__file__).resolve().parents[3];depot=Path('C:/Users/Matty/Dev/project-wroughtwild')
def record(p):
    with p.open('rb') as f:h=hashlib.file_digest(f,'sha256').hexdigest()
    return {'path':str(p),'bytes':p.stat().st_size,'sha256':h}
manifest=json.loads((depot/'tools/wroughtwild-trellis/install-manifest.json').read_text());rows=[]
for w in manifest['weights']:
    r=record(depot/'build/trellis-local/models'/w['name']);assert r['sha256']==w['sha256'] and r['bytes']==w['bytes'];rows.append(r)
for rel in ['build/trellis-local/runtime/trellis-cli.exe','build/blender-tool/blender-4.5.9-windows-x64/blender.exe','tools/wroughtwild-trellis/install-manifest.json','docs/art/concepts/environment/2026-09-09-frontier/03-building-family.png','docs/art/concepts/environment/2026-09-09-frontier/asset-catalogue.json','data/tuning/construction.json','data/tuning/crafting.json','data/tuning/worldgen.json']:
    rows.append(record(depot/rel))
rows.append(record(Path('C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe')))
packages=[]
for rel in ['grove-art02/emberroot-handoff','boar-art01/boar-handoff','roster-art06c/lifeline-handoff','workshop-art04/red-handoff','workshop-white/white-handoff','workshop-blue/blue-handoff','workshop-green/green-handoff']:
    p=depot/'build'/rel;assert p.is_dir(),p
    manifests=list(p.glob('*manifest*.json'));assert manifests,p
    for m in manifests:
        entry=record(m);data=json.loads(m.read_text(encoding='utf-8-sig'));entries=data.get('files',data)
        if isinstance(entries,dict):entries=[dict(path=k,**v) for k,v in entries.items() if isinstance(v,dict) and 'sha256' in v]
        selected=[e for e in entries if str(e.get('path','')).endswith(('.blend','.glb')) and any(s in e['path'] for s in ['editable/','sources/','source'])]
        assert selected,(m,'no immutable sources')
        entry['verified_sources']=[]
        for e in selected:
            r=record(p/e['path']);assert r['sha256']==e['sha256'].lower(),r['path'];entry['verified_sources'].append(r)
        packages.append(entry)
out=Path(sys.argv[1]);out.write_text(json.dumps({'model_runtime':manifest,'verified_files':rows,'retained_package_manifests':packages,'consumed_organic_assets':[],'generation':'not applicable: direct lattice/metal authoring; no imagegen or TRELLIS job'},indent=2)+'\n')
print('D6_PROVENANCE_OK',len(rows),len(packages))
