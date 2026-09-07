"""Selected animal concepts -> editable Blender master and five game skins.

Run Blender --background --python this_file -- <repository> <output directory>.
Only Blender's bundled modules are used. Coordinates below are Godot metres.
"""
import hashlib
import json
import math
from pathlib import Path
import random
import sys

import bpy
from mathutils import Vector, Quaternion
from mathutils.bvhtree import BVHTree

ROOT, OUT = map(Path, sys.argv[sys.argv.index('--') + 1:])
OUT.mkdir(parents=True, exist_ok=True)
CFG = json.loads((Path(__file__).resolve().parents[1] / 'augmented_beasts.json').read_text())
WORLD = json.loads((ROOT / 'data/tuning/world.json').read_text())
ROWS = {r['id']: r for r in WORLD['enemies']}
TAU = math.tau


def xyz(p): return Vector((p[0], -p[2], p[1]))
def godot(p): return Vector((p[0], p[2], -p[1]))
def lerp(a, b, t): return Vector(a).lerp(Vector(b), t)
def clamp(x): return min(1.0, max(0.0, x))
def rgb(s): return tuple(int(s[i:i+2], 16) / 255 for i in (0, 2, 4))


class Geo:
    def __init__(self):
        self.v, self.f, self.tiles, self.weights = [], [], [], []

    def patch(self, verts, faces, tile=0, weights=None):
        start = len(self.v)
        self.v.extend(tuple(p) for p in verts)
        self.weights.extend([weights or {'body': 1.0}] * len(verts))
        self.f.extend(tuple(start + i for i in f) for f in faces)
        self.tiles.extend([tile] * len(faces))

    def ellipsoid(self, at, scale, tile=0, weights=None, sides=20, rings=12):
        # UV spheres with shared vertices; poles are single vertices.
        v = [Vector(at) + Vector((0, scale[1], 0))]
        for i in range(1, rings):
            a = math.pi * i / rings
            for j in range(sides):
                b = TAU * j / sides
                v.append(Vector(at) + Vector((scale[0]*math.sin(a)*math.cos(b), scale[1]*math.cos(a), scale[2]*math.sin(a)*math.sin(b))))
        bottom = len(v)
        v.append(Vector(at) - Vector((0, scale[1], 0)))
        faces = []
        for j in range(sides): faces.append((0, 1+(j+1)%sides, 1+j))
        for i in range(rings-2):
            for j in range(sides):
                a = 1+i*sides+j; b = 1+i*sides+(j+1)%sides
                faces.append((a, b, b+sides, a+sides))
        for j in range(sides): faces.append((bottom, bottom-sides+j, bottom-sides+(j+1)%sides))
        self.patch(v, faces, tile, weights)

    def tube(self, points, radii, tile=0, weights=None, sides=None):
        sides = sides or CFG['tube_sides']
        points = list(map(Vector, points)); v = []; cross = None
        for i, p in enumerate(points):
            d = (points[min(i+1, len(points)-1)] - points[max(i-1, 0)]).normalized()
            c = d.cross(Vector((0, 1, 0))) if cross is None else cross-d*cross.dot(d)
            if c.length < .001: c = d.cross(Vector((1, 0, 0)))
            c.normalize(); cross = c; up = d.cross(c)
            radius = radii[i]
            rx, ry = radius if isinstance(radius, tuple) else (radius, radius)
            v.extend(p+c*math.cos(TAU*j/sides)*rx+up*math.sin(TAU*j/sides)*ry for j in range(sides))
        f = []
        for i in range(len(points)-1):
            for j in range(sides):
                a=i*sides+j; b=i*sides+(j+1)%sides
                f.append((a,b,b+sides,a+sides))
        f.extend([tuple(reversed(range(sides))), tuple(range(len(v)-sides,len(v)))])
        self.patch(v,f,tile,weights)

    def leaf(self, root, tip, width, depth, tile=2, weights=None):
        root, tip = Vector(root), Vector(tip)
        d=(tip-root).normalized(); across=d.cross(Vector((0,1,0)))
        if across.length < .01: across=d.cross(Vector((1,0,0)))
        across.normalize(); normal=across.cross(d).normalized()
        v=[]
        for t,w in [(0,.16),(.23,.8),(.55,1),(.82,.68),(1,.015)]:
            c=root.lerp(tip,t)
            v += [c-across*width*w, c+normal*depth*math.sin(math.pi*t), c+across*width*w]
        f=[]
        for k in range(4):
            a=k*3
            f.extend([(a,a+3,a+4,a+1),(a+1,a+4,a+5,a+2)])
        # Separate back vertices preserve useful normals on both sides.
        count=len(v); v += [p-normal*.003 for p in v]
        self.patch(v,f+[tuple(i+count for i in reversed(x)) for x in f],tile,weights)

    def curve(self,points,radii,tile=0,weights=None,sides=12):
        points=list(map(Vector,points)); smooth=[]; sizes=[]
        for i in range(len(points)-1):
            p0=points[max(0,i-1)]; p1=points[i]; p2=points[i+1]; p3=points[min(len(points)-1,i+2)]
            for j in range(4):
                t=j/4
                smooth.append(.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t))
                sizes.append(radii[i]*(1-t)+radii[i+1]*t)
        self.tube(smooth+[points[-1]],sizes+[radii[-1]],tile,weights,sides)


