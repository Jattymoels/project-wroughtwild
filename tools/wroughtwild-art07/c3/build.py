"""C3: fit B1 oak ancestry, then cut wounds; finish separate finite cork deadwood.
Derivative export/material conventions from B1/B4; only task-local output changes.
"""
import bpy, bmesh, json, math, sys, random
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree
from mathutils.geometry import barycentric_transform
sys.path.insert(0,str(Path(__file__).parent))
from prerequisites import PACKAGES, sha
out=Path(sys.argv[sys.argv.index('--')+1]).resolve();assert not out.exists()
out.mkdir(parents=True);(out/'models').mkdir()
cfg=json.loads(Path(__file__).with_name('kit.json').read_text());tc=cfg['tree']
src=PACKAGES['b1'][0]/'models/broadleaf'
bpy.ops.wm.open_mainfile(filepath=str(src/'broadleaf-master.blend'))
base=bpy.data.objects['FINISHED broadleaf'];cut=bpy.data.objects['FINISHED deep injured oak']
high_points=[v.co.copy() for v in base.data.vertices]
high_faces=[tuple(p.vertices) for p in base.data.polygons]
high_tree=BVHTree.FromPolygons(high_points,high_faces)
weights={}
for loop in cut.data.loops: weights[loop.vertex_index]=cut.data.uv_layers[1].data[loop.index].uv.copy()
hero_depth=max(Vector((a.co.x-b.co.x,a.co.y-b.co.y,(a.co.z-b.co.z)*tc['vertical_scale'])).length for a,b in zip(base.data.vertices,cut.data.vertices))
bpy.ops.wm.read_factory_settings(use_empty=True);scene=bpy.context.scene
cols={}
for name in ['SOURCE','FINISHED','RUNTIME','REVIEW']:
    c=bpy.data.collections.new(name);scene.collection.children.link(c);cols[name]=c
report={'assets':{},'lineage':[], 'scar':{},'transform':cfg['tree'],'full_width_hero_inherited_scar_depth_m':hero_depth};assets={}

def import_source(path):
    before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(path),import_pack_images=True)
    obs=[o for o in bpy.data.objects if o not in before and o.type=='MESH']
    for o in obs:
        matrix=o.matrix_world.copy();o.parent=None;o.matrix_world=matrix
        o.data.transform(o.matrix_world);o.matrix_world.identity()
        for c in list(o.users_collection):c.objects.unlink(o)
        cols['SOURCE'].objects.link(o);o.name='SOURCE '+o.name;o.hide_set(True);o.hide_render=True
    report['lineage'].append({'path':str(path),'sha256':sha(path)})
    return obs

def clone(o,name,col='RUNTIME'):
    n=o.copy();n.data=o.data.copy();n.name=name;cols[col].objects.link(n)
    n.hide_set(False);n.hide_render=False
    return n

def texmat(name,image,rough=.85):
    m=bpy.data.materials.new(name);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Roughness'].default_value=rough
    n=m.node_tree.nodes.new('ShaderNodeTexImage');n.image=image
    m.node_tree.links.new(n.outputs['Color'],p.inputs['Base Color']);return m

def packed_image(name,pixels):
    im=bpy.data.images.new(name,width=pixels.shape[1],height=pixels.shape[0],alpha=True)
    im.pixels.foreach_set(pixels.astype(np.float32).ravel());im.pack();return im

n=512;yy,xx=np.mgrid[0:n,0:n]/n
r=np.sqrt((xx-.5)**2+(yy-.5)**2)
grain=np.sin(r*180+np.sin(xx*21)*.7+np.sin(yy*17)*.4)
amber=np.ones((n,n,4));amber[:,:,:3]=np.array([.48,.235,.072])*(.82+.14*grain[:,:,None])
amber[:,:,:3]+=np.sin(xx*581+np.sin(yy*30)*2)[:,:,None]*.02
amber_im=packed_image('C3 amber heartgrain sRGB',amber);amber_mat=texmat('C3 amber cut wood',amber_im)
longgrain=np.ones((n,n,4));ribbon=np.sin(yy*307+np.sin(xx*12)*2+np.sin(yy*51)*.45)
longgrain[:,:,:3]=np.array([.50,.29,.125])*(.82+.15*ribbon[:,:,None])
longgrain[:,:,:3]+=np.sin(yy*787+np.sin(xx*22))[:,:,None]*.018
long_im=packed_image('C3 lengthwise amber grain sRGB',longgrain);long_mat=texmat('C3 lengthwise amber wood',long_im)
pores=np.random.default_rng(42).random((n,n))
cork=np.ones((n,n,4));cork[:,:,:3]=np.array([.43,.265,.13])*(.6+.55*pores[:,:,None])
cork[(pores<.10),:3]*=.2
cork_im=packed_image('C3 porous cork sRGB',cork);cork_mat=texmat('C3 porous cork',cork_im,.97)

