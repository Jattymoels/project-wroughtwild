"""Independent Blender process: packed master reopen, six-angle inspection, fresh GLB import."""
import bpy, bmesh, hashlib, json, sys, math, struct, re
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree

source,out=map(Path,sys.argv[sys.argv.index('--')+1:]); assert not out.exists(); out.mkdir(parents=True)
master=source/'roof-joinery-spans.blend'; before=hashlib.sha256(master.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(master))
scene=bpy.context.scene
hinge=bpy.data.objects['Door hinge - native two-state control']; leaf=hinge.children[0]
hinge['open']=False; hinge.update_tag(); bpy.context.view_layer.update(); closed=leaf.matrix_world.copy()
hinge['open']=True; hinge.update_tag(); bpy.context.view_layer.update(); opened=leaf.matrix_world.copy()
assert abs(hinge.rotation_euler.z+math.pi/2)<1e-6
assert (opened.translation-closed.translation-Vector((-.5,-.5,0))).length<1e-6
hinge['open']=False; hinge.update_tag(); bpy.context.view_layer.update()
images=[i for i in bpy.data.images if i.type=='IMAGE']; assert images and all(i.packed_file for i in images)
for c in scene.collection.children: c.hide_render=c.name!='RUNTIME - selected candidates'
runtime=bpy.data.collections['RUNTIME - selected candidates']; runtime.hide_render=False; runtime.hide_viewport=False
# Blender appends numeric suffixes because SOURCE already owns the plain names.
# Require a one-to-one complete catalogue mapping, never silently skip objects.
assets={o['catalogue_id']:o for o in runtime.objects}; geometry=json.loads((source/'geometry.json').read_text())
assert len(assets)==len(runtime.objects)==7 and set(assets)==set(geometry['assets'])
camera=scene.camera; camera.data.ortho_scale=2.5
# Inspection-only fill follows each camera, including below the asset, so a
# backlit underside cannot conceal missing faces in a technically valid render.
fill_data=bpy.data.lights.new('Inspection camera fill','AREA'); fill_data.energy=250; fill_data.shape='DISK'; fill_data.size=3
fill=bpy.data.objects.new('Inspection camera fill',fill_data); scene.collection.objects.link(fill)
scene.render.resolution_x=384; scene.render.resolution_y=384; scene.cycles.samples=8
scene.render.film_transparent=True
clay=bpy.data.materials['Neutral clay']
angles={'front':(0,0,-3),'back':(0,0,3),'side':(3,0,0),'three-quarter':(2,1.7,-3),'top':(0,3,.01),'underside':(0,-3,.01)}
for k,obj in assets.items():
    camera.data.ortho_scale=2.5 if k in ['door','girder'] else 1.5
    for other in assets.values(): other.hide_render=other!=obj
    target=Vector((0,0,-.25 if k in ('foundation','dry_wall') else 0))
    for view,pos in angles.items():
        camera.location=Vector((pos[0],-pos[2],pos[1]))+target
        camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
        fill.location=camera.location; fill.rotation_euler=camera.rotation_euler
        for mode in ['material','neutral']:
            scene.view_layers[0].material_override=clay if mode=='neutral' else None
            scene.render.filepath=str(out/f'{k}-{view}-{mode}.png'); bpy.ops.render.render(write_still=True)
