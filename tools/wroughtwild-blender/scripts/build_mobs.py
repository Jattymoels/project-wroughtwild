"""Rigged studies of the existing roster; no AI, hit events or combat changes.

Authored in Godot coordinates, then exported in actual world metres. Animation
uses the current six/eight-part convention; collision remains the original body.
"""
import hashlib
import json
import math
from pathlib import Path
import random
import re
import sys

import bpy
from mathutils import Vector, Quaternion

project, output = map(Path, sys.argv[sys.argv.index('--')+1:])
config = json.loads((Path(__file__).resolve().parents[1]/'mobs.json').read_text())
world = json.loads((project/'data/tuning/world.json').read_text())
trial = json.loads((project/'data/tuning/trial.json').read_text())
realtime = json.loads((project/'data/tuning/combat_realtime.json').read_text())
enemy_source = (project/'game/scripts/enemy.gd').read_text()
boss_source = (project/'game/scripts/boss.gd').read_text()
motion_source = (project/'game/art/creature_motion_tuning.gd').read_text()
assert '_mesh.scale *= 0.76' in enemy_source and '_mesh.scale *= 1.3' in enemy_source
assert '_mesh.scale = Vector3(1.9,1.87,1.9)' in boss_source
assert '_mesh.position.y = 0.0' in enemy_source and '_mesh.position.y = 0.0' in boss_source
roster = world['enemies']+[dict(trial['boss'],behaviour='boss')]
motion = {key:float(re.search(r'@export var '+key+r' := ([0-9.]+)',motion_source)[1]) for key in
          ('idle_metres','step_lift','release_seconds','windup_radians','strike_radians','lunge_metres','hover_metres')}
gaits = {key:(float(a),float(b)) for key,a,b in re.findall(r'"(beast|crawler|humanoid)":Vector2\(([0-9.]+),([0-9.]+)\)',motion_source)}
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.context.scene.render.fps = config['animation_fps']


def xyz(v):
    return Vector((v[0],-v[2],v[1]))


def linear(c):
    return c/12.92 if c <= .04045 else ((c+.055)/1.055)**2.4


def mix(a,b,t):
    return tuple(x+(y-x)*t for x,y in zip(a,b))


def shade(c,t):
    return tuple(min(1,max(0,x*t)) for x in c)


def family_colour(row):
    if row.get('tint'):
        text = row['tint'].lstrip('#')
        return tuple(int(text[i:i+2],16)/255 for i in (0,2,4))
    if row['behaviour']=='boss':
        source = re.search(r'_base_material.albedo_color = Color\(([^)]+)',boss_source)[1]
    else:
        match = re.search(r'"'+row['behaviour']+r'": _material.albedo_color = Color\(([^)]+)',enemy_source)
        source = match[1] if match else re.search(r'_: _material.albedo_color = Color\(([^)]+)',enemy_source)[1]
    return tuple(float(n) for n in source.split(','))


def capsule_contract(boss):
    path = 'game/scenes/boss.tscn' if boss else 'game/scenes/enemy.tscn'
    source = (project/path).read_text()
    body = re.search(r'\[sub_resource type="CapsuleShape3D"[^\]]*\]([^\[]+)',source)[1]
    return {'kind':'capsule','radius':float(re.search(r'radius = ([0-9.]+)',body)[1]),
            'height':float(re.search(r'height = ([0-9.]+)',body)[1]),
            'centre':[float(n) for n in re.search(r'position = Vector3\(([^)]+)',source)[1].split(',')],
            'source':path}


def pivots(role):
    p=[(0,.7,0),(0,1.32,0)]
    if role in ('fast','melee','grazer'):
        p[1]=(0,.91,-.27)
        p += [(x,.62,z) for x in (-.2,.2) for z in (-.26,.32)]
    elif role in ('swarm','lurker'):
        p[1]=(0,.57,-.3)
        p += [(s*.2,.64,z) for s in (-1,1) for z in (-.3,0,.3)]
    else:
        p += [point for s in (-1,1) for point in ((s*.3,1.14,0),(s*.13,.57,0))]
    return p


