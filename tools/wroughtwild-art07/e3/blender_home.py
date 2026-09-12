"""E3 metric direct modelling. Reuses verified D4/5/6 maps without editing them.
Blender (x,y,z) -> Godot (x,z,-y), front -Y -> +Z. Real hollow chests,
backed joints, separate supported hinge/lid, split solid fuel and inert ash.
"""
import bpy, bmesh, json, math, random, sys
from pathlib import Path
from mathutils import Vector
CFG=json.loads(Path(__file__).with_name('appearance.json').read_text())
ARGS=sys.argv[sys.argv.index('--')+1:]
CHESTS=['wood','pine','bog_oak','ash_wood','resinheart','iron','bronze','steel']
FUELS=['wood','pine','bog_oak','ash_wood','charcoal']

def clean():
 # Operator selection skips hidden reference/runtime collections in a master.
 # Remove every object explicitly before measuring one imported GLB.
 for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
 for c in list(bpy.data.collections):bpy.data.collections.remove(c)
def coll(name):
 c=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(c);return c
def material(name,stem=None,metal=False,color=(1,1,1,1)):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=color;p.inputs['Roughness'].default_value=.8;p.inputs['Metallic'].default_value=float(metal)
 if stem:
  n=m.node_tree.nodes;l=m.node_tree.links
  for channel in ['albedo','normal','orm']:
   im=bpy.data.images.load(str(TEXTURES/f'{stem}_{channel}.png'),check_existing=True)
   if channel!='albedo':im.colorspace_settings.name='Non-Color'
   t=n.new('ShaderNodeTexImage');t.image=im
   if channel=='albedo':l.new(t.outputs[0],p.inputs['Base Color'])
   elif channel=='normal':
    q=n.new('ShaderNodeNormalMap');q.inputs['Strength'].default_value=CFG['normal_strength'];l.new(t.outputs[0],q.inputs['Color']);l.new(q.outputs[0],p.inputs['Normal'])
   else:
    q=n.new('ShaderNodeSeparateColor');l.new(t.outputs[0],q.inputs[0]);l.new(q.outputs['Green'],p.inputs['Roughness'])
 return m
def finish(o,name,c,m,bevel=CFG['worked_edge_m'],grain=None):
 o.name=name
 for old in list(o.users_collection):old.objects.unlink(o)
 c.objects.link(o);o.data.materials.append(m)
 bpy.context.view_layer.objects.active=o;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  q=o.modifiers.new('Worn arris','BEVEL');q.width=bevel;q.segments=2;bpy.ops.object.modifier_apply(modifier=q.name)
 me=o.data
 while me.uv_layers:me.uv_layers.remove(me.uv_layers[0])
 uv=me.uv_layers.new(name='Metric grain')
 timber=m.name.startswith('d4_');axis=grain if grain is not None else max(range(3),key=lambda a:o.dimensions[a])
 if timber:me.materials.append(MATS[m.name.replace('_face','_edge')])
 for f in me.polygons:
  normal=max(range(3),key=lambda a:abs(f.normal[a]));axes=[a for a in range(3) if a!=normal];sign=1 if f.normal[normal]>=0 else -1
  end=timber and abs(f.normal[axis])>.9
  if end:f.material_index=1
  for li in f.loop_indices:
   v=me.vertices[me.loops[li].vertex_index].co
   if timber and not end:
    cross=next(a for a in axes if a!=axis);u=v[cross]*sign/.5;w=v[axis]/2
   else:u=v[axes[0]]*sign/.5;w=v[axes[1]]/.5
   uv.data[li].uv=(u+.173,w+.287)
 bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);o.select_set(False);return o
