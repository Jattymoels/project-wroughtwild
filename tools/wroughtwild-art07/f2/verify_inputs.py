"""Read-only predecessor verification; immutable input receipt for F2."""
import hashlib, json, sys, subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
DEPOT = Path('C:/Users/Matty/Dev/project-wroughtwild')
BASE = '4b5d89b376765fbf4d46049aa099e0bb154a82da'
PACKAGES = {
    'd4': (Path('C:/Users/Matty/Dev/project-wroughtwild-art07-d4/build/art07/d4/h04'), 'aaa0316f108cdb1de0ed27cc3a40fac7a07574497c14486e88b18fa73dfbda59'),
    'd6': (DEPOT/'build/art07/d6/worktree/build/art07/d6/v04/handoff', '8d82eb36775959f41905e579e36d737caa4a8512ed504d679ab49652301338a7'),
}
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    out=Path(sys.argv[1]).resolve(); assert out.is_relative_to(ROOT/'build/art07/f2')
    report={'base':BASE,'packages':{},'inputs':[]}
    for ident,(path,expected) in PACKAGES.items():
        manifest=path/'manifest.json'; assert sha(manifest)==expected,manifest
        data=json.loads(manifest.read_text(encoding='utf-8-sig'))
        for e in data['files']:
            p=path/e['path']; assert sha(p)==e['sha256'],p
            assert p.stat().st_size==e['bytes'],p
        receipt='docs/prototype/art07-production/receipts/'+ident+'.md'
        subprocess.run(['git','cat-file','-e',BASE+':'+receipt],cwd=ROOT,check=True)
        report['packages'][ident]={'path':str(path),'manifest_sha256':expected,'verified_files':len(data['files']),'published_receipt_sha256':sha(ROOT/receipt)}
    names=['docs/art/concepts/environment/2026-09-09-frontier/05-useful-fixtures.png','game/scripts/strange_resource_art.gd','game/scripts/contraption_site.gd','game/scripts/resource_node.gd','game/art/contraption_look.gd','data/tuning/contraptions.json','data/tuning/crafting.json','game/assets/authored/strange_thrumroot_core.glb','game/assets/authored/strange_thrumroot_shell.glb','game/assets/authored/deadfall.glb','tools/wroughtwild-trellis/install-manifest.json','build/trellis-local/runtime/trellis-cli.exe','build/blender-tool/blender-4.5.9-windows-x64/blender.exe']
    for name in names:
        p=DEPOT/name; report['inputs'].append({'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size})
    out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(report,indent=2)+'\n')
    print('F2_INPUTS_OK', {k:v['verified_files'] for k,v in report['packages'].items()})
if __name__=='__main__': main()
