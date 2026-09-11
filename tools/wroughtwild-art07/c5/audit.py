"""Independent packed-source reopen and fresh glTF topology/bounds/UV audit."""
import bpy,bmesh,json,sys,math
from pathlib import Path
kit,out=map(lambda p:Path(p).resolve(),sys.argv[sys.argv.index('--')+1:])
bpy.ops.wm.open_mainfile(filepath=str(kit/'c5-master.blend'))
images=[i for i in bpy.data.images if i.source in ['FILE','GENERATED'] and i.users>0]
assert images and all(i.packed_file and min(i.size)>0 for i in images)
incisions=[]
for row in json.loads((kit/'model-report.json').read_text())['incisions']:
    a=bpy.data.objects[row['reference']];b=bpy.data.objects[row['object']];assert len(a.data.vertices)==len(b.data.vertices)
    depth=max((av.co-bv.co).dot(av.normal) for av,bv in zip(a.data.vertices,b.data.vertices));assert abs(depth-row['max_inward_m'])<1e-5
    if row['displaced_vertices']>0:assert depth>.038,(row,depth)
    incisions.append({'object':row['object'],'independent_max_inward_m':depth})
report={'packed_images':[{'name':i.name,'size':list(i.size),'colourspace':i.colorspace_settings.name} for i in images],'incisions':incisions,'exports':[]}
for path in sorted(kit.glob('*.glb')):
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(path));tri=bad=boundary=0;points=[];uv=True;col=True
    for o in bpy.context.scene.objects:
        if o.type!='MESH':continue
        o.data.calc_loop_triangles();tri+=len(o.data.loop_triangles);bad+=sum(t.area<1e-12 for t in o.data.loop_triangles);points.extend(o.matrix_world@v.co for v in o.data.vertices)
        uv=uv and bool(o.data.uv_layers);col=col and bool(o.data.color_attributes)
        bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6);boundary+=sum(e.is_boundary for e in bm.edges);bm.free()
    assert bad==0 and uv and col,(path,bad,uv,col)
    assert all(math.isfinite(v) for p in points for v in p)
    assert all(abs(p.x)<=1.301 and abs(p.y)<=.451 and -.001<=p.z<=.601 for p in points),path
    lod=int(path.stem[-1]);assert tri<=[6000,2600,900][lod],(path,tri)
    report['exports'].append({'file':path.name,'triangles':tri,'degenerate':bad,'boundary_edges_after_weld':boundary,'uv':uv,'colour':col,'bytes':path.stat().st_size,'bounds_blender_m':[[min(p[i] for p in points) for i in range(3)],[max(p[i] for p in points) for i in range(3)]]})
out.write_text(json.dumps(report,indent=2)+'\n');print('C5_BLENDER_AUDIT_OK',len(report['exports']))