def box(name,p,d,c,m,bevel=CFG['worked_edge_m'],grain=None):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.scale=d;return finish(o,name,c,m,bevel,grain)
def rod(name,a,b,r,c,m,n=12):
 a,b=Vector(a),Vector(b);delta=b-a
 bpy.ops.mesh.primitive_cylinder_add(vertices=n,radius=r,depth=delta.length,location=(a+b)/2);o=bpy.context.object;o.rotation_euler=delta.to_track_quat('Z','Y').to_euler();return finish(o,name,c,m,0)
def mesh(name,vs,faces,c,m):
 me=bpy.data.meshes.new(name);me.from_pydata(vs,[],faces);me.update()
 bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
 o=bpy.data.objects.new(name,me);c.objects.link(o);bpy.context.view_layer.objects.active=o;o.select_set(True);return finish(o,name,c,m,0)
def chest(family):
 c=coll('FINISHED_chest_'+family);l=coll('LID_'+family)
 timber=family not in ['iron','bronze','steel'];m=MATS['d4_'+family+'_face'] if timber else MATS['d6_'+family];hardware=MATS['d6_iron'] if timber else m
 # All faces close a true cavity; no content proxy or counterfeit inventory.
 box('Bottom',(0,0,-.473),(.96,.752,.054),c,m,grain=0)
 for row in range(4):
  z=-.407+row*.133
  for y in [-.369,.369]:box('FrontBackBoard',(0,y,z),(.98,.062,.133-CFG['plank_gap_m']),c,m,grain=0)
  for x in [-.469,.469]:box('EndBoard',(x,0,z),(.062,.676,.133-CFG['plank_gap_m']),c,m,grain=1)
 # Same-family joinery keeps framing plausible without implying extra ingredients.
 for x in [-.471,.471]:
  for y in [-.368,.368]:box('CornerPost',(x,y,-.205),(.058,.064,.57),c,m,grain=2)
 for x in [-.368,.368]:
  for y in [-.394,.394]:box('BoundStrap',(x,y,-.213),(.051,.012,.554),c,hardware,.001)
 for y in [-.343,.343]:box('InnerRim',(0,y,.054),(.865,.025,.024),c,m,grain=0)
 for x in [-.435,.435]:box('InnerRim',(x,0,.054),(.025,.68,.024),c,m,grain=1)
 # Fitted low lid, individual planks and underside battens. Exported separately.
 for j in range(5):box('LidBoard',(0,-.314+j*.157,.161),(.994,.157-CFG['plank_gap_m'],.078),l,m,grain=0)
 # Inset lid lip meets the inner rim with 1 mm closing clearance. It backs
 # the visible edge gap without intersecting the posts or widening the body.
 for y in [-.330,.330]:box('InsetLidLip',(0,y,.0945),(.874,.014,.055),l,m,.001,grain=0)
 for x in [-.430,.430]:box('InsetLidLip',(x,0,.0945),(.014,.646,.055),l,m,.001,grain=1)
 for x in [-.37,.37]:
  box('LidBand',(x,0,.196),(.054,.793,.008),l,hardware,.001)
  box('UnderLidBatten',(x,0,.102),(.055,.68,.039),l,m,grain=1)
 # Pin and alternating knuckles at the exact lid pivot; plates are visibly attached.
 for x in [-.34,.34]:
  box('HingeBodyPlate',(x,.395,.027),(.100,.010,.11),c,hardware,.001)
  box('HingeLeafPlate',(x,.371,.127),(.100,.018,.066),l,hardware,.001)
  rod('HingePin',(x-.075,.354,.09),(x+.075,.354,.09),.010,c,hardware)
  for i in range(5):rod('HingeKnuckle',(x-.06+i*.024,.354,.09),(x-.039+i*.024,.354,.09),.018,c if i%2==0 else l,hardware)
 # Rivets at boards/strap ends; no lock or new access gate.
 for x in [-.368,.368]:
  for z in [-.442,-.176,.035]:rod('Peen',(x,-.397,z),(x,-.399,z),.008,c,hardware,10)
  for y in [-.32,.31]:rod('LidPeen',(x,y,.197),(x,y,.200),.008,l,hardware,10)
 box('LatchBack',(0,-.396,-.005),(.083,.008,.122),c,hardware,.002)
 box('LatchTongue',(0,-.397,.098),(.045,.006,.120),l,hardware,.002)
 # Small side grips sit inside the original one-metre width.
 for x in [-.490,.490]:
  for y in [-.12,.12]:rod('HandleMount',(x,y,-.20),(x,y,-.24),.009,c,hardware)
  rod('HandleGrip',(x,-.12,-.24),(x,.12,-.24),.008,c,hardware)
 return c,l
