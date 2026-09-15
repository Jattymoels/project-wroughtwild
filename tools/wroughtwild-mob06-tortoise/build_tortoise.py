"""Fit the approved ART-06C tortoise. Never overwrite a source master.
Blender --background --python build_tortoise.py -- INPUT NEW_MASTER RUNTIME
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
bpy.ops.wm.open_mainfile(filepath=str(source/'hollow_knight-surface.blend'))
scene=bpy.context.scene;host=bpy.data.objects['hollow_knight - surface host']
bpy.ops.object.select_all(action='DESELECT')
mesh=host.copy();mesh.data=host.data.copy();mesh.name='TortoiseSkin';scene.collection.objects.link(mesh)
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
bone('neck',cfg['neck'],cfg['neck_tip'],'body');bone('head',cfg['head'],cfg['head_tip'],'neck')
bone('tail',cfg['tail'],cfg['tail_tip'],'body')
for leg in cfg['legs']:
 n=leg['name'];bone(n+'_upper',leg['hip'],leg['knee'],'body');bone(n+'_lower',leg['knee'],leg['ankle'],n+'_upper');bone(n+'_foot',leg['ankle'],leg['toe'],n+'_lower')
 q=p[(p[:,0]*leg['side']>.28)&(p[:,2]<.12)]
 q=q[(q[:,1]<-.2) if leg['kind']=='fore' else (q[:,1]>.3)]
 assert len(q)>30,('Missing foot',n);leg['sole']=float(q[:,2].min())
arm=bpy.data.objects.new('TortoiseRig',bpy.data.armatures.new('TortoiseAnatomy'));scene.collection.objects.link(arm)
arm.select_set(True);bpy.context.view_layer.objects.active=arm;bpy.ops.object.mode_set(mode='EDIT')
for b in bones:
 e=arm.data.edit_bones.new(b['name']);e.head=b['head'];e.tail=b['tail']
 if b['parent']:e.parent=arm.data.edit_bones[b['parent']]
bpy.ops.object.mode_set(mode='OBJECT');arm.show_in_front=True
groups={b['name']:mesh.vertex_groups.new(name=b['name']) for b in bones}
def smooth(x):x=max(0,min(1,x));return x*x*(3-2*x)
def segment(q,a,b):
 a=np.array(a);d=np.array(b)-a;t=float(np.clip(np.dot(q-a,d)/np.dot(d,d),0,1));return float(np.linalg.norm(q-(a+t*d))),t
rigid_shell=0;weighted={k:0 for k in groups}
for i,q in enumerate(p):
 x,y,z=q;w={'body':1.0}
 # Region gates keep the layered mantle/scutes on the body. The neck is
 # supported at its source opening; leg weights cannot leak through cavities.
 neck=smooth((-.56-y)/.14)*(1-smooth((abs(x)-.17)/.07))*smooth((z-.45)/.12)
 if neck:
  head=smooth((-.77-y)/.09)*smooth((z-.75)/.09)
  w={'body':1-neck,'neck':neck*(1-head),'head':neck*head}
 tail=smooth((y-.74)/.12)*(1-smooth((abs(x)-.12)/.08))*(1-smooth((z-.27)/.055))
 if tail:w={'body':1-tail,'tail':tail}
 if abs(x)>.27 and z<.39 and (y<-.21 or y>.29):
  leg=next(l for l in cfg['legs'] if l['side']*x>0 and l['kind']==('fore' if y<0 else 'hind'))
  n=leg['name']
  influence=smooth((abs(x)-.27)/.09)*(1-smooth((z-.30)/.09))
  # Foot remains rigid across its sole, upper/lower transition follows height.
  if z<.11:lw={n+'_foot':1.0};influence=1.0
  elif z<.18:
   a=smooth((z-.11)/.07);lw={n+'_foot':1-a,n+'_lower':a}
  elif z<.29:
   a=smooth((z-.20)/.09);lw={n+'_lower':1-a,n+'_upper':a}
  else:lw={n+'_upper':1.0}
  w={k:v*(1-influence) for k,v in w.items()}
  for k,v in lw.items():w[k]=w.get(k,0)+v*influence
 if z>=.39 and y>=-.56:
  assert w=={'body':1.0};rigid_shell+=1
 keep=sorted([(k,v) for k,v in w.items() if v>1e-7],key=lambda kv:-kv[1])[:4];total=sum(v for k,v in keep)
 assert total>0
 for k,v in keep:groups[k].add([i],float(v/total),'REPLACE');weighted[k]+=1
assert all(weighted[leg['name']+'_'+part]>20 for leg in cfg['legs'] for part in ['upper','lower','foot'])
assert all(weighted[k]>10 for k in ['body','neck','head','tail'])
mesh.parent=arm;mod=mesh.modifiers.new('Fitted tortoise joints','ARMATURE');mod.object=arm
rest={b.name:b.matrix_local.copy() for b in arm.data.bones}
def pivot(p,a,axis):return Matrix.Translation(Vector(p))@Matrix.Rotation(a,4,axis)@Matrix.Translation(-Vector(p))
def place(n,h,t):
 b=arm.data.bones[n];m=(b.tail_local-b.head_local).rotation_difference(t-h).to_matrix().to_4x4()@rest[n];m.translation=h
 arm.pose.bones[n].matrix=m;bpy.context.view_layer.update()
errors=[];length_errors=[];samples={}
def pose(clip,u):
 for pb in arm.pose.bones:pb.matrix_basis=Matrix.Identity(4)
 cyc=math.tau*u;neck_angle=cfg['neck_idle_radians']*math.sin(cyc);head_angle=-neck_angle*.4
 body=Matrix.Translation(Vector((0,0,cfg['body_lift_units']+(cfg['breath_units']*math.sin(cyc) if clip=='idle' else 0))))
 arm.pose.bones['body'].matrix=body@rest['body'];bpy.context.view_layer.update()
 if clip=='windup':neck_angle=cfg['neck_windup_radians']*smooth(u);head_angle=cfg['head_windup_radians']*smooth(u)
 elif clip=='release':
  q=smooth(u/.25) if u<.25 else 1-smooth((u-.25)/.75);r=smooth((u-.25)/.75) if u>.25 else 0
  neck_angle=cfg['neck_windup_radians']*(1-r)+(cfg['neck_release_radians']-cfg['neck_windup_radians'])*q
  head_angle=cfg['head_windup_radians']*(1-r)+(cfg['head_release_radians']-cfg['head_windup_radians'])*q
 neck=body@pivot(cfg['neck'],neck_angle,'X');arm.pose.bones['neck'].matrix=neck@rest['neck'];bpy.context.view_layer.update()
 arm.pose.bones['head'].matrix=neck@pivot(cfg['head'],head_angle,'X')@rest['head']
 tail_angle=cfg['tail_sway_radians']*math.sin(cyc) if clip in ['idle','walk'] else 0
 arm.pose.bones['tail'].matrix=body@pivot(cfg['tail'],tail_angle,'Z')@rest['tail'];bpy.context.view_layer.update()
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
original=mesh.data.materials[0];fallback=bpy.data.materials.new('TortoiseHost_Bind_ART06C');fallback.use_nodes=True
bsdf=fallback.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Base Color'].default_value=(.1,.095,.09,1);bsdf.inputs['Roughness'].default_value=.8
mesh.data.materials[0]=fallback
bpy.ops.object.select_all(action='DESELECT');mesh.select_set(True);arm.select_set(True);bpy.context.view_layer.objects.active=arm
for track in arm.animation_data.nla_tracks:track.mute=False
bpy.ops.export_scene.gltf(filepath=str(runtime/'model.glb'),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_frame_range=False,export_anim_slide_to_zero=True,export_cameras=False,export_lights=False)
mesh.data.materials[0]=original
for track in arm.animation_data.nla_tracks:track.mute=True
for image in bpy.data.images:
 if image.source=='FILE' and image.has_data and not image.packed_file:image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(out/'hollow_knight-rigged.blend'),compress=True)
receipt=json.loads((source/'source-selection.json').read_text(encoding='utf-8-sig'));map_hashes={e['file']:e['sha256'] for e in receipt['files'] if e['file'].endswith('.png')}
for n,sha in map_hashes.items():
 shutil.copyfile(source/n,runtime/n);assert hashlib.sha256((runtime/n).read_bytes()).hexdigest()==sha
report=dict(stage='saved rig and export',source_triangles=len(host.data.polygons),runtime_triangles=len(mesh.data.loop_triangles),runtime_vertices=len(p),bones=bones,weighted_vertices=weighted,rigid_shell_vertices=rigid_shell,max_weights=max(counts),max_weight_error=max(abs(s-1) for s in sums),max_foot_target_error=max(errors),max_segment_length_error=max(length_errors),pose_samples=samples,clips_seconds=clips,baked_clips_seconds={n:round(v*cfg["source_fps"])/cfg["source_fps"] for n,v in clips.items()},settings=cfg,original_maps_sha256=map_hashes,source_bounds=[p.min(0).tolist(),p.max(0).tolist()],post_simplification_validation_changed=validation_changed,root_motion=False)
(out/'rig-report.json').write_text(json.dumps(report,indent=2)+'\n');shutil.copyfile(Path(__file__).parent/'rig.json',out/'rig.json')
print('MOB06_SOURCE_EXPORT_OK '+json.dumps({k:report[k] for k in ['runtime_triangles','runtime_vertices','max_weights','max_foot_target_error']}),flush=True)