def fit(p):
    p=p.copy();p.z=(p.z-tc['source_burial_m'])*tc['vertical_scale']
    radius=math.hypot(p.x,p.y)
    a=max(0,min(1,(p.z-tc['crown_start_m'])/(tc['crown_full_m']-tc['crown_start_m'])))
    a=a*a*(3-2*a)
    bounded=tc['body_radius_m']*math.tanh(radius/.72)
    factor=((1-a)*bounded+a*radius)/max(radius,1e-12)
    p.x*=factor;p.y*=factor
    return p

def scar_weight(p):
    location,normal,index,distance=high_tree.find_nearest(p)
    face=high_faces[index]
    if len(face)!=3:return weights[face[0]]
    a,b,c=[high_points[i] for i in face]
    wa,wb,wc=[Vector((*weights[i],0)) for i in face]
    w=barycentric_transform(location,a,b,c,wa,wb,wc)
    return Vector((max(0,min(1,w.x)),max(0,min(1,w.y))))

def export(obs,name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs:o.hide_set(False);o.hide_render=False;o.select_set(True)
    bpy.context.view_layer.objects.active=obs[0]
    path=out/'models'/(name+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_all_vertex_colors=True)
    pts=[];triangles=bad=0
    for o in obs:
        o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles)
        bad+=sum(t.area<1e-12 for t in o.data.loop_triangles)
        pts.extend(o.matrix_world@v.co for v in o.data.vertices)
    assert bad==0,(name,bad)
    report['assets'][name]={'triangles':triangles,'surfaces':sum(len(o.data.materials) for o in obs),'bounds':[[min(p[i] for p in pts) for i in range(3)],[max(p[i] for p in pts) for i in range(3)]], 'sha256':sha(path)}
    assets[name]=obs
    for o in obs:o.hide_set(True);o.hide_render=True

def clean(o):
    bm=bmesh.new();bm.from_mesh(o.data)
    bmesh.ops.triangulate(bm,faces=list(bm.faces))
    bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.000001)
    bm.to_mesh(o.data);bm.free();o.data.update()
    if o.data.has_custom_normals:
        bpy.context.view_layer.objects.active=o;o.hide_set(False)
        bpy.ops.mesh.customdata_custom_splitnormals_clear()

def attach_crown(parts):
    wood=next(o for o in parts if 'foliage' not in o.name and 'branchlets' not in o.name)
    twig=next(o for o in parts if 'branchlets' in o.name)
    leaf=next(o for o in parts if 'foliage' in o.name)
    offsets=[]
    for obj,parent,is_leaf in [(twig,wood,False),(leaf,twig,True)]:
        target=BVHTree.FromPolygons([v.co for v in parent.data.vertices],[tuple(p.vertices) for p in parent.data.polygons])
        bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
        unseen=set(bm.verts);max_shift=0
        while unseen:
            first=unseen.pop();stack=[first];group=[first]
            while stack:
                v=stack.pop()
                for edge in v.link_edges:
                    other=edge.other_vert(v)
                    if other in unseen:unseen.remove(other);stack.append(other);group.append(other)
            candidates=group
            if is_leaf:
                uv=bm.loops.layers.uv.values()[1]
                candidates=[v for v in group if any(loop[uv].uv.x<1e-6 for loop in v.link_loops)]
                assert candidates,'Every leaf component needs its retained petiole'
            selected=min(candidates,key=lambda v:target.find_nearest(v.co)[3])
            point,normal,index,distance=target.find_nearest(selected.co)
            shift=point-selected.co+normal*(.001 if is_leaf else -.003)
            for v in group:v.co+=shift
            max_shift=max(max_shift,shift.length)
        bm.to_mesh(obj.data);bm.free();obj.data.update()
        offsets.append(max_shift)
    return offsets

