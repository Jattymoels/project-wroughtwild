"""Blender direct modelling. Run: blender -b -t 8 --python-exit-code 1 --python build.py -- SNAPSHOT OUTPUT.

Dimensional and coordinate conventions derive from wroughtwild-blender/build_study.py;
the watertight stair prism, diagonal prisms and low stone courses are authored here.
All coordinates below are Godot metres, converted exactly once for glTF export.
"""
import bpy, bmesh, json, math, sys, random, hashlib, re
from pathlib import Path
from mathutils import Vector

snapshot, out = map(Path, sys.argv[sys.argv.index('--')+1:])
cfg=json.loads(Path(__file__).with_name('settings.json').read_text())
ids=['cube','wall_panel','pillar','beam','floor_slab','stairs','codex_corner','codex_corner_floor','foundation','dry_wall']
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
def base(k):
    s=shapes[k]; w,h,d=s['size_m']; f=s.get('form','box')
    if f=='corner':
        # PieceMesh rotates wedge about Godot -Z: x' = old y, so solid x <= z.
        return prism(k,[(-w/2,-d/2),(w/2,d/2),(-w/2,d/2)],1,-h/2,h/2)
    if f=='stairs':
        # A single closed six-sided stair profile, no coplanar interior boxes.
        return prism(k,[(-h/2,-d/2),(0,-d/2),(0,0),(h/2,0),(h/2,d/2),(-h/2,d/2)],0,-w/2,w/2)
    return box(k,(0,-(1-h)/2 if f=='low' else 0,0),(w,h,d))
def clone(o,name,c):
    n=o.copy(); n.data=o.data.copy(); n.name=name; c.objects.link(n); return n
def grooves(o,k):
    w,h,d=shapes[k]['size_m']; dep=cfg['joint_depth_m']; gap=cfg['joint_width_m']
    if k in ('cube','wall_panel'):
        for sign in (-1,1):
            for x in (-.25,0,.25):
                boolean(o,box('recess cutter',(x,0,sign*(d/2-dep/2)),(gap,h-.13,dep*1.1)))
            for y in (-h/2+.065,h/2-.065):
                boolean(o,box('rail joint',(0,y,sign*(d/2-dep/2)),(w+.02,gap,dep*1.1)))
    elif k in ('floor_slab','stairs','codex_corner_floor'):
        for x in (-.25,0,.25):
            for y in ([0,h/2] if k=='stairs' else [-h/2,h/2]):
                sign=-1 if y<0 else 1
                zcentre=(-d*.25 if y==0 else d*.25) if k=='stairs' else 0
                span=d*.5 if k=='stairs' else d
                boolean(o,box('tread or soffit join',(x,y-sign*dep/2,zcentre),(gap,dep*1.1,span+.02)))
    elif k in ('beam','pillar'):
        # Narrow end checks, wholly backed, never projecting collars.
        for sign in (-1,1):
            if k=='beam': c=(sign*(w/2-.045),0,-d/2+dep/2); s=(gap,h*.55,dep*1.1)
            else: c=(0,sign*(h/2-.045),-d/2+dep/2); s=(w*.55,gap,dep*1.1)
            boolean(o,box('end check',c,s))
    # The diagonal mating face remains uninterrupted and dimensionally exact.
