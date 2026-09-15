"""Fit the approved ART-06C nymph. Never overwrite a source master.
Blender --background --python build_nymph.py -- INPUT NEW_MASTER RUNTIME
"""
import hashlib,json,math,shutil,sys
from pathlib import Path
import bpy
import numpy as np
from mathutils import Matrix,Vector
source,out,runtime=[Path(a).resolve() for a in sys.argv[sys.argv.index('--')+1:]]
assert not out.exists(),'Use a new source version.'
out.mkdir(parents=True);runtime.mkdir(parents=True,exist_ok=True)
cfg=json.loads((Path(__file__).parent/'rig.json').read_text(encoding='utf-8-sig'))
bpy.ops.wm.open_mainfile(filepath=str(source/'bog_lurker-surface.blend'))
scene=bpy.context.scene;host=bpy.data.objects['bog_lurker - surface host']
bpy.ops.object.select_all(action='DESELECT')
mesh=host.copy();mesh.data=host.data.copy();mesh.name='NymphSkin';scene.collection.objects.link(mesh)
mesh.select_set(True);bpy.context.view_layer.objects.active=mesh
mod=mesh.modifiers.new('Weld coincident UV seams','WELD');mod.merge_threshold=1e-6
bpy.ops.object.modifier_apply(modifier=mod.name)
mod=mesh.modifiers.new('One runtime detail level','DECIMATE');mod.ratio=cfg['target_triangles']/len(mesh.data.polygons);mod.use_collapse_triangulate=True
bpy.ops.object.modifier_apply(modifier=mod.name)
validation_changed=mesh.data.validate(verbose=True);mesh.data.calc_loop_triangles()
assert len(mesh.data.uv_layers)==1
host.hide_render=True;host.hide_set(True);host.select_set(False)
p=np.array([v.co[:] for v in mesh.data.vertices]);bones=[]
def bone(n,h,t,parent=None):bones.append(dict(name=n,head=h,tail=t,parent=parent))
bone('root',[0,0,0],[0,0,.15]);bone('body',cfg['body'],cfg['body_tip'],'root')
bone('head',cfg['head'],cfg['head_tip'],'body');bone('labium',cfg['labium'],cfg['labium_tip'],'head')
for j in range(3):bone('abdomen_'+str(j+1),cfg['abdomen'][j],cfg['abdomen'][j+1],'body' if j==0 else 'abdomen_'+str(j))
for side,label in [(-1,'L'),(1,'R')]:bone('antenna_'+label,[side*.07,-.795,.365],[side*.13,-.94,.43],'head')
for leg in cfg['legs']:
 n=leg['name'];bone(n+'_upper',leg['hip'],leg['knee'],'body');bone(n+'_lower',leg['knee'],leg['ankle'],n+'_upper');bone(n+'_foot',leg['ankle'],leg['toe'],n+'_lower')
 q=p[(p[:,0]*leg['side']>(.45 if leg['kind']=='fore' else .77 if leg['kind']=='mid' else .56))]
 q=q[(q[:,1]<-.9) if leg['kind']=='fore' else ((q[:,1]>-.30)&(q[:,1]<-.16)) if leg['kind']=='mid' else (q[:,1]>.43)]
 assert len(q)>30,('Missing foot',n);leg['sole']=float(q[:,2].min())
arm=bpy.data.objects.new('NymphRig',bpy.data.armatures.new('NymphAnatomy'));scene.collection.objects.link(arm)
arm.select_set(True);bpy.context.view_layer.objects.active=arm;bpy.ops.object.mode_set(mode='EDIT')
for b in bones:
 e=arm.data.edit_bones.new(b['name']);e.head=b['head'];e.tail=b['tail']
 if b['parent']:e.parent=arm.data.edit_bones[b['parent']]
bpy.ops.object.mode_set(mode='OBJECT');arm.show_in_front=True
groups={b['name']:mesh.vertex_groups.new(name=b['name']) for b in bones}
def smooth(x):x=max(0,min(1,x));return x*x*(3-2*x)
def segment(q,a,b):
 a=np.array(a);d=np.array(b)-a;t=float(np.clip(np.dot(q-a,d)/np.dot(d,d),0,1));return float(np.linalg.norm(q-(a+t*d))),t
