"""Reopen packed delivery and independently audit GLB topology/attachment."""
import bpy,bmesh,sys,json,math,struct
from pathlib import Path
from mathutils.bvhtree import BVHTree
args=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]]
kit,out=args[:2];asset_dir=args[2] if len(args)>2 else kit/'assets'
bpy.ops.wm.open_mainfile(filepath=str(kit/'groundcover-master.blend'))
images=[im for im in bpy.data.images if im.source in ['FILE','GENERATED']]
assert images and all(im.packed_file and min(im.size)>0 and len(im.pixels)>0 for im in images)
result={'packed_images':[{'name':im.name,'size':list(im.size)} for im in images],'collections':[c.name for c in bpy.data.collections],'exports':[]}
exports=sorted(asset_dir.glob('*.glb'));assert len(exports)==34
for file in exports:
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(file))
    obs=[o for o in bpy.context.scene.objects if o.type=='MESH'];pts=[];tri=bad=0
    for o in obs:
        o.data.calc_loop_triangles();tri+=len(o.data.loop_triangles);bad+=sum(t.area<1e-12 for t in o.data.loop_triangles);pts.extend(o.matrix_world@v.co for v in o.data.vertices)
    assert all(math.isfinite(c) for p in pts for c in p)
    assert bad==0,(file.name,bad)
    row={'file':file.name,'triangles':tri,'degenerates':bad,'surfaces':sum(len(o.data.materials) for o in obs),'bounds_blender':[[min(p[i] for p in pts) for i in range(3)],[max(p[i] for p in pts) for i in range(3)]]}
    if file.name.startswith('sapling-shrub'):assert abs(row['bounds_blender'][0][2])<.00001
    stems=[o for o in obs if 'stems' in o.name]
    foliage=[o for o in obs if 'foliage' in o.name]
    if stems:
        ob=stems[0];tree=BVHTree.FromPolygons([ob.matrix_world@v.co for v in ob.data.vertices],[tuple(p.vertices) for p in ob.data.polygons])
        leaf=foliage[0];uv=leaf.data.uv_layers[0];roots={l.vertex_index for l in leaf.data.loops if abs(uv.data[l.index].uv.y)<1e-6 and abs(uv.data[l.index].uv.x-.5)<1e-6}
        distances=[tree.find_nearest(leaf.matrix_world@leaf.data.vertices[i].co)[3] for i in roots]
        assert distances and max(distances)<.01,(file.name,max(distances))
        row['leaf_roots']=len(roots);row['max_leaf_to_stem_m']=max(distances)
    result['exports'].append(row)
if (kit/'shrub-source.blend').exists():
    bpy.ops.wm.open_mainfile(filepath=str(kit/'shrub-source.blend'))
    source_images=[im for im in bpy.data.images if im.source in ['FILE','GENERATED']]
    assert source_images and all(im.packed_file and min(im.size)>0 and len(im.pixels)>0 for im in source_images)
    result['separate_source_master_packed_images']=len(source_images)
out.write_text(json.dumps(result,indent=2));print('B2_PACKED_REOPEN_AND_GLB_AUDIT_OK',len(result['exports']))
