"""Build one skinned ram from the selected ART-06C source, without shared wiring.
Blender --background --python build_ram.py -- INPUT NEW_SOURCE RUNTIME_OUTPUT
"""
import json, math, shutil, sys
from pathlib import Path
import bpy
import numpy as np
from mathutils import Matrix, Vector
repo=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(repo/'tools/wroughtwild-fauna'))
from smooth_weights import smooth_fitted_weights

source, output, runtime=[Path(v).resolve() for v in sys.argv[sys.argv.index('--')+1:]]
assert not output.exists(), 'Author a new source version; preserve prior masters.'
output.mkdir(parents=True)
runtime.mkdir(parents=True,exist_ok=True)
cfg=json.loads((Path(__file__).parent/'rig.json').read_text(encoding='utf-8-sig'))
bpy.ops.wm.open_mainfile(filepath=str(source/'stone_husk-surface.blend'))
scene=bpy.context.scene
host=bpy.data.objects['stone_husk - surface host']
host.hide_set(False)
bpy.ops.object.select_all(action='DESELECT')
mesh=host.copy();mesh.data=host.data.copy();mesh.name='RamSkin'
scene.collection.objects.link(mesh)
mesh.select_set(True);bpy.context.view_layer.objects.active=mesh
mod=mesh.modifiers.new('Weld identical UV seam positions','WELD');mod.merge_threshold=1e-6
bpy.ops.object.modifier_apply(modifier=mod.name)
welded=len(mesh.data.vertices)
mod=mesh.modifiers.new('Single runtime detail','DECIMATE')
mod.ratio=cfg['target_triangles']/len(mesh.data.polygons);mod.use_collapse_triangulate=True
bpy.ops.object.modifier_apply(modifier=mod.name)
validation_changed=mesh.data.validate(verbose=True)
mesh.data.calc_loop_triangles()
assert len(mesh.data.uv_layers)==1
host.hide_render=True;host.hide_set(True);host.select_set(False)
p=np.array([v.co[:] for v in mesh.data.vertices])
B=cfg['body'];bones=[]
def bone(name,head,tail,parent=None):
    bones.append(dict(name=name,head=head,tail=tail,parent=parent))
bone('root',[0,0,0],[0,0,.18])
bone('pelvis',B['pelvis'],B['spine'],'root')
bone('spine',B['spine'],B['chest'],'pelvis')
bone('chest',B['chest'],B['neck'],'spine')
bone('neck',B['neck'],B['head'],'chest')
bone('head',B['head'],B['muzzle'],'neck')
bone('tail',B['tail_root'],B['tail_tip'],'pelvis')
for leg in cfg['legs']:
    n=leg['name']
    q=p[(p[:,0]*leg['side']>.06)&(p[:,2]<.085)&((p[:,1]<-.1) if leg['front'] else (p[:,1]>.3))]
    assert len(q)>10,('Missing hoof',n)
    leg['sole']=float(q[:,2].min())
    bone(n+'_upper',leg['hip'],leg['knee'],'chest' if leg['front'] else 'pelvis')
    bone(n+'_lower',leg['knee'],leg['hock'],n+'_upper')
    bone(n+'_pastern',leg['hock'],leg['ankle'],n+'_lower')
    bone(n+'_hoof',leg['ankle'],[leg['ankle'][0],leg['ankle'][1]-.11,leg['ankle'][2]],n+'_pastern')
arm=bpy.data.objects.new('RamRig',bpy.data.armatures.new('RamAnatomy'))
scene.collection.objects.link(arm);arm.select_set(True);bpy.context.view_layer.objects.active=arm
bpy.ops.object.mode_set(mode='EDIT')
for b in bones:
    e=arm.data.edit_bones.new(b['name']);e.head=b['head'];e.tail=b['tail']
    if b['parent']:e.parent=arm.data.edit_bones[b['parent']]
bpy.ops.object.mode_set(mode='OBJECT');arm.show_in_front=True
groups={b['name']:mesh.vertex_groups.new(name=b['name']) for b in bones}
def smooth(v):
    v=max(0,min(1,v));return v*v*(3-2*v)