def mesh_object(name,g):
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata([xyz(v) for v in g.v],[],g.f); mesh.update()
    obj=bpy.data.objects.new(name,mesh); bpy.context.scene.collection.objects.link(obj)
    return obj


def fuse_skin(g):
    obj=mesh_object('Continuous anatomical skin',g)
    bpy.context.view_layer.objects.active=obj; obj.select_set(True)
    mod=obj.modifiers.new('Fuse anatomical masses','REMESH'); mod.mode='VOXEL'
    mod.voxel_size=CFG['voxel_metres']; mod.use_smooth_shade=True
    bpy.ops.object.modifier_apply(modifier=mod.name)
    mod=obj.modifiers.new('Soften muscle transitions','SMOOTH'); mod.factor=1.2; mod.iterations=CFG['skin_smooth_iterations']
    bpy.ops.object.modifier_apply(modifier=mod.name)
    mod=obj.modifiers.new('Crowd skin resolution','DECIMATE'); mod.ratio=CFG['skin_decimate_ratio']
    bpy.ops.object.modifier_apply(modifier=mod.name)
    result=Geo(); result.v=[tuple(godot(v.co)) for v in obj.data.vertices]
    result.f=[tuple(p.vertices) for p in obj.data.polygons]
    result.tiles=[0]*len(result.f); result.weights=[{'body':1.0}]*len(result.v)
    bpy.data.objects.remove(obj,do_unlink=True)
    return result


def bone(name,at,parent='body',motion='',side=0,phase=0):
    return dict(name=name,pivot=list(at),parent=parent,motion=motion,side=side,phase=phase)


