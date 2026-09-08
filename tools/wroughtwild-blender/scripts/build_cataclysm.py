"""Bounded owner-approved Cataclysm ruin kit, authored in local Blender.

Blender --background --python this-file -- repository output-directory
Godot metres and applied ground pivots; visual-only meshes and original baked
surface grain. No external assets, gameplay objects, collision or resource data.
"""
import hashlib
import json
import math
from pathlib import Path
import random
import struct
import sys

import bpy
from mathutils import Vector, Matrix

project, output=map(Path,sys.argv[sys.argv.index('--')+1:]);output.mkdir(parents=True,exist_ok=True)
config=json.loads((Path(__file__).resolve().parents[1]/'cataclysm.json').read_text())
palette={k:tuple(int(v[i:i+2],16)/255 for i in (0,2,4)) for k,v in config['palette'].items()}
def srgb(v): return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
def xyz(p): return (p[0],-p[2],p[1])
def tint(c,s): return tuple(min(1,max(0,v*s)) for v in c)

bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
materials={}
for name,rough,metal in [('stone',.93,0),('wood',.88,0),('reed',.91,0),('metal',.54,.42),('light',.52,.12)]:
    mat=bpy.data.materials.new('Cataclysm '+name);mat.use_nodes=True
    nodes=mat.node_tree.nodes;links=mat.node_tree.links;bsdf=nodes.get('Principled BSDF')
    bsdf.inputs['Roughness'].default_value=rough;bsdf.inputs['Metallic'].default_value=metal
    vertex=nodes.new('ShaderNodeVertexColor');vertex.layer_name='Color'
    links.new(vertex.outputs['Color'],bsdf.inputs['Base Color'])
    # A single tiled original grain image. glTF exports it embedded and applies
    # vertex colour multiplicatively, preserving each regional material palette.
    size=config['surface_texture_px'];image=bpy.data.images.new('Cataclysm '+name+' grain',width=size,height=size)
    pixels=[];rng=random.Random(config['seed']+len(materials)*37)
    for y in range(size):
        for x in range(size):
            noise=rng.random()
            streak=math.sin(x*.51+math.sin(y*.046)*2.2)*math.sin(x*.139+y*.008)
            grain = streak if name in ['wood','reed'] else math.sin(x*.19+math.sin(y*.08)*2)*math.cos(y*.21)
            amount=.88+noise*.075+grain*config['weathering_grain']
            pixels.extend([amount,amount,amount,1])
    image.pixels=pixels;image.pack()
    tex=nodes.new('ShaderNodeTexImage');tex.image=image;tex.interpolation='Linear';tex.extension='REPEAT'
    mix=nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1
    links.new(vertex.outputs['Color'],mix.inputs[1]);links.new(tex.outputs['Color'],mix.inputs[2]);links.new(mix.outputs[0],bsdf.inputs['Base Color'])
    if name=='light':
        links.new(vertex.outputs['Color'],bsdf.inputs['Emission Color']);bsdf.inputs['Emission Strength'].default_value=config['inlay_emission']
    materials[name]=mat


