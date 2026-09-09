"""Inspect real GLB streams, skins, maps, evidence and preserved sources.
Run with the existing Python/NumPy/Pillow runtime: REVIEW wolf|stag OUTPUT.json.
"""
import hashlib,json,struct,sys
from pathlib import Path
import numpy as np
from PIL import Image
review=Path(sys.argv[1]).resolve();kind=sys.argv[2];output=Path(sys.argv[3]).resolve()
repo=Path(__file__).resolve().parents[2]
cfg=json.loads((review/(kind+'.json')).read_text(encoding='utf-8'))
rig=json.loads((review/'rig-report.json').read_text(encoding='utf-8'))
preserved={cfg['source']:cfg['source_sha256'],
 'game/assets/authored/mobs/ash_hound.glb':'ec2cded39e9414591991be589608235d20884ff96c020e4bcbc33a6cdd0f0354',
 'game/assets/authored/mobs/marsh_wisp.glb':'554ec16fe3c7154239682da327d717f694a7ff20c430d27cbaca0266a749e389',
 'build/trellis-local/normalized-review/wolf-normalized.glb':'0245276461c8562f26a6053a58d8bc831a70ab8238498b22d1568e6e8ea9a9e0'}
checks=[]
def check(name,passed,detail=None):
    checks.append({'name':name,'passed':bool(passed),'detail':detail})
for path,digest in preserved.items():check('preserved '+path,hashlib.sha256((repo/path).read_bytes()).hexdigest()==digest)
exports=[]
for level in ['near','mid','far']:
    file=review/(kind+'-'+level+'.glb');data=file.read_bytes()
    assert data[:4]==b'glTF' and struct.unpack_from('<II',data,4)==(2,len(data))
    length=struct.unpack_from('<I',data,12)[0];doc=json.loads(data[20:20+length]);binary=data[28+length:]
    def array(index):
        acc=doc['accessors'][index];view=doc['bufferViews'][acc['bufferView']]
        dtype={5121:'u1',5123:'<u2',5125:'<u4',5126:'<f4'}[acc['componentType']]
        count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[acc['type']]
        assert not acc.get('sparse') and not view.get('byteStride')
        return np.frombuffer(binary,dtype=dtype,count=acc['count']*count,offset=view.get('byteOffset',0)+acc.get('byteOffset',0)).reshape((-1,count))
    triangles=0;vertices=0;surfaces=0;zero=0
    for node in doc['nodes']:
        if 'mesh' not in node:continue
        check(level+' mesh skinned '+node.get('name',''), 'skin' in node)
        joints_count=len(doc['skins'][node['skin']]['joints'])
        for primitive in doc['meshes'][node['mesh']]['primitives']:
            attributes=primitive['attributes'];p=array(attributes['POSITION']);weights=array(attributes['WEIGHTS_0']);joints=array(attributes['JOINTS_0'])
            idx=array(primitive['indices']).ravel().reshape(-1,3);assert idx.max()<len(p)
            area=np.linalg.norm(np.cross(p[idx[:,1]]-p[idx[:,0]],p[idx[:,2]]-p[idx[:,0]]),axis=1)*.5
            zero+=int((area<=1e-14).sum());triangles+=len(idx);vertices+=len(p);surfaces+=1
            check(level+' finite surface '+str(surfaces),np.isfinite(p).all() and np.isfinite(weights).all())
            check(level+' skin weights '+str(surfaces),weights.min()>=0 and np.max(abs(weights.sum(1)-1))<1e-5 and joints.max()<joints_count)
            check(level+' valid UVs '+str(surfaces),'TEXCOORD_0' in attributes and np.isfinite(array(attributes['TEXCOORD_0'])).all())
    check(level+' nonzero triangles',zero==0,{'near_zero_area_triangles':zero,'area_epsilon_m2':1e-14})
    check(level+' complete rig',max(len(s['joints']) for s in doc['skins'])==len(rig['bones']))
    clips={a['name']:float(max(array(s['input']).max() for s in a['samplers'])) for a in doc['animations']}
    check(level+' complete clips',set(clips)==set(rig['clips_seconds']))
    for name,duration in clips.items():check(level+' duration '+name,abs(duration-rig['clips_seconds'][name])<1e-6)
    check(level+' safe PBR fallback',not any(any(m.get('emissiveFactor',[0,0,0])) for m in doc['materials']))
    for im in doc.get('images',[]):
        view=doc['bufferViews'][im['bufferView']];offset=view.get('byteOffset',0)
        check(level+' embedded PNG '+im.get('name',''),im['mimeType']=='image/png' and binary[offset:offset+8]==b'\x89PNG\r\n\x1a\n')
    exports.append({'level':level,'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'triangles':triangles,'exported_vertices':vertices,'surfaces':surfaces,'bones':len(rig['bones']),'clips_seconds':clips})
textures=[]
for name in ['base.png','orm.png','normal.png','scar-mask.png']:
    data=(review/name).read_bytes();im=Image.open(review/name);im.load()
    check(name+' decodes PNG',data[:8]==b'\x89PNG\r\n\x1a\n')
    textures.append({'name':name,'size':list(im.size),'bits_per_channel':data[24],'bytes':len(data)})
mark=np.array(Image.open(review/'scar-mask.png').convert('RGB'))
check('independent core and host damage',np.any(mark[:,:,0]!=mark[:,:,1]) and np.any(mark[:,:,0]>180) and np.any(mark[:,:,1]>180))
check('branch travel varies',len(np.unique(mark[:,:,2][mark[:,:,0]>80]))>20)
report={'kind':kind,'checks':checks,'passed':sum(c['passed'] for c in checks),'failed':sum(not c['passed'] for c in checks),'exports':exports,'textures':textures,'preserved_sha256':preserved,'limitations':'Stream validation is not watertightness, self-intersection certification, manual retopology or native-game integration.'}
output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'passed':report['passed'],'failed':report['failed'],'exports':exports}))
assert not report['failed'],[c for c in checks if not c['passed']]