class Geometry:
    def __init__(self, seed, tint):
        self.rng=random.Random(seed)
        self.verts,self.faces,self.colours,self.bones=[],[],[],[]
        self.bone=0
        self.base=mix((.39,.38,.34),tint,config['family_colour_fraction'])
        self.dark=mix((.19,.18,.16),tint,.23)
        self.light=mix((.61,.60,.54),tint,.22)
        self.accent=mix((.51,.45,.30),tint,.72)
        self.metal=mix(config['armour_base_rgb'],tint,.14)
        self.edge=mix(config['armour_edge_rgb'],tint,.14)

    def face(self, points, colour, outward=None):
        points=list(map(Vector,points))
        if outward is not None and (points[1]-points[0]).cross(points[2]-points[0]).dot(Vector(outward))<0:
            points.reverse()
        start=len(self.verts)
        self.verts.extend(tuple(p) for p in points)
        self.faces.append(tuple(range(start,len(self.verts))))
        self.colours.append(shade(colour,1+self.rng.uniform(-config['surface_variation'],config['surface_variation'])))
        self.bones.extend([self.bone]*len(points))

    def oval(self, centre, size, colour, sides=None):
        sides=sides or config['radial_sides']
        centre=Vector(centre)
        rings=[]
        for i in range(1,config['body_rings']+1):
            theta=math.pi*i/(config['body_rings']+1)
            rings.append([centre+Vector((size[0]*.5*math.sin(theta)*math.cos(j*math.tau/sides),
                size[1]*.5*math.cos(theta),size[2]*.5*math.sin(theta)*math.sin(j*math.tau/sides))) for j in range(sides)])
        for i in range(len(rings)-1):
            for j in range(sides):
                points=[rings[i][j],rings[i][(j+1)%sides],rings[i+1][(j+1)%sides],rings[i+1][j]]
                self.face(points,colour,sum(points,Vector())/4-centre)
        for ring,sign in ((rings[0],1),(rings[-1],-1)):
            pole=centre+Vector((0,size[1]*.5*sign,0))
            for j in range(sides):
                self.face([pole,ring[j],ring[(j+1)%sides]],colour,(0,sign,0))

    def tube(self, points, radii, colour, sides=7):
        points=list(map(Vector,points))
        rings=[]
        previous=None
        for i,(p,r) in enumerate(zip(points,radii)):
            direction=(points[min(i+1,len(points)-1)]-points[max(0,i-1)]).normalized()
            cross=previous-direction*previous.dot(direction) if previous is not None else direction.cross(Vector((0,1,0)))
            if cross.length<.01:
                cross=direction.cross(Vector((1,0,0)))
            cross.normalize()
            previous=cross
            up=direction.cross(cross)
            rings.append([p+(cross*math.cos(j*math.tau/sides)+up*math.sin(j*math.tau/sides))*r for j in range(sides)])
        for i in range(len(rings)-1):
            for j in range(sides):
                points_face=[rings[i][j],rings[i][(j+1)%sides],rings[i+1][(j+1)%sides],rings[i+1][j]]
                self.face(points_face,colour,sum(points_face,Vector())/4-(points[i]+points[i+1])/2)
        self.face(rings[0],shade(colour,.8),points[0]-points[1])
        self.face(rings[-1],colour,points[-1]-points[-2])

    def box(self, centre, size, colour, chamfer=.12, taper=1.):
        # Eight-sided horizontal outline gives armour/boards readable bevels.
        x,y,z=size
        outline=[(-.5+chamfer,-.5),(.5-chamfer,-.5),(.5,-.5+chamfer),(.5,.5-chamfer),
                 (.5-chamfer,.5),(-.5+chamfer,.5),(-.5,.5-chamfer),(-.5,-.5+chamfer)]
        c=Vector(centre)
        rings=[[c+Vector((a*x*(taper if s>0 else 1),s*y/2,b*z)) for a,b in outline] for s in (-1,1)]
        for j in range(8):
            points=[rings[0][j],rings[0][(j+1)%8],rings[1][(j+1)%8],rings[1][j]]
            self.face(points,colour,sum(points,Vector())/4-c)
        self.face(rings[0],shade(colour,.8),(0,-1,0))
        self.face(rings[1],shade(colour,1.08),(0,1,0))