class Geometry:
    def __init__(self,seed):
        self.vertices=[];self.faces=[];self.colours=[];self.kinds=[];self.rng=random.Random(seed)
    def face(self,points,colour,kind='stone',inside=None):
        pts=list(map(Vector,points))
        if inside is not None and (pts[1]-pts[0]).cross(pts[2]-pts[0]).dot(sum(pts,Vector())/len(pts)-Vector(inside))<0:pts.reverse()
        start=len(self.vertices);self.vertices.extend(tuple(p) for p in pts);self.faces.append(tuple(range(start,start+len(pts))));self.colours.append(colour);self.kinds.append(kind)
    def block(self,centre,size,colour,kind='stone',rotation=None,wear=None):
        centre=Vector(centre);half=Vector(size)*.5;rot=rotation if rotation is not None else Matrix.Identity(3)
        bevel=min(config['edge_wear_m'] if wear is None else wear,min(size)*.22)
        def point(local): return centre+rot@Vector(local)
        for axis in range(3):
            u=(axis+1)%3;v=(axis+2)%3
            for sign in [-1,1]:
                plane=[]
                for x,y in [(-half[u]+bevel,-half[v]),(half[u]-bevel,-half[v]),(half[u],-half[v]+bevel),(half[u],half[v]-bevel),(half[u]-bevel,half[v]),(-half[u]+bevel,half[v]),(-half[u],half[v]-bevel),(-half[u],-half[v]+bevel)]:
                    p=[0,0,0];p[axis]=sign*half[axis];p[u]=x;p[v]=y;plane.append(point(p))
                self.face(plane,tint(colour,1+self.rng.uniform(-.035,.035)),kind,centre)
        for a in range(3):
            for b in range(a+1,3):
                c=3-a-b
                for sa in [-1,1]:
                    for sb in [-1,1]:
                        pts=[]
                        for side,which in [(-1,0),(-1,1),(1,1),(1,0)]:
                            p=[0,0,0];p[a]=sa*(half[a]-(bevel if which else 0));p[b]=sb*(half[b]-(0 if which else bevel));p[c]=side*(half[c]-bevel);pts.append(point(p))
                        self.face(pts,tint(colour,1.06),kind,centre)
        for sx in [-1,1]:
            for sy in [-1,1]:
                for sz in [-1,1]:
                    signs=[sx,sy,sz];pts=[]
                    for axis in range(3):pts.append(point([signs[i]*(half[i]-(0 if axis==i else bevel)) for i in range(3)]))
                    self.face(pts,tint(colour,1.025),kind,centre)
    def beam(self,a,b,width,depth,colour,kind='wood'):
        a=Vector(a);b=Vector(b);y=(b-a).normalized();x=y.cross(Vector((0,0,1)))
        if x.length<.01:x=y.cross(Vector((1,0,0)))
        x.normalize();z=x.cross(y).normalized();rot=Matrix((x,y,z)).transposed()
        self.block((a+b)*.5,(width,(b-a).length,depth),colour,kind,rot,min(.022,width*.15))
    def tube(self,points,radii,colour,kind='wood',sides=9):
        source=list(map(Vector,points));pts=[];smooth_radii=[]
        for index in range(len(source)-1):
            a=source[max(0,index-1)];b=source[index];c=source[index+1];d=source[min(len(source)-1,index+2)]
            steps=1 if len(source)==2 else 3
            for step in range(steps):
                t=step/steps
                pts.append(.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
                smooth_radii.append(radii[index]*(1-t)+radii[index+1]*t)
        pts.append(source[-1]);smooth_radii.append(radii[-1]);radii=smooth_radii
        rings=[];previous=None
        for i,(p,r) in enumerate(zip(pts,radii)):
            axis=(pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)]).normalized()
            cross=axis.cross(Vector((0,1,0))) if previous is None else previous-axis*previous.dot(axis)
            if cross.length<.01:cross=axis.cross(Vector((1,0,0)))
            cross.normalize();previous=cross;up=axis.cross(cross).normalized()
            rings.append([p+(cross*math.cos(j*math.tau/sides)+up*math.sin(j*math.tau/sides))*r*(1+.05*math.sin(j*4.2+i*.4)) for j in range(sides)])
        for i in range(len(rings)-1):
            for j in range(sides):
                k=(j+1)%sides
                self.face([rings[i][j],rings[i][k],rings[i+1][k],rings[i+1][j]],tint(colour,.94+.08*(j%3)/2),kind,pts[i].lerp(pts[i+1],.5))
        self.face(rings[0],colour,kind,pts[1]);self.face(rings[-1],tint(colour,1.12),kind,pts[-2])
    def add(self,recipe,at=(0,0,0),scale=(1,1,1),yaw=0):
        part=Geometry(self.rng.randrange(2**30));recipe(part);at=Vector(at);scale=Vector(scale);rot=Matrix.Rotation(yaw,3,'Y')
        for face,colour,kind in zip(part.faces,part.colours,part.kinds):
            self.face([at+rot@Vector(tuple(part.vertices[i][a]*scale[a] for a in range(3))) for i in face],colour,kind)
    def object(self,name):
        mesh=bpy.data.meshes.new(name);mesh.from_pydata([xyz(p) for p in self.vertices],[],self.faces);mesh.update()
        colours=mesh.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='CORNER');uv=mesh.uv_layers.new(name='GrainUV')
        kinds=list(materials)
        for material in materials.values():mesh.materials.append(material)
        for poly,colour,kind in zip(mesh.polygons,self.colours,self.kinds):
            poly.material_index=kinds.index(kind)
            n=poly.normal;axis=max(range(3),key=lambda i:abs(n[i]));u=(axis+1)%3;v=(axis+2)%3
            for loop in poly.loop_indices:
                colours.data[loop].color=tuple(srgb(c) for c in colour)+(1,)
                p=mesh.vertices[mesh.loops[loop].vertex_index].co
                uv.data[loop].uv=(p[u]*(2.0 if kind in ['wood','reed'] else 1.8),p[v]*.7)
        obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj);return obj


