"""Audit the actual exported GLBs, texture headers, evidence and preservation.

-- REVIEW OUTPUT_JSON
Uses existing NumPy/Pillow, reads source and preserved game assets only.
"""
import hashlib,json,struct,sys
from pathlib import Path
import numpy as np
from PIL import Image

review,output=[Path(p).resolve() for p in sys.argv[1:]]
repo=Path(__file__).resolve().parents[2]
config=json.loads((review/'boar-study.json').read_text())
rig=json.loads((review/'rig-report.json').read_text())
preserved={config['source']:config['source_sha256'],
 'game/assets/authored/mobs/ash_hound.glb':'ec2cded39e9414591991be589608235d20884ff96c020e4bcbc33a6cdd0f0354',
 'game/assets/authored/mobs/marsh_wisp.glb':'554ec16fe3c7154239682da327d717f694a7ff20c430d27cbaca0266a749e389',
 'art/blender/augmented-beasts-v01.blend':'364d616f69bb7b716ac3b7287372b0c5f016f4d99600e4783c992e9c13a2218c'}
for file,digest in preserved.items():assert hashlib.sha256((repo/file).read_bytes()).hexdigest()==digest,file
results=[]
expected_counts={v['name']:v['triangles'] for v in rig['variants']}
expected_counts['far']=json.loads((review/'far-report.json').read_text())['final_triangles']
for detail in ['near','mid','far']:
    expected=expected_counts[detail]
    file=review/('boar-'+detail+'.glb');data=file.read_bytes()
    assert data[:4]==b'glTF' and struct.unpack_from('<II',data,4)==(2,len(data))
    length=struct.unpack_from('<I',data,12)[0];doc=json.loads(data[20:20+length]);binary=data[28+length:]
    def array(index):
        acc=doc['accessors'][index];view=doc['bufferViews'][acc['bufferView']]
        dtype={5121:'u1',5123:'<u2',5125:'<u4',5126:'<f4'}[acc['componentType']]
        components={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[acc['type']]
        assert not acc.get('sparse') and not view.get('byteStride')
        return np.frombuffer(binary,dtype=dtype,count=acc['count']*components,offset=view.get('byteOffset',0)+acc.get('byteOffset',0)).reshape((-1,components))
    assert len(doc['meshes'])==1 and len(doc['skins'])==1 and len(doc['skins'][0]['joints'])==16
    primitives=doc['meshes'][0]['primitives'];assert len(primitives)==1
    primitive=primitives[0];attributes=primitive['attributes']
    positions=array(attributes['POSITION']);weights=array(attributes['WEIGHTS_0']);joints=array(attributes['JOINTS_0'])
    assert np.isfinite(positions).all() and np.isfinite(weights).all()
    assert weights.min()>=0 and np.max(np.abs(weights.sum(1)-1))<1e-5
    assert joints.max()<16 and len(array(attributes['TEXCOORD_0']))==len(positions)
    indices=array(primitive['indices']);triangles=len(indices)//3
    assert triangles==expected and indices.max()<len(positions)
    clips={a['name']:float(max(array(s['input']).max() for s in a['samplers'])) for a in doc['animations']}
    assert set(clips)==set(rig['clips_seconds'])
    for name,duration in clips.items():assert abs(duration-rig['clips_seconds'][name])<1e-6
    assert not any(any(m.get('emissiveFactor',[0,0,0])) for m in doc['materials']),'Whole-body fallback emission'
    for image in doc['images']:
        view=doc['bufferViews'][image['bufferView']];offset=view.get('byteOffset',0)
        assert image['mimeType']=='image/png' and binary[offset:offset+8]==b'\x89PNG\r\n\x1a\n'
    results.append({'lod':detail,'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'triangles':triangles,'exported_vertices_after_uv_normal_splits':len(positions),'surfaces':1,'bones':16,'clips_seconds':clips,'bounds_min':positions.min(0).tolist(),'bounds_max':positions.max(0).tolist()})
textures=[]
for name in ['base.png','orm.png','scar-mask.png','normal.png','far-base.png','far-orm.png','far-scar.png','far-normal.png']:
    file=review/name;data=file.read_bytes();assert data[:8]==b'\x89PNG\r\n\x1a\n'
    im=Image.open(file);im.load()
    textures.append({'name':name,'size':list(im.size),'png_bits_per_channel':data[24],'bytes':len(data)})
output.write_text(json.dumps({'exports':results,'textures':textures,'preserved_sha256':preserved,'note':'Checks inspect the actual GLB streams; source-rig far collapse results are superseded by the separate rebaked far export.'},indent=2)+'\n')
print('BOAR_HANDOFF_VALIDATION_OK')
