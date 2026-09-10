"""Blender direct modelling. Run: blender -b -t 8 --python-exit-code 1 --python build.py -- SNAPSHOT OUTPUT.

Closed-solid helpers derive from ART-07D1; roofs, leaf, wedge and metal spans
are dimensioned here against the frozen current native contracts.
All coordinates below are Godot metres, converted exactly once for glTF export.
"""
import bpy, bmesh, json, math, sys, random, hashlib, re
from pathlib import Path
from mathutils import Vector

snapshot, out = map(Path, sys.argv[sys.argv.index('--')+1:])
cfg=json.loads(Path(__file__).with_name('settings.json').read_text())
ids=['codex_roof_slope','codex_roof_hip','codex_roof_valley','door','roof_wedge','girder','arch']
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

def clone(o,name,c):
    n=o.copy(); n.data=o.data.copy(); n.name=name; c.objects.link(n); return n

def roof(k,detail):
    w,h,d=shapes[k]['size_m']; n=cfg['roof_subdivisions'] if detail and k!='roof_wedge' else 2
    vs=[]; fs=[]
    for j in range(n+1):
        for i in range(n+1):
            u=i/n; v=j/n; x=u-.5; z=v-.5
            t=v if k in ('codex_roof_slope','roof_wedge') else min(u,v) if k=='codex_roof_hip' else max(u,v)
            y=-h/2+h*t
            if detail and k!='roof_wedge':
                # A continuous solid backing. Relief recedes from native planes;
                # every outer mating edge and the shared 0--2 diagonal stay exact.
                guard=min(u,1-u,v,1-v,abs(u-v) if k!='codex_roof_slope' else 1)
                taper=min(1,guard/cfg['roof_edge_guard_m'],t/.06)
                along=v if k=='codex_roof_slope' or (k=='codex_roof_hip' and v<u) or (k=='codex_roof_valley' and v>u) else u
                across=u if along==v else v
                row=int(along*cfg['roof_courses']+1e-6)
                f=(along*cfg['roof_courses'])%1
                seam=abs(((across*4+(.5 if row%2 else 0))%1)-.5)
                cut=max(f*.68,1.0 if seam<.035 else 0)
                y-=cfg['roof_joint_depth_m']*taper*cut
            vs.append((x*w,y,z*d))
    top_count=len(vs)
    for j in range(n):
        for i in range(n):
            a=j*(n+1)+i; b=a+1; c=b+n+1; e=a+n+1
            fs.extend([(a,b,c),(a,c,e)])
    ring=list(range(n+1))+[j*(n+1)+n for j in range(1,n+1)]+[n*(n+1)+i for i in range(n-1,-1,-1)]+[j*(n+1) for j in range(n-1,0,-1)]
    for a in ring: vs.append((vs[a][0],-h/2,vs[a][2]))
    for i,a in enumerate(ring):
        j=(i+1)%len(ring); fs.append((a,ring[j],top_count+j,top_count+i))
    fs.append(tuple(range(top_count,len(vs))))
    return mesh(k,vs,fs)

def arch(k):
    w,h,d=shapes[k]['size_m']; r=.4*w; p=[]
    # Preserve the exact twelve native strip steps, not a smooth proxy arch.
    for i in range(12):
        x0=-w/2+w*i/12; x1=-w/2+w*(i+1)/12; mid=(x0+x1)/2
        y=math.sqrt(max(0,r*r-mid*mid))-h/2 if abs(mid)<r else -h/2
        p.extend([(x0,y),(x1,y)])
    p.extend([(w/2,h/2),(-w/2,h/2)])
    return prism(k,p,2,-d/2,d/2)

def base(k,detail=False):
    s=shapes[k]; w,h,d=s['size_m']
    if 'roof' in k: return roof(k,detail)
    if k=='arch': return arch(k)
    if k=='door': w-=.06; h-=.06; d*=.5
    return box(k,(0,0,0),(w,h,d))

def blind(o,x,y,z,depth,sign,radius=.013):
    bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=radius,depth=depth*1.1,location=xyz((x,y,z-sign*depth*.45)),rotation=(math.pi/2,0,0))
    boolean(o,bpy.context.object)

