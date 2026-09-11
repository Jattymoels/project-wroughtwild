"""D3 direct modelling: fine timber/solid variants and complete framed coverings.
Primitive/UV/topology helpers derive from checked ART-07D1. All geometry is
Godot metres converted once at export; gameplay collision is never replaced.
Run Blender -b -t 8 --python-exit-code 1 --python build.py -- SNAPSHOT FRESH.
"""
import bpy, bmesh, json, math, sys, random, hashlib, re
from pathlib import Path
from mathutils import Vector

snapshot, out = map(Path, sys.argv[sys.argv.index('--')+1:])
cfg=json.loads(Path(__file__).with_name('settings.json').read_text())
ids=['half_cube','half_wall','half_pillar','half_beam','half_slab','light_panel','glazed_window']
shapes={s['id']:s for s in json.loads((snapshot/'data/tuning/construction.json').read_text())['shapes']}
assert not out.exists(), 'Use a fresh model version'
out.mkdir(parents=True); (out/'assets').mkdir(); (out/'evidence').mkdir()
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
def xyz(p): return (p[0],-p[2],p[1])
def godot(p): return (p[0],p[2],-p[1])
def col(name):
    c=bpy.data.collections.new(name); scene.collection.children.link(c); return c
source=col('SOURCE - exact native solids'); finished=col('FINISHED - editable detail'); runtime=col('RUNTIME - selected candidates'); review=col('REVIEW - metre gallery')
def move(o,c):
    for old in list(o.users_collection): old.objects.unlink(o)
    c.objects.link(o)
def mesh(name,vs,faces,c=source):
    m=bpy.data.meshes.new(name); m.from_pydata([xyz(p) for p in vs],[],faces); m.update()
    o=bpy.data.objects.new(name,m); c.objects.link(o)
    bm=bmesh.new(); bm.from_mesh(m); bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces)); bm.to_mesh(m); bm.free()
    return o
def prism(name,outline,axis,lo,hi,c=source):
    axes=[a for a in range(3) if a!=axis]; vs=[]
    for v in (lo,hi):
        for a,b in outline:
            p=[0.,0.,0.]; p[axis]=v; p[axes[0]]=a; p[axes[1]]=b; vs.append(p)
    n=len(outline); fs=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
    fs += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,vs,fs,c)
def box(name,centre,size,c=source):
    x,y,z=centre; w,h,d=size
    return prism(name,[(x-w/2,z-d/2),(x+w/2,z-d/2),(x+w/2,z+d/2),(x-w/2,z+d/2)],1,y-h/2,y+h/2,c)
def active(o):
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active=o
def bevel(o,width):
    active(o); m=o.modifiers.new('Inward worn edges','BEVEL'); m.width=width; m.segments=1
    bpy.ops.object.modifier_apply(modifier=m.name)
def boolean(o,cut,op='DIFFERENCE'):
    active(o); m=o.modifiers.new('Physical backed join' if op=='DIFFERENCE' else 'Joined stone core','BOOLEAN'); m.operation=op; m.solver='EXACT'; m.object=cut
    bpy.ops.object.modifier_apply(modifier=m.name); bpy.data.objects.remove(cut,do_unlink=True)
def material(name,rgb):
    mat=bpy.data.materials.new(name); mat.use_nodes=True
    color=tuple((v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4) for v in rgb)+(1,)
    bs=mat.node_tree.nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=color; bs.inputs['Roughness'].default_value=cfg['roughness']; mat.diffuse_color=color
    return mat
palette=(snapshot/'game/art/building_look.gd').read_text()
hexwood=re.search(r'timber := Color\("([0-9a-f]+)"\)',palette)[1]
woodrgb=[int(hexwood[i:i+2],16)/255 for i in (0,2,4)]
wood=material('Existing timber review',woodrgb); stone=material('Existing mineral review',(.43,.425,.4)); clay=material('Neutral clay',(.58,.58,.57)); ground=material('Review ground',(.145,.165,.175))
# A small embedded sRGB grain atlas is inspection colour, superseded by the exact
# existing game material in the native review. No artificial glowing material.
for mat,rgb in [(wood,woodrgb),(stone,(.43,.425,.4))]:
    im=bpy.data.images.new(mat.name+' colour',width=128,height=256); px=[]
    for v in range(256):
        for u in range(128):
            if mat==wood: n=.08*math.sin(u*.8+math.sin(v*.04)*1.8)+.035*math.sin(u*2.8+v*.01)
            else: n=.035*math.sin(u*.8+v*1.3)+.025*math.sin(u*3.3-v*.9)
            srgb=[max(0,min(1,c*(1+n))) for c in rgb]
            # Blender pixel buffers are linear; encode sRGB only when packing.
            px.extend([(c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4) for c in srgb]+[1])
    im.colorspace_settings.name='sRGB'; im.pixels.foreach_set(px); im.pack()
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=im; mat.node_tree.links.new(tex.outputs['Color'],mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
def uv(o):
    layer=o.data.uv_layers.new(name='Metre surfaces')
    for f in o.data.polygons:
        axis=max(range(3),key=lambda a:abs(f.normal[a])); axes=[a for a in range(3) if a!=axis]
        for i in f.loop_indices:
            p=o.data.vertices[o.data.loops[i].vertex_index].co; layer.data[i].uv=(p[axes[0]]*2,p[axes[1]])
def finish_topology(o):
    # Boolean junctions can leave almost-collinear n-gons. Commit explicit
    # triangles before glTF, so exporter tessellation cannot change the shell.
    bm=bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
    bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=1e-6)
    bmesh.ops.triangulate(bm,faces=list(bm.faces),quad_method='FIXED',ngon_method='EAR_CLIP')
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    assert all(e.is_manifold for e in bm.edges),o.name
    bm.to_mesh(o.data); bm.free(); o.data.update()
