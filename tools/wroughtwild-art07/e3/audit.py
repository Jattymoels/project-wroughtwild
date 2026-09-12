"""E3 package/source contracts, unchanged inputs and documentation-owned controls."""
import json,sys,subprocess,struct
from pathlib import Path
from PIL import Image
from inputs import ROOT,BASE,sha,verify
source,review,inputs,out=[Path(p).resolve() for p in sys.argv[1:5]]
assert out.is_relative_to(ROOT/'build/art07/e3')
data=json.loads((source/'source/geometry.json').read_text())
assert len(data)==31 and all(v['degenerates']==0 for v in data.values())
assert sha(source/'source/geometry.json')==sha(review/'game/e3/geometry.json')
runtime={}
for p in sorted((source/'runtime').glob('*.glb')):
 assert sha(p)==sha(review/'game/assets/authored/e3'/p.name)
 raw=p.read_bytes();magic,version,size=struct.unpack_from('<III',raw)
 assert magic==0x46546c67 and version==2 and size==len(raw)
 length,kind=struct.unpack_from('<II',raw,12);assert kind==0x4e4f534a
 gltf=json.loads(raw[20:20+length])
 runtime[p.stem]={'bytes':len(raw),'surfaces':sum(len(m['primitives']) for m in gltf['meshes']),'embedded_images':len(gltf.get('images',[])),'sha256':sha(p)}
assert len(runtime)==31
catalogue=json.loads((ROOT/'docs/art/concepts/environment/2026-09-09-frontier/asset-catalogue.json').read_text())
entries={v['id']:v for v in catalogue['shapes'] if v['id'] in ['chest','campfire']}
assert len(entries['chest']['allowed_materials'])==8 and len(entries['campfire']['allowed_materials'])==5
for family in entries['chest']['allowed_materials']:
 for part in ['body','lid']:assert f'chest_{family}_{part}' in data
for family in entries['campfire']['allowed_materials']:
 for part in ['fuel','embers','ash']:assert f'fire_{family}_{part}' in data
texture_bytes=rgba_mips=0;maps=[]
for p in sorted((inputs/'textures').glob('*.png')):
 assert sha(p)==sha(review/'game/e3/textures'/p.name)
 with Image.open(p) as im:
  assert im.mode=='RGB' and im.size in [(512,512),(1024,1024)]
  decoded=im.width*im.height*3;texture_bytes+=decoded
  mip=sum(max(1,im.width>>level)*max(1,im.height>>level)*4 for level in range(im.width.bit_length()))
  rgba_mips+=mip;maps.append({'file':p.name,'size':list(im.size),'bytes':p.stat().st_size,'sha256':sha(p),'rgb_bytes':decoded,'rgba_mip_bytes':mip})
  settings=(review/'game/e3/textures'/(p.name+'.import')).read_text()
  assert 'mipmaps/generate=true' in settings and 'detect_3d/compress_to=0' in settings
  assert ('compress/normal_map='+('1' if '_normal.png' in p.name else '2')) in settings
assert len(maps)==42
for p in (ROOT/'tools/wroughtwild-art07/e3').glob('*.gd*'):
 if p.name in ['home_state.gd','home_art.gd','fuel.gdshader','ember.gdshader']:
  s=p.read_text();assert 'Time.get_ticks' not in s and 'TIME' not in s
audit=verify()
initial=json.loads((inputs/'provenance.json').read_text())
for p,h in initial['sources'].items():assert sha(p)==h,p
changed=subprocess.check_output(['git','-C',str(ROOT),'diff','--name-only',BASE,'--','game','sim','data'],text=True)
assert not changed,changed
out.write_text(json.dumps({'base':BASE,'dependencies':audit['dependencies'],'unchanged_source_files':len(initial['sources']),'models':data,'runtime':runtime,'textures':maps,'rgb_base_bytes':texture_bytes,'rgba_full_mip_bytes':rgba_mips,'png_bytes':sum(v['bytes'] for v in maps),'normal_game_sim_data_diff':changed,'limitations':'Source triangle counts, not whole-world budgets. Same explicit mesh set at near/middle/far; engine import LOD retained on articulated parts. GLBs retain embedded source maps in addition to shared external runtime bindings; report engine resident bytes separately.'},indent=2)+'\n')
print('E3_AUDIT_OK',len(data),'models',len(maps),'maps',rgba_mips,'RGBA mip bytes')
