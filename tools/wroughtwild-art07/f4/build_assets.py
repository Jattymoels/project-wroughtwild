"""F4 metric assembly from verified E2/F2/F3 donors; Blender 4.5.9."""
import bpy,sys,json,math,hashlib
from pathlib import Path
from mathutils import Vector,Matrix
sys.path.insert(0,str(Path(__file__).parent))
import model_helpers as h
from inputs import ROOT,DEPOT,PACKAGES
OUT=Path(sys.argv[sys.argv.index('--')+1]).resolve()
assert OUT.is_relative_to(ROOT/'build/art07/f4');OUT.mkdir(parents=True,exist_ok=False)
for d in ['runtime','source','renders','textures']:(OUT/d).mkdir()
bpy.ops.wm.read_factory_settings(use_empty=True)
donors=bpy.data.collections.new('Immutable donor copies');bpy.context.scene.collection.children.link(donors)
finished=bpy.data.collections.new('Finished editable F4');bpy.context.scene.collection.children.link(finished)
def collect(o,c):
 for old in list(o.users_collection):old.objects.unlink(o)
 c.objects.link(o)
def imported(path):
 before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(path));items=list(set(bpy.data.objects)-before)
 for o in items:collect(o,donors)
 return items
winch=imported(DEPOT/PACKAGES['f2'][0]/'source/devices/winch.glb')
drum_donor=next(o for o in winch if o.name=='MovingAssembly')
wood=next(m for m in bpy.data.materials if m.name=='D4 Timber')
h.WOOD_END=next(m for m in bpy.data.materials if m.name=='D4 Timber cut end')
iron=next(m for m in bpy.data.materials if m.name=='D6 Iron')
with bpy.data.libraries.load(str(DEPOT/PACKAGES['e2'][0]/'source/e2_forges.blend'),link=False) as (src,dst):dst.collections=['Common_near']
forge_collection=bpy.data.collections['Common_near'];donors.children.link(forge_collection)
stone=next(m for m in bpy.data.materials if m.name=='Stone')
# Keep predecessor image bytes, use a darker local tint in both renderers later.
clay=h.material('F4 fired clay',(.27,.12,.063));fuel=h.material('F4 fuel',(.07,.056,.038))
cut=h.material('F4 dark cut',(.028,.030,.022));tissue=h.material('F4 pocket tissue',(.055,.075,.049))
cores={}
for level in ['near','middle','far']:
 items=imported(DEPOT/PACKAGES['f3'][0]/('source/ventlung_'+level+'.glb'))
 cores[level]=next(o for o in items if o.type=='MESH')
def copy_mesh(src,name,parent,matrix):
 o=src.copy();o.data=src.data.copy();o.name=name;finished.objects.link(o);o.parent=None;o.matrix_world=matrix;h.parent_keep(o,parent);return o
def root(name):
 o=h.empty(name);collect(o,finished);return o
def box(name,at,size,mat,parent,bevel=.006):
 o=h.box(name,at,size,mat,parent,bevel);collect(o,finished);return o
def rod(name,a,b,r,mat,parent):
 o=h.cylinder(name,a,b,r,mat,16,parent);collect(o,finished);return o
def group(name,at,parent):
 o=root(name);o.location=h.v(at);o.parent=parent;o['f4_role']=name;bpy.context.view_layer.update();return o
def chamber(name,at,size,parent):
 g=group(name,(0,0,0),parent);x,y,z=at;w,hh,d=size
 box(name+' floor',(x,y-hh/2+.02,z),(w,.04,d),clay,g)
 for dx in [-1,1]:box(name+' side',(x+dx*(w/2-.016),y,z),(.032,hh,d),clay,g)
 for dz in [-1,1]:box(name+' lip',(x,y,z+dz*(d/2-.016)),(w-.06,hh,.032),clay,g)
 return g
def membrane(level,name,at,size,parent):
 src=cores[level];pts=[src.matrix_world@v.co for v in src.data.vertices];lo=Vector([min(p[i] for p in pts) for i in range(3)]);hi=Vector([max(p[i] for p in pts) for i in range(3)])
 centre=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z));target=Vector((size[0],size[2],size[1]));scale=Vector([target[i]/(hi[i]-lo[i]) for i in range(3)])
 bpy.context.view_layer.update()
 matrix=parent.matrix_world@Matrix.Translation(h.v(at))@Matrix.Diagonal((*scale,1))@Matrix.Translation(-centre)@src.matrix_world
 o=copy_mesh(src,name,parent,matrix);o['source_lod']=level;o['scar_depth_before_mount_m']=.026;return o