scar_points=[fit(p) for i,p in enumerate(high_points) if weights[i].x>.65 and 0<fit(p).z<4.1]
scar_tree=KDTree(len(scar_points))
for i,p in enumerate(scar_points):scar_tree.insert(p,i)
scar_tree.balance()

def bark_material(o,altered):
    old=o.data.materials[0];m=old.copy();m.name='C3 injured bark' if altered else 'C3 resinheart bark'
    o.data.materials[0]=m;ns=m.node_tree.nodes;ls=m.node_tree.links;p=next(n for n in ns if n.type=='BSDF_PRINCIPLED')
    for link in list(p.inputs['Emission Strength'].links):ls.remove(link)
    p.inputs['Emission Strength'].default_value=0
    base=p.inputs['Base Color'].links[0].from_socket
    tint=ns.new('ShaderNodeMixRGB');tint.blend_type='MULTIPLY';tint.inputs[0].default_value=1
    tint.inputs[2].default_value=(1,.79,.52,1);ls.new(base,tint.inputs[1]);ls.new(tint.outputs[0],p.inputs['Base Color'])
    if altered:
        uv=ns.new('ShaderNodeUVMap');uv.uv_map=o.data.uv_layers[1].name
        sep=ns.new('ShaderNodeSeparateXYZ');ls.new(uv.outputs[0],sep.inputs[0])
        dark=ns.new('ShaderNodeMixRGB');dark.inputs[2].default_value=(.011,.006,.003,1)
        ls.new(sep.outputs[1],dark.inputs[0]);ls.new(tint.outputs[0],dark.inputs[1]);ls.new(dark.outputs[0],p.inputs['Base Color'])
        p.inputs['Emission Color'].default_value=(1,.16,.015,1)
        gain=ns.new('ShaderNodeMath');gain.operation='MULTIPLY';gain.inputs[1].default_value=cfg['peak_emission']
        ls.new(sep.outputs[0],gain.inputs[0]);ls.new(gain.outputs[0],p.inputs['Emission Strength'])

for level in range(3):
    originals=import_source(src/f'broadleaf-a-lod{level}.glb')
    plain=[]
    for old in originals:
        o=clone(old,'resinheart '+old.name.removeprefix('SOURCE ')+f' L{level}')
        source_coordinates=o.data.attributes.new('C3 source coordinates','FLOAT_VECTOR','POINT')
        for v in o.data.vertices:source_coordinates.data[v.index].vector=v.co
        for v in o.data.vertices:v.co=fit(v.co)
        o.data.update();clean(o)
        is_wood='foliage' not in o.name and 'branchlets' not in o.name
        if is_wood:bark_material(o,False)
        if level==2:
            o.data.calc_loop_triangles();count=len(o.data.loop_triangles)
            target=8500 if 'foliage' in o.name else (1800 if 'branchlets' in o.name else 3500)
            if count>target:
                bpy.context.view_layer.objects.active=o
                mod=o.modifiers.new('C3 far silhouette','DECIMATE');mod.ratio=target/count
                bpy.ops.object.modifier_apply(modifier=mod.name);clean(o)
            # QEM can pull a crown vertex down into the trunk band. Reproject
            # that silhouette to the same native envelope before exporting.
            for v in o.data.vertices:
                radius=math.hypot(v.co.x,v.co.y)
                if v.co.z<=tc['crown_start_m'] and radius>tc['body_radius_m']:
                    v.co.x*=tc['body_radius_m']/radius;v.co.y*=tc['body_radius_m']/radius
            clean(o)
        plain.append(o)
    if level<2:report.setdefault('crown_resnap_m',{})[str(level)]=attach_crown(plain)
    export(plain,f'resinheart-lod{level}')
    injured=[]
    for o in plain:
        nobj=clone(o,'altered '+o.name)
        if 'foliage' not in o.name and 'branchlets' not in o.name:
            # Preserve source coordinates through cleanup/LOD interpolation; never
            # assume the simplified vertex order still matches its source.
            ws=[]
            for v in nobj.data.vertices:
                distance=scar_tree.find(v.co)[2]
                damage=max(0,1-distance/.105);damage=damage*damage*(3-2*damage)
                core_weight=max(0,1-distance/.038)
                ws.append(Vector((core_weight,damage)))
            before=[v.co.copy() for v in nobj.data.vertices]
            normals=[v.normal.copy() for v in nobj.data.vertices]
            for i,v in enumerate(nobj.data.vertices):
                # Only root/trunk scars, never detach a crown socket.
                fade=max(0,min(1,(4.5-v.co.z)/.6));w=ws[i]*fade
                ws[i]=w
                inward=Vector((v.co.x,v.co.y,0))
                depth=min(w.y*tc['scar_depth_m'],inward.length*.45)
                v.co-=inward.normalized()*depth
            for loop in nobj.data.loops:nobj.data.uv_layers[1].data[loop.index].uv=ws[loop.vertex_index]
            nobj.data.update();bark_material(nobj,True)
            depths=[(v.co-before[i]).length for i,v in enumerate(nobj.data.vertices)]
            report['scar'][str(level)]={'max_depth_m':max(depths),'vertices':sum(d>.005 for d in depths)}
            if level==0:
                clone(o,'FINISHED ordinary fitted trunk','FINISHED')
                clone(nobj,'FINISHED incised fitted trunk','FINISHED')
        injured.append(nobj)
    export(injured,f'resinheart-altered-lod{level}')