def masonry(g,width,height,depth,colour,step=.34,broken=True):
    rows=math.ceil(height/step)
    for row in range(rows):
        count=max(1,round(width/.58));offset=width/count*.5 if row%2 and count>1 else 0
        for col in range(count):
            x=-width*.5+(col+.5)*width/count+offset
            if x>width*.5-.1:continue
            if broken and row==rows-1 and col in [3,4]:continue
            w=width/count-.025;h=min(step-.022,height-row*step)
            g.block((x,row*step+h*.5-.055,g.rng.uniform(-.013,.013)),(w,h,depth*g.rng.uniform(.94,1.0)),tint(colour,g.rng.uniform(.89,1.06)))

def peg(g,at):g.tube([Vector(at)-Vector((0,0,.03)),Vector(at)+Vector((0,0,.07))],[.035,.029],palette['endgrain'],sides=7)

def inlay(g):
    # Lower-centre pivot; all attachment relief faces +Z.
    g.block((0,.53,.017),(.12,1.04,.032),palette['seam'],'metal',wear=.008)
    paths=[[(0,.025,.049),(0,.47,.05),(-.16,.66,.05),(-.34,1.07,.05)],
           [(0,.47,.05),(.20,.71,.05),(.32,1.13,.05)],
           [(.10,.59,.05),(.02,.89,.05),(.075,1.13,.05)]]
    for path in paths:
        for a,b in zip(path,path[1:]):
            g.beam(a,b,.09,.029,palette['seam'],'metal')
            g.beam(Vector(a)+Vector((0,0,.019)),Vector(b)+Vector((0,0,.019)),.034,.025,palette['pale_metal'],'metal')
    for index in range(7):
        y=.08+index*.057;w=.23+(index%3)*.036
        g.block((-.003,y,.094+index*.001),(w,.021,.035),tint(palette['oxide'],1+index*.022),'metal',wear=.004)
    g.block((.071,1.10,.074),(.031,.074,.028),palette['quiet_light'],'light',wear=.004)

def root_wall(g):
    masonry(g,2.95,.62,.52,palette['masonry'])
    for x,h in [(-1.3,2.25),(1.28,1.7)]:
        g.beam((x,.48,0),(x+.03,h,.04),.19,.29,palette['wood'])
        for y in [.7,1.35]:peg(g,(x,y,.16))
    for index in range(8):
        y=.72+index*.185;end=1.25-max(0,index-3)*.18
        g.beam((-1.24,y,.04),(end,y+.015*math.sin(index),.045),.157,.13,tint(palette['wood'],.93+(index%3)*.045))
    g.beam((-1.16,.69,.13),(.72,1.87,.16),.09,.08,palette['char'])
    g.add(inlay,(-.94,.72,.14),(.42,.7,.7))

