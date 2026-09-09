"""Fresh Blender reopen, actual exported topology, leaf/twig/host attachment audit."""
import bpy,bmesh,json,sys,math
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
output=Path(sys.argv[sys.argv.index('--')+1]);folders=[Path(p) for p in sys.argv[sys.argv.index('--')+2:]];result={'masters':[],'exports':[]}
for folder in folders:
 master=next(folder.glob('*-master.blend'));bpy.ops.wm.open_mainfile(filepath=str(master))
 images=[im for im in bpy.data.images if im.source in ['FILE','GENERATED']]
 assert images and all(im.packed_file and min(im.size)>0 and len(im.pixels)>0 for im in images)
 row={'file':str(master),'packed_images':len(images),'collections':[c.name for c in bpy.data.collections]}
 if 'broadleaf' in master.name:
  base=bpy.data.objects['FINISHED broadleaf'];altered=bpy.data.objects['FINISHED deep injured oak']
  assert len(base.data.vertices)==len(altered.data.vertices)
  depth=max((a.co-b.co).length for a,b in zip(base.data.vertices,altered.data.vertices));assert depth>.095 and depth<=.101
  row['independent_measured_scar_depth_m']=depth
 result['masters'].append(row)
 for path in sorted(folder.glob('*.glb')):
  bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(path))
  objects=[o for o in bpy.context.scene.objects if o.type=='MESH'];triangles=bad=0;pts=[]
  for o in objects:
   o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles);bad+=sum(t.area<1e-12 for t in o.data.loop_triangles);pts.extend([o.matrix_world@v.co for v in o.data.vertices])
  assert bad==0,(path.name,bad)
  assert all(math.isfinite(c) for p in pts for c in p)
  row={'file':path.name,'triangles':triangles,'degenerate_triangles':bad,'surfaces':sum(len(o.data.materials) for o in objects),'bounds_blender_m':[[min(p[i] for p in pts) for i in range(3)],[max(p[i] for p in pts) for i in range(3)]]}
  if 'lod' in path.name:
   leaves=next(o for o in objects if 'foliage' in o.name);twigs=next(o for o in objects if 'branchlets' in o.name);trunk=next(o for o in objects if o not in [leaves,twigs])
   def bvh(obj):return BVHTree.FromPolygons([obj.matrix_world@v.co for v in obj.data.vertices],[tuple(p.vertices) for p in obj.data.polygons])
   branch_bvh=bvh(twigs);trunk_bvh=bvh(trunk)
   # Independent exported UV2 identifies stationary leaf roots; every one must meet its twig.
   uv=leaves.data.uv_layers[1];roots={l.vertex_index for l in leaves.data.loops if uv.data[l.index].uv.x<1e-6}
   distances=[branch_bvh.find_nearest(leaves.matrix_world@leaves.data.vertices[i].co)[3] for i in roots]
   assert roots and max(distances)<.013,(path.name,'floating leaf root',max(distances))
   # Weld the audit copy, then check every disconnected branchlet component touches the host.
   bm=bmesh.new();bm.from_mesh(twigs.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001);unseen=set(bm.verts);contacts=[]
   while unseen:
    start=unseen.pop();stack=[start];group=[start]
    while stack:
     v=stack.pop()
     for edge in v.link_edges:
      n=edge.other_vert(v)
      if n in unseen:unseen.remove(n);stack.append(n);group.append(n)
    contacts.append(min(trunk_bvh.find_nearest(twigs.matrix_world@v.co)[3] for v in group))
   bm.free();assert contacts and max(contacts)<.026,(path.name,'floating branchlet',max(contacts))
   row.update({'leaf_roots':len(roots),'max_leaf_to_twig_surface_m':max(distances),'branchlets':len(contacts),'max_branchlet_to_trunk_surface_m':max(contacts)})
  result['exports'].append(row)
output.write_text(json.dumps(result,indent=2));print('B1_FRESH_BLENDER_AUDIT_OK',len(result['exports']))
