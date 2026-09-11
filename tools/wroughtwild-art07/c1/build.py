"""C1: measured native-fit bog oak, generated soft clay, attached fen plants.
Read-only B1/B2/B3 lineage; all writes are to a fresh C1 candidate directory.
Geometry helper derives from published B2; no normal-game edits.
"""
import bpy, bmesh, json, math, random, sys, hashlib
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
sys.path.insert(0,str(Path(__file__).parent))
from geometry import Mesh, tube, leaf

clay_source,out=map(lambda p:Path(p).resolve(),sys.argv[sys.argv.index('--')+1:])
assert not out.exists();out.mkdir(parents=True);(out/'models').mkdir()
cfg=json.loads(Path(__file__).with_name('kit.json').read_text());rng=random.Random(cfg['seed'])
depot=Path('C:/Users/Matty/Dev/project-wroughtwild')
b1=Path('C:/Users/Matty/Dev/project-wroughtwild-art07-b1/build/art07/b1/v01/canopy-handoff-v02/models/broadleaf')
bpy.ops.wm.read_factory_settings(use_empty=True);scene=bpy.context.scene
cols={n:bpy.data.collections.new(n) for n in ['SOURCE','FINISHED','RUNTIME','REVIEW']}
for c in cols.values():scene.collection.children.link(c)
assets={};report={'assets':{},'source_files':{},'transforms':{},'attachment_roots':[],'work_incisions':{}}

def move(o,c):
    for old in list(o.users_collection):old.objects.unlink(o)
    cols[c].objects.link(o)
def active(o):
    bpy.ops.object.select_all(action='DESELECT');o.hide_set(False);o.select_set(True);bpy.context.view_layer.objects.active=o
def clone(o,name,c='FINISHED'):
    n=o.copy();n.data=o.data.copy();n.name=name;cols[c].objects.link(n);n.hide_set(False);n.hide_render=False;return n
def load_meshes(path,prefix,c='SOURCE'):
    before=set(scene.objects);bpy.ops.import_scene.gltf(filepath=str(path))
    obs=[o for o in scene.objects if o not in before and o.type=='MESH']
    for i,o in enumerate(obs):
        active(o);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);o.parent=None;o.name=prefix+' '+str(i);move(o,c)
    for o in list(scene.objects):
        if o not in before and o.type!='MESH':bpy.data.objects.remove(o,do_unlink=True)
    report['source_files'][str(path)]=hashlib.sha256(path.read_bytes()).hexdigest()
    return obs
def clean(o):
    bm=bmesh.new();bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
    bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.000001)
    bmesh.ops.triangulate(bm,faces=list(bm.faces))
    tiny=[f for f in bm.faces if f.calc_area()<1e-12]
    if tiny:bmesh.ops.delete(bm,geom=tiny,context='FACES')
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free();o.data.update()
def reduce(o,target):
    o.data.calc_loop_triangles();count=len(o.data.loop_triangles)
    if count>target:
        active(o);m=o.modifiers.new('C1 silhouette reduction','DECIMATE');m.ratio=target/count;m.use_collapse_triangulate=True;bpy.ops.object.modifier_apply(modifier=m.name)
    clean(o)
def fit(obs,size):
    pts=np.array([v.co for o in obs for v in o.data.vertices]);lo=pts.min(0);hi=pts.max(0)
    for o in obs:
        for v in o.data.vertices:
            p=(np.array(v.co)-lo)/(hi-lo)*size;p[:2]-=np.array(size[:2])*.5;v.co=p
        o.data.update()
    return {'subtract':lo.tolist(),'scale':(np.array(size)/(hi-lo)).tolist(),'horizontal_center':[-size[0]/2,-size[1]/2]}
def material(name,color,vertex=False,rough=.84):
    m=bpy.data.materials.new(name);m.use_nodes=True;bs=m.node_tree.nodes['Principled BSDF'];bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=rough
    if vertex:
        a=m.node_tree.nodes.new('ShaderNodeVertexColor');a.layer_name='Plant colour';m.node_tree.links.new(a.outputs['Color'],bs.inputs['Base Color'])
    return m