def quadruped(animal,seed):
    stag=animal=='stag'; boar=animal=='boar'
    y=1.30 if stag else .79 if boar else .77
    width=.31 if stag else .43 if boar else .245
    front=-.42; rear=.48
    head=Vector((0,2.00,-.78) if stag else (0,.71,-.86) if boar else (0,1.0,-.77))
    neck=Vector((0,1.65,-.53) if stag else (0,.96,-.46))
    jaw=head+Vector((0,-.10,-.04))
    bones=[bone('body',(0,y,0),''),bone('neck',neck),bone('head',head,'neck','head'),bone('jaw',jaw,'head','jaw')]
    tailroot=(0,y+.15,.72 if boar else .75)
    bones += [bone('tail',tailroot,'body','tail')]
    limbs=[]
    g=Geo()
    g.ellipsoid((0,y,.08),(width,.34 if boar else .30 if stag else .25,.72))
    g.ellipsoid((0,y+.05,front), (width*.94,.38 if not stag else .47,.35))
    g.ellipsoid((0,y+.03,rear), (width*.9,.31 if not stag else .37,.35))
    g.tube([(0,y,front),neck,head],[(width*.83,.26),(.21 if stag else .25,.27),(.17,.20)],sides=20)
    g.ellipsoid(head,(.15 if stag else .23 if boar else .172,.185 if not boar else .21,.255))
    muzzle=head+Vector((0,-.08,-.27 if boar else -.26))
    g.ellipsoid(muzzle,(.15 if boar else .105,.13 if boar else .092,.22 if boar else .24))
    for side in (-1,1):
        for is_rear,z in [(False,front),(True,rear)]:
            tag=('rear' if is_rear else 'front')+('_l' if side<0 else '_r')
            top=Vector((side*width*.78,y-.07,z))
            knee=Vector((side*width*.90,y*.52,z+(.17 if is_rear else .08)))
            ankle=Vector((side*width*.94,.17,z+(.08 if is_rear else -.08)))
            foot=Vector((ankle.x,.055,ankle.z-.07))
            phase=0 if (side<0)!=is_rear else 1
            bones.extend([bone(tag+'_upper',top,'body','upper',side,phase),bone(tag+'_lower',knee,tag+'_upper','lower',side,phase),bone(tag+'_foot',ankle,tag+'_lower','foot',side,phase)])
            bones[-1]['sole'] = list(foot+Vector((0,-.067,0)))
            limbs.append((tag,top,knee,ankle,foot))
            g.ellipsoid(top,(.16 if boar else .13,.30 if not stag else .38,.23 if is_rear else .17))
            r=.115 if boar else .075 if stag else .09
            g.tube([top,top.lerp(knee,.4),knee,ankle,foot],[r*1.4,r*1.35,r*.76,r*.50,r*.62],sides=16)
            g.ellipsoid(foot,(.095 if boar else .074,.065,.14 if not stag else .105))
    g=fuse_skin(g)
    skin_bvh=BVHTree.FromPolygons(g.v,g.f)
    def surface(x,z,raise_by=.008):
        hit=skin_bvh.ray_cast(Vector((x,4,z)),Vector((0,-1,0)))
        if hit[0] is not None and hit[0].y>y*.8:
            return hit[0]+hit[1]*raise_by
        return Vector((x,y+.12,z))
    def skin_weights(p):
        p=Vector(p)
        # Blend neck into chest and skull, then use the closest leg chain below it.
        if p.z<-.47 and p.y>y-.11:
            t=clamp((-.47-p.z)/.29)
            return {'neck':1-t,'head':t} if t<1 else {'head':1.}
        best=min(limbs,key=lambda l:abs(p.x-l[1].x)+abs(p.z-l[1].z))
        tag,top,knee,ankle,foot=best
        leg=clamp((y+.02-p.y)/.30)*clamp(abs(p.x)/(width*.60))
        if p.y>knee.y:
            lower=clamp((knee.y+.16-p.y)/.28)
            return {'body':1-leg,tag+'_upper':leg*(1-lower),tag+'_lower':leg*lower}
        f=clamp((ankle.y+.09-p.y)/.17)
        return {tag+'_lower':1-f,tag+'_foot':f}
    g.weights=[skin_weights(p) for p in g.v]
    # Distinct muzzle, eyes, nostrils, jaw, ears and paired hooves/paw digits.
    headw={'head':1.}; jaww={'jaw':1.}
    g.ellipsoid(head+Vector((0,-.145,-.19)),(.086 if not boar else .14,.040,.24),0,jaww)
    nose=muzzle+Vector((0,0,-.19 if boar else -.20))
    g.ellipsoid(nose,(.148 if boar else .078,.087 if boar else .043,.027),5,headw)
    for side in (-1,1):
        eye=head+Vector((side*(.120 if stag else .177 if boar else .137),.035,-.145))
        g.ellipsoid(eye,(.018,.018,.031),5,headw,16,8)
        g.ellipsoid(eye+Vector((side*.013,.001,-.007)),(.006,.010,.015),6,headw,12,8)
        # The eye sits in the skull. A separate spherical brow reads as a bump.
        if boar:
            g.ellipsoid(nose+Vector((side*.06,.006,-.031)),(.026,.033,.012),4,headw,12,8)
        earroot=head+Vector((side*.12,.12,.025))
        eartip=earroot+Vector((side*(.28 if stag else .10),.10 if stag else .23,.04))
        g.leaf(earroot,eartip,.092 if stag else .075,.025,0,headw)
        g.leaf(earroot+Vector((0,0,-.014)),eartip+Vector((0,-.025,-.02)),.046,.012,4,headw)
    for tag,top,knee,ankle,foot in limbs:
        fw={tag+'_foot':1.}
        if boar or stag:
            for side in (-1,1):g.ellipsoid(foot+Vector((side*.037,.005,-.034)),(.041,.072,.103),5,fw,12,8)
        else:
            for offset in (-.05,-.017,.017,.05):
                g.ellipsoid(foot+Vector((offset,-.012,-.055)),(.023,.04,.071),1,fw,12,8)
                g.tube([foot+Vector((offset,.007,-.102)),foot+Vector((offset,-.011,-.135))],[.009,.002],5,fw,6)
    rng=random.Random(seed)
    if boar:
        path=[tailroot,(.08,y+.18,.97),(.13,y+.09,1.02),(.09,y+.04,.96),(.05,y+.09,.94)]
        g.tube(path,[.035,.022,.018,.012,.005],1,{'tail':1.})
    elif stag:g.tube([tailroot,(0,y-.02,.91)],[.09,.02],1,{'tail':1.})
    else:g.tube([tailroot,(0,y+.10,1.03),(.03,y-.12,1.29),(.04,y-.30,1.45)],[.12,.115,.08,.01],0,{'tail':1.},14)
    # Broad grouped fur follows growth directions instead of random surface noise.
    for i in range(120 if not boar else 60):
        z=rng.uniform(-.44,.68); side=rng.choice((-1,1)); a=rng.uniform(.2,1.22)
        p=surface(side*width*.90*math.sin(a),z,.003)
        g.leaf(p,p+Vector((side*.018,-rng.uniform(.035,.07),rng.uniform(.05,.11))),.013,.006,0,skin_weights(p))
    # Cheek/neck ruff breaks the soft silhouette with grouped, downward fur.
    if not boar:
        for side in (-1,1):
            for i in range(25):
                p=head+Vector((side*(.14+rng.uniform(0,.02)),-.02-i*.009,.08+i*.007))
                g.leaf(p,p+Vector((side*.03,-.12,.06)),.016,.012,0,headw)
    if boar:
        # Overlapping saddle rows with actual flexion spaces around each shoulder.
        for row in range(6):
            z=-.55+row*.19
            for side in (-1,1):
                for col in range(3):
                    x=side*(.055+col*.105)
                    outline=[(-.070,-.055),(.050,-.068),(.090,-.02),(.095,.10),(.035,.19),(-.065,.14),(-.095,.05)]
                    verts=[surface(x+dx,z+dz,.012) for dx,dz in outline]
                    verts.append(surface(x,z+.045,.045))
                    faces=[(7,j,(j+1)%7) for j in range(7)]
                    g.patch(verts,faces,2)
                    if col==1:g.curve([verts[1],verts[2],verts[3]],[.004,.005,.003],3)
        for side in (-1,1):
            tusk=[jaw+Vector((side*.13,-.045,-.18)),jaw+Vector((side*.28,-.02,-.28)),jaw+Vector((side*.43,.09,-.29)),jaw+Vector((side*.49,.24,-.24))]
            g.curve(tusk,[.055,.044,.028,.003],7,jaww,14)
        for i in range(24):
            z=-.48+i*.05; at=(0,y+.38,z)
            g.leaf(at,(0,y+.43,z+.08),.008,.006,0)
    elif stag:
        # Exactly two root-attached antler beams, repeatable branches and open crown.
        for side in (-1,1):
            path=[head+Vector((side*.10,.17,.02)),head+Vector((side*.33,.34,.08)),head+Vector((side*.70,.54,.14)),head+Vector((side*.92,.78,.06)),head+Vector((side*.82,.98,-.10)),head+Vector((side*.61,1.07,-.21))]
            g.curve(path,[.057,.050,.040,.030,.020,.003],7,headw,14)
            for j in range(1,5):
                start=path[j]; inward=Vector((-side*(.20 if j<3 else .14),.30,-.15-.02*j))
                branch=[start,start+inward*.55+Vector((0,.045,.01)),start+inward]
                g.curve(branch,[.026,.016,.002],7,headw,12)
                if j<4:
                    sprout=branch[1]
                    g.curve([sprout,sprout+Vector((side*.06,.12,.07)),sprout+Vector((side*.055,.24,.04))],[.014,.009,.002],7,headw,10)
                g.tube([start+Vector((0,.015,-.026)),start+inward*.58],[.009,.003],3,headw,7)
            for j in range(1,4):
                at=path[j]
                g.tube([at,at+Vector((side*.03,-.14,.01)),at+Vector((side*.02,-.21,.025))],[.012,.007,.002],8,headw,6)
        for i in range(7):
            at=head.lerp(Vector((0,y+.30,-.15)),i/7)+Vector((0,.12,.10))
            for side in (-1,1):g.leaf(at+Vector((side*.05,0,0)),at+Vector((side*.25,-.10,.16)),.047,.025,2,{'neck':1.})
    else:
        for side in (-1,1):
            for i in range(5):
                at=head+Vector((side*.17,.04-i*.057,-.10+i*.025))
                tip=at+Vector((side*(.13+i*.006),.08,.24))
                g.leaf(at,tip,.042,.018,2,headw)
                g.tube([at,at.lerp(tip,.75)],[.006,.003],3,headw,6)
            for i in range(4):
                at=Vector((side*.14,y+.31,-.38+i*.085))
                g.leaf(at,at+Vector((side*.17,.07,.12)),.041,.018,2)
            g.tube([head+Vector((side*.16,-.14,.06)),neck+Vector((side*.19,.05,.09)),(side*.16,y+.34,-.22)],[.007,.006,.004],3,{'neck':.5,'head':.5})
    return g,bones


