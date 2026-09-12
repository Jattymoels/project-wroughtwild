"""Verify all four published handoffs, then copy only E3's legal surface inputs."""
import hashlib, json, shutil, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
DEPOT=Path('C:/Users/Matty/Dev/project-wroughtwild')
BASE='bbcb3a7dfd235e8f803141ccb57c38e03d6c1708'
PACKAGES={
 'd1':(DEPOT/'build/art07/d1/worktree/build/art07/d1/v02/core-lattice-handoff-v01','a3e92f9692e05eae547290cd6520242f91dfbda31d9236eb6d12842f0453b85a','58d3223'),
 'd4':(Path('C:/Users/Matty/Dev/project-wroughtwild-art07-d4/build/art07/d4/h04'),'aaa0316f108cdb1de0ed27cc3a40fac7a07574497c14486e88b18fa73dfbda59','b1abc42'),
 'd5':(DEPOT/'build/art07/d5/worktree/build/art07/d5/v03/d5-handoff','79532aa924414715fbbde0bf714280fd75d40c9f21cc62cb44c0ce12c3834844','68b7ca1'),
 'd6':(DEPOT/'build/art07/d6/worktree/build/art07/d6/v04/handoff','8d82eb36775959f41905e579e36d737caa4a8512ed504d679ab49652301338a7','3bc4f68')}
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def verify():
 result={'base':BASE,'dependencies':{},'sources':{}}
 for key,(package,expected,commit) in PACKAGES.items():
  assert sha(package/'manifest.json')==expected,key
  subprocess.run(['git','-C',str(ROOT),'merge-base','--is-ancestor',commit,BASE],check=True)
  rows=json.loads((package/'manifest.json').read_text())['files']
  if isinstance(rows,dict): rows=[dict(path=k,**v) for k,v in rows.items()]
  for row in rows:
   p=(package/row['path']).resolve();assert p.is_relative_to(package.resolve())
   assert p.stat().st_size==row['bytes'] and sha(p)==row['sha256'],p
  result['dependencies'][key]={'path':str(package),'manifest_sha256':expected,'published_commit':commit,'verified_files':len(rows)}
 for rel in ['docs/art/concepts/environment/2026-09-09-frontier/04-stations-and-home.png','docs/art/concepts/environment/2026-09-09-frontier/asset-catalogue.json','game/scripts/placed_block.gd','game/scripts/piece_mesh.gd','game/scripts/chest_panel.gd','game/scripts/grid_placement.gd','game/scripts/save_manager.gd','data/tuning/construction.json','data/tuning/worldgen.json','data/tuning/world.json']:
  result['sources'][str(ROOT/rel)]=sha(ROOT/rel)
 for p in [DEPOT/'build/blender-tool/blender-4.5.9-windows-x64/blender.exe',DEPOT/'build/trellis-local/runtime/trellis-cli.exe',DEPOT/'tools/wroughtwild-trellis/install-manifest.json',Path('C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe')]:result['sources'][str(p)]=sha(p)
 return result
if __name__=='__main__':
 out=Path(sys.argv[1]).resolve();assert out.is_relative_to(ROOT/'build/art07/e3')
 audit=verify();out.mkdir(parents=True,exist_ok=False);maps=out/'textures';maps.mkdir()
 stems=[('d4',f'd4_{f}_{side}') for f in ['wood','pine','bog_oak','ash_wood','resinheart'] for side in ['face','edge']]
 stems += [('d5','d5_charcoal_face')]+[('d6','d6_'+f) for f in ['iron','bronze','steel']]
 for key,stem in stems:
  for channel in ['albedo','normal','orm']:
   src=PACKAGES[key][0]/'review/textures'/f'{stem}_{channel}.png'
   shutil.copy2(src,maps/src.name);audit['sources'][str(src)]=sha(src)
 (out/'provenance.json').write_text(json.dumps(audit,indent=2)+'\n')
 print('E3_INPUTS_OK',{k:v['verified_files'] for k,v in audit['dependencies'].items()})
