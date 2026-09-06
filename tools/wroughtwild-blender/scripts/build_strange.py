"""Authored Strange Frontier kit: deterministic local Blender -> visual GLB.

Uses the reviewed nature-study conventions: Godot metres, applied ground
pivots, linear vertex colours, no runtime bodies or gameplay data in exports.
Run Blender --background --python this-file -- project output-directory.
"""
import hashlib
import json
import math
from pathlib import Path
import random
import sys

import bpy
from mathutils import Vector

project, output = map(Path, sys.argv[sys.argv.index('--') + 1:])
output.mkdir(parents=True, exist_ok=True)
config = json.loads((Path(__file__).resolve().parents[1] / 'strange.json').read_text())
palette = {key: tuple(int(value[i:i+2], 16)/255 for i in (0,2,4)) for key,value in config['palette'].items()}

def shade(c, amount): return tuple(min(1,max(0,x*amount)) for x in c)
def linear(c): return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
def xyz(p): return (p[0],-p[2],p[1])

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
material=bpy.data.materials.new('Strange Frontier · aged surfaces')
material.use_nodes=True
bsdf=material.node_tree.nodes.get('Principled BSDF')
bsdf.inputs['Roughness'].default_value=.88
col=material.node_tree.nodes.new('ShaderNodeVertexColor')
col.layer_name='Color'
material.node_tree.links.new(col.outputs['Color'],bsdf.inputs['Base Color'])

class Geometry:
    def __init__(self, seed):
        self.vertices=[]; self.faces=[]; self.colours=[]
        self.corner_normals=[]
        self.rng=random.Random(seed)
    def face(self, points, colour, outside=None, normals=None):
        pts=list(map(Vector,points))
        if outside is not None and (pts[1]-pts[0]).cross(pts[2]-pts[0]).dot(sum(pts,Vector())/len(pts)-Vector(outside))<0:
            pts.reverse()
            if normals is not None: normals=list(reversed(normals))
        start=len(self.vertices)
        self.vertices.extend(tuple(p) for p in pts)
        self.faces.append(tuple(range(start,start+len(pts))))
        self.colours.append(colour)
        self.corner_normals.extend([None]*len(pts) if normals is None else list(normals))
    def tube(self, points, radii, colour, sides=None, cap=True, ridges=False):
        sides=sides or config['radial_sides']; pts=list(map(Vector,points)); rings=[]; previous=None
        for i,(p,r) in enumerate(zip(pts,radii)):
            tangent=(pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)]).normalized()
            cross=previous-tangent*previous.dot(tangent) if previous is not None else tangent.cross(Vector((0,1,0)))
            if cross.length<.01: cross=tangent.cross(Vector((1,0,0)))
            cross.normalize(); previous=cross; up=tangent.cross(cross).normalized()
            rings.append([p+(cross*math.cos(a*math.tau/sides)+up*math.sin(a*math.tau/sides))*r*(1+config['bark_ridge']*math.sin(a*3.9) if ridges else 1) for a in range(sides)])
        for i in range(len(rings)-1):
            for j in range(sides):
                k=(j+1)%sides
                self.face([rings[i][j],rings[i][k],rings[i+1][k],rings[i+1][j]],shade(colour,.9+.15*math.sin(j*2.4)**2),pts[i].lerp(pts[i+1],.5))
        if cap:
            self.face(rings[0],shade(colour,.8),pts[1])
            self.face(rings[-1],colour,pts[-2])
    def box(self, centre, size, colour):
        c=Vector(centre); s=Vector(size)*.5
        pts=[c+Vector((x*s.x,y*s.y,z*s.z)) for x,y,z in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
        for f in [(0,1,2,3),(5,4,7,6),(4,0,3,7),(1,5,6,2),(3,2,6,7),(4,5,1,0)]: self.face([pts[i] for i in f],colour,c)
    def petal(self, centre, length, width, angle, colour, folded=.14):
        c=Vector(centre); right=Vector((math.cos(angle),0,math.sin(angle)))*width
        top=c+Vector((0,length,0)); ridge=c+Vector((math.sin(angle)*folded,length*.5,-math.cos(angle)*folded))
        for a,b in [(c,c+right+Vector((0,length*.4,0))),(c+right+Vector((0,length*.4,0)),top),(top,c-right+Vector((0,length*.5,0))),(c-right+Vector((0,length*.5,0)),c)]:
            self.face([a,b,ridge],colour)
            self.face([ridge,b,a],shade(colour,.86))
    def object(self,name):
        mesh=bpy.data.meshes.new(name);mesh.from_pydata([xyz(p) for p in self.vertices],[],self.faces);mesh.update()
        colours=mesh.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='CORNER')
        for poly,c in zip(mesh.polygons,self.colours):
            for index in poly.loop_indices: colours.data[index].color=tuple(linear(x) for x in c)+(1,)
        if any(normal is not None for normal in self.corner_normals):
            normals=[None]*len(mesh.loops)
            for poly in mesh.polygons:
                poly.use_smooth=True
                for loop in poly.loop_indices:
                    n=self.corner_normals[loop]
                    normals[loop]=poly.normal if n is None else xyz(n)
            mesh.normals_split_custom_set(normals)
        mesh.materials.append(material); obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
        return obj