# Matching native session-only stump; independent cap UV, no material emission.
stump=clone(next(o for o in assets['resinheart-lod0'] if 'foliage' not in o.name and 'branchlets' not in o.name),'resinheart matching stump')
bm=bmesh.new();bm.from_mesh(stump.data)
bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,plane_co=(0,0,.5),plane_no=(0,0,1),clear_outer=True)
boundary=[e for e in bm.edges if e.is_boundary and all(abs(v.co.z-.5)<.00001 for v in e.verts)]
for f in bmesh.ops.holes_fill(bm,edges=boundary,sides=0)['faces']:f.material_index=1
bm.to_mesh(stump.data);bm.free();stump.data.materials.append(amber_mat)
for p in stump.data.polygons:
    if p.material_index==1:
        for li in p.loop_indices:
            co=stump.data.vertices[stump.data.loops[li].vertex_index].co
            stump.data.uv_layers[0].data[li].uv=(co.x/.82+.5,co.y/.82+.5)
export([stump],'resinheart-stump')

# Independent existing deadwood source, fitted once at its native origin.
dead=import_source(src/'broadleaf-deadwood.glb')
core=clone(dead[0],'corkbark pale inner deadwood')
ps=[v.co.copy() for v in core.data.vertices];lo=Vector(tuple(min(p[i] for p in ps) for i in range(3)));hi=Vector(tuple(max(p[i] for p in ps) for i in range(3)))
for v in core.data.vertices:
    q=(v.co-lo);v.co=Vector(((q.x/(hi.x-lo.x)-.5)*1.54,(q.y/(hi.y-lo.y)-.5)*.47,q.z/(hi.z-lo.z)*.43+.02))
bm=bmesh.new();bm.from_mesh(core.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001)
for x,normal in [(.70,(1,0,0)),(-.70,(-1,0,0))]:
    bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,plane_co=(x,0,0),plane_no=normal,clear_outer=True)
boundary=[e for e in bm.edges if e.is_boundary]
if boundary:bmesh.ops.holes_fill(bm,edges=boundary,sides=0)
bm.normal_update();bm.to_mesh(core.data);bm.free();clean(core)
core.data.materials.clear();core.data.materials.append(long_mat);core.data.materials.append(amber_mat)
for p in core.data.polygons:
    p.material_index=1 if abs(p.normal.x)>.65 else 0
    for li in p.loop_indices:
        v=core.data.vertices[core.data.loops[li].vertex_index].co
        core.data.uv_layers[0].data[li].uv=((v.y/.65+.5,v.z/.65) if p.material_index==1 else (v.x/1.6+.5,math.atan2(v.y,v.z-.24)/math.tau+.5))

