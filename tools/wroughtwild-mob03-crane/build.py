"""Fit the approved ART-06C crane, save a new packed master and export one skin.
Blender --background --python build.py -- NEW_SOURCE_VERSION
No renderer, gameplay integration or source-input mutation occurs here.
"""
import bpy, bmesh, json, math, sys, shutil
from pathlib import Path
import numpy as np
from mathutils import Matrix, Vector

REPO=Path(__file__).resolve().parents[2]
INPUT=Path('D:/Wroughtwild/source-art/mob03-crane/input-art06c')
OUT=Path(sys.argv[sys.argv.index('--')+1]).resolve()
assert OUT.parent==INPUT.parent and OUT!=INPUT and not OUT.exists()
OUT.mkdir()
CFG=json.loads((Path(__file__).parent/'rig.json').read_text(encoding='utf-8-sig'))
RUNTIME=REPO/'game/assets/authored/roster/shrieker'
RUNTIME.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(INPUT/'shrieker-surface.blend'))
scene=bpy.context.scene
source=bpy.data.objects['shrieker - surface host']
bpy.ops.object.select_all(action='DESELECT')
mesh=source.copy();mesh.data=source.data.copy();mesh.name='CraneBody'
scene.collection.objects.link(mesh);mesh.hide_set(False);mesh.hide_render=False
mesh.select_set(True);bpy.context.view_layer.objects.active=mesh
weld=mesh.modifiers.new('Weld coincident UV seam positions','WELD');weld.merge_threshold=1e-6
bpy.ops.object.modifier_apply(modifier=weld.name)
welded=len(mesh.data.vertices)
dec=mesh.modifiers.new('Single runtime surface','DECIMATE');dec.ratio=CFG['target_triangles']/len(mesh.data.polygons);dec.use_collapse_triangulate=True
bpy.ops.object.modifier_apply(modifier=dec.name)
source.hide_set(True);source.hide_render=True
# Open the existing fused beak along its actual central seam. The new lower
# surface remains weighted to the same head at its root, then to the jaw hinge.
bm=bmesh.new();bm.from_mesh(mesh.data)
bm.verts.ensure_lookup_table()
seen=set();duplicates=[]
for face in bm.faces:
 key=tuple(sorted(v.index for v in face.verts))
 if key in seen:duplicates.append(face)
 else:seen.add(key)
bmesh.ops.delete(bm,geom=duplicates,context='FACES_ONLY')
print('Removed duplicate collapse faces:',len(duplicates),flush=True)
def front(v):return v.co.y<-.535 and v.co.z>1.68
geom=[v for v in bm.verts if front(v)]
geom += [e for e in bm.edges if all(front(v) for v in e.verts)]
geom += [f for f in bm.faces if all(front(v) for v in f.verts)]
bmesh.ops.bisect_plane(bm,geom=geom,dist=1e-6,plane_co=(0,-.6,1.813),plane_no=(0,-.5,1),clear_inner=False,clear_outer=False)
for f in bm.faces:
 c=f.calc_center_median();f.select_set(c.y<-.55 and c.z>1.68 and c.z<2.113+.5*c.y-1e-5)
bm.to_mesh(mesh.data);bm.free()
bpy.context.tool_settings.mesh_select_mode=(False,False,True)
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.separate(type='SELECTED');bpy.ops.object.mode_set(mode='OBJECT')
jaw=next(o for o in bpy.context.selected_objects if o!=mesh);jaw.name='CraneLowerBeak'
assert 15<len(jaw.data.polygons)<1200
parts=[mesh,jaw]
for part in parts:
 repaired=part.data.validate(verbose=True)
 assert not repaired, ("Unexpected invalid mesh after seam repair",part.name)
 part.data.update()
 part.data.calc_loop_triangles()
 assert len(part.data.uv_layers)==1
 p=np.array([v.co[:] for v in part.data.vertices]);assert np.isfinite(p).all()