def root_frame(g):
    for sign in [-1,1]:
        x=sign*1.4
        masonry_part=lambda part:masonry(part,.55,.52,.66,palette['masonry'],broken=False)
        g.add(masonry_part,(x,0,0))
        g.beam((x,.35,-.05),(x-sign*.09,2.35,.08),.25,.31,palette['wood'])
        g.beam((x,.42,.04),(x-sign*.28,1.34,.07),.11,.14,palette['char'])
        peg(g,(x-sign*.03,1.85,.25))
    g.beam((-1.43,2.34,.03),(.24,2.67,.08),.23,.27,palette['wood'])
    g.beam((.20,2.67,.08),(1.4,2.33,.10),.17,.26,palette['wood'])
    for i in range(3):g.beam((.23+i*.08,2.6,.1),(.37+i*.12,2.68-i*.1,.27),.045,.04,palette['endgrain'])
    g.add(inlay,(-1.42,.88,.18),(.3,.65,.6))

def root_roof(g):
    for x in [-1.1,0,1.1]:g.beam((x,.06,-1.0),(x+.05,.31,.92),.14,.16,palette['char'])
    for row in range(8):
        z=-.93+row*.25;length=2.76-(.43 if row in [1,5] else 0)
        g.block((-.08 if row==1 else .02,.18+row*.035,z),(length,.105,.275),tint(palette['wood'],.9+.025*(row%4)),'wood',Matrix.Rotation(.025*math.sin(row),3,'Y'))
    g.beam((-1.36,.55,.13),(.5,.40,.8),.075,.1,palette['char'])

def fen_wall(g):
    masonry(g,2.76,.68,.47,palette['clay'],.25)
    for x in [-1.25,.06,1.23]:g.beam((x,.44,0),(x+.035,1.65,.02),.11,.15,palette['wood'])
    for i in range(31):
        x=-1.2+i*.077;height=1.46-(.20 if i>22 else 0)
        g.beam((x,.56,.02),(x+.025,height,.035),.039,.037,tint(palette['reed'],.91+.07*(i%3)/2),'reed')
    for row in range(9):
        y=.66+row*.088
        g.beam((-1.23,y,.071),(1.22-(.15 if row>6 else 0),y,.068),.027,.026,tint(palette['reed'],.76),'reed')
    g.add(inlay,(.055,.67,.09),(.28,.65,.65))

def cistern(g):
    # Managed low waterwork: a three-lobed clay rim with one broken outlet.
    for i in range(19):
        if i in [0,1,12]:continue
        a=i*math.tau/19;r=1+.07*math.cos(a*3)
        for row in range(2 if i not in [3,8,14] else 1):
            g.block((math.cos(a)*r*1.19,.16+row*.24-.065,math.sin(a)*r*.92),(.39,.255,.26),tint(palette['clay'],.93+(i%3)*.045),'stone',Matrix.Rotation(-a,3,'Y'),.035)
    for k in range(6):
        a=k*math.tau/6
        g.block((math.cos(a)*.58,.005,math.sin(a)*.43),(.75,.11,.52),palette['clay_dark'],'stone',Matrix.Rotation(-a,3,'Y'))
    for sign in [-1,1]:g.block((1.20,.05,sign*.26),(.62,.19,.15),palette['clay'])
    g.add(inlay,(-.22,.14,.78),(.42,.4,.5),-.2)

def fen_roof(g):
    for z in [-.7,.1,.78]:g.beam((-1.28,.08,z),(1.27,.24,z),.11,.12,palette['wood'])
    for i in range(37):
        x=-1.28+i*.071;end=.82-(.26 if i%11 in [0,1] else 0)
        g.beam((x,.12,-.92),(x+.035,.35,end),.055,.065,tint(palette['reed'],.88+(i%4)*.045),'reed')
    for z in [-.67,-.22,.21,.65]:
        g.beam((-1.25,.23+(z+.9)*.14,z),(1.3,.23+(z+.9)*.14,z),.043,.034,palette['char'],'reed')