def arch(g):
    w=config['root_arch_width_m']*.5;h=config['root_arch_height_m']
    points=[(-w+2*w*i/24,h*math.sin(math.pi*i/24)**.82-.25,.38*math.sin(i*.33)) for i in range(25)]
    g.tube(points,[1.02-.42*math.sin(math.pi*i/24) for i in range(25)],palette['bark'],ridges=True)
    for sign in (-1,1):
        for k in range(4):
            end=(sign*(w+1.9+k*.48),-.15,(k-1.5)*1.45)
            g.tube([(sign*w,.7,-.2),(sign*(w+.8),.12,(k-1.5)*.75),end],[.45,.23,.035],palette['bark'],sides=8,ridges=True)
    for k,index in enumerate((5,9,12,15,19)):
        start=Vector(points[index]);side=-1 if k%2 else 1
        knee=start+Vector((side*.55,1.35,.3));tip=start+Vector((side*1.65,2.45,.65))
        g.tube([start,knee,tip],[.36,.2,.045],palette['bark'],sides=8,ridges=True)
        g.tube([knee,knee+Vector((-side*.6,.5,-.85)),knee+Vector((-side*1.1,.85,-1.3))],[.12,.07,.02],palette['bark_light'],sides=7)

def hollow(g,small=False):
    h=2.5 if small else config['hollow_trunk_height_m'];r=.68 if small else 1.15
    # Broad open front and dark inner wall: this is a hollow, never a painted ring.
    angles=[.48+i*4.85/14 for i in range(15)]
    outer=[];inner=[]
    for row,(y,scale,lean) in enumerate(((-.12,1.0,0),(h*.35,.98,.05),(h*.72,.85,.2),(h*.94,.7,.35))):
        ring=[];inside=[]
        for i,a in enumerate(angles):
            yy=y+(g.rng.uniform(-.17,.12)*h if row==3 else 0)
            radius=r*scale*(1+.07*math.sin(i*2.73))
            ring.append(Vector((math.sin(a)*radius+lean,yy,math.cos(a)*radius)))
            inside.append(Vector((math.sin(a)*(radius-.19)+lean,yy,math.cos(a)*(radius-.19))))
        outer.append(ring);inner.append(inside)
    for row in range(3):
        for i in range(14):
            middle=(outer[row][i]+outer[row+1][i+1])*.5
            g.face([outer[row][i],outer[row][i+1],outer[row+1][i+1],outer[row+1][i]],shade(palette['bark'],.91+.14*math.sin(i*1.7)**2),(middle.x*.1,middle.y,0))
            a=(angles[i]+angles[i+1])*.5
            g.face([inner[row][i],inner[row][i+1],inner[row+1][i+1],inner[row+1][i]],shade(palette['bark'],.64),(math.sin(a)*r*2,middle.y,math.cos(a)*r*2))
    for i in range(14):g.face([outer[-1][i],outer[-1][i+1],inner[-1][i+1],inner[-1][i]],palette['heartwood'],(0,0,0))
    for end in (0,-1):
        for row in range(3):g.face([outer[row][end],outer[row+1][end],inner[row+1][end],inner[row][end]],palette['heartwood'])
    for i in range(0,15,2):g.tube([outer[row][i] for row in range(4)],[.04,.045,.032,.01],palette['bark_light'],sides=5)
    for k in range(4):
        a=.4+k*1.55
        g.tube([(math.sin(a)*r,.35,math.cos(a)*r),(math.sin(a)*r*1.8,.05,math.cos(a)*r*1.8)],[.27,.035],palette['bark'],sides=7)
    for k in range(7):
        a=.3+k*.83
        g.petal((math.sin(a)*r*.65,h*.27+(k%3)*h*.08,math.cos(a)*r*.65),h*.2,.22,a,palette['paper_dark'])

