"""Fresh copied packed-master reopen and direct exported geometry/attachment audit."""
import bpy,bmesh,json,sys,math,hashlib,shutil
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
root=Path(sys.argv[sys.argv.index('--')+1]);packed='--repacked' in sys.argv
out=root/('reopen-packed' if packed else 'reopen');assert not out.exists();out.mkdir()
models=root/('models-packed-v2' if packed else 'models')
report={'masters':[],'exports':[]}
for kind in ['broadleaf','pine']:
    folder=models/kind;master=folder/(kind+'-master.blend');copy=out/master.name;shutil.copy2(master,copy)
    assert hashlib.sha256(copy.read_bytes()).digest()==hashlib.sha256(master.read_bytes()).digest()
    bpy.ops.wm.open_mainfile(filepath=str(copy))
    images=[im for im in bpy.data.images if im.source in ['FILE','GENERATED']]
    assert images and all(im.packed_file and min(im.size)>0 and len(im.pixels)>0 for im in images)
    report['masters'].append({'path':str(copy),'sha256':hashlib.sha256(copy.read_bytes()).hexdigest(),'packed_images':[{'name':im.name,'size':list(im.size),'colour_space':im.colorspace_settings.name,'packed_sha256':hashlib.sha256(im.packed_file.data).hexdigest()} for im in images],'collections':[c.name for c in bpy.data.collections]})
    for path in sorted(folder.glob('*.glb')):
        bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(path))
        objects=[o for o in bpy.context.scene.objects if o.type=='MESH'];triangles=bad=0;pts=[]
        for o in objects:
            o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles);bad+=sum(t.area<1e-12 for t in o.data.loop_triangles);pts.extend([o.matrix_world@v.co for v in o.data.vertices])
        assert bad==0,(path.name,bad)
        assert all(math.isfinite(c) for p in pts for c in p)
        burial={'broadleaf':.65,'pine':.55}[kind];lower=[p for p in pts if 0<=p.z-burial<=2.6]
        radius=max(math.hypot(p.x,p.y) for p in lower)
        assert radius<=.343001,(path.name,radius)
        row={'file':path.name,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'triangles':triangles,'degenerate_triangles':bad,'lower_radius_m':radius,'bounds_blender_m':[[min(p[i] for p in pts) for i in range(3)],[max(p[i] for p in pts) for i in range(3)]],'object_scales':[list(o.scale) for o in objects]}
        if 'lod' in path.name:
            leaves=next(o for o in objects if 'foliage' in o.name);twigs=next(o for o in objects if 'branchlets' in o.name);trunk=next(o for o in objects if o not in [leaves,twigs])
            def bvh(o):return BVHTree.FromPolygons([o.matrix_world@v.co for v in o.data.vertices],[tuple(p.vertices) for p in o.data.polygons])
            branch_bvh=bvh(twigs);trunk_bvh=bvh(trunk)
            uv=leaves.data.uv_layers[1];roots={l.vertex_index for l in leaves.data.loops if uv.data[l.index].uv.x<1e-6}
            distances=[branch_bvh.find_nearest(leaves.matrix_world@leaves.data.vertices[i].co)[3] for i in roots]
            assert roots and max(distances)<.013,(path.name,'floating leaf root',max(distances))
            bm=bmesh.new();bm.from_mesh(twigs.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001);unseen=set(bm.verts);contacts=[]
            while unseen:
                stack=[unseen.pop()];group=[]
                while stack:
                    v=stack.pop();group.append(v)
                    for e in v.link_edges:
                        n=e.other_vert(v)
                        if n in unseen:unseen.remove(n);stack.append(n)
                contacts.append(min(trunk_bvh.find_nearest(twigs.matrix_world@v.co)[3] for v in group))
            bm.free();assert contacts and max(contacts)<.026,(path.name,'floating branchlet',max(contacts))
            row.update({'leaf_roots':len(roots),'max_leaf_to_twig_surface_m':max(distances),'branchlets':len(contacts),'max_branchlet_to_trunk_surface_m':max(contacts)})
        report['exports'].append(row)
        (out/'audit-progress.json').write_text(json.dumps(report,indent=2))
(root/'evidence'/('blender-reopen-packed.json' if packed else 'blender-reopen.json')).write_text(json.dumps(report,indent=2));print('R1_FRESH_REOPEN_OK',len(report['masters']),len(report['exports']))
