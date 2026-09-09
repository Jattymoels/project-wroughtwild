"""Package the selected B1 outputs into a fresh, cache-free local handoff."""
import sys,shutil,json,hashlib,zipfile,subprocess
from pathlib import Path
root,out=map(Path,sys.argv[1:]);assert not out.exists();out.mkdir(parents=True)
recipe=Path(__file__).parent
def copy(p,d):d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,d)
def tree(src,dst):shutil.copytree(src,dst,ignore=shutil.ignore_patterns('.godot','*.import','*.blend1','__pycache__','evidence'))
for species,folder in [('broadleaf','broadleaf-kit-v05'),('pine','pine-kit-v03')]:
 for p in (root/folder).iterdir():
  if p.suffix in ['.blend','.glb','.json']:copy(p,out/'models'/species/p.name)
  elif p.suffix=='.png':copy(p,out/'evidence/blender'/species/p.name)
for species,folder in [('broadleaf','oak-inspection'),('pine','pine-inspection')]:
 for p in (root/folder).iterdir():
  if p.suffix in ['.json','.png']:copy(p,out/'evidence/source-inspection'/species/p.name)
for p in (root/'pine-source').iterdir():
 if p.suffix in ['.json','.png','.glb','.log']:copy(p,out/'source/pine'/p.name)
copy(recipe.parents[2]/'docs/art/leyline-studies/2026-09-09/art07/b1/pine-input-v01.png',out/'source/pine/input.png')
for p in recipe.iterdir():
 if p.is_file():copy(p,out/'recipe'/p.name)
copy(recipe/'README.md',out/'README.md')
tree(root/'review-v05',out/'review')
with zipfile.ZipFile(root/'current-game.zip') as z:z.extractall(out/'native')
copy(root/'native/bin/libwroughtwild_sim.windows.x86_64.dll',out/'native/game/bin/libwroughtwild_sim.windows.x86_64.dll')
subprocess.run([sys.executable,str(recipe/'prepare_native.py'),str(out/'review'),str(out/'native/game')],check=True)
copy(root/'native/provenance.json',out/'native/provenance.json')
for folder in ['current-checks','final-native-v04']:
 for p in (root/folder).iterdir():
  if p.is_file():copy(p,out/'evidence/logs'/folder/p.name)
for p in root.glob('*.log*'):
 if p.name.startswith(('final-','blender-audit-v03','broadleaf-kit-v05','pine-kit-v03','review-v05-import','native-fixture-v04-import','oak-inspection','pine-inspection')):copy(p,out/'evidence/logs'/p.name)
for name in ['costs-and-lineage.json','source-verification.json','blender-audit-v03.json','cut-face-audit.json']:copy(root/name,out/'evidence'/name)
for renderer in ['forward_plus','gl_compatibility']:
 for p in (root/'review-v05/evidence'/renderer).iterdir():
  if not p.name.startswith('motion-'):copy(p,out/'evidence/godot'/renderer/p.name)
 for p in (root/'native-fixture-v04/game/b1/evidence'/renderer).iterdir():
  if not p.name.startswith('fall-'):copy(p,out/'evidence/native'/renderer/p.name)
for p in (root/'native-fixture-v04/game/b1/evidence/headless').glob('*.json'):copy(p,out/'evidence/native/headless'/p.name)
shutil.copytree(root/'motion-v02',out/'evidence/motion')
manifest={p.relative_to(out).as_posix():{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(out.rglob('*')) if p.is_file()}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2));print('B1_PACKAGE_OK',len(manifest),sum(v['bytes'] for v in manifest.values()),hashlib.sha256((out/'manifest.json').read_bytes()).hexdigest())