def beast(g,role):
    elk=role=='grazer'
    hound=role=='fast'
    g.oval((0,.70,.03),(.48 if hound else .58,.54,.98 if hound else .87),g.base)
    g.oval((0,.76,-.24),(.48,.62,.41),g.base)
    g.tube([(0,.80,.39),(0,.87,.62),(0,.75,.85)], [.075,.05,.012],g.dark)
    for i in range(5):
        g.box((0,.94+i*.012,-.27+i*.13),(.28,.065,.18),g.dark)
    for side in (-1,1):
        for front,z in enumerate((-.26,.32)):
            g.bone=2+(2 if side>0 else 0)+front
            hip=(side*.2,.62,z)
            knee=(side*.225,.32,z+(.10 if front else -.055))
            foot=(side*.24,.07,z-.025)
            g.oval(hip,(.22,.32,.27),g.base)
            g.tube([hip,knee,foot],[.085,.057,.035],g.dark)
            g.box((foot[0],.055,foot[2]-.025),(.10,.11,.17),g.dark)
    g.bone=1
    g.oval((0,1.00,-.35),(.33,.40,.35),g.base)
    g.oval((0,.91,-.56),(.25,.23,.43 if hound else .33),g.light)
    g.box((0,.87,-.68),(.18,.07,.17),g.dark)
    for side in (-1,1):
        g.oval((side*.144,1.065,-.48),(.035,.033,.042),g.accent)
        g.tube([(side*.12,1.13,-.33),(side*.19,1.29,-.24)],[.071,.005],g.dark)
        if elk:
            g.tube([(side*.105,1.15,-.28),(side*.20,1.43,-.20),(side*.31,1.61,-.16)], [.028,.024,.004],g.light)
            for y,z,reach in ((1.36,-.21,.31),(1.48,-.18,.39)):
                g.tube([(side*(.18 if y<1.4 else .24),y,z),(side*reach,y+.09,z-.16)], [.019,.004],g.light)
        elif not hound:
            g.box((side*.13,1.11,-.40),(.12,.08,.20),g.accent)


def crawler(g,role):
    g.oval((0,.62,.02),(.63,.55,.91),g.dark)
    for i in range(5):
        g.oval((0,.75,-.29+i*.16),(.63-i*.035,.32,.28),g.base)
        g.tube([(0,.86,-.29+i*.16),(0,1.01,-.22+i*.16)],[.065,.005],g.accent)
    for side in (-1,1):
        for index,z in enumerate((-.3,0,.3)):
            g.bone=2+(3 if side>0 else 0)+index
            knee=(side*.52,.43,z+.04)
            g.tube([(side*.2,.64,z),knee,(side*.56,.06,z+.22)], [.075,.06,.013],g.base)
            g.oval(knee,(.15,.15,.18),g.dark)
    g.bone=1
    g.oval((0,.56,-.46),(.38,.27,.34),g.light)
    for side in (-1,1):
        g.tube([(side*.13,.53,-.55),(side*.19,.40,-.70),(side*.07,.41,-.76)],[.046,.032,.005],g.dark)
        for x in (.07,.135):
            g.oval((side*x,.64,-.575),(.035,.034,.035),g.accent)


def wisp(g):
    g.oval((0,.88,0),(.26,.52,.24),g.light)
    g.bone=1
    g.oval((0,.90,-.12),(.16,.25,.12),g.accent)
    for i in range(4):
        angle=i*math.tau/4+.4
        g.bone=2+i
        at=(math.cos(angle)*.24,.86+math.sin(angle)*.08,math.sin(angle)*.24)
        g.oval(at,(.13,.39,.13),g.dark,6)
    g.bone=0
    g.tube([(0,.64,0),(.04,.47,.02),(0,.35,.03)],[.075,.043,.005],g.accent)


