"""Blender import and actual multi-angle source inspection; no donor writes."""
import bpy,json,sys,math
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent))
from inputs import DEPOT,PACKAGES,ROOT
out=Path(sys.argv[sys.argv.index('--')+1]).resolve();assert out.is_relative_to(ROOT/'build/art07/f4');out.mkdir(parents=True,exist_ok=False)
sources={'drum':DEPOT/PACKAGES['f2'][0]/'source/devices/winch.glb','membrane':DEPOT/PACKAGES['f3'][0]/'source/ventlung_bellows.glb','forge':DEPOT/PACKAGES['e2'][0]/'runtime/forge_basic_near.glb'}
audit={}
for name,path in sources.items():
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(path));objs=list(bpy.context.scene.objects)
 audit[name]=[{'name':o.name,'type':o.type,'parent':o.parent.name if o.parent else None,'location':list(o.location),'scale':list(o.scale),'materials':[m.name if m else None for m in o.data.materials] if o.type=='MESH' else []} for o in objs]
 s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.device='CPU';s.cycles.samples=20;s.render.resolution_x=900;s.render.resolution_y=800;s.render.resolution_percentage=100
 s.world=bpy.data.worlds.new('Inspection world');s.world.color=(.22,.22,.22)
 for at,power in [((3,-4,5),850),((-3,-1,3),650),((0,4,4),900)]:
  bpy.ops.object.light_add(type='AREA',location=at);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=4;o.rotation_euler=(Vector((0,0,.7))-o.location).to_track_quat('-Z','Y').to_euler()
 bpy.ops.object.camera_add();s.camera=bpy.context.object;s.camera.data.type='ORTHO';s.camera.data.ortho_scale=2.8
 for label,at in [('front',(0,-4,1.5)),('back',(0,4,1.5)),('side',(4,0,1.5)),('three-quarter',(3,-4,2.7)),('top',(0,0,5)),('underside',(2,-3,-2))]:
  s.camera.location=at;s.camera.rotation_euler=(Vector((0,0,.85))-s.camera.location).to_track_quat('-Z','Y').to_euler();s.render.filepath=str(out/(name+'-'+label+'.png'));bpy.ops.render.render(write_still=True)
(out/'nodes.json').write_text(json.dumps(audit,indent=2));print('F4_DONOR_INSPECTION_OK')
