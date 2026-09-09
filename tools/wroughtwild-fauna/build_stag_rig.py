"""Blender: stag deformation/LOD candidate from the reviewed scar surface.

-- SURFACE_DIRECTORY NEW_OUTPUT
The generated topology is an evaluated candidate, not a hand-retopology claim.
"""
import hashlib,json,math,sys
from pathlib import Path
import bpy
import numpy as np
from mathutils import Matrix, Vector
from mathutils.kdtree import KDTree
sys.path.insert(0, str(Path(__file__).resolve().parent))
from smooth_weights import smooth_fitted_weights

surface,output=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]]
assert not output.exists();output.mkdir(parents=True)
repo=Path(__file__).resolve().parents[2]
cfg=json.loads((repo/'tools/wroughtwild-fauna/stag.json').read_text())
settings=json.loads((repo/'tools/wroughtwild-fauna/stag-rig.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(surface/'stag-surface.blend'))
scene=bpy.context.scene
source=bpy.data.objects['Vaultcrown - host']
source.hide_set(False)
bpy.ops.object.select_all(action='DESELECT')
near=source.copy();near.data=source.data.copy();near.name='Vaultcrown - near candidate'
scene.collection.objects.link(near);near.select_set(True);bpy.context.view_layer.objects.active=near
mod=near.modifiers.new('Join identical seam positions before simplification','WELD');mod.merge_threshold=1e-6
bpy.ops.object.modifier_apply(modifier=mod.name)
welded_vertices=len(near.data.vertices)
mod=near.modifiers.new('Measured near detail candidate','DECIMATE');mod.ratio=settings['near_triangles']/len(near.data.polygons)
mod.use_collapse_triangulate=True
bpy.ops.object.modifier_apply(modifier=mod.name)
near.data.validate(verbose=True)
near.data.calc_loop_triangles()
assert len(near.data.uv_layers)==1

# Bake the dense coat and plates, including the recessed fracture surface.
mat=near.data.materials[0].copy();near.data.materials[0]=mat
normal=bpy.data.images.new('Vaultcrown baked normals',width=settings['normal_pixels'],height=settings['normal_pixels'],alpha=False)
normal.colorspace_settings.name='Non-Color'
node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=normal;mat.node_tree.nodes.active=node
bpy.ops.object.select_all(action='DESELECT');source.select_set(True);near.select_set(True)
bpy.context.view_layer.objects.active=near
scene.render.engine='CYCLES';scene.cycles.samples=1
scene.render.bake.use_selected_to_active=True;scene.render.bake.cage_extrusion=.025
scene.render.bake.max_ray_distance=.05;scene.render.bake.margin=8;scene.render.bake.normal_space='TANGENT'
bpy.ops.object.bake(type='NORMAL')
normal.filepath_raw=str(output/'normal.png');normal.file_format='PNG';normal.save();normal.pack()
normal_map=mat.node_tree.nodes.new('ShaderNodeNormalMap')
mat.node_tree.links.new(node.outputs['Color'],normal_map.inputs['Color'])
shader=mat.node_tree.nodes.get('Principled BSDF')
mat.node_tree.links.new(normal_map.outputs['Normal'],shader.inputs['Normal'])
source.hide_render=True;source.hide_set(True);source.select_set(False)

# Articulation fitted to the actual normalized stag, with planted feet and a rigid skull.
p=np.array([v.co for v in near.data.vertices])
bones=[{'name':'body','parent':None,'head':[0,-.40,1.35],'tail':[0,.15,1.40]},
 {'name':'chest','parent':'body','head':[0,.10,1.42],'tail':[0,.40,1.50]},
 {'name':'neck','parent':'chest','head':[0,.38,1.38],'tail':[-.13,.93,2.09]},
 {'name':'head','parent':'neck','head':[-.13,.93,2.09],'tail':[-.19,1.30,1.89]},
 {'name':'tail','parent':'body','head':[0,-1.20,1.43],'tail':[0,-1.40,1.27]}]
feet=[]
for front,yhip,zhip in [(True,.32,1.24),(False,-1.0,1.20)]:
    for side in [-1,1]:
        name=('front' if front else 'rear')+('_L' if side<0 else '_R')
        q=p[(p[:,0]*side>.1)&(p[:,1]*(1 if front else -1)>0)&(p[:,1]<.8)&(p[:,2]<.15)]
        assert len(q)>10
        sole=float(q[:,2].min());x=float(np.median(q[:,0]));y=float(np.median(q[:,1]))
        hip=Vector((x,yhip,zhip));foot=Vector((x,y,sole+.10))
        knee=Vector((x,(y+yhip)/2+(.035 if front else -.04),.65))
        for part,h,t,parent in [('upper',hip,knee,'chest' if front else 'body'),
                                 ('lower',knee,foot,name+'_upper'),
                                 ('hoof',foot,foot+Vector((0,.10,0)),name+'_lower')]:
            bones.append({'name':name+'_'+part,'parent':parent,'head':list(h),'tail':list(t)})
        feet.append({'name':name,'side':side,'front':front,'hip':list(hip),'knee':list(knee),'foot':list(foot),'sole':sole})

arm=bpy.data.objects.new('Vaultcrown - study rig',bpy.data.armatures.new('Vaultcrown anatomy rig'))
scene.collection.objects.link(arm);bpy.context.view_layer.objects.active=arm;arm.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for entry in bones:
    bone=arm.data.edit_bones.new(entry['name']);bone.head=entry['head'];bone.tail=entry['tail']
    if entry['parent']:bone.parent=arm.data.edit_bones[entry['parent']]
bpy.ops.object.mode_set(mode='OBJECT')
arm.show_in_front=True
groups={entry['name']:near.vertex_groups.new(name=entry['name']) for entry in bones}
def smooth(v):
    v=max(0,min(1,v));return v*v*(3-2*v)
for i,point in enumerate(p):
    x,y,z=point
    head=smooth((y-.60)/.30)*smooth((z-1.58)/.30)
    head=max(head,smooth((z-1.65)/.31),smooth((abs(x)-.30)/.15)*smooth((z-1.45)/.25))
    neck=smooth((y-.05)/.55)*smooth((z-1.20)/.55)*(1-head)
    chest=smooth((y+.30)/.55)*(1-head-neck)
    weights={'body':1-head-neck-chest,'chest':chest,'neck':neck,'head':head}
    tail=smooth((-y-1.18)/.16)*smooth((z-.9)/.25)
    if tail>0:
        weights={k:v*(1-tail) for k,v in weights.items()};weights['tail']=tail
    limb=min(feet,key=lambda f:(x-f['foot'][0])**2+(y-f['foot'][1])**2)
    foot_distance=math.hypot(x-limb['foot'][0],y-limb['foot'][1])
    leg=smooth((1.30-z)/.42)*smooth((abs(x)-.055)/.10)
    leg=max(leg,smooth((.70-z)/.28)*(1-smooth((foot_distance-.3)/.15)))
    centre_y=float(np.interp(z,[limb['foot'][2],limb['knee'][2],limb['hip'][2]],[limb['foot'][1],limb['knee'][1],limb['hip'][1]]))
    radius=math.hypot(x-limb['foot'][0],y-centre_y)
    leg*=(1-tail)*(1-smooth((radius-.14)/.16))
    if leg>0:
        weights={k:v*(1-leg) for k,v in weights.items()}
        foot_weight=1-smooth((z-(limb['sole']+.11))/.13)
        upper=smooth((z-.53)/.23)*(1-foot_weight)
        weights[limb['name']+'_upper']=leg*upper
        weights[limb['name']+'_lower']=leg*(1-foot_weight-upper)
        weights[limb['name']+'_hoof']=leg*foot_weight
    if z<limb['sole']+.09 and foot_distance<.30:
        weights={limb['name']+'_hoof':1.0};near.data.vertices[i].co.z=max(z,limb['sole'])
    keep=sorted([(k,v) for k,v in weights.items() if v>1e-7],key=lambda v:-v[1])[:4]
    total=sum(v for k,v in keep);assert total>0
    for name,value in keep:groups[name].add([i],float(value/total),'REPLACE')
# Diffuse spatial fitting boundaries through connected skin, retaining rigid
# skull/crown and planted sole anchors. Detached surfaces are never bridged.
smooth_fitted_weights(near, (p[:,2]>1.96)|((np.abs(p[:,0])>.45)&(p[:,2]>1.70)), settings['weight_smoothing_passes'])
modifier=near.modifiers.new('Anatomical deformation','ARMATURE');modifier.object=arm
near.parent=arm

# The shallow eyes and lids follow the rigid skull.
parts=[o for o in scene.objects if o.type=='MESH' and o.get('attachment')=='head']
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join()
face=bpy.context.object;face.name='Vaultcrown - fitted eyes'
group=face.vertex_groups.new(name='head');group.add(list(range(len(face.data.vertices))),1,'REPLACE')
face.parent=arm;mod=face.modifiers.new('Rigid skull attachment','ARMATURE');mod.object=arm

# Analytic two-segment IK gives each hoof an explicit target; no stretchy bones.
rest={bone.name:bone.matrix_local.copy() for bone in arm.data.bones}
def matrix_for(name,head,tail):
    old=Vector(bones[next(i for i,e in enumerate(bones) if e['name']==name)]['tail'])-Vector(bones[next(i for i,e in enumerate(bones) if e['name']==name)]['head'])
    rotation=old.rotation_difference(tail-head).to_matrix().to_4x4()
    result=rotation@rest[name];result.translation=head
    return result
ik_errors=[];target_errors=[];evaluated_hoof_errors=[]
def pose(clip,t,duration):
    for pb in arm.pose.bones:pb.matrix_basis=Matrix.Identity(4)
    u=t/duration;cycle=math.tau*u
    offset=Vector((0,0,-settings['stance_sink_metres']+(math.sin(cycle)*settings['breath_metres'] if clip=='idle' else 0)))
    body_matrix=Matrix.Translation(offset)
    arm.pose.bones['body'].matrix=body_matrix@rest['body'];bpy.context.view_layer.update()
    arm.pose.bones['chest'].matrix=body_matrix@rest['chest'];bpy.context.view_layer.update()
    def pivot(at,rotation):return Matrix.Translation(Vector(at))@rotation@Matrix.Translation(-Vector(at))
    graze=math.sin(math.pi*u)**2 if clip=='graze' else 0.0
    neck_delta=pivot(bones[2]['head'],Matrix.Rotation(settings['graze_neck_radians']*graze,4,'X'))
    if clip=='turn':neck_delta=pivot(bones[2]['head'],Matrix.Rotation(settings['turn_neck_radians']*math.sin(cycle),4,'Z'))
    head_delta=pivot(bones[3]['head'],Matrix.Rotation(settings['graze_head_counter_radians']*graze,4,'X'))
    if clip=='turn':head_delta=pivot(bones[3]['head'],Matrix.Rotation(settings['turn_head_radians']*math.sin(cycle),4,'Z'))
    arm.pose.bones['neck'].matrix=body_matrix@neck_delta@rest['neck'];bpy.context.view_layer.update()
    arm.pose.bones['head'].matrix=body_matrix@neck_delta@head_delta@rest['head'];bpy.context.view_layer.update()
    arm.pose.bones['tail'].matrix=body_matrix@rest['tail'];bpy.context.view_layer.update()
    for limb in feet:
        name=limb['name'];hip=body_matrix@Vector(limb['hip']);knee=Vector(limb['knee']);ankle=Vector(limb['foot'])
        target=ankle.copy();target.z-=limb['sole']
        if clip=='walk':
            phase=u+(.0 if (limb['front'] and limb['side']<0) or (not limb['front'] and limb['side']>0) else .5)
            phase%=1
            if phase<.6:
                target.y+=settings['step_metres']*(.5-phase/.6)
            else:
                swing=(phase-.6)/.4
                target.y+=settings['step_metres']*(-.5+smooth(swing))
                target.z+=settings['hoof_lift_metres']*math.sin(math.pi*swing)
        l1=(Vector(limb['knee'])-Vector(limb['hip'])).length;l2=(Vector(limb['foot'])-Vector(limb['knee'])).length
        v=target-hip;distance=v.length
        requested_target=target.copy()
        if distance>l1+l2-.001:
            target=hip+v.normalized()*(l1+l2-.001);v=target-hip;distance=v.length
        target_errors.append((target-requested_target).length)
        along=v.normalized();a=(l1*l1-l2*l2+distance*distance)/(2*distance)
        height=math.sqrt(max(0,l1*l1-a*a))
        bend=Vector((0,-along.z,along.y))*(1 if limb['front'] else -1)
        knee=hip+along*a+bend*height
        arm.pose.bones[name+'_upper'].matrix=matrix_for(name+'_upper',hip,knee)
        bpy.context.view_layer.update()
        arm.pose.bones[name+'_lower'].matrix=matrix_for(name+'_lower',knee,target)
        bpy.context.view_layer.update()
        hoof_matrix=rest[name+'_hoof'].copy();hoof_matrix.translation=target
        arm.pose.bones[name+'_hoof'].matrix=hoof_matrix
        bpy.context.view_layer.update()
        evaluated_hoof_errors.append((arm.pose.bones[name+'_hoof'].head-requested_target).length)
        ik_errors.append(abs((hip-knee).length-l1)+abs((target-knee).length-l2))
    bpy.context.view_layer.update()

clips={'idle':4.0,'walk':1.6,'graze':6.0,'turn':4.0}
scene.render.fps=100;arm.animation_data_create()
for clip,duration in clips.items():
    action=bpy.data.actions.new('Vaultcrown__'+clip);arm.animation_data.action=action
    end=round(duration*100)
    # Dense local transforms keep the planted IK solution through the short
    # 0.22-second release after glTF/Godot interpolation.
    for frame in range(end+1):
        scene.frame_set(frame);pose(clip,frame/100,duration)
        for pb in arm.pose.bones:
            pb.rotation_mode='QUATERNION';pb.keyframe_insert('location',frame=frame);pb.keyframe_insert('rotation_quaternion',frame=frame);pb.keyframe_insert('scale',frame=frame)
    track=arm.animation_data.nla_tracks.new();track.name=clip
    strip=track.strips.new(clip,0,action);strip.action_slot=arm.animation_data.action_slot;strip.extrapolation='NOTHING';track.mute=True
    arm.animation_data.action=None
for pb in arm.pose.bones:pb.matrix_basis=Matrix.Identity(4)
scene.frame_set(0)
assert max(target_errors)<1e-5, ('Unreachable hoof target',max(target_errors))
assert max(evaluated_hoof_errors)<1e-5, ('Hoof failed to reach its target',max(evaluated_hoof_errors))

variants=[near]
weight_tree=KDTree(len(near.data.vertices))
for vertex in near.data.vertices:weight_tree.insert(vertex.co,vertex.index)
weight_tree.balance()
for label,count in [('mid',settings['mid_triangles']),('far',settings['far_triangles'])]:
    obj=near.copy();obj.data=near.data.copy();obj.name='Vaultcrown - '+label+' candidate';scene.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
    decimate=obj.modifiers.new('Measured '+label+' candidate','DECIMATE');decimate.ratio=count/len(obj.data.polygons);decimate.use_collapse_triangulate=True
    bpy.ops.object.modifier_move_up(modifier=decimate.name)
    bpy.ops.object.modifier_apply(modifier=decimate.name)
    obj.data.validate(verbose=True)
    # Reattach reduced vertices to the reviewed near skin. Edge collapse can
    # blend a planted hoof with its lower-leg group and move it below its sole.
    for vertex in obj.data.vertices:
        _,index,_=weight_tree.find(vertex.co)
        incoming=[(g.group,g.weight) for g in near.data.vertices[index].groups]
        for group in [g.group for g in vertex.groups]:obj.vertex_groups[group].remove([vertex.index])
        for group,weight in incoming:obj.vertex_groups[group].add([vertex.index],weight,'REPLACE')
        strongest=max(incoming,key=lambda pair:pair[1])
        name=obj.vertex_groups[strongest[0]].name
        if name.endswith('_hoof') and strongest[1]>.999:
            foot=next(f for f in feet if f['name']+'_hoof'==name)
            vertex.co.z=max(vertex.co.z,foot['sole'])
    obj.hide_render=True;obj.hide_set(True);variants.append(obj)

report={'source_sha256':cfg['source_sha256'],'surface_sha256':hashlib.sha256((surface/'stag-surface.blend').read_bytes()).hexdigest(),
        'settings':settings,'bones':bones,'feet':feet,'accessories':[{'name':face.name,'triangles':len(face.data.polygons),'materials':len(face.data.materials)}],'clips_seconds':clips,'variants':[],
        'max_ik_segment_length_error_metres':max(ik_errors),'welded_source_vertices':welded_vertices,
        'max_unreachable_hoof_target_metres':max(target_errors),'max_evaluated_hoof_target_error_metres':max(evaluated_hoof_errors),
        'limitations':'Generated triangle topology and fitted weights; not hand-authored quad retopology. In-place preview locomotion is not an actual Enemy integration or terrain IK test.'}
for label,obj in zip(['near','mid','far'],variants):
    obj.data.calc_loop_triangles()
    # Edge collapse may combine two legal four-weight sets. Select and normalize
    # the strongest influences explicitly before the four-influence export.
    for vertex in obj.data.vertices:
        influences=sorted([(g.group,g.weight) for g in vertex.groups if g.weight>1e-7],key=lambda value:-value[1])
        keep=influences[:4];total=sum(weight for group,weight in keep)
        assert total>0
        keep_ids={group for group,weight in keep}
        for group in [g.group for g in vertex.groups if g.group not in keep_ids]:obj.vertex_groups[group].remove([vertex.index])
        for group,weight in keep:obj.vertex_groups[group].add([vertex.index],weight/total,'REPLACE')
    counts=[len(v.groups) for v in obj.data.vertices]
    assert min(counts)>0 and max(counts)<=4
    report['variants'].append({'name':label,'vertices':len(obj.data.vertices),'triangles':len(obj.data.loop_triangles),'uv_layers':len(obj.data.uv_layers),'materials':len(obj.data.materials),'max_weights':max(counts)})
    obj.hide_set(False);obj.hide_render=False
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);arm.select_set(True);bpy.context.view_layer.objects.active=arm
    face.select_set(True)
    for track in arm.animation_data.nla_tracks:track.mute=False
    # Export a safe ordinary PBR fallback. glTF does not carry the authored node
    # graph; exporting its strength alone would incorrectly illuminate the body.
    authored=obj.data.materials[0]
    fallback=bpy.data.materials.new('Vaultcrown - PBR fallback (bind scar shader in Godot)');fallback.use_nodes=True
    fn=fallback.node_tree.nodes;fl=fallback.node_tree.links;bsdf=fn.get('Principled BSDF')
    base_node=fn.new('ShaderNodeTexImage');base_node.image=bpy.data.images.load(str(surface/'base.png'),check_existing=True)
    fl.new(base_node.outputs['Color'],bsdf.inputs['Base Color'])
    orm_node=fn.new('ShaderNodeTexImage');orm_node.image=bpy.data.images.load(str(surface/'orm.png'),check_existing=True);orm_node.image.colorspace_settings.name='Non-Color'
    separate=fn.new('ShaderNodeSeparateColor');fl.new(orm_node.outputs['Color'],separate.inputs['Color'])
    fl.new(separate.outputs['Green'],bsdf.inputs['Roughness']);fl.new(separate.outputs['Blue'],bsdf.inputs['Metallic'])
    nn=fn.new('ShaderNodeTexImage');nn.image=normal;nm=fn.new('ShaderNodeNormalMap');fl.new(nn.outputs['Color'],nm.inputs['Color']);fl.new(nm.outputs['Normal'],bsdf.inputs['Normal'])
    obj.data.materials[0]=fallback
    bpy.ops.export_scene.gltf(filepath=str(output/('stag-'+label+'.glb')),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_frame_range=False,export_anim_slide_to_zero=True,export_cameras=False,export_lights=False)
    obj.data.materials[0]=authored
    for track in arm.animation_data.nla_tracks:track.mute=True
    obj.hide_set(True);obj.hide_render=True
near.hide_set(False);near.hide_render=False
bpy.ops.object.select_all(action='DESELECT');near.select_set(True);arm.select_set(True);bpy.context.view_layer.objects.active=arm
for image in bpy.data.images:
    if image.source=='FILE' and image.has_data:image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(output/'stag-candidate.blend'),compress=True)
(output/'rig-report.json').write_text(json.dumps(report,indent=2)+'\n')
print('STAG_RIG_OK '+str(output),flush=True)