def details(o,k):
    w,h,d=shapes[k]['size_m']; dep=cfg['join_depth_m']; gap=cfg['join_width_m']
    if k=='door':
        w-=.06; h-=.06; d*=.5
        bevel(o,.002)
        for sign in (-1,1):
            for x in [-.3,-.15,0,.15,.3]:
                boolean(o,box('Backed vertical leaf joint',(x,0,sign*(d/2-dep/2)),(gap,h-.13,dep*1.1)))
            for y in [-.78,.53]:
                # Wide inset panels leave broad flush straps/rails at native skin.
                for edge in [-.035,.035]:
                    boolean(o,box('Strap edge',(0,y+edge,sign*(d/2-dep/2)),(w-.11,gap,dep*1.1)))
                for x in [-.39,-.29,.29,.39]: blind(o,x,y,sign*d/2,dep,sign)
            # Recessed finger pull: part of the leaf, never an enlarged handle/body.
            blind(o,.31,-.05,sign*d/2,dep,sign,.045)
    elif k=='girder':
        bevel(o,.002)
        for sign in [-1,1]:
            dep=cfg['web_recess_m']
            boolean(o,box('Solid backed reinforced web',(0,0,sign*(d/2-dep/2)),(w-.2,h-.12,dep*1.1)))
            for x in [-.94,.94]:
                for y in [-.12,.12]: blind(o,x,y,sign*d/2,cfg['join_depth_m'],sign,.016)
    elif k=='arch':
        for sign in [-1,1]:
            for x in [-.45,.45]:
                for y in [-.35,.32]: blind(o,x,y,sign*d/2,dep,sign,.014)
            boolean(o,box('Head worked seam',(0,.41,sign*(d/2-dep/2)),(.77,gap,dep*1.1)))
    elif k=='roof_wedge':
        # Course joints on the two vertical cut faces, not additional roof layers.
        for sign in [-1,1]:
            for y in [-.24,.01,.26]:
                start=y+.025
                boolean(o,box('Masonry course',(sign*(w/2-dep/2),y,(start+.48)/2),(dep*1.1,gap,.48-start)))

def clean(o):
    bm=bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
    bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=1e-7)
    bmesh.ops.triangulate(bm,faces=list(bm.faces),quad_method='FIXED',ngon_method='EAR_CLIP')
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    assert all(e.is_manifold for e in bm.edges),o.name
    bm.to_mesh(o.data); bm.free(); o.data.update()

def material(name,rgb,metal=0):
    m=bpy.data.materials.new(name); m.use_nodes=True; bs=m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value=(*rgb,1); bs.inputs['Roughness'].default_value=.7; bs.inputs['Metallic'].default_value=metal
    im=bpy.data.images.new(name+' provisional sRGB',width=256,height=256); pixels=[]; rng=random.Random(cfg['seed'])
    for y in range(256):
        for x in range(256):
            n=.13*math.sin(x*.62+math.sin(y*.021)*3)+.035*math.sin(x*2.3+y*.011)+rng.uniform(-.03,.03) if name=='Timber' else rng.uniform(-.08,.08)+.025*math.sin(x*.09+math.sin(y*.04)*4)*math.sin(y*.13+x*.031)
            pixels.extend([max(.001,c*(1+n)) for c in rgb]+[1])
    im.colorspace_settings.name='sRGB'; im.pixels.foreach_set(pixels); im.pack()
    tex=m.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=im; m.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color']); return m

wood=material('Timber',(.29,.19,.095)); slate=material('Covering',(.23,.255,.27)); stone=material('Masonry',(.37,.35,.31)); iron=material('Iron',(.23,.25,.26),.75); bronze=material('Malleable bronze',(.39,.25,.11),.7)
clay=bpy.data.materials.new('Neutral clay'); clay.diffuse_color=(.5,.51,.5,1)
ground=bpy.data.materials.new('Review ground'); ground.diffuse_color=(.07,.085,.09,1)
assets={}; report={'blender_version':bpy.app.version_string,'assets':{},'controls':cfg,'coordinate_mapping':'Godot metres -> Blender (x,-z,y) -> glTF Y-up once','lod_policy':'Same source at near/middle/far; no approved runtime budget.'}
for k in ids:
    raw=base(k); clean(raw)
    o=base(k,True); move(o,finished); details(o,k); clean(o)
    o.data.materials.append(wood if k=='door' else iron if k=='girder' else bronze if k=='arch' else stone if k=='roof_wedge' else slate)
    layer=o.data.uv_layers.new(name='Metre surfaces')
    for f in o.data.polygons:
        axis=max(range(3),key=lambda a:abs(f.normal[a])); axes=[a for a in range(3) if a!=axis]
        for i in f.loop_indices:
            p=o.data.vertices[o.data.loops[i].vertex_index].co; layer.data[i].uv=(p[axes[0]],p[axes[1]])
    r=clone(o,k,runtime); r['catalogue_id']=k; active(r); bpy.context.view_layer.update()
    r.data.calc_loop_triangles(); points=[godot(v.co) for v in r.data.vertices]
    bounds=[[min(p[a] for p in points) for a in range(3)],[max(p[a] for p in points) for a in range(3)]]
    size=shapes[k]['size_m'].copy()
    if k=='door': size=[size[0]-.06,size[1]-.06,size[2]*.5]
    assert max(abs(bounds[i][a]-size[a]*(i-.5)) for i in range(2) for a in range(3))<1e-5,(k,bounds,size)
    assert all(t.area>1e-12 for t in r.data.loop_triangles) and all(math.isfinite(v) for p in points for v in p)
    bpy.ops.export_scene.gltf(filepath=str(out/'assets'/f'{k}.glb'),export_format='GLB',use_selection=True,export_yup=True,export_apply=True,export_cameras=False,export_lights=False)
    report['assets'][k]={'vertices':len(r.data.vertices),'triangles':len(r.data.loop_triangles),'surfaces':len(r.data.materials),'bounds':bounds,'pivot':[0,0,0],'sha256':hashlib.sha256((out/'assets'/f'{k}.glb').read_bytes()).hexdigest(),'nonmanifold_edges':0,'degenerate_triangles':0}; assets[k]=r
