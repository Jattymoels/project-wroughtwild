"""Reopen packed source, import exported GLBs independently and measure actual topology."""
import bpy,bmesh,json,sys,math
from pathlib import Path
from mathutils import Vector
folder,out=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]]
bpy.ops.wm.open_mainfile(filepath=str(folder/'b3-master.blend'))
images=[im for im in bpy.data.images if im.source in ['FILE','GENERATED']]
assert images and all(im.packed_file and min(im.size)>0 for im in images)
base=bpy.data.objects['rock-shelf'];altered=bpy.data.objects['rock-shelf-altered']
assert len(base.data.vertices)==len(altered.data.vertices)
depth=max((a.co-b.co).length for a,b in zip(base.data.vertices,altered.data.vertices));assert depth>.055 and depth<=.0651
result={'packed_images':len(images),'independent_max_incision_m':depth,'exports':[],'textures':[{'name':im.name,'dimensions':list(im.size),'colourspace':im.colorspace_settings.name} for im in images]}
for p in sorted(folder.glob('*.glb')):
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(p));objects=[o for o in bpy.context.scene.objects if o.type=='MESH'];triangles=bad=boundary=0;points=[];cuts=0
 for o in objects:
  o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles);bad+=sum(t.area<1e-12 for t in o.data.loop_triangles);points.extend([o.matrix_world@v.co for v in o.data.vertices])
  bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001);boundary+=sum(e.is_boundary for e in bm.edges);bm.free()
  cuts+=sum(1 for f in o.data.polygons if f.material_index==1)
 assert bad==0,(p.name,bad)
 assert all(math.isfinite(c) for point in points for c in point)
 bounds=[[min(v[i] for v in points) for i in range(3)],[max(v[i] for v in points) for i in range(3)]]
 if p.name.startswith('boulder'):
  assert bounds[0][0]>=-.701 and bounds[1][0]<=.701 and bounds[0][1]>=-.601 and bounds[1][1]<=.601 and bounds[0][2]>=-.025 and bounds[1][2]<=1.001
 if p.name.startswith('cave'):
  # Every exported vertex in the passage height band is outside the required human-width corridor.
  assert all(abs(v.x)>=1.20 for v in points if .03<v.z<2.40),(p.name,'cave intrusion')
 result['exports'].append({'file':p.name,'triangles':triangles,'surfaces':sum(len(o.data.materials) for o in objects),'degenerate_triangles':bad,'boundary_edges_after_weld':boundary,'cap_faces':cuts,'bounds_blender_m':bounds,'bytes':p.stat().st_size})
out.write_text(json.dumps(result,indent=2));print('B3_FRESH_BLENDER_AUDIT_OK',len(result['exports']))