def stones(o,k):
    w,h,d=shapes[k]['size_m']; rng=random.Random(cfg['seed']+(0 if k=='foundation' else 1))
    # Replace finished copy with an inset, solid, dark backing and merged courses.
    bpy.data.objects.remove(o,do_unlink=True)
    o=box(k+' backed fieldstone',(0,-.5+h/2,0),(w-.055,h-.045,d-.055),finished)
    for row in range(cfg['fieldstone_courses']):
        n=3 if row==0 else 4; xs=[-w/2]+[-w/2+w*i/n+rng.uniform(-.025,.025) for i in range(1,n)]+[w/2]
        nz=3 if d>.5 else 1
        for i in range(n):
            for j in range(nz):
                lo=xs[i]+(cfg['fieldstone_joint_m']/2 if i else 0); hi=xs[i+1]-(cfg['fieldstone_joint_m']/2 if i<n-1 else 0)
                zlo=-d/2+d*j/nz+(cfg['fieldstone_joint_m']/2 if j else 0)
                zhi=-d/2+d*(j+1)/nz-(cfg['fieldstone_joint_m']/2 if j<nz-1 else 0)
                bottom=-.5+row*h/2+(cfg['fieldstone_joint_m']/2 if row else 0)
                top=-.5+(row+1)*h/2-(cfg['fieldstone_joint_m']/2 if row==0 else (0 if i==0 else rng.uniform(.004,cfg['fieldstone_relief_m'])))
                stone=box('dry laid stone',((lo+hi)/2,(bottom+top)/2,(zlo+zhi)/2),(hi-lo,top-bottom,zhi-zlo))
                bevel(stone,cfg['fieldstone_bevel_m']*rng.uniform(.8,1.5))
                original=[[min(v.co[a] for v in stone.data.vertices),max(v.co[a] for v in stone.data.vertices)] for a in range(3)]
                for v in stone.data.vertices:
                    for a in range(3): v.co[a]+=rng.uniform(-cfg['fieldstone_corner_wear_m'],cfg['fieldstone_corner_wear_m'])
                # Refit only each stone's tiny wear variation to its assigned bounds.
                # This preserves the exact outer native dimensions and closed backing.
                for a in range(3):
                    lo2=min(v.co[a] for v in stone.data.vertices); hi2=max(v.co[a] for v in stone.data.vertices)
                    for v in stone.data.vertices: v.co[a]=original[a][0]+(v.co[a]-lo2)/(hi2-lo2)*(original[a][1]-original[a][0])
                # Worn quads are nonplanar: resolve them into planar facets before
                # boolean evaluation, not after a union has intersected an n-gon.
                bm=bmesh.new(); bm.from_mesh(stone.data)
                bmesh.ops.triangulate(bm,faces=list(bm.faces),quad_method='FIXED',ngon_method='EAR_CLIP')
                bm.to_mesh(stone.data); bm.free()
                stone.data.update(); boolean(o,stone,'UNION')
    return o
def material(name,rgb):
    mat=bpy.data.materials.new(name); mat.use_nodes=True
    color=tuple((v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4) for v in rgb)+(1,)
    bs=mat.node_tree.nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=color; bs.inputs['Roughness'].default_value=cfg['roughness']; mat.diffuse_color=color
    return mat
palette=(snapshot/'game/art/building_look.gd').read_text()
hexwood=re.search(r'timber := Color\("([0-9a-f]+)"\)',palette)[1]
woodrgb=[int(hexwood[i:i+2],16)/255 for i in (0,2,4)]
wood=material('Provisional existing timber',woodrgb); stone=material('Provisional fieldstone',(.43,.425,.4)); clay=material('Neutral clay',(.58,.58,.57)); ground=material('Review ground',(.145,.165,.175))
# A small embedded sRGB grain atlas is inspection colour, superseded by the exact
# existing game material in the native review. No artificial glowing material.
for mat,rgb in [(wood,woodrgb),(stone,(.43,.425,.4))]:
    im=bpy.data.images.new(mat.name+' colour',width=128,height=256); px=[]
    for v in range(256):
        for u in range(128):
            if mat==wood: n=.08*math.sin(u*.8+math.sin(v*.04)*1.8)+.035*math.sin(u*2.8+v*.01)
            else: n=.035*math.sin(u*.8+v*1.3)+.025*math.sin(u*3.3-v*.9)
            px.extend([max(0,min(1,c*(1+n))) for c in rgb]+[1])
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
assets={}; report={'blender_version':bpy.app.version_string,'coordinate_mapping':'Blender (x,y,z) to Godot (x,z,-y), metres, centred native pose; low pieces local Y [-0.5,0]','assets':{},'controls':cfg,'lod_policy':'One bounded mesh at all distances; measured near/middle/far cost, no arbitrary decimation.'}
for k in ids:
    raw=base(k); obj=clone(raw,k+' finished',finished)
    if shapes[k].get('form')=='low': obj=stones(obj,k)
    else:
        # Bevelling a triangle's pointed corners shrinks its measured X/Z extent.
        # Preserve its exact mating planes instead of rescaling the finished cut.
        if shapes[k].get('form')!='corner': bevel(obj,cfg['edge_bevel_m'])
        grooves(obj,k)
    finish_topology(obj)
    uv(obj); obj.data.materials.append(stone if k in ('foundation','dry_wall') else wood)
    r=clone(obj,k,runtime); active(r); bpy.context.view_layer.update()
    # Local geometry contains the low-piece offset; object transforms stay identity.
    assert r.location.length<1e-7 and all(abs(v-1)<1e-7 for v in r.scale)
    info=stats(r); w,h,d=shapes[k]['size_m']; cy=-(1-h)/2 if shapes[k].get('form')=='low' else 0
    expected=[[-w/2,cy-h/2,-d/2],[w/2,cy+h/2,d/2]]
    assert max(abs(info['bounds'][i][a]-expected[i][a]) for i in range(2) for a in range(3))<1e-5,(k,info['bounds'],expected)
    bpy.ops.export_scene.gltf(filepath=str(out/'assets'/f'{k}.glb'),export_format='GLB',use_selection=True,export_yup=True,export_apply=True,export_cameras=False,export_lights=False)
    info.update(size_m=[w,h,d],pivot=[0,0,0],form=shapes[k].get('form','box'),sha256=hashlib.sha256((out/'assets'/f'{k}.glb').read_bytes()).hexdigest()); report['assets'][k]=info; assets[k]=r