for c in [source,finished,runtime]: c.hide_render=True; c.hide_viewport=True
for i,k in enumerate(ids):
    o=clone(assets[k],k+' review',review); x=(i%4-1.5)*2; z=(i//4)*2.8; o.location=xyz((x,.97 if k=='door' else shapes[k]['size_m'][1]/2,z))
    if k=='door':
        hinge=bpy.data.objects.new('Door hinge - native two-state control',None); review.objects.link(hinge)
        hinge.location=xyz((x-.5,.97,z)); hinge.empty_display_type='ARROWS'; hinge.empty_display_size=.18
        hinge['open']=False; hinge['contract']='False: closed; True: -90 degree native state. No opening tween.'
        o.parent=hinge; o.location=(.5,0,0)
        driver=hinge.driver_add('rotation_euler',2).driver; variable=driver.variables.new(); variable.name='opened'; variable.type='SINGLE_PROP'
        variable.targets[0].id=hinge; variable.targets[0].data_path='["open"]'; driver.expression='-1.5707963267948966 if opened else 0.0'
    curve=bpy.data.curves.new(k+' label','FONT'); curve.body=k.replace('codex_','').replace('_',' '); curve.size=.13; curve.align_x='CENTER'
    t=bpy.data.objects.new(k+' label',curve); review.objects.link(t); t.location=xyz((x,.01,z-.8)); t.rotation_euler.z=math.pi; curve.materials.append(clay)
floor=box('Review ground',(0,-.08,1),(200,.1,200),review); floor.data.materials.append(ground)
data=bpy.data.cameras.new('Inspection camera'); cam=bpy.data.objects.new('Inspection camera',data); scene.collection.objects.link(cam); scene.camera=cam
cam.location=xyz((6,6,-9)); cam.rotation_euler=(Vector(xyz((0,.6,1)))-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.type='ORTHO'; cam.data.ortho_scale=9
for at,power,size in [((1,7,-3),1800,5),((-5,3,-1),1100,4),((2,5,7),1600,3)]:
    d=bpy.data.lights.new('Softbox','AREA'); d.energy=power; d.size=size; l=bpy.data.objects.new('Softbox',d); scene.collection.objects.link(l); l.location=xyz(at); l.rotation_euler=(Vector(xyz((0,.5,1)))-l.location).to_track_quat('-Z','Y').to_euler()
scene.world.color=(.16,.16,.16); scene.render.engine='CYCLES'; scene.cycles.device='CPU'; scene.cycles.samples=cfg['render_samples']; scene.cycles.use_denoising=True
scene.render.resolution_x=1600; scene.render.resolution_y=1000; scene.render.resolution_percentage=100; scene.view_settings.view_transform='AgX'
bpy.ops.wm.save_as_mainfile(filepath=str(out/'roof-joinery-spans.blend'))
(out/'geometry.json').write_text(json.dumps(report,indent=2)+'\n')
for mode in ['material','neutral']:
    scene.view_layers[0].material_override=clay if mode=='neutral' else None; scene.render.filepath=str(out/'evidence'/('blender-'+mode+'.png')); bpy.ops.render.render(write_still=True)
print('D2_BLENDER_BUILD_OK',json.dumps({k:v['triangles'] for k,v in report['assets'].items()}))
