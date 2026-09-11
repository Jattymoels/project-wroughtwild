"""C2 source finish. Reuses inspected ART02 geometry; B3/B1 context stays intact.
B3 build_kit.py supplied the same-source UV/capped-cut approach. No generator run.
"""
import bpy, bmesh, sys, json, math, random, shutil, hashlib
import numpy as np
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from prerequisites import PACKAGES, DEPOT
out=Path(sys.argv[sys.argv.index('--')+1]).resolve();assert not out.exists();out.mkdir(parents=True)
(out/'models').mkdir()
cfg=json.loads(Path(__file__).with_name('kit.json').read_text());rng=random.Random(cfg['seed'])
bpy.ops.wm.open_mainfile(filepath=str(PACKAGES['art02'][0]/'editable/rock-finished.blend'))
original=bpy.data.objects['Quiet river oak'];raw=bpy.data.objects['SOURCE - intact normalized oak']
for o in list(bpy.context.scene.objects):
 if o not in [original,raw]:bpy.data.objects.remove(o,do_unlink=True)
scene=bpy.context.scene;cols={}
for name in ['SOURCE','FINISHED','RUNTIME','REVIEW']:
 c=bpy.data.collections.new(name);scene.collection.children.link(c);cols[name]=c
def move(o,col):
 for c in list(o.users_collection):c.objects.unlink(o)
 cols[col].objects.link(o)
for o in [original,raw]:move(o,'SOURCE');o.hide_render=True;o.hide_set(True)
original.name='SOURCE approved ART02 fractured bedding';raw.name='SOURCE intact normalized generation'
def active(o):
 bpy.ops.object.select_all(action='DESELECT');o.hide_set(False);o.select_set(True);bpy.context.view_layer.objects.active=o
def clone(src,name,col='FINISHED'):
 o=src.copy();o.data=src.data.copy();o.modifiers.clear();o.name=name;cols[col].objects.link(o);o.hide_render=False;o.hide_set(False);return o
def fit(o,size):
 p=np.array([v.co for v in o.data.vertices]);lo=p.min(0);hi=p.max(0);p=(p-lo)/(hi-lo)*size;p[:,:2]-=np.array(size[:2])/2
 for v,pv in zip(o.data.vertices,p):v.co=pv
 o.data.update()
def clean(o):
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001);bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.000001);bmesh.ops.triangulate(bm,faces=list(bm.faces));bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free();o.data.update()
def reduce(o,target):
 o.data.calc_loop_triangles();n=len(o.data.loop_triangles)
 if n>target:
  active(o);m=o.modifiers.new('Measured detail reduction','DECIMATE');m.ratio=target/n;m.use_collapse_triangulate=True;bpy.ops.object.modifier_apply(modifier=m.name)
 clean(o)
def material(name,colour):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*colour,1);p.inputs['Roughness'].default_value=.9;return m
stone_mats={}
def mineral_image(family,palette):
 # Engine-portable mineral grain, generated from seeded periodic fields. No baked illumination.
 dim=1024;nr=np.random.default_rng(42);field=np.zeros((dim,dim),dtype=np.float32)
 for frequency,amplitude in [(3,.07),(9,.06),(23,.05),(61,.04),(137,.03)]:
  x=np.arange(dim)[None,:]/dim*math.tau;y=np.arange(dim)[:,None]/dim*math.tau
  for k in range(4):
   a=int(nr.integers(1,frequency+1));b=int(nr.integers(1,frequency+1));field+=np.sin(a*x+b*y+nr.random()*math.tau)*amplitude/4
 field+=nr.normal(0,.032,(dim,dim));pixels=np.ones((dim,dim,4),dtype=np.float32);pixels[:,:,:3]=np.clip(np.array(palette)*(1+field[:,:,None]),0,1)
 im=bpy.data.images.new(family+' seamless mineral albedo',width=dim,height=dim,alpha=True);im.pixels.foreach_set(pixels.ravel());im.pack();return im
for family,palette in [('slate',(.11,.15,.18)),('shellstone',(.65,.57,.41))]:
 m=material(family+' shared weathered mineral',palette);nt=m.node_tree;tex=nt.nodes.new('ShaderNodeTexImage');tex.image=mineral_image(family,palette);nt.links.new(tex.outputs['Color'],nt.nodes.get('Principled BSDF').inputs['Base Color'])
 stone_mats[family]=m