def assemble_feeder(level):
 r=root('Feeder_'+level)
 for x in [-.60,.60]:
  box('Foot',(x,.065,0),(.19,.13,1.20),wood,r)
  for z in [-.48,.48]:
   box('Upright',(x,.54,z),(.11,.96,.11),wood,r)
   for y in [.19,.87]:
    box('Forged strap',(x,y,z),(.128,.055,.127),iron,r,.003)
    rod('Peened fastener',(x,y,z-.069),(x,y,z-.077),.019,iron,r)
 for z in [-.48,.48]:box('Crossbar',(0,.18,z),(1.26,.105,.12),wood,r)
 for x in [-.60,.60]:box('Longitudinal rail',(x,.86,0),(.13,.11,1.08),wood,r)
 box('Hopper support',(0,.98,-.27),(1.22,.09,.62),wood,r)
 chamber('Hopper',(-.15,1.195,-.26),(.31,.34,.53),r)
 chamber('FuelCup',(.17,1.195,-.26),(.27,.34,.53),r)
 # A real visible partition keeps both existing load centres in separate containers.
 chamber('OutputTray',(.12,.215,.30),(.75,.19,.62),r)
 bellows=group('Bellows',(-.31,.32,.1),r)
 membrane(level,'Membrane',(0,0,0),(.42,.50,.46),bellows)
 box('Lower bearing',(-.31,.29,.1),(.51,.055,.53),wood,r)
 box('Guided platen',(-.31,.84,.1),(.50,.055,.52),wood,bellows)
 for x in [-.57,-.05]:
  rod('Platen guide',(x,.30,.12),(x,.90,.12),.018,iron,r)
 drum=group('Drum',(.33,.66,.02),r)
 # Full finished F2 moving assembly, transformed about its measured native X pivot.
 mat=Matrix.Translation(h.v((.33,.66,.02)))@Matrix.Scale(.49,4)@Matrix.Translation(h.v((0,-1.05,0)))@drum_donor.matrix_world
 copy_mesh(drum_donor,'Recovered root and crank',drum,mat)
 for x in [.04,.62]:
  box('Drum bearing',(x,.59,.02),(.08,.28,.12),wood,r)
  rod('Axle collar',(x-.04,.66,.02),(x+.04,.66,.02),.055,iron,r)
 # Native connections share this centre; rings are visual collars, never offset ports.
 for axis in [0,2]:
  a=[0,.85,0];b=a.copy();a[axis]=-.10;b[axis]=.10
  rod('Centre manifold',a,b,.070,iron,r)
 socket=group('ConnectionAnchor',(0,.85,0),r);socket['native_shared_origin']=True
 return r
def assemble_pocket(level):
 r=root('Pocket_'+level)
 # Reuse actual E2 lower masonry, rim and scarred jamb. Remove the cowl entirely:
 # this is the struck remnant, not an operational or free StationSite.
 for src in forge_collection.objects:
  if src.type!='MESH':continue
  if not src.name.startswith(('Bed_','Return_','HearthFloor','HearthRim','RearHearthRim','ScarredJamb','RightJamb','Fireback')):continue
  # Keep the lower two bed courses; shift upper hearth into their ruined seat.
  if src.name.startswith(('Bed_','Return_')):
   row=int(src.name.split('_')[1])
   if row>1:continue
   matrix=src.matrix_world.copy()
  else:matrix=Matrix.Translation((0,0,-.40))@src.matrix_world
  if src.name.startswith('Fireback') and src.location.z>1.22:continue
  o=copy_mesh(src,'Salvaged '+src.name,r,matrix)
  if src.name.startswith('Bed_') and src.location.y<0 and abs(src.location.x)<.18:
   bpy.data.objects.remove(o,do_unlink=True) # A real open broken front, not painted damage.
 # Detached old iron strips brace fractured stone, no added gameplay casing.
 for x in [-.40,.40]:box('Old band',(x,.48,0),(.038,.07,.85),iron,r,.003)
 m=group('PressureMembrane',(0,.40,.025),r)
 membrane(level,'Finite membrane',(0,0,0),(.58,.52,.62),m)
 group('ConnectionAnchor',(0,.85,0),r)
 return r
def audit(r):
 points=[];tri=0;surfaces=0;deg=0
 for o in [r]+list(r.children_recursive):
  if o.type!='MESH':continue
  ev=o.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();me.calc_loop_triangles();tri+=len(me.loop_triangles);surfaces+=len(set(t.material_index for t in me.loop_triangles));deg+=sum(t.area<1e-12 for t in me.loop_triangles);points += [r.matrix_world.inverted()@o.matrix_world@vv.co for vv in me.vertices];ev.to_mesh_clear()
 lo=[min(p[i] for p in points) for i in range(3)];hi=[max(p[i] for p in points) for i in range(3)]
 assert all(math.isfinite(x) for x in lo+hi) and deg==0
 return {'triangles':tri,'surfaces':surfaces,'min':[lo[0],lo[2],-hi[1]],'max':[hi[0],hi[2],-lo[1]],'size':[hi[0]-lo[0],hi[2]-lo[2],hi[1]-lo[1]]}
