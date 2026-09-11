"""Read-only verification of the published B3 source and current native baseline."""
import hashlib,json,subprocess,sys,struct,zipfile,shutil
from pathlib import Path
DEPOT=Path('C:/Users/Matty/Dev/project-wroughtwild')
REV='4b5d89b376765fbf4d46049aa099e0bb154a82da'
B3=DEPOT/'build/art07/b3/worktree/build/art07/b3/v01/handoff-v02'
ROOT=Path(sys.argv[1]).resolve();ROOT.mkdir(parents=True,exist_ok=True)
def sha(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda:f.read(4*1024*1024),b''):h.update(b)
    return h.hexdigest()
assert sha(B3/'manifest.json')=='b53961b58ddf4720ec51f77adfe1e87860890f4c3d9b68ec3f6de27102b39321'
manifest=json.loads((B3/'manifest.json').read_text())
for rel,row in manifest.items():
    p=(B3/rel).resolve();assert p.is_relative_to(B3) and p.stat().st_size==row['bytes'] and sha(p)==row['sha256'],rel
assert not subprocess.check_output(['git','diff','f00d4b76274ef2a73c3b6f4a275d2bd3ca0f958d',REV,'--','game','sim','data'])
subprocess.run(['git','merge-base','--is-ancestor','2ca4f4e5c06a7016f575f993844cac0913436ca7',REV],check=True)
files={str(B3/'models/b3-master.blend'):sha(B3/'models/b3-master.blend')}
for rel in ['build/grove-art02/rock-source-v01/rock.glb','build/grove-art02/rock-source-v01/rock_cutout.png','build/grove-art02/rock-source-v01/generation.json','docs/art/leyline-studies/2026-09-09/grove-art02/rock-input-v01.png','build/trellis-local/runtime/trellis-cli.exe','build/blender-tool/blender-4.5.9-windows-x64/blender.exe','tools/wroughtwild-trellis/install-manifest.json']:
    p=DEPOT/rel;files[str(p)]=sha(p)
pinned=json.loads((DEPOT/'tools/wroughtwild-trellis/install-manifest.json').read_text())
for w in pinned['weights']:assert sha(DEPOT/'build/trellis-local/models'/w['name'])==w['sha256']
raw=(DEPOT/'build/grove-art02/rock-source-v01/rock.glb').read_bytes();n=struct.unpack_from('<I',raw,12)[0]
report={'base':REV,'b3_package':str(B3),'b3_manifest_sha256':sha(B3/'manifest.json'),'b3_files_verified':len(manifest),'files':files,'models_verified':len(pinned['weights']),'model_revision':pinned['model_revision'],'raw_metadata':json.loads(raw[20:20+n])['asset'],'generation':json.loads((DEPOT/'build/grove-art02/rock-source-v01/generation.json').read_text()),'new_generation':False,'native_reuse':'B3 DLL; exact game/sim/data Git diff is empty to current base'}
native=ROOT/'baseline'
if not native.exists():
    native.mkdir();archive=ROOT/'baseline.zip'
    subprocess.run(['git','archive','--format=zip','--output='+str(archive),REV,'game','data'],check=True)
    with zipfile.ZipFile(archive) as z:z.extractall(native)
    dll=B3/'native/game/bin/libwroughtwild_sim.windows.x86_64.dll'
    assert sha(dll)=='6d8094fc95c0854f9100b161806a11d9fa3a67bb4f870080976bcd8d2e8f2279'
    shutil.copy2(dll,native/'game/bin'/dll.name)
(ROOT/'prerequisites.json').write_text(json.dumps(report,indent=2)+'\n')
print('C5_PREREQUISITES_OK',len(manifest))