supported_abdomen=0;weighted={k:0 for k in groups}
for i,q in enumerate(p):
 x,y,z=q;w={'body':1.0}
 # All layers within a segment share these longitudinal supports. Abdominal
 # vertices never use nearest-leg weighting through a cavity or scar route.
 if y>-.05 and abs(x)<.27:
  a=smooth((y+.05)/.10);w={'body':1-a,'abdomen_1':a}
  if y>.24:
   a=smooth((y-.24)/.14);w={'abdomen_1':1-a,'abdomen_2':a}
  if y>.58:
   a=smooth((y-.58)/.13);w={'abdomen_2':1-a,'abdomen_3':a}
  supported_abdomen+=1
 head=smooth((-.54-y)/.10)*(1-smooth((abs(x)-.20)/.07))
 if head:w={'body':1-head,'head':head}
 if abs(x)>.19 and z<.36:
  candidates=[]
  for leg in cfg['legs']:
   if x*leg['side']<=0:continue
   segments=[segment(q,leg[a],leg[b]) for a,b in [('hip','knee'),('knee','ankle'),('ankle','toe')]]
   j=min(range(3),key=lambda j:segments[j][0]);candidates.append((segments[j][0],leg,j,segments[j][1]))
  distance,leg,j,t=min(candidates,key=lambda v:v[0]);n=leg['name']
  extent=smooth((abs(x)-abs(leg['hip'][0])+.02)/.095)
  influence=extent*(1-smooth((distance-.075)/.075))
  if y>-.05 and abs(x)<.27:influence=0
  if influence>0:
   lw={n+['_upper','_lower','_foot'][j]:1.0}
   if j==0 and t>.72:lw={n+'_upper':1-smooth((t-.72)/.28)*.5,n+'_lower':smooth((t-.72)/.28)*.5}
   elif j==1 and t<.2:lw={n+'_upper':.5*(1-smooth(t/.2)),n+'_lower':.5+.5*smooth(t/.2)}
   elif j==1 and t>.8:lw={n+'_lower':1-smooth((t-.8)/.2)*.5,n+'_foot':smooth((t-.8)/.2)*.5}
   elif j==2 and t<.15:lw={n+'_lower':.5*(1-smooth(t/.15)),n+'_foot':.5+.5*smooth(t/.15)}
   beyond=(y<-.9 if leg['kind']=='fore' else abs(x)>.77 if leg['kind']=='mid' else y>.43)
   if beyond and distance<.15:influence=1;lw={n+'_foot':1}
   w={k:v*(1-influence) for k,v in w.items()}
   for k,v in lw.items():w[k]=w.get(k,0)+v*influence
 if y<-.795 and z>.345 and abs(x)<.18:
  a=smooth((-.795-y)/.055)*smooth((z-.345)/.04)
  w={k:v*(1-a) for k,v in w.items()};w['antenna_'+('L' if x<0 else 'R')]=a
 if y<-.69 and z<.23 and abs(x)<.125:
  a=smooth((-.69-y)/.06)*(1-smooth((z-.19)/.04))*(1-smooth((abs(x)-.085)/.04))
  w={k:v*(1-a) for k,v in w.items()};w['labium']=a
 keep=sorted([(k,v) for k,v in w.items() if v>1e-7],key=lambda kv:-kv[1])[:4];total=sum(v for k,v in keep)
 assert total>0
 for k,v in keep:groups[k].add([i],float(v/total),'REPLACE');weighted[k]+=1
assert all(weighted[leg['name']+'_'+part]>20 for leg in cfg['legs'] for part in ['upper','lower','foot'])
assert all(weighted[k]>10 for k in ['antenna_L','antenna_R','labium','abdomen_1','abdomen_2','abdomen_3'])
mesh.parent=arm;mod=mesh.modifiers.new('Fitted nymph joints','ARMATURE');mod.object=arm
rest={b.name:b.matrix_local.copy() for b in arm.data.bones}
def pivot(p,a,axis):return Matrix.Translation(Vector(p))@Matrix.Rotation(a,4,axis)@Matrix.Translation(-Vector(p))
def place(n,h,t):
 b=arm.data.bones[n];m=(b.tail_local-b.head_local).rotation_difference(t-h).to_matrix().to_4x4()@rest[n];m.translation=h
 arm.pose.bones[n].matrix=m;bpy.context.view_layer.update()
