"""Rig the approved ART-06C porcupine; no source generation or new game rules.
Blender -b --python-exit-code 1 --python build_rig.py -- INPUT NEW_VERSION
Keeps a dense weighted master and one automatically decimated runtime surface.
"""
import bpy,json,math,sys,hashlib
import numpy as np
from pathlib import Path
from mathutils import Matrix,Vector
repo=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(repo/'tools/wroughtwild-fauna'))
from smooth_weights import smooth_fitted_weights
source,output=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]]
assert not output.exists(), 'Use a new source version'
output.mkdir(parents=True)
cfg=json.loads((repo/'tools/wroughtwild-porcupine/rig.json').read_text())
bpy.ops.wm.open_mainfile(filepath=str(source/'cinder_archer-surface.blend'))
scene=bpy.context.scene
host=bpy.data.objects['cinder_archer - surface host']
attachments=[o for o in scene.objects if o.type=='MESH' and o.get('attachment')=='head']
assert len(attachments)==12
report=json.loads((source/'surface-report.json').read_text())
p=np.array([v.co[:] for v in host.data.vertices],np.float32)
f=np.array([v.vertices[:] for v in host.data.polygons],np.int32)
assert hashlib.sha256(p.tobytes()+f.tobytes()).hexdigest()==report['geometry_sha256']
uv_before=np.array([u.uv[:] for u in host.data.uv_layers.active.data],np.float32)
for o in attachments:
 a=next(a for a in report['face_repair']['attachments'] if a['name']==o.name)
 q=np.array([v.co[:] for v in o.data.vertices],np.float32)
 t=np.array([v.vertices[:] for v in o.data.polygons],np.int32)
 assert hashlib.sha256(q.tobytes()+t.tobytes()).hexdigest()==a['geometry_sha256']
bones=[dict(name='body',parent=None,head=[0,.18,.49],tail=[0,-.10,.57]),
 dict(name='chest',parent='body',head=[0,-.26,.60],tail=[0,-.48,.70]),
 dict(name='head',parent='chest',head=[0,-.59,.73],tail=[0,-.90,.73]),
 dict(name='mantle',parent='chest',head=[0,-.23,.84],tail=[0,.10,1.0]),
 dict(name='tail',parent='body',head=[0,.59,.23],tail=[0,.9,.19])]
feet=[]
for front in [True,False]:
 for side in [-1,1]:
  name=('front' if front else 'rear')+('_L' if side<0 else '_R')
  q=p[(p[:,0]*side>.14)&(p[:,2]<.07)&((p[:,1]<-.20) if front else ((p[:,1]>.10)&(p[:,1]<.52)))]
  assert len(q)>20
  x=float(np.median(q[:,0]));y=float(np.median(q[:,1]));sole=float(q[:,2].min())
  hip=Vector((x,-.32 if front else .36,.44 if front else .34))
  knee=Vector((x,-.33 if front else .47,.22 if front else .19))
  foot=Vector((x,y,sole+.065))
  for part,h,t,parent in [('upper',hip,knee,'chest' if front else 'body'),('lower',knee,foot,name+'_upper'),('hoof',foot,foot+Vector((0,-.1,0)),name+'_lower')]:
   bones.append(dict(name=name+'_'+part,parent=parent,head=list(h),tail=list(t)))
  feet.append(dict(name=name,front=front,side=side,hip=list(hip),knee=list(knee),foot=list(foot),sole=sole))
arm=bpy.data.objects.new('Porcupine rig',bpy.data.armatures.new('Porcupine fitted anatomy'))
scene.collection.objects.link(arm)
bpy.ops.object.select_all(action='DESELECT');arm.select_set(True);bpy.context.view_layer.objects.active=arm
bpy.ops.object.mode_set(mode='EDIT')
for b in bones:
 bone=arm.data.edit_bones.new(b['name']);bone.head=b['head'];bone.tail=b['tail']
 if b['parent']:bone.parent=arm.data.edit_bones[b['parent']]
bpy.ops.object.mode_set(mode='OBJECT');arm.show_in_front=True

def smooth(x):
 x=max(0,min(1,x));return x*x*(3-2*x)