def humanoid(g,role):
    armoured=role in ('guard','knight','boss')
    g.oval((0,1.02,0),(.51,.60,.32),g.base)
    g.box((0,.80,0),(.48,.07,.33),g.dark)
    for side in (-1,1):
        g.box((side*.14,.62,0),(.25,.30,.36),g.dark)
        g.bone=3 if side<0 else 5
        g.tube([(side*.13,.57,0),(side*.145,.32,.02),(side*.15,.13,-.025)],[.103,.075,.065],g.dark)
        g.box((side*.15,.085,-.065),(.18,.17,.31),g.dark)
        g.bone=2 if side<0 else 4
        shoulder=(side*.3,1.14,0)
        hand=(side*.36,.75,-.13)
        if role=='ranged':
            hand=(side*.32,1.00,-.28) if side<0 else (.13,1.06,-.17)
        g.oval(shoulder,(.28,.25,.35),g.light if armoured else g.base)
        g.tube([shoulder,(side*.38,.92,-.04),hand],[.105,.075,.06],g.base)
        g.oval(hand,(.12,.15,.12),g.dark)
        if armoured:
            g.box((side*.30,1.225,0),(.31,.11,.38),g.metal,taper=.72)
    g.bone=0
    g.tube([(-.17,1.22,-.175),(.16,.82,-.175)],[.025,.025],g.dark)
    g.bone=1
    g.oval((0,1.48,0),(.35,.43,.34),g.base)
    g.oval((0,1.48,-.145),(.235,.28,.075),g.dark)
    for side in (-1,1):
        g.box((side*.06,1.51,-.184),(.043,.018,.012),g.accent)
    if role=='ranged':
        g.bone=2
        g.tube([(-.34,.67,-.29),(-.43,.86,-.33),(-.45,1.1,-.35),(-.40,1.34,-.32),(-.30,1.48,-.28)], [.015,.022,.025,.022,.012],g.light)
        g.tube([(-.34,.67,-.29),(-.30,1.48,-.28)],[.003,.003],g.dark,4)
        g.bone=0
        g.box((.14,1.08,.19),(.14,.42,.14),g.dark)
        for x in (.09,.15,.20):
            g.tube([(x,1.05,.19),(x,1.43,.20)],[.006,.006],g.light,4)
    if role=='shrieker':
        g.bone=1
        g.tube([(0,1.39,-.12),(0,1.37,-.32),(0,1.41,-.46)],[.075,.11,.17],g.accent,8)
        g.oval((0,1.41,-.471),(.25,.25,.014),g.dark,8)
        for side in (-1,1):
            g.tube([(side*.13,1.59,0),(side*.23,1.72,.07)],[.035,.006],g.light)
    if armoured:
        g.bone=0
        g.box((0,1.09,-.15),(.38,.39,.14),g.metal,taper=1.18)
        for y in (.91,1.05,1.2):
            g.box((0,y,-.229),(.36,.027,.018),g.dark)
        g.bone=1
        g.box((0,1.45,-.14),(.28,.29,.095),g.edge,taper=.82 if role=='guard' else 1.)
        g.box((0,1.51,-.193),(.22,.024,.016),g.dark)
        g.bone=2
        g.box((-.40,.87,-.24),(.41,.74 if role!='knight' else .9,.14),g.edge,taper=1. if role=='guard' else 1.15)
        g.box((-.40,.88,-.318),(.31,.52,.03),g.metal)
        g.oval((-.40,.92,-.348),(.11,.11,.06),g.accent)
        g.bone=4
        if role=='boss':
            for x in (.30,.37,.44):
                g.tube([(x,.75,-.16),(x,.58,-.23),(x,.54,-.39)],[.034,.027,.005],g.edge)
        else:
            g.tube([(.39,.53,-.15),(.39,1.08,-.15)],[.023,.023],g.dark)
            if role=='knight':
                g.tube([(.39,.79,-.15),(.39,1.12,-.15),(.39,1.31,-.15)],[.035,.028,.002],g.edge,4)
                g.box((.39,.79,-.15),(.16,.035,.07),g.metal)
            else:
                g.box((.39,1.01,-.15),(.13,.23,.14),g.edge)
    if role=='boss':
        g.bone=1
        for side in (-1,1):
            g.tube([(side*.12,1.60,0),(side*.27,1.79,.05),(side*.31,1.84,-.06)],[.065,.04,.004],g.light)
        g.bone=0
        g.box((0,1.08,-.233),(.07,.29,.025),g.accent)


def build_geometry(role,seed,tint):
    g=Geometry(seed,tint)
    if role in ('melee','fast','grazer'):
        beast(g,role)
    elif role in ('swarm','lurker'):
        crawler(g,role)
    elif role=='skirmisher':
        wisp(g)
    else:
        humanoid(g,role)
    return g


