"""Independent packed reopen, delivered export topology, physical depth and fit diagnostics."""
import bpy,sys,json,math
from pathlib import Path
from mathutils.bvhtree import BVHTree
sys.path.insert(0,str(Path(__file__).parent))
from landform import height,route_x
from prerequisites import PACKAGES,sha
kit,out=map(lambda p:Path(p).resolve(),sys.argv[sys.argv.index('--')+1:])
bpy.ops.wm.open_mainfile(filepath=str(kit/'b4-composition.blend'))
images=[im for im in bpy.data.images if im.source in ['FILE','GENERATED']]
assert images and all(im.packed_file and min(im.size)>0 and len(im.pixels)>0 for im in images)
result={'packed_images':len(images),'collections':[c.name for c in bpy.data.collections],'exports':[],'native_tree_fit':[]}
assert all(n in result['collections'] for n in ['SOURCE','FINISHED','RUNTIME','REVIEW'])
stored={}
for path in sorted((kit/'models').glob('*.glb')):
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(path))
    obs=[o for o in bpy.context.scene.objects if o.type=='MESH'];n=bad=0;points=[]
    for o in obs:
        o.data.calc_loop_triangles();n+=len(o.data.loop_triangles);bad+=sum(t.area<1e-12 for t in o.data.loop_triangles)
        points.extend(o.matrix_world@v.co for v in o.data.vertices)
    assert bad==0,(path.name,bad)
    assert all(math.isfinite(c) for p in points for c in p)
    row={'file':path.name,'triangles':n,'degenerate':bad,'surfaces':sum(len(o.data.materials) for o in obs),'bounds':[[min(p[k] for p in points) for k in range(3)],[max(p[k] for p in points) for k in range(3)]]}
    if path.stem in ['broadleaf-a-0','broadleaf-altered-0','rock-shelf-0','rock-shelf-altered-0']:
        host=next(o for o in obs if 'foliage' not in o.name.lower() and 'branchlets' not in o.name.lower())
        vertices=[host.matrix_world@v.co for v in host.data.vertices];polys=[tuple(p.vertices) for p in host.data.polygons]
        by_uv={}
        for loop in host.data.loops:
            uv=host.data.uv_layers[0].data[loop.index].uv
            key=(round(uv.x,7),round(uv.y,7));p=vertices[loop.vertex_index]
            by_uv.setdefault(key,set()).add(tuple(round(c,6) for c in p))
        stored[path.stem]=(vertices,polys,by_uv)
    if path.stem in ['broadleaf-a-0','pine-a-0','broadleaf-altered-0']:
        # Wood only: ordinary leaves are not a solid body. No collider is resized.
        wood=[o.matrix_world@v.co for o in obs if 'foliage' not in o.name.lower() and 'branchlets' not in o.name.lower() for v in o.data.vertices]
        burial=.55 if path.stem.startswith('pine') else .65
        band=[p for p in wood if burial<p.z<burial+3]
        outside=sum(abs(p.x)>.35 or abs(p.y)>.35 for p in band)
        result['native_tree_fit'].append({'asset':path.stem,'walking_band_vertices':len(band),'outside_native_body':outside,'max_horizontal_radius_m':max(math.hypot(p.x,p.y) for p in band),'native_fit_pass':outside==0})
    if path.stem.startswith(('broadleaf','pine')) and not path.stem.endswith('-2'):
        leaves=next(o for o in obs if 'foliage' in o.name.lower());twigs=next(o for o in obs if 'branchlets' in o.name.lower())
        bvh=BVHTree.FromPolygons([twigs.matrix_world@v.co for v in twigs.data.vertices],[tuple(p.vertices) for p in twigs.data.polygons])
        uv=leaves.data.uv_layers[1];roots={l.vertex_index for l in leaves.data.loops if uv.data[l.index].uv.x<1e-6}
        distance=max(bvh.find_nearest(leaves.matrix_world@leaves.data.vertices[i].co)[3] for i in roots)
        assert roots and distance<.013,(path.name,distance)
        row['attached_leaf_roots']=len(roots);row['max_leaf_attachment_m']=distance
    result['exports'].append(row)
for family,base,altered in [('tree','broadleaf-a-0','broadleaf-altered-0'),('shelf','rock-shelf-0','rock-shelf-altered-0')]:
    verts,polys,uvs=stored[base];bvh=BVHTree.FromPolygons(verts,polys)
    distances=[bvh.find_nearest(p)[3] for p in stored[altered][0]]
    result[family+'_independent_nearest_surface_distance_m']=max(distances)
    # Independently reduced quiet/altered exports do not have common vertex/UV topology.
    # Verify exact selected host positions against the published input, and measure
    # incision in the original corresponding source topology (same inherited bounds).
    source=PACKAGES['b1'][0]/'models/broadleaf/broadleaf-altered-lod0.glb' if family=='tree' else PACKAGES['b3'][0]/'models/rock-shelf-altered-lod0.glb'
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(source))
    host=next(o for o in bpy.context.scene.objects if o.type=='MESH' and 'foliage' not in o.name.lower() and 'branchlets' not in o.name.lower())
    def pointset(points):return {tuple(round(c,5) for c in p) for p in points}
    assert pointset([host.matrix_world@v.co for v in host.data.vertices])==pointset(stored[altered][0]),family
    master=PACKAGES['b1'][0]/'models/broadleaf/broadleaf-master.blend' if family=='tree' else PACKAGES['b3'][0]/'models/b3-master.blend'
    bpy.ops.wm.open_mainfile(filepath=str(master))
    names=['FINISHED broadleaf','FINISHED deep injured oak'] if family=='tree' else ['rock-shelf','rock-shelf-altered']
    a,b=[bpy.data.objects[n] for n in names];assert len(a.data.vertices)==len(b.data.vertices)
    depth=max((v.co-w.co).length for v,w in zip(a.data.vertices,b.data.vertices))
    assert (.095<depth<=.101 if family=='tree' else .055<depth<=.0651)
    result[family+'_source_incision_m']=depth
    result[family+'_source_master_sha256']=sha(master)
    result[family+'_selected_export_positions_unchanged']=True
layout=json.loads((kit/'layout.json').read_text())
contact=[]
for row in layout:
    if row['role'] in ['moss','leaf-litter','fern-lush','fern-sparse','grass-edge','grass-meadow','sapling-shrub']:
        gap=row['y']-height(row['x'],row['z']);assert abs(gap)<1e-8;contact.append(gap)
result['projected_plant_origins']=len(contact)
out.write_text(json.dumps(result,indent=2)+'\n');print('B4_AUDIT_OK',len(result['exports']))
