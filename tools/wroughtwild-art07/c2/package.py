"""Assemble this selected, checked C2 handoff in a fresh destination; no caches/saves."""
import sys,json,shutil,hashlib,subprocess,zipfile,io
from pathlib import Path
root,out=[Path(p).resolve() for p in sys.argv[1:]]
assert not out.exists();out.mkdir(parents=True)
recipe=Path(__file__).resolve().parent
selected={'kit':'kit-v05','review':'review-v04','native':'native-v04','media':'media-v03'}
def copy(src,dst):
 dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
def tree(src,dst,exclude=()):
 for p in src.rglob('*'):
  rel=p.relative_to(src)
  if p.is_file() and not any(part in exclude for part in rel.parts) and not p.name.endswith(('.blend1','.pyc')):copy(p,dst/rel)
def digest(p):
 with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
tree(root/selected['kit'],out/'source',('__pycache__',))
tree(root/selected['review'],out/'review',('.godot','evidence'))
tree(recipe,out/'recipe',('__pycache__',))
tree(root/selected['review']/'evidence',out/'evidence/godot')
tree(root/selected['native']/'game/c2/evidence',out/'evidence/native')
tree(root/'blender-v05',out/'evidence/blender')
tree(root/'shellstone-inspection-v01',out/'evidence/raw-shellstone')
tree(root/'source-inspection',out/'evidence/raw-rock')
tree(root/selected['media'],out/'evidence/media')
tree(root/'shellstone-generation-v01',out/'raw/shellstone',('user','local-user','blender-user'))
copy(recipe.parents[2]/'docs/art/leyline-studies/2026-09-09/art07/c2/shellstone-input-v01.png',out/'raw/shellstone/input.png')
# Recreate a clean current archive, then apply only the exact previously checked visual files.
revision='f5e481a28fb032a7d4d7ebec1e3e01cc1aca0bc9'
archive=subprocess.check_output(['git','archive','--format=zip',revision,'game','data'])
with zipfile.ZipFile(io.BytesIO(archive)) as z:z.extractall(out/'native')
copy(root/'current/game/bin/libwroughtwild_sim.windows.x86_64.dll',out/'native/game/bin/libwroughtwild_sim.windows.x86_64.dll')
copy(root/'current/provenance.json',out/'native/provenance.json')
tree(root/selected['native']/'game/c2',out/'native/game/c2',('evidence',))
copy(root/selected['native']/'game/scenes/resource_node.tscn',out/'native/game/scenes/resource_node.tscn')
for name in ['current-checks','adapter-current-checks','capture-v02','motion-v01','native-render-v01','benchmark-v01']:
 tree(root/name,out/'checks'/name,('user','local-user','blender-user'))
for prefix in ['build-v04','finish-v05','audit-v05','blender-v05','shellstone-inspection','inspection','native-v04','current-import','review-v04-import','probe']:
 for p in root.glob(prefix+'*'):
  if p.is_file():copy(p,out/'checks'/p.name)
copy(root/'prerequisites.json',out/'checks/prerequisites.json')
copy(root/'check-summary.json',out/'checks/check-summary.json')
for renderer in ['forward_plus','gl_compatibility']:
 evidence=out/'evidence/godot'/renderer
 assert json.loads((evidence/'checks.json').read_text())['pause_resume']
 assert len(json.loads((evidence/'benchmark.json').read_text())['cases'])==6
 for mode in ['flow','partial-restart','final-restart']:
  check=json.loads((out/'evidence/native'/renderer/('native-'+mode+'.json')).read_text())
  assert check['failures']==0,check
assert json.loads((out/'checks/audit-v05.json').read_text())['packed_images']
(out/'selected-inputs.json').write_text(json.dumps({'selected':selected,'revision':revision,'source_root':str(root),'scope':'Source candidates and isolated reviews only; no ordinary-world adoption or owner visual acceptance.'},indent=2)+'\n')
(out/'README.txt').write_text('ART-07C2 source handoff. Verify manifest before use.\nSee recipe/README.md for reconstruction and launch.\nUse recipe/launch-review.ps1 with a fresh CopyTo path. Never run the canonical package directly.\nNative fixtures are authored work/restart checks, not a generated-world player journey.\nAll C2 runtime candidates fit existing quarry bodies. Inherited pine is distant decorative context only.\n')
manifest={str(p.relative_to(out)).replace('\\','/'):{'bytes':p.stat().st_size,'sha256':digest(p)} for p in sorted(out.rglob('*')) if p.is_file()}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('C2_HANDOFF',len(manifest),'files',sum(v['bytes'] for v in manifest.values()),'bytes',digest(out/'manifest.json'))
