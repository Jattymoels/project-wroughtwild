"""Fresh copied current game plus shared-texture ore study. No ordinary project edits."""
import json,sys,shutil,struct,hashlib,subprocess,zipfile
from pathlib import Path
kit,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);assert not out.exists();out.mkdir(parents=True)
recipe=Path(__file__).parent;rev='4b5d89b376765fbf4d46049aa099e0bb154a82da'
archive=out/'base.zip';subprocess.run(['git','archive','--format=zip','--output='+str(archive),rev,'game','data'],check=True)
with zipfile.ZipFile(archive) as z:z.extractall(out)
game=out/'game';art=game/'c5';(art/'assets').mkdir(parents=True);(art/'textures').mkdir()
dll=Path('C:/Users/Matty/Dev/project-wroughtwild/build/art07/b3/worktree/build/art07/b3/v01/handoff-v02/native/game/bin/libwroughtwild_sim.windows.x86_64.dll')
assert hashlib.sha256(dll.read_bytes()).hexdigest()=='6d8094fc95c0854f9100b161806a11d9fa3a67bb4f870080976bcd8d2e8f2279'
shutil.copy2(dll,game/'bin'/dll.name)
cooked=[]
for path in sorted(kit.glob('*.glb')):
    blob=path.read_bytes();jlen=struct.unpack_from('<I',blob,12)[0];doc=json.loads(blob[20:20+jlen]);binary=blob[28+jlen:];views=doc['bufferViews'];imageviews={i['bufferView'] for i in doc.get('images',[]) if 'bufferView' in i}
    data=bytearray();new=[];mapping={}
    for idx,v in enumerate(views):
        if idx in imageviews:continue
        while len(data)%4:data.append(0)
        payload=binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']];nv=dict(v);nv['byteOffset']=len(data);mapping[idx]=len(new);new.append(nv);data.extend(payload)
        assert bytes(data[nv['byteOffset']:nv['byteOffset']+nv['byteLength']])==payload
    for acc in doc.get('accessors',[]):
        if 'bufferView' in acc:acc['bufferView']=mapping[acc['bufferView']]
        assert 'sparse' not in acc
    for key in ['images','textures','samplers']:doc.pop(key,None)
    # The ore shader implements the authored look explicitly (renderer-dependent lighting);
    # generic glTF material fallback must not introduce duplicate embedded maps.
    doc['materials']=[{'name':m.get('name','ore'),'pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1],'metallicFactor':0,'roughnessFactor':1}} for m in doc.get('materials',[])]
    doc['bufferViews']=new;doc['buffers']=[{'byteLength':len(data),'uri':path.stem+'.bin'}]
    (art/'assets'/(path.stem+'.bin')).write_bytes(data);(art/'assets'/(path.stem+'.gltf')).write_text(json.dumps(doc,separators=(',',':')))
    (art/'assets'/(path.stem+'.gltf.import')).write_text('[remap]\nimporter="scene"\ntype="PackedScene"\n[deps]\nsource_file="res://c5/assets/'+path.stem+'.gltf"\n[params]\nmeshes/generate_lods=false\nmeshes/create_shadow_meshes=false\nmeshes/force_disable_compression=true\n')
    cooked.append({'source':path.name,'sha256':hashlib.sha256(blob).hexdigest(),'geometry_bytes':len(data),'unchanged_views':len(new)})
for name in ['rock-albedo.png','rock-orm.png']:
    shutil.copy2(kit/name,art/'textures'/name)
    (art/'textures'/(name+'.import')).write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n[deps]\nsource_file="res://c5/textures/'+name+'"\n[params]\ncompress/mode=0\nmipmaps/generate=true\nprocess/fix_alpha_border=false\n')
for p in recipe.iterdir():
    if p.suffix in ['.gd','.gdshader','.json']:shutil.copy2(p,art/p.name)
for name in ['review','native_review']:
    (art/(name+'.tscn')).write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://c5/'+name+'.gd" id="1"]\n[node name="C5" type="Node3D"]\nscript=ExtResource("1")\n')
project=game/'project.godot';text=project.read_text();text=text.replace('run/main_scene="res://scenes/sandpit.tscn"','run/main_scene="res://c5/review.tscn"');project.write_text(text)
(out/'cook.json').write_text(json.dumps({'base':rev,'models':cooked,'texture_images':2,'texture_dimensions':[1024,1024],'estimated_rgba8_with_mips_bytes':2*1024*1024*4*4//3,'geometry_unchanged':True},indent=2)+'\n');print('C5_PREPARED',len(cooked))
