"""RF-02 Blender grass using the retained B2 Mesh/curved-strip authoring method.
Only four selected B2 GLBs are inspected, never the parent package/master.
Original B2 and reference files are read-only. All new forms remain editable.
"""
import bpy, sys, math, random, json, hashlib, shutil
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/wroughtwild-art07/b2'))
from geometry import Mesh
SOURCE=Path('D:/Wroughtwild/source-art/rf02-ground-grass')
OUT=ROOT/'game/rf02/assets'
RETAINED=Path('C:/Users/Matty/Dev/project-wroughtwild/build/art07/b2/worktree/build/art07/b2/v10/handoff/review/assets')
cfg=json.loads((ROOT/'tools/wroughtwild-rf02/grass.json').read_text())
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
report={'inspected_inputs':{},'forms':{},'coordinates':'metres, Blender Z up; standard glTF Y-up export'}
for role in ['grass-meadow','grass-edge']:
    for lod in [0,1]:
        path=RETAINED/(role+'-lod'+str(lod)+'.glb')
        bpy.ops.import_scene.gltf(filepath=str(path))
        obs=list(bpy.context.selected_objects)
        meshobs=[o for o in obs if o.type=='MESH']
        points=[o.matrix_world@v.co for o in meshobs for v in o.data.vertices]
        for o in meshobs:o.data.calc_loop_triangles()
        report['inspected_inputs'][path.name]={'path':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'vertices':len(points),'triangles':sum(len(o.data.loop_triangles) for o in meshobs),'min':[min(v[k] for v in points) for k in range(3)],'max':[max(v[k] for v in points) for k in range(3)]}
        for o in obs:bpy.data.objects.remove(o,do_unlink=True)
mat=bpy.data.materials.new('RF02 rooted blade colour');mat.use_nodes=True;mat.use_backface_culling=False
nodes=mat.node_tree.nodes;p=nodes.get('Principled BSDF');p.inputs['Roughness'].default_value=.94
attr=nodes.new('ShaderNodeVertexColor');attr.layer_name='Plant colour'
mat.node_tree.links.new(attr.outputs['Color'],p.inputs['Base Color'])
def smooth(t):
    t=min(1,max(0,t*1.6));return t*t*(3-2*t)
SOURCE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
for role,n in cfg['blades'].items():
    rng=random.Random(cfg['seed']+(role=='edge'))
    m=Mesh()
    for i in range(n):
        a=rng.random()*math.tau
        # Several growing points and short outward basal blades soften each root.
        basal=i%4==0
        r=math.sqrt(rng.random())*(.24 if role=='meadow' else .20)
        root=Vector((r*math.cos(a),r*math.sin(a),0))
        direction=a+rng.uniform(-1.1,1.1) if role=='meadow' else rng.uniform(-.8,1.8)
        d=Vector((math.cos(direction),math.sin(direction),0));u=Vector((-d.y,d.x,0))
        h=rng.uniform(.20,.38) if role=='meadow' else rng.uniform(.11,.25)
        if basal:h*=.45
        lean=rng.uniform(.08,.22) if role=='meadow' else rng.uniform(.17,.29)
        if basal:lean*=1.05
        width=rng.uniform(*cfg['half_width_m'])
        green=Vector((.105,.155,.045)) if i%7 else Vector((.15,.155,.062))
        green*=rng.uniform(.79,1.10)
        start=len(m.v)
        for j in range(cfg['sections']):
            t=j/cfg['sections']
            centre=root+d*(lean*t*t)+Vector((0,0,h*(math.sin(t*1.7)/math.sin(1.7))))
            shape=(.52+.56*math.sin(t*math.pi))*(1-t)**.55
            color=Vector((.037,.045,.016)).lerp(green,smooth(t))
            for side in [-1,0,1]:
                ridge=(1-abs(side))*width*.32*math.sin(t*math.pi)
                v=centre+u*width*shape*side+Vector((0,0,ridge))
                c=color*(1.05 if side==0 else .96 if side<0 else 1)
                m.vert(v,(side*.5+.5,t),tuple(c))
        tip=m.vert(root+d*lean+Vector((0,0,h)),(.5,1),tuple(green*.89))
        for j in range(cfg['sections']-1):
            for k in range(2):
                a0=start+j*3+k;m.face(a0,a0+3,a0+4,a0+1)
        a0=start+(cfg['sections']-1)*3;m.face(a0,tip,a0+1);m.face(a0+1,tip,a0+2)
    ob=m.obj('RF02 '+role+' rooted clump',mat)
    ob['design_purpose']='Curved, folded blades with short basal growth; no collision or harvest identity.'
    # Fit the source to RF01's existing circular envelope, before its own fit.
    coords=[v.co for v in ob.data.vertices]
    cx=(min(v.x for v in coords)+max(v.x for v in coords))*.5
    cy=(min(v.y for v in coords)+max(v.y for v in coords))*.5
    radius=max(math.hypot(v.x-cx,v.y-cy) for v in coords)
    peak=max(v.z for v in coords)
    for v in ob.data.vertices:
        v.co.x=(v.co.x-cx)*.47/radius;v.co.y=(v.co.y-cy)*.47/radius
        v.co.z*=((.38 if role=='meadow' else .2508)/peak)
    ob.data.update();ob.data.calc_loop_triangles()
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
    path=OUT/('grass-'+role+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_all_vertex_colors=True)
    report['forms'][role]={'blades':n,'triangles':len(ob.data.loop_triangles),'vertices':len(ob.data.vertices),'radius_m':.47,'height_m':.38 if role=='meadow' else .2508,'surfaces':1,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'rf02-grass-master.blend'),compress=True)
(SOURCE/'grass-source.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
for name in ['build_grass.py','grass.json']:shutil.copy2(ROOT/'tools/wroughtwild-rf02'/name,SOURCE/name)
print('RF02_GRASS_OK '+json.dumps(report))
