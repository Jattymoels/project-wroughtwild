"""LAND-03 original Blender Steppe kit; background --python this file."""
import bpy, math, random, json, sys, hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/wroughtwild-art07/b2'))
from geometry import Mesh,tube,leaf
SOURCE=ROOT/'build/land03/source-art';OUT=ROOT/'game/land03/assets'
SOURCE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
mat=bpy.data.materials.new('LAND03 living dry host colour');mat.use_nodes=True;mat.use_backface_culling=False
p=mat.node_tree.nodes.get('Principled BSDF');p.inputs['Roughness'].default_value=.92
attr=mat.node_tree.nodes.new('ShaderNodeVertexColor');attr.layer_name='Plant colour'
mat.node_tree.links.new(attr.outputs['Color'],p.inputs['Base Color'])
def blade(m,root,angle,length,height,width,color,lean=.16):
 d=Vector((math.cos(angle),math.sin(angle),0));side=Vector((-d.y,d.x,0));start=len(m.v)
 for j in range(6):
  t=j/5;mid=Vector(root)+d*length*(t*.24+t*t*.76)+Vector((lean*t*t,0,height*math.sin(t*math.pi*.76)))
  shape=math.sin(math.pi*t)**.65*.83+.17 if t<1 else .006
  c=Vector((.078,.063,.027)).lerp(Vector(color),min(1,t*2.8))
  for k in [-1,0,1]:m.vert(mid+side*width*shape*k+Vector((0,0,(1-abs(k))*width*.30)),(k*.5+.5,t),tuple(c*(1.08 if k==0 else .94)))
 for j in range(5):
  for k in range(2):
   a=start+j*3+k;m.face(a,a+3,a+4,a+1)
def pebble(m,root,scale,color,rng):
 start=len(m.v);rings=5;sides=9
 for j in range(rings):
  t=j/(rings-1);theta=math.pi*t
  for k in range(sides):
   a=k/sides*math.tau;r=math.sin(theta)*(1+rng.uniform(-.14,.14))
   m.vert(Vector(root)+Vector((math.cos(a)*r*scale[0],math.sin(a)*r*scale[1],(.5-.5*math.cos(theta))*scale[2])),(k/sides,t),tuple(c*rng.uniform(.86,1.13) for c in color))
 for j in range(rings-1):
  for k in range(sides):
   a=start+j*sides+k;b=start+j*sides+(k+1)%sides;m.face(a,b,b+sides,a+sides)
def mineral(m,rng):
 # Small ground-hugging lobes enclose actual recessed dark surfaces; native ribs remain the physical landform.
 for l in range(3):
  center=Vector((-.52+l*.48,rng.uniform(-.18,.18),-.12));rad=.37+.10*(l==1);path=[];radii=[]
  for j in range(17):
   a=j/16*math.tau;r=rad*(1+.14*math.sin(a*3+l)+.09*math.sin(a*5))
   path.append(center+Vector((r*math.cos(a),r*.64*math.sin(a),.19+.18*math.sin(a)**2+.05*math.cos(a*3))))
   radii.append(.085+.055*(.5+.5*math.sin(a*4+l)))
  tube(m,path,radii,(.24,.20,.14),sides=8)
  pebble(m,center+Vector((0,0,.02)),(rad*.71,rad*.45,.16),(.044,.029,.018),rng)
  for j in range(3):
   x=center.x+(j-1)*.095
   tube(m,[(x,center.y-.09,.12),(x+.05,center.y,.135),(x-.015,center.y+.08,.12)],[.012,.027,.009],(.46,.045,.008),sides=5)
 for i in range(6):
  a=rng.random()*math.tau;pebble(m,(math.cos(a)*.76,math.sin(a)*.40,-.05),(.22,.17,.17),(.21,.19,.145),rng)