def fuel(family):
 c=coll('FINISHED_fire_'+family);embers=coll('EMBERS_'+family);ash=coll('ASH_'+family);rng=random.Random(CFG['seed'])
 m=MATS['d5_charcoal_face'] if family=='charcoal' else MATS['d4_'+family+'_face']
 # Ash exists only as cosmetic pre-expiry residue. No stones around the pile.
 for i in range(20):
  x,y=rng.uniform(-.31,.31),rng.uniform(-.29,.29)
  bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=(x,y,-.238));o=bpy.context.object;o.scale=(rng.uniform(.045,.09),rng.uniform(.035,.08),rng.uniform(.005,.01));finish(o,'AshFlake',ash,MATS['Ash'],0)
 if family=='charcoal':
  for i in range(29):
   angle=i*2.399;radius=.28*math.sqrt(i/29);x,y=math.cos(angle)*radius,math.sin(angle)*radius;z=-.205+.115*(1-radius/.34)
   bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=(x,y,z));o=bpy.context.object;o.scale=(.063+rng.random()*.022,.055+rng.random()*.020,.033+rng.random()*.027);o.rotation_euler=(rng.random(),rng.random(),rng.random());finish(o,'CharcoalLump',c,m,0)
  for i in range(10):
   a=i*2.4;x,y=.22*math.cos(a),.22*math.sin(a)
   box('BuriedCoal',(x,y,-.18),(.043,.031,.012),embers,MATS['Ember'],.003)
 else:
  # Split wedge profiles have open V channels, closed backs and cut-end grain.
  for i in range(6):
   cy=-.225+(i%3)*.22;z=-.205+(i//3)*.072;length=.62+rng.uniform(-.025,.025)
   section=[(-.053,0),(-.037,.032),(-.009,.042),(0,.021),(.010,.043),(.045,.028),(.054,0),(.032,-.032),(-.035,-.034)]
   vs=[(x,cy+y,z+h) for x in [-length/2,length/2] for y,h in section];n=len(section)
   faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]
   o=mesh('SplitBillet',vs,faces,c,m)
   e=box('EmberChannel',(0,cy,z+.043-CFG['ember_recess_m']-.0015),(length-.04,.005,.003),embers,MATS['Ember'],0)
   if i>=3:
    o.rotation_euler.z=math.pi/2;e.rotation_euler.z=math.pi/2
 return c,embers,ash
def metric(objects,authored_solids=True):
 bpy.context.view_layer.update() # Rotated final billets need evaluated world matrices.
 pts=[];tri=bad=0
 for o in objects:
  bm=bmesh.new();bm.from_mesh(o.data)
  if authored_solids:assert all(e.is_manifold for e in bm.edges),o.name
  assert bm.calc_volume(signed=True)>0,(o.name,'inward winding')
  bm.free()
  o.data.calc_loop_triangles();tri+=len(o.data.loop_triangles)
  for t in o.data.loop_triangles:
   a,b,c=[o.matrix_world@o.data.vertices[i].co for i in t.vertices];bad+=int((b-a).cross(c-a).length<1e-10)
  pts += [o.matrix_world@v.co for v in o.data.vertices]
 assert all(all(math.isfinite(a) for a in p) for p in pts)
 return {'triangles':tri,'degenerates':bad,'objects':len(objects),'bounds_blender':[[min(v[a] for v in pts) for a in range(3)],[max(v[a] for v in pts) for a in range(3)]]}
