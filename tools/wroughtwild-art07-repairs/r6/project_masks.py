"""Project the verified C5 vertex mineral/scar fields onto a surface-only atlas.

CPU source conversion, not new generated art. No geometry or original map changes.
R/G/B/A = original mineral mask / original scar mask / top height / coverage.
"""
import json
from pathlib import Path
import numpy as np
from PIL import Image
from stage import OUT, GAME, TOOLS, sha, write

cfg=json.loads((TOOLS/'surface.json').read_text(encoding='utf-8'))
dest=OUT/'projection-v01'
assert not dest.exists()
dest.mkdir()
prepared=json.loads((OUT/'prepared.json').read_text())['original_files']
width,height=512,128
atlas=np.zeros((height*10,width,4),dtype=np.uint8)
sources=[]
for kind_index,kind in enumerate(cfg['ids']):
    units=8 if kind in ['iron_vein','copper_vein'] else 6
    for cracked in [0,1]:
        state='cracked' if cracked and kind!='iron_vein' else 'cold'
        path=GAME/'c5/assets'/f'{kind}-u{units}-{state}-lod0.gltf'
        doc=json.loads(path.read_text(encoding='utf-8'))
        binary=path.with_suffix('.bin')
        for source in [path,binary]:assert sha(source)==prepared['game/'+source.relative_to(GAME).as_posix()]['sha256']
        data=binary.read_bytes()
        def accessor(index):
            a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
            dtype={5126:'<f4',5123:'<u2',5125:'<u4',5121:'u1'}[a['componentType']]
            size={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
            result=np.frombuffer(data,dtype=dtype,count=a['count']*size,offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(-1,size)
            if a.get('normalized'):result=result.astype(np.float64)/np.iinfo(np.dtype(dtype)).max
            return result
        zbuffer=np.full((height,width),-np.inf)
        fields=np.zeros((height,width,4))
        for primitive in doc['meshes'][0]['primitives']:
            vertices=accessor(primitive['attributes']['POSITION'])
            colours=accessor(primitive['attributes']['COLOR_0'])
            triangles=accessor(primitive['indices']).reshape(-1,3)
            for ids in triangles:
                pts=vertices[ids].astype(np.float64)
                px=(pts[:,0]/2.5+0.5)*width-0.5
                py=(pts[:,2]/0.8+0.5)*height-0.5
                left=max(0,int(np.floor(px.min())));right=min(width-1,int(np.ceil(px.max())))
                top=max(0,int(np.floor(py.min())));bottom=min(height-1,int(np.ceil(py.max())))
                if left>right or top>bottom:continue
                det=(py[1]-py[2])*(px[0]-px[2])+(px[2]-px[1])*(py[0]-py[2])
                if abs(det)<1e-10:continue
                xx,yy=np.meshgrid(np.arange(left,right+1),np.arange(top,bottom+1))
                a=((py[1]-py[2])*(xx-px[2])+(px[2]-px[1])*(yy-py[2]))/det
                b=((py[2]-py[0])*(xx-px[2])+(px[0]-px[2])*(yy-py[2]))/det
                c=1-a-b
                y=a*pts[0,1]+b*pts[1,1]+c*pts[2,1]
                mask=(a>=0)&(b>=0)&(c>=0)&(y>zbuffer[top:bottom+1,left:right+1])
                if not mask.any():continue
                colour=a[...,None]*colours[ids[0]]+b[...,None]*colours[ids[1]]+c[...,None]*colours[ids[2]]
                values=np.stack([colour[...,0],colour[...,1],y/0.52,np.ones_like(y)],axis=-1)
                fields[top:bottom+1,left:right+1][mask]=values[mask]
                zbuffer[top:bottom+1,left:right+1][mask]=y[mask]
        row=kind_index*2+cracked
        atlas[row*height:(row+1)*height]=np.rint(np.clip(fields,0,1)*255).astype(np.uint8)
        sources.append({'row':row,'id':kind,'state':state,'gltf':str(path),'gltf_sha256':sha(path),'bin_sha256':sha(binary),'covered_pixels':int(np.isfinite(zbuffer).sum()),'mineral_pixels':int((fields[:,:,0]>.2).sum())})
Image.fromarray(atlas).save(dest/'c5-surface-fields.png')
write(dest/'projection.json',json.dumps({'atlas_sha256':sha(dest/'c5-surface-fields.png'),'size':[width,height*10],'source_bounds_godot_m':[-1.25,1.25,-.4,.4,0,.52],'channels':'mineral,scar,height,coverage','sources':sources,'purpose':'Project the selected original C5 mineral and fracture structure onto the retained native surface; no invented raised body.'},indent=2))
print('R6_C5_FIELDS_PROJECTED',dest)