# Blender Z is up and -Y is forward; GLB becomes +Y up, +Z forward.
bones=[]
def bone(name,parent,head,tail):bones.append(dict(name=name,parent=parent,head=head,tail=tail))
bone('root',None,[0,0,0],[0,0,.2])
bone('body','root',[0,.08,1.02],[0,-.18,1.28])
bone('neck','body',[0,-.24,1.27],[0,-.40,1.61])
bone('upper_neck','neck',[0,-.40,1.61],[0,-.40,1.81])
bone('head','upper_neck',[0,-.40,1.81],[0,-.57,1.845])
bone('jaw','head',[0,-.535,1.837],[0,-.805,1.704])
bone('resonator','neck',[0,-.40,1.29],[0,-.51,1.53])
bone('tail','body',[0,.35,1.02],[0,.72,.65])
for side,x in [('L',-.17),('R',.17)]:bone('wing_'+side,'body',[x,-.07,1.28],[x,.43,.98])
feet=[]
for side,sign in [('L',-1),('R',1)]:
 hip=[sign*.115,-.005,.90];hock=[sign*.148,.049,.575];ankle=[sign*.218,.030,.105]
 bone('leg_'+side,'body',hip,hock);bone('shin_'+side,'leg_'+side,hock,ankle)
 bone('foot_'+side,'shin_'+side,ankle,[sign*.235,-.115,.04])
 feet.append(dict(side=side,hip=hip,hock=hock,ankle=ankle))
arm=bpy.data.objects.new('CraneRig',bpy.data.armatures.new('CraneAnatomy'))
scene.collection.objects.link(arm);bpy.ops.object.select_all(action='DESELECT');arm.select_set(True);bpy.context.view_layer.objects.active=arm
bpy.ops.object.mode_set(mode='EDIT')
for row in bones:
 eb=arm.data.edit_bones.new(row['name']);eb.head=row['head'];eb.tail=row['tail']
 if row['parent']:eb.parent=arm.data.edit_bones[row['parent']]
bpy.ops.object.mode_set(mode='OBJECT');arm.show_in_front=True

def smooth(v):
 v=float(np.clip(v,0,1));return v*v*(3-2*v)
def replace(w,name,f):
 for key in list(w):w[key]*=1-f
 w[name]=w.get(name,0)+f

def weight_part(obj):
 groups={r['name']:obj.vertex_groups.new(name=r['name']) for r in bones}
 p=np.array([v.co[:] for v in obj.data.vertices]);W=np.zeros((len(p),len(groups)))
 for i,(x,y,z) in enumerate(p):
  if obj==jaw:
   f=smooth((-.55-y)/.05);w={'head':1-f,'jaw':f}
  else:
   w={'body':1.0}
   n=smooth((z-1.12)/.25)*(1-smooth((y+.20)/.15));replace(w,'neck',n)
   u=smooth((z-1.48)/.20);replace(w,'upper_neck',u)
   h=smooth((z-1.69)/.10);replace(w,'head',h)
   # The forward air-sac follows the supporting neck with a gentle expansion.
   r=smooth((-.30-y)/.14)*smooth((z-1.11)/.16)*(1-smooth((z-1.52)/.15))*.80
   replace(w,'resonator',r)
   wing=smooth((abs(x)-.065)/.10)*smooth((y+.16)/.22)*smooth((z-.68)/.16)*(1-smooth((z-1.29)/.12))*.85
   replace(w,'wing_'+('L' if x<0 else 'R'),wing)
   tail=smooth((y-.39)/.27);replace(w,'tail',tail)
   leg=smooth((.99-z)/.18)*(1-smooth((y-.15)/.13))
   if leg:
    s='L' if x<0 else 'R';f=1-smooth((z-.095)/.065);upper=smooth((z-.50)/.15)*(1-f)
    for key in list(w):w[key]*=1-leg
    w['leg_'+s]=leg*upper;w['shin_'+s]=leg*(1-f-upper);w['foot_'+s]=leg*f
  for name,value in w.items():W[i,groups[name].index]=value
 # Smooth only across actual edges. Keep the skull, jaw and ground soles exact.
 if obj!=jaw:
  edges=np.array([e.vertices[:] for e in obj.data.edges],int)
  src=np.concatenate([edges[:,0],edges[:,1]]);dst=np.concatenate([edges[:,1],edges[:,0]])
  degree=np.bincount(src,minlength=len(p)).clip(1)[:,None]
  locked=(p[:,2]>1.80)|(p[:,2]<.10);original=W.copy()
  for _ in range(CFG['weight_smoothing_passes']):
   avg=np.stack([np.bincount(src,weights=W[dst,j],minlength=len(p)) for j in range(W.shape[1])],axis=1)
   W=.5*W+.5*avg/degree;W[locked]=original[locked]
 for i in range(len(p)):
  ids=np.argsort(W[i])[-4:];total=W[i,ids].sum();assert total>0
  for j in ids:
   value=float(W[i,j]/total)
   if value>1e-7:obj.vertex_groups[int(j)].add([i],value,'REPLACE')
 obj.parent=arm;mod=obj.modifiers.new('Fitted anatomical skin','ARMATURE');mod.object=arm
 return p