def export(objects,path):
 bpy.ops.object.select_all(action='DESELECT');copies=[]
 for o in objects:
  n=o.copy();n.data=o.data.copy();bpy.context.scene.collection.objects.link(n);n.select_set(True);copies.append(n)
 bpy.context.view_layer.objects.active=copies[0];bpy.ops.object.join();o=bpy.context.object;o.name=path.stem
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
 slots=list(o.data.materials);unique=list(dict.fromkeys(slots));idx=[unique.index(slots[p.material_index]) for p in o.data.polygons];o.data.materials.clear()
 for m in unique:o.data.materials.append(m)
 for p,i in zip(o.data.polygons,idx):p.material_index=i
 mod=o.modifiers.new('Export triangles','TRIANGULATE');bpy.ops.object.modifier_apply(modifier=mod.name)
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_tangents=True,export_materials='EXPORT')
 bpy.data.objects.remove(o,do_unlink=True)
def stage():
 sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=16;sc.render.threads_mode='FIXED';sc.render.threads=8
 sc.render.resolution_x=1000;sc.render.resolution_y=800;sc.render.resolution_percentage=100;sc.world.color=(.22,.22,.22);sc.view_settings.view_transform='AgX';sc.render.image_settings.file_format='PNG'
 for name,loc,power in [('Key',(2,-3,4),400),('Fill',(-3,-2,2),300),('Rim',(0,3,3),500)]:
  data=bpy.data.lights.new(name,'AREA');data.energy=power;data.size=3;o=bpy.data.objects.new(name,data);sc.collection.objects.link(o);o.location=loc;o.rotation_euler=(-o.location).to_track_quat('-Z','Y').to_euler()
 data=bpy.data.cameras.new('Camera');o=bpy.data.objects.new('Camera',data);sc.collection.objects.link(o);sc.camera=o;data.type='ORTHO';data.ortho_scale=2.5
def render(out,objects,name,view=(2,-3,1.8),target=(0,0,-.02),clay=False):
 sc=bpy.context.scene
 for o in bpy.data.objects:
  if o.type=='MESH':o.hide_render=o not in objects
 sc.camera.location=view;sc.camera.rotation_euler=(Vector(target)-sc.camera.location).to_track_quat('-Z','Y').to_euler()
 if clay:sc.view_layers[0].material_override=bpy.data.materials.get('InspectionClay') or material('InspectionClay',color=(.36,.34,.30,1))
 sc.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True);sc.view_layers[0].material_override=None
if ARGS[0]=='--reopen':
 src,out=map(lambda x:Path(x).resolve(),ARGS[1:3]);out.mkdir(parents=True,exist_ok=False);bpy.ops.wm.open_mainfile(filepath=str(src));images=[i for i in bpy.data.images if i.type=='IMAGE'];assert len(images)==42 and all(i.packed_file for i in images);stage()
 views={'front':(0,-4,0),'back':(0,4,0),'side':(4,0,0),'top':(0,-.001,4),'underside':(0,-.001,-4),'three-quarter':(2,-3,1.8)}
 for family in CHESTS:
  body=list(bpy.data.collections['FINISHED_chest_'+family].objects);lid=list(bpy.data.collections['LID_'+family].objects);objects=body+lid
  render(out,objects,family+'-closed')
  if family=='wood':
   for v,loc in views.items():render(out,objects,'wood-clay-'+v,loc,clay=True)
  from mathutils import Matrix
  pivot=Vector((0,.354,.09));t=Matrix.Translation(pivot)@Matrix.Rotation(math.radians(-CFG['lid_angle_degrees']),4,'X')@Matrix.Translation(-pivot)
  for o in lid:o.matrix_world=t
  render(out,objects,family+'-open',target=(0,0,.18))
  for o in lid:o.matrix_world.identity()
 for family in FUELS:
  parts=list(bpy.data.collections['FINISHED_fire_'+family].objects);e=list(bpy.data.collections['EMBERS_'+family].objects);a=list(bpy.data.collections['ASH_'+family].objects)
  render(out,parts+e,family+'-fuel');render(out,parts+e,family+'-fuel-clay',clay=True);render(out,a,family+'-ash')
 imports={};expected=json.loads((src.parent/'geometry.json').read_text())
 for p in sorted((src.parent.parent/'runtime').glob('*.glb')):
  clean();bpy.ops.import_scene.gltf(filepath=str(p));r=metric([o for o in bpy.data.objects if o.type=='MESH'],False);assert r['degenerates']==0,p
  assert r['objects']==1 and r['triangles']==expected[p.stem]['triangles'],(p,r,expected[p.stem])
  assert all(abs(r['bounds_blender'][i][a]-expected[p.stem]['bounds_blender'][i][a])<1e-5 for i in range(2) for a in range(3)),(p,r['bounds_blender'],expected[p.stem]['bounds_blender'])
  imports[p.name]=r
 (out/'reopen.json').write_text(json.dumps({'packed_images':len(images),'imports':imports},indent=2))