def upland_wall(g):
    masonry(g,2.96,1.42,.61,palette['shellstone'],.37)
    for x,h in [(-1.16,1.38),(-.54,1.38),(.10,1.05),(.76,1.05),(1.25,.67)]:
        g.block((x,h+.07,.02),(.62,.12,.67),palette['slate'],'stone',Matrix.Rotation(.035,3,'Y'),.02)
    g.add(inlay,(-1.15,.33,.326),(.50,.85,.75))

def upland_shelter(g):
    for x,h in [(-1.31,2.20),(1.32,1.84)]:
        g.add(lambda p:masonry(p,.56,h,.77,palette['shellstone'],.33,False),(x,0,0))
    g.beam((-1.38,2.16,0),(.76,2.30,0),.18,.78,palette['slate'],'stone')
    for i in range(4):
        g.block((-.98+i*.43,2.24+i*.032,-.08),(.51,.10,.98),palette['slate'],'stone',Matrix.Rotation(.025*(i-1),3,'Y'))
    g.add(inlay,(-1.32,.6,.41),(.36,1.0,.75))

def paving(g):
    for row in range(2):
        for col in range(4):
            if row==1 and col==3:continue
            x=-1.08+col*.69+row*.17;z=-.48+row*.77
            g.block((x,.025,z),(.64,.09,.7),tint(palette['shellstone'],.9+.045*((row+col)%3)),'stone',Matrix.Rotation(.016*(col-row),3,'Y'),.055)
    for i in range(3):g.block((-.4+i*.5,.073,-.2),(.40,.016,.022),palette['slate'],'stone',wear=.003)

def impact(g):
    rings=[];steps=[(-.18,1.3,.62),(.25,1.48,.77),(1.30,1.12,.60),(2.35,.57,.29)]
    for row,(y,x,z) in enumerate(steps):
        ring=[]
        for k in range(9):
            a=k*math.tau/9;r=1+.08*math.sin(k*2.2+row*.4)
            ring.append(Vector((math.cos(a)*x*r,y+.06*math.sin(a*3),math.sin(a)*z*r+y*config['impact_lean'])))
        rings.append(ring)
    for row in range(3):
        for k in range(9):
            n=(k+1)%9
            g.face([rings[row][k],rings[row][n],rings[row+1][n],rings[row+1][k]],tint(palette['impact'],.90+.07*(k%3)),inside=Vector((0,row*.7,0)))
    g.face(rings[0],palette['impact'],inside=(0,1,0));g.face(rings[-1],palette['basalt'],inside=(0,1,0))
    # Project every attachment vertex onto the actual front triangles. A guessed
    # vertical plane buried the upper fork in the changing meteor cross-section.
    triangles=[]
    for face in g.faces:
        for i in range(1,len(face)-1):triangles.append([Vector(g.vertices[j]) for j in [face[0],face[i],face[i+1]]])
    def front(x,y):
        hits=[]
        for a,b,c in triangles:
            det=(b.y-c.y)*(a.x-c.x)+(c.x-b.x)*(a.y-c.y)
            if abs(det)<1e-8:continue
            u=((b.y-c.y)*(x-c.x)+(c.x-b.x)*(y-c.y))/det
            v=((c.y-a.y)*(x-c.x)+(a.x-c.x)*(y-c.y))/det
            if min(u,v,1-u-v)>=-.00001:hits.append(u*a.z+v*b.z+(1-u-v)*c.z)
        assert hits,'inlay must lie over the physical fragment front'
        return max(hits)
    detail=Geometry(g.rng.randrange(2**30));inlay(detail)
    for face,colour,kind in zip(detail.faces,detail.colours,detail.kinds):
        projected=[]
        for vertex in face:
            p=Vector(detail.vertices[vertex]);p.x=p.x*.95+.02;p.y=p.y*1.45+.34
            p.z=front(p.x,p.y)+.012+p.z*.65;projected.append(p)
        g.face(projected,colour,kind)
    for i in range(7):
        y=.42+i*.19
        g.block((-.72,y,.66+y*.12),(.42,.075,.09),tint(palette['oxide'],.94+i*.014),'metal',Matrix.Rotation(-.13,3,'Z'),.012)

