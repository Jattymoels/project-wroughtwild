"""Cook shared textures while retaining every geometry/accessor byte; fresh review only."""
import sys,json,struct,hashlib,shutil,io
from pathlib import Path
from PIL import Image
kit,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);assert not out.exists();out.mkdir(parents=True)
recipe=Path(__file__).parent;depot=Path('C:/Users/Matty/Dev/project-wroughtwild')
(out/'assets').mkdir();(out/'textures').mkdir();audit=[];textures={}
for path in sorted((kit/'models').glob('*.glb')):
    blob=path.read_bytes();jlen=struct.unpack_from('<I',blob,12)[0];doc=json.loads(blob[20:20+jlen]);binstart=20+jlen+8;binary=blob[binstart:]
    oldviews=doc['bufferViews'];imageviews={i['bufferView'] for i in doc.get('images',[]) if 'bufferView' in i}
    for im in doc.get('images',[]):
        v=oldviews[im.pop('bufferView')];raw=binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]
        image=Image.open(io.BytesIO(raw));before=list(image.size)
        if max(image.size)>1024:
            image.thumbnail((1024,1024),Image.Resampling.LANCZOS);b=io.BytesIO();image.save(b,format='PNG');raw=b.getvalue()
        digest=hashlib.sha256(raw).hexdigest();name=digest+'.png';(out/'textures'/name).write_bytes(raw)
        im['uri']='../textures/'+name;im.pop('mimeType',None)
        textures[digest]={'size':list(image.size),'source_size':before,'encoded_bytes':len(raw),'rgba8_mip_bytes':int(image.width*image.height*4*4/3)}
    # Keep unused image bytes out of geometry buffers; update all retained view references.
    newbin=bytearray();mapping={};newviews=[]
    for idx,v in enumerate(oldviews):
        if idx in imageviews:continue
        while len(newbin)%4:newbin.append(0)
        payload=binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]
        nv=dict(v);nv['byteOffset']=len(newbin);nv['buffer']=0;mapping[idx]=len(newviews);newviews.append(nv);newbin.extend(payload)
        assert bytes(newbin[nv['byteOffset']:nv['byteOffset']+nv['byteLength']])==payload
    for accessor in doc.get('accessors',[]):
        if 'bufferView' in accessor:accessor['bufferView']=mapping[accessor['bufferView']]
        assert 'sparse' not in accessor
    doc['bufferViews']=newviews;doc['buffers']=[{'byteLength':len(newbin),'uri':path.stem+'.bin'}]
    (out/'assets'/(path.stem+'.bin')).write_bytes(newbin)
    (out/'assets'/(path.stem+'.gltf')).write_text(json.dumps(doc,separators=(',',':')))
    (out/'assets'/(path.stem+'.gltf.import')).write_text('[remap]\nimporter="scene"\ntype="PackedScene"\n[deps]\nsource_file="res://assets/'+path.stem+'.gltf"\n[params]\nmeshes/generate_lods=false\nmeshes/create_shadow_meshes=false\nmeshes/force_disable_compression=true\n')
    audit.append({'source':path.name,'source_sha256':hashlib.sha256(blob).hexdigest(),'geometry_views_preserved':len(newviews),'geometry_bytes':len(newbin)})
for name in ['kit.json','review.gd','asset_view.gd','surface.gdshader']:
    shutil.copy2(recipe/name,out/name)
shutil.copy2(kit/'models.json',out/'models.json')
shutil.copy2(depot/'docs/art/leyline-studies/2026-09-09/grove-art02/forest-floor.png',out/'forest-floor.png')
for png in list((out/'textures').glob('*.png'))+[out/'forest-floor.png']:
    rel=png.relative_to(out).as_posix()
    png.with_suffix('.png.import').write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n[deps]\nsource_file="res://'+rel+'"\n[params]\ncompress/mode=0\nmipmaps/generate=true\nprocess/fix_alpha_border=false\n')
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="ART-07C3 Oldgrowth source review"\nrun/main_scene="res://review.tscn"\n[display]\nwindow/size/viewport_width=1280\nwindow/size/viewport_height=900\nwindow/vsync/vsync_mode=0\n[rendering]\nrenderer/rendering_method="forward_plus"\n')
(out/'review.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://review.gd" id="1"]\n[node name="C3" type="Node3D"]\nscript=ExtResource("1")\n')
(out/'cook.json').write_text(json.dumps({'models':audit,'unique_textures':textures,'texture_rgba8_mip_bytes':sum(t['rgba8_mip_bytes'] for t in textures.values())},indent=2)+'\n')
print('C3_COOK_OK',len(audit),len(textures))