def moth(seed):
    g=Geo(); y=.88; head=(0,y+.015,-.19)
    bones=[bone('body',(0,y,0),''),bone('head',head,'body','head'),bone('abdomen',(0,y,.05),'body','tail')]
    g.ellipsoid((0,y,-.07),(.095,.095,.15),0)
    g.ellipsoid(head,(.075,.065,.075),0,{'head':1.})
    g.ellipsoid((0,y-.015,.16),(.076,.067,.20),3,{'abdomen':1.})
    for i in range(7):
        z=.04+i*.042; r=.073*(1-(i/8)**2)
        for side in (-1,1):
            g.tube([(side*r,y-.025,z),(side*r*.9,y+.040,z),(0,y+.061,z),(0,y+.061,z+.015)],[.010,.010,.008,.004],2,{'abdomen':1.},7)
    for side in (-1,1):
        suffix='_l' if side<0 else '_r'
        g.ellipsoid((side*.063,y+.013,-.22),(.030,.038,.035),5,{'head':1.},16,10)
        antenna=(side*.037,y+.06,-.23)
        name='antenna'+suffix; bones.append(bone(name,antenna,'head','antenna',side))
        path=[Vector(antenna),Vector((side*.08,y+.20,-.30)),Vector((side*.12,y+.30,-.34))]
        g.tube(path,[.009,.006,.002],7,{name:1.},7)
        for j in range(9):
            p=path[0].lerp(path[-1],(j+1)/11)
            for s in (-1,1):g.tube([p,p+Vector((s*.032*(1-j/12),.017,.012))],[.003,.001],1,{name:1.},5)
        for i in range(3):
            root=Vector((side*.06,y-.03,-.14+i*.08)); knee=root+Vector((side*.065,-.13,.035)); foot=knee+Vector((side*.035,-.11,-.055))
            n='leg'+str(i)+suffix; bones.extend([bone(n,root,'body','insect_leg',side,i%2),bone(n+'_tip',knee,n)])
            g.tube([root,knee],[.011,.008],1,{n:1.},7)
            g.tube([knee,foot,foot+Vector((0,.015,-.035))],[.008,.005,.0015],1,{n+'_tip':1.},7)
        for hind in (False,True):
            n=('hindwing' if hind else 'forewing')+suffix
            root=Vector((side*.055,y,.055 if hind else -.10))
            bones.append(bone(n,root,'body','hindwing' if hind else 'forewing',side))
            # Two distinct lobes/roots; wing surface is closed and visible underneath.
            outline=[(0,0),(.15,-.12),(.42,-.26),(.64,-.29),(.60,-.11),(.49,.05),(.31,.17),(.13,.14)] if not hind else [(0,0),(.17,.00),(.45,.05),(.48,.18),(.37,.32),(.22,.36),(.10,.22)]
            verts=[root]+[root+Vector((side*x,.025*math.sin(x*5),z)) for x,z in outline[1:]]
            centre=sum(verts,Vector())/len(verts); verts.append(centre)
            last=len(verts)-1; faces=[(last,j,(j+1)%last) for j in range(last)]
            count=len(verts); verts += [p-Vector((0,.003,0)) for p in verts]
            g.patch(verts,faces+[tuple(i+count for i in reversed(f)) for f in faces],0,{n:1.})
            for j in range(last):
                a=verts[j]; b=verts[(j+1)%last]
                g.tube([a,b],[.006,.004],2,{n:1.},6)
            for j in range(2,last):
                tip=verts[j]; mid=root.lerp(tip,.55)+Vector((0,.016,0))
                g.tube([root,mid,tip],[.006,.004,.0015],2,{n:1.},6)
                if j%2==0:
                    g.tube([root+Vector((0,.006,0)),mid+Vector((0,.006,0)),tip.lerp(mid,.3)],[.003,.002,.001],3,{n:1.},5)
                for k in (0.4,0.7):
                    p=root.lerp(tip,k); g.ellipsoid(p+Vector((0,.012,0)),(.011,.007,.014),3,{n:1.},8,6)
            for j in range(1,last-1):
                at=root.lerp(verts[j],.62)
                g.leaf(at,root.lerp(verts[j+1],.86),.033,.006,1,{n:1.})
    # Proboscis is one coiled mouthpart, clearly separate from six thoracic legs.
    points=[(0,y-.033,-.248)]+[(0,y-.089+.035*math.sin(t),-.267+.035*math.cos(t)) for t in [i*TAU/18 for i in range(20)]]
    g.tube(points,[.005]*len(points),5,{'head':1.},6)
    rng=random.Random(seed)
    for i in range(45):
        a=rng.uniform(0,TAU); z=rng.uniform(-.15,.01)
        p=Vector((.088*math.cos(a),y+.085*math.sin(a),z))
        g.leaf(p,p+Vector((.02*math.cos(a),.022*math.sin(a),.055)),.010,.006,1)
    return g,bones


