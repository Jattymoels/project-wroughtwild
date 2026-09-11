"""F3 immutable prerequisite, tool and exact selected input verification."""
import hashlib,json,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
DEPOT=Path('C:/Users/Matty/Dev/project-wroughtwild')
BASE='4b5d89b376765fbf4d46049aa099e0bb154a82da'
PACKAGES={
 'd4':('C:/Users/Matty/Dev/project-wroughtwild-art07-d4/build/art07/d4/h04','aaa0316f108cdb1de0ed27cc3a40fac7a07574497c14486e88b18fa73dfbda59'),
 'd6':(str(DEPOT/'build/art07/d6/worktree/build/art07/d6/v04/handoff'),'8d82eb36775959f41905e579e36d737caa4a8512ed504d679ab49652301338a7')}
def sha(p):
 with Path(p).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def row(p):
 p=Path(p);return {'path':p.as_posix(),'bytes':p.stat().st_size,'sha256':sha(p)}
def audit():
 result={'base':BASE,'packages':{},'tools':[],'inputs':[]}
 for key,(path,expected) in PACKAGES.items():
  folder=Path(path);m=folder/'manifest.json';assert sha(m)==expected,(key,'manifest mismatch')
  data=json.loads(m.read_text(encoding='utf-8-sig'));files=data['files']
  if isinstance(files,dict):files=[dict(path=k,**v) for k,v in files.items()]
  for f in files:assert sha(folder/f['path'])==f['sha256'].lower(),f['path']
  result['packages'][key]={'manifest':row(m),'verified_files':len(files)}
 model=json.loads((DEPOT/'tools/wroughtwild-trellis/install-manifest.json').read_text())
 result['pinned_runtime']=model
 for item in model['weights']:
  p=DEPOT/'build/trellis-local/models'/item['name'];r=row(p);assert r['sha256']==item['sha256'];result['tools'].append(r)
 for p in [DEPOT/'build/trellis-local/runtime/trellis-cli.exe',DEPOT/'build/blender-tool/blender-4.5.9-windows-x64/blender.exe',Path('C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe')]:result['tools'].append(row(p))
 for name in ['strange_ventlung.glb','strange_pullstone.glb','strange_vent_case.glb','strange_sorter.glb','strange_bellows.glb']:
  result['inputs'].append(row(ROOT/'game/assets/authored'/name))
 for p in (ROOT/'docs/art/leyline-studies/2026-09-09/art07/f3').glob('*v01.*'):result['inputs'].append(row(p))
 for name in ['construction','crafting','contraptions','worldgen']:result['inputs'].append(row(ROOT/'data/tuning'/f'{name}.json'))
 return result
if __name__=='__main__':
 out=Path(sys.argv[1]);out.parent.mkdir(parents=True,exist_ok=True);assert not out.exists();out.write_text(json.dumps(audit(),indent=2)+'\n');print('F3_PROVENANCE_OK',out)