def make_rig(name,g,scale,points):
    mesh=bpy.data.meshes.new(name+' mesh')
    mesh.from_pydata([xyz(Vector(p)*scale) for p in g.verts],[],g.faces)
    mesh.update()
    colours=mesh.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='CORNER')
    for polygon,rgb in zip(mesh.polygons,g.colours):
        for loop in polygon.loop_indices:
            colours.data[loop].color=tuple(linear(c) for c in rgb)+(1,)
    mat=bpy.data.materials.new(name+' one status surface')
    mat.use_nodes=True
    shader=mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Roughness'].default_value=config['roughness']
    node=mat.node_tree.nodes.new('ShaderNodeVertexColor')
    node.layer_name='Color'
    mat.node_tree.links.new(node.outputs['Color'],shader.inputs['Base Color'])
    mesh.materials.append(mat)
    obj=bpy.data.objects.new(name+'_mesh',mesh)
    bpy.context.scene.collection.objects.link(obj)
    arm=bpy.data.armatures.new(name+' skeleton')
    rig=bpy.data.objects.new(name,arm)
    bpy.context.scene.collection.objects.link(rig)
    bpy.ops.object.select_all(action='DESELECT')
    rig.select_set(True)
    bpy.context.view_layer.objects.active=rig
    bpy.ops.object.mode_set(mode='EDIT')
    for i,p in enumerate(points):
        bone=arm.edit_bones.new('body' if i==0 else 'part_'+str(i))
        bone.head=xyz(Vector(p)*scale)
        bone.tail=bone.head+xyz(Vector((0,.12,0))*scale)
        if i:
            bone.parent=arm.edit_bones['body']
    bpy.ops.object.mode_set(mode='OBJECT')
    obj.parent=rig
    for i,bone in enumerate(arm.bones):
        group=obj.vertex_groups.new(name=bone.name)
        indices=[j for j,value in enumerate(g.bones) if value==i]
        if indices:
            group.add(indices,1.,'REPLACE')
    mod=obj.modifiers.new('Current part skin','ARMATURE')
    mod.object=rig
    return rig,obj


def pose(rig,index,angles=(0,0,0),offset=(0,0,0)):
    bone=rig.pose.bones['body' if index==0 else 'part_'+str(index)]
    rest=bone.bone.matrix_local.to_quaternion()
    q=Quaternion(xyz((1,0,0)),angles[0]) @ Quaternion(xyz((0,1,0)),angles[1]) @ Quaternion(xyz((0,0,1)),angles[2])
    bone.rotation_mode='QUATERNION'
    bone.rotation_quaternion=rest.inverted() @ q @ rest
    bone.location=rest.inverted() @ xyz(offset)


def animate(rig,role,scale,clips):
    rig.animation_data_create()
    fps=config['animation_fps']
    for clip,seconds in clips.items():
        action=bpy.data.actions.new(rig.name+'__'+clip)
        rig.animation_data.action=action
        frames=round(seconds*fps)
        for frame in sorted(set([0,frames]+list(range(0,frames+1,5)))):
            t=frame/max(1,frames)
            for i in range(len(rig.pose.bones)):
                pose(rig,i)
            if clip=='idle':
                amount=motion['hover_metres'] if role=='skirmisher' else motion['idle_metres']
                pose(rig,0,(0,math.sin(t*math.tau)*.05,0),(0,math.sin(t*math.tau)*amount*scale.y,0))
            elif clip=='walk':
                gait='beast' if role in ('fast','melee','grazer') else ('crawler' if role in ('swarm','lurker') else 'humanoid')
                swing=math.sin(t*math.tau)*math.radians(gaits[gait][1])
                pose(rig,0,(0,0,math.sin(t*math.tau)*.025),(0,abs(math.sin(t*math.tau))*motion['step_lift']*scale.y,0))
                for i in range(2,len(rig.pose.bones)):
                    sign=1 if i in (2,5) else -1
                    if gait=='crawler':
                        pose(rig,i,(0,swing*(-1 if i%2 else 1),0))
                    else:
                        pose(rig,i,(swing*sign*(.65 if gait=='humanoid' and i%2==0 else 1),0,0))
                if role=='skirmisher':
                    pose(rig,0,(0,math.sin(t*math.tau)*.16,0),(0,math.sin(t*math.tau)*motion['hover_metres']*scale.y,0))
            else:
                weight=t if clip in ('windup','inhale') else 1-t
                sign=1 if clip in ('windup','inhale') else -1
                lean=weight*(motion['windup_radians'] if sign>0 else motion['strike_radians'])*sign
                pose(rig,0,(lean,0,0),(0,0,weight*motion['lunge_metres']*scale.z*(.35 if sign>0 else -1)))
                pose(rig,1,(weight*(.2 if sign>0 else -.3),0,0))
                if role not in ('melee','fast','grazer','swarm','lurker','skirmisher'):
                    pose(rig,2,(-weight*.3,0,-weight*.35 if clip=='inhale' else 0))
                    pose(rig,4,(-weight*1.05 if sign>0 else weight*.55,weight*.25,weight*.35 if clip=='inhale' else 0))
            for bone in rig.pose.bones:
                bone.keyframe_insert('location',frame=frame,group=bone.name)
                bone.keyframe_insert('rotation_quaternion',frame=frame,group=bone.name)
        track=rig.animation_data.nla_tracks.new()
        track.name=clip
        strip=track.strips.new(clip,0,action)
        strip.action_slot=rig.animation_data.action_slot
        strip.extrapolation='NOTHING'
        track.mute=True
        rig.animation_data.action=None
    for i in range(len(rig.pose.bones)):
        pose(rig,i)