def make_atlas(name,profile):
    size=CFG['atlas_pixels']; tile=size//4
    colours=[rgb(profile['coat']),rgb(profile['light']),rgb(profile['plate']),rgb(profile['accent']),(.07,.065,.055),(.12,.105,.086),(.53,.43,.22),(.68,.62,.48),(.29,.31,.20)]
    colours += [colours[0]]*(16-len(colours))
    pixels=[]; emission=[]; rough=[]; rng=random.Random(CFG['seed'])
    for yy in range(size):
        for xx in range(size):
            slot=(yy//tile)*4+xx//tile; x=xx%tile; y=yy%tile
            grain=rng.uniform(-.08,.08)
            if slot in (0,1): grain+=.015*math.sin(x*.9+math.sin(y*.15)*2)
            elif slot in (2,7): grain+=.035*math.sin(y*.35+x*.2)
            elif slot==3: grain*=.22
            c=tuple(clamp(v*(1+grain)) for v in colours[slot])
            pixels.extend((*c,1)); emission.extend((*(c if slot==3 else (0,0,0)),1))
            r=.34 if slot==5 else .58 if slot==3 else .84 if slot==2 else .94
            rough.extend((r,r,r,1))
    mat=bpy.data.materials.new(name+' skin, growth and buried light'); mat.use_nodes=True
    shader=mat.node_tree.nodes.get('Principled BSDF')
    for label,values,socket in [('albedo',pixels,'Base Color'),('emission',emission,'Emission Color'),('roughness',rough,'Roughness')]:
        im=bpy.data.images.new(name+'_'+label,width=size,height=size,alpha=True)
        im.colorspace_settings.name='Non-Color' if label=='roughness' else 'sRGB'
        im.pixels.foreach_set(values)
        # Reload the encoded PNG so Blender and glTF agree on sRGB decoding.
        path=OUT/(name+'_'+label+'.png'); im.filepath_raw=str(path); im.file_format='PNG'; im.save()
        bpy.data.images.remove(im); im=bpy.data.images.load(str(path))
        im.colorspace_settings.name='Non-Color' if label=='roughness' else 'sRGB'
        im.pack()
        node=mat.node_tree.nodes.new('ShaderNodeTexImage'); node.image=im
        mat.node_tree.links.new(node.outputs['Color'],shader.inputs[socket])
    shader.inputs['Emission Strength'].default_value=CFG['normal_emission_energy']
    return mat


def make_rig(name,g,bones,mat):
    obj=mesh_object(name+'_skin',g); obj.data.materials.append(mat)
    uv=obj.data.uv_layers.new(name='Material atlas')
    col=obj.data.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='CORNER')
    # Adding a colour attribute reallocates CustomData; reacquire the UV layer.
    uv=obj.data.uv_layers.get('Material atlas')
    for poly,slot in zip(obj.data.polygons,g.tiles):
        poly.use_smooth=True
        for loop in poly.loop_indices:
            p=godot(obj.data.vertices[obj.data.loops[loop].vertex_index].co)
            u=(p.z*2.1+p.x*.2)%1; v=(p.y*2.1+p.x*.3)%1
            uv.data[loop].uv=((slot%4+.08+.84*u)/4,(slot//4+.08+.84*v)/4)
            col.data[loop].color=(1,1,1,1)
    arm=bpy.data.armatures.new(name+'_anatomy'); rig=bpy.data.objects.new(name,arm)
    bpy.context.scene.collection.objects.link(rig)
    bpy.ops.object.select_all(action='DESELECT'); rig.select_set(True); bpy.context.view_layer.objects.active=rig
    bpy.ops.object.mode_set(mode='EDIT')
    for entry in bones:
        b=arm.edit_bones.new(entry['name']); b.head=xyz(entry['pivot']); b.tail=b.head+Vector((0,0,.10))
        if entry['parent']: b.parent=arm.edit_bones[entry['parent']]
    bpy.ops.object.mode_set(mode='OBJECT')
    obj.parent=rig
    for entry in bones:
        group=obj.vertex_groups.new(name=entry['name'])
        for i,weights in enumerate(g.weights):
            w=weights.get(entry['name'],0)
            if w>.00001: group.add([i],w,'REPLACE')
    mod=obj.modifiers.new('Articulated animal skin','ARMATURE'); mod.object=rig
    rig.show_in_front=True
    return rig,obj


def pose(rig,name,angles=(0,0,0),offset=(0,0,0)):
    pb=rig.pose.bones[name]; rest=pb.bone.matrix_local.to_quaternion()
    q=Quaternion(xyz((1,0,0)),angles[0])@Quaternion(xyz((0,1,0)),angles[1])@Quaternion(xyz((0,0,1)),angles[2])
    pb.rotation_mode='QUATERNION'; pb.rotation_quaternion=rest.inverted()@q@rest
    pb.location=rest.inverted()@xyz(offset)


def animation(rig,bones,animal,passive,role):
    rt=json.loads((ROOT/'data/tuning/combat_realtime.json').read_text())['behaviours'][role]
    clips={'idle':2.,'walk':1.}
    if not passive: clips.update(windup=rt['windup_seconds'],release=.22)
    rig.animation_data_create(); bpy.context.scene.render.fps=100
    m=CFG['motion']
    for clip,duration in clips.items():
        action=bpy.data.actions.new(rig.name+'__'+clip); rig.animation_data.action=action
        frames=round(duration*100)
        for frame in sorted(set(range(0,frames+1,5))|{frames}):
            t=frame/100; cycle=t/duration*TAU; effort=frame/frames if clip=='windup' else 1-frame/frames if clip=='release' else 0
            for entry in bones:
                a=[0.,0.,0.]; move=[0.,0.,0.]; mode=entry['motion']; wave=math.sin(cycle+entry['phase']*math.pi)
                if mode=='upper' and clip=='walk':a[0]=wave*.30
                if mode=='lower' and clip=='walk':a[0]=max(0,-wave)*m['knee_bend_radians']
                if mode=='foot' and clip=='walk':a[0]=-max(0,-wave)*m['ankle_bend_radians']
                if mode in ('forewing','hindwing'):
                    a[2]=entry['side']*(.17+math.sin(t*TAU*m['wing_hz']-(m['hindwing_lag_radians'] if mode=='hindwing' else 0))*m['wing_swing_radians'])
                if mode=='jaw':a[0]=-effort*m['jaw_open_radians']
                if mode=='tail':a[1]=math.sin(cycle)*m['tail_sway_radians']
                if mode=='antenna':a[2]=math.sin(cycle)*entry['side']*m['antenna_sway_radians']
                if entry['name']=='body':
                    move[1]=math.sin(cycle)*(.025 if animal=='moth' else .006)
                    if clip in ('windup','release'):a[0]=effort*(.13 if clip=='windup' else -.17)
                pose(rig,entry['name'],a,move)
                pb=rig.pose.bones[entry['name']]; pb.keyframe_insert('location',frame=frame); pb.keyframe_insert('rotation_quaternion',frame=frame)
        track=rig.animation_data.nla_tracks.new(); track.name=clip
        strip=track.strips.new(clip,0,action); strip.action_slot=rig.animation_data.action_slot; strip.extrapolation='NOTHING'
        track.mute=True; rig.animation_data.action=None
    for b in bones:pose(rig,b['name'])
    return clips


def aim(obj,point):obj.rotation_euler=(Vector(point)-obj.location).to_track_quat('-Z','Y').to_euler()


bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
assets={}; report={'study':'augmented_beasts','author':'Codex / local Blender authoring','assets':{}}
for index,(name,profile) in enumerate(CFG['families'].items()):
    print('AUTHORING '+name,flush=True)
    seed=CFG['seed']+index; animal=profile['animal']
    g,bones=moth(seed) if animal=='moth' else quadruped(animal,seed)
    # Keep family visuals at the authored world size: runtime adapter cancels only
    # the old presentation scale, never actor physics or the elite multiplier.
    mat=make_atlas(name,profile); rig,obj=make_rig(name,g,bones,mat)
    clips=animation(rig,bones,animal,ROWS[name]['behaviour']=='grazer',ROWS[name]['behaviour'])
    obj.data.calc_loop_triangles()
    assert all(math.isfinite(c) for v in g.v for c in v)
    assert all(abs(sum(w.values())-1)<1e-5 and len(w)<=4 for w in g.weights)
    triangles=len(obj.data.loop_triangles)
    assert triangles<50000,(name,triangles)
    bpy.ops.object.select_all(action='DESELECT'); rig.select_set(True); obj.select_set(True); bpy.context.view_layer.objects.active=rig
    for track in rig.animation_data.nla_tracks:track.mute=False
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_frame_range=False,export_anim_slide_to_zero=True,export_cameras=False,export_lights=False)
    for track in rig.animation_data.nla_tracks:track.mute=True
    for b in bones:pose(rig,b['name'])
    lo=[min(p[i] for p in g.v) for i in range(3)]; hi=[max(p[i] for p in g.v) for i in range(3)]
    scale=ROWS[name].get('size_scale',1.)*(.76 if animal=='moth' else 1.)
    report['assets'][name]={'role':ROWS[name]['behaviour'],'animal':animal,'concept':profile['concept'],'kind':profile['kind'],'rig_version':2,'rig':bones,'motion':CFG['motion'],'normal_emission_energy':CFG['normal_emission_energy'],'triangles':triangles,'applied_visual_scale':[scale]*3,'bone_pivots':[b['pivot'] for b in bones],'visual_bounds':[lo,hi],'clips':clips,'collision':{'kind':'capsule','radius':.35,'height':1.3,'centre':[0,.65,0],'source':'game/scenes/enemy.tscn'},'source':'art/blender/augmented-beasts-v01.blend','sha256':hashlib.sha256((OUT/(name+'.glb')).read_bytes()).hexdigest(),'geometry_sha256':hashlib.sha256(json.dumps([g.v,g.f,g.weights,g.tiles]).encode()).hexdigest(),'radial_overhang_m':max(0,max(math.hypot(p[0],p[2]) for p in g.v)-.35)}
    assets[name]=(rig,obj)
    # Temporarily hide each completed source while constructing the next animal.
    rig.hide_render=True; obj.hide_render=True; rig.hide_set(True); obj.hide_set(True)
    print('EXPORTED '+name+' '+str(triangles)+' triangles',flush=True)

scene=bpy.context.scene; scene.frame_set(0); scene.render.engine='CYCLES'; scene.cycles.samples=CFG['render_samples']; scene.cycles.use_denoising=True
scene.render.resolution_x,scene.render.resolution_y=CFG['render_pixels']; scene.render.resolution_percentage=100
scene.world.use_nodes=True; scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.16,.18,.20,1); scene.world.node_tree.nodes['Background'].inputs[1].default_value=.5
scene.view_settings.view_transform='AgX'
bpy.ops.mesh.primitive_plane_add(size=200); floor=bpy.context.object; floor.name='Review ground'; floor.location.z=-.04
floor_mat=bpy.data.materials.new('Warm neutral studio'); floor_mat.diffuse_color=(.19,.20,.18,1); floor.data.materials.append(floor_mat)
for name,at,power,size in [('Key',(-3,4,6),650,5),('Fill',(4,1,4),250,4),('Rim',(1,-4,5),900,3)]:
    data=bpy.data.lights.new(name,'AREA'); data.energy=power; data.shape='DISK'; data.size=size
    light=bpy.data.objects.new(name,data); scene.collection.objects.link(light); light.location=at; aim(light,(0,0,1))