def quiet_copy(m,name,gain=1):
    n=m.copy();n.name=name;bs=next(x for x in n.node_tree.nodes if x.type=='BSDF_PRINCIPLED')
    for link in list(n.node_tree.links):
        if link.to_socket in [bs.inputs['Emission Color'],bs.inputs['Emission Strength']]:n.node_tree.links.remove(link)
    bs.inputs['Emission Strength'].default_value=0;bs.inputs['Roughness'].default_value=.88
    if gain!=1:
        old=next((l.from_socket for l in n.node_tree.links if l.to_socket==bs.inputs['Base Color']),None)
        if old:
            mix=n.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(gain,gain*.97,gain*.92,1);n.node_tree.links.new(old,mix.inputs[1]);n.node_tree.links.new(mix.outputs[0],bs.inputs['Base Color'])
        else:
            bs.inputs['Base Color'].default_value=tuple(v*gain for v in bs.inputs['Base Color'].default_value[:3])+(1,)
    return n
def finish_obj(o,name):o.name=name;move(o,'FINISHED');return o
def cut_top(o,z,mat):
    bm=bmesh.new();bm.from_mesh(o.data)
    bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=(0,0,z),plane_no=(0,0,1),clear_outer=True,dist=.000001)
    edges=[e for e in bm.edges if e.is_boundary and all(abs(v.co.z-z)<.00001 for v in e.verts)]
    faces=bmesh.ops.holes_fill(bm,edges=edges,sides=0).get('faces',[])
    o.data.materials.append(mat);uv=bm.loops.layers.uv.verify()
    for f in faces:
        f.material_index=len(o.data.materials)-1
        for l in f.loops:l[uv].uv=(l.vert.co.x+.5,l.vert.co.y+.5)
    bmesh.ops.triangulate(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free();clean(o)
def stat(obs):
    pts=[];tris=deg=surfs=0
    for o in obs:
        o.data.calc_loop_triangles();tris+=len(o.data.loop_triangles);deg+=sum(t.area<1e-12 for t in o.data.loop_triangles);surfs+=len(o.data.materials)
        pts.extend([o.matrix_world@v.co for v in o.data.vertices])
    p=np.array(pts);assert np.isfinite(p).all();assert deg==0,(obs[0].name,deg)
    return {'objects':[o.name for o in obs],'triangles':tris,'surfaces':surfs,'bounds_blender_m':[p.min(0).tolist(),p.max(0).tolist()],'degenerates':deg}
def export(name,obs):
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs:o.hide_set(False);o.hide_render=False;o.select_set(True)
    bpy.context.view_layer.objects.active=obs[0]
    path=out/'models'/(name+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_all_vertex_colors=True,export_attributes=True)
    report['assets'][name]=stat(obs);assets[name]=obs
    for o in obs:o.hide_render=True;o.hide_set(True)

# Every LOD uses the SAME spatial field. Petioles, branches and leaves stay together.
oak_sources=[load_meshes(b1/('broadleaf-a-lod%d.glb'%i),'SOURCE B1 oak L%d'%i) for i in range(3)]
maxrad=max(math.hypot(v.co.x,v.co.y) for obs in oak_sources for o in obs for v in o.data.vertices if v.co.z-.65<=3.0)
lower_factor=(cfg['oak_body_radius_m']-.025)/maxrad
def oak_transform(p):
    z=p.z-.65;t=max(0,min(1,(z-cfg['oak_crown_start_m'])/(cfg['oak_crown_spread_m']-cfg['oak_crown_start_m'])));t=t*t*(3-2*t)
    # Radial compression retains a substantial trunk; a single source-wide factor
    # pinched the trunk into a reed in v02 because low branch tips set that factor.
    radius=.235+.07*math.exp(-(max(0,z)/.48)**2)
    r=math.hypot(p.x,p.y);fitted=radius*math.tanh(r/radius)/max(r,.000001)
    factor=fitted*(1-t)+.82*t
    return Vector((p.x*factor+.018*math.sin(max(0,z)*.8)+max(0,z-3)*cfg['oak_upper_lean_m_per_m'],p.y*factor,z))
report['transforms']['oak']={'burial_m':.65,'overhead_xz_scale':.82,'maximum_source_lower_radius':maxrad,'function':'radius=(.235+.07*exp(-(max(0,z)/.48)^2))*tanh(r/radius), smoothly blends to .82 overhead; same field for all attachments'}
cutmat=material('Bog oak dark cut end grain',(.20,.125,.062))
oakmats={}
for lod,srcs in enumerate(oak_sources):
    obs=[]
    for j,src in enumerate(srcs):
        o=clone(src,'bog-oak-%d-%d'%(lod,j),'RUNTIME')
        for v in o.data.vertices:v.co=oak_transform(v.co)
        o.data.update()
        for i,m in enumerate(o.data.materials):
            key=m.name.split('.')[0]
            if key not in oakmats:oakmats[key]=quiet_copy(m,'C1 '+key,.72 if 'bark' in key else 1)
            o.data.materials[i]=oakmats[key]
        if lod==2:reduce(o,8000 if j==0 else 2600)
        else:clean(o)
        obs.append(o)
    # Small knuckled surface roots stay inside the native radius. Long source
    # roots remain buried; these connect the visible stem to its wet foot.
    rootmesh=Mesh()
    for k in range(6):
        a=k*math.tau/6+.27;d=Vector((math.cos(a),math.sin(a),0))
        path=[d*.18+Vector((0,0,.25)),d*.25+Vector((0,0,.11)),d*.305+Vector((0,0,.012))]
        tube(rootmesh,path,[.042,.043,.016],(.09,.063,.035),8 if lod==0 else 5)
    root=finish_obj(rootmesh.obj('C1 knuckled roots L%d'%lod,material('C1 root grain L%d'%lod,(.1,.07,.04),True)),'C1 knuckled roots L%d'%lod);clean(root);obs.append(root)
    export('bog-oak-full-lod%d'%lod,obs)
    worked=[clone(o,'worked '+o.name,'RUNTIME') for o in obs]
    depths=[]
    for o in worked:
        # Physical hollow at the existing low work face; original source is retained.
        for v in o.data.vertices:
            p=v.co.copy();r=math.hypot(p.x,p.y)
            w=math.exp(-((p.z-.76)/.15)**4)*math.exp(-((p.x-.02)/.12)**4)*max(0,min(1,-p.y/.08))
            if r>.04:
                depth=min(cfg['oak_notch_depth_m']*w,r*.48);v.co.x*=1-depth/r;v.co.y*=1-depth/r;depths.append(depth)
        clean(o)
    report['work_incisions']['oak_lod%d'%lod]=max(depths)
    export('bog-oak-worked-lod%d'%lod,worked)
    stump=[]
    for o in obs:
        if any(v.co.z<.43 for v in o.data.vertices):
            s=clone(o,'stump '+o.name,'RUNTIME');cut_top(s,.43,cutmat)
            if s.data.vertices:stump.append(s)
    export('bog-oak-stump-lod%d'%lod,stump)

raw=load_meshes(clay_source,'SOURCE immutable generated clay')
clay=[clone(o,'FINISHED soft clay') for o in raw]
report['transforms']['clay']=fit(clay,cfg['clay_size_blender_m'])
for o in clay:
    for i,m in enumerate(o.data.materials):o.data.materials[i]=quiet_copy(m,'Damp rustclay - retained original albedo and linear ORM')
    clean(o)
# Six real releases: 24,20,16,12,8,4; no invented intermediate inventory state.
for stage in range(7):
    for lod,target in enumerate([16000,6000,1800]):
        obs=[clone(o,'clay stage %d L%d'%(stage,lod),'RUNTIME') for o in clay]
        for o in obs:
            for v in o.data.vertices:
                x,y,z=v.co;w=math.exp(-((x+.08)/.60)**4)*math.exp(-((y+.08)/.52)**4)
                amount=cfg['clay_scoop_depth_m']*stage/6*w*min(1,max(0,z/.09))
                v.co.z=max(.003,z-amount)*(1-.06*stage)
            reduce(o,target)
        export(('clay-%d'%max(0,24-stage*4))+'-lod%d'%lod,obs)

plantmat=material('C1 rooted reed and sedge colours',(.2,.23,.08),True,.76)
woodmat=material('Damp wood and fungus natural colours',(.13,.09,.04),True,.88)
# Fixed plant specifications reused across LODs and work stages.
stalks=[]
for i in range(cfg['reed_stalks']):
    a=rng.random()*math.tau;r=.34*math.sqrt(rng.random());p=Vector((math.cos(a)*r,math.sin(a)*r,0))
    h=rng.uniform(.82,cfg['reed_height_m']-.13);lean=Vector((rng.uniform(-.045,.045),rng.uniform(-.045,.045),0))
    stalks.append((p,h,lean,rng.uniform(.10,.16)))
for left in [24,18,12,6,0]:
    for lod in range(3):
        m=Mesh();live=int(left/24*len(stalks))
        for i,(p,h,lean,shade) in enumerate(stalks):
            if i>=live:
                tube(m,[p,p+Vector((0,0,.07+(i%3)*.012))],[.008,.007],(.26,.20,.09),5);continue
            top=p+lean+Vector((0,0,h));path=[p,p+lean*.4+Vector((0,0,h*.45)),top]
            tube(m,path,[.012,.009,.006],(shade*.9,shade,.047),6 if lod<2 else 4)
            tube(m,[top,top+Vector((0,0,.07)),top+Vector((0,0,.125))],[.017,.025,.006],(.16,.105,.045),8 if lod==0 else 5)
            for k in range(3 if lod<2 else 2):
                t=.22+k*.20;q=p+lean*t+Vector((0,0,h*t));a=i*2.39+k*2.3;d=Vector((math.cos(a)*.6,math.sin(a)*.6,.8))
                leaf(m,q,d,.25,.018,(shade,shade*1.2,.052),lod)
                if left==24 and lod==0:report['attachment_roots'].append({'asset':'reed-24-lod0','root':list(q),'kind':'leaf_to_stalk'})
        o=finish_obj(m.obj('Reed %d L%d'%(left,lod),plantmat),'Reed %d L%d'%(left,lod));clean(o);export('reed-%d-lod%d'%(left,lod),[o])
for lod in range(3):
    m=Mesh();rr=random.Random(cfg['seed']+101)
    for i in range(52 if lod==0 else (30 if lod==1 else 16)):
        a=rr.random()*math.tau;r=rr.uniform(0,.08);p=Vector((math.cos(a)*r,math.sin(a)*r,0));h=rr.uniform(.14,cfg['sedge_height_m']);d=Vector((math.cos(a)*.8,math.sin(a)*.8,.72))
        leaf(m,p,d,h,.012,(.095,.14,.052),lod)
    o=finish_obj(m.obj('Short splayed sedge L%d'%lod,plantmat),'Short sedge L%d'%lod);clean(o);export('fen-sedge-lod%d'%lod,[o])

# Small rotten wood uses B1's approved side-grounded cut source, not a new harvest log.
deadsrc=load_meshes(b1/'broadleaf-deadwood.glb','SOURCE B1 inert cut wood')
for lod in range(3):
    wood=[clone(o,'Fungal wood L%d'%lod,'RUNTIME') for o in deadsrc];fit(wood,[.83,.32,.18])
    for o in wood:
        reduce(o,[4200,1800,650][lod])
        for i,m in enumerate(o.data.materials):o.data.materials[i]=quiet_copy(m,'Unlit rotten bog wood',.8)
    # Mushrooms seated by rays on actual parent triangles, separate closed cap undersides.
    verts=[];faces=[]
    for o in wood:
        off=len(verts);verts.extend([v.co.copy() for v in o.data.vertices]);faces.extend([tuple(off+i for i in p.vertices) for p in o.data.polygons])
    bv=BVHTree.FromPolygons(verts,faces);m=Mesh()
    for i,x in enumerate([-.28,-.15,.04,.24]):
        hit,_,_,_=bv.ray_cast(Vector((x,0,1)),Vector((0,0,-1)))
        assert hit is not None
        root=hit-Vector((0,0,.008));h=.08+i*.009;top=root+Vector((.015,0,h));tube(m,[root,top],[.009,.006],(.29,.22,.13),6)
        rings=5 if lod==0 else 3;segments=18 if lod==0 else 10;base=len(m.v);radius=.047+i*.008
        # Closed domed cap with cream rim and flat supporting underside.
        for j in range(rings+1):
            a=(j/rings)*math.pi/2;r=radius*math.sin(a);z=.035*math.cos(a)
            for k in range(segments):
                az=k/segments*math.tau;col=(.20,.105,.045) if j<rings else (.43,.34,.20)
                m.vert(top+Vector((r*math.cos(az),r*math.sin(az),z)),(k/segments,j/rings),col)
        for j in range(rings):
            for k in range(segments):
                a=base+j*segments+k;b=base+j*segments+(k+1)%segments;m.face(a,b,b+segments,a+segments)
        m.face(*[base+rings*segments+k for k in reversed(range(segments))])
        if lod==0:report['attachment_roots'].append({'asset':'fungal-detritus-lod0','root':list(root),'kind':'fungus_to_actual_wood','embed_m':.008})
    for x in [-.16,.16]:
        hit,_,_,_=bv.ray_cast(Vector((x,-1,.105)),Vector((0,1,0)))
        assert hit is not None
        base=len(m.v);segments=20 if lod==0 else 10;origin=hit+Vector((0,.008,0))
        # Two closed semicircular shelves embedded in the actual parent side.
        for dz in [0,.012]:
            m.vert(origin+Vector((0,0,dz)),(.5,.5),(.19,.105,.05))
            for k in range(segments+1):
                a=k/segments*math.pi;p=origin+Vector((.072*math.cos(a),-.067*math.sin(a),dz+.014*math.sin(a)))
                m.vert(p,(k/segments,dz/.012),(.44,.32,.18))
        top=base+segments+2
        for k in range(segments):
            m.face(base,base+k+2,base+k+1);m.face(top,top+k+1,top+k+2);m.face(base+k+1,base+k+2,top+k+2,top+k+1)
        m.face(base,base+1,top+1,top);m.face(base,top,top+segments+1,base+segments+1)
        if lod==0:report['attachment_roots'].append({'asset':'fungal-detritus-lod0','root':list(origin),'kind':'shelf_to_actual_wood','embed_m':.008})
    fungus=finish_obj(m.obj('Shelf fungi and small caps L%d'%lod,woodmat),'Small caps L%d'%lod);clean(fungus)
    # Eliminate zero-area cap-pole triangles by welding the actual mesh pole.
    export('fungal-detritus-lod%d'%lod,wood+[fungus])

for col in ['SOURCE','FINISHED','RUNTIME']:
    for o in cols[col].objects:o.hide_set(True);o.hide_render=True
for name,at in [('bog-oak-full-lod0',(-2,1,0)),('bog-oak-worked-lod0',(2,2,0)),('clay-24-lod0',(-1,-1.8,0)),('clay-8-lod0',(1.2,-1.8,0)),('reed-24-lod0',(3,-1,0)),('reed-6-lod0',(4.2,-1,0)),('fen-sedge-lod0',(-2.2,-1.5,0)),('fungal-detritus-lod0',(0,-2.4,0)),('bog-oak-stump-lod0',(-3,-1,0))]:
    for o in assets[name]:n=clone(o,'REVIEW '+name,'REVIEW');n.location=at
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=20;scene.cycles.use_denoising=True
scene.render.resolution_x=1440;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Neutral overcast');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.30,.34,.37,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.75
sun=bpy.data.objects.new('Daylight',bpy.data.lights.new('Daylight','SUN'));scene.collection.objects.link(sun);sun.data.energy=2;sun.rotation_euler=(.6,-.5,-.6)
cam=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));scene.collection.objects.link(cam);scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=17;cam.location=(14,-19,12);cam.rotation_euler=(Vector((.6,0,3.6))-cam.location).to_track_quat('-Z','Y').to_euler()
for im in bpy.data.images:
    if im.has_data and im.source in ['FILE','GENERATED']:im.pack()
report['packed_images']=[{'name':im.name,'size':list(im.size)} for im in bpy.data.images if im.packed_file]
(out/'models.json').write_text(json.dumps(report,indent=2)+'\n')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'c1-master.blend'),compress=True)
scene.render.filepath=str(out/'blender-kit.png');bpy.ops.render.render(write_still=True)
print('C1_BUILD_OK',len(assets))