points={o.name:weight_part(o) for o in parts}
rest={b.name:b.matrix_local.copy() for b in arm.data.bones}
rows={b['name']:b for b in bones}
def pivot(name,angle):
 at=Vector(rows[name]['head']);return Matrix.Translation(at)@Matrix.Rotation(angle,4,'X')@Matrix.Translation(-at)
def aimed(name,h,t):
 r=Vector(rows[name]['tail'])-Vector(rows[name]['head'])
 m=r.rotation_difference(t-h).to_matrix().to_4x4()@rest[name];m.translation=h;return m
def setm(name,m):
 arm.pose.bones[name].matrix=m;bpy.context.view_layer.update()
errors=[]
def pose(clip,u):
 for pb in arm.pose.bones:pb.matrix_basis=Matrix.Identity(4)
 bpy.context.view_layer.update()
 call=0.0
 if clip=='call':
  if u<.16:call=smooth(u/.16)
  elif u<.54:call=1-.04*math.sin((u-.16)/.38*math.tau)
  else:call=1-smooth((u-.54)/.46)
 neck=CFG['call_neck_radians']*call
 head=CFG['call_head_radians']*call
 if clip=='windup':neck=CFG['windup_neck_radians']*smooth(u)
 if clip=='release':
  neck=CFG['windup_neck_radians']*(1-smooth(min(u/.2,1)))+CFG['peck_neck_radians']*math.sin(math.pi*u)
  head=.13*math.sin(math.pi*u)
 rise=CFG['breath_units']*math.sin(math.tau*u) if clip=='idle' else 0.0
 body=Matrix.Translation((0,0,-CFG['stance_sink_units']+rise))
 setm('root',rest['root']);setm('body',body@rest['body'])
 nd=body@pivot('neck',neck);setm('neck',nd@rest['neck'])
 ud=nd@pivot('upper_neck',neck*.35);setm('upper_neck',ud@rest['upper_neck'])
 hd=ud@pivot('head',head);setm('head',hd@rest['head'])
 setm('jaw',hd@pivot('jaw',CFG['call_jaw_radians']*call)@rest['jaw'])
 rp=Vector(rows['resonator']['head'])
 scale=Matrix.Diagonal((1+CFG['call_throat_expansion']*call,1+CFG['call_throat_expansion']*call*.5,1.0,1.0))
 setm('resonator',nd@Matrix.Translation(rp)@scale@Matrix.Translation(-rp)@rest['resonator'])
 for name in ['tail','wing_L','wing_R']:setm(name,body@rest[name])
 for f in feet:
  s=f['side'];hip=body@Vector(f['hip']);target=Vector(f['ankle'])
  if clip=='walk':
   phase=(u+(0 if s=='L' else .5))%1;stance=CFG['walk_stance_fraction']
   if phase<stance:target.y+=CFG['walk_foot_travel_units']*(phase/stance-.5)
   else:
    sw=(phase-stance)/(1-stance);target.y+=CFG['walk_foot_travel_units']*(.5-smooth(sw));target.z+=CFG['walk_foot_lift_units']*math.sin(math.pi*sw)
  l1=(Vector(f['hock'])-Vector(f['hip'])).length;l2=(Vector(f['ankle'])-Vector(f['hock'])).length
  v=target-hip;d=v.length;assert d<l1+l2,('Unreachable target',clip,u,s,d,l1+l2)
  along=v.normalized();a=(l1*l1-l2*l2+d*d)/(2*d);height=math.sqrt(max(0,l1*l1-a*a))
  bend=Vector((0,1,0));bend=(bend-along*bend.dot(along)).normalized();hock=hip+along*a+bend*height
  setm('leg_'+s,aimed('leg_'+s,hip,hock));setm('shin_'+s,aimed('shin_'+s,hock,target))
  fm=rest['foot_'+s].copy();fm.translation=target;setm('foot_'+s,fm)
  errors.append((arm.pose.bones['foot_'+s].head-target).length)
 bpy.context.view_layer.update()

clips={'idle':4.0,'walk':1.2,'windup':.5,'release':.3,'call':1.25}
scene.render.fps=CFG['fps'];arm.animation_data_create();actions={}
for clip,duration in clips.items():
 act=bpy.data.actions.new(clip);actions[clip]=act;arm.animation_data.action=act
 for frame in range(round(duration*CFG['fps'])+1):
  scene.frame_set(frame);pose(clip,frame/(duration*CFG['fps']))
  for pb in arm.pose.bones:
   pb.rotation_mode='QUATERNION'
   for channel in ['location','rotation_quaternion','scale']:pb.keyframe_insert(channel,frame=frame)
 track=arm.animation_data.nla_tracks.new();track.name=clip
 strip=track.strips.new(clip,0,act);strip.action_slot=arm.animation_data.action_slot;strip.extrapolation='NOTHING';track.mute=True
 arm.animation_data.action=None
