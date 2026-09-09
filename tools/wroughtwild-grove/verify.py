"""Inspect the actual GLB streams, maps, route and rendered evidence."""
import hashlib, json, struct, sys
from pathlib import Path
import numpy as np
from PIL import Image
review, output=map(Path,sys.argv[1:])
repo=Path(__file__).resolve().parents[2]
results=[]
def check(label,value):
    results.append({'check':label,'passed':bool(value)})
    assert value,label
def glb(path):
    b=path.read_bytes();magic,version,length=struct.unpack_from('<III',b)
    check(path.name+' valid header',magic==0x46546c67 and version==2 and length==len(b))
    n=struct.unpack_from('<I',b,12)[0];doc=json.loads(b[20:20+n]);binary=b[28+n:]
    def array(index):
        a=doc['accessors'][index];view=doc['bufferViews'][a['bufferView']]
        dtype={5121:'u1',5123:'<u2',5125:'<u4',5126:'<f4'}[a['componentType']]
        dim={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
        stride=view.get('byteStride',np.dtype(dtype).itemsize*dim)
        return np.ndarray((a['count'],dim),dtype=dtype,buffer=binary,offset=view.get('byteOffset',0)+a.get('byteOffset',0),strides=(stride,np.dtype(dtype).itemsize))
    return doc,array
stats={}
for path in sorted(review.glob('*.glb')):
    doc,array=glb(path);triangles=vertices=slivers=0;lo=np.full(3,np.inf);hi=-lo
    for mesh in doc['meshes']:
        for p in mesh['primitives']:
            pos=array(p['attributes']['POSITION']);indices=array(p['indices']).reshape(-1)
            check(path.name+' finite coordinates and valid indices',np.isfinite(pos).all() and len(indices)%3==0 and indices.max()<len(pos))
            lo=np.minimum(lo,pos.min(0));hi=np.maximum(hi,pos.max(0));vertices+=len(pos);triangles+=len(indices)//3
            tri=pos[indices.reshape(-1,3)];areas=np.linalg.norm(np.cross(tri[:,1]-tri[:,0],tri[:,2]-tri[:,0]),axis=1)
            slivers+=int((areas<1e-12).sum())
            if path.stem in ['canopy','canopy-far','understory','terrain','deadfall']:
                check(path.name+' exported linear colour and two UV channels',all(k in p['attributes'] for k in ['COLOR_0','TEXCOORD_0','TEXCOORD_1']))
    stats[path.name]={'triangles':triangles,'exported_vertices':vertices,'material_count':len(doc.get('materials',[])),'bounds':[lo.tolist(),hi.tolist()],'near_zero_area_triangles':slivers,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
check('Distant canopy reduces triangles',stats['canopy-far.glb']['triangles']<stats['canopy.glb']['triangles']*.35)
check('Quiet and altered tree keep triangle count',stats['quiet-tree.glb']['triangles']==stats['altered-tree.glb']['triangles'])
for name in ['tree-base.png','tree-orm.png','tree-scar.png','tree-normal.png','rock-base.png','rock-orm.png','rock-scar.png','forest-floor.png','base.png','orm.png','scar-mask.png','normal.png']:
    im=Image.open(review/name);im.load();check(name+' decodes as PNG',im.format=='PNG' and min(im.size)>512)
for name in ['tree-scar.png','rock-scar.png']:
    a=np.array(Image.open(review/name).convert('RGB'))
    check(name+' narrow nonempty core and independent dark margin',0<(a[:,:,0]>30).mean()<.06 and (a[:,:,1]>30).mean()>(a[:,:,0]>30).mean())
checks=json.loads((review/'evidence/checks.json').read_text())
check('153 route samples with no collision failures',checks['route_points']==153 and not checks['route_support_and_capsule_failures'])
check('Actual capsule completes the route',checks['physical_walk']['completed'] and checks['physical_walk']['maximum_support_error_m']<.06)
check('Independent project and paused clock',checks['isolated_no_game_extension'] and checks['pause_clock_unchanged'])
captures=json.loads((review/'evidence/capture-manifest.json').read_text())
for shot in captures:
    im=Image.open(review/'evidence'/(shot['name']+'.png')).convert('RGB');a=np.array(im)
    check(shot['name']+' real nonblank 1440x900 image',im.size==(1440,900) and a.std()>12)
on=np.array(Image.open(review/'evidence/scar-shade.png').convert('RGB')).astype(int)
off=np.array(Image.open(review/'evidence/scar-unlit.png').convert('RGB')).astype(int)
delta=np.abs(on-off).max(2)
check('Matched glow-off changes a small nonempty region',0.0001<(delta>12).mean()<.10)
preserve={
'build/grove-art02/tree-source-v01/tree.glb':'d3931de79e69c609958ed0807d93d4b45217bdb50f7d1a59d4862e8f92214f30',
'build/grove-art02/rock-source-v01/rock.glb':'6185f02594ec0d064d9750fa28fe33603c513361f0a96a65512ff9668c721322',
'build/trellis-local/studio/data/output/Screenshot 2026-09-08 224118_1024_seed42_mtsp0zp4-77uj0z.glb':'2a889ab30879bf6a4854ebe6def3e1b696d8a411ffaee6f215c7398bebe7abef',
'game/assets/authored/mobs/ash_hound.glb':'ec2cded39e9414591991be589608235d20884ff96c020e4bcbc33a6cdd0f0354',
'game/assets/authored/mobs/marsh_wisp.glb':'554ec16fe3c7154239682da327d717f694a7ff20c430d27cbaca0266a749e389'}
for name,digest in preserve.items():check(name+' preserved',hashlib.sha256((repo/name).read_bytes()).hexdigest()==digest)
output.write_text(json.dumps({'checks':results,'passed':len(results),'assets':stats,'glow_changed_pixel_fraction':float((delta>12).mean()),'limitations':'Stream checks report microscopic slivers; they do not certify watertight generated topology or normal-game adoption.'},indent=2)+'\n')
print('GROVE_VERIFIED',len(results))