checks={}; roofs={}
for k,expected in geometry['assets'].items():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source/'assets'/f'{k}.glb'))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']; assert len(meshes)==1
    o=meshes[0]; o.data.calc_loop_triangles(); verts=[o.matrix_world@v.co for v in o.data.vertices]
    points=[(v.x,v.z,-v.y) for v in verts]
    bounds=[[min(p[a] for p in points) for a in range(3)],[max(p[a] for p in points) for a in range(3)]]
    assert max(abs(bounds[i][a]-expected['bounds'][i][a]) for i in range(2) for a in range(3))<1e-5,(k,bounds)
    assert len(o.data.loop_triangles)==expected['triangles']
    assert all(t.area>1e-12 for t in o.data.loop_triangles)
    bm=bmesh.new(); bm.from_mesh(o.data); bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
    if k.startswith('codex_roof_'): roofs[k]=BVHTree.FromBMesh(bm)
    (out/f'{k}-topology.json').write_text(json.dumps({'vertices_after_weld':len(bm.verts),'bad_edges':[{'length':e.calc_length(),'faces':len(e.link_faces),'points':[list(v.co) for v in e.verts]} for e in bm.edges if not e.is_manifold]},indent=2))
    assert all(e.is_manifold for e in bm.edges),k; bm.free()
    raw=(source/'assets'/f'{k}.glb').read_bytes(); chunk_length=struct.unpack_from('<I',raw,12)[0]; gltf=json.loads(raw[20:20+chunk_length])
    checks[k]={'bounds':bounds,'triangles':len(o.data.loop_triangles),'surfaces':len(o.data.materials),'closed_after_welding_export_seams':True,'actual_glb_asset_metadata':gltf['asset']}
assert hashlib.sha256(master.read_bytes()).hexdigest()==before
# Exhaustive actual imported roof-edge samples and every equal-height legal
# slope/hip/valley adjacency. Native shape equations are independent of relief.
def local(x,z,turn):
    angle=turn*math.pi/2; c=math.cos(angle); s=math.sin(angle)
    return (c*x-s*z,s*x+c*z)
def native(k,x,z,turn):
    x,z=local(x,z,turn); u=x+.5; v=z+.5
    return -.25+.5*(v if k=='codex_roof_slope' else min(u,v) if k=='codex_roof_hip' else max(u,v))
def actual(k,x,z,turn):
    x,z=local(x,z,turn)
    # Infinitesimal inward probe avoids zero-area triangles at an exact eave.
    x=max(-.499999,min(.499999,x)); z=max(-.499999,min(.499999,z))
    hit=roofs[k].ray_cast(Vector((x,-z,1)),Vector((0,0,-1)),2)[0]
    assert hit is not None,(k,x,z)
    return hit.z
edge_checks=0; seam_pairs=[]
for k in roofs:
    for turn in range(4):
        for axis in range(2):
            for sign in [-1,1]:
                for j in range(11):
                    x,z=(sign*.5,-.5+j*.1) if axis==0 else (-.5+j*.1,sign*.5)
                    assert abs(actual(k,x,z,turn)-native(k,x,z,turn))<.00002,(k,turn,x,z)
                    edge_checks+=1
for a in roofs:
    for b in roofs:
        for ta in range(4):
            for tb in range(4):
                for axis in range(2):
                    for dy in [-.5,0,.5]:
                        points=[((.5,-.5+j*.1),(-.5,-.5+j*.1)) if axis==0 else ((-.5+j*.1,.5),(-.5+j*.1,-.5)) for j in range(11)]
                        if all(abs(native(a,*p,ta)-native(b,*q,tb)-dy)<1e-7 for p,q in points):
                            assert all(abs(actual(a,*p,ta)-actual(b,*q,tb)-dy)<.00004 for p,q in points),(a,b,ta,tb,axis,dy)
                            seam_pairs.append([a,b,ta,tb,axis,dy])
assert edge_checks==528 and len(seam_pairs)>0
(out/'seams.json').write_text(json.dumps({'actual_imported_edge_samples':edge_checks,'tolerance_m':.00002,'legal_seam_pairs':seam_pairs,'samples_per_pair':11,'covers':'Every turn, both horizontal adjacency axes, and -0.5/0/+0.5 m native fine-grid lifts'},indent=2)+'\n')
(out/'reopen.json').write_text(json.dumps({'master_sha256':before,'native_two_state_hinge_control':True,'packed_images':len(images),'six_angles_each_material_and_neutral':True,'fresh_glb_imports':checks,'edge_samples':edge_checks,'legal_seam_pairs':len(seam_pairs)},indent=2)+'\n')
print('D2_REOPEN_OK 7 fresh GLBs, packed master, 84 actual inspection renders')
