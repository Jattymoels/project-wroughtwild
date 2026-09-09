"""Independent cut-surface boundary/UV audit of exported GLBs (no renderer)."""
import json,struct,sys
from pathlib import Path
import numpy as np
root,out=map(Path,sys.argv[1:]);rows=[]
for folder in ['broadleaf-kit-v05','pine-kit-v03']:
 for p in sorted((root/folder).glob('*.glb')):
  if 'lod' in p.name:continue
  data=p.read_bytes();n=struct.unpack_from('<I',data,12)[0];doc=json.loads(data[20:20+n]);blob=data[28+n:]
  def arr(index):
   a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']];size={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']];dtype={5126:'<f4',5125:'<u4',5123:'<u2',5121:'u1'}[a['componentType']]
   return np.ndarray((a['count'],size),dtype=dtype,buffer=blob,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',np.dtype(dtype).itemsize*size),np.dtype(dtype).itemsize))
  vertices=[];faces=[];cap=[];uvs=[]
  for me in doc['meshes']:
   for prim in me['primitives']:
    pos=arr(prim['attributes']['POSITION']);tri=arr(prim['indices']).reshape(-1,3)+len(vertices);is_cap='cut wood' in doc['materials'][prim['material']].get('name','')
    vertices.extend(pos);faces.extend(tri);cap.extend([is_cap]*len(tri))
    if is_cap:uvs.extend(arr(prim['attributes']['TEXCOORD_0']))
  vertices=np.array(vertices);faces=np.array(faces);cap=np.array(cap);uvs=np.array(uvs)
  _,ids=np.unique(np.round(vertices,5),axis=0,return_inverse=True);f=ids[faces];edges=np.sort(np.concatenate([f[:,[0,1]],f[:,[1,2]],f[:,[2,0]]]),axis=1);unique,counts=np.unique(edges,axis=0,return_counts=True);lookup={tuple(e):c for e,c in zip(unique,counts)}
  cf=f[cap];ce=np.sort(np.concatenate([cf[:,[0,1]],cf[:,[1,2]],cf[:,[2,0]]]),axis=1);open_cap=sum(lookup[tuple(e)]==1 for e in ce)
  rows.append({'file':p.name,'cut_triangles':int(cap.sum()),'open_cut_edges':int(open_cap),'uv0_min':uvs.min(0).tolist(),'uv0_max':uvs.max(0).tolist(),'nonmanifold_source_edges':int((counts!=2).sum())})
  assert cap.any() and open_cap==0,(p.name,'open cut face',open_cap)
  assert uvs.min()>=0 and uvs.max()<=1,(p.name,'cut UV outside chart')
out.write_text(json.dumps(rows,indent=2));print('B1_CUT_FACE_AUDIT_OK',len(rows))