core_bvh=BVHTree.FromPolygons([v.co for v in core.data.vertices],[tuple(p.vertices) for p in core.data.polygons])
def sleeve(index,detail):
    verts=[];faces=[];uvs=[];nx=[36,20,10][detail];nt=[128,64,32][detail]
    start=-.79+index*1.58/3;length=1.58/3-.008
    # Broad split on the upper-front face; irregular thick exposed lips.
    for layer in [0,1]:
        for i in range(nx+1):
            t=i/nx;x=start+length*t
            for j in range(nt+1):
                a=.26+(math.tau-.85)*j/nt
                a+=.035*math.sin(t*17+index*3)*math.sin(math.pi*j/nt)
                noise=math.sin(x*137+a*43)*math.sin(x*79-a*81)
                pit=max(0,noise-.18)**2/.82**2*cfg['deadfall']['pore_depth_m']
                radius=(.277+.015*math.sin(a*11+x*7)-pit) if layer==0 else .205
                if layer==0:
                    radius+=.015*math.exp(-min(j,nt-j)/2.5)
                z=.30+math.cos(a)*radius
                point=Vector((x,math.sin(a)*radius*1.29,z))
                verts.append(tuple(point));uvs.append((t,j/nt))
    span=(nx+1)*(nt+1)
    for layer in [0,1]:
        for i in range(nx):
            for j in range(nt):
                a=layer*span+i*(nt+1)+j;b=a+nt+1
                faces.append((a,b,b+1,a+1) if layer==0 else (a,a+1,b+1,b))
    for i in range(nx):
        for j in [0,nt]:
            a=i*(nt+1)+j;b=a+nt+1;faces.append((a,a+span,b+span,b))
    for i in [0,nx]:
        for j in range(nt):
            a=i*(nt+1)+j;faces.append((a,a+1,a+1+span,a+span))
    me=bpy.data.meshes.new('Closed porous bark');me.from_pydata(verts,[],faces);me.update()
    uv=me.uv_layers.new(name='Cork coherent sleeve UV')
    for loop in me.loops:uv.data[loop.index].uv=uvs[loop.vertex_index]
    me.materials.append(cork_mat)
    o=bpy.data.objects.new(f'cork sleeve {index} L{detail}',me);cols['RUNTIME'].objects.link(o)
    for p in me.polygons:p.use_smooth=True
    clean(o)
    return o