# Head, ears and both horn curls share a rigid skull. The low neck transitions
# through connected skin; no horn-waving bones or independent effect meshes.
rigid=np.zeros(len(p),dtype=bool)
for i,(x,y,z) in enumerate(p):
    head=max(smooth((z-1.24)/.19)*smooth((.05-y)/.18),smooth((-y-.60)/.15)*smooth((z-1.20)/.12))
    horn_anchor=(abs(x)>.235 and z>1.28 and y<-.17) or (y<-.64 and z>1.25)
    if horn_anchor:head=1
    neck=smooth((-y-.16)/.30)*smooth((z-.94)/.30)*(1-head)
    chest=smooth((.22-y)/.48)*(1-head-neck)
    spine=(1-smooth((y-.10)/.48))*(1-head-neck-chest)
    w={'head':head,'neck':neck,'chest':chest,'spine':spine,
       'pelvis':max(0,1-head-neck-chest-spine)}
    tail=smooth((y-.79)/.09)*smooth((z-.83)/.19)
    if tail:
        w={k:v*(1-tail) for k,v in w.items()};w['tail']=tail
    leg=min(cfg['legs'],key=lambda l:(x-l['ankle'][0])**2+(y-l['ankle'][1])**2)
    n=leg['name'];a=np.array(leg['ankle']);h=np.array(leg['hock']);k=np.array(leg['knee']);hip=np.array(leg['hip'])
    cx=np.interp(z,[a[2],h[2],k[2],hip[2]],[a[0],h[0],k[0],hip[0]])
    cy=np.interp(z,[a[2],h[2],k[2],hip[2]],[a[1],h[1],k[1],hip[1]])
    radius=math.hypot(x-cx,y-cy)
    limb=smooth((hip[2]+.03-z)/.26)*(1-smooth((radius-.11)/.13))
    limb*=1-tail
    if limb>0:
        hoof=1-smooth((z-.105)/.085)
        upper=smooth((z-k[2]+.075)/.15)*(1-hoof)
        lower=smooth((z-h[2]+.07)/.14)*(1-hoof-upper)
        pastern=max(0,1-hoof-upper-lower)
        w={key:value*(1-limb) for key,value in w.items()}
        for part,value in [('hoof',hoof),('upper',upper),('lower',lower),('pastern',pastern)]:
            w[n+'_'+part]=limb*value
    if z<.09 and radius<.20:w={n+'_hoof':1}
    if head>.999:
        w={'head':1};rigid[i]=True
    keep=sorted([(k,v) for k,v in w.items() if v>1e-7],key=lambda v:-v[1])[:4]
    total=sum(v for k,v in keep);assert total>0
    for key,value in keep:groups[key].add([i],float(value/total),'REPLACE')
# Keep the quiet rear torso independent of head/neck weight diffusion.
back_anchor=(p[:,1]>.18)&(p[:,2]>.90)
smooth_fitted_weights(mesh,rigid|back_anchor,cfg['weight_smoothing_passes'])
mesh.parent=arm;mod=mesh.modifiers.new('Fitted anatomy','ARMATURE');mod.object=arm
rest={b.name:b.matrix_local.copy() for b in arm.data.bones}
def pivot(at,r):
    return Matrix.Translation(Vector(at))@r@Matrix.Translation(-Vector(at))
def place(name,head,tail):
    b=arm.data.bones[name]
    result=(b.tail_local-b.head_local).rotation_difference(tail-head).to_matrix().to_4x4()@rest[name]
    result.translation=head
    arm.pose.bones[name].matrix=result
    bpy.context.view_layer.update()