def rib(g):
    h=config['stone_rib_height_m']
    for side in range(3):
        x=(side-1)*.48
        g.tube([(x,-.25,0),(x+.2,h*.3,.2),(x+.85,h*.72,.65),(x+1.55,h,.78)], [.78,.64,.42,.06],shade(palette['stone'],1-side*.08),sides=5)
    for k in range(5):
        g.tube([(-.7,.2+k*.55,-.54),(1.15,.22+k*.55,-.5)],[.036,.012],palette['stone_dark'],sides=4)

def glass(g,large=False):
    scale=3.4 if large else 1
    for k in range(5 if large else 3):
        x=(k-1)*.28*scale
        pts=[(x,-.08,0),(x+.09,.28*scale,.07),(x+.18,.68*scale,-.025),(x+.02,1.02*scale,.12)]
        g.tube(pts,[.18*scale,.14*scale,.105*scale,.078*scale],palette['glass'],sides=10,cap=False)
        for j in range(4):
            y=(.2+j*.17)*scale
            g.tube([(x-.11*scale,y,0),(x+.1*scale,y+.015*scale,0)],[.022*scale,.014*scale],palette['stone'],sides=6)
    for k in range(4):
        a=k*1.7
        g.tube([(0,.05,0),(math.cos(a)*1.1*scale,.07,math.sin(a)*.65*scale)],[.15*scale,.025*scale],palette['stone_dark'],sides=6)

def root(g,core=False):
    if not core:
        for a in [2.25,3.1,3.9,4.8,5.65]:
            g.tube([(-1.5,.32+math.sin(a)*.24,math.cos(a)*.34),(-.3,.35+math.sin(a)*.29,math.cos(a)*.38),(1.5,.4+math.sin(a)*.25,math.cos(a)*.31)],[.18,.15,.11],palette['bark'],sides=7,ridges=True)
        for sign in (-1,1): g.tube([(sign*.82,0,-.62),(sign*.8,.84,-.1),(sign*.7,.74,.5)],[.13,.095,.055],palette['heartwood'],sides=7)
    else:
        pts=[]
        for i in range(68):
            a=i*math.tau/16;pts.append((-1.0+i*.03,.48+math.cos(a)*.24,math.sin(a)*.24))
        g.tube(pts,[.065]*len(pts),palette['heartwood'],sides=7,ridges=True)

def membrane(g):
    for i in range(10):
        a=i*math.tau/10
        pts=[(math.cos(a)*.23,.08,math.sin(a)*.23),(math.cos(a)*.45,.35,math.sin(a)*.45),(math.cos(a)*.35,.79,math.sin(a)*.35),(math.cos(a)*.11,1.08,math.sin(a)*.11)]
        g.tube(pts,[.12,.135,.09,.04],shade(palette['membrane'],.93+.12*(i%3)/2),sides=7)

def vent(g):
    for i in range(9):
        a=i*math.tau/9
        g.tube([(math.cos(a)*.51,-.12,math.sin(a)*.51),(math.cos(a)*.46,.3,math.sin(a)*.46),(math.cos(a)*.31,.55+g.rng.random()*.12,math.sin(a)*.31)],[.25,.22,.08],palette['stone_dark'],sides=7)

