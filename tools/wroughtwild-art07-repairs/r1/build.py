"""Refit copies of B1 packed masters; preserve source collections and all heights.
Run only through the repair job wrapper. No raw/source/depot file is written.
"""
import bpy,bmesh,json,math,sys,hashlib
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ARGS=sys.argv[sys.argv.index('--')+1:];root=Path(ARGS[0]).resolve();kind=ARGS[1]
source=root/'sources/b1/models'/kind;out=root/'models'/kind
assert not out.exists();out.mkdir(parents=True)
cfg=json.loads((Path(__file__).parent/'settings.json').read_text(encoding='utf-8-sig'));burial=cfg['burial_m'][kind]
master=source/(kind+'-master.blend');bpy.ops.wm.open_mainfile(filepath=str(master))
# Preserve original unreferenced packed masks as well as material-linked images.
for im in bpy.data.images:im.use_fake_user=True
# Original source and production object data remain independently inspectable.
for col in bpy.data.collections:
    col.name='ORIGINAL '+col.name
new=bpy.data.collections.new('R1 REFITTED RUNTIME');bpy.context.scene.collection.children.link(new)
report={'source_master':str(master),'source_sha256':hashlib.sha256(master.read_bytes()).hexdigest(),'settings':cfg,'exports':[]}
def deform(p):
    x,y,z=p;h=z-burial;r=math.hypot(x,y);R=cfg['lower_radius_m']
    lower=R/math.sqrt(R*R+r*r)
    t=max(0,min(1,(h-cfg['clear_height_m'])/(cfg['full_crown_height_m']-cfg['clear_height_m'])));t=t*t*(3-2*t)
    s=lower+(1-lower)*t
    return Vector((x*s,y*s,z))
def bvh(o):return BVHTree.FromPolygons([v.co for v in o.data.vertices],[tuple(p.vertices) for p in o.data.polygons])
def attach(o,parent,foliage):
    tree=bvh(parent);bm=bmesh.new();bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
    uv=bm.loops.layers.uv[1] if foliage else None
    unseen=set(bm.verts);maximum=0;count=0
    while unseen:
        stack=[unseen.pop()];group=[]
        while stack:
            v=stack.pop();group.append(v)
            for e in v.link_edges:
                n=e.other_vert(v)
                if n in unseen:unseen.remove(n);stack.append(n)
        if foliage:
            roots=[v for v in group if any(l[uv].uv.x<1e-6 for l in v.link_loops)]
            assert roots,('Leaf component without authored root',o.name)
            root=min(roots,key=lambda v:tree.find_nearest(v.co)[3])
        else:root=min(group,key=lambda v:tree.find_nearest(v.co)[3])
        hit=tree.find_nearest(root.co);delta=hit[0]-root.co
        # A whole-vertex nonlinear deformation does not commute with triangle
        # interpolation. Re-seat the stationary attachment, tapering to zero at
        # the existing tip. This is mesh authoring, not runtime collision logic.
        if delta.length>.007:
            maximum=max(maximum,delta.length);count+=1
            extent=max((v.co-root.co).length for v in group);origin=root.co.copy()
            for v in group:
                weight=min(l[uv].uv.x for l in v.link_loops) if foliage else min(1,(v.co-origin).length/max(extent,1e-6))
                v.co+=delta*max(0,1-weight)
    bm.normal_update();bm.to_mesh(o.data);bm.free();o.data.update()
    return {'components_adjusted':count,'max_root_shift_m':maximum}

# Reuse exact LOD assemblies and packed maps, rather than regenerate foliage.
for glb in sorted(source.glob('*.glb')):
    if 'deadwood' in glb.name:continue
    # Import the verified original export; each derivative is now an editable mesh.
    existing=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(glb))
    added=[o for o in bpy.data.objects if o not in existing];parts=[o for o in added if o.type=='MESH']
    assert parts
    for o in parts:
        for col in list(o.users_collection):col.objects.unlink(o)
        new.objects.link(o);o.name='R1 '+glb.stem+' '+o.name
        # glTF importer has already performed the sole Godot -> Blender mapping.
        transform=o.matrix_world.copy()
        for v in o.data.vertices:v.co=deform(transform@v.co)
        o.matrix_world.identity();o.data.update();o['r1_export']=glb.stem
        o['r1_source_sha256']=hashlib.sha256(glb.read_bytes()).hexdigest()
    contacts={}
    if 'lod' in glb.name:
        leaves=next(o for o in parts if 'foliage' in o.name);twigs=next(o for o in parts if 'branchlets' in o.name);trunk=next(o for o in parts if o not in [leaves,twigs])
        contacts['branchlets']=attach(twigs,trunk,False)
        contacts['leaves']=attach(leaves,twigs,True)
    # The root re-seat may shift an alternate lower leaf by millimetres.
    # Clip only that residual to the documented native-envelope allowance.
    clipped=0
    for o in parts:
        for v in o.data.vertices:
            r=math.hypot(v.co.x,v.co.y)
            if v.co.z-burial<=cfg['clear_height_m'] and r>cfg['lower_radius_m']:
                v.co.x*=cfg['lower_radius_m']/r;v.co.y*=cfg['lower_radius_m']/r;clipped+=1
        o.data.update()
    contacts['lower_envelope_vertices_trimmed']=clipped
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts:o.hide_set(False);o.hide_render=False;o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    target=out/glb.name
    bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,export_animations=False,export_all_vertex_colors=True,export_texcoords=True)
    report['exports'].append({'name':glb.name,'source_sha256':hashlib.sha256(glb.read_bytes()).hexdigest(),'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'objects':[o.name for o in parts],'attachment_corrections':contacts})
    for o in added:o.hide_render=True;o.hide_set(True)
for im in bpy.data.images:
    if im.has_data and im.source in ['FILE','GENERATED'] and not im.packed_file:im.pack()
scene=bpy.context.scene;scene['r1_settings']=json.dumps(cfg);scene['r1_scope']='R1 source-preserving lower-trunk refit; no native collision or heights changed'
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=16
(out/'build.json').write_text(json.dumps(report,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(out/(kind+'-master.blend')),compress=True)
print('R1_MASTER_BUILT',kind,len(report['exports']))
