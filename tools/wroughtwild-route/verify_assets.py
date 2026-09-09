"""Validate the cook against its frozen input bytes, independently of Godot."""
import hashlib,json,struct,sys
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
out=Path(sys.argv[1]);report=json.loads((out/'asset-index.json').read_text(encoding='utf-8'))
checks=0
def check(ok,label):
 global checks
 assert ok,label
 checks+=1
def glb(p):
 b=p.read_bytes();l=struct.unpack_from('<I',b,12)[0];return json.loads(b[20:20+l]),b[28+l:]
def view(doc,data,i):
 v=doc['bufferViews'][i];return data[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]
for path,digest in report['inputs'].items():check(hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==digest,'original input unchanged: '+path)
for name,record in report['models'].items():
 old,raw=glb(ROOT/record['source']);new,cooked=glb(out/(name+'.glb'))
 check(old.get('animations')==new.get('animations'),'all original animation names, samplers and channels retained: '+name)
 check(old.get('skins')==new.get('skins'),'skin and inverse bind accessors retained: '+name)
 check(old['nodes']==new['nodes'],'node hierarchy and local transforms retained: '+name)
 check(len(old['accessors'])==len(new['accessors']),'accessor count: '+name)
 for i,(a,b) in enumerate(zip(old['accessors'],new['accessors'])):
  check({k:v for k,v in a.items() if k!='bufferView'}=={k:v for k,v in b.items() if k!='bufferView'},'accessor layout: '+name+'/'+str(i))
  if 'bufferView' in a:check(view(old,raw,a['bufferView'])==view(new,cooked,b['bufferView']),'mesh/skin/animation bytes: '+name+'/'+str(i))
 for im in new.get('images',[]):check('bufferView' not in im and (out/im['uri']).exists(),'external shared image: '+name)
 descriptor=(out/(name+'.glb.import')).read_text()
 check('meshes/generate_lods=false' in descriptor and 'animation/fps=100' in descriptor,'explicit imported geometry and 100 Hz animation: '+name)
for name in report['textures']:
 im=Image.open(out/'textures'/name);im.load();check(max(im.size)<=2048,'maximum-2k texture: '+name)
result={'checks':checks,'failures':0,'models':len(report['models']),'textures':len(report['textures']),'texture_png_bytes':report['texture_bytes'],'note':'Every source hash and mesh/skin/animation buffer is exact. GPU compression is not selected; external PNG maps are deduplicated and limited to 2k.'}
(out.parent.parent.parent/'evidence-art'/'asset-checks.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print('ART05_ASSETS_OK',checks)
