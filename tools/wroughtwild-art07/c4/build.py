"""C4 Blender finish: fitted ash variants and B2-derived surviving scrub."""
import bpy,bmesh,json,math,random,sys,shutil
from pathlib import Path
from mathutils import Vector,Matrix
from mathutils.bvhtree import BVHTree
sys.path.insert(0,str(Path(__file__).parent))
from prerequisites import PACKAGES,sha
from geometry import Mesh,tube,leaf
source,out=map(lambda p:Path(p).resolve(),sys.argv[sys.argv.index('--')+1:])
assert not out.exists();out.mkdir(parents=True);(out/'models').mkdir()
cfg=json.loads((Path(__file__).parent/'kit.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(source))
raw=next(o for o in bpy.context.scene.objects if o.type=='MESH')
for o in list(bpy.context.scene.objects):
    if o!=raw:bpy.data.objects.remove(o,do_unlink=True)
collections={}
for name in ['SOURCE immutable','FINISHED ash and scrub','RUNTIME candidates','REVIEW']:
    c=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(c);collections[name.split()[0]]=c
def move(o,key):
    for c in list(o.users_collection):c.objects.unlink(o)
    collections[key].objects.link(o)
def hidden(o):
    o.hide_set(True);o.hide_render=True
def clone(o,name,key='FINISHED'):
    n=o.copy();n.data=o.data.copy();bpy.context.scene.collection.objects.link(n);n.name=name;n.hide_set(False);n.hide_render=False;move(n,key);return n
def clean(o):
    bm=bmesh.new();bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=0.000002)
    bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.000002)
    bm.to_mesh(o.data);bm.free();o.data.update()
def material(name,color,vertex=False):
    m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
    bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=.9
    if vertex:
        n=m.node_tree.nodes.new('ShaderNodeVertexColor');n.layer_name='Plant colour';m.node_tree.links.new(n.outputs['Color'],bs.inputs['Base Color'])
    return m
cutmat=material('Pale broken end grain',(.36,.29,.20))
plantmat=material('Quiet surviving foliage',(.18,.19,.07),True)
stemmat=material('Weathered thorn stems',(.19,.13,.075),True)
move(raw,'SOURCE');raw.name='SOURCE normalized ash unchanged';hidden(raw)
host=clone(raw,'FINISHED body-fitted ash')
clean(host)
# Retain largest connected generated host; record detached fragments.
bm=bmesh.new();bm.from_mesh(host.data);unseen=set(bm.verts);groups=[]
while unseen:
    stack=[unseen.pop()];g=[]
    while stack:
        v=stack.pop();g.append(v)
        for e in v.link_edges:
            other=e.other_vert(v)
            if other in unseen:unseen.remove(other);stack.append(other)
    groups.append(g)
main=max(groups,key=len);removed=sum(len(g) for g in groups if g is not main)
bmesh.ops.delete(bm,geom=[v for g in groups if g is not main for v in g],context='VERTS');bm.to_mesh(host.data);bm.free()
# Uniform horizontal fit below body top, smoothly restored upper branch reach.
radius=max(Vector((v.co.x,v.co.y)).length for v in host.data.vertices if v.co.z<=cfg['clear_bough_height_m'])
factor=min(1,cfg['body_radius_m']/radius)
for v in host.data.vertices:
    t=max(0,min(1,(v.co.z-2.6)/.55));t=t*t*(3-2*t);s=factor+(1-factor)*t
    v.co.x*=s;v.co.y*=s
host.data.update()
report={'source':{'path':str(source),'sha256':sha(source)},'removed_detached_vertices':removed,'lower_xy_factor':factor,'source_lower_radius_m':radius,'roles':{},'lineage':{},'scar':{},'attachments':[]}
def cap(o,z,keep_below):
    bm=bmesh.new();bm.from_mesh(o.data)
    result=bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,plane_co=(0,0,z),plane_no=(0,0,1),clear_outer=keep_below,clear_inner=not keep_below)
    edges=[e for e in result['geom_cut'] if isinstance(e,bmesh.types.BMEdge) and e.is_boundary]
    faces=bmesh.ops.holes_fill(bm,edges=edges,sides=0)['faces'] if edges else []
    uv=bm.loops.layers.uv.active
    idx=len(o.data.materials);o.data.materials.append(cutmat)
    for f in faces:
        f.normal_update()
        if (f.normal.z<0 if keep_below else f.normal.z>0):f.normal_flip()
        f.material_index=idx
        for l in f.loops:
            if uv:l[uv].uv=(l.vert.co.x+0.5,l.vert.co.y+0.5)
    assert len(faces)>0,('Missing cut closure',o.name,z)
    bm.normal_update();bm.to_mesh(o.data);bm.free();clean(o)
    return len(faces)
