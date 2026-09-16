"""One original woodland creeping mat, using the established Blender pipeline."""
import bpy, math, random, sys, json, shutil
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/wroughtwild-art07/b2'))
from geometry import Mesh,leaf,tube
SOURCE=Path('D:/Wroughtwild/source-art/rf08-impact-scars')
OUT=ROOT/'game/rf08/assets'
SOURCE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
mat=bpy.data.materials.new('RF08 matte woodland runners');mat.use_nodes=True;mat.use_backface_culling=False
shader=mat.node_tree.nodes.get('Principled BSDF');shader.inputs['Roughness'].default_value=.94
color=mat.node_tree.nodes.new('ShaderNodeVertexColor');color.layer_name='Plant colour'
mat.node_tree.links.new(color.outputs['Color'],shader.inputs['Base Color'])
m=Mesh();rng=random.Random(90877)
for branch in range(5):
 angle=branch*2.399+.3;d=Vector((math.cos(angle),math.sin(angle),0));side=Vector((-d.y,d.x,0))
 root=Vector((-.05,.025,.018));length=rng.uniform(.20,.29)
 path=[root+d*(length*t)+side*(.025*math.sin(t*math.pi*2+branch))+Vector((0,0,.035*math.sin(t*math.pi))) for t in [0,.25,.5,.75,1]]
 tube(m,path,[.006,.005,.004,.003,.001],(.10,.09,.027),sides=4)
 for j in range(1,4):
  t=j/4;at=root+d*length*t+Vector((0,0,.028+.024*math.sin(t*math.pi)))
  for sign in [-1,1]:
   direction=(d*.35+side*sign*.82+Vector((0,0,.24+rng.random()*.2))).normalized()
   tint=(.070+rng.random()*.035,.15+rng.random()*.065,.035+rng.random()*.026)
   leaf(m,at,direction,rng.uniform(.11,.17),rng.uniform(.038,.063),tint,detail=1,ivy=True)
ob=m.obj('RF08 creeping broadleaf recovery',mat)
# Keep one rooted sub-cell footprint, with asymmetry in its connected stems.
radius=max(math.hypot(v.co.x,v.co.y) for v in ob.data.vertices)
for v in ob.data.vertices:v.co.x*=.315/radius;v.co.y*=.315/radius
ob['purpose']='Low living growth connecting old impact damage; no collision or yield.'
ob.data.calc_loop_triangles()
bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
bpy.ops.export_scene.gltf(filepath=str(OUT/'creeping-mat.glb'),export_format='GLB',use_selection=True,export_animations=False,export_all_vertex_colors=True)
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'rf08-creeping-mat.blend'),compress=True)
report={'master':str(SOURCE/'rf08-creeping-mat.blend'),'recipe':'tools/wroughtwild-rf08/build_mat.py','triangles':len(ob.data.loop_triangles),'radius_m':.315,'height_m':max(v.co.z for v in ob.data.vertices),'method':'Original direct Blender geometry; no external inputs.'}
(ROOT/'game/rf08/source.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
(SOURCE/'source.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
shutil.copy2(__file__,SOURCE/'build_mat.py')
print('RF08_ART',json.dumps(report))