fossil_dark=material('Fossil weathered margins',(.25,.22,.16));fossil_pale=material('Calcified shell cross-sections',(.69,.64,.51))
grassmat=material('Living green centre / dry rim',(.33,.31,.12));gn=grassmat.node_tree;attr=gn.nodes.new('ShaderNodeVertexColor');attr.layer_name='Blade';gn.links.new(attr.outputs['Color'],gn.nodes.get('Principled BSDF').inputs['Base Color'])
def base_rock(name,family,size,triangles):
 o=clone(repaired,name);o.data.materials.clear();o.data.materials.append(stone_mats[family]);fit(o,size);clean(o);reduce(o,triangles)
 # Flat capped bottom removes the unsupported generated underside. New faces use planar UVs.
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=(0,0,size[2]*.07),plane_no=(0,0,1),clear_inner=True,dist=.000001)
 edges=[e for e in bm.edges if e.is_boundary];faces=bmesh.ops.holes_fill(bm,edges=edges,sides=0).get('faces',[]);uv=bm.loops.layers.uv.verify()
 for f in faces:
  for l in f.loops:l[uv].uv=(l.vert.co.x/size[0]+.5,l.vert.co.y/size[1]+.5)
 for v in bm.verts:v.co.z-=size[2]*.07
 bmesh.ops.triangulate(bm,faces=list(bm.faces));bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
 for f in bm.faces:
  axis=max(range(3),key=lambda i:abs(f.normal[i]));axes=[i for i in range(3) if i!=axis]
  for l in f.loops:l[uv].uv=(l.vert.co[axes[0]]*.7+.5,l.vert.co[axes[1]]*.7+.5)
 bm.to_mesh(o.data);bm.free();clean(o)
 for f in o.data.polygons:f.use_smooth=True
 return o

# Reuse B3's inspected closed source repair (same ART02 geometry/UV lineage).
with bpy.data.libraries.load(str(PACKAGES['b3'][0]/'models/b3-master.blend'),link=False) as (available,wanted):
 assert 'FINISHED repaired closed host' in available.objects
 wanted.objects=['FINISHED repaired closed host']
repaired=wanted.objects[0];move(repaired,'SOURCE');repaired.hide_render=True;repaired.hide_set(True)
assets={};fossil_records=[]
def join(objects,name):
 active(objects[0])
 for o in objects:o.select_set(True)
 bpy.ops.object.join();o=objects[0];o.name=name;return o
def stroke(name,points,width,mat):
 verts=[];faces=[]
 for i,p in enumerate(points):
  tangent=points[min(i+1,len(points)-1)]-points[max(0,i-1)];side=Vector((-tangent.y,tangent.x,0)).normalized()*width
  verts.extend([p-side,p+side])
 for i in range(len(points)-1):faces.append((2*i,2*i+1,2*i+3,2*i+2))
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new(name,mesh);cols['FINISHED'].objects.link(o);o.data.materials.append(mat);clean(o);return o
def fossils(host,variant):
 # Individual compressed spirals, bivalve sections and broken ribs, projected onto this actual bed.
 bv=BVHTree.FromPolygons([host.matrix_world@v.co for v in host.data.vertices],[tuple(f.vertices) for f in host.data.polygons]);parts=[]
 local=random.Random(420+variant);records=[]
 for i in range(9):
  cx=local.uniform(-.69,.69);cy=local.uniform(-.33,.32);r=local.uniform(.048,.12);angle=local.uniform(-math.pi,math.pi);kind=i%3;curve=[]
  for j in range(58):
   t=j/57
   if kind==0:a=t*math.pi*3.25;rad=r*(.12+.88*t);x=math.cos(a)*rad;y=math.sin(a)*rad*.69
   elif kind==1:a=math.pi*(.07+t*.80);x=math.cos(a)*r;y=math.sin(a)*r*.58
   else:a=math.pi*(.12+t*.55);x=math.cos(a)*r*.6;y=math.sin(a)*r
   x,y=cx+x*math.cos(angle)-y*math.sin(angle),cy+x*math.sin(angle)+y*math.cos(angle)
   hit,no,index,d=bv.ray_cast(Vector((x,y,2)),Vector((0,0,-1)))
   if hit is not None and no.z>.3:curve.append(hit+no*.001)
  if len(curve)<5:continue
  # Breaks prevent the continuous stamped-medallion read; both strips share the sampled surface.
  sections=[];current=[]
  for p in curve:
   if current and (p-current[-1]).length>.028:sections.append(current);current=[]
   current.append(p)
  sections.append(current)
  for section in sections:
   if len(section)>2:
    parts.append(stroke('fossil mineral seam',section,.0045,fossil_dark));parts.append(stroke('fossil shell inset',[p+Vector((0,0,.001)) for p in section],.0023,fossil_pale))
  records.append({'centre_xy':[cx,cy],'radius_m':r,'rotation':angle,'kind':['compressed partial spiral','bivalve arc','broken cross-section'][kind],'surface_samples':len(curve)})
 fossil_records.append({'variant':variant,'sections':records});return parts