cam=bpy.data.objects.new('Review camera',bpy.data.cameras.new('Review camera')); scene.collection.objects.link(cam); scene.camera=cam; cam.data.type='ORTHO'
display=[]
for name,(rig,obj) in assets.items():
    proxy=bpy.data.objects.new(name+' review',obj.data); scene.collection.objects.link(proxy); display.append(proxy)
    bounds=report['assets'][name]['visual_bounds']; height=bounds[1][1]; centre=Vector((0,height*.5,.14))
    if report['assets'][name]['animal']=='moth': centre=Vector((0,.88,0))
    cam.location=xyz((3.5,height*.7+1.3,-5.2)); aim(cam,xyz(centre)); cam.data.ortho_scale=2.15 if report['assets'][name]['animal']=='moth' else max(3.7 if height<1.5 else 0,height*1.82)
    scene.render.filepath=str(OUT/(name+'-blender.png')); bpy.ops.render.render(write_still=True)
    proxy.hide_render=True
    print('RENDERED '+name,flush=True)
# Source collection stores each rig at the origin; display gallery is spaced.
source=bpy.data.collections.new('SOURCE - isolate one animal to edit'); scene.collection.children.link(source)
for pair in assets.values():
    for obj in pair:
        obj.hide_set(False)
        for col in list(obj.users_collection):col.objects.unlink(obj)
        source.objects.link(obj); obj.hide_render=False
source.hide_render=True; source.hide_viewport=True
for i,proxy in enumerate(display):
    proxy.hide_render=False; proxy.location=xyz(((i%3-1)*2.9,0,(i//3)*3.1))
    # Raise only gallery moth copies so neither is obscured by the stag crown.
    if 'wisp' in proxy.name:proxy.location.z+=1.4
cam.location=xyz((6,5,-9)); aim(cam,xyz((0,1,1))); cam.data.ortho_scale=11
scene.render.filepath=str(OUT/'augmented-beasts-blender.png'); bpy.ops.render.render(write_still=True)
scene['authoring_notes']='Codex: selected animal concepts. SOURCE contains skinned world-metre assets; gallery copies are review only. No damage or gameplay event tracks.'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'augmented-beasts-v01.blend'),compress=True)
(OUT/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('AUGMENTED_BEASTS_OK '+str(OUT),flush=True)
