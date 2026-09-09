"""Blender authoring: six-role kit and composed grove; no game inputs mutated."""
import bpy, bmesh, json, math, random, sys, hashlib
import numpy as np
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent))
from landform import height, route_x, stream_x
finished, config, out, rock_finished=map(Path,sys.argv[sys.argv.index('--')+1:])
cfg=json.loads(config.read_text());rng=random.Random(cfg['seed'])
assert not out.exists();out.mkdir(parents=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
materials={}
for name in ['Bark','Rock','Soil','Leaf']:
    m=bpy.data.materials.new(name);m.use_nodes=True
    n=m.node_tree.nodes.new('ShaderNodeVertexColor');n.layer_name='Host colour'
    bsdf=m.node_tree.nodes.get('Principled BSDF');m.node_tree.links.new(n.outputs['Color'],bsdf.inputs['Base Color']);bsdf.inputs['Roughness'].default_value=.9
    materials[name]=m
class Mesh:
    def __init__(self):self.v=[];self.f=[];self.uv=[];self.mask=[];self.col=[]
    def vert(self,p,uv=(0,0),mask=(0,0),col=(.15,.12,.08)):
        self.v.append(tuple(p));self.uv.append(uv);self.mask.append(mask);self.col.append((*col,1));return len(self.v)-1
    def face(self,*v):self.f.append(v)
    def object(self,name,material):
        mesh=bpy.data.meshes.new(name);mesh.from_pydata(self.v,[],self.f);mesh.update()
        for face in mesh.polygons:face.use_smooth=True
        uv=mesh.uv_layers.new(name='Grain and travel');mask=mesh.uv_layers.new(name='Core and damage')
        col=mesh.color_attributes.new(name='Host colour',type='FLOAT_COLOR',domain='POINT');col.data.foreach_set('color',np.array(self.col,dtype=np.float32).ravel())
        for loop in mesh.loops:uv.data[loop.index].uv=self.uv[loop.vertex_index];mask.data[loop.index].uv=self.mask[loop.vertex_index]
        o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);mesh.materials.append(materials[material]);return o
