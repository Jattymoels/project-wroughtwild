"""Separate Blender reopen and actual glTF triangle/body/contact verification."""
import bpy,bmesh,sys,json,math,hashlib
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
kit,out=map(lambda p:Path(p).resolve(),sys.argv[sys.argv.index('--')+1:]);out.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(kit/'c1-master.blend'))
images=[]
for im in bpy.data.images:
    if im.source not in ['FILE','GENERATED']:continue
    assert im.packed_file is not None,(im.name,'unpacked image')
    pixel=im.pixels[0]  # Blender loads packed pixels lazily after reopening.
    assert im.has_data and len(im.pixels)>0 and math.isfinite(pixel)
    images.append({'name':im.name,'size':list(im.size),'packed_bytes':len(im.packed_file.data)})
assert images and all(im['packed_bytes']>0 for im in images)
report={'master_sha256':hashlib.sha256((kit/'c1-master.blend').read_bytes()).hexdigest(),'packed_images':images,'exports':{},'work_depth_m':{}}
for lod in range(3):
    a=bpy.data.objects['bog-oak-%d-0'%lod];b=bpy.data.objects['worked bog-oak-%d-0'%lod]
    assert len(a.data.vertices)==len(b.data.vertices)
    depth=max((x.co-y.co).length for x,y in zip(a.data.vertices,b.data.vertices));assert depth>.045
    report['work_depth_m'][str(lod)]=depth
records=json.loads((kit/'models.json').read_text())
for path in sorted((kit/'models').glob('*.glb')):
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(path))
    obs=[o for o in bpy.context.scene.objects if o.type=='MESH'];pts=[];triangles=bad=boundary=0
    for o in obs:
        o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles)
        for t in o.data.loop_triangles:
            p=[o.matrix_world@o.data.vertices[i].co for i in t.vertices]
            if (p[1]-p[0]).cross(p[2]-p[0]).length*.5<1e-12:bad+=1
        pts.extend([o.matrix_world@v.co for v in o.data.vertices])
        bm=bmesh.new();bm.from_mesh(o.data);boundary+=sum(e.is_boundary for e in bm.edges);bm.free()
        for m in o.data.materials:
            bs=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
            assert bs.inputs['Emission Strength'].default_value==0,(path,m.name,'ordinary asset emitting')
    p=np.array(pts);assert np.isfinite(p).all();assert bad==0,(path,bad)
    assert triangles==records['assets'][path.stem]['triangles'],(path,triangles)
    if path.stem.startswith('bog-oak'):
        lower=p[(p[:,2]>=0)&(p[:,2]<=3)];rad=np.linalg.norm(lower[:,:2],axis=1).max();assert rad<=.35,(path,rad)
    elif path.stem.startswith('clay'):
        assert (np.abs(p[:,:2]).max(0)<=np.array([.9,.625])+1e-5).all() and p[:,2].max()<=.38
    elif path.stem.startswith('reed'):
        assert np.abs(p[:,:2]).max()<=.48 and p[:,2].max()<=1.28,(path,p.max(0))
    elif path.stem.startswith('fen-sedge'):assert p[:,2].max()<=.28
    report['exports'][path.name]={'triangles':triangles,'degenerates':bad,'boundary_edges':boundary,'dimensions_blender_m':(p.max(0)-p.min(0)).tolist(),'bounds_blender_m':[p.min(0).tolist(),p.max(0).tolist()],'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
# Reimport complete reed source and independently test every authored leaf root against actual faces.
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(kit/'models/reed-24-lod0.glb'))
obj=next(o for o in bpy.context.scene.objects if o.type=='MESH')
colors=obj.data.color_attributes[0]
def stem_face(face):
    indices=face.vertices if colors.domain=='POINT' else face.loop_indices
    return all(colors.data[i].color[1]/max(colors.data[i].color[0],.0001)<1.16 for i in indices)
stem_faces=[tuple(f.vertices) for f in obj.data.polygons if stem_face(f)]
assert len(stem_faces)>100
bv=BVHTree.FromPolygons([obj.matrix_world@v.co for v in obj.data.vertices],stem_faces)
roots=[r for r in records['attachment_roots'] if r['kind']=='leaf_to_stalk'];dist=[bv.find_nearest(Vector(r['root']))[3] for r in roots]
assert len(dist)==96 and max(dist)<.013
report['reed_leaf_roots']={'count':len(dist),'max_surface_gap_m':max(dist),'method':'recorded rooted leaf points against actual exported stalk faces only, excluding green leaf faces by authored vertex-colour ratio'}
out.write_text(json.dumps(report,indent=2)+'\n');print('C1_AUDIT_OK',len(report['exports']),len(images),max(dist))
