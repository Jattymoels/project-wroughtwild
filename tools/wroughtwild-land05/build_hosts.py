"""Original LAND-05 growth and close bank kit, Blender 4.5 background recipe.

Large solid geology is generated/editable native terrain. Low bank skins are
conformed to those exact triangles in journeys.gd; taller forms are foliage.
"""
import bpy, math, random, json, hashlib, sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/wroughtwild-art07/b2'))
from geometry import Mesh,tube,leaf
OUT=ROOT/'game/land05/assets'
SOURCE=ROOT/'build/land05/source-art'
OUT.mkdir(parents=True,exist_ok=True); SOURCE.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
mat=bpy.data.materials.new('LAND05 original host vertex materials');mat.use_nodes=True
p=mat.node_tree.nodes.get('Principled BSDF');p.inputs['Roughness'].default_value=.88
attr=mat.node_tree.nodes.new('ShaderNodeVertexColor');attr.layer_name='Plant colour'
mat.node_tree.links.new(attr.outputs['Color'],p.inputs['Base Color'])

def ribbon(m,path,width,color,phase=0):
    # UV.y is distance from the common root: sibling branches share pulse time.
    base=len(m.v)
    for j,p in enumerate(map(Vector,path)):
        t=j/(len(path)-1);q=Vector(path[min(j+1,len(path)-1)])-Vector(path[max(j-1,0)])
        side=Vector((-q.y,q.x,0)).normalized()*width*(.65+.35*math.sin(t*math.pi))
        m.vert(p-side,(0,phase+t),color);m.vert(p+side,(1,phase+t),color)
    for j in range(len(path)-1):m.face(base+2*j,base+2*j+2,base+2*j+3,base+2*j+1)

def clast(m,center,rx,ry,h,rng,color):
    start=len(m.v);n=9
    outer=[(math.cos(j/n*math.tau)*rx*rng.uniform(.84,1.12),math.sin(j/n*math.tau)*ry*rng.uniform(.84,1.12)) for j in range(n)]
    for k in range(3):
        for j,(x,y) in enumerate(outer):
            inset=[1,.94,.68][k];z=[-.035,h*.40,h][k]
            c=tuple(v*rng.uniform(.87,1.12)*(1.12 if k==2 else .88) for v in color)
            m.vert(Vector(center)+Vector((x*inset,y*inset,z)),(j/n,k/2),c)
    for k in range(2):
        for j in range(n):a=start+k*n+j;b=start+k*n+(j+1)%n;m.face(a,b,b+n,a+n)
    m.face(*[start+2*n+j for j in range(n)])

def sheath(m,root,angle,length,width,lift,color,phase,rng):
    root=Vector(root);d=Vector((math.cos(angle),math.sin(angle),0));side=Vector((-d.y,d.x,0));start=len(m.v)
    for j in range(11):
        t=j/10;shape=math.sin(math.pi*t)**.67
        mid=root+d*length*(.22*t+.78*t*t)+Vector((0,0,lift*(math.sin(t*1.80))+.05*t))
        for s in [-1,-.5,0,.5,1]:
            # Stiff deeply cupped bracts overlap around a protected interior.
            pos=mid+side*width*shape*s+Vector((0,0,abs(s)**1.8*width*.50*shape))
            edge=1.17 if abs(s)==1 else (.80 if s==0 else 1.0)
            c=tuple(v*edge*(.80+.20*t) for v in color)
            m.vert(pos,(s*.5+.5,t),c)
    for j in range(10):
        for s in range(4):a=start+j*5+s;m.face(a,a+5,a+6,a+1)
    # Fine mineral line is enclosed by the overlapping sheath, never its outline.
    if phase%3==0:
        path=[]
        for j in range(3,8):
            t=j/10;path.append(root+d*length*(.22*t+.78*t*t)+Vector((0,0,lift*math.sin(t*1.80)+.05*t+.007)))
        ribbon(m,path,.014,(.035,.28,.57),phase=.20)