for level in range(3):
    sleeves=[sleeve(i,level) for i in range(3)]
    for state in [18,12,6]:
        export([core]+sleeves[:state//6],f'corkbark-{state}-lod{level}')
    for o in sleeves:o.hide_render=True;o.hide_set(True)
sample=sleeve(1,1)
for v in sample.data.vertices:v.co.z-=.0
export([sample],'recovered-corkbark')
# Closed cut sample in the same grain; a material specimen, never another kit.
bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=.19,depth=.7,rotation=(0,math.pi/2,0))
sample=bpy.context.object;sample.name='Recovered closed resinheart log'
bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
for c in list(sample.users_collection):c.objects.unlink(sample)
cols['RUNTIME'].objects.link(sample)
for v in sample.data.vertices:v.co.z+=.19
sample.data.materials.append(long_mat);sample.data.materials.append(amber_mat)
for p in sample.data.polygons:
    p.material_index=1 if abs(p.normal.x)>.8 else 0
    for li in p.loop_indices:
        v=sample.data.vertices[sample.data.loops[li].vertex_index].co
        sample.data.uv_layers[0].data[li].uv=((v.y/.42+.5,(v.z-.19)/.42+.5) if p.material_index==1 else (v.x/.7+.5,math.atan2(v.y,v.z-.19)/math.tau+.5))
export([sample],'recovered-resinheart')

# Preserve the full buttressed art direction alongside the strictly fitted
# native-state candidate. It is explicitly a source study with unresolved fit.
hero=[]
for old in import_source(src/'broadleaf-altered-lod0.glb'):
    o=clone(old,'Full width hero '+old.name)
    for v in o.data.vertices:v.co.z=(v.co.z-.65)*tc['vertical_scale']
    clean(o)
    if 'foliage' not in o.name and 'branchlets' not in o.name:bark_material(o,True)
    hero.append(o)
export(hero,'resinheart-altered-hero')

# Verified B2 sparse kit supplies oldgrowth context without another scatter system.
for family in ['fern-sparse','moss','leaf-litter','grass-edge']:
    obs=import_source(PACKAGES['b2'][0]/'review/assets'/f'{family}-lod2.glb')
    export([clone(o,'context '+o.name) for o in obs],family)

for col in cols.values():
    for o in col.objects:o.hide_render=True;o.hide_set(True)
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24
scene.render.threads_mode='FIXED';scene.render.threads=8
scene.render.resolution_x=1100;scene.render.resolution_y=900;scene.render.resolution_percentage=100
if scene.world is None:scene.world=bpy.data.worlds.new('C3 studio')
scene.world.color=(.16,.17,.19)
camera=bpy.data.objects.new('C3 camera',bpy.data.cameras.new('C3 camera'));cols['REVIEW'].objects.link(camera);scene.camera=camera;camera.data.type='ORTHO'
for name,pos,power in [('key',(4,-7,11),2100),('fill',(-6,3,8),1500)]:
    o=bpy.data.objects.new(name,bpy.data.lights.new(name,'AREA'));cols['REVIEW'].objects.link(o);o.location=pos;o.data.energy=power;o.data.size=7
    o.rotation_euler=(Vector((0,0,4))-o.location).to_track_quat('-Z','Y').to_euler()
clay=bpy.data.materials.new('C3 clay');clay.diffuse_color=(.4,.4,.4,1)
views=[('tree','resinheart-lod0',(0,0,5.2),(13,-17,10),16,None),('altered','resinheart-altered-lod0',(0,0,5.2),(13,-17,10),16,None),('incision-off','resinheart-altered-lod0',(0,0,1.5),(3,-4,2.9),3.9,clay),('back','resinheart-altered-lod0',(0,0,5.2),(-13,17,10),16,clay),('crown','resinheart-lod0',(0,0,6),(1,-1,17),11,None),('roots','resinheart-lod0',(0,0,.5),(2,-2,-2),2.5,clay),('cork-full','corkbark-18-lod0',(0,0,.3),(2,-3,1.6),2.1,None),('cork-worked','corkbark-6-lod0',(0,0,.3),(2,-3,1.6),2.1,None),('cork-underside','corkbark-18-lod0',(0,0,.3),(2,-3,-1),2.1,clay),('amber-cut','resinheart-stump',(0,0,.3),(1,-1,1.7),1.4,None),('recovered-log','recovered-resinheart',(0,0,.19),(1,-1,1),1.2,None)]
for name,key,target,eye,size,override in views:
    for obs in assets.values():
        for o in obs:o.hide_render=True
    for o in assets[key]:o.hide_render=False
    camera.data.ortho_scale=size;camera.location=eye;camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.view_layers[0].material_override=override;scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
for obs in assets.values():
    for o in obs:o.hide_render=True
for o in hero:o.hide_render=False
for name,target,eye,size,override in [('hero',(0,0,5.2),(13,-17,10),16,None),('hero-incision-off',(0,0,1.4),(2,-7,2.9),4.8,clay)]:
    camera.data.ortho_scale=size;camera.location=eye;camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.view_layers[0].material_override=override;scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
scene.view_layers[0].material_override=None
for obs in assets.values():
    for o in obs:o.hide_render=True
for o in assets['resinheart-altered-lod0']:o.hide_render=False;o.hide_set(False)
camera.data.ortho_scale=12;camera.location=(13,-17,10);camera.rotation_euler=(Vector((0,0,5.3))-camera.location).to_track_quat('-Z','Y').to_euler()
for im in bpy.data.images:
    if im.has_data and im.source in ['FILE','GENERATED']:im.pack()
(out/'models.json').write_text(json.dumps(report,indent=2)+'\n')
scene['C3_controls']=json.dumps(cfg)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'oldgrowth-master.blend'),compress=True)
print('C3_BUILD_OK',len(report['assets']),report['scar'])