def stats(o):
    m=o.data; m.calc_loop_triangles(); vs=[godot(v.co) for v in m.vertices]
    bm=bmesh.new(); bm.from_mesh(m); bad=sum(not e.is_manifold for e in bm.edges); bm.free()
    result={'vertices':len(m.vertices),'triangles':len(m.loop_triangles),'surfaces':len(m.materials),'nonmanifold_edges':bad,'degenerate_triangles':sum(t.area<1e-12 for t in m.loop_triangles),'bounds':[ [min(p[a] for p in vs) for a in range(3)],[max(p[a] for p in vs) for a in range(3)]]}
    assert bad==0 and result['degenerate_triangles']==0,result
    assert all(math.isfinite(v) for p in vs for v in p)
    return result

def clone(o,name,c):
    n=o.copy(); n.data=o.data.copy(); n.name=name; c.objects.link(n); return n

def join(parts,name):
    active(parts[0])
    for p in parts: p.select_set(True)
    bpy.ops.object.join(); obj=parts[0]; obj.name=name; return obj

frame=material('Integral dark frame',(.23,.19,.145))
glass=material('Smoky fixed cinderglass',(.20,.25,.235))
bs=glass.node_tree.nodes.get('Principled BSDF'); bs.inputs['Alpha'].default_value=.48
bs.inputs['Roughness'].default_value=.31; glass.diffuse_color=(.2,.25,.235,.48)
glass.surface_render_method='DITHERED'; glass.use_transparent_shadow=False
lib=(snapshot/'game/art/material_library.gd').read_text()
def native_num(name): return float(re.search(r'var '+name+r' := ([\d.]+)',lib)[1])
frame_width=native_num('window_frame_metres'); batten=native_num('panel_batten_metres'); muntin=native_num('window_muntin_metres')
assets={}; report={'blender_version':bpy.app.version_string,'assets':{},'controls':cfg,'native_frame_width_m':frame_width,'native_panel_batten_m':batten,'native_muntin_m':muntin,'coordinate_mapping':'Blender (x,y,z) -> Godot (x,z,-y) once; centred native pose, metres','lod_policy':'Same bounded geometry at near/middle/far; no additional collision or automatic decimation.'}

def fine(k,timber):
    w,h,d=shapes[k]['size_m']; obj=box(k,(0,0,0),(w,h,d),finished); bevel(obj,cfg['edge_bevel_m'])
    if timber:
        dep=cfg['joint_depth_m']; gap=cfg['joint_width_m']
        if k in ('half_cube','half_wall'):
            for sign in (-1,1):
                # Metre-aligned quarter-metre boards, not scaled parent UVs.
                boolean(obj,box('backed board join',(0,0,sign*(d/2-dep/2)),(gap,h-.064,dep*1.1)))
                for y in (-h/2+.032,h/2-.032):
                    boolean(obj,box('end join',(0,y,sign*(d/2-dep/2)),(w+.01,gap,dep*1.1)))
        elif k=='half_slab':
            for sign in (-1,1): boolean(obj,box('shelf top and underside join',(0,sign*(h/2-dep/2),0),(gap,dep*1.1,d-2*cfg['shelf_end_margin_m'])))
        else:
            for sign in (-1,1):
                centre=(sign*(w/2-.024),0,-d/2+dep/2) if k=='half_beam' else (0,sign*(h/2-.024),-d/2+dep/2)
                size=(gap,h*.55,dep*1.1) if k=='half_beam' else (w*.55,gap,dep*1.1)
                boolean(obj,box('fine end check',centre,size))
    obj.data.materials.append(wood if timber else stone); return obj