def export(name,obs):
    bpy.ops.object.select_all(action='DESELECT')
    pts=[]
    for o in obs:
        o.hide_set(False);o.hide_render=False;o.select_set(True);move(o,'RUNTIME')
        clean(o);pts += [o.matrix_world@v.co for v in o.data.vertices]
    bpy.context.view_layer.objects.active=obs[0]
    bpy.ops.export_scene.gltf(filepath=str(out/'models'/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_all_vertex_colors=True,export_texcoords=True)
    tris=0
    for o in obs:o.data.calc_loop_triangles();tris+=len(o.data.loop_triangles);hidden(o)
    report['roles'][name]={'triangles':tris,'surfaces':sum(len(o.data.materials) for o in obs),'bounds':[[min(p[i] for p in pts) for i in range(3)],[max(p[i] for p in pts) for i in range(3)]]}
def reduce(o,target):
    o.data.calc_loop_triangles()
    if len(o.data.loop_triangles)>target:
        bpy.ops.object.select_all(action='DESELECT');o.hide_set(False);o.select_set(True);bpy.context.view_layer.objects.active=o
        mod=o.modifiers.new('Silhouette detail candidate','DECIMATE');mod.ratio=target/len(o.data.loop_triangles)
        bpy.ops.object.modifier_apply(modifier=mod.name)
    clean(o)
hidden(host)
for lod,target in enumerate(cfg['targets']):
    a=clone(host,'ash-a-lod'+str(lod));reduce(a,target)
    # Re-seat each reduced root without moving original source.
    bottom=min(v.co.z for v in a.data.vertices)
    for v in a.data.vertices:v.co.z-=bottom
    b=clone(a,'ash-b-lod'+str(lod))
    for v in b.data.vertices:
        t=max(0,(v.co.z-2.6)/1.8);angle=.55*t
        x,y=v.co.x,v.co.y;v.co.x=x*math.cos(angle)-y*math.sin(angle)+.24*t*t;v.co.y=x*math.sin(angle)+y*math.cos(angle)
    c=clone(a,'ash-short-lod'+str(lod));cap(c,3.3,True)
    # Scar on the front (+Y) upper face of the lower timber, measured displacement.
    alt=clone(a,'ash-altered-lod'+str(lod))
    uv2=alt.data.uv_layers.new(name='Scar depth and energy')
    changed={}
    for v in alt.data.vertices:
        p=v.co;centre=.045*math.sin(p.z*4)+.01
        width=cfg['scar_half_width_m'];d=abs(p.x-centre)
        gate=max(0,min(1,(p.z-.55)/.22))*max(0,min(1,(2.35-p.z)/.25))
        if p.y>.04 and d<width and gate>0:
            weight=(1-(d/width)**2)**2*gate
            depth=cfg['scar_depth_m']*weight;p.y-=depth;changed[v.index]=(depth,weight)
    for l in alt.data.loops:
        depth,weight=changed.get(l.vertex_index,(0,0));uv2.data[l.index].uv=(weight,alt.data.vertices[l.vertex_index].co.z/4.4)
    report['scar'][str(lod)]={'requested_depth_m':cfg['scar_depth_m'],'measured_vertex_depth_m':max((x[0] for x in changed.values()),default=0),'moved_vertices':len(changed)}
    alt.data.update()
    if lod==0:
        before=clone(a,'MEASURE before scar','FINISHED');after=clone(alt,'MEASURE after scar','FINISHED');hidden(before);hidden(after)
    for n,o in [('ash-a',a),('ash-b',b),('ash-short',c),('ash-altered',alt)]:export(n+'-lod'+str(lod),[o])
    stump=clone(a,'ash-stump-lod'+str(lod));cap(stump,.42,True);export(stump.name,[stump])
    for variant,ref in [('a',a),('b',b)]:
        fell=clone(ref,'ash-felled-'+variant+'-lod'+str(lod));cap(fell,.44,False)
        rotation=Matrix.Rotation(math.pi/2,4,'Y')
        for v in fell.data.vertices:v.co=rotation@v.co
        xmin=min(v.co.x for v in fell.data.vertices);xmax=max(v.co.x for v in fell.data.vertices);zmin=min(v.co.z for v in fell.data.vertices)
        for v in fell.data.vertices:v.co.x-=(xmin+xmax)/2;v.co.z-=zmin
        export(fell.name,[fell])
# Reuse B2's actual rooted shrub and low bramble forms; finish dry sparse variants.
for role,source_role,scale in [('scrub','sapling-shrub',(.85,.85,.50)),('thorn','bramble',(.85,.85,.80))]:
    for lod in range(3):
        p=PACKAGES['b2'][0]/'review/assets'/(source_role+'-lod'+str(lod)+'.glb')
        report['lineage'][str(p)]=sha(p)
        bpy.ops.import_scene.gltf(filepath=str(p));obs=[o for o in bpy.context.selected_objects if o.type=='MESH']
        for o in obs:
            bpy.context.view_layer.objects.active=o;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
            for v in o.data.vertices:v.co=Vector((v.co.x*scale[0],v.co.y*scale[1],v.co.z*scale[2]))
            for attr in o.data.color_attributes:
                for cdata in attr.data:
                    c0=cdata.color;cdata.color=(c0[0]*1.15,c0[1]*.80,c0[2]*.85,1)
            if role=='thorn' and 'foliage' in o.name:
                bm=bmesh.new();bm.from_mesh(o.data);bm.verts.ensure_lookup_table()
                unseen=set(bm.verts);groups=[]
                while unseen:
                    first=min(unseen,key=lambda v:v.index);unseen.remove(first);stack=[first];g=[]
                    while stack:
                        v=stack.pop();g.append(v)
                        for e in v.link_edges:
                            other=e.other_vert(v)
                            if other in unseen:unseen.remove(other);stack.append(other)
                    groups.append(g)
                # Whole attached leaves are retained; never cut leaf polygons into debris.
                bmesh.ops.delete(bm,geom=[v for i,g in enumerate(groups) if i%4!=0 for v in g],context='VERTS')
                bm.to_mesh(o.data);bm.free()
            # Keep the generated host's original albedo/ORM and physical branch joins.
            o.name=role+' '+o.name
        export(role+'-lod'+str(lod),obs)
# Coarse bent grass with attached weathered seed heads. B2 mesh/tube technique.
for lod in range(3):
    rng=random.Random(42);grass=Mesh();heads=Mesh();stems=Mesh()
    for i in range(42):
        angle=rng.random()*math.tau;rad=math.sqrt(rng.random())*.23;p=Vector((rad*math.cos(angle),rad*math.sin(angle),.003));d=Vector((math.cos(angle),math.sin(angle),0));u=Vector((-d.y,d.x,0));h=rng.uniform(.22,.59);width=rng.uniform(.005,.012);segments=[7,4,2][lod];base=len(grass.v)
        color=(.13+rng.random()*.04,.12+rng.random()*.025,.053)
        for j in range(segments):
            t=j/segments;pos=p+d*h*.45*t*t+Vector((0,0,h*t))
            for side in [-1,1]:grass.vert(pos+u*width*(1-t*.8)*side,(side*.5+.5,t),color)
        tip=grass.vert(p+d*h*.45+Vector((0,0,h)),(.5,1),color)
        for j in range(segments-1):a0=base+j*2;grass.face(a0,a0+2,a0+3,a0+1)
        grass.face(base+(segments-1)*2,tip,base+(segments-1)*2+1)
    for i in range(5):
        a=i*1.8;p=Vector((.11*math.cos(a),.11*math.sin(a),.002));end=p+Vector((.12*math.cos(a),.12*math.sin(a),.55+i*.035))
        tube(stems,[p,(p+end)/2,end],[.0024,.0018,.001],(.23,.18,.08),sides=4)
        for j in range(4):
            pp=end-(end-p).normalized()*j*.015;direction=Vector((math.cos(a+j),math.sin(a+j),.3))
            leaf(heads,pp,direction,.035,.009,(.30,.23,.12),2)
        report['attachments'].append({'lod':lod,'type':'seedhead','stem_tip':list(end),'head_start':list(end)})
    export('seed-grass-lod'+str(lod),[grass.obj('coarse surviving grass',plantmat),heads.obj('weathered seed heads',plantmat),stems.obj('attached seed stems',stemmat)])
# Existing ordinary ground/rock families are copied byte-for-byte as context.
for name in ['rock-shelf-lod0','talus-pebbles-lod0','boulder-full-lod0']:
    p=PACKAGES['b3'][0]/'models'/(name+'.glb')
    if not p.exists():continue
    shutil.copy2(p,out/'models'/p.name);report['lineage'][str(p)]=sha(p)
for im in bpy.data.images:
    if im.has_data and im.source=='FILE':im.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(out/'c4-master.blend'),compress=True)
(out/'models.json').write_text(json.dumps(report,indent=2)+'\n')
shutil.copy2(Path(__file__).parent/'kit.json',out/'kit.json')
print('C4_BUILD_OK',len(report['roles']),factor)