errors=[];length_errors=[];samples={}
def pose(clip,u):
 for pb in arm.pose.bones:pb.matrix_basis=Matrix.Identity(4)
 angle=labium_angle=extension=0;cyc=math.tau*u
 body=Matrix.Translation(Vector((0,0,cfg['body_lift_units']+(cfg['breath_units']*math.sin(cyc) if clip=='idle' else 0))))
 arm.pose.bones['body'].matrix=body@rest['body'];bpy.context.view_layer.update()
 if clip=='windup':angle=cfg['head_windup_radians']*smooth(u);labium_angle=cfg['labium_windup_radians']*smooth(u)
 elif clip=='release':
  q=smooth(u/.25) if u<.25 else 1-smooth((u-.25)/.75);r=smooth((u-.25)/.75) if u>.25 else 0
  angle=cfg['head_windup_radians']*(1-r)+(cfg['head_followthrough_radians']-cfg['head_windup_radians'])*q
  labium_angle=cfg['labium_windup_radians']*(1-r)+(cfg['labium_release_radians']-cfg['labium_windup_radians'])*q
  extension=cfg['labium_extension_units']*q
 else:angle=.006*math.sin(cyc)
 head=body@pivot(cfg['head'],angle,'X');arm.pose.bones['head'].matrix=head@rest['head'];bpy.context.view_layer.update()
 arm.pose.bones['labium'].matrix=head@Matrix.Translation(Vector((0,-extension,0)))@pivot(cfg['labium'],labium_angle,'X')@rest['labium']
 abdomen=body
 for j in range(3):
  a=cfg['abdomen_flex_radians']*math.sin(cyc-j*.25) if clip in ['idle','walk'] else 0
  abdomen=abdomen@pivot(cfg['abdomen'][j],a,'X');arm.pose.bones['abdomen_'+str(j+1)].matrix=abdomen@rest['abdomen_'+str(j+1)];bpy.context.view_layer.update()
 for side,label in [(-1,'L'),(1,'R')]:
  n='antenna_'+label;a=cfg['antenna_sweep_radians']*math.sin(cyc+side*.6) if clip in ['idle','walk'] else -side*.03*smooth(u if clip=='windup' else 1-u)
  arm.pose.bones[n].matrix=head@pivot(arm.data.bones[n].head_local,a,'Z')@rest[n]
 bpy.context.view_layer.update()
 for leg in cfg['legs']:
  n=leg['name'];hip=body@Vector(leg['hip']);ankle=Vector(leg['ankle']);ankle.z-=leg['sole']
  if clip=='walk':
   phase=(u+leg['phase'])%1;duty=cfg['stance_fraction']
   if phase<duty:ankle.y-=cfg['step_units']*(.5-phase/duty)
   else:
    swing=(phase-duty)/(1-duty);ankle.y-=cfg['step_units']*(-.5+smooth(swing));ankle.z+=cfg['foot_lift_units']*math.sin(math.pi*swing)
  l1=(Vector(leg['knee'])-Vector(leg['hip'])).length;l2=(Vector(leg['ankle'])-Vector(leg['knee'])).length
  axis=ankle-hip;d=axis.length
  assert abs(l1-l2)+1e-5<d<l1+l2-1e-5,('Unreachable leg',clip,u,n,d,l1+l2)
  axis.normalize();along=(l1*l1-l2*l2+d*d)/(2*d);height=math.sqrt(max(0,l1*l1-along*along))
  original=Vector(leg['knee'])-Vector(leg['hip']);old_axis=(Vector(leg['ankle'])-Vector(leg['hip'])).normalized();pole=original-old_axis*original.dot(old_axis)
  bend=(pole-axis*pole.dot(axis)).normalized();knee=hip+axis*along+bend*height
  place(n+'_upper',hip,knee);place(n+'_lower',knee,ankle)
  foot=rest[n+'_foot'].copy();foot.translation=ankle;arm.pose.bones[n+'_foot'].matrix=foot;bpy.context.view_layer.update()
  errors.append((arm.pose.bones[n+'_foot'].head-ankle).length);length_errors.append(abs((knee-hip).length-l1)+abs((ankle-knee).length-l2))
 bpy.context.view_layer.update()