else:
 TEXTURES=Path(ARGS[0]).resolve();out=Path(ARGS[1]).resolve();out.mkdir(parents=True,exist_ok=False);runtime=out.parent/'runtime';runtime.mkdir(exist_ok=False);clean();MATS={}
 for f in CHESTS[:5]:
  for side in ['face','edge']:
   stem='d4_'+f+'_'+side;MATS[stem]=material(stem,stem)
 for f in CHESTS[5:]:MATS['d6_'+f]=material('d6_'+f,'d6_'+f,True)
 MATS['d5_charcoal_face']=material('d5_charcoal_face','d5_charcoal_face');MATS['Ash']=material('Ash',color=(.28,.26,.235,1));MATS['Ember']=material('Ember',color=(.025,.007,.003,1))
 records={}
 for f in CHESTS:
  c,l=chest(f)
  for label,objects in [('body',list(c.objects)),('lid',list(l.objects))]:
   key=f'chest_{f}_{label}';r=metric(objects);assert r['degenerates']==0;records[key]=r;export(objects,runtime/(key+'.glb'))
 for f in FUELS:
  parts=fuel(f)
  for label,c in zip(['fuel','embers','ash'],parts):
   key=f'fire_{f}_{label}';r=metric(list(c.objects));assert r['degenerates']==0;records[key]=r;export(list(c.objects),runtime/(key+'.glb'))
 # Keep the modelling references, editable finish and runtime inspection copies
 # distinct in the master; no reference envelope is ever exported to the game.
 reference=coll('SOURCE_NATIVE_ENVELOPES');refmat=material('NativeEnvelope',color=(.22,.28,.34,1))
 box('ChestNativeBody',(0,0,-.15),(1,.8,.7),reference,refmat,0)
 box('FireNativeBody',(0,0,-.125),(.8,.8,.25),reference,refmat,0)
 reference.hide_render=True;reference.hide_viewport=True
 runtimes=coll('RUNTIME_INSPECTION_COPIES')
 for group in list(bpy.data.collections):
  if group.name.startswith(('FINISHED_','LID_','EMBERS_','ASH_')):
   for o in group.objects:
    n=o.copy();runtimes.objects.link(n)
 runtimes.hide_render=True;runtimes.hide_viewport=True
 review=coll('REVIEW');review['inspection']='Six-angle clay and material views are produced by --reopen; original references are unexported.'
 for i in bpy.data.images:
  if i.type=='IMAGE':i.pack()
 bpy.ops.wm.save_as_mainfile(filepath=str(out/'e3_home.blend'));(out/'geometry.json').write_text(json.dumps(records,indent=2)+'\n');print('E3_BLENDER_OK',len(records))
