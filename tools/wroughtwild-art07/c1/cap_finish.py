"""Seal the visible stump section with an explicit UV-mapped end-grain face.
The generated hollow underside remains below grade; the cut may not look hollow.
"""
import bpy,bmesh,sys,json,shutil,hashlib
import numpy as np
from pathlib import Path
source,out=map(lambda p:Path(p).resolve(),sys.argv[sys.argv.index('--')+1:]);assert not out.exists();out.mkdir(parents=True);shutil.copytree(source/'models',out/'models')
bpy.ops.wm.open_mainfile(filepath=str(source/'c1-master.blend'));records=json.loads((source/'models.json').read_text())
def hull(points):
    points=sorted(set(points))
    def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
    low=[];up=[]
    for p in points:
        while len(low)>=2 and cross(low[-2],low[-1],p)<=0:low.pop()
        low.append(p)
    for p in reversed(points):
        while len(up)>=2 and cross(up[-2],up[-1],p)<=0:up.pop()
        up.append(p)
    return low[:-1]+up[:-1]
mat=bpy.data.materials.new('Bog oak exposed closed end grain');mat.use_nodes=True;bs=mat.node_tree.nodes['Principled BSDF'];bs.inputs['Roughness'].default_value=.9
image=bpy.data.images.get('broadleaf coherent cut grain');assert image and image.packed_file
tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image;mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
for lod in range(3):
    key='bog-oak-stump-lod%d'%lod;r=records['assets'][key];obs=[bpy.data.objects[n] for n in r['objects']]
    points=[(float(v.co.x),float(v.co.y)) for o in obs for v in o.data.vertices if abs(v.co.z-.43)<.0001];border=hull(points);assert len(border)>8
    # Existing generated cap fragments are removed, retaining the side shell.
    for o in obs:
        bm=bmesh.new();bm.from_mesh(o.data);faces=[f for f in bm.faces if all(abs(v.co.z-.43)<.0001 for v in f.verts)]
        if faces:bmesh.ops.delete(bm,geom=faces,context='FACES_ONLY')
        bm.to_mesh(o.data);bm.free();o.data.update()
    xy=np.array(border);center=xy.mean(0);verts=[(float(center[0]),float(center[1]),.43)]+[(x,y,.43) for x,y in border]
    faces=[(0,i+1,(i+1)%len(border)+1) for i in range(len(border))]
    me=bpy.data.meshes.new('Closed measured end grain');me.from_pydata(verts,[],faces);me.update();uv=me.uv_layers.new(name='Independent planar cut UV')
    for loop in me.loops:
        v=me.vertices[loop.vertex_index].co;uv.data[loop.index].uv=(v.x/.65+.5,v.y/.65+.5)
    me.materials.append(mat);cap=bpy.data.objects.new('C1 closed end grain L%d'%lod,me);bpy.data.collections['RUNTIME'].objects.link(cap);obs.append(cap);r['objects'].append(cap.name)
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs:o.hide_set(False);o.hide_render=False;o.select_set(True)
    bpy.context.view_layer.objects.active=obs[0]
    bpy.ops.export_scene.gltf(filepath=str(out/'models'/(key+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_all_vertex_colors=True,export_attributes=True)
    r['triangles']=0;r['surfaces']=0
    for o in obs:o.data.calc_loop_triangles();r['triangles']+=len(o.data.loop_triangles);r['surfaces']+=len(o.data.materials);o.hide_render=True;o.hide_set(True)
    r['explicit_cap_area_m2']=sum(f.area for f in cap.data.polygons);assert r['explicit_cap_area_m2']>.1
    if lod==0:
        preview=cap.copy();preview.data=cap.data.copy();preview.name='REVIEW closed stump end grain';bpy.data.collections['REVIEW'].objects.link(preview);preview.hide_render=False;preview.location=(-3,-1,0)
records['cap_finish']={'source_master':str(source/'c1-master.blend'),'source_sha256':hashlib.sha256((source/'c1-master.blend').read_bytes()).hexdigest(),'purpose':'Remove black open-looking stump top; independent measured planar cut with packed source end grain.'}
(out/'models.json').write_text(json.dumps(records,indent=2)+'\n');bpy.ops.wm.save_as_mainfile(filepath=str(out/'c1-master.blend'),compress=True)
bpy.context.scene.render.filepath=str(out/'blender-kit.png');bpy.ops.render.render(write_still=True);print('C1_CAP_FINISH_OK')