def pullstone(g):
    g.tube([(-.5,.05,0),(-.25,.55,0),(.2,.86,.12),(.55,.95,.08)],[.53,.49,.32,.05],palette['grit'],sides=7)
    for k in range(35):
        y=.22+g.rng.random()*.48;z=g.rng.uniform(-.25,.25);x=.23+g.rng.random()*.21
        g.tube([(x,y,z),(x+.18+g.rng.random()*.16,y+.015,z+.02)],[.023,.006],palette['iron'],sides=4)

def heart(g):
    for k in range(9):
        a=k*math.tau/9
        g.petal((math.cos(a)*.12,.10,math.sin(a)*.12),.62,.16,a,palette['paper'])
    g.tube([(0,.2,0),(0,.43,0),(0,.65,0)],[.12,.2,.06],palette['heart'],sides=12)

def empty_husk(g):
    for k in range(5):
        a=k*math.tau/5
        g.petal((math.cos(a)*.15,.02,math.sin(a)*.15),.34,.12,a,palette['paper_dark'],folded=.08)

def fixture(g,kind):
    wood=palette['frame'];metal=palette['iron']
    if kind=='lamp':
        g.box((0,.08,0),(.55,.16,.45),wood)
        for sign in (-1,1): g.tube([(sign*.25,.1,0),(sign*.27,.65,0),(sign*.12,1.02,0)],[.045,.045,.035],metal,sides=6)
        g.box((0,1.02,0),(.42,.075,.3),wood)
    elif kind in ('winch','landing'):
        g.box((0,.08,0),(1.4,.16,1.15),wood)
        for x in (-.55,.55):
            g.box((x,.92,0),(.13,1.7,.16),wood)
            g.tube([(x,.12,-.48),(x,.87,0)],[.075,.07],wood,sides=6)
        g.box((0,1.74,0),(1.4,.17,.19),wood)
        if kind=='winch':
            g.tube([(-.8,1.05,0),(.8,1.05,0)],[.08,.08],metal,sides=10)
            g.tube([(.8,1.05,0),(.8,1.05,.35),(1.02,1.05,.35)],[.045,.045,.045],metal,sides=6)
    elif kind=='drum':
        g.tube([(-.4,0,0),(.4,0,0)],[.24,.24],wood,sides=12)
        for x in (-.43,.43):g.tube([(x-.03,0,0),(x+.03,0,0)],[.36,.36],metal,sides=12)
        pts=[(-.37+i*.01,math.sin(i*math.tau/14)*.255,math.cos(i*math.tau/14)*.255) for i in range(76)]
        g.tube(pts,[.035]*len(pts),palette['rope'],sides=5)
    elif kind=='basket':
        g.box((0,.045,0),(.8,.09,.65),wood)
        for y in (.13,.28,.43):
            for z in (-.31,.31):g.box((0,y,z),(.8,.085,.065),wood)
            for x in (-.37,.37):g.box((x,y,0),(.065,.085,.6),wood)
        for x in (-.35,.35):g.tube([(x,.03,-.29),(x,.54,-.29),(x,.54,.29),(x,.03,.29)],[.04]*4,palette['rope'],sides=6)
    elif kind=='lever':
        g.box((0,.08,0),(.65,.16,.5),wood)
        for x in (-.18,.18):g.tube([(x,.1,0),(x,.42,0)],[.065,.065],metal,sides=8)
        g.tube([(-.3,.4,0),(.3,.4,0)],[.07,.07],palette['glass'],sides=10)
    elif kind=='arm':
        g.tube([(0,0,0),(0,.48,.19)],[.06,.045],palette['glass'],sides=10)
        g.tube([(-.16,.48,.19),(.16,.48,.19)],[.065,.065],wood,sides=8)
    elif kind=='sorter':
        for x in (-.55,.55):g.box((x,.43,0),(.12,.86,.7),wood)
        for z in (-.33,.33):g.box((0,.74,z),(1.3,.14,.1),wood)
        for x in (-.34,.34):
            g.box((x,.11,.15),(.57,.12,.72),metal)
            for z in (-.18,.49):g.box((x,.2,z),(.57,.16,.04),wood)
        g.tube([(0,.73,-.1),(0,1.15,-.2)],[.25,.15],palette['grit'],sides=8)
        for k in range(11):g.tube([(-.4+k*.08,.71,-.28),(-.4+k*.08,.5,.25)],[.014,.014],metal,sides=4)
    elif kind=='bellows':
        g.box((0,.075,0),(.85,.15,.7),wood)
        g.tube([(0,.2,-.15),(0,.19,-.7)],[.13,.065],metal,sides=10)
        g.tube([(-.42,.1,0),(-.42,.93,.05),(.4,.93,.05),(.4,.1,0)],[.04]*4,metal,sides=6)
        g.box((0,.91,.12),(.92,.11,.32),wood)