def root_fragment(g):
    g.add(impact,(-.2,0,0),(.86,.84,.9),.18)
    roots=[([(-1.68,-.08,-.7),(-1.24,.22,-.6),(-.8,1.35,-.34),(-.4,2.03,.2),(.8,1.26,.79),(1.62,.1,1.00)],[.34,.35,.29,.24,.18,.055]),
           ([(-1.7,.02,.85),(-1.1,.2,.57),(-.55,.74,.8),(.30,.33,1.01),(1.55,-.08,1.14)],[.21,.26,.19,.14,.035]),
           ([(-1.2,1.1,-.22),(-.1,1.56,-.3),(.72,.84,-.5),(1.72,-.08,-.68)],[.19,.22,.13,.028])]
    for points,radii in roots:g.tube(points,radii,palette['wood'],sides=12)
    for i in range(3):g.block((-.96+i*.21,.45+i*.21,.65),(.10,.10,.09),palette['pale_metal'],'metal',Matrix.Rotation(.5,3,'Z'),.014)

def threshold(g):
    for sign in [-1,1]:
        x=sign*1.43
        for row in range(7):
            g.block((x-sign*row*.009,row*.37+.15-.04,0),(.67,.36,.72),tint(palette['basalt'],.92+(row%3)*.04))
        g.add(inlay,(x-sign*.035,.64,.39),(.54,1.4,1.0))
    g.beam((-1.62,2.60,0),(1.63,2.70,.04),.21,.74,palette['basalt'],'stone')
    for x in [-1.11,-.75,-.38,0,.37,.74,1.11]:
        g.block((x,2.66,.415),(.14,.21,.11),palette['oxide'],'metal',wear=.012)

def lamella(g):
    g.block((0,1.0,-.05),(.70,2.0,.22),palette['basalt'])
    for row in range(11):
        y=.14+row*.171;angle=-.12+.023*(row%3)
        g.block((.035*math.sin(row),y,.10),(.93,.073,.42),tint(palette['oxide'],.92+(row%3)*.055),'metal',Matrix.Rotation(angle,3,'X'),.012)
    g.add(inlay,(-.18,.39,.33),(.48,1.23,.75))


recipes={'rootvault_wall':root_wall,'rootvault_frame':root_frame,'rootvault_roof':root_roof,
         'fen_wall':fen_wall,'fen_cistern':cistern,'fen_roof':fen_roof,
         'upland_wall':upland_wall,'upland_shelter':upland_shelter,'upland_paving':paving,
         'impact_fragment':impact,'root_fragment':root_fragment,'augmentation_inlay':inlay,
         'forge_threshold':threshold,'forge_lamella':lamella}
apertures={'rootvault_frame':{'width_m':2.0,'height_m':2.10},'upland_shelter':{'width_m':2.0,'height_m':2.02},'forge_threshold':{'width_m':2.0,'height_m':2.40}}
report={'source':'tools/wroughtwild-blender/scripts/build_cataclysm.py','seed':config['seed'],
        'coordinates':'Godot metres. +Z is the damage/impact direction. Ground y=0 with small intentional burial.',
        'collision':'Visual-only. No exported bodies or resource yield. Runtime keeps paths outside the measured extents.',
        'material_contract':'Keep imported surfaces for embedded original grain, linear vertex colours, varied roughness and tiny pale seams.',
        'assets':{}}