def sprig(m,root,angle,height,rng,dry=False):
    d=Vector((math.cos(angle),math.sin(angle),0));root=Vector(root)
    path=[root+d*.22*t+Vector((0,0,height*t)) for t in [0,.25,.5,.75,1]]
    tube(m,path,[.025,.022,.017,.012,.003],(.115,.083,.043),sides=7)
    for j in range(2,7):
        t=j/7;at=root+d*.22*t+Vector((0,0,height*t))
        for s in [-1,1]:
            a=angle+s*1.15+j*.28;direction=Vector((math.cos(a),math.sin(a),.30))
            leaf(m,at,direction,.22 if dry else .40,.065 if dry else .10,(.17,.205,.093) if dry else (.105,.18,.06),detail=1)

def root_graph(m,rng,green=True,low=False):
    # One branching graph, not disconnected decorated roots. Every fork starts
    # at the parent node. Large gaps exist between susceptible colonies.
    bark=(.20,.126,.062) if not low else (.24,.157,.076)
    glow=(.035,.49,.16) if green else (.64,.69,.59)
    width=2.7 if not low else 2.2;length=4.6 if not low else 3.8
    trunk=[Vector((.18*math.sin(t*3),-length*.5+length*t,.085+.06*math.sin(t*math.pi))) for t in [0,.2,.4,.6,.8,1]]
    tube(m,trunk,[.26,.38,.32,.27,.16,.065] if not low else [.14,.21,.18,.14,.10,.03],bark,sides=10)
    ribbon(m,[p+Vector((0,0,.115 if not low else .062)) for p in trunk],.017 if not low else .011,glow,phase=0)
    root_start=len(m.v)
    for j in range(1,5):
        parent=trunk[j]
        for sign in [-1,1]:
            end=parent+Vector((sign*width*rng.uniform(.64,1.0),rng.uniform(.35,1.0),-.015))
            path=[parent,parent.lerp(end,.30)+Vector((sign*.12,-.09,.025)),parent.lerp(end,.7)+Vector((0,.15,0)),end]
            tube(m,path,[.25,.20,.12,.024] if not low else [.14,.12,.075,.012],bark,sides=9)
            ribbon(m,[p+Vector((0,0,.078 if not low else .046)) for p in path],.011 if not low else .008,glow,phase=j/5)
            fork=path[2];tip=fork+Vector((sign*.28,-.68,.012))
            tube(m,[fork,fork.lerp(tip,.55)+Vector((0,0,.04)),tip],[.10,.065,.01],bark,sides=7)
            ribbon(m,[fork+Vector((0,0,.034)),tip+Vector((0,0,.005))],.006,glow,phase=j/5+.7)
            # Root tips produce fans attached directly to the branching junction.
            for k in range(2 if low else 3):
                at=end+Vector((0,0,.035))
                angle=math.atan2(end.y-parent.y,end.x-parent.x)+(k-1.5)*.38
                if low:
                    sprig(m,at,angle,rng.uniform(.24,.52),rng,dry=True)
                elif not green:
                    sprig(m,at,angle,rng.uniform(.38,.72),rng,dry=True)
                else:
                    d=Vector((math.cos(angle),math.sin(angle),0))
                    height=rng.uniform(1.75,2.65)
                    path=[at+d*(t*t*1.0)+Vector((0,0,height*math.sin(t*1.55))) for t in [0,.2,.4,.6,.8,1]]
                    tube(m,path,[.04,.035,.028,.021,.013,.003],bark,sides=7)
                    for j in range(1,6):
                        t=j/7;mid=at+d*(t*t)+Vector((0,0,height*math.sin(t*1.55)))
                        lateral=Vector((-d.y,d.x,.22))
                        for side in [-1,1]:
                            leaf(m,mid,lateral*side+d*.34+Vector((0,0,.13)),(.75-.42*t),.115,(.15,.245,.074),detail=1)
    # Broad basal ridges embrace the junctions, remaining thin against terrain.
    for j in range(1,5):
        at=trunk[j]
        clast(m,at+Vector((0,0,-.03)),.38 if not low else .24,.30,.10,rng,bark)

roles={
 'blue-sheaths':'Nested, persistent overlapping bracts shelter a pale retained centre; living fen/bank foliage.',
 'blue-lamination':'Thin irregular mineral scales cling to native supported nested banks; no freestanding solid shell.',
 'white-brace':'Asymmetric loaded roots and offset mineral flakes follow one common displacement direction.',
 'green-root-fan':'Broad connected branching woody roots with attached moist woodland fronds.',
 'green-steppe-colony':'Low horizontal connected woody colony with small stiff dry-host leaves and real gaps.',
 'root-link':'Connected low branching bark follows actual host ground and stops at dry gaps.',
 'blue-bracts-dry':'Short compact perennial overlapping bracts for the sheltered Rocky Hills fallback.'}