recipes={'root_arch':arch,'hollow_trunk':hollow,'lantern_shell':lambda g:hollow(g,True),
         'stone_rib':rib,'lightning_scar':lambda g:glass(g,True),'stormglass':glass,
         'thrumroot_shell':root,'thrumroot_core':lambda g:root(g,True),'vent_case':vent,
         'ventlung':membrane,'pullstone':pullstone,'lanternheart':heart,'empty_husk':empty_husk}
for name in ('lamp','winch','landing','drum','basket','lever','arm','sorter','bellows'):
    recipes[name]=lambda g,name=name:fixture(g,name)

# Bounded owner-directed natural silhouette refinement. Fixture/core IDs keep
# their original geometry; the ecology kit overrides only decorative assets.
sys.path.insert(0,str(Path(__file__).resolve().parent))
from polish_strange_nature import install
install(recipes,Geometry,palette,config)

report={'study_type':'strange_frontier','author':'Codex (OpenAI)','seed':config['seed'],'assets':{},'collision':'visual-only; gameplay bodies remain in Godot'}
objects=[]
for index,(name,recipe) in enumerate(recipes.items()):
    seed=config['seed']+index*997
    geometry=Geometry(seed);recipe(geometry)
    repeated=Geometry(seed);recipe(repeated)
    assert geometry.vertices==repeated.vertices and geometry.faces==repeated.faces and geometry.colours==repeated.colours and geometry.corner_normals==repeated.corner_normals
    assert all(math.isfinite(c) for p in geometry.vertices for c in p)
    for face in geometry.faces:
        a,b,c=(Vector(geometry.vertices[i]) for i in face[:3]);assert (b-a).cross(c-a).length>1e-8,(name,face)
    obj=geometry.object('strange_'+name);objects.append(obj)
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
    target=output/('strange_'+name+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,export_yup=True,export_apply=True,export_cameras=False,export_lights=False,export_extras=False)
    report['assets'][name]={'triangles':sum(len(f)-2 for f in geometry.faces),'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
         'bounds_min':[min(p[a] for p in geometry.vertices) for a in range(3)],'bounds_max':[max(p[a] for p in geometry.vertices) for a in range(3)]}
    obj.hide_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(output/'strange-frontier-source.blend'))
(output/'report.json').write_text(json.dumps(report,indent=2))
manifest={'purpose':'Curated visual-only Strange Frontier assets; metres and applied ground pivots.',
          'source':'tools/wroughtwild-blender/scripts/build_strange.py',
          'nature_refinement_source':'tools/wroughtwild-blender/scripts/polish_strange_nature.py',
          'crown_anchor_m':[-3.1,9.3,-.65],
          'ground_note':'Negative root/stone bounds are intentional burial. Do not lift scenery by its AABB minimum.',
          'assets':{'strange_'+name:value for name,value in report['assets'].items()}}
(output/'strange_nature_manifest.json').write_text(json.dumps(manifest,indent=2))
print('STRANGE_FRONTIER_AUTHORING_OK',len(objects),'deterministic visual exports')