groups={b['name']:host.vertex_groups.new(name=b['name']) for b in bones}
for i,(x,y,z) in enumerate(p):
 head=smooth((-y-.54)/.13)*smooth((z-.44)/.12)
 chest=smooth((.22-y)/.42)*(1-head)
 weights={'body':1-head-chest,'chest':chest,'head':head}
 mantle=smooth((z-.85)/.16)*smooth((y+.65)/.18)
 tail=smooth((y-.56)/.17)*(1-smooth((z-.35)/.18))
 for name,blend in [('mantle',mantle),('tail',tail)]:
  weights={k:v*(1-blend) for k,v in weights.items()};weights[name]=blend
 limb=min(feet,key=lambda l:(x-l['foot'][0])**2+(y-l['foot'][1])**2)
 radius=math.hypot(x-limb['foot'][0],y-float(np.interp(z,[limb['foot'][2],limb['knee'][2],limb['hip'][2]],[limb['foot'][1],limb['knee'][1],limb['hip'][1]])))
 blend=smooth((limb['hip'][2]+.08-z)/.21)*(1-smooth((radius-.13)/.11))*(1-tail)*(1-head)
 if blend>0:
  weights={k:v*(1-blend) for k,v in weights.items()}
  paw=1-smooth((z-(limb['sole']+.075))/.07)
  upper=smooth((z-.18)/.13)*(1-paw)
  weights.update({limb['name']+'_upper':blend*upper,limb['name']+'_lower':blend*(1-paw-upper),limb['name']+'_hoof':blend*paw})
 if z<limb['sole']+.05 and math.hypot(x-limb['foot'][0],y-limb['foot'][1])<.20:
  weights={limb['name']+'_hoof':1.0}
 selected=sorted([(k,v) for k,v in weights.items() if v>1e-7],key=lambda kv:-kv[1])[:4]
 total=sum(v for k,v in selected)
 for name,value in selected:groups[name].add([i],float(value/total),'REPLACE')
smooth_fitted_weights(host,(p[:,1]<-.69)&(p[:,2]>.57),cfg['weight_smoothing_passes'])
for o in [host]+attachments:
 if o!=host:
  o.vertex_groups.new(name='head').add(list(range(len(o.data.vertices))),1,'REPLACE')
 o.parent=arm
 mod=o.modifiers.new('Fitted skin','ARMATURE');mod.object=arm
host.name='Porcupine dense editable host'
# Decimate once; no added normal map, no new UV bake, no LOD chain.
runtime=host.copy();runtime.data=host.data.copy();runtime.name='Porcupine runtime host';scene.collection.objects.link(runtime)
bpy.ops.object.select_all(action='DESELECT');runtime.select_set(True);bpy.context.view_layer.objects.active=runtime
mod=runtime.modifiers.new('Single production triangle reduction','DECIMATE');mod.ratio=cfg['runtime_host_triangles']/len(f);mod.use_collapse_triangulate=True
bpy.ops.object.modifier_move_up(modifier=mod.name);bpy.ops.object.modifier_apply(modifier=mod.name)
runtime.data.validate(verbose=True)
for v in runtime.data.vertices:
 incoming=sorted([(g.group,g.weight) for g in v.groups if g.weight>1e-7],key=lambda kv:-kv[1])[:4]
 total=sum(w for g,w in incoming);assert total>0
 for group in list(v.groups):runtime.vertex_groups[group.group].remove([v.index])
 for g,w in incoming:runtime.vertex_groups[g].add([v.index],w/total,'REPLACE')
assert np.array_equal(uv_before,np.array([u.uv[:] for u in host.data.uv_layers.active.data],np.float32))
host.hide_render=True;host.hide_set(True)
rest={b.name:b.matrix_local.copy() for b in arm.data.bones}
entries={b['name']:b for b in bones}
errors=[]
def rotate_at(pivot,angle,axis):
 return Matrix.Translation(Vector(pivot))@Matrix.Rotation(angle,4,axis)@Matrix.Translation(-Vector(pivot))