target_errors=[];segment_errors=[];pose_samples={}
def pose(clip,u):
    cyc=math.tau*u
    for pb in arm.pose.bones:pb.matrix_basis=Matrix.Identity(4)
    sink=cfg['stance_sink_units'];breath=0
    if clip in ['idle','guard']:breath=cfg['breath_units']*math.sin(cyc)
    offset=Vector((0,0,-sink))
    body=Matrix.Translation(offset)
    arm.pose.bones['root'].matrix=rest['root'];bpy.context.view_layer.update()
    arm.pose.bones['pelvis'].matrix=body@rest['pelvis'];bpy.context.view_layer.update()
    spine_delta=body@pivot(B['spine'],Matrix.Rotation(breath*2,4,'X'))
    arm.pose.bones['spine'].matrix=spine_delta@rest['spine'];bpy.context.view_layer.update()
    arm.pose.bones['chest'].matrix=body@rest['chest'];bpy.context.view_layer.update()
    neck_angle=0;head_angle=0
    if clip=='idle':
        neck_angle=.012*math.sin(cyc);head_angle=-.009*math.sin(cyc)
    elif clip=='walk':
        neck_angle=-.045+.015*math.sin(cyc*2);head_angle=.008*math.sin(cyc*2)
    elif clip=='guard':
        neck_angle=cfg['guard_neck_radians']+.006*math.sin(cyc)
        head_angle=cfg['guard_head_radians']
    elif clip=='windup':
        q=smooth(u)
        neck_angle=cfg['guard_neck_radians']+(cfg['windup_neck_radians']-cfg['guard_neck_radians'])*q
        head_angle=cfg['guard_head_radians']+(cfg['windup_head_radians']-cfg['guard_head_radians'])*q
    elif clip=='release':
        # Native release occurs at t=0. This is only a small follow-through.
        q=smooth(u/.23) if u<.23 else 1-smooth((u-.23)/.77)
        recovery=smooth((u-.23)/.77) if u>.23 else 0
        neck_angle=cfg['windup_neck_radians']+(cfg['strike_neck_radians']-cfg['windup_neck_radians'])*q
        neck_angle+=(cfg['guard_neck_radians']-cfg['windup_neck_radians'])*recovery
        head_angle=cfg['windup_head_radians']+(cfg['strike_head_radians']-cfg['windup_head_radians'])*q
        head_angle+=(cfg['guard_head_radians']-cfg['windup_head_radians'])*recovery
    neck_delta=body@pivot(B['neck'],Matrix.Rotation(neck_angle,4,'X'))
    head_delta=neck_delta@pivot(B['head'],Matrix.Rotation(head_angle,4,'X'))
    arm.pose.bones['neck'].matrix=neck_delta@rest['neck'];bpy.context.view_layer.update()
    arm.pose.bones['head'].matrix=head_delta@rest['head'];bpy.context.view_layer.update()
    tail_delta=body@pivot(B['tail_root'],Matrix.Rotation(.025*math.sin(cyc),4,'Y')) if clip in ['idle','walk'] else body
    arm.pose.bones['tail'].matrix=tail_delta@rest['tail'];bpy.context.view_layer.update()
    for leg in cfg['legs']:
        n=leg['name'];hip=body@Vector(leg['hip'])
        target=Vector(leg['ankle']);target.z-=leg['sole']
        phase=(u+leg['phase'])%1
        lift=0
        if clip=='walk':
            duty=cfg['stance_fraction']
            if phase<duty:
                target.y+=cfg['step_units']*(-.5+phase/duty)
            else:
                swing=(phase-duty)/(1-duty)
                target.y+=cfg['step_units']*(.5-smooth(swing))
                lift=cfg['hoof_lift_units']*math.sin(math.pi*swing)
                target.z+=lift
        # A fitted distal segment retains its length; solve the two proximal
        # segments at a consistent pole to avoid knee flips.
        distal=Vector(leg['hock'])-Vector(leg['ankle'])
        distal=Matrix.Rotation((-.12 if leg['front'] else .09)*lift/max(cfg['hoof_lift_units'],.001),4,'X').to_3x3()@distal
        hock=target+distal
        l1=(Vector(leg['knee'])-Vector(leg['hip'])).length
        l2=(Vector(leg['hock'])-Vector(leg['knee'])).length
        axis=hock-hip;d=axis.length
        assert abs(l1-l2)+.0001<d<l1+l2-.0001,('Unreachable target',clip,u,n,d,l1+l2)
        axis.normalize()
        along=(l1*l1-l2*l2+d*d)/(2*d)
        height=math.sqrt(max(0,l1*l1-along*along))
        original=Vector(leg['knee'])-Vector(leg['hip'])
        old_axis=(Vector(leg['hock'])-Vector(leg['hip'])).normalized()
        pole=original-old_axis*original.dot(old_axis)
        bend=(pole-axis*pole.dot(axis)).normalized()
        knee=hip+axis*along+bend*height
        place(n+'_upper',hip,knee);place(n+'_lower',knee,hock);place(n+'_pastern',hock,target)
        hoof=rest[n+'_hoof'].copy();hoof.translation=target
        arm.pose.bones[n+'_hoof'].matrix=hoof;bpy.context.view_layer.update()
        target_errors.append((arm.pose.bones[n+'_hoof'].head-target).length)
        segment_errors.append(abs((knee-hip).length-l1)+abs((hock-knee).length-l2))
    bpy.context.view_layer.update()

