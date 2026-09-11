"""Copy current native archive and cook shared textures; canonical sources are read-only."""
import sys,json,struct,hashlib,shutil,io
from pathlib import Path
from PIL import Image
current,kit,out=[Path(p).resolve() for p in sys.argv[1:]]
assert not out.exists();out.mkdir(parents=True)
recipe=Path(__file__).parent
shutil.copytree(current/'game',out/'game',ignore=shutil.ignore_patterns('.godot','*.json.previous'))
shutil.copytree(current/'data',out/'data');shutil.copy2(current/'provenance.json',out/'provenance.json')
game=out/'game';art=game/'c6';(art/'assets').mkdir(exist_ok=True);(art/'textures').mkdir(exist_ok=True)
(out/'build/lf3').mkdir(parents=True)
audit=[];textures={}
for path in sorted((kit/'models').glob('*.glb')):
    blob=path.read_bytes();jlen=struct.unpack_from('<I',blob,12)[0];doc=json.loads(blob[20:20+jlen]);binary=blob[20+jlen+8:]
    oldviews=doc['bufferViews'];imageviews={i['bufferView'] for i in doc.get('images',[]) if 'bufferView' in i}
    for im in doc.get('images',[]):
        view=oldviews[im.pop('bufferView')];raw=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
        png=Image.open(io.BytesIO(raw));digest=hashlib.sha256(raw).hexdigest();name=digest+'.png';(art/'textures'/name).write_bytes(raw)
        im['uri']='../textures/'+name;im.pop('mimeType',None)
        textures[digest]={'size':list(png.size),'encoded_bytes':len(raw),'rgba8_mip_bytes':int(png.width*png.height*4*4/3)}
    data=bytearray();mapping={};views=[]
    for idx,view in enumerate(oldviews):
        if idx in imageviews:continue
        while len(data)%4:data.append(0)
        payload=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
        new=dict(view);new['byteOffset']=len(data);new['buffer']=0;mapping[idx]=len(views);views.append(new);data.extend(payload)
        assert bytes(data[new['byteOffset']:new['byteOffset']+new['byteLength']])==payload
    for accessor in doc.get('accessors',[]):
        if 'bufferView' in accessor:accessor['bufferView']=mapping[accessor['bufferView']]
        assert 'sparse' not in accessor
    doc['bufferViews']=views;doc['buffers']=[{'byteLength':len(data),'uri':path.stem+'.bin'}]
    (art/'assets'/(path.stem+'.bin')).write_bytes(data)
    target=art/'assets'/(path.stem+'.gltf');target.write_text(json.dumps(doc,separators=(',',':')))
    (art/'assets'/(path.stem+'.gltf.import')).write_text('[remap]\nimporter="scene"\ntype="PackedScene"\n[deps]\nsource_file="res://c6/assets/'+path.stem+'.gltf"\n[params]\nmeshes/generate_lods=false\nmeshes/create_shadow_meshes=false\nmeshes/force_disable_compression=true\n')
    audit.append({'source':path.name,'sha256':hashlib.sha256(blob).hexdigest(),'geometry_views_unchanged':len(views),'geometry_bytes':len(data)})
for path in (art/'textures').glob('*.png'):
    path.with_suffix('.png.import').write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n[deps]\nsource_file="res://c6/textures/'+path.name+'"\n[params]\ncompress/mode=0\nmipmaps/generate=true\nprocess/fix_alpha_border=false\n')
for name in ['adapter.gd','surface.gdshader','native_review.gd','kit.json']:shutil.copy2(recipe/name,art/name)
scene='[gd_scene load_steps=3 format=3]\n[ext_resource type="PackedScene" path="res://scenes/sandpit.tscn" id="1"]\n[ext_resource type="Script" path="res://c6/{script}.gd" id="2"]\n[node name="C6Review" instance=ExtResource("1")]\nscript=ExtResource("2")\n'
(art/'native_review.tscn').write_text(scene.format(script='native_review'))
for name in ['smithy_story','living_frontier_routes']:
    (art/(name+'.gd')).write_text('extends "res://tests/'+name+'.gd"\nvar c6_adapter: RefCounted\nfunc _build_world(seed_value: int) -> void:\n\tsuper._build_world(seed_value)\n\tc6_adapter=preload("res://c6/adapter.gd").new()\n\tc6_adapter.install(self)\n')
    (art/(name+'.tscn')).write_text(scene.format(script=name))
project=(game/'project.godot').read_text();project=project.replace('run/main_scene="res://scenes/sandpit.tscn"','run/main_scene="res://c6/native_review.tscn"')
(game/'project.godot').write_text(project)
(out/'cook.json').write_text(json.dumps({'models':audit,'textures':textures,'unique_texture_rgba8_mip_bytes':sum(t['rgba8_mip_bytes'] for t in textures.values())},indent=2)+'\n')
print('C6_PREPARED',out,len(audit),len(textures))
