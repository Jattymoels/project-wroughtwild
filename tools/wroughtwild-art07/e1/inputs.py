"""Verify published source packages in full; copy only E1's unchanged maps."""
import hashlib, json, shutil, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
DEPOT=Path('C:/Users/Matty/Dev/project-wroughtwild')
BASE='bbcb3a7dfd235e8f803141ccb57c38e03d6c1708'
PACKAGES={
 'd1':(DEPOT/'build/art07/d1/worktree/build/art07/d1/v02/core-lattice-handoff-v01','a3e92f9692e05eae547290cd6520242f91dfbda31d9236eb6d12842f0453b85a','58d3223'),
 'd4':(Path('C:/Users/Matty/Dev/project-wroughtwild-art07-d4/build/art07/d4/h04'),'aaa0316f108cdb1de0ed27cc3a40fac7a07574497c14486e88b18fa73dfbda59','b1abc42'),
 'd5':(DEPOT/'build/art07/d5/worktree/build/art07/d5/v03/d5-handoff','79532aa924414715fbbde0bf714280fd75d40c9f21cc62cb44c0ce12c3834844','68b7ca1152fc543449316c8187efb1ce3abd0382')}
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def verify():
 result={'base':BASE,'dependencies':{},'sources':{}}
 for key,(package,expected,commit) in PACKAGES.items():
  assert sha(package/'manifest.json')==expected,key
  subprocess.run(['git','-C',str(ROOT),'merge-base','--is-ancestor',commit,BASE],check=True)
  files=json.loads((package/'manifest.json').read_text())['files']
  rows=[dict(path=k,**v) for k,v in files.items()] if isinstance(files,dict) else files
  for row in rows:
   p=(package/row['path']).resolve();assert p.is_relative_to(package.resolve())
   assert p.stat().st_size==row['bytes'] and sha(p)==row['sha256'],str(p)
  result['dependencies'][key]={'path':str(package),'manifest_sha256':expected,'published_commit':commit,'verified_files':len(rows)}
 for rel in ['docs/art/concepts/environment/2026-09-09-frontier/04-stations-and-home.png','game/assets/authored/workbench.glb','game/assets/authored/mason_yard.glb','game/scenes/station_body.tres','game/art/station_look.gd','game/scripts/station_site.gd','game/art/workshop_feedback_look.tres','data/tuning/crafting.json','data/tuning/construction.json']:
  result['sources'][str(ROOT/rel)]=sha(ROOT/rel)
 for rel in ['build/blender-tool/blender-4.5.9-windows-x64/blender.exe','build/trellis-local/runtime/trellis-cli.exe','tools/wroughtwild-trellis/install-manifest.json']:
  result['sources'][str(DEPOT/rel)]=sha(DEPOT/rel)
 return result
if __name__=='__main__':
 result=verify();out=Path(sys.argv[1]).resolve();assert out.is_relative_to(ROOT/'build/art07/e1')
 out.mkdir(parents=True,exist_ok=False);(out/'textures').mkdir()
 for key,stem in [('d4','d4_wood_face'),('d4','d4_wood_edge'),('d5','d5_fieldstone_edge'),('d5','d5_stone_edge')]:
  for channel in ['albedo','normal','orm']:
   src=PACKAGES[key][0]/'review/textures'/f'{stem}_{channel}.png'
   shutil.copy2(src,out/'textures'/src.name);result['sources'][str(src)]=sha(src)
 (out/'provenance.json').write_text(json.dumps(result,indent=2)+'\n')
 print('E1_INPUTS_OK',{k:v['verified_files'] for k,v in result['dependencies'].items()})