def export(objects,name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.hide_set(False);o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.export_scene.gltf(filepath=str((out/(name+'.glb')).resolve()),export_format='GLB',use_selection=True,export_animations=False)
    for o in objects:o.hide_render=True;o.hide_set(True)
def tube(m,path,radii,scar=False,sides=32):
    path=[Vector(p) for p in path];start=len(m.v)
    for j,(p,r) in enumerate(zip(path,radii)):
        t=j/(len(path)-1);tangent=(path[min(j+1,len(path)-1)]-path[max(j-1,0)]).normalized()
        u=tangent.cross(Vector((0,0,1)))
        if u.length<.01:u=tangent.cross(Vector((0,1,0)))
        u.normalize();v=tangent.cross(u).normalized()
        for k in range(sides+1):
            a=k/sides*math.tau;d=abs(math.atan2(math.sin(a-(1.1+.12*math.sin(t*18)+.045*math.sin(t*87))),math.cos(a-(1.1+.12*math.sin(t*18)+.045*math.sin(t*87))))) * r
            core=max(0,1-d/.012) if scar else 0;damage=max(0,1-d/.060) if scar else 0
            ridges=.05*math.sin(a*11+t*7)+.02*math.sin(a*27-t*19)
            rr=r*(1+ridges)-.012*damage
            co=p+(u*math.cos(a)+v*math.sin(a))*rr
            tone=.8+.18*math.sin(a*11+t*7)+.12*math.sin(t*80+a*3)
            c=np.array((.13,.09,.054))*tone
            if math.sin(a)>0 and t>.2:c=c*.75+np.array((.10,.14,.036))*.25
            m.vert(co,(k/sides*3,t),(core,damage),tuple(c))
    for j in range(len(path)-1):
        for k in range(sides):
            a=start+j*(sides+1)+k;b=a+sides+1;m.face(a,a+1,b+1,b)
    m.face(*[start+k for k in reversed(range(sides))]);m.face(*[start+(len(path)-1)*(sides+1)+k for k in range(sides)])
def leaf(m,p,d,length,width,colour,lobes=False):
    d=Vector(d).normalized();p=Vector(p);u=d.cross(Vector((0,0,1)))
    if u.length<.01:u=Vector((1,0,0))
    u.normalize();base=len(m.v)
    if lobes:
        widths=[.70,.53,1.0,.63,.84,.44,.45]
        root_tip=m.vert(p,(.5,0),(0,0),colour)
        for j,w in enumerate(widths):
            t=(j+1)/8;mid=p+d*length*t+Vector((0,0,math.sin(t*math.pi)*length*.10))
            m.vert(mid-u*width*w-Vector((0,0,length*.025*w)),(0,t),(0,0),colour)
            m.vert(mid,(.5,t),(0,0),colour)
            m.vert(mid+u*width*w-Vector((0,0,length*.025*w)),(1,t),(0,0),colour)
        end_tip=m.vert(p+d*length,(.5,1),(0,0),colour)
        m.face(root_tip,base+1,base+2);m.face(root_tip,base+2,base+3)
        for j in range(6):
            for k in range(2):
                a=base+1+j*3+k;m.face(a,a+3,a+4,a+1)
        m.face(base+19,end_tip,base+20);m.face(base+20,end_tip,base+21)
        return
    for pos,uv in [(p,(.5,0)),(p+d*length*.36-u*width,(0,.36)),(p+d*length*.42+Vector((0,0,length*.10)),(.5,.42)),(p+d*length*.36+u*width,(1,.36)),(p+d*length*.77-u*width*.6,(.2,.77)),(p+d*length*.77+u*width*.6,(.8,.77)),(p+d*length,(.5,1))]:m.vert(pos,uv,(0,0),colour)
    for f in [(0,1,2),(0,2,3),(1,4,2),(2,5,3),(4,6,2),(2,6,5)]:m.face(*[base+i for i in f])

# Leaf-bearing sprays start on the actual reconstructed upper limbs.
bpy.ops.import_scene.gltf(filepath=str((finished/'quiet-tree.glb').resolve()))
tree=next(o for o in bpy.context.scene.objects if o.type=='MESH' and o.name not in materials)
p=np.array([tree.matrix_world@v.co for v in tree.data.vertices])
anchors=p[(p[:,2]>3.9)&(np.linalg.norm(p[:,:2],axis=1)>.75)]
foliage=Mesh();foliage_far=Mesh();twigs=Mesh()
for i in range(cfg['canopy_sprays']):
    anchor=Vector(anchors[rng.randrange(len(anchors))]);direction=Vector((anchor.x*.25+rng.uniform(-.7,.7),anchor.y*.25+rng.uniform(-.7,.7),rng.uniform(.05,.55))).normalized()
    length=rng.uniform(.55,1.20);end=anchor+direction*length
    tube(twigs,[anchor,anchor+direction*length*.48+Vector((0,0,.08)),end],[.012,.007,.002],sides=5)
    lateral=direction.cross(Vector((0,0,1))).normalized()
    for j in range(7):
        for side in [-1,1]:
            at=anchor+direction*(length*(.20+j*.11))
            ld=(direction*rng.uniform(-.1,.6)+lateral*side+Vector((rng.uniform(-.5,.5),rng.uniform(-.5,.5),rng.uniform(-.6,.6)))).normalized()
            ll=rng.uniform(*cfg['leaf_length_m']);shade=rng.uniform(.75,1.4)
            leaf(foliage,at,ld,ll,ll*cfg['leaf_width_fraction'],(.065*shade,.20*shade,.024*shade),lobes=True)
            leaf(foliage_far,at,ld,ll,ll*cfg['leaf_width_fraction'],(.065*shade,.20*shade,.024*shade))
canopy=[foliage.object('Folded broadleaf canopy','Leaf'),twigs.object('Connected leaf-bearing twigs','Bark')]
export(canopy,'canopy')
export([foliage_far.object('Distant folded broadleaf canopy','Leaf'),canopy[1]],'canopy-far')
bpy.data.objects.remove(tree,do_unlink=True)

# Bank-facing root section from the generated host. Its open back is buried.
bpy.ops.import_scene.gltf(filepath=str((finished/'altered-tree.glb').resolve()))
root=next(o for o in bpy.context.selected_objects if o.type=='MESH')
bpy.context.view_layer.objects.active=root;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
bm=bmesh.new();bm.from_mesh(root.data)
bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.co.z>1.45 or v.co.y>-.40],context='VERTS')
bm.to_mesh(root.data);bm.free();root.data.update();root.name='Exposed original oak root section'
roots=[root];export(roots,'root-bank')
bpy.ops.import_scene.gltf(filepath=str((rock_finished/'fractured-rock.glb').resolve()))
rocks=[o for o in bpy.context.selected_objects if o.type=='MESH'];export(rocks,'fractured-rock')

