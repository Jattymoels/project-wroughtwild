"""Verify published prerequisites and immutable source bytes before F4 assembly."""
import hashlib,json,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
DEPOT=Path('C:/Users/Matty/Dev/project-wroughtwild')
BASE='bbcb3a7dfd235e8f803141ccb57c38e03d6c1708'
PACKAGES={
 'e2':('build/art07/e2/worktree/build/art07/e2/v05/handoff','95d33325e5ce3ec48b9ae8a25345579965c9defae4381c492797008973d51fbd','fd7c4e9aa11027fc0d40732dd1d5c7922bea2744'),
 'f2':('build/art07/f2/worktree/build/art07/f2/v04/handoff','0a182b3cb25c5815497cf79645ff1be7769cf1d9d012572bfbbb0a8116d0d9cd','025fd5cf905b5c761d6354d45ecb12fe6d02cf0d'),
 'f3':('build/art07/f3/worktree/build/art07/f3/v28/handoff','0bdfa7b9f39b2f79e67fe0fa6adfa5a27f89188418e29e52de2fa91471d73dd8','e131d3e765875bea077fcbbbd1c0900261d55d29')}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify():
 result={'base':BASE,'packages':{}}
 for key,(rel,digest,commit) in PACKAGES.items():
  package=DEPOT/rel;manifest=package/'manifest.json'
  assert sha(manifest)==digest,(key,'manifest')
  subprocess.run(['git','-C',str(ROOT),'merge-base','--is-ancestor',commit,BASE],check=True)
  data=json.loads(manifest.read_text(encoding='utf-8-sig'))
  for record in data['files']:
   p=(package/record['path']).resolve();assert p.is_relative_to(package)
   assert p.stat().st_size==record['bytes'] and sha(p)==record['sha256'],str(p)
  result['packages'][key]={'path':str(package),'manifest_sha256':digest,'published_commit':commit,'files_verified':len(data['files'])}
 result['originals']={p:sha(ROOT/p) for p in ['game/scripts/pressure_pocket.gd','game/scripts/contraption_site.gd','game/scripts/strange_resource_art.gd','game/art/contraption_look.gd','data/tuning/contraptions.json','data/tuning/crafting.json','docs/art/concepts/environment/2026-09-09-frontier/05-useful-fixtures.png']}
 return result
if __name__=='__main__':
 out=Path(sys.argv[1]).resolve();assert out.is_relative_to(ROOT/'build/art07/f4');assert not out.exists()
 result=verify();out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(result,indent=2));print(json.dumps(result['packages'],indent=2))
