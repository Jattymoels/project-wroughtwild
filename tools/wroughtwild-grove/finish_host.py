"""Blender: reduce the inspected source, bake embedded scars, export two forms."""
import bpy, bmesh, json, math, sys
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
source, config, output=map(Path,sys.argv[sys.argv.index('--')+1:])
cfg=json.loads(config.read_text());sc=cfg['scar']
kind=cfg.get('host','tree')
assert not output.exists();output.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(source.resolve()))
tree=bpy.data.objects['River oak - intact source' if kind=='tree' else 'Fractured rock - intact source']
for o in list(bpy.context.scene.objects):
    if o!=tree:bpy.data.objects.remove(o,do_unlink=True)
bpy.context.view_layer.objects.active=tree;tree.select_set(True)
reference=tree.copy();reference.data=tree.data.copy();reference.name='SOURCE - intact normalized oak'
bpy.context.collection.objects.link(reference);reference.hide_set(True);reference.hide_render=True
bm=bmesh.new();bm.from_mesh(tree.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00005);bm.to_mesh(tree.data);bm.free()
dec=tree.modifiers.new('Branch and bark reduction','DECIMATE');dec.ratio=cfg['tree_triangle_target']/len(tree.data.polygons)
bpy.ops.object.modifier_apply(modifier=dec.name)
validated=tree.data.validate(verbose=True)
tree.data.update()
for f in tree.data.polygons:f.use_smooth=True
tree.name='Quiet river oak'
def export(o,name):
    bpy.ops.object.select_all(action='DESELECT');o.hide_set(False);o.select_set(True);bpy.context.view_layer.objects.active=o
    bpy.ops.export_scene.gltf(filepath=str((output/name).resolve()),export_format='GLB',use_selection=True,export_animations=False)
export(tree,'quiet-'+kind+'.glb')
for i,name in enumerate([kind+'-base.png',kind+'-orm.png']):
    im=bpy.data.images['Image_'+str(i)].copy();list(im.pixels[:4]);im.filepath_raw=str((output/name).resolve());im.file_format='PNG';im.save()
altered=tree.copy();altered.data=tree.data.copy();altered.name='Altered river oak';bpy.context.collection.objects.link(altered)
tree.hide_render=True;tree.hide_set(True)
mesh=altered.data;p=np.array([v.co for v in mesh.vertices]);lo,hi=p.min(0),p.max(0)
bvh=BVHTree.FromPolygons([Vector(v) for v in p],[tuple(f.vertices) for f in mesh.polygons])
controls=[[(.0,.75),(.15,1.0),(.1,1.4),(.21,1.95),(.10,2.5),(-.10,3.05),(.06,3.65),(.10,4.0),(.12,4.5)],
          [(-.10,3.05),(-.55,3.45),(-1.00,3.7),(-1.42,3.94)],
          [(-.1,1.4),(-.47,1.7),(-.62,2.15)]]
controls=cfg.get('scar_controls_xz',controls)
ray_side=cfg.get('ray_side',-1)
starts=[];ends=[];flow=[];projections=[]
for pi,path in enumerate(controls):
    hits=[]
    for a,b in zip(path[:-1],path[1:]):
        a,b=np.array(a),np.array(b)
        for t in np.linspace(0,1,max(2,int(np.linalg.norm(b-a)/.035)),endpoint=False):
            x,z=a*(1-t)+b*t
            hit,normal,index,d=bvh.ray_cast(Vector((x,ray_side*7,z)),Vector((0,-ray_side,0)),14)
            assert hit is not None,('Scar misses tree',x,z)
            hits.append(np.array(hit))
    projections.append(np.array(hits).tolist())
    for a,b in zip(hits[:-1],hits[1:]):
        if np.linalg.norm(b-a)<1e-6:continue
        starts.append(a);ends.append(b);flow.append(a[2]/5)