def matrix_for(name,a,b):
 old=Vector(entries[name]['tail'])-Vector(entries[name]['head'])
 m=old.rotation_difference(b-a).to_matrix().to_4x4()@rest[name];m.translation=a;return m

def pose(clip,u):
 for b in arm.pose.bones:b.matrix_basis=Matrix.Identity(4)
 wave=math.tau*u
 brace=smooth(u) if clip=='windup' else ((1-u)**2 if clip=='release' else 0)
 recoil=math.sin(math.pi*min(1,u/.45)) if clip=='release' and u<.45 else 0
 offset=Vector((0,cfg['recoil_units']*recoil,-cfg['stance_sink_units']-cfg['brace_sink_units']*brace))
 if clip=='idle':offset.z+=cfg['breath_units']*math.sin(wave)
 if clip=='walk':offset.z+=cfg['walk_bob_units']*math.cos(wave*2)
 body=Matrix.Translation(offset)@rotate_at(entries['body']['head'],cfg['body_brace_radians']*brace-cfg['body_recoil_radians']*recoil,'X')
 chest=body@rotate_at(entries['chest']['head'],cfg['chest_brace_radians']*brace,'X')
 transforms={'body':body,'chest':chest,'head':chest@rotate_at(entries['head']['head'],-cfg['head_tuck_radians']*brace+(.025*math.sin(wave) if clip=='idle' else 0),'X'),
 'mantle':chest@rotate_at(entries['mantle']['head'],cfg['quill_brace_radians']*brace-cfg['quill_recoil_radians']*recoil,'X'),
 'tail':body@rotate_at(entries['tail']['head'],cfg['tail_sway_radians']*math.sin(wave) if clip in ['idle','walk'] else 0,'Z')}
 for name,transform in transforms.items():
  arm.pose.bones[name].matrix=transform@rest[name];bpy.context.view_layer.update()
 for limb in feet:
  name=limb['name'];hip=transforms['chest' if limb['front'] else 'body']@Vector(limb['hip']);target=Vector(limb['foot'])
  if clip=='walk':
   # Four-beat walk: 65% planted rearward sweep, then lifted return.
   phase=(u+({(True,-1):0,(False,1):.25,(True,1):.5,(False,-1):.75}[(limb['front'],limb['side'])]))%1
   stance=cfg['stance_fraction'];step=cfg['step_span_units']
   if phase<stance:target.y+=-step/2+step*phase/stance
   else:
    s=(phase-stance)/(1-stance);target.y+=step/2-step*s;target.z+=cfg['step_lift_units']*math.sin(math.pi*s)
  l1=(Vector(limb['knee'])-Vector(limb['hip'])).length;l2=(Vector(limb['foot'])-Vector(limb['knee'])).length
  v=target-hip;d=v.length
  assert abs(l1-l2)+1e-5<d<l1+l2, ('Unreachable foot',clip,u,name,d,l1+l2)
  along=v/d;a=(l1*l1-l2*l2+d*d)/(2*d);height=math.sqrt(max(0,l1*l1-a*a))
  # Both knees sit behind their hip-to-paw line in this actual source.
  bend=Vector((0,-along.z,along.y))
  knee=hip+along*a+bend*height
  arm.pose.bones[name+'_upper'].matrix=matrix_for(name+'_upper',hip,knee);bpy.context.view_layer.update()
  arm.pose.bones[name+'_lower'].matrix=matrix_for(name+'_lower',knee,target);bpy.context.view_layer.update()
  foot=rest[name+'_hoof'].copy();foot.translation=target
  arm.pose.bones[name+'_hoof'].matrix=foot;bpy.context.view_layer.update()
  errors.append((arm.pose.bones[name+'_hoof'].head-target).length)

rt=json.loads((repo/'data/tuning/combat_realtime.json').read_text())
clips={'idle':cfg['idle_seconds'],'walk':cfg['walk_seconds'],'windup':rt['behaviours']['ranged']['windup_seconds'],'release':cfg['release_clip_seconds']}
scene.render.fps=60;arm.animation_data_create()
for clip,duration in clips.items():
 action=bpy.data.actions.new('Porcupine__'+clip);arm.animation_data.action=action
 for frame in range(round(duration*60)+1):
  scene.frame_set(frame);pose(clip,frame/(duration*60))
  for b in arm.pose.bones:
   b.rotation_mode='QUATERNION'
   for field in ['location','rotation_quaternion','scale']:b.keyframe_insert(field,frame=frame)
 track=arm.animation_data.nla_tracks.new();track.name=clip
 strip=track.strips.new(clip,0,action);strip.action_slot=arm.animation_data.action_slot;strip.extrapolation='NOTHING';track.mute=True
 arm.animation_data.action=None