dead=Mesh();path=[];rs=[]
for j in range(81):
    t=j/80;path.append((-2+t*4,.18*math.sin(t*5),.26+.10*math.sin(t*7)));rs.append(.28*(1-t*.62))
tube(dead,path,rs,sides=48)
for i in range(5):
    t=.15+i*.14;base=Vector((-2+t*4,.18*math.sin(t*5),.26+.10*math.sin(t*7)))
    tube(dead,[base,base+Vector((.12,(-1)**i*.40,.25)),base+Vector((.3,(-1)**i*.65,.42))],[.09,.04,.012],sides=12)
deadfall=[dead.object('Broken mossy deadfall','Bark')];export(deadfall,'deadfall')

under=Mesh();stems=Mesh()
for f in range(5):
    centre=Vector((rng.uniform(-.7,.7),rng.uniform(-.65,.65),0))
    for fr in range(10):
        a=fr*math.tau/10+rng.uniform(-.2,.2);d=Vector((math.cos(a),math.sin(a),0));u=Vector((-d.y,d.x,0));length=rng.uniform(.48,.9)
        path=[]
        for j in range(16):
            t=j/15;p=centre+d*length*t+Vector((0,0,.07+math.sin(t*math.pi*.82)*length*.62));path.append(p)
            if j<2:continue
            ll=.13*math.sin(t*math.pi)**.6+.025
            for s in [-1,1]:leaf(under,p,d*.32+u*s,ll,ll*.25,(.11,.23,.048))
        tube(stems,path,[.004*(1-j/17) for j in range(16)],sides=4)
for g in range(90):
    p=Vector((rng.uniform(-1,1),rng.uniform(-.85,.85),.01));a=rng.random()*math.tau;h=rng.uniform(.13,.44)
    leaf(under,p,(math.cos(a)*.3,math.sin(a)*.3,1),h,.012,(.15,.22,.055))
understory=[under.object('Fern and tuft cluster','Leaf'),stems.object('Fern stems','Bark')];export(understory,'understory')

# Support surface: an authored stream corridor and the same triangulation in review.
ground=Mesh();step=cfg['terrain_step_m'];nx=round(cfg['terrain_size_m'][0]/step);nz=round(cfg['terrain_size_m'][1]/step)
for j in range(nz+1):
    z=(j-nz/2)*step
    for i in range(nx+1):
        x=(i-nx/2)*step;h=height(x,z)
        trail=math.exp(-((x-route_x(z))/1.35)**4)
        c=np.array((.12,.16,.048))*(1-trail)+np.array((.18,.125,.067))*trail
        ground.vert((x,-z,h),(x*.2,z*.2),(0,0),tuple(c))
for j in range(nz):
    for i in range(nx):
        a=j*(nx+1)+i;b=a+nx+1;ground.face(a,b,a+1);ground.face(a+1,b,b+1)
terrain=ground.object('Authored review terrain','Soil');export([terrain],'terrain')

layout=[]
def place(role,x,z,scale=1,yaw=0,burial=0):
    layout.append({'role':role,'position':[x,height(x,z)-burial,z],'scale':scale,'yaw':yaw})