a,b=np.array(starts),np.array(ends);ab=b-a;len2=(ab*ab).sum(1);flow=np.array(flow)
def sample(points):
    result=np.zeros((len(points),4),np.float32);result[:,3]=1
    for off in range(0,len(points),2048):
        q=points[off:off+2048];ap=q[:,None,:]-a
        t=np.clip(np.einsum('ijk,jk->ij',ap,ab)/len2,0,1)
        ds=np.linalg.norm(ap-t[:,:,None]*ab,axis=2);idx=ds.argmin(1);rows=np.arange(len(q));d=ds[rows,idx]
        def smooth(v):
            v=np.clip(v,0,1);return v*v*(3-2*v)
        result[off:off+len(q),0]=1-smooth((d/sc['core_half_width_m']-.15)/.85)
        result[off:off+len(q),1]=1-smooth(d/sc['damage_half_width_m'])
        result[off:off+len(q),2]=flow[idx]
    return result
vertex=sample(p)
normals=np.empty(len(mesh.vertices)*3,np.float32);mesh.vertices.foreach_get('normal',normals)
displaced=p-normals.reshape(-1,3)*vertex[:,1,None]*sc['recess_m']
mesh.vertices.foreach_set('co',displaced.astype(np.float32).ravel());mesh.update()
mat=mesh.materials[0].copy();mesh.materials[0]=mat;mat.name='Altered bark - scar mask authored in UV'
nodes=mat.node_tree.nodes;links=mat.node_tree.links;bsdf=nodes.get('Principled BSDF');out=next(n for n in nodes if n.type=='OUTPUT_MATERIAL')
attr=mesh.color_attributes.new(name='Bake position',type='FLOAT_COLOR',domain='POINT')
col=np.ones((len(p),4),np.float32);col[:,:3]=(p-lo)/(hi-lo);attr.data.foreach_set('color',col.ravel())
n=nodes.new('ShaderNodeAttribute');n.attribute_name=attr.name
emit=nodes.new('ShaderNodeEmission');links.new(n.outputs['Color'],emit.inputs['Color']);links.new(emit.outputs[0],out.inputs['Surface'])
mask=bpy.data.images.new('Tree scar - core damage travel',width=2048,height=2048,alpha=True,float_buffer=True);mask.colorspace_settings.name='Non-Color'
target=nodes.new('ShaderNodeTexImage');target.image=mask;nodes.active=target
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=1;scene.render.bake.margin=8
bpy.ops.object.select_all(action='DESELECT');altered.select_set(True);bpy.context.view_layer.objects.active=altered
bpy.ops.object.bake(type='EMIT')
texels=np.empty(2048*2048*4,np.float32);mask.pixels.foreach_get(texels)
positions=texels.reshape(-1,4)[:,:3]*(hi-lo)+lo
mask.pixels.foreach_set(sample(positions).ravel());mask.update();mask.filepath_raw=str((output/(kind+'-scar.png')).resolve());mask.file_format='PNG';mask.save();mask.pack()
nodes.remove(emit);links.new(bsdf.outputs[0],out.inputs['Surface'])
# Fallback GLB remains PBR and non-emissive. Runtime binds the mask explicitly.
mesh.color_attributes.remove(attr)
export(altered,'altered-tree.glb' if kind=='tree' else 'fractured-rock.glb')
report={'triangles':len(mesh.polygons),'vertices':len(mesh.vertices),'post_reduction_validation_repaired':validated,'source_blend':str(source),'controls_xz':controls,'projected_paths':projections,'core_vertices':int((vertex[:,0]>.05).sum()),'max_incision_m':float(vertex[:,1].max()*sc['recess_m']),'bounds':[lo.tolist(),hi.tolist()]}
(output/(kind+'-report.json')).write_text(json.dumps(report,indent=2))
for im in bpy.data.images:
    if im.has_data and im.source=='FILE':im.pack()
scene['study']='ART-02 isolated grove; current game art unchanged'
bpy.ops.wm.save_as_mainfile(filepath=str((output/(kind+'-finished.blend')).resolve()),compress=True)
print('TREE_FINISH_OK')