for family in ['slate','shellstone']:
 for variant in range(2):
  parts=[]
  if family=='slate':
   for layer in range(cfg['slate_layers']):
    size=(1.96-layer*.115,1.11-layer*.045,.066)
    o=base_rock('slate cleaved sheet %d'%layer,family,size,2400);o.location=(.025*math.sin(layer*2.3+variant),.015*math.cos(layer*1.7),layer*(.066+cfg['slate_gap_m']));parts.append(o)
  else:
   for layer in range(3):
    o=base_rock('shellstone bed %d'%layer,family,(1.95-layer*.16,1.1-layer*.08,.19),5500);o.location=(.018*math.sin(layer+variant),0,layer*.17);parts.append(o)
   bpy.context.view_layer.update();parts+=fossils(parts[-1],variant)
  full=join(parts,family+'-v%d-full'%variant);assets[full.name]=full
  for state,cutx in [('worked',.23),('last',-.28)]:
   o=clone(full,family+'-v%d-'%variant+state);bm=bmesh.new();bm.from_mesh(o.data)
   # A real removed work face opens the stone, while the unchanged body remains the work target.
   bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=(cutx,0,0),plane_no=(1,0,0),clear_outer=True,dist=.000001)
   edges=[e for e in bm.edges if e.is_boundary and all(abs(v.co.x-cutx)<.0001 for v in e.verts)];faces=bmesh.ops.holes_fill(bm,edges=edges,sides=0).get('faces',[]);uv=bm.loops.layers.uv.verify()
   for f in faces:
    f.material_index=0
    for l in f.loops:l[uv].uv=(l.vert.co.y+.5,l.vert.co.z+.25)
   bm.to_mesh(o.data);bm.free();clean(o);assets[o.name]=o
  # A representative recovered solid uses this exact family's original UVs, scaled to a hand sample.
  o=base_rock(family+'-v%d-recovered'%variant,family,(.37,.26,.035 if family=='slate' else .18),2500)
  if family=='shellstone':o=join([o]+fossils(o,variant+10),o.name)
  assets[o.name]=o
for variant in range(3):
 for lod,count in enumerate(cfg['tussock_blades']):
  local=random.Random(42+variant);verts=[];faces=[];colours=[]
  for i in range(count):
   a=local.random()*math.tau;r=.23*math.sqrt(local.random());x,y=math.cos(a)*r,math.sin(a)*r;h=local.uniform(.17,.37)*(1-r*.75);width=local.uniform(.004,.010);ang=local.random()*math.tau;side=Vector((math.cos(ang),math.sin(ang),0));start=len(verts);dry=r>.15 or local.random()<.17
   colour=(.34,.28,.12,1) if dry else (.16,.24,.08,1)
   for j in range(5):
    t=j/4;p=Vector((x+.13*t*t,y+.024*math.sin(t*3+a),h*math.sin(t*1.40)));w=width*(1-.97*t)
    verts.extend([p-side*w,p+side*w]);colours.extend([colour,colour])
   for j in range(4):faces.append(tuple(start+k for k in [2*j,2*j+1,2*j+3,2*j+2]))
  mesh=bpy.data.meshes.new('Rooted combed blades');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('upland-tussock-v%d-lod%d'%(variant,lod),mesh);cols['FINISHED'].objects.link(o);o.data.materials.append(grassmat)
  ca=mesh.color_attributes.new(name='Blade',type='FLOAT_COLOR',domain='POINT')
  for c,col in zip(ca.data,colours):c.color=col
  clean(o);assets[o.name]=o
