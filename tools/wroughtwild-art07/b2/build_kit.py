"""B2 ordinary understory kit. Fresh output; sources immutable; metres."""
import bpy,bmesh,json,math,random,sys,hashlib
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
sys.path.insert(0,str(Path(__file__).parent))
from geometry import Mesh,tube,leaf
source,depot,out=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]]
cfg=json.loads((Path(__file__).parent/'kit.json').read_text())
assert not out.exists();out.mkdir(parents=True);(out/'assets').mkdir();(out/'renders').mkdir()
bpy.ops.wm.open_mainfile(filepath=str(source))
raw=[o for o in bpy.context.scene.objects if o.type=='MESH']
for o in list(bpy.context.scene.objects):
    if o not in raw:bpy.data.objects.remove(o,do_unlink=True)
collections={}
for name in ['SOURCE immutable normalized','FINISHED specimens','RUNTIME variants','REVIEW composition']:
    c=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(c);collections[name.split()[0]]=c
def move(o,key):
    for c in list(o.users_collection):c.objects.unlink(o)
    collections[key].objects.link(o)
for o in raw:move(o,'SOURCE');o.hide_render=True;o.hide_set(True)
def material(name,color,vertex=False,texture=None):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;m.use_backface_culling=False
    bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=.84
    if vertex:
        n=m.node_tree.nodes.new('ShaderNodeVertexColor');n.layer_name='Plant colour';m.node_tree.links.new(n.outputs['Color'],bs.inputs['Base Color'])
    if texture:
        n=m.node_tree.nodes.new('ShaderNodeTexImage');n.image=bpy.data.images.load(str(texture));m.node_tree.links.new(n.outputs['Color'],bs.inputs['Base Color'])
        uv=m.node_tree.nodes.new('ShaderNodeTexCoord');sep=m.node_tree.nodes.new('ShaderNodeSeparateXYZ');combine=m.node_tree.nodes.new('ShaderNodeCombineXYZ')
        m.node_tree.links.new(uv.outputs['UV'],sep.inputs[0])
        for axis in ['X','Y']:
            p=m.node_tree.nodes.new('ShaderNodeMath');p.operation='PINGPONG';p.inputs[1].default_value=1
            m.node_tree.links.new(sep.outputs[axis],p.inputs[0]);m.node_tree.links.new(p.outputs[0],combine.inputs[axis])
        m.node_tree.links.new(combine.outputs[0],n.inputs['Vector'])
    return m
