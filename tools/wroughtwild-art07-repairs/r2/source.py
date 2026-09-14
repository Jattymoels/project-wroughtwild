"""Apply bounded R2 presentation changes to a fresh, verified G1 runtime.

No mesh regeneration. Texture aliases require identical PNG bytes AND complete
import parameters. GLB BIN chunks and every non-image JSON field stay identical.
"""
import argparse
import collections
import hashlib
import json
import os
import re
import struct
from pathlib import Path
from urllib.parse import quote, unquote
from measure import BUILD, ROOT, TOOLS, read, write, replace

ART_ROOTS={'b1','b2','b3','b4','c1','c2','c3','c4','c5','c6','d4','d5','d6','e1','e2','e3','f1','f2','f3','f4','f5','art07_d1','art07_d2','art07_d3','g1'}

def sha_bytes(data):return hashlib.sha256(data).hexdigest()
def sha(path):
    with path.open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()

def art_path(name):
    parts=Path(name).parts
    return len(parts)>1 and parts[0]=='game' and (parts[1] in ART_ROOTS or (len(parts)>3 and parts[1:3]==('assets','authored') and parts[3] in ART_ROOTS))

def import_parameters(path):
    if not path.is_file():return None
    body=path.read_text(encoding='utf-8-sig')
    assert '[params]' in body,path
    return body.split('[params]',1)[1].strip().replace('\r\n','\n')

def glb_chunks(data):
    assert data[:4]==b'glTF' and struct.unpack_from('<I',data,4)[0]==2
    assert struct.unpack_from('<I',data,8)[0]==len(data)
    result=[];offset=12
    while offset<len(data):
        size,kind=struct.unpack_from('<II',data,offset);offset+=8
        result.append((kind,data[offset:offset+size]));offset+=size
    assert offset==len(data) and result[0][0]==0x4e4f534a
    return result

def make_glb(chunks,document):
    body=json.dumps(document,separators=(',',':'),ensure_ascii=False).encode()
    body+=b' '*((-len(body))%4)
    updated=[(chunks[0][0],body),*chunks[1:]]
    payload=b''.join(struct.pack('<II',len(b),kind)+b for kind,b in updated)
    return b'glTF'+struct.pack('<II',2,len(payload)+12)+payload