clips={name:cfg[name+'_duration'] for name in ['idle','walk','windup','release','guard']}
scene.render.fps=cfg['source_fps'];arm.animation_data_create()
for clip,duration in clips.items():
    action=bpy.data.actions.new(clip);arm.animation_data.action=action
    end=round(duration*cfg['source_fps'])
    for frame in range(end+1):
        scene.frame_set(frame);pose(clip,frame/end)
        for pb in arm.pose.bones:
            pb.rotation_mode='QUATERNION'
            pb.keyframe_insert('location',frame=frame)
            pb.keyframe_insert('rotation_quaternion',frame=frame)
            pb.keyframe_insert('scale',frame=frame)
        if frame in {0,end//2,end}:
            evaluated=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
            posed=np.array([v.co[:] for v in evaluated.data.vertices])
            pose_samples[f'{clip}:{frame}']={'bounds':[posed.min(0).tolist(),posed.max(0).tolist()]}
            assert posed[:,2].min()>-.008,('Ground penetration',clip,frame,posed[:,2].min())
            if clip in ['guard','windup','release']:
                pelvic_anchor=(p[:,1]>.35)&(p[:,2]>.95)&(p[:,2]<1.4)
                shift=np.linalg.norm(posed[pelvic_anchor]-p[pelvic_anchor],axis=1).max()
                assert shift<.09, ('Back pulled by action pose',clip,frame,float(shift))
                pose_samples[f'{clip}:{frame}']['max_pelvic_shift_units']=float(shift)
    track=arm.animation_data.nla_tracks.new();track.name=clip
    strip=track.strips.new(clip,0,action);strip.action_slot=arm.animation_data.action_slot
    strip.extrapolation='NOTHING';track.mute=True;arm.animation_data.action=None
for pb in arm.pose.bones:pb.matrix_basis=Matrix.Identity(4)
scene.frame_set(0)
assert max(target_errors)<1e-5
assert max(segment_errors)<1e-5
pelvic_anchor=(p[:,1]>.35)&(p[:,2]>.95)&(p[:,2]<1.4)
assert all(sum(g.weight for g in mesh.data.vertices[i].groups if g.group in [groups['head'].index,groups['neck'].index])<1e-6 for i in np.where(pelvic_anchor)[0]), 'Pelvic torso must not follow skull'
counts=[len(v.groups) for v in mesh.data.vertices]
sums=[sum(g.weight for g in v.groups) for v in mesh.data.vertices]
assert min(counts)>0 and max(counts)<=4
assert max(abs(v-1) for v in sums)<1e-5
assert all(len(mesh.data.vertices[i].groups)==1 and mesh.data.vertices[i].groups[0].group==groups['head'].index for i in np.where(rigid)[0])
# glTF carries geometry, skin and clips. Bind the supplied ART-06C maps and
# surface_scar shader in Godot; a non-emissive fallback prevents whole-body glow.
assert not mesh.data.validate(verbose=True), 'Unexpected topology mutation after skinning'
authored=mesh.data.materials[0]
fallback=bpy.data.materials.new('RamHost_Bind_ART06C');fallback.use_nodes=True
bsdf=fallback.node_tree.nodes.get('Principled BSDF')
bsdf.inputs['Base Color'].default_value=(.32,.25,.19,1);bsdf.inputs['Roughness'].default_value=.9
mesh.data.materials[0]=fallback
bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);arm.select_set(True)
bpy.context.view_layer.objects.active=arm
for track in arm.animation_data.nla_tracks:track.mute=False
bpy.ops.export_scene.gltf(filepath=str(runtime/'model.glb'),export_format='GLB',
    use_selection=True,export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',
    export_frame_range=False,export_anim_slide_to_zero=True,export_cameras=False,export_lights=False)
mesh.data.materials[0]=authored
for track in arm.animation_data.nla_tracks:track.mute=True
for image in bpy.data.images:
    if image.source=='FILE' and image.has_data and not image.packed_file:image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(output/'stone_husk-rigged.blend'),compress=True)
for name in ['base.png','orm.png','scar-mask.png']:
    shutil.copyfile(source/name,runtime/name)
report={'stage':'production source/export validation','source_selection':str(source/'source-selection.json'),
        'source_triangles':len(host.data.polygons),'runtime_triangles':len(mesh.data.loop_triangles),
        'runtime_vertices':len(mesh.data.vertices),'welded_vertices':welded,'post_simplification_validation_changed':validation_changed,
        'bones':bones,'legs':cfg['legs'],'clips_seconds':clips,
        'max_weights':max(counts),'max_weight_sum_error':max(abs(v-1) for v in sums),
        'rigid_skull_and_horn_vertices':int(rigid.sum()),'max_hoof_target_error_units':max(target_errors),
        'max_segment_length_error_units':max(segment_errors),'pose_samples':pose_samples,
        'source_units':'Blender Z-up, -Y forward; two-unit longest dimension',
        'root_motion':False,'settings':cfg,
        'limitations':['Automatic triangle simplification and fitted skin, not hand retopology.',
        'No runtime terrain IK, facial animation or later-era physical forms.',
        'Native guard/combat/save integration remains coordinator-owned.']}
(output/'rig-report.json').write_text(json.dumps(report,indent=2)+'\n')
shutil.copyfile(Path(__file__).parent/'rig.json',output/'rig.json')
print('MOB02_SOURCE_EXPORT_OK '+json.dumps({k:report[k] for k in ['runtime_triangles','runtime_vertices','max_weights','max_hoof_target_error_units']}),flush=True)