def export(r,name):
 # Join static children per motion role, retaining all useful editable originals in master.
 copies=[]
 for parent in [r]+[o for o in r.children_recursive if o.type=='EMPTY']:
  meshes=[o for o in parent.children if o.type=='MESH']
  if len(meshes)>1:
   bpy.ops.object.select_all(action='DESELECT')
   for o in meshes:o.select_set(True)
   bpy.context.view_layer.objects.active=meshes[0];bpy.ops.object.join();meshes[0].name=parent.name+' surface'
 bpy.ops.object.select_all(action='DESELECT');r.select_set(True)
 for o in r.children_recursive:o.select_set(True)
 bpy.ops.export_scene.gltf(filepath=str(OUT/'runtime'/name),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_animations=False,export_extras=True)
records={};roots=[]
for level in ['near','middle','far']:
 for kind,fn in [('feeder',assemble_feeder),('pocket',assemble_pocket)]:
  r=fn(level);bpy.context.view_layer.update();records[kind+'_'+level]=audit(r)
  bounds=(1.5,1.45,1.45) if kind=='feeder' else (1.05,1.25,1.05)
  a=records[kind+'_'+level];assert a['min'][1]>=-.00001
  for axis in [0,2]:assert a['min'][axis]>=-bounds[axis]/2 and a['max'][axis]<=bounds[axis]/2,(kind,axis,a)
  assert a['max'][1]<=bounds[1],a
  roots.append(r)
donors.hide_render=True;donors.hide_viewport=True
load_roots=[]
for kind,material in [('clay',clay),('fuel',fuel),('bricks',clay)]:
 r=root('Load_'+kind);load_roots.append(r)
 if kind=='bricks':
  for x in [-.143,.143]:
   for z in [-.108,.108]:box('Fired brick',(x,0,z),(.266,.108,.196),material,r,.008)
 else:
  for x in [-.059,.059]:
   for z in [-.13,0,.13]:box('Supply lump',(x,0,z),(.108,.10,.12),material,r,.016)
# Normalize only finished UVs before packing or joining. Donor layer names differ;
# joined missing layers otherwise receive zero coordinates. Preserve mapped faces,
# including root travel UVs; metric-map only a material whose entire chart collapsed.
uv_repairs=[]
for o in list(finished.objects):
 if o.type!='MESH' or not o.data.uv_layers:continue
 active=o.data.uv_layers.active
 for face in o.data.polygons:
  if max((active.data[i].uv.length for i in face.loop_indices),default=0)<1e-9:
   for other in o.data.uv_layers:
    if other!=active and any(other.data[i].uv.length>1e-9 for i in face.loop_indices):
     for i in face.loop_indices:active.data[i].uv=other.data[i].uv
     break
 for slot in range(len(o.data.materials)):
  faces=[f for f in o.data.polygons if f.material_index==slot]
  if faces and all(active.data[i].uv.length<1e-9 for f in faces for i in f.loop_indices):
   for f in faces:
    axis=max(range(3),key=lambda i:abs(f.normal[i]));axes=[i for i in range(3) if i!=axis]
    for i in f.loop_indices:
     co=o.data.vertices[o.data.loops[i].vertex_index].co;active.data[i].uv=(co[axes[0]]/.5,co[axes[1]]/.5)
   uv_repairs.append({'object':o.name,'material':o.data.materials[slot].name,'faces':len(faces)})
 for uv in list(o.data.uv_layers):
  if uv!=active:o.data.uv_layers.remove(uv)
 active.name='UVMap';active.active_render=True
(OUT/'source/uv-repairs.json').write_text(json.dumps(uv_repairs,indent=2))
# Pack both finished and unmodified donor copies in one editable master.
for img in bpy.data.images:
 if img.source=='FILE' and img.has_data:img.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'source/f4-master.blend'))
for r in roots:export(r,r.name.lower()+'.glb')
for r in load_roots:export(r,r.name.lower()+'.glb')
(OUT/'source/geometry.json').write_text(json.dumps(records,indent=2))
# Save texture payloads by content hash for one shared runtime copy across LODs.
texture_records={}
for m in bpy.data.materials:
 if not m.use_nodes:continue
 for node in m.node_tree.nodes:
  if node.type=='TEX_IMAGE' and node.image and node.image.packed_file:
   raw=bytes(node.image.packed_file.data);digest=hashlib.sha256(raw).hexdigest();p=OUT/'textures'/(digest+'.png');p.write_bytes(raw)
   texture_records.setdefault(m.name,[]).append({'node':node.name,'image':node.image.name,'sha256':digest,'bytes':len(raw),'size':list(node.image.size),'colorspace':node.image.colorspace_settings.name})
(OUT/'source/textures.json').write_text(json.dumps(texture_records,indent=2));print('F4_ASSEMBLY_OK',json.dumps(records))