def export(path,objects,animated=False):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,
        export_apply=False,export_cameras=False,export_lights=False,export_animations=animated,
        export_animation_mode='NLA_TRACKS',export_frame_range=False,export_anim_slide_to_zero=True)


assets={}
report={'study':'mobs','seed':config['seed'],'assets':{},'status':'isolated art/rig study; original AI, combat clocks, damage and capsules unchanged'}
for index,row in enumerate(roster):
    name,role=row['id'],row['behaviour']
    scale=Vector((1.9,1.87,1.9)) if role=='boss' else Vector((1,1,1))*row.get('size_scale',1.)*(.76 if role not in ('fast','melee','swarm','lurker','grazer') else 1.)
    seed=config['seed']+index*7919
    g=build_geometry(role,seed,family_colour(row))
    twin=build_geometry(role,seed,family_colour(row))
    payload=[g.verts,g.faces,g.colours,g.bones]
    assert payload==[twin.verts,twin.faces,twin.colours,twin.bones],name
    rig,obj=make_rig(name,g,scale,pivots(role))
    obj.data.calc_loop_triangles()
    assert all(t.area>1e-12 for t in obj.data.loop_triangles),name+' degenerate face'
    assert all(math.isfinite(c) for v in obj.data.vertices for c in v.co),name
    points=[Vector(p)*scale for p in g.verts]
    bounds=[[min(v[i] for v in points) for i in range(3)],[max(v[i] for v in points) for i in range(3)]]
    rules=realtime['boss'] if role=='boss' else realtime['behaviours'][role]
    clips={'idle':config['idle_cycle_seconds'],'walk':config['walk_cycle_seconds']}
    if not rules.get('flees',False):
        clips.update(windup=rules['claw_windup_seconds'] if role=='boss' else rules['windup_seconds'],release=motion['release_seconds'])
    if role=='boss':
        clips['inhale']=rules['breath_telegraph_seconds']
    animate(rig,role,scale,clips)
    # Export each selected rig's own NLA tracks; never broadcast compatible
    # actions across the other eleven creatures with the same bone names.
    for track in rig.animation_data.nla_tracks:
        track.mute=False
    export(output/(name+'.glb'),[rig,obj],True)
    for track in rig.animation_data.nla_tracks:
        track.mute=True
    for i in range(len(rig.pose.bones)):
        pose(rig,i)
    capsule=capsule_contract(role=='boss')
    # Primitive shape restored by the Godot post-import script; the GLB proxy
    # is a visual envelope, never a fitted convex substitute for the capsule.
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,radius=capsule['radius'],location=xyz(capsule['centre']))
    proxy=bpy.context.object
    for vertex in proxy.data.vertices:
        vertex.co.z += (capsule['height']/2-capsule['radius'])*(1 if vertex.co.z>=0 else -1)
    proxy.name=name+'-convcolonly'
    export(output/(name+'_collision.glb'),[proxy])
    bpy.data.objects.remove(proxy,do_unlink=True)
    radius=max(math.hypot(p.x,p.z) for p in points)
    report['assets'][name]={'display_name':row['display_name'],'role':role,'passive':rules.get('flees',False),
        'visual_bounds':bounds,'triangles':len(obj.data.loop_triangles),'mesh_parts':1,'materials':1,
        'bones':['body']+['part_'+str(i) for i in range(1,len(pivots(role)))],
        'bone_pivots':[list(Vector(p)*scale) for p in pivots(role)],'clips':clips,'collision':capsule,
        'applied_visual_scale':list(scale),'elite_visual_scale_only':1.3,'horizontal_radius':radius,
        'radial_overhang_m':max(0,radius-capsule['radius']),
        'empty_height_above_visual_m':max(0,capsule['height']-bounds[1][1]),
        'geometry_sha256':hashlib.sha256(json.dumps(payload).encode()).hexdigest(),
        'attack_range_m':rules.get('attack_range_m',rules.get('claw_range_m',0)),
        'projectile':rules.get('projectile'),'forward_axis':'-Z'}
    assets[name]=(rig,obj)
    print('MOB_EXPORTED '+name,flush=True)

