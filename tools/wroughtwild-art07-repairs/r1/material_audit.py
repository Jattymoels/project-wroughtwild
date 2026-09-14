"""Resolve the Blender sampler warning against actual exported glTF bindings."""
import collections,json,struct
from pathlib import Path
from measure import OUT,write

def header(path):
    with path.open('rb') as f:
        f.seek(12);n=struct.unpack('<I',f.read(4))[0];f.seek(20)
        return json.loads(f.read(n))

def bindings(doc,images):
    textures=[]
    for t in doc.get('textures',[]):
        textures.append({'sampler':doc.get('samplers',[])[t['sampler']] if 'sampler' in t else {},'decoded_image_sha256':images[t['source']]['rgba_sha256']})
    def normalise(value):
        if isinstance(value,list):return [normalise(x) for x in value]
        if not isinstance(value,dict):return value
        result={}
        for k,v in value.items():
            if k.endswith('Texture') and isinstance(v,dict) and 'index' in v:
                result[k]={**{a:b for a,b in v.items() if a!='index'},'texture':textures[v['index']]}
            else:result[k]=normalise(v)
        return result
    materials=[json.dumps(normalise({k:v for k,v in m.items() if k!='name'}),sort_keys=True) for m in doc.get('materials',[])]
    triangles=collections.Counter()
    for mesh in doc['meshes']:
        for p in mesh['primitives']:
            assert p.get('mode',4)==4
            n=doc['accessors'][p['indices']]['count'] if 'indices' in p else doc['accessors'][p['attributes']['POSITION']]['count']
            triangles[materials[p['material']]]+=n//3
    return collections.Counter(materials),triangles

rows=[]
for costs in json.loads((OUT/'evidence/model-costs.json').read_text())['exports']:
    kind='pine' if costs['file'].startswith('pine') else 'broadleaf'
    old=header(OUT/'sources/b1/models'/kind/costs['file']);new=header(OUT/'models'/kind/costs['file'])
    a,at=bindings(old,costs['source_maps']);b,bt=bindings(new,costs['maps'])
    assert a==b,(costs['file'],'material semantics differ')
    assert at==bt,(costs['file'],'material-assigned triangle totals differ')
    assert old.get('samplers',[])==new.get('samplers',[])
    rows.append({'file':costs['file'],'material_properties_texture_bindings_and_sampler_settings_equal':True,'triangle_totals_by_material_equal':True,'samplers':new.get('samplers',[]),'source_material_names':[m['name'] for m in old['materials']],'candidate_material_names':[m['name'] for m in new['materials']]})
write(OUT/'evidence/material-bindings.json',{'exports':rows,'scope':'Blender may reorder or suffix material names. Actual material properties, decoded image bindings, sampler settings and triangle totals assigned to each material must match the source. This does not suppress exporter warnings.'})
print('R1_MATERIAL_BINDINGS_OK',len(rows),'exports')