"""Seal only R5 candidate and evidence. Canonical outputs are never imported."""
import argparse,hashlib,json,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];BUILD=ROOT/'build/art07-repairs/r5';C=BUILD/'v02';B=BUILD/'v01'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.file_digest(p.open('rb'),'sha256').hexdigest()
def copy(src,dst):
 dst.parent.mkdir(parents=True,exist_ok=True);assert not dst.exists(),dst;shutil.copy2(src,dst);assert sha(src)==sha(dst)
def verify(root):
 manifest=read(root/'manifest.json');files=manifest['files'];actual={p.relative_to(root).as_posix() for p in root.rglob('*') if p.is_file() and p!=root/'manifest.json'}
 assert actual==set(files),(actual-set(files),set(files)-actual)
 for name,row in files.items():
  p=(root/name).resolve();assert p.is_relative_to(root.resolve()) and p.stat().st_size==row['bytes'] and sha(p)==row['sha256'],name
 return {'path':str(root),'manifest_sha256':sha(root/'manifest.json'),'files':len(files),'bytes':sum(r['bytes'] for r in files.values())}
p=argparse.ArgumentParser();p.add_argument('mode',choices=['seal','verify']);p.add_argument('path',type=Path);a=p.parse_args();out=a.path.resolve()
if a.mode=='verify':print(json.dumps(verify(out),indent=2));raise SystemExit
assert out.is_relative_to(BUILD) and not out.exists()
assert read(C/'audit.json')['original_runtime_entries_checked']==4787
out.mkdir()
# Full pinned runtime file set with the nine expressly audited visual deltas.
for rel in read(C/'prepared.json')['original_files']:copy(C/'runtime'/rel,out/'runtime'/rel)
for f in (C/'runtime/game/r5').iterdir():
 if f.suffix in ['.gd','.tscn']:copy(f,out/'runtime/game/r5'/f.name)
for name in ['changes.json','audit.json']:copy(C/name,out/name)
copy(C/'blender-initial-framing.py',out/'evidence/source-execution/blender-fit-executed.py')
for root,prefix in [(C/'models','source-candidate'),(C/'reopen-v02','evidence/reopen'),(C/'reopen','evidence/reopen-initial-cropped'),(B/'original-source','source-original'),(B/'preflight','evidence/preflight')]:
 for f in root.rglob('*'):
  if f.is_file():copy(f,out/prefix/f.relative_to(root))
for version,label in [(B,'baseline'),(C,'candidate')]:
 for folder in ['logs','evidence']:
  for f in (version/folder).rglob('*'):
   if f.is_file():copy(f,out/'evidence'/label/folder/f.relative_to(version/folder))
 for f in version.glob('*.json'):
  if f.name not in ['changes.json','audit.json']:copy(f,out/'evidence'/label/'job-specs'/f.name)
 for f in version.glob('*.txt'):copy(f,out/'evidence'/label/f.name)
 for f in (version/'users').rglob('r5-*.json'):copy(f,out/'evidence'/label/'saved-checkpoints'/f.relative_to(version/'users'))
for f in (ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r5').rglob('*'):
 if f.is_file():copy(f,out/'evidence/selected'/f.name)
for f in Path(__file__).parent.iterdir():
 if f.is_file() and f.suffix in ['.py','.gd','.json','.md','.ps1']:copy(f,out/'tools'/f.name)
files={f.relative_to(out).as_posix():{'bytes':f.stat().st_size,'sha256':sha(f)} for f in sorted(out.rglob('*')) if f.is_file()}
(out/'manifest.json').write_text(json.dumps({'id':'r5','runtime_base':'6bb2e044dcd0bf1788896aa2c19cdf56fee93522','files':files},indent=2)+'\n')
record=verify(out);(C/'package-result.json').write_text(json.dumps(record,indent=2)+'\n');print(json.dumps(record,indent=2))