assert max(errors)<1e-5
# Sample meaningful deformed vertices in this single source validation job.
validation=[]
for clip,u in [('idle',0),('walk',.12),('walk',.72),('windup',1),('release',.3),('call',.30),('call',1)]:
 pose(clip,u);dg=bpy.context.evaluated_depsgraph_get()
 for obj in parts:
  ev=obj.evaluated_get(dg);m=ev.to_mesh();p=np.array([v.co[:] for v in m.vertices]);ev.to_mesh_clear()
  assert np.isfinite(p).all();assert p[:,2].min()>-.015,(clip,obj.name,p[:,2].min())
  validation.append({'clip':clip,'phase':u,'mesh':obj.name,'bounds':[p.min(0).tolist(),p.max(0).tolist()]})
# Safe nonemissive GLB material fallback; runtime binds original ART-06C maps.
authored=mesh.data.materials[0]
fallback=bpy.data.materials.new('Crane PBR fallback');fallback.use_nodes=True
bsdf=fallback.node_tree.nodes.get('Principled BSDF')
for filename in ['base.png','orm.png','scar-mask.png']:shutil.copy2(INPUT/filename,RUNTIME/filename)
base=fallback.node_tree.nodes.new('ShaderNodeTexImage');base.image=bpy.data.images.load(str(INPUT/'base.png'),check_existing=True)
fallback.node_tree.links.new(base.outputs['Color'],bsdf.inputs['Base Color'])
orm=fallback.node_tree.nodes.new('ShaderNodeTexImage');orm.image=bpy.data.images.load(str(INPUT/'orm.png'),check_existing=True);orm.image.colorspace_settings.name='Non-Color'
sep=fallback.node_tree.nodes.new('ShaderNodeSeparateColor');fallback.node_tree.links.new(orm.outputs['Color'],sep.inputs['Color'])
fallback.node_tree.links.new(sep.outputs['Green'],bsdf.inputs['Roughness']);fallback.node_tree.links.new(sep.outputs['Blue'],bsdf.inputs['Metallic'])
for o in parts:o.data.materials[0]=fallback
# Rest skeleton stays at the approved geometry. Every clip contains its full pose.
for pb in arm.pose.bones:pb.matrix_basis=Matrix.Identity(4)
scene.frame_set(0);bpy.context.view_layer.update()
bpy.ops.object.select_all(action='DESELECT');arm.select_set(True)
for o in parts:o.select_set(True)
for tr in arm.animation_data.nla_tracks:tr.mute=False
bpy.ops.export_scene.gltf(filepath=str(RUNTIME/'model.glb'),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_frame_range=False,export_anim_slide_to_zero=True,export_cameras=False,export_lights=False)
for tr in arm.animation_data.nla_tracks:tr.mute=True
for o in parts:o.data.materials[0]=authored
pose('idle',0)
for im in bpy.data.images:
 if im.source=='FILE' and im.has_data:im.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'shrieker-rigged.blend'),compress=True)
report={'enemy_id':'shrieker','source_receipt':str(INPUT/'source-selection.json'),'editable_master':str(OUT/'shrieker-rigged.blend'),'blender':bpy.app.version_string,'source_triangles':296116,'welded_vertices':welded,'parts':[], 'bones':bones,'clips_seconds':clips,'max_foot_target_error_units':max(errors),'sampled_poses':validation,'passed':True}
for o in parts:
 o.data.calc_loop_triangles();counts=[len(v.groups) for v in o.data.vertices]
 assert min(counts)>0 and max(counts)<=4
 assert all(abs(sum(g.weight for g in v.groups)-1)<1e-5 for v in o.data.vertices)
 report['parts'].append({'name':o.name,'vertices':len(o.data.vertices),'triangles':len(o.data.loop_triangles),'max_weights':max(counts)})
report['triangles']=sum(r['triangles'] for r in report['parts'])
(OUT/'rig-report.json').write_text(json.dumps(report,indent=2)+'\n')
shutil.copy2(Path(__file__),OUT/'build.py');shutil.copy2(Path(__file__).parent/'rig.json',OUT/'rig.json')
(REPO/'build/mob03/evidence/rig-report.json').write_text(json.dumps(report,indent=2)+'\n')
print('MOB03_SOURCE_OK',report['triangles'],max(errors),flush=True)
