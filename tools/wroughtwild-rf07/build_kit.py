"""RF07 original highland plants and settled stone, editable in metres."""
import bpy, math, random, json, sys, shutil, hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/wroughtwild-art07/b2'))
from geometry import Mesh,tube,leaf
SOURCE=Path('D:/Wroughtwild/source-art/rf07-highland-recovery')
OUT=ROOT/'game/rf07/assets'
cfg=json.loads((ROOT/'tools/wroughtwild-rf07/art.json').read_text())
SOURCE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
mat=bpy.data.materials.new('RF07 weathered stone and hardy growth');mat.use_nodes=True;mat.use_backface_culling=False
p=mat.node_tree.nodes.get('Principled BSDF');p.inputs['Roughness'].default_value=.96
attr=mat.node_tree.nodes.new('ShaderNodeVertexColor');attr.layer_name='Plant colour'
mat.node_tree.links.new(attr.outputs['Color'],p.inputs['Base Color'])
def blade(m,root,a,length,height,width,color):
 d=Vector((math.cos(a),math.sin(a),0));side=Vector((-d.y,d.x,0));start=len(m.v)
 for j in range(6):
  t=j/5;mid=Vector(root)+d*(length*t*t)+Vector((0,0,height*math.sin(t*math.pi*.66)))
  w=width*(math.sin(t*math.pi)**.6+.12)*(1-t) if t<1 else .001
  c=Vector((.05,.06,.02)).lerp(Vector(color),min(1,t*4));c=c.lerp(Vector((.24,.205,.102)),max(0,t-.65)*2)
  for k in [-1,0,1]:m.vert(mid+side*w*k+Vector((0,0,(1-abs(k))*w*.3)),(k*.5+.5,t),tuple(c))
 for j in range(5):
  for k in range(2):
   a=start+j*3+k;m.face(a,a+3,a+4,a+1)
forms={}
for role in cfg['purpose']:
 rng=random.Random(cfg['seed']+len(forms)*199);m=Mesh()
 if role=='tussock':
  for i in range(72):
   a=rng.random()*math.tau;r=rng.random()**.5*.26
   blade(m,(math.cos(a)*r,math.sin(a)*r*.75,0),a*.6+.8,rng.uniform(.2,.5),rng.uniform(.19,.47),rng.uniform(.008,.017),(.135,.169,.059) if i%4 else (.19,.177,.080))
  for i in range(9):
   a=rng.random()*math.tau;d=Vector((math.cos(a),math.sin(a),0));h=rng.uniform(.38,.62)
   tube(m,[d*.1,d*.18+Vector((0,0,h*.6)),d*.3+Vector((0,0,h))],[.006,.005,.002],(.18,.15,.072),sides=4)
 elif role in ['heath','cushion']:
  low=role=='cushion'
  for i in range(11 if low else 15):
   a=i*2.399+rng.uniform(-.3,.3);d=Vector((math.cos(a),math.sin(a),0));length=rng.uniform(.26,.56);h=rng.uniform(.06,.12) if low else rng.uniform(.22,.56)
   path=[Vector((0,0,.02)),d*length*.25+Vector((0,0,h*.5)),d*length*.7+Vector((0,0,h)),d*length+Vector((0,0,h*.86))]
   tube(m,path,[.018,.014,.009,.002],(.105,.083,.048),sides=5)
   for j in range(2,9):
    t=j/10;at=d*length*t+Vector((0,0,h*math.sin(t*math.pi*.6)))
    for sign in [-1,1]:
     side=Vector((-d.y,d.x,0))*sign
     tip=at+side*.1+Vector((0,0,.055))
     tube(m,[at,tip],[.005,.001],(.10,.074,.038),sides=4)
     for k in range(3):
      direction=(d*.2+side*.8+Vector((0,0,.1+k*.3))).normalized()
      leaf(m,at.lerp(tip,(k+1)/3),direction,.075 if low else .105,.018 if low else .029,(.12,.17,.09) if j%3 else (.17,.205,.11),detail=2)
 elif role=='shingle':
  for i in range(7):
   cx=rng.uniform(-.38,.38);cy=rng.uniform(-.28,.28);rx=rng.uniform(.10,.26);ry=rng.uniform(.07,.18);h=rng.uniform(.04,.11);a=rng.random()*math.tau
   start=len(m.v);n=7
   for ring in range(3):
    for j in range(n):
     q=j/n*math.tau;f=1.0 if ring==1 else .80 if ring==2 else .86
     x=math.cos(q)*rx*f;y=math.sin(q)*ry*f
     z=0 if ring==0 else h*.6 if ring==1 else h*(.9+.12*math.sin(j*2+i))
     colour=(.24,.265,.22) if ring==2 and i%3==0 else (.24,.25,.235) if ring==2 else (.15,.162,.153)
     m.vert((cx+x*math.cos(a)-y*math.sin(a),cy+x*math.sin(a)+y*math.cos(a),z),(x,y),colour)
   for ring in range(2):
    for j in range(n):m.face(start+ring*n+j,start+ring*n+(j+1)%n,start+(ring+1)*n+(j+1)%n,start+(ring+1)*n+j)
   m.face(*[start+2*n+j for j in range(n)])
 ob=m.obj('RF07 '+role,mat)
 if role=='shingle':
  for face in ob.data.polygons:face.use_smooth=False
 ob['purpose']=cfg['purpose'][role];ob['author']='Original RF07 scripted Blender geometry';ob['collision']='None'
 coords=[v.co.copy() for v in ob.data.vertices];cx=(min(v.x for v in coords)+max(v.x for v in coords))*.5;cy=(min(v.y for v in coords)+max(v.y for v in coords))*.5;floor=min(v.z for v in coords)
 for v in ob.data.vertices:v.co-=Vector((cx,cy,floor))
 ob.data.update();ob.data.calc_loop_triangles()
 bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
 path=OUT/(role+'.glb');bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_all_vertex_colors=True)
 coords=[v.co for v in ob.data.vertices]
 forms[role]={'triangles':len(ob.data.loop_triangles),'width_m':2*max(math.hypot(v.x,v.y) for v in coords),'height_m':max(v.z for v in coords),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'rf07-highland-master.blend'),compress=True)
report={'forms':forms,'method':'Original direct Blender modelling; no external assets or reference pixels.','source':str(SOURCE/'rf07-highland-master.blend')}
for p in [SOURCE/'source.json',ROOT/'game/rf07/source.json']:p.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
for name in ['build_kit.py','art.json']:shutil.copy2(ROOT/'tools/wroughtwild-rf07'/name,SOURCE/name)
print('RF07_ART '+json.dumps(report))