def covering(k):
    w,h,d=shapes[k]['size_m']; fw=frame_width if k=='glazed_window' else batten
    # Ring made by a through opening, one watertight continuous frame including
    # four corners. Rebate is an inward shoulder; no independent frame recipe.
    ring=box(k+' integral frame',(0,0,0),(w,h,d),finished)
    boolean(ring,box('opening',(0,0,0),(w-2*fw,h-2*fw,d+.1)))
    for sign in (-1,1):
        boolean(ring,box('pane seating rebate',(0,0,sign*(d*.36)),(w-2*fw+cfg['frame_rebate_m']*2,h-2*fw+cfg['frame_rebate_m']*2,d*.36)))
        for y in (-h/2+fw,h/2-fw):
            for x in (-w/2+fw/2,w/2-fw/2):
                boolean(ring,box('backed frame joint',(x,y,sign*(d/2-.001)),(fw*.66,cfg['frame_joint_m'],.0022)))
    if k=='glazed_window':
        # Boolean union eliminates the cross's coplanar centre and seals its ends.
        boolean(ring,box('vertical muntin',(0,0,0),(muntin,h-2*fw+.002,d*.8)),'UNION')
        boolean(ring,box('horizontal muntin',(0,0,0),(w-2*fw+.002,muntin,d*.8)),'UNION')
    bevel(ring,cfg['edge_bevel_m']); finish_topology(ring); uv(ring); ring.data.materials.append(frame)
    pane=box(k+' complete infill',(0,0,0),(w-2*fw,h-2*fw,d*.24),finished)
    finish_topology(pane); uv(pane); pane.data.materials.append(glass if k=='glazed_window' else wood)
    # Pane is surface 0; ring/muntins surface 1, matching native apply_to.
    obj=join([pane,ring],k+' finished')
    assert len(obj.data.materials)==2
    return obj

for k in ids:
    raw=box(k,(0,0,0),shapes[k]['size_m']); variants=[k,k+'_solid'] if k.startswith('half_') else [k]
    for key in variants:
        obj=fine(k,key==k) if k.startswith('half_') else covering(k)
        if k.startswith('half_'): finish_topology(obj); uv(obj)
        r=clone(obj,key,runtime); active(r); bpy.context.view_layer.update()
        info=stats(r); size=shapes[k]['size_m']; expected=[[-v/2 for v in size],[v/2 for v in size]]
        assert max(abs(info['bounds'][i][a]-expected[i][a]) for i in range(2) for a in range(3))<1e-5,(key,info)
        assert r.location.length<1e-7 and all(abs(v-1)<1e-7 for v in r.scale)
        bpy.ops.export_scene.gltf(filepath=str(out/'assets'/f'{key}.glb'),export_format='GLB',use_selection=True,export_yup=True,export_apply=True,export_cameras=False,export_lights=False)
        info.update(shape_id=k,size_m=size,pivot=[0,0,0],sha256=hashlib.sha256((out/'assets'/f'{key}.glb').read_bytes()).hexdigest(),form=shapes[k].get('form','box'))
        report['assets'][key]=info; assets[key]=r
for c in (source,finished,runtime): c.hide_render=True; c.hide_viewport=True
def instance(k,at):
    o=clone(assets[k],k+' review',review); o.location=xyz(at); return o
for i,k in enumerate(ids):
    x=(i%4-1.5)*1.55; z=(i//4)*1.8; h=shapes[k]['size_m'][1]
    instance(k,(x,h/2,z))
    textcurve=bpy.data.curves.new(k+' label','FONT'); textcurve.body=k.replace('_',' '); textcurve.size=.09; textcurve.align_x='CENTER'
    txt=bpy.data.objects.new(k+' label',textcurve); review.objects.link(txt); txt.location=xyz((x,.006,z-.65)); txt.rotation_euler.z=math.pi; txt.data.materials.append(clay)
floor=box('Review ground',(0,-.065,1),(200,.1,200),review); floor.data.materials.append(ground)
data=bpy.data.cameras.new('Inspection camera'); cam=bpy.data.objects.new('Inspection camera',data); scene.collection.objects.link(cam); scene.camera=cam
cam.location=xyz((4.5,4,-7)); cam.rotation_euler=(Vector(xyz((0,.4,.85)))-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.type='ORTHO'; cam.data.ortho_scale=7.1
for at,power,size in [((2,7,-3),1800,5),((-5,4,1),1100,4),((2,5,7),1600,3)]:
    data=bpy.data.lights.new('Softbox','AREA'); data.energy=power; data.shape='DISK'; data.size=size
    o=bpy.data.objects.new('Softbox',data); scene.collection.objects.link(o); o.location=xyz(at); o.rotation_euler=(Vector(xyz((0,.3,1)))-o.location).to_track_quat('-Z','Y').to_euler()
scene.world.color=(.16,.16,.16); scene.render.engine='CYCLES'; scene.cycles.device='CPU'; scene.cycles.samples=cfg['render_samples']; scene.cycles.use_denoising=True
scene.render.resolution_x=1600; scene.render.resolution_y=1000; scene.render.resolution_percentage=100; scene.view_settings.view_transform='AgX'
bpy.ops.wm.save_as_mainfile(filepath=str(out/'fine-coverings.blend'))
(out/'geometry.json').write_text(json.dumps(report,indent=2)+'\n')
scene.render.filepath=str(out/'evidence/blender-material.png'); bpy.ops.render.render(write_still=True)
scene.view_layers[0].material_override=clay; scene.render.filepath=str(out/'evidence/blender-neutral.png'); bpy.ops.render.render(write_still=True)
print('D3_BLENDER_BUILD_OK',json.dumps({k:v['triangles'] for k,v in report['assets'].items()}))
