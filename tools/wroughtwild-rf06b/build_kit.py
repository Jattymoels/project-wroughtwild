"""RF06B original wetland foliage; editable Blender geometry in metres."""
import bpy, math, random, json, sys, shutil, hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/wroughtwild-art07/b2'))
from geometry import Mesh,tube,leaf
SOURCE=Path('D:/Wroughtwild/source-art/rf06b-fen-art')
OUT=ROOT/'game/rf06b/assets'
cfg=json.loads((ROOT/'tools/wroughtwild-rf06b/art.json').read_text(encoding='utf-8'))
SOURCE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
mat=bpy.data.materials.new('RF06B folded wetland leaves and weathered fibre');mat.use_nodes=True;mat.use_backface_culling=False
p=mat.node_tree.nodes.get('Principled BSDF');p.inputs['Roughness'].default_value=.94
attr=mat.node_tree.nodes.new('ShaderNodeVertexColor');attr.layer_name='Plant colour'
mat.node_tree.links.new(attr.outputs['Color'],p.inputs['Base Color'])
# Curved folded blade: many growing points, broad middle and tapered curled tip.
def blade(m,root,angle,length,height,width,color,sections=7,curl=.14):
 d=Vector((math.cos(angle),math.sin(angle),0));side=Vector((-d.y,d.x,0));start=len(m.v)
 for j in range(sections):
  t=j/(sections-1);tip=t**2
  mid=Vector(root)+d*(length*(t*.35+t*t*.65))+Vector((0,0,height*math.sin(t*math.pi*.70)-curl*tip))
  shape=(.20+.80*math.sin(math.pi*t)**.7)*(1-t)**.3 if t<1 else .008
  c=Vector((.026,.043,.017)).lerp(Vector(color),min(1,t*3))
  c=c.lerp(Vector((.16,.13,.052)),max(0,t-.82)*.7)
  for k in [-1,0,1]:m.vert(mid+side*width*shape*k+Vector((0,0,(1-abs(k))*width*.27)),(k*.5+.5,t),tuple(c*(1.08 if k==0 else .93 if k<0 else 1)))
 for j in range(sections-1):
  for k in range(2):
   a=start+j*3+k;m.face(a,a+3,a+4,a+1)
forms={}
for role in ['sedge-spread','sedge-crescent','rush-fan','fern-bower','root-weave']:
 rng=random.Random(cfg['seed']+len(forms)*491);m=Mesh()
 if role.startswith('sedge'):
  for i in range(cfg['sedge_blades']):
   a=rng.random()*math.tau;r=rng.random()**.5*.50
   root=Vector((r*math.cos(a),r*math.sin(a)*.66,0))
   direction=a+rng.uniform(-.5,.5) if role=='sedge-spread' else rng.uniform(-.4,2.6)
   dry=i%8==0
   color=(.135,.119,.038) if dry else ((.066,.137,.045) if i%3 else (.09,.175,.055))
   blade(m,root,direction,rng.uniform(.23,.54),rng.uniform(.14,.34),rng.uniform(.022,.044),color,curl=.06)
 elif role=='rush-fan':
  for i in range(cfg['rush_stems']):
   a=rng.uniform(-.8,2.7);rad=rng.random()**.5*.28
   root=Vector((math.cos(i*2.4)*rad,math.sin(i*2.4)*rad*.7,0))
   h=rng.uniform(.65,1.25);lean=rng.uniform(.19,.5);d=Vector((math.cos(a),math.sin(a),0))
   path=[root+d*(lean*t*t)+Vector((0,0,h*t)) for t in [0,.25,.5,.75,1]]
   tube(m,path,[.012,.011,.009,.007,.002],(.10,.16,.058),sides=5)
   for j in range(2):
    base=root+Vector((0,0,h*(.14+j*.2)))+d*lean*.1
    blade(m,base,a+(-1 if j else 1)*rng.uniform(.3,1.2),rng.uniform(.35,.60),h*.48,rng.uniform(.025,.043),(.075,.16,.065),curl=.16)
  # Broad basal rosettes tie upright stems down to the low living layer.
  for i in range(24):blade(m,(0,0,0),rng.random()*math.tau,rng.uniform(.28,.65),.22,.029,(.10,.155,.05),curl=.06)
 elif role=='fern-bower':
  for i in range(cfg['fern_fronds']):
   a=i*2.399+rng.uniform(-.3,.3);d=Vector((math.cos(a),math.sin(a),0));cross=Vector((-d.y,d.x,0))
   length=rng.uniform(.62,.87);height=rng.uniform(.42,.70)
   path=[d*(length*t)+Vector((0,0,height*math.sin(t*math.pi*.78))) for t in [0,.2,.4,.6,.8,1]]
   tube(m,path,[.014,.013,.012,.010,.006,.001],(.073,.105,.033),sides=5)
   for j in range(1,9):
    t=j/10;at=d*length*t+Vector((0,0,height*math.sin(t*math.pi*.78)))
    for side in [-1,1]:
     direction=(cross*side*.83+d*.50+Vector((0,0,.11))).normalized()
     leaf(m,at,direction,(.26*(1-t)+.065),.052*(1-t)+.014,(.047,.137,.058) if j%3 else (.074,.176,.071),detail=1)
 elif role=='root-weave':
  for i in range(5):
   a=rng.uniform(-.9,.9);length=rng.uniform(.65,.9)
   path=[Vector((-length+2*length*t,.17*math.sin(t*math.pi*2+i)+i*.065,.035+.12*math.sin(t*math.pi))) for t in [0,.2,.4,.6,.8,1]]
   tube(m,path,[.016,.06,.075,.07,.045,.009],(.075+i*.006,.060+i*.004,.033),sides=7)
  for i in range(30):
   root=(rng.uniform(-.6,.6),rng.uniform(-.30,.35),.03)
   blade(m,root,rng.random()*math.tau,.26,.18,.035,(.064,.115,.037),curl=.04)
 ob=m.obj('RF06B '+role,mat)
 ob['purpose']=cfg['purpose'][role];ob['author']='Original scripted Blender mesh, RF06B';ob['collision']='None; cosmetic only'
 # Model asymmetry is kept. Recenter horizontally and seat the lowest root.
 bounds=[v.co.copy() for v in ob.data.vertices];cx=(min(v.x for v in bounds)+max(v.x for v in bounds))*.5;cy=(min(v.y for v in bounds)+max(v.y for v in bounds))*.5
 floor=min(v.z for v in bounds)
 for v in ob.data.vertices:v.co-=Vector((cx,cy,floor))
 ob.data.update();ob.data.calc_loop_triangles()
 bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
 path=OUT/(role+'.glb');bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_all_vertex_colors=True)
 coords=[v.co for v in ob.data.vertices]
 forms[role]={'triangles':len(ob.data.loop_triangles),'vertices':len(coords),'width_m':2*max(math.hypot(v.x,v.y) for v in coords),'height_m':max(v.z for v in coords),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'rf06b-wetland-master.blend'),compress=True)
report={'forms':forms,'method':'Direct original Blender foliage; no reconstruction, external assets or reference pixels.','coordinate_system':'Metres; Blender Z up, standard glTF Y up.','source':str(SOURCE/'rf06b-wetland-master.blend')}
(SOURCE/'source.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
(ROOT/'game/rf06b/source.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
for name in ['build_kit.py','art.json']:shutil.copy2(ROOT/'tools/wroughtwild-rf06b'/name,SOURCE/name)
print('RF06B_ART '+json.dumps(report))