green=material('Ordinary leaf opaque',(.12,.21,.055),True)
bark=material('Ordinary stems opaque',(.11,.075,.035),True)
mossmat=material('Moss and lichen opaque',(.13,.18,.05),True)
littermat=material('Litter chips opaque',(.18,.10,.045),True)
floorpath=depot/'docs/art/leyline-studies/2026-09-09/grove-art02/forest-floor.png'
soil=material('Approved grove litter mirrored',(.18,.13,.07),texture=floorpath)
assets={};report={'roles':{},'source':str(source),'source_hash':hashlib.sha256(source.read_bytes()).hexdigest(),'attachments':[]}
def export(role,objects):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.hide_set(False);o.hide_render=False;o.select_set(True);move(o,'RUNTIME')
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.export_scene.gltf(filepath=str(out/'assets'/(role+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_all_vertex_colors=True)
    count=0
    for o in objects:o.data.calc_loop_triangles();count+=len(o.data.loop_triangles);o.hide_set(True);o.hide_render=True
    report['roles'][role]={'triangles':count,'surfaces':sum(len(o.data.materials) for o in objects)}
    assets[role]=objects
def group(role,foliage,stems=None,mat=green):
    objs=[foliage.obj(role+' foliage',mat)]
    if stems and stems.v:objs.append(stems.obj(role+' stems',bark))
    export(role,objs)
# Clean generated source copy once. Preserve source collection; retain largest rooted component.
host=raw[0].copy();host.data=raw[0].data.copy();bpy.context.collection.objects.link(host);host.hide_set(False)
bm=bmesh.new();bm.from_mesh(host.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001)
unseen=set(bm.verts);groups=[]
while unseen:
    start=unseen.pop();stack=[start];groupv=[start]
    while stack:
        v=stack.pop()
        for e in v.link_edges:
            n=e.other_vert(v)
            if n in unseen:unseen.remove(n);stack.append(n);groupv.append(n)
    groups.append(groupv)
largest=max(groups,key=len);bmesh.ops.delete(bm,geom=[v for g in groups if g is not largest for v in g],context='VERTS')
bmesh.ops.dissolve_degenerate(bm,dist=.000005,edges=list(bm.edges));bm.to_mesh(host.data);bm.free()
host.name='FINISHED rooted shrub';move(host,'FINISHED');host.hide_render=True
report['source_components']={'count':len(groups),'retained_vertices':len(largest),'removed_vertices':sum(len(g) for g in groups if g is not largest)}
for lod,target in enumerate(cfg['shrub_triangles']):
    ob=host.copy();ob.data=host.data.copy();bpy.context.collection.objects.link(ob);ob.hide_set(False);ob.name='shrub host'
    ob.data.calc_loop_triangles();mod=ob.modifiers.new('Measured woody simplification','DECIMATE');mod.ratio=min(1,target/len(ob.data.loop_triangles))
    bpy.context.view_layer.objects.active=ob;ob.select_set(True);bpy.ops.object.modifier_apply(modifier=mod.name)
    base_offset=min(v.co.z for v in ob.data.vertices)
    for v in ob.data.vertices:v.co.z-=base_offset
    report.setdefault('lod_root_reseat_m',{})[str(lod)]=base_offset
    # Fine attached sprays start on inspected actual upper host vertices.
    rng=random.Random(42);candidates=[v.co.copy() for v in ob.data.vertices if v.co.z>.5]
    leaves=Mesh();stems=Mesh()
    for i in range(45):
        p=candidates[rng.randrange(len(candidates))];d=Vector((rng.uniform(-1,1),rng.uniform(-1,1),rng.uniform(.1,.5))).normalized();ln=rng.uniform(.08,.16)
        tube(stems,[p,p+d*ln],[.0025,.0008],sides=4)
        for j in range(3):
            a=p+d*ln*(.25+j*.28)
            for sign in [-1,1]:
                ld=Vector((-d.y*sign,d.x*sign,.3));leaf(leaves,a,ld,.065,.019,(.105,.165,.046),lod)
    export('sapling-shrub-lod'+str(lod),[ob,leaves.obj('attached shrub foliage',green),stems.obj('attached shrub stems',bark)])
# Ferns retain ART-02's rooted radial structure but add asymmetric double pinnae.
for variant,fronds in zip(['lush','sparse'],cfg['fern_fronds']):
 for lod in range(3):
    rng=random.Random(42+(variant=='sparse'));f=Mesh();s=Mesh()
    for i in range(fronds):
        rng=random.Random(42+(variant=='sparse')+i*977)
        a=i*math.tau/fronds+rng.uniform(-.25,.25);d=Vector((math.cos(a),math.sin(a),0));u=Vector((-d.y,d.x,0));ln=rng.uniform(.52,.9)
        path=[d*ln*t+Vector((0,0,.008+ln*(.84*math.sin(t*math.pi*.83)+.06*t))) for t in [j/20 for j in range(21)]]
        tube(s,path,[.005*(1-j/23) for j in range(21)],(.095,.14,.038),5 if lod==0 else 4)
        for j in range(3,20):
            t=j/20;p=path[j];length=.18*math.sin(t*math.pi)**.85+.012
            for side in [-1,1]:
                tangent=(path[min(j+1,20)]-path[j-1]).normalized()
                direction=(u*side+tangent*.42+Vector((0,0,.08*math.sin(j*1.9+i)))).normalized()
                if lod<2:
                    end=p+direction*length;tube(s,[p,end],[.0012,.00035],(.13,.20,.046),3)
                    for k in range(1,6):
                        pp=p+direction*length*k/6
                        for sign in [-1,1]:
                            ld=direction*.5+Vector((-direction.y,direction.x,.12*math.sin(k+i)))*sign
                            leaf(f,pp,ld,length*.32*(1-k/8),length*.075,(.10+rng.random()*.026,.19+rng.random()*.036,.035),lod)
                else:leaf(f,p,direction,length,length*.16,(.12,.215,.04),2)
    group('fern-'+variant+'-lod'+str(lod),f,s)
# Curved grass strips; every strip starts in the ground, equal roots at all LODs.
for variant,blades in zip(['meadow','edge'],cfg['grass_blades']):
 for lod in range(3):
    rng=random.Random(84+(variant=='edge'));m=Mesh()
    for i in range(blades):
        a=rng.random()*math.tau;r=math.sqrt(rng.random())*.22;p=Vector((r*math.cos(a),r*math.sin(a),.001))
        a=rng.random()*math.tau;h=rng.uniform(.18,.58)*(1 if variant=='meadow' else .45);d=Vector((math.cos(a),math.sin(a),0));u=Vector((-d.y,d.x,0))
        width=rng.uniform(.004,.012);segments=[8,4,2][lod];base=len(m.v);color=(.17+rng.random()*.08,.22+rng.random()*.045,.07)
        for j in range(segments):
            t=j/segments;pos=p+d*(h*t*t*(.7 if variant=='meadow' else 1.8))+Vector((0,0,h*math.sin(t*1.8)))
            for side in [-1,1]:m.vert(pos+u*width*(1-t*.8)*side,(side*.5+.5,t),color)
        tip=m.vert(p+d*h*(.7 if variant=='meadow' else 1.8)+Vector((0,0,h*math.sin(1.8))),(.5,1),color)
        for j in range(segments-1):a0=base+j*2;m.face(a0,a0+2,a0+3,a0+1)
        m.face(base+(segments-1)*2,tip,base+(segments-1)*2+1)
    group('grass-'+variant+'-lod'+str(lod),m)
# Approved deadfall is a read-only contextual support, not a new B3 asset.
bpy.ops.import_scene.gltf(filepath=str(depot/'build/grove-art02/emberroot-handoff/review/deadfall.glb'))
support=[o for o in bpy.context.selected_objects if o.type=='MESH'][0]
bvh=BVHTree.FromPolygons([support.matrix_world@v.co for v in support.data.vertices],[tuple(p.vertices) for p in support.data.polygons])
export('context-deadfall',[support])
for variant in ['bramble','climber']:
 for lod in range(3):
    rng=random.Random(126);f=Mesh();s=Mesh()
    for branch in range(3):
        path=[]
        for j in range(41):
            t=j/40
            if variant=='bramble':p=Vector((-.6+1.2*t,(branch-1)*.12+.16*math.sin(t*5+branch),.003+.48*math.sin(t*math.pi)))
            else:
                x=-1.92+3.05*t;y=.18*math.sin((x+2)/4*5)+(branch-1)*.095
                hit=bvh.ray_cast(Vector((x,y,3)),Vector((0,0,-1)))[0]
                assert hit is not None
                p=hit+Vector((0,0,.006))
            path.append(p)
        if variant=='climber':path.insert(0,Vector((-2.18,path[0].y,0)))
        tube(s,path,[.007*(1-j/(len(path)+3)) for j in range(len(path))],sides=5)
        for j in range(3,len(path)-1,2):
            p=path[j];d=(path[j+1]-path[j-1]).normalized()
            for side in [-1,1]:
                ld=Vector((-d.y*side,d.x*side,.28));leaf(f,p,ld,.12,.049,(.07,.13,.028),lod,ivy=variant=='climber')
            if lod==0:
                tube(s,[p,p+Vector((.009,.02,.015)),p+Vector((.018,.025,.045))],[.004,.002,.0002],(.20,.13,.055),3)
    group(variant+'-lod'+str(lod),f,s)
# Separate damp cushion and pale crust patches; irregular outlines, no alpha carpet.
for kind in ['moss','lichen']:
 for lod in range(3):
    rng=random.Random(168);m=Mesh()
    for k in range(22 if kind=='moss' else 13):
        x=rng.uniform(-.4,.4);y=rng.uniform(-.3,.3);r=rng.uniform(.045,.13)
        center=Vector((x,y,.032 if kind=='moss' else .003));idx=m.vert(center,(.5,.5),(.10,.16,.028) if kind=='moss' else (.29,.31,.21))
        n=[38,22,12][lod]
        for j in range(n):
            a=j/n*math.tau;radius=r*(.78+.16*math.sin(a*5+k)+.1*math.cos(a*11+k*3));z=.004 if kind=='moss' else .001
            m.vert((x+math.cos(a)*radius,y+math.sin(a)*radius,z),(math.cos(a)*.5+.5,math.sin(a)*.5+.5),(.14,.20,.042) if kind=='moss' else (.34,.35,.24))
        for j in range(n):m.face(idx,idx+1+j,idx+1+(j+1)%n)
        if kind=='moss':
            for tuft in range([55,24,8][lod]):
                a=rng.random()*math.tau;rr=rng.random()*r*.85
                pp=Vector((x+math.cos(a)*rr,y+math.sin(a)*rr,.006+.026*(1-rr/r)))
                for side in [-1,1]:
                    leaf(m,pp,(math.cos(a)*side*.3,math.sin(a)*side*.3,1),rng.uniform(.013,.027),.002,(.095+rng.random()*.055,.15+rng.random()*.06,.028),2)
    group(kind+'-lod'+str(lod),m,mat=mossmat)
# Litter silhouette chips plus separate needle fans over the tiling floor material.
for kind in ['leaf-litter','needle-litter']:
 for lod in range(3):
    rng=random.Random(210);m=Mesh()
    for i in range(32):
        p=Vector((rng.uniform(-.48,.48),rng.uniform(-.4,.4),.001+rng.random()*.012));a=rng.random()*math.tau
        if kind=='leaf-litter':leaf(m,p,(math.cos(a),math.sin(a),.03),rng.uniform(.07,.14),.026,(.16+rng.random()*.06,.10,.044),lod,True)
        else:
            for j in range(3):leaf(m,p,(math.cos(a+j*.13),math.sin(a+j*.13),.02),.12,.0018,(.13,.09,.036),2)
    group(kind+'-lod'+str(lod),m,mat=littermat)
# One authored route, patch density/role tied to local pockets, not blanket world scatter.
rng=random.Random(42);layout=[]
def place(role,x,z,scale=1,yaw=0):layout.append({'role':role,'position':[x,0,z],'scale':scale,'yaw':yaw})
for role,x,z,scale in [('sapling-shrub',-2.5,0,1),('sapling-shrub',2.8,-3,.85),('sapling-shrub',-3.3,-7,1.12),('sapling-shrub',3.3,-11,1),('context-deadfall',-2.9,-4,1),('climber',-2.9,-4,1),('bramble',3,-7,1)]:
    place(role,x,z,scale)
for cx,cz,role,n in [(-2,-1,'fern-lush',9),(2,-5,'fern-sparse',7),(-2.7,-8,'fern-lush',8),(2.2,0,'grass-meadow',18),(-2.5,-11,'grass-meadow',14),(2.5,-10,'grass-edge',16),(-2.5,-4,'moss',14),(3,-7,'lichen',10),(-2,-7,'leaf-litter',15),(2,-11,'needle-litter',14)]:
    for i in range(n):
        a=rng.random()*math.tau;r=math.sqrt(rng.random())*1.35;x=cx+math.cos(a)*r;z=cz+math.sin(a)*r
        if abs(x)<.82:continue
        place(role,x,z,rng.uniform(.7,1.2),rng.uniform(0,360))
for z in range(2,-14,-1):
    for sign in [-1,1]:
        place('grass-edge' if z>-4 else 'leaf-litter',sign*rng.uniform(.9,1.15),z,.6,rng.uniform(0,360))
(out/'layout.json').write_text(json.dumps(layout,indent=2))
# Blender composed inspection; linked assets do not change canonical pivots.
for row in layout:
    role=row['role'];obs=assets.get(role,assets.get(role+'-lod0'))
    parent=bpy.data.objects.new('REVIEW '+role,None);collections['REVIEW'].objects.link(parent);x,y,z=row['position'];parent.location=(x,-z,y);parent.rotation_euler.z=-math.radians(row['yaw']);parent.scale=(row['scale'],)*3
    for src in obs:
        ob=src.copy();ob.data=src.data;collections['REVIEW'].objects.link(ob);ob.parent=parent;ob.hide_set(False);ob.hide_render=False
ground=Mesh()
for p,uv in [((-7,-5,-.009),(-7/2.4,-5/2.4)),((7,-5,-.009),(7/2.4,-5/2.4)),((7,17,-.009),(7/2.4,17/2.4)),((-7,17,-.009),(-7/2.4,17/2.4))]:ground.vert(p,uv)
ground.face(0,1,2,3);g=ground.obj('Review floor',soil);move(g,'REVIEW')
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.resolution_x=1280;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Review sky');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.23,.28,.3,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
sun=bpy.data.objects.new('Sun',bpy.data.lights.new('Sun','SUN'));collections['REVIEW'].objects.link(sun);sun.rotation_euler=(.5,-.6,-.4);sun.data.energy=2.2
cam=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));collections['REVIEW'].objects.link(cam);scene.camera=cam;cam.data.lens=43
for name,at,target in [('composition',(7,-8,6),(0,4,.1)),('fern-close',(-.3,-1.8,.8),(-2,1,.25)),('shrub-close',(-.7,-2,1.2),(-2.5,0,.6)),('floor-close',(1.4,9,1.1),(2,11,0))]:
    cam.location=at;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(out/'renders'/(name+'.png'));bpy.ops.render.render(write_still=True)
for im in bpy.data.images:
    if im.source in ['FILE','GENERATED']:im.pack()
(out/'kit-report.json').write_text(json.dumps(report,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(out/'groundcover-master.blend'),compress=True);print('B2_KIT_OK')