report={}
for slot,(role,purpose) in enumerate(roles.items()):
    rng=random.Random(170904+slot*817);m=Mesh()
    if role=='root-link':
        # Unit-length modular root skin, with flattened buttressed section.
        path=[(0,-.5,0),(.035,-.25,.018),(0,0,.022),(-.03,.25,.015),(0,.5,0)]
        tube(m,path,[.22,.28,.30,.26,.22],(.20,.125,.056),sides=10)
        for i,(x,y,z) in enumerate(m.v):m.v[i]=(x,y,z*.36+.065)
        for side in [-1,1]:
            tube(m,[(0,-.15,.07),(side*.24,.04,.055),(side*.44,.28,.025)],[.075,.05,.015],(.22,.148,.066),sides=7)
        ribbon(m,[(.01,-.5,.147),(.04,0,.18),(-.025,.5,.147)],.014,(.035,.49,.16),phase=0)
    elif role in ['blue-sheaths','blue-bracts-dry']:
        dry=role=='blue-bracts-dry'
        for plant in range(4 if not dry else 3):
            root=Vector((math.cos(plant*2.4)*(.65 if plant else 0),math.sin(plant*2.4)*.52,-.04))
            for tier in range(3):
                for k in range(7-tier):
                    a=k*math.tau/(7-tier)+tier*.57+plant*.9
                    scale=(1-tier*.20)*(.61 if dry else 1)
                    c=(.15,.19,.105) if tier<2 else (.22,.27,.17)
                    sheath(m,root+Vector((0,0,tier*.12)),a,1.55*scale,.36*scale,(1.40+tier*.24)*scale,c,k+tier,rng)
    elif role=='blue-lamination':
        for bank in range(4):
            for row in range(3):
                # broken staggered retained plates; no complete concentric ring
                at=(-1.5+bank*1.02+row*.14,-.48+row*.55,.012*row)
                clast(m,at,.90-rng.random()*.16,.65,.14+row*.025,rng,(.23,.265,.24))
                if bank%3!=2:
                    path=[Vector(at)+Vector((-.34,-.36,.028)),Vector(at)+Vector((-.04,-.38,.033)),Vector(at)+Vector((.22,-.28,.028))]
                    ribbon(m,path,.012,(.035,.28,.57),phase=row*.21)
    elif role=='white-brace':
        root_graph(m,rng,green=False)
        for k in range(7):
            # one directional stagger, with independent broken intervals
            at=(-2.1+k*.66,-.5+k*.15,.025)
            clast(m,at,.60,.47,.20,rng,(.25,.25,.20))
    else:root_graph(m,rng,green=True,low=role=='green-steppe-colony')
    if role in ['green-root-fan','green-steppe-colony','white-brace']:
        m.v=[(x,y,.07+(z-.07)*.40 if z<.42 else z) for x,y,z in m.v]
    ob=m.obj('LAND05 '+role,mat);ob['purpose']=purpose;ob['support']='Native actual terrain triangles; no stock or terrain owner'
    ob.data.calc_loop_triangles()
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
    file=OUT/(role+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(file),export_format='GLB',use_selection=True,export_animations=False,export_all_vertex_colors=True)
    report[role]={'purpose':purpose,'triangles':len(ob.data.loop_triangles),'vertices':len(ob.data.vertices),'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'bounds_blender':[list(min(v.co[i] for v in ob.data.vertices) for i in range(3)),list(max(v.co[i] for v in ob.data.vertices) for i in range(3))]}
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'force-hosts.blend'),compress=True)
document={'method':'Original directly authored procedural Blender geometry, not image-to-3D or concept pixels.','recipe':'tools/wroughtwild-land05/build_hosts.py','seed':170904,'source':str(SOURCE/'force-hosts.blend'),'coordinates':'Metres; standard glTF Y up.','forms':report}
(OUT.parent/'source.json').write_text(json.dumps(document,indent=2)+'\n',encoding='utf8')
(SOURCE/'source.json').write_text(json.dumps(document,indent=2)+'\n',encoding='utf8')
print('LAND05_ART '+json.dumps(document))
