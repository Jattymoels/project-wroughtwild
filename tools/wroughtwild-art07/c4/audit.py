"""Independent packed-source and exported geometry checks, never inferred from recipe targets."""
import bpy,json,sys,math
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
kit,output=map(lambda p:Path(p).resolve(),sys.argv[sys.argv.index('--')+1:])
bpy.ops.wm.open_mainfile(filepath=str(kit/'c4-master.blend'))
images=[]
for im in bpy.data.images:
    if im.source!='FILE' or im.users==0:continue
    # Reopened Blender images decode lazily; actually read packed pixels.
    pixel=list(im.pixels[:4])
    assert len(pixel)==4 and all(math.isfinite(v) for v in pixel),im.name
    images.append({'name':im.name,'size':list(im.size),'packed':bool(im.packed_file),'bytes':len(im.packed_file.data) if im.packed_file else 0})
assert images and all(im['packed'] and im['bytes']>0 for im in images)
a=bpy.data.objects['MEASURE before scar'];b=bpy.data.objects['MEASURE after scar']
assert len(a.data.vertices)==len(b.data.vertices)
depth=max((va.co-vb.co).length for va,vb in zip(a.data.vertices,b.data.vertices));assert .04<depth<.046
report={'packed_images':images,'independent_scar_vertex_displacement_m':depth,'models':{}}
for path in sorted((kit/'models').glob('*.glb')):
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(path))
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH'];pts=[];triangles=0;degenerate=0;surfaces=0;open_edges=0
    for o in objects:
        o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles);surfaces+=len(o.data.materials)
        pts += [o.matrix_world@v.co for v in o.data.vertices]
        degenerate+=sum(t.area<1e-12 for t in o.data.loop_triangles)
        uses={}
        for p in o.data.polygons:
            v=list(p.vertices)
            for i in range(len(v)):
                e=tuple(sorted((v[i],v[(i+1)%len(v)])));uses[e]=uses.get(e,0)+1
        open_edges+=sum(n==1 for n in uses.values())
    assert all(math.isfinite(v) for p in pts for v in p),path
    assert degenerate==0,(path,degenerate)
    lo=[min(p[i] for p in pts) for i in range(3)];hi=[max(p[i] for p in pts) for i in range(3)]
    item={'triangles':triangles,'surfaces':surfaces,'degenerate_triangles':degenerate,'boundary_edges_in_export_charts':open_edges,'bounds_blender_m':[lo,hi],'bytes':path.stat().st_size}
    if path.stem.startswith('seed-grass'):
        stems=next(o for o in objects if 'seed stems' in o.name)
        heads=next(o for o in objects if 'seed heads' in o.name)
        bvh=BVHTree.FromPolygons([stems.matrix_world@v.co for v in stems.data.vertices],[list(p.vertices) for p in stems.data.polygons])
        roots=set()
        for l in heads.data.loops:
            uv=heads.data.uv_layers.active.data[l.index].uv
            if abs(uv.x-.5)<1e-5 and abs(uv.y)<1e-5:roots.add(l.vertex_index)
        distances=[bvh.find_nearest(heads.matrix_world@heads.data.vertices[i].co)[3] for i in roots]
        assert len(distances)==20 and max(distances)<.003,(path,distances)
        item['seedhead_attachment_roots']=len(distances);item['max_seedhead_stem_distance_m']=max(distances)
    if path.stem.startswith(('ash-a-','ash-b-','ash-short-','ash-altered-','ash-stump-')):
        radius=max(Vector((p.x,p.y)).length for p in pts if -.01<=p.z<=2.6)
        assert radius<=.2901,(path,radius);item['body_band_radius_m']=radius
    if 'felled' in path.stem or 'stump' in path.stem:assert abs(lo[2])<.0001,(path,lo)
    report['models'][path.stem]=item
output.parent.mkdir(parents=True,exist_ok=True);output.write_text(json.dumps(report,indent=2)+'\n')
print('C4_AUDIT_OK',len(report['models']),depth)
