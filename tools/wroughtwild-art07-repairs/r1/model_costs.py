"""CPU audit of every delivered export: height/triangles and actual embedded maps."""
import collections,hashlib,io,json,struct
from pathlib import Path
import numpy as np
from PIL import Image
from measure import OUT,model,bands,sha,write

def maps(path):
    raw=path.read_bytes();n=struct.unpack_from('<I',raw,12)[0]
    doc=json.loads(raw[20:20+n]);blob=raw[28+n:];rows=[]
    for image in doc.get('images',[]):
        assert 'bufferView' in image
        v=doc['bufferViews'][image['bufferView']];offset=v.get('byteOffset',0)
        data=blob[offset:offset+v['byteLength']]
        with Image.open(io.BytesIO(data)) as im:
            rows.append({'name':image.get('name'),'size':list(im.size),'encoded_bytes':len(data),'encoded_sha256':hashlib.sha256(data).hexdigest(),'rgba_sha256':hashlib.sha256(im.convert('RGBA').tobytes()).hexdigest()})
    return rows
rows=[]
for kind in ['broadleaf','pine']:
    for p in sorted((OUT/'models'/kind).glob('*.glb')):
        before=OUT/'sources/b1/models'/kind/p.name
        old_doc,old_parts=model(before);new_doc,new_parts=model(p)
        old=np.concatenate([m['positions'] for m in old_parts]);new=np.concatenate([m['positions'] for m in new_parts])
        burial=.65 if kind=='broadleaf' else .55;old[:,1]-=burial;new[:,1]-=burial
        old_tri=sum(m['triangles'] for m in old_parts);new_tri=sum(m['triangles'] for m in new_parts)
        assert old_tri==new_tri
        assert np.allclose([old[:,1].min(),old[:,1].max()],[new[:,1].min(),new[:,1].max()],atol=1e-5,rtol=0)
        a=maps(before);b=maps(p)
        # Shared exporter images may be deduplicated; all unique decoded maps must survive.
        assert {x['rgba_sha256'] for x in a}=={x['rgba_sha256'] for x in b},p.name
        rows.append({'file':p.name,'source_sha256':sha(before),'sha256':sha(p),'source_glb_bytes':before.stat().st_size,'glb_bytes':p.stat().st_size,'triangles':new_tri,'source_triangles':old_tri,'surfaces':len(new_parts),'source_surfaces':len(old_parts),'height_extremes_preserved':True,'source_maps':a,'maps':b,'unique_decoded_maps_preserved':True,'bands':bands(new)})
write(OUT/'evidence/model-costs.json',{'exports':rows,'scope':'Actual GLB embedded images and exported geometry. Runtime total loaded GPU allocations are measured separately by views.gd.'})
print('R1_MODEL_COSTS_OK',len(rows),'exports; all decoded maps and height extrema retained')
for r in rows:
    if '-a-lod2' in r['file']:print(r['file'],r['triangles'],r['source_glb_bytes'],r['glb_bytes'],[x['size'] for x in r['maps']])
