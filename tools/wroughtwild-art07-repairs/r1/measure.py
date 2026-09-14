"""R1 guarded paths, source checks and direct glTF geometry measurement."""
import hashlib, json, struct, sys, os
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[3]
VERSION=os.environ.get('WW_R1_VERSION','v03')
assert __import__('re').fullmatch(r'v[0-9]{2,3}',VERSION)
OUT=ROOT/'build/art07-repairs/r1'/VERSION
GAME=OUT/'runtime/game'
INPUTS=json.loads((ROOT/'docs/prototype/art07-repairs/2026-09-14/inputs.json').read_text())
def sha(p):
    with Path(p).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def write(p,data):
    p=Path(p).resolve();assert p.is_relative_to(ROOT.resolve())
    p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('x',encoding='utf-8',newline='\n') as f:json.dump(data,f,indent=2)
def model(path):
    path=Path(path);raw=path.read_bytes()
    if path.suffix=='.glb':
        assert raw[:4]==b'glTF'
        n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n]);blob=raw[28+n:]
        buffers=[blob]
    else:
        doc=json.loads(raw);buffers=[(path.parent/b['uri']).read_bytes() for b in doc['buffers']]
    def accessor(i):
        a=doc['accessors'][i];v=doc['bufferViews'][a['bufferView']]
        dtype={5126:'<f4',5125:'<u4',5123:'<u2',5121:'u1',5122:'<i2',5120:'i1'}[a['componentType']]
        count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']];size=np.dtype(dtype).itemsize
        return np.ndarray((a['count'],count),dtype=dtype,buffer=buffers[v.get('buffer',0)],offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',size*count),size)).copy()
    rows=[]
    def walk(i,parent):
        node=doc['nodes'][i];matrix=np.eye(4)
        if 'matrix' in node:matrix=np.array(node['matrix']).reshape(4,4).T
        else:
            x,y,z,w=node.get('rotation',[0,0,0,1]);matrix[:3,:3]=[[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],[2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],[2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]]
            matrix[:3,:3]=matrix[:3,:3]@np.diag(node.get('scale',[1,1,1]));matrix[:3,3]=node.get('translation',[0,0,0])
        matrix=parent@matrix
        if 'mesh' in node:
            mesh=doc['meshes'][node['mesh']]
            for p in mesh['primitives']:
                pos=accessor(p['attributes']['POSITION']).astype(float);pos=pos@matrix[:3,:3].T+matrix[:3,3]
                indices=accessor(p['indices']).ravel() if 'indices' in p else np.arange(len(pos))
                assert np.isfinite(pos).all()
                rows.append({'name':node.get('name',mesh.get('name','mesh')),'positions':pos,'triangles':len(indices)//3,'material':p.get('material')})
        for j in node.get('children',[]):walk(j,matrix)
    for i in doc['scenes'][doc.get('scene',0)]['nodes']:walk(i,np.eye(4))
    return doc,rows

def bounds(points):
    if not len(points):return None
    return {'vertices':len(points),'min_m':points.min(0).tolist(),'max_m':points.max(0).tolist(),'size_m':np.ptp(points,axis=0).tolist(),'max_radius_m':float(np.linalg.norm(points[:,[0,2]],axis=1).max())}
def bands(points):
    return {'whole':bounds(points),'roots_below_0_6':bounds(points[points[:,1]<.6]),'walk_0_6_to_1_9':bounds(points[(points[:,1]>=.6)&(points[:,1]<=1.9)]),'lower_0_to_2_6':bounds(points[(points[:,1]>=0)&(points[:,1]<=2.6)]),'crown_above_2_6':bounds(points[points[:,1]>2.6])}
if __name__=='__main__':
    rows=[]
    for kind in ['broadleaf','pine']:
        path=GAME/'b1/assets'/f'{kind}-a-lod2.glb';doc,meshes=model(path);pts=np.concatenate([m['positions'] for m in meshes]);pts[:,1]-={'broadleaf':.65,'pine':.55}[kind]
        s=.343/bands(pts)['walk_0_6_to_1_9']['max_radius_m'];narrow=pts.copy();narrow[:,[0,2]]*=s
        rows.append({'kind':kind,'file':str(path),'sha256':sha(path),'triangles':sum(m['triangles'] for m in meshes),'source':bands(pts),'g1_horizontal_scale':s,'g1_delivered':bands(narrow),'parts':[{'name':m['name'],'triangles':m['triangles']} for m in meshes]})
    path=GAME/'c4/assets/ash-a-lod2.gltf';doc,meshes=model(path);pts=np.concatenate([m['positions'] for m in meshes])
    rows.append({'kind':'ash','file':str(path),'sha256':sha(path),'source_and_delivered':bands(pts),'triangles':sum(m['triangles'] for m in meshes)})
    write(OUT/'evidence/baseline-shapes.json',{'coordinates':'Godot metres after unchanged source burial; instance yaw varies in retained world','models':rows,'player':{'capsule_radius_m':.42,'capsule_height_m':1.92,'eye_above_center_m':.72,'eye_above_feet_m':1.68}})
    for r in rows:print(json.dumps(r))
