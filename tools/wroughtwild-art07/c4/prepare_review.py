"""C4 derivative of B4's content-hashed texture cook; geometry bytes retained."""
import sys,json,struct,hashlib,shutil,io,random,math
from pathlib import Path
from PIL import Image
from prerequisites import DEPOT,sha
kit,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);assert not out.exists();out.mkdir(parents=True)
(out/'evidence').mkdir();(out/'evidence/.gdignore').write_text('')
recipe=Path(__file__).parent;(out/'assets').mkdir();(out/'textures').mkdir();audit=[];textures={}
for path in sorted((kit/'models').glob('*.glb')):
    blob=path.read_bytes();jlen=struct.unpack_from('<I',blob,12)[0];doc=json.loads(blob[20:20+jlen]);binary=blob[20+jlen+8:]
    old=doc.get('bufferViews',[]);ivs={i['bufferView'] for i in doc.get('images',[]) if 'bufferView' in i}
    for im in doc.get('images',[]):
        v=old[im.pop('bufferView')];raw=binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]
        image=Image.open(io.BytesIO(raw));original=list(image.size)
        if max(image.size)>1024:
            image.thumbnail((1024,1024),Image.Resampling.LANCZOS);b=io.BytesIO();image.save(b,format='PNG');raw=b.getvalue()
        digest=hashlib.sha256(raw).hexdigest();name=digest+'.png';(out/'textures'/name).write_bytes(raw)
        im['uri']='../textures/'+name;im.pop('mimeType',None)
        textures[digest]={'size':list(image.size),'source_size':original,'encoded_bytes':len(raw),'rgba8_mip_bytes':int(image.width*image.height*4*4/3)}
    new=bytearray();views=[];mapping={}
    for idx,v in enumerate(old):
        if idx in ivs:continue
        while len(new)%4:new.append(0)
        payload=binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]
        nv=dict(v);nv['byteOffset']=len(new);nv['buffer']=0;mapping[idx]=len(views);views.append(nv);new.extend(payload)
        assert bytes(new[nv['byteOffset']:nv['byteOffset']+nv['byteLength']])==payload
    for a in doc.get('accessors',[]):
        if 'bufferView' in a:a['bufferView']=mapping[a['bufferView']]
        assert 'sparse' not in a
    doc['bufferViews']=views;doc['buffers']=[{'byteLength':len(new),'uri':path.stem+'.bin'}]
    (out/'assets'/(path.stem+'.bin')).write_bytes(new);(out/'assets'/(path.stem+'.gltf')).write_text(json.dumps(doc,separators=(',',':')))
    (out/'assets'/(path.stem+'.gltf.import')).write_text('[remap]\nimporter="scene"\ntype="PackedScene"\n[deps]\nsource_file="res://assets/'+path.stem+'.gltf"\n[params]\nmeshes/generate_lods=false\nmeshes/create_shadow_meshes=false\nmeshes/force_disable_compression=true\n')
    audit.append({'source':path.name,'sha256':sha(path),'geometry_views_preserved':len(views),'geometry_bytes':len(new)})
for n in ['kit.json','review.gd','surface.gdshader','verify_pause.gd']:shutil.copy2(recipe/n,out/n)
floor=DEPOT/'docs/art/leyline-studies/2026-09-09/grove-art02/forest-floor.png';shutil.copy2(floor,out/'forest-floor.png')
for p in list((out/'textures').glob('*.png'))+[out/'forest-floor.png']:
    rel=p.relative_to(out).as_posix();p.with_suffix('.png.import').write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n[deps]\nsource_file="res://'+rel+'"\n[params]\ncompress/mode=0\nmipmaps/generate=true\nprocess/fix_alpha_border=false\n')
# Authored review pockets, not a native scatter rule or save geography.
layout=[]
for i,(x,z) in enumerate([(-2.5,-9),(3.1,-5),(-4,-2),(2.5,2),(-3.2,7),(4.3,9),(-6,14),(5,18),(-8,22),(8,26),(-5,30),(5,33)]):
    layout.append({'role':['ash-a','ash-b','ash-short'][i%3],'x':x,'z':z,'yaw':(.7*i+2.3),'scale':1})
layout[0]['role']='ash-altered';layout[0]['yaw']=0
layout += [{'role':'ash-felled-a','x':-3.7,'z':-5,'yaw':.3,'scale':1},{'role':'ash-felled-b','x':4.5,'z':4,'yaw':1.2,'scale':1}]
for i,(x,z) in enumerate([(-4,-9),(4,-2),(-5,5),(5,13),(-8,21),(8,29)]):
    layout.append({'role':'rock-shelf','x':x,'z':z,'yaw':i*.9,'scale':.7 if i%2 else 1})
    layout.append({'role':'talus-pebbles','x':x+1,'z':z-1.5,'yaw':i,'scale':1})
rng=random.Random(42)
for cx,cz in [(-3,-10),(3,-5),(-3,0),(4,6),(-4,12),(5,19),(-6,26),(5,31)]:
    for j in range(10):
        x=cx+rng.uniform(-1.1,1.1);z=cz+rng.uniform(-1.6,1.6)
        layout.append({'role':['scrub','thorn','seed-grass','seed-grass','seed-grass'][j%5],'x':x,'z':z,'yaw':rng.uniform(0,math.tau),'scale':rng.uniform(.7,1.05)})
# Uneven survivor pockets away from the route; source identity remains in the native fixture.
for i,(x,z) in enumerate([(-6,-6),(-7,-3),(-8,0),(7,2),(8,5),(9,8),(-7,11),(-9,15),(7,23),(9,24),(-10,29)]):
    layout.append({'role':['ash-short','ash-b','ash-a'][i%3],'x':x,'z':z,'yaw':rng.uniform(0,math.tau),'scale':rng.uniform(.72,1)})
for cx,cz in [(-7,-5),(7,4),(-8,14),(8,25)]:
    for j in range(12):
        layout.append({'role':'seed-grass' if j%3 else 'scrub','x':cx+rng.uniform(-2,2),'z':cz+rng.uniform(-2.5,2.5),'yaw':rng.uniform(0,math.tau),'scale':rng.uniform(.65,1.2)})
    layout.append({'role':'rock-shelf','x':cx,'z':cz,'yaw':rng.uniform(0,math.tau),'scale':1.2})
for x,z,scale in [(-13,10,2.5),(14,21,2.5),(-13,30,3.0),(6,43,3.5),(-5,48,4.0)]:
    layout.append({'role':'rock-shelf','x':x,'z':z,'yaw':rng.uniform(0,math.tau),'scale':scale})
(out/'layout.json').write_text(json.dumps(layout,indent=2)+'\n')
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="ART-07C4 Recovering wastes"\nrun/main_scene="res://review.tscn"\n[display]\nwindow/size/viewport_width=1440\nwindow/size/viewport_height=900\nwindow/vsync/vsync_mode=0\n[rendering]\nrenderer/rendering_method="forward_plus"\n')
(out/'review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://review.gd" id="1"]\n[node name="C4" type="Node3D"]\nscript=ExtResource("1")\n')
(out/'cook.json').write_text(json.dumps({'models':audit,'textures':textures,'texture_rgba8_mip_bytes':sum(t['rgba8_mip_bytes'] for t in textures.values()),'floor_sha256':sha(floor)},indent=2)+'\n')
print('C4_REVIEW_PREPARED',len(layout),len(textures))