def main(version):
    base=BUILD/version;prepared=read(base/'prepared.json');runtime=Path(prepared['runtime'])
    assert runtime.is_relative_to(BUILD) and prepared['runtime_base']=='6bb2e044dcd0bf1788896aa2c19cdf56fee93522'
    assert not (base/'changes.json').exists(),'Use a fresh candidate.'
    rows=prepared['original_files'];changes=[]
    def change(name,data,functions,purpose,overlaps=()):
        path=runtime/name;before=path.read_bytes()
        assert sha_bytes(before)==rows[name]['sha256'],name
        if before==data:return
        path.write_bytes(data)
        changes.append({'path':name,'before_sha256':sha_bytes(before),'after_sha256':sha_bytes(data),'functions_or_settings':functions,'purpose':purpose,'overlaps':list(overlaps),'replacement_asset':None})
    name='game/b3/native_resource.gd';s=(runtime/name).read_text()
    s=replace(s,'\tvar along_x:=_visual_seed()%2==0','\t# Exact call-local samples: no retained terrain result can outlive a rebuild.\n\tvar r2_samples:Dictionary={}\n\tvar along_x:=_visual_seed()%2==0')
    s=replace(s,'terrain.rendered_height(position.x+p.x,position.z+p.z,position.y,1.25)','_r2_height(terrain,r2_samples,position.x+p.x,position.z+p.z)')
    s=replace(s,'terrain.rendered_height(position.x+sample.x,position.z+sample.z,position.y,1.25)','_r2_height(terrain,r2_samples,position.x+sample.x,position.z+sample.z)')
    s+='''
func _r2_height(terrain:Terrain, samples:Dictionary, x:float, z:float)->float:
	# Float64 array keys preserve the original scalar query coordinates exactly.
	# Vector2 would round them to float32 and could conflate nearby edge samples.
	var key:Array[float]=[x,z]
	if not samples.has(key):samples[key]=terrain.rendered_height(x,z,position.y,1.25)
	return samples[key]
'''
    change(name,s.encode(),['reproject','_r2_height'],'Reuse exact repeated terrain samples within one synchronous projection; unchanged triangles, sampling reach and safety checks.')
    name='game/b1/native_tree.gd';s=(runtime/name).read_text()
    s=replace(s,'var source_kind:=','static var r2_fit_radii:Dictionary={}\nvar source_kind:=')
    s=replace(s,'\tvar radius:=0.0','\tvar r2_fit_key:=source_kind+":"+str(art_burial)\n\tvar r2_scan:=not r2_fit_radii.has(r2_fit_key)\n\tvar radius:float=r2_fit_radii.get(r2_fit_key,0.0)')
    old='\t\t\tvar vertices:PackedVector3Array=mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]\n\t\t\tfor point in vertices:\n\t\t\t\tif point.y-art_burial>=.6 and point.y-art_burial<=1.9:radius=maxf(radius,Vector2(point.x,point.z).length())'
    new='\t\t\tif r2_scan:\n'+''.join('\t'+line+'\n' for line in old.splitlines()).rstrip('\n')
    s=replace(s,old,new)
    s=replace(s,'\tassert(radius>0)','\tassert(radius>0)\n\tr2_fit_radii[r2_fit_key]=radius')
    change(name,s.encode(),['_apply_visual','r2_fit_radii'],'Memoize the unchanged source-kind/burial fit measurement; retain per-instance work materials, exact fit formula and native body.',['r1: _apply_visual and revised fit/geometry; recompute this memo from the final R1 source, do not copy the whole R2 file over R1.'])
    # Exact content AND all import parameters determine equivalence, including
    # normal-map treatment, channel processing, mipmaps and size/compression.
    groups=collections.defaultdict(list)
    for name,row in rows.items():
        if art_path(name) and name.endswith('.png'):
            params=import_parameters(runtime/(name+'.import'))
            if params is not None:groups[(row['sha256'],sha_bytes(params.encode()))].append(name)
    aliases={}
    for names in groups.values():
        canonical=min(names,key=lambda n:(len(n),n))
        for name in names:
            if name!=canonical:aliases['res://'+name[5:]]='res://'+canonical[5:]
    write(runtime/'game/r2/texture-aliases.json',aliases)
    alias_records=[]
    for old,new in sorted(aliases.items()):
        old_name='game/'+old[6:];new_name='game/'+new[6:]
        assert rows[old_name]['sha256']==rows[new_name]['sha256']
        assert import_parameters(runtime/(old_name+'.import'))==import_parameters(runtime/(new_name+'.import'))
        alias_records.append({'from':old,'to':new,'png_sha256':rows[old_name]['sha256'],'import_parameters_sha256':sha_bytes(import_parameters(runtime/(old_name+'.import')).encode())})
    write(base/'texture-alias-proof.json',{'aliases':alias_records,'scope':'Identical bytes and import parameters; no PNG, mesh geometry, map dimensions, sampler roles or color-space declarations changed. Original redundant PNG files remain present for provenance/reconstruction.'})
    resources='''extends RefCounted
## R2 exact texture aliases; materials retain their original samplers and state.
static var aliases:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://r2/texture-aliases.json"))
static func resource(path:String)->Resource:
	return load(String(aliases.get(path,path)))
'''
    write(runtime/'game/r2/resources.gd',resources)
    # Dynamic material stems retain every original property and shader hint.
    consumers=[]
    for name in sorted(rows):
        if not art_path(name) or not name.endswith('.gd') or 'review' in name or 'check' in name:continue
        s=(runtime/name).read_text(encoding='utf-8-sig')
        if not any('load(' in line and '.png' in line for line in s.splitlines()):continue
        # These source adapters use dynamic PNG stems. Preserve non-texture load
        # behavior, including PackedScenes; only exact alias-table keys redirect.
        assert 'ResourceLoader.load(' not in s,name
        s=re.sub(r'(?<![A-Za-z_])load\(', 'R2Resources.resource(',s)
        s+='\nconst R2Resources=preload("res://r2/resources.gd")\n'
        change(name,s.encode(),['existing material/texture loaders','R2Resources.resource'],'Resolve byte-and-import-identical texture paths to one engine resource without sharing mutable work materials.',['r3: building material roles/paths; regenerate aliases after composed maps.','r7: supporting art texture references; regenerate aliases after composed sources.'])
        consumers.append(name)
    # Rebind source scene image references. Preserve all geometry, materials,
    # transforms, samplers, animations and binary buffers byte-for-byte.
    rebindings=[]
    for name in sorted(rows):
        if not art_path(name) or not name.endswith(('.gltf','.glb')):continue
        path=runtime/name;before=path.read_bytes();chunks=glb_chunks(before) if name.endswith('.glb') else None
        original=json.loads(chunks[0][1] if chunks else before)
        document=json.loads(json.dumps(original));bindings=[]
        for i,img in enumerate(document.get('images',[])):
            old_file=None
            if 'uri' in img and not img['uri'].startswith('data:'):
                old_file=(path.parent/unquote(img['uri'])).resolve()
            elif chunks and 'bufferView' in img:
                # Godot's retained extraction name is grounded in an actual
                # prepared PNG, never guessed into existence or newly generated.
                candidate=path.with_name(path.stem+'_'+img.get('name','Image_'+str(i))+'.png')
                if candidate.is_file():
                    view=document['bufferViews'][img['bufferView']]
                    assert view.get('buffer',0)==0
                    binary=next(data for kind,data in chunks if kind==0x004e4942)
                    raw=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
                    if sha_bytes(raw)==sha(candidate):old_file=candidate.resolve()
            if old_file is None or not old_file.is_relative_to(runtime.resolve()):continue
            resource='res://'+old_file.relative_to(runtime/'game').as_posix()
            if resource not in aliases:continue
            target=runtime/'game'/aliases[resource][6:]
            uri=quote(os.path.relpath(target,path.parent).replace('\\','/'),safe='/._-')
            img.pop('bufferView',None);img.pop('mimeType',None);img['uri']=uri
            bindings.append({'image':i,'from':resource,'to':aliases[resource]})
        if not bindings:continue
        assert {k:v for k,v in original.items() if k!='images'}=={k:v for k,v in document.items() if k!='images'}
        after=make_glb(chunks,document) if chunks else json.dumps(document,separators=(',',':'),ensure_ascii=False).encode()
        if chunks:assert glb_chunks(after)[1:]==chunks[1:]
        overlap=[]
        if name.startswith(('game/b1/','game/c4/')):overlap.append('r1: source images/GLB packaging; apply image aliases to final R1 geometry, preserving its BIN data.')
        if name.startswith(('game/b2/','game/b4/','game/c6/')):overlap.append('r7: source image packaging; recompute aliases on final retained-anchor assets.')
        if '/art07_d' in name:overlap.append('r3: source image packaging; preserve final R3 material roles and geometry.')
        change(name,after,['glTF images[].uri only'],'Reference one equivalent imported texture; all non-image JSON fields and original GLB BIN chunks preserved.',overlap)
        rebindings.append({'path':name,'images':bindings,'non_image_json_equal':True,'glb_non_json_chunks_sha256':[sha_bytes(data) for kind,data in chunks[1:]] if chunks else []})
    write(base/'image-reference-proof.json',rebindings)
    additions=[]
    for path in sorted((runtime/'game/r2').glob('*')):
        if path.name in ['resources.gd','texture-aliases.json']:
            additions.append({'path':path.relative_to(runtime).as_posix(),'before_sha256':None,'after_sha256':sha(path),'functions_or_settings':['exact texture alias lookup'],'purpose':'Share equivalent immutable texture resources; preserve every per-instance material/state owner.','overlaps':['r1/r3/r7: regenerate alias table from final composed source bytes and import settings.'],'replacement_asset':None})
    write(base/'changes.json',{'id':'r2','delta_base':prepared['source'],'runtime_base':prepared['runtime_base'],'parent_candidates':[],'files':changes+additions,'tuning_values':[],'application':'Run source.py only against a fresh matching prepared G1 runtime. For R8 compose functions then regenerate lossless texture aliases from the final sources; whole-file last-writer copying is prohibited.'})
    print('R2_CANDIDATE_APPLIED',len(changes),'changed sources;',len(aliases),'exact texture aliases;',len(rebindings),'source scene reference derivatives;',len(consumers),'material loaders')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',required=True);a=p.parse_args();main(a.version)
