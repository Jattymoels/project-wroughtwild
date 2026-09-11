"""Independent Blender process: packed master reopen, six-angle inspection, fresh GLB import."""
import bpy, bmesh, hashlib, json, sys, math, struct, re
from pathlib import Path
from mathutils import Vector

source,out=map(Path,sys.argv[sys.argv.index('--')+1:]); assert not out.exists(); out.mkdir(parents=True)
master=source/'fine-coverings.blend'; before=hashlib.sha256(master.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(master))
scene=bpy.context.scene
images=[i for i in bpy.data.images if i.type=='IMAGE']; assert images and all(i.packed_file for i in images)
for c in scene.collection.children: c.hide_render=c.name!='RUNTIME - selected candidates'
runtime=bpy.data.collections['RUNTIME - selected candidates']; runtime.hide_render=False; runtime.hide_viewport=False
# Blender appends numeric suffixes because SOURCE already owns the plain names.
# Require a one-to-one complete catalogue mapping, never silently skip objects.
assets={re.sub(r'\.\d+$','',o.name):o for o in runtime.objects}; geometry=json.loads((source/'geometry.json').read_text())
assert len(assets)==len(runtime.objects)==12 and set(assets)==set(geometry['assets'])
camera=scene.camera; camera.data.ortho_scale=1.55
# Inspection-only fill follows each camera, including below the asset, so a
# backlit underside cannot conceal missing faces in a technically valid render.
fill_data=bpy.data.lights.new('Inspection camera fill','AREA'); fill_data.energy=250; fill_data.shape='DISK'; fill_data.size=3
fill=bpy.data.objects.new('Inspection camera fill',fill_data); scene.collection.objects.link(fill)
scene.render.resolution_x=384; scene.render.resolution_y=384; scene.cycles.samples=8
scene.render.film_transparent=True
clay=bpy.data.materials['Neutral clay']
angles={'front':(0,0,-3),'back':(0,0,3),'side':(3,0,0),'three-quarter':(2,1.7,-3),'top':(0,3,.01),'underside':(0,-3,.01)}
for k,obj in assets.items():
    for other in assets.values(): other.hide_render=other!=obj
    target=Vector((0,0,-.25 if k in ('foundation','dry_wall') else 0))
    for view,pos in angles.items():
        camera.location=Vector((pos[0],-pos[2],pos[1]))+target
        camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
        fill.location=camera.location; fill.rotation_euler=camera.rotation_euler
        for mode in ['material','neutral']:
            scene.view_layers[0].material_override=clay if mode=='neutral' else None
            scene.render.filepath=str(out/f'{k}-{view}-{mode}.png'); bpy.ops.render.render(write_still=True)
checks={}
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
    (out/f'{k}-topology.json').write_text(json.dumps({'vertices_after_weld':len(bm.verts),'bad_edges':[{'length':e.calc_length(),'faces':len(e.link_faces),'points':[list(v.co) for v in e.verts]} for e in bm.edges if not e.is_manifold]},indent=2))
    assert all(e.is_manifold for e in bm.edges),k; bm.free()
    raw=(source/'assets'/f'{k}.glb').read_bytes(); chunk_length=struct.unpack_from('<I',raw,12)[0]; gltf=json.loads(raw[20:20+chunk_length])
    checks[k]={'bounds':bounds,'triangles':len(o.data.loop_triangles),'surfaces':len(o.data.materials),'closed_after_welding_export_seams':True,'actual_glb_asset_metadata':gltf['asset']}
assert hashlib.sha256(master.read_bytes()).hexdigest()==before
(out/'reopen.json').write_text(json.dumps({'master_sha256':before,'packed_images':len(images),'six_angles_each_material_and_neutral':True,'fresh_glb_imports':checks},indent=2)+'\n')
print('D3_REOPEN_OK 12 fresh GLBs, packed master, 144 actual inspection renders')
