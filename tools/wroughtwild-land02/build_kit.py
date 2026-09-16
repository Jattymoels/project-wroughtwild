"""Original LAND-02 kit. Reproducible authored shapes in metres, Blender Z-up.
No reference pixels/external assets. Native terrain owns all ridge/cut collision.
"""
import bpy, math, random, sys, json, hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/wroughtwild-art07/b2'))
from geometry import Mesh,tube,leaf
OUT=ROOT/'game/land02/assets';SOURCE=ROOT/'build/land02/source-art'
OUT.mkdir(parents=True,exist_ok=True);SOURCE.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
mat=bpy.data.materials.new('Scarwater living wood and layered mineral');mat.use_nodes=True;mat.use_backface_culling=False
bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.92
vc=mat.node_tree.nodes.new('ShaderNodeVertexColor');vc.layer_name='Plant colour';mat.node_tree.links.new(vc.outputs['Color'],bs.inputs['Base Color'])
forms={}
def export(role,m,purpose):
 ob=m.obj('LAND02 '+role,mat);ob['purpose']=purpose;ob['author']='Original Wroughtwild LAND-02 scripted Blender geometry';ob['units']='metres'
 bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
 bpy.ops.export_scene.gltf(filepath=str(OUT/(role+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_all_vertex_colors=True)
 ob.data.calc_loop_triangles();forms[role]={'triangles':len(ob.data.loop_triangles),'purpose':purpose,'sha256':hashlib.sha256((OUT/(role+'.glb')).read_bytes()).hexdigest()}
def wood_tube(m,path,radii,rng,sides=9):
 start=len(m.v);tube(m,path,radii,(.17,.12,.063),sides=sides)
 for i in range(start,len(m.v)):
  ring=(i-start)//sides;j=(i-start)%sides
  shade=.70+.35*(j%3)+.10*math.sin(ring*2+j)
  m.colors[i]=(.17*shade,.128*shade,.080*shade,1)
def spray(m,base,direction,rng,length=1.1):
 direction=Vector(direction).normalized();cross=Vector((-direction.y,direction.x,.18)).normalized()
 for j in range(5):
  at=base+direction*length*(j/5)
  for side in [-1,1]:
   d=(direction*.48+cross*side*.8+Vector((0,0,rng.uniform(-.35,.4)))).normalized()
   tone=rng.choice([(.12,.23,.055),(.17,.29,.078),(.095,.175,.04),(.22,.30,.075)])
   leaf(m,at,d,rng.uniform(.27,.49),rng.uniform(.12,.19),tone,detail=2)
 leaf(m,base+direction*length,direction,.38,.16,(.21,.29,.08),detail=2)
for variant in range(2):
 rng=random.Random(92022+variant*973);m=Mesh();h=16 if variant==0 else 12.5
 # Eccentric bole and long buttress roots brace the same physical load.
 path=[Vector((.12*math.sin(t*5)+t*t*(1.5 if variant else .7),.25*math.sin(t*4),h*t)) for t in [0,.12,.25,.42,.58,.75,1]]
 wood_tube(m,path,[.78,.58,.50,.40,.27,.13,.025],rng,12)
 for k in range(7):
  a=k*math.tau/7+rng.uniform(-.15,.15);d=Vector((math.cos(a),math.sin(a),0));length=rng.uniform(1.7,3.1)*(1.3 if d.x<0 else .8)
  root=[Vector((0,0,1.6)),d*.65+Vector((0,0,.5)),d*length*.55+Vector((0,0,.14)),d*length+Vector((0,0,-.12))]
  wood_tube(m,root,[.34,.26,.13,.012],rng,8)
 # Tall gallery crown / open spreading fork. Branch-level asymmetry produces
 # two recognisable silhouettes; crowns have foliage volume, not flat umbrellas.
 for k in range(11):
  t=.40+k*.048;origin=Vector((t*t*(1.5 if variant else .7),.1,h*t));a=k*2.399+rng.uniform(-.35,.35)
  reach=(4.4 if variant else 3.6)*(1-.40*(k/11));d=Vector((math.cos(a),math.sin(a),0))
  tip=origin+d*reach+Vector((0,0,2.0+rng.random()*1.2))
  mid=origin+d*reach*.44+Vector((0,0,.65))
  wood_tube(m,[origin,mid,tip],[.20,.11,.025],rng,8)
  for j in range(7):
   q=j/7;root=mid.lerp(tip,q);angle=a+(-1 if j%2 else 1)*rng.uniform(.6,1.6)
   out=Vector((math.cos(angle),math.sin(angle),rng.uniform(.2,.65)))
   end=root+out*rng.uniform(1.1,2.0)
   wood_tube(m,[root,(root+end)*.5+Vector((0,0,.15)),end],[.04,.021,.004],rng,5)
   for n in range(3):spray(m,root.lerp(end,n/3),out+Vector((rng.uniform(-.5,.5),rng.uniform(-.5,.5),.2)),rng,length=.8)
 export('gallery-column' if variant==0 else 'gallery-fork',m,'Harvestable existing tree; tall interlocking bank canopy and asymmetric braced roots, unchanged resource rules.')
# Polygonal weathered bedding, irregular long edges and offset layers.
def slab(m,rng,cx,cy,cz,sx,sy,sz,color):
 base=len(m.v);n=9
 for ring in range(2):
  for k in range(n):
   a=k*math.tau/n;w=1+rng.uniform(-.12,.12)
   p=(cx+math.cos(a)*sx*.5*w+(ring-.5)*.20,cy+math.sin(a)*sy*.5*w,cz+(ring-.5)*sz+rng.uniform(-.075,.075))
   m.vert(p,(k/n,ring),tuple(c*(1.12 if ring else .71) for c in color))
 m.face(*[base+i for i in reversed(range(n))]);m.face(*[base+n+i for i in range(n)])
 for k in range(n):m.face(base+k,base+(k+1)%n,base+(k+1)%n+n,base+k+n)
for variant in range(3):
 rng=random.Random(92600+variant);m=Mesh()
 for j in range(5):
  slab(m,rng,-.13*j,.07*math.sin(j),-.32+j*.25,3.7-j*.25,2.3-j*.12,.31,(.26+j*.007,.27+j*.005,.245+j*.007))
 export('strata-'+str(variant),m,'Low layered mineral ribs seated into the native displaced ridge; decorative, no separate uneditable collider.')
for variant in range(2):
 rng=random.Random(92700+variant);m=Mesh()
 for j in range(5):slab(m,rng,-1.2+j*.62,.16*math.sin(j*1.3),-.12,.90,.65,.36,(.26,.29,.23))
 for j in range(4):
  path=[Vector((-1.7+q*3.4,j*.12+.14*math.sin(q*5+j),.08+.09*math.sin(q*math.pi))) for q in [0,.2,.4,.6,.8,1]]
  wood_tube(m,path,[.012,.11,.14,.12,.06,.008],rng,7)
 export('root-bank-'+str(variant),m,'Irregular shallow stone/root join for native lips and gallery banks; no bridge across fissure.')
for variant in range(2):
 rng=random.Random(92800+variant);m=Mesh()
 for k in range(8):
  a=k*2.399;d=Vector((math.cos(a),math.sin(a),0));height=rng.uniform(.48,1.05)
  root=d*rng.uniform(.03,.25);tip=root+d*.6+Vector((0,0,height))
  wood_tube(m,[root,tip*.5+Vector((0,0,.17)),tip],[.025,.018,.002],rng,5)
  for n in range(3):spray(m,root.lerp(tip,.25+n*.22),d+Vector((0,0,.35)),rng,.48)
 export('underwood-'+str(variant),m,'Connected broad-leaf middle growth with open passage edges, sheltered root fans and living meadow joins.')
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'scarwater-kit.blend'),compress=True)
report={'author':'Original scripted Blender kit, 16 September 2026','recipe':'tools/wroughtwild-land02/build_kit.py','master':str(SOURCE/'scarwater-kit.blend'),'units':'metres, Blender Z up / glTF Y up','forms':forms}
(OUT.parent/'source.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('LAND02_ART '+json.dumps(report))