for index,(name,recipe) in enumerate(recipes.items()):
    seed=config['seed']+index*701;g=Geometry(seed);recipe(g);again=Geometry(seed);recipe(again)
    assert g.vertices==again.vertices and g.faces==again.faces and g.colours==again.colours and g.kinds==again.kinds
    assert all(math.isfinite(v) for p in g.vertices for v in p)
    for face in g.faces:
        a,b,c=[Vector(g.vertices[i]) for i in face[:3]]
        assert (b-a).cross(c-a).length>1e-9,(name,face)
    # Last-stage colour treatment leaves every vertex, aperture and derived
    # runtime body exactly where the accepted kit put it. Apply only once,
    # after nested recipes have composed their parts.
    for i, (face, kind) in enumerate(zip(g.faces, g.kinds)):
        if kind == 'light': continue
        p=sum((Vector(g.vertices[v]) for v in face),Vector())/len(face)
        damp=math.exp(-max(0,p.y)/.48)*config['base_weathering']
        patch=(math.sin(p.x*2.3+p.z)+math.cos(p.z*3.1-p.y))*.25+.5
        c=tint(g.colours[i],1-damp)
        moss=damp*patch*.55 if kind in ['stone','wood','reed'] else 0
        g.colours[i]=tuple(v*(1-moss)+palette['moss'][a]*moss for a,v in enumerate(c))
    obj=g.object('cataclysm_'+name)
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
    path=output/('cataclysm_'+name+'.glb')
    # MATERIAL inference does not recognise this vertex-colour/texture multiply
    # and emits a synthetic white COLOR_0 plus the real layer as COLOR_1.
    # glTF runtime materials multiply COLOR_0, so choose the authored layer
    # explicitly instead of relying on shader-graph inference.
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_apply=True,export_cameras=False,export_lights=False,export_extras=False,export_vertex_color='NAME',export_vertex_color_name='Color',export_all_vertex_colors=False)
    blob=path.read_bytes();json_length=struct.unpack_from('<I',blob,12)[0]
    gltf=json.loads(blob[20:20+json_length]);binary_start=28+json_length
    exported=[]
    for primitive in gltf['meshes'][0]['primitives']:
        accessor=gltf['accessors'][primitive['attributes']['COLOR_0']]
        view=gltf['bufferViews'][accessor['bufferView']]
        fmt,component_size,divisor={5121:('B',1,255),5123:('H',2,65535),5126:('f',4,1)}[accessor['componentType']]
        stride=view.get('byteStride',component_size*4)
        start=binary_start+view.get('byteOffset',0)+accessor.get('byteOffset',0)
        for vertex in range(accessor['count']):
            exported.append(tuple(v/divisor for v in struct.unpack_from('<'+fmt*3,blob,start+vertex*stride)))
    expected_min=[min(srgb(c[axis]) for c in g.colours) for axis in range(3)]
    expected_max=[max(srgb(c[axis]) for c in g.colours) for axis in range(3)]
    exported_min=[min(c[axis] for c in exported) for axis in range(3)]
    exported_max=[max(c[axis] for c in exported) for axis in range(3)]
    assert all(abs(a-b)<.005 for a,b in zip(expected_min+expected_max,exported_min+exported_max)),(name,'GLB COLOR_0 differs from authored palette',exported_min,exported_max,expected_min,expected_max)
    report['assets']['cataclysm_'+name]={'triangles':sum(len(face)-2 for face in g.faces),
        'bounds_min':[min(p[axis] for p in g.vertices) for axis in range(3)],
        'bounds_max':[max(p[axis] for p in g.vertices) for axis in range(3)],
        'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
        'materials':sorted(set(g.kinds)),'clear_aperture':apertures.get(name),
        'colour_linear_min':expected_min,'colour_linear_max':expected_max,
        'pivot':'lower centre, y=0; imported transform is identity'}
    obj.hide_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(output/'cataclysm-source.blend'))
(output/'cataclysm_manifest.json').write_text(json.dumps(report,indent=2))
print('CATACLYSM_AUTHORING_OK',len(recipes),'deterministic visual exports')
