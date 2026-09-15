"""Fit the approved ART-06C beetle. Never overwrite a source master.
Blender --background --python build_beetle.py -- INPUT NEW_MASTER RUNTIME
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
bpy.ops.wm.open_mainfile(filepath=str(source/'gloom_crawler-surface.blend'))
scene=bpy.context.scene;host=bpy.data.objects['gloom_crawler - surface host']
bpy.ops.object.select_all(action='DESELECT')
mesh=host.copy();mesh.data=host.data.copy();mesh.name='BeetleSkin';scene.collection.objects.link(mesh)
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
bone('root',[0,0,0],[0,0,.15]);bone('body',cfg['body'],[0,.46,.44],'root')
bone('head',cfg['head'],cfg['head_tip'],'body')
for side,label in [(-1,'L'),(1,'R')]:
 bone('mandible_'+label,[side*.12,.80,.34],[side*.105,.91,.25],'head')
 bone('antenna_'+label,[side*.21,.755,.485],[side*.48,.90,.48],'head')
for leg in cfg['legs']:
 n=leg['name'];bone(n+'_upper',leg['hip'],leg['knee'],'body');bone(n+'_lower',leg['knee'],leg['ankle'],n+'_upper');bone(n+'_foot',leg['ankle'],leg['toe'],n+'_lower')
 q=p[(p[:,0]*leg['side']>.45)&(p[:,2]<.065)]
 q=q[(q[:,1]>.55) if leg['kind']=='fore' else ((q[:,1]>.0)&(q[:,1]<.35)) if leg['kind']=='mid' else (q[:,1]<-.3)]
 assert len(q)>30,('Missing foot',n);leg['sole']=float(q[:,2].min())
arm=bpy.data.objects.new('BeetleRig',bpy.data.armatures.new('BeetleAnatomy'));scene.collection.objects.link(arm)
arm.select_set(True);bpy.context.view_layer.objects.active=arm;bpy.ops.object.mode_set(mode='EDIT')
for b in bones:
 e=arm.data.edit_bones.new(b['name']);e.head=b['head'];e.tail=b['tail']
 if b['parent']:e.parent=arm.data.edit_bones[b['parent']]
bpy.ops.object.mode_set(mode='OBJECT');arm.show_in_front=True
groups={b['name']:mesh.vertex_groups.new(name=b['name']) for b in bones}
def smooth(x):x=max(0,min(1,x));return x*x*(3-2*x)
def segment(q,a,b):
 a=np.array(a);d=np.array(b)-a;t=float(np.clip(np.dot(q-a,d)/np.dot(d,d),0,1));return float(np.linalg.norm(q-(a+t*d))),t
locked_shell=0;weighted={k:0 for k in groups}
for i,q in enumerate(p):
 x,y,z=q;w={'body':1.0}
 head=smooth((y-.58)/.15)*(1-smooth((abs(x)-.27)/.09))
 if head:w={'body':1-head,'head':head}
 # Shell, exposed lamellae and their roots remain rigid together. Limb envelopes
 # are below the elytra and outside the body, never nearest-bone through a shell.
 if z<.48:
  candidates=[]
  for leg in cfg['legs']:
   if x*leg['side']<=0:continue
   segments=[segment(q,leg[a],leg[b]) for a,b in [('hip','knee'),('knee','ankle'),('ankle','toe')]]
   j=min(range(3),key=lambda j:segments[j][0]);candidates.append((segments[j][0],leg,j,segments[j][1]))
  distance,leg,j,t=min(candidates,key=lambda v:v[0]);n=leg['name']
  extent=smooth((abs(x)-abs(leg['hip'][0])+.045)/.14)
  influence=extent*(1-smooth((distance-.065)/.065))*(1-smooth((z-.40)/.08))
  if influence>0:
   lw={n+['_upper','_lower','_foot'][j]:1.0}
   if j==0 and t>.72:lw={n+'_upper':1-smooth((t-.72)/.28)*.5,n+'_lower':smooth((t-.72)/.28)*.5}
   elif j==1 and t<.2:lw={n+'_upper':.5*(1-smooth(t/.2)),n+'_lower':.5+.5*smooth(t/.2)}
   elif j==1 and t>.82:lw={n+'_lower':1-smooth((t-.82)/.18)*.5,n+'_foot':smooth((t-.82)/.18)*.5}
   elif j==2 and t<.15:lw={n+'_lower':.5*(1-smooth(t/.15)),n+'_foot':.5+.5*smooth(t/.15)}
   if z<.11 and distance<.12:influence=1;lw={n+'_foot':1}
   w={k:v*(1-influence) for k,v in w.items()}
   for k,v in lw.items():w[k]=w.get(k,0)+v*influence
 # Source antennae are raised lateral branches; mandibles are central and lower.
 if y>.755 and z>.435 and z<.57 and abs(x)>.19:
  a=smooth((abs(x)-.19)/.09)*smooth((y-.755)/.045)
  w={k:v*(1-a) for k,v in w.items()};w['antenna_'+('L' if x<0 else 'R')]=a
 if y>.80 and z<.375 and abs(x)<.245:
  a=smooth((y-.80)/.055)*smooth((.375-z)/.06)
  w={k:v*(1-a) for k,v in w.items()};w['mandible_'+('L' if x<0 else 'R')]=a
 if y<.55 and z>.49:w={'body':1.0};locked_shell+=1
 keep=sorted([(k,v) for k,v in w.items() if v>1e-7],key=lambda kv:-kv[1])[:4];total=sum(v for k,v in keep)
 assert total>0
 for k,v in keep:groups[k].add([i],float(v/total),'REPLACE');weighted[k]+=1
assert all(weighted[leg['name']+'_'+part]>20 for leg in cfg['legs'] for part in ['upper','lower','foot'])
assert all(weighted[k]>10 for k in ['antenna_L','antenna_R','mandible_L','mandible_R'])
mesh.parent=arm;mod=mesh.modifiers.new('Fitted beetle joints','ARMATURE');mod.object=arm
rest={b.name:b.matrix_local.copy() for b in arm.data.bones}
def pivot(p,a,axis):return Matrix.Translation(Vector(p))@Matrix.Rotation(a,4,axis)@Matrix.Translation(-Vector(p))
def place(n,h,t):
 b=arm.data.bones[n];m=(b.tail_local-b.head_local).rotation_difference(t-h).to_matrix().to_4x4()@rest[n];m.translation=h
 arm.pose.bones[n].matrix=m;bpy.context.view_layer.update()
errors=[];length_errors=[];samples={}
def pose(clip,u):
 for pb in arm.pose.bones:pb.matrix_basis=Matrix.Identity(4)
 angle=jaw=0;cyc=math.tau*u
 body=Matrix.Translation(Vector((0,0,-cfg['stance_sink_units']+(cfg['breath_units']*math.sin(cyc) if clip=='idle' else 0))))
 arm.pose.bones['body'].matrix=body@rest['body'];bpy.context.view_layer.update()
 if clip=='windup':angle=cfg['head_windup_radians']*smooth(u);jaw=cfg['mandible_open_radians']*smooth(u)
 elif clip=='release':
  q=smooth(u/.22) if u<.22 else 1-smooth((u-.22)/.78);r=smooth((u-.22)/.78) if u>.22 else 0
  angle=cfg['head_windup_radians']*(1-r)+(cfg['head_followthrough_radians']-cfg['head_windup_radians'])*q
  jaw=cfg['mandible_open_radians']*(1-r)+(cfg['mandible_close_radians']-cfg['mandible_open_radians'])*q
 else:angle=.008*math.sin(cyc)
 head=body@pivot(cfg['head'],angle,'X');arm.pose.bones['head'].matrix=head@rest['head'];bpy.context.view_layer.update()
 for side,label in [(-1,'L'),(1,'R')]:
  n='mandible_'+label;arm.pose.bones[n].matrix=head@pivot(arm.data.bones[n].head_local,-side*jaw,'Z')@rest[n]
  n='antenna_'+label;a=cfg['antenna_sweep_radians']*math.sin(cyc+side*.6) if clip in ['idle','walk'] else -side*.045*smooth(u if clip=='windup' else 1-u)
  arm.pose.bones[n].matrix=head@pivot(arm.data.bones[n].head_local,a,'Z')@rest[n]
 bpy.context.view_layer.update()
 for leg in cfg['legs']:
  n=leg['name'];hip=body@Vector(leg['hip']);ankle=Vector(leg['ankle']);ankle.z-=leg['sole']
  if clip=='walk':
   phase=(u+leg['phase'])%1;duty=cfg['stance_fraction']
   if phase<duty:ankle.y+=cfg['step_units']*(.5-phase/duty)
   else:
    swing=(phase-duty)/(1-duty);ankle.y+=cfg['step_units']*(-.5+smooth(swing));ankle.z+=cfg['foot_lift_units']*math.sin(math.pi*swing)
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
original=mesh.data.materials[0];fallback=bpy.data.materials.new('BeetleHost_Bind_ART06C');fallback.use_nodes=True
bsdf=fallback.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Base Color'].default_value=(.1,.095,.09,1);bsdf.inputs['Roughness'].default_value=.8
mesh.data.materials[0]=fallback
bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);arm.select_set(True);bpy.context.view_layer.objects.active=arm
for track in arm.animation_data.nla_tracks:track.mute=False
bpy.ops.export_scene.gltf(filepath=str(runtime/'model.glb'),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_frame_range=False,export_anim_slide_to_zero=True,export_cameras=False,export_lights=False)
mesh.data.materials[0]=original
for track in arm.animation_data.nla_tracks:track.mute=True
for image in bpy.data.images:
 if image.source=='FILE' and image.has_data and not image.packed_file:image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(out/'gloom_crawler-rigged.blend'),compress=True)
receipt=json.loads((source/'source-selection.json').read_text(encoding='utf-8-sig'));map_hashes={e['file']:e['sha256'] for e in receipt['files'] if e['file'].endswith('.png')}
for n,sha in map_hashes.items():
 shutil.copyfile(source/n,runtime/n);assert hashlib.sha256((runtime/n).read_bytes()).hexdigest()==sha
report=dict(stage='saved rig and export',source_triangles=len(host.data.polygons),runtime_triangles=len(mesh.data.loop_triangles),runtime_vertices=len(p),bones=bones,weighted_vertices=weighted,rigid_shell_vertices=locked_shell,max_weights=max(counts),max_weight_error=max(abs(s-1) for s in sums),max_foot_target_error=max(errors),max_segment_length_error=max(length_errors),pose_samples=samples,clips_seconds=clips,baked_clips_seconds={n:round(v*cfg["source_fps"])/cfg["source_fps"] for n,v in clips.items()},settings=cfg,original_maps_sha256=map_hashes,source_bounds=[p.min(0).tolist(),p.max(0).tolist()],post_simplification_validation_changed=validation_changed,root_motion=False)
(out/'rig-report.json').write_text(json.dumps(report,indent=2)+'\n');shutil.copyfile(Path(__file__).parent/'rig.json',out/'rig.json')
print('MOB04_SOURCE_EXPORT_OK '+json.dumps({k:report[k] for k in ['runtime_triangles','runtime_vertices','max_weights','max_foot_target_error']}),flush=True)
