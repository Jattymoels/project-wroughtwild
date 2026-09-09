"""Read immutable sources and selected exports; report real GLB metadata and costs."""
import json,struct,hashlib,io,sys,re
from pathlib import Path
from PIL import Image
root=Path(sys.argv[1]);out=Path(sys.argv[2]);assert not out.exists()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def glb(p):
 data=p.read_bytes();n=struct.unpack_from('<I',data,12)[0];doc=json.loads(data[20:20+n]);return doc,data[28+n:]
def maps(p):
 doc,binary=glb(p);rows=[]
 for image in doc.get('images',[]):
  v=doc['bufferViews'][image['bufferView']];blob=binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']];im=Image.open(io.BytesIO(blob));rows.append({'name':image.get('name',''),'size':list(im.size),'encoded_bytes':len(blob),'decoded_rgba8_bytes':im.width*im.height*4,'sha256':hashlib.sha256(blob).hexdigest()})
 return rows
source=root/'pine-source/pine.glb';doc,_=glb(source)
result={'runtime_asset_metadata':doc.get('asset'), 'runtime_extras':doc.get('extras'), 'generation':json.loads((root/'pine-source/generation.json').read_text(encoding='utf-8-sig')), 'exports':{}, 'checks':[]}
for folder in [root/'broadleaf-kit-v05',root/'pine-kit-v03']:
 report=json.loads((folder/'kit-report.json').read_text())
 for name,row in report['assets'].items():
  p=folder/(name+'.glb');row.update({'file_bytes':p.stat().st_size,'textures':maps(p)});result['exports'][name]=row
for p in sorted((root/'current-checks').glob('*.log')):
 text=p.read_text();counts=re.findall(r'(\d+) checks, (\d+) failures',text);job=json.loads(Path(str(p)+'.job.json').read_text(encoding='utf-8-sig'));assert counts and counts[-1][1]=='0' and job['exit']==0
 result['checks'].append({'log':str(p),'checks':int(counts[-1][0]),'failures':int(counts[-1][1]),'job':job})
result['total_current_checks']=sum(r['checks'] for r in result['checks'])
depot=Path('C:/Users/Matty/Dev/project-wroughtwild/build/grove-art02/emberroot-handoff');manifest=json.loads((depot/'manifest.json').read_text());failed=[name for name,entry in manifest.items() if sha(depot/name)!=entry['sha256']];assert not failed
result['approved_source_recheck']={'files':len(manifest),'failures':failed,'manifest_sha256':sha(depot/'manifest.json')}
result['selected_masters']={str(p):{'sha256':sha(p),'bytes':p.stat().st_size} for p in [root/'broadleaf-kit-v05/broadleaf-master.blend',root/'pine-kit-v03/pine-master.blend']}
out.write_text(json.dumps(result,indent=2));print('B1_COSTS_AND_LINEAGE_OK',result['total_current_checks']);print(json.dumps(result['runtime_asset_metadata'],indent=2))
