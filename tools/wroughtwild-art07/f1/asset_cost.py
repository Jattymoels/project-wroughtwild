"""Measure real GLB accessors, surface/image payloads and material modes."""
import hashlib,json,struct,sys
from pathlib import Path
from io import BytesIO
from PIL import Image
folder,out=map(Path,sys.argv[1:]);report={};unique={}
for p in sorted(folder.glob('*.glb')):
 data=p.read_bytes();length=struct.unpack_from('<I',data,12)[0];doc=json.loads(data[20:20+length]);binary=data[28+length:];images=[]
 for item in doc.get('images',[]):
  view=doc['bufferViews'][item['bufferView']];payload=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']];digest=hashlib.sha256(payload).hexdigest()
  with Image.open(BytesIO(payload)) as im:w,h=im.size
  record={'sha256':digest,'width':w,'height':h,'encoded_bytes':len(payload),'rgba8_with_mips_estimate_bytes':round(w*h*4*4/3)};images.append(record);unique[digest]=record
 primitives=[prim for mesh in doc.get('meshes',[]) for prim in mesh['primitives']]
 triangles=sum(doc['accessors'][prim['indices']]['count']//3 for prim in primitives)
 assert all(prim.get('mode',4)==4 for prim in primitives)
 report[p.name]={'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'triangles':triangles,'surfaces':len(primitives),'scar_surfaces':sum('COLOR_0' in x['attributes'] for x in primitives),'alpha_modes':sorted({m.get('alphaMode','OPAQUE') for m in doc.get('materials',[])}),'images':images}
out.parent.mkdir(parents=True,exist_ok=True);assert not out.exists()
out.write_text(json.dumps({'assets':report,'unique_images':list(unique.values()),'unique_rgba8_mips_estimate_bytes':sum(i['rgba8_with_mips_estimate_bytes'] for i in unique.values()),'note':'Encoded GLB payloads are measured. RGBA8+mips is a format estimate, not measured renderer allocation; see separate Godot benchmarks. Opaque meshes add no alpha overdraw. Device costs include fitted core and every housing/moving part; native representative chips and shadows are counted in engine benchmarks.'},indent=2)+'\n')
print('F1_COSTS',[(k,v['triangles'],v['surfaces']) for k,v in report.items()])
