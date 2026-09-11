"""Independent packed reopen and actual GLB geometry/contact/body checks."""
import bpy,bmesh,json,math,sys
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
kit,output=map(Path,sys.argv[sys.argv.index('--')+1:])
bpy.ops.wm.open_mainfile(filepath=str(kit/'oldgrowth-master.blend'))
images=[i for i in bpy.data.images if i.source in ['FILE','GENERATED']]
assert images and all(i.packed_file and len(i.pixels)>0 for i in images)
ordinary=bpy.data.objects['FINISHED ordinary fitted trunk'];incised=bpy.data.objects['FINISHED incised fitted trunk']
assert len(ordinary.data.vertices)==len(incised.data.vertices)
depth=max((a.co-b.co).length for a,b in zip(ordinary.data.vertices,incised.data.vertices))
assert .058<depth<=.0651
result={'packed_images':len(images),'collections':[c.name for c in bpy.data.collections],'independent_scar_depth_m':depth,'exports':[]}

def tree(obj):
    return BVHTree.FromPolygons([obj.matrix_world@v.co for v in obj.data.vertices],[tuple(p.vertices) for p in obj.data.polygons])

def groups(obj):
    bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
    unseen=set(bm.verts);answer=[]
    while unseen:
        first=unseen.pop();stack=[first];group=[first]
        while stack:
            v=stack.pop()
            for edge in v.link_edges:
                n=edge.other_vert(v)
                if n in unseen:unseen.remove(n);stack.append(n);group.append(n)
        answer.append([obj.matrix_world@v.co.copy() for v in group])
    bm.free();return answer

for path in sorted((kit/'models').glob('*.glb')):
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(path))
    obs=[o for o in bpy.context.scene.objects if o.type=='MESH'];pts=[];triangles=bad=0
    for o in obs:
        o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles)
        bad+=sum(t.area<1e-12 for t in o.data.loop_triangles)
        pts.extend(o.matrix_world@v.co for v in o.data.vertices)
    assert bad==0,(path.name,'degenerate',bad)
    assert all(math.isfinite(c) for p in pts for c in p)
    row={'asset':path.stem,'triangles':triangles,'surfaces':sum(len(o.data.materials) for o in obs),'degenerate_triangles':bad,'bounds_blender_xyz':[[min(p[k] for p in pts) for k in range(3)],[max(p[k] for p in pts) for k in range(3)]]}
    if path.name.startswith('resinheart') and 'lod' in path.name:
        wood=next(o for o in obs if 'foliage' not in o.name and 'branchlets' not in o.name)
        wp=[wood.matrix_world@v.co for v in wood.data.vertices]
        band=[p for p in wp if 0<=p.z<=4.5]
        radius=max(math.hypot(p.x,p.y) for p in band)
        assert radius<=.4025,(path.name,'native trunk envelope',radius)
        row['native_body_band_max_radius_m']=radius
        row['root_min_z']=min(p.z for p in wp);assert row['root_min_z']<=0
        if 'lod2' not in path.name:
            leaves=next(o for o in obs if 'foliage' in o.name);twigs=next(o for o in obs if 'branchlets' in o.name)
            tb=tree(twigs);wb=tree(wood)
            roots={l.vertex_index for l in leaves.data.loops if leaves.data.uv_layers[1].data[l.index].uv.x<1e-6}
            distances=[tb.find_nearest(leaves.matrix_world@leaves.data.vertices[i].co)[3] for i in roots]
            assert roots and max(distances)<.020,(path.name,'leaf root',max(distances))
            contacts=[min(wb.find_nearest(p)[3] for p in group) for group in groups(twigs)]
            assert max(contacts)<.030,(path.name,'branch root',max(contacts))
            row.update({'leaf_roots':len(roots),'leaf_max_gap_m':max(distances),'branch_roots':len(contacts),'branch_max_gap_m':max(contacts)})
        else:row['attachment_scope']='Far silhouette only; near/middle own attachment fidelity.'
    if path.name.startswith('corkbark'):
        assert all(abs(p.x)<=.825 and abs(p.y)<=.45 and 0<=p.z<=.65 for p in pts),(path.name,'native cork envelope',row['bounds_blender_xyz'])
        row['native_envelope_fit']=True
        # Every separate bark sleeve is a closed solid and intersects the source core.
        core=next(o for o in obs if 'inner deadwood' in o.name);cb=tree(core)
        gaps=[]
        for o in obs:
            if 'sleeve' not in o.name:continue
            bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
            assert not any(not e.is_manifold for e in bm.edges),(path.name,'open bark sleeve')
            bm.free();gaps.append(min(cb.find_nearest(o.matrix_world@v.co)[3] for v in o.data.vertices))
        assert gaps and max(gaps)<.020,(path.name,'floating bark sleeve',gaps)
        row['sleeve_min_surface_contacts_m']=gaps
    if path.name.startswith('recovered'):
        for o in obs:
            bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
            assert all(e.is_manifold for e in bm.edges),(path.name,'recovered solid not closed')
            bm.free()
            for mat in o.data.materials:
                bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
                assert bs.inputs['Emission Strength'].default_value==0
        row['closed_non_emitting_recovered_solids']=True
    result['exports'].append(row)
output.parent.mkdir(parents=True,exist_ok=True);output.write_text(json.dumps(result,indent=2)+'\n')
print('C3_AUDIT_OK',len(result['exports']),depth)