scene.render.fps=cfg['source_fps'];arm.animation_data_create();clips={n:cfg[n+'_duration'] for n in ['idle','walk','windup','release']}
for clip,duration in clips.items():
 action=bpy.data.actions.new(clip);arm.animation_data.action=action;end=round(duration*cfg['source_fps'])
 for frame in range(end+1):
  scene.frame_set(frame);pose(clip,frame/end)
  for pb in arm.pose.bones:
   pb.rotation_mode='QUATERNION'
   for field in ['location','rotation_quaternion','scale']:pb.keyframe_insert(field,frame=frame)
  if frame in {0,end//4,end//2,3*end//4,end}:
   evaluated=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get());pp=np.array([v.co[:] for v in evaluated.data.vertices])
   samples[f'{clip}:{frame}']={'bounds':[pp.min(0).tolist(),pp.max(0).tolist()]}
   assert np.isfinite(pp).all() and pp[:,2].min()>-.01,('Invalid/underground pose',clip,frame,float(pp[:,2].min()))
 track=arm.animation_data.nla_tracks.new();track.name=clip;strip=track.strips.new(clip,0,action);strip.action_slot=arm.animation_data.action_slot;strip.extrapolation='NOTHING';track.mute=True;arm.animation_data.action=None
for pb in arm.pose.bones:pb.matrix_basis=Matrix.Identity(4)
scene.frame_set(0)
counts=[len(v.groups) for v in mesh.data.vertices];sums=[sum(g.weight for g in v.groups) for v in mesh.data.vertices]
assert min(counts)>0 and max(counts)<=4 and max(abs(s-1) for s in sums)<1e-5
assert max(errors)<1e-5 and max(length_errors)<1e-5
assert not mesh.data.validate(verbose=True)
original=mesh.data.materials[0];fallback=bpy.data.materials.new('NymphHost_Bind_ART06C');fallback.use_nodes=True
bsdf=fallback.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Base Color'].default_value=(.1,.095,.09,1);bsdf.inputs['Roughness'].default_value=.8
mesh.data.materials[0]=fallback
bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);arm.select_set(True);bpy.context.view_layer.objects.active=arm
for track in arm.animation_data.nla_tracks:track.mute=False
bpy.ops.export_scene.gltf(filepath=str(runtime/'model.glb'),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_frame_range=False,export_anim_slide_to_zero=True,export_cameras=False,export_lights=False)
mesh.data.materials[0]=original
for track in arm.animation_data.nla_tracks:track.mute=True
for image in bpy.data.images:
 if image.source=='FILE' and image.has_data and not image.packed_file:image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(out/'bog_lurker-rigged.blend'),compress=True)
receipt=json.loads((source/'source-selection.json').read_text(encoding='utf-8-sig'));map_hashes={e['file']:e['sha256'] for e in receipt['files'] if e['file'].endswith('.png')}
for n,sha in map_hashes.items():
 shutil.copyfile(source/n,runtime/n);assert hashlib.sha256((runtime/n).read_bytes()).hexdigest()==sha
report=dict(stage='saved rig and export',source_triangles=len(host.data.polygons),runtime_triangles=len(mesh.data.loop_triangles),runtime_vertices=len(p),bones=bones,weighted_vertices=weighted,supported_abdomen_vertices=supported_abdomen,max_weights=max(counts),max_weight_error=max(abs(s-1) for s in sums),max_foot_target_error=max(errors),max_segment_length_error=max(length_errors),pose_samples=samples,clips_seconds=clips,baked_clips_seconds={n:round(v*cfg["source_fps"])/cfg["source_fps"] for n,v in clips.items()},settings=cfg,original_maps_sha256=map_hashes,source_bounds=[p.min(0).tolist(),p.max(0).tolist()],post_simplification_validation_changed=validation_changed,root_motion=False)
(out/'rig-report.json').write_text(json.dumps(report,indent=2)+'\n');shutil.copyfile(Path(__file__).parent/'rig.json',out/'rig.json')
print('MOB05_SOURCE_EXPORT_OK '+json.dumps({k:report[k] for k in ['runtime_triangles','runtime_vertices','max_weights','max_foot_target_error']}),flush=True)