source.hide_render=True; source.hide_viewport=True; finished.hide_render=True; finished.hide_viewport=True; runtime.hide_render=True; runtime.hide_viewport=True
def instance(k,at,angle=0):
    o=clone(assets[k],k+' review',review); o.location=xyz(at); o.rotation_euler.z=angle; return o
for i,k in enumerate(ids):
    x=(i%5-2)*1.75; z=(i//5)*2.1
    h=shapes[k]['size_m'][1]; lift=.5 if shapes[k].get('form')=='low' else h/2
    instance(k,(x,lift,z))
    textcurve=bpy.data.curves.new(k+' label','FONT'); textcurve.body=k.replace('codex_','').replace('_',' '); textcurve.size=.12; textcurve.align_x='CENTER'
    txt=bpy.data.objects.new(k+' label',textcurve); review.objects.link(txt); txt.location=xyz((x,.006,z-.7)); txt.rotation_euler.z=math.pi; txt.data.materials.append(clay)
floor=box('Review ground',(0,-.065,1),(200,.1,200),review); floor.data.materials.append(ground)
def camera(at,target,scale):
    if scene.camera is None:
        data=bpy.data.cameras.new('Inspection camera'); o=bpy.data.objects.new('Inspection camera',data); scene.collection.objects.link(o); scene.camera=o
    o=scene.camera; o.location=xyz(at); o.rotation_euler=(Vector(xyz(target))-o.location).to_track_quat('-Z','Y').to_euler(); o.data.type='ORTHO'; o.data.ortho_scale=scale
for at,power,size in [((2,7,-3),1800,5),((-5,4,1),1100,4),((2,5,7),1600,3)]:
    data=bpy.data.lights.new('Softbox','AREA'); data.energy=power; data.shape='DISK'; data.size=size
    o=bpy.data.objects.new('Softbox',data); scene.collection.objects.link(o); o.location=xyz(at); o.rotation_euler=(Vector(xyz((0,.3,1)))-o.location).to_track_quat('-Z','Y').to_euler()
scene.world.color=(.16,.16,.16); scene.render.engine='CYCLES'; scene.cycles.device='CPU'; scene.cycles.samples=cfg['render_samples']; scene.cycles.use_denoising=True
scene.render.resolution_x=1600; scene.render.resolution_y=1000; scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX'; camera((6,6,-9),(0,.35,1),10.5)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'core-lattice.blend'))
(out/'geometry.json').write_text(json.dumps(report,indent=2)+'\n')
scene.render.filepath=str(out/'evidence/blender-material.png'); bpy.ops.render.render(write_still=True)
scene.view_layers[0].material_override=clay; scene.render.filepath=str(out/'evidence/blender-neutral.png'); bpy.ops.render.render(write_still=True)
print('D1_BLENDER_BUILD_OK',json.dumps({k:v['triangles'] for k,v in report['assets'].items()}))