reports=[]
def export(o,name):
 active(o);bpy.ops.export_scene.gltf(filepath=str(out/'models'/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True,export_image_format='AUTO',export_texcoords=True,export_normals=True,export_materials='EXPORT',export_attributes=True,export_all_vertex_colors=True)
 o.data.calc_loop_triangles();points=[o.matrix_world@v.co for v in o.data.vertices]
 reports.append({'name':name,'triangles':len(o.data.loop_triangles),'surfaces':len(o.data.materials),'bounds_blender_m':[[min(p[i] for p in points) for i in range(3)],[max(p[i] for p in points) for i in range(3)]]})
for name,o in list(assets.items()):
 if 'tussock' in name:export(o,name);o.hide_render=True;continue
 for lod,target in enumerate([50000,7000,1800]):
  n=clone(o,name+'-lod%d'%lod,'RUNTIME');reduce(n,target);export(n,n.name);n.hide_render=True;n.hide_set(True)
 o.hide_render=True
# Source-package context is copied byte-for-byte, then texture sharing happens only in the review cook.
context={}
for name,source in [('rock-shelf',PACKAGES['b3'][0]/'models/rock-shelf-lod1.glb'),('rock-shelf-altered',PACKAGES['b3'][0]/'models/rock-shelf-altered-lod1.glb')]:
 shutil.copy2(source,out/'models'/(name+'.glb'));context[name]={'source':str(source),'sha256':hashlib.sha256(source.read_bytes()).hexdigest()}
pine=PACKAGES['b1'][0]/'runtime/pine/pine-a-lod2.glb'
if not pine.exists():
 matches=list(PACKAGES['b1'][0].rglob('pine-a-lod2.glb'));assert matches;pine=matches[0]
shutil.copy2(pine,out/'models/pine-context.glb');context['pine-context']={'source':str(pine),'sha256':hashlib.sha256(pine.read_bytes()).hexdigest()}
# Review copies arranged in rows: full -> worked -> last -> recovered, with identical palette lineage.
for family,y in [('slate',1.0),('shellstone',-1.0)]:
 for state,x in [('full',-2.5),('worked',0),('last',2.5),('recovered',4)]:
  o=clone(assets[family+'-v0-'+state],family+' '+state+' review','REVIEW');o.location+=(Vector((x,y,0)))
for v in range(3):
 o=clone(assets['upland-tussock-v%d-lod0'%v],'tussock review '+str(v),'REVIEW');o.location=(v-1,-2.4,0)
plane=material('Neutral mineral ground',(.19,.19,.165));bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.012));floor=bpy.context.object;floor.name='Review floor';floor.data.materials.append(plane);move(floor,'REVIEW')
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24;scene.cycles.use_denoising=True;scene.render.resolution_x=1440;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Neutral outdoor');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.34,.40,.46,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.65
sun=bpy.data.objects.new('Sun',bpy.data.lights.new('Sun','SUN'));cols['REVIEW'].objects.link(sun);sun.data.energy=2.5;sun.rotation_euler=(.55,-.45,-.5)
cam=bpy.data.objects.new('Review camera',bpy.data.cameras.new('Review camera'));cols['REVIEW'].objects.link(cam);scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=9.8;cam.location=(6,8,7);cam.rotation_euler=(Vector((.6,-.5,.2))-cam.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(out/'c2-master.blend'))
(out/'models.json').write_text(json.dumps(reports,indent=2)+'\n');(out/'fossils.json').write_text(json.dumps(fossil_records,indent=2)+'\n');(out/'context.json').write_text(json.dumps(context,indent=2)+'\n')
scene.render.filepath=str(out/'blender-kit.png');bpy.ops.render.render(write_still=True)
print('C2_BUILD_OK',len(reports))