for b in arm.pose.bones:b.matrix_basis=Matrix.Identity(4)
scene.frame_set(0)
# Plain host fallback avoids embedding unused copies of the three retained atlases.
authored=runtime.data.materials[0]
fallback=bpy.data.materials.new('Porcupine host - bind ART06C shader');fallback.diffuse_color=(.22,.16,.10,1)
runtime.data.materials[0]=fallback
bpy.ops.object.select_all(action='DESELECT')
for o in [runtime,arm]+attachments:o.hide_set(False);o.select_set(True)
bpy.context.view_layer.objects.active=arm
for t in arm.animation_data.nla_tracks:t.mute=False
bpy.ops.export_scene.gltf(filepath=str(output/'porcupine.glb'),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_frame_range=False,export_anim_slide_to_zero=True,export_cameras=False,export_lights=False)
runtime.data.materials[0]=authored
for t in arm.animation_data.nla_tracks:t.mute=True
for i in bpy.data.images:
 if i.source=='FILE' and i.has_data:i.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(output/'porcupine-rigged.blend'),compress=True)
# Check actual saved source, weights and representative deformations once.
bpy.ops.wm.open_mainfile(filepath=str(output/'porcupine-rigged.blend'))
scene=bpy.context.scene
arm=bpy.data.objects['Porcupine rig'];runtime=bpy.data.objects['Porcupine runtime host']
assert len(arm.data.bones)==17
for o in [runtime,bpy.data.objects['Porcupine dense editable host']]+[o for o in bpy.context.scene.objects if o.type=='MESH' and o.get('attachment')=='head']:
 for v in o.data.vertices:
  assert 1<=len(v.groups)<=4 and abs(sum(g.weight for g in v.groups)-1)<1e-5
stats=[]
base=np.array([v.co[:] for v in runtime.data.vertices])
for clip,frame in [('idle',0),('walk',17),('windup',36),('release',4)]:
 action=bpy.data.actions['Porcupine__'+clip];arm.animation_data.action=action;arm.animation_data.action_slot=action.slots[0]
 scene.frame_set(frame);bpy.context.view_layer.update()
 obj=runtime.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=obj.to_mesh()
 deformed=np.array([v.co[:] for v in mesh.vertices]);assert np.isfinite(deformed).all()
 displacement=np.linalg.norm(deformed-base,axis=1)
 row={'clip':clip,'frame':frame,'max_displacement_units':float(displacement.max()),'minimum_z':float(deformed[:,2].min())}
 assert row['minimum_z']>-.05 and row['max_displacement_units']<.4,row
 if clip in ['walk','windup','release']:assert displacement.max()>.015,row
 stats.append(row);obj.to_mesh_clear()
arm.animation_data.action=None
runtime.data.calc_loop_triangles()
result={'source_selection':json.loads((source/'source-selection.json').read_text()),'source_geometry_sha256':report['geometry_sha256'],'dense_triangles':len(f),'runtime_host_triangles':len(runtime.data.loop_triangles),'attachment_triangles':sum(a['triangles'] for a in report['face_repair']['attachments']),'bones':bones,'feet':feet,'clips_seconds':clips,'max_foot_target_error_units':max(errors),'saved_pose_checks':stats,'uv_dense_unchanged':True,'all_vertices_normalized_1_to_4_weights':True,'settings':cfg}
assert max(errors)<1e-5
(output/'rig-report.json').write_text(json.dumps(result,indent=2)+'\n')
print('MOB01_RIG_OK',json.dumps({k:result[k] for k in ['runtime_host_triangles','attachment_triangles','max_foot_target_error_units','saved_pose_checks']}),flush=True)
