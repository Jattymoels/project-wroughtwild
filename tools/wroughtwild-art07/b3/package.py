"""Fresh cache-free B3 handoff, hash every delivered byte before import."""
import sys,json,shutil,hashlib
from pathlib import Path
root,out=[Path(p).resolve() for p in sys.argv[1:]];assert not out.exists();out.mkdir(parents=True)
recipe=Path(__file__).parent
def copy(p,d):d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,d)
def tree(p,d):shutil.copytree(p,d,ignore=shutil.ignore_patterns('.godot','*.import','*.blend1','__pycache__','evidence','build'))
kit=root/'kit-v10';review=root/'review-v06'
for p in kit.iterdir():
 if p.suffix in ['.blend','.glb','.json']:copy(p,out/'models'/p.name)
tree(review/'review',out/'review');tree(review/'native',out/'native')
for name in ['audit-v10.json','fresh-audit.json','provenance.json']:copy(root/name,out/'evidence'/name)
for p in (root/'blender-v09').glob('*.png'):copy(p,out/'evidence/blender'/p.name)
for p in (root/'inspection-v02').iterdir():copy(p,out/'evidence/source-inspection'/p.name)
for renderer in ['forward_plus','gl_compatibility']:
 for context,folder in [('godot',review/'review/evidence'/renderer),('native',review/'native/game/b3/evidence'/renderer)]:
  for p in folder.iterdir():
   if p.is_file() and not p.name.startswith(('pulse-','deplete-')):copy(p,out/'evidence'/context/renderer/p.name)
for p in (review/'native/game/b3/evidence/headless').glob('*.json'):copy(p,out/'evidence/native/headless'/p.name)
tree(root/'motion',out/'evidence/motion')
for folder in ['current-checks','checked-native-v06','checked-capture-v05','checked-capture-v06','checked-benchmark','fresh-checks','fresh-native','fresh-capture']:
 for p in (root/folder).iterdir():
  if p.is_file() and not p.name.startswith('interactive-pause.log'):copy(p,out/'evidence/logs'/folder/p.name)
for pattern in ['*v09.log*','*v10.log*','*v05-import.log*','*v06-import.log*']:
 for p in root.glob(pattern):copy(p,out/'evidence/logs'/p.name)
for p in recipe.iterdir():
 if p.is_file():copy(p,out/'recipe'/p.name)
copy(recipe/'README.md',out/'README.md')
manifest={p.relative_to(out).as_posix():{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(out.rglob('*')) if p.is_file()}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2));print('B3_PACKAGE_OK',len(manifest),sum(v['bytes'] for v in manifest.values()),hashlib.sha256((out/'manifest.json').read_bytes()).hexdigest())