source=bpy.data.collections.new('SOURCE - world metre rigs; original capsules separate')
bpy.context.scene.collection.children.link(source)
for pair in assets.values():
    for obj in pair:
        for collection in list(obj.users_collection):
            collection.objects.unlink(obj)
        source.objects.link(obj)
source.hide_render,source.hide_viewport=True,True


def aim(obj,point):
    obj.rotation_euler=(Vector(point)-obj.location).to_track_quat('-Z','Y').to_euler()


display=[]
def display_set(names):
    for obj in display:
        bpy.data.objects.remove(obj,do_unlink=True)
    display.clear()
    for index,name in enumerate(names):
        # Display copies use rest mesh data; editable skinned sources stay intact.
        obj=bpy.data.objects.new(name+' display',assets[name][1].data)
        bpy.context.scene.collection.objects.link(obj)
        obj.location=xyz(((index%3-1)*2.4,0,(index//3)*2.5))
        display.append(obj)


scene=bpy.context.scene
scene.frame_set(0)
scene.render.engine='CYCLES'
scene.cycles.samples=32
scene.cycles.use_denoising=True
scene.render.resolution_x,scene.render.resolution_y=2000,1300
scene.render.resolution_percentage=100
scene.world.color=(.20,.21,.20)
scene.view_settings.view_transform='AgX'
bpy.ops.mesh.primitive_plane_add(size=200)
floor=bpy.context.object
floor.name='Review floor - not exported'
floor.location.z=-.012
mat=bpy.data.materials.new('Neutral review ground')
mat.diffuse_color=(.15,.17,.15,1)
floor.data.materials.append(mat)
for name,location,power,size in [('Soft daylight',(-4,5,7),1750,6),('Sky fill',(4,-2,6),1300,5)]:
    light=bpy.data.lights.new(name,'AREA')
    light.energy,light.shape,light.size=power,'DISK',size
    obj=bpy.data.objects.new(name,light)
    scene.collection.objects.link(obj)
    obj.location=location
    aim(obj,(0,-1,.7))
camera=bpy.data.objects.new('Mob review camera',bpy.data.cameras.new('Mob review camera'))
scene.collection.objects.link(camera)
camera.location=(5,10,7)
aim(camera,xyz((0,.65,1.5)))
camera.data.type,camera.data.ortho_scale='ORTHO',10.4
scene.camera=camera
display_set(['ember_whelp','ash_hound','gloom_crawler','bog_lurker','valley_elk','marsh_wisp','cinder_wisp'])
scene.render.filepath=str(output/'mobs-beasts.png')
bpy.ops.render.render(write_still=True)
display_set(['cinder_archer','stone_husk','shrieker','hollow_knight','forge_tyrant'])
camera.location=(5,10,7)
aim(camera,xyz((0,1.1,1.25)))
scene.render.filepath=str(output/'mobs-humanoids.png')
bpy.ops.wm.save_as_mainfile(filepath=str(output/'mobs-study.blend'))
bpy.ops.render.render(write_still=True)
(output/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('WROUGHTWILD_MOBS_OK '+str(output))
