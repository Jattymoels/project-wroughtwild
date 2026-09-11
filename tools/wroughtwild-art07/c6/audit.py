"""Independent packed-source reopen, exact-envelope and exported topology checks."""
import bpy,bmesh,json,sys,math
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
kit,out=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]]
report=json.loads((kit/'model-report.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(kit/'c6-master.blend'))
images=[im for im in bpy.data.images if im.source in ['FILE','GENERATED'] and im.users>0]
assert images and all(im.packed_file and min(im.size)>0 for im in images)
scar=report['scar'];a=bpy.data.objects[scar['reference']];b=bpy.data.objects[scar['altered']]
assert len(a.data.vertices)==len(b.data.vertices)
depth=max((x.co-y.co).length for x,y in zip(a.data.vertices,b.data.vertices));assert .038<depth<=.04801
reference=BVHTree.FromPolygons([v.co.copy() for v in a.data.vertices],[tuple(f.vertices) for f in a.data.polygons])
result={'packed_images':[{'name':im.name,'size':list(im.size),'colourspace':im.colorspace_settings.name} for im in images],'independent_incision_m':depth,'exports':[]}
for p in sorted((kit/'models').glob('*.glb')):
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(p))
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH'];points=[];triangles=bad=surfaces=0
    for o in objects:
        o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles);bad+=sum(t.area<1e-12 for t in o.data.loop_triangles);surfaces+=len(o.data.materials)
        points.extend(o.matrix_world@v.co for v in o.data.vertices)
    assert bad==0,(p.name,bad)
    assert all(math.isfinite(c) for v in points for c in v)
    name=p.stem.rsplit('-lod',1)[0];source=report['sources'].get(name,report['sources'].get(name.replace('_struck','')))
    if 'bounds' in source: low,high=map(Vector,source['bounds'])
    else:
        size=Vector(source['native_size_blender_m']);low=-size*.5;high=size*.5
    assert all(all(low[i]-.00005<=v[i]<=high[i]+.00005 for i in range(3)) for v in points),(p.name,'envelope')
    # Opening solids remain the original source; added root faces cannot bridge portals.
    if name in ['cataclysm_rootvault_frame','cataclysm_forge_threshold']:
        added=[o for o in objects if 'root' in o.name and 'roots' in o.name]
        assert all(abs((o.matrix_world@v.co).x)>1.1 for o in added for v in o.data.vertices)
    entry={'file':p.name,'triangles':triangles,'surfaces':surfaces,'degenerate_triangles':bad,'bounds_blender_m':[[min(v[i] for v in points) for i in range(3)],[max(v[i] for v in points) for i in range(3)]],'bytes':p.stat().st_size}
    if name=='cataclysm_fen_wall_struck':
        body=next(o for o in objects if 'roots' not in o.name)
        candidate=BVHTree.FromPolygons([body.matrix_world@v.co for v in body.data.vertices],[tuple(f.vertices) for f in body.data.polygons])
        recession=[]
        for i in range(33):
            for j in range(55):
                ray=Vector((-.10+i*.0125,-1,.04+j*.012))
                r=reference.ray_cast(ray,Vector((0,1,0)));c=candidate.ray_cast(ray,Vector((0,1,0)))
                if r[0] is not None and c[0] is not None and r[1].y<-.6:recession.append(c[0].y-r[0].y)
        maximum=max(recession);assert .032<maximum<.06,(p.name,maximum)
        entry['independent_front_ray_recession_m']=maximum;entry['matched_ray_samples']=len(recession)
    result['exports'].append(entry)
out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(result,indent=2)+'\n');print('C6_FRESH_AUDIT_OK',len(result['exports']),'incision',depth)