for z in [-30,-22,-14,-6,2,10,18,26,34]:
    for x in [-18,-11,7.5,15,23]:
        xx=x+rng.uniform(-1.1,1.1);zz=z+rng.uniform(-1.3,1.3)
        if abs(zz-6)<7 and xx<10 and xx>0:continue
        scale=rng.uniform(.87,1.25);place('quiet-tree',xx,zz,scale,rng.uniform(0,360),.55*scale)
# Close the distant view with smaller overlapping growth, keeping the actual
# 38 m route open. These are authored background placements, not spawn records.
for x in [-15,-8,-1,6,13,20]:
    place('quiet-tree',x+rng.uniform(-.8,.8),31+rng.uniform(-1,1),rng.uniform(.85,1.2),rng.uniform(0,360),.6)
place('altered-tree',5.8,6,1.10,-70,.60)
place('quiet-tree',4.8,-9,.84,160,.49)
place('quiet-tree',4.6,-17,1.1,185,.6)
place('root-bank',5.1,8.4,.80,-80,.43)
place('fractured-rock',4.7,10.1,1.05,-65,.13)
place('fractured-rock',-8.5,2,.9,100,.2)
place('fractured-rock',-3,-15,.65,200,.22)
place('deadfall',4.1,-2,1,60,.15)
place('deadfall',-9,14,1.2,80,.16)
for i in range(cfg['understory_attempts']):
    x=rng.uniform(-20,23);z=rng.uniform(-33,36)
    if abs(x-route_x(z))<1.25 or abs(x-stream_x(z))<2.8:continue
    place('understory',x,z,rng.uniform(.65,1.15),rng.uniform(0,360),.025)
layout.append({'role':'boar','position':[2.65,height(2.65,4),4],'scale':1,'yaw':-60})
route=[]
for z in np.linspace(*cfg['route_z_m'],153):route.append([route_x(float(z)),height(route_x(float(z)),float(z)),float(z)])
(out/'layout.json').write_text(json.dumps({'instances':layout,'route':route,'coordinates':'Godot metres; source meshes use Blender (x,-z,y)'},indent=2))

# Editable composition retains linked kit geometry and the actual tree shapes.
assets={'root-bank':roots,'fractured-rock':rocks,'deadfall':deadfall,'understory':understory}
for name in ['quiet-tree','altered-tree']:
    bpy.ops.import_scene.gltf(filepath=str((finished/(name+'.glb')).resolve()))
    objects=list(bpy.context.selected_objects);assets[name]=[o for o in objects if o.type=='MESH']+canopy
    for o in objects:o.hide_set(True);o.hide_render=True
for row in layout:
    if row['role']=='boar':continue
    parent=bpy.data.objects.new('Placed '+row['role'],None);bpy.context.collection.objects.link(parent)
    x,y,z=row['position'];parent.location=(x,-z,y);parent.rotation_euler.z=-math.radians(row['yaw']);parent.scale=(row['scale'],)*3
    for source in assets[row['role']]:
        o=source.copy();o.data=source.data;bpy.context.collection.objects.link(o);o.parent=parent;o.hide_render=False;o.hide_set(False)
terrain.hide_render=False;terrain.hide_set(False)
report={'seed':cfg['seed'],'roles':{},'instances':{r:sum(i['role']==r for i in layout) for r in set(i['role'] for i in layout)},'route_length_m':sum(math.dist(a,b) for a,b in zip(route[:-1],route[1:]))}
for p in out.glob('*.glb'):report['roles'][p.stem]={'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
(out/'kit-report.json').write_text(json.dumps(report,indent=2))
for im in bpy.data.images:
    if im.has_data and im.source=='FILE':im.pack()
bpy.context.scene['study']='ART-02 - composed grove, not generated game geography'
bpy.ops.wm.save_as_mainfile(filepath=str((out/'grove-layout.blend').resolve()),compress=True)
print('GROVE_KIT_OK')