forms={}
roles=['grass-flow','grass-islands','sage-fan','red-brush','erosion-join','release-nodule']
purposes=['Swept straw/olive blades tie many growing points into a broad low living mat.','Interrupted low grass hummocks form irregular dry holes between colonies.','Woody horizontal branching shrub, grey-olive paddle leaves and asymmetric sheltered crown.','Tough recurved clustered leaves with swollen woody joints and a few red active tips.','Small fractured shale fans seat native shallow-cut edges without inventing collision.','Irregular swollen mineral lobes surround dark recessed release pockets; local Red only.']
for idx,role in enumerate(roles):
 rng=random.Random(170903+idx*311);m=Mesh()
 if role.startswith('grass'):
  for i in range(180):
   a=rng.random()*math.tau;r=math.sqrt(rng.random())*1.24;root=Vector((math.cos(a)*r,math.sin(a)*r*.70,0))
   if role=='grass-islands' and -.30<root.x<.30 and root.y>.02:continue
   color=(.33,.25,.091) if i%4 else (.145,.173,.059)
   blade(m,root,rng.uniform(-.7,1.3),rng.uniform(.13,.37),rng.uniform(.19,.48),rng.uniform(.014,.025),color)
 elif role in ['sage-fan','red-brush']:
  for b in range(8 if role=='sage-fan' else 6):
   a=b*2.399+rng.uniform(-.4,.4);d=Vector((math.cos(a),math.sin(a),0));h=rng.uniform(.38,.80);length=rng.uniform(.35,.71)
   path=[d*length*t+Vector((0,0,h*math.sin(t*1.5))) for t in [0,.22,.45,.68,.84,1]]
   tube(m,path,[.038,.036,.029,.021,.012,.003],(.095,.070,.035),sides=6)
   for j in range(2,7):
    t=j/7;at=d*length*t+Vector((0,0,h*math.sin(t*1.5)))
    for k in range(4):
     direction=Vector((math.cos(a+k*1.8)*.65,math.sin(a+k*1.8)*.65,.30));c=(.11,.16,.084) if j%2 else (.165,.195,.107)
     if role=='red-brush':blade(m,at,a+k*1.7,.24,.18,.043,(.22,.145,.055) if j%3 else (.30,.09,.026),lean=.03)
     else:leaf(m,at,direction,.24,.055,c,detail=1)
   if role=='red-brush':pebble(m,path[3],(.068,.054,.078),(.33,.074,.015),rng)
  for i in range(35):blade(m,(rng.uniform(-.5,.5),rng.uniform(-.4,.4),0),rng.random()*math.tau,.22,.17,.019,(.25,.21,.067),lean=.1)
 elif role=='erosion-join':
  for i in range(24):
   x=rng.uniform(-1,1);y=rng.uniform(-.5,.5);s=rng.uniform(.10,.24)
   pebble(m,(x,y,-.06),(s*1.5,s,.08+rng.random()*.08),(.26,.225,.16),rng)
  for i in range(19):blade(m,(rng.uniform(-.8,.8),rng.uniform(-.5,.5),0),rng.random()*math.tau,.16,.13,.014,(.24,.20,.067),lean=.1)
 else:mineral(m,rng)
 ob=m.obj('LAND03 '+role,mat);ob['purpose']=purposes[idx];ob['collision']='Cosmetic host/plant joins; native terrain remains authoritative'
 ob.data.update();ob.data.calc_loop_triangles();bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
 path=OUT/(role+'.glb');bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_all_vertex_colors=True)
 coords=[v.co for v in ob.data.vertices]
 forms[role]={'purpose':purposes[idx],'triangles':len(ob.data.loop_triangles),'vertices':len(coords),'width_m':2*max(math.hypot(v.x,v.y) for v in coords),'height_m':max(v.z for v in coords),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'steppe-production.blend'),compress=True)
report={'forms':forms,'method':'Original direct scripted Blender meshes and vertex materials. No image-to-3D, third-party art or reference pixels.','source':str(SOURCE/'steppe-production.blend'),'coordinate_system':'Metres; Blender Z up, standard glTF Y up.'}
(OUT.parent/'source.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');(SOURCE/'source.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('LAND03_ART '+json.dumps(report))
