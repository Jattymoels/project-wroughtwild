"""Preserve inspected TRELLIS source; fit depth, carve attached geometric wounds.
No glow mask substitutes for geometry. Original textures/UVs remain immutable.
"""
import bpy,sys,math,json,shutil
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree
ROOT=Path(__file__).resolve().parents[3]
inspection,out=map(lambda s:Path(s).resolve(),sys.argv[sys.argv.index('--')+1:]);assert out.is_relative_to(ROOT/'build/art07/f2');out.mkdir(parents=True,exist_ok=False)
bpy.ops.wm.open_mainfile(filepath=str(inspection/'inspected-source.blend'))
source=next(o for o in bpy.context.scene.objects if o.type=='MESH')
source.name='OriginalInspectedSource';rawcopy=source.copy();rawcopy.data=source.data.copy();bpy.context.collection.objects.link(rawcopy);source.hide_render=True;source.hide_set(True)
finished=rawcopy;finished.name='ThrumrootFinishedMaster'
depth_scale=.71/1.3234434116701252
for ve in finished.data.vertices:ve.co.y*=depth_scale
finished.data.update()
before=[v.co.copy() for v in finished.data.vertices]
bvh=BVHTree.FromPolygons(before,[list(p.vertices) for p in finished.data.polygons])
routes=[
 [(-.85,.09),(-.69,.16),(-.54,.27),(-.45,.43),(-.36,.57),(-.29,.71)],
 [(.88,.09),(.70,.18),(.57,.26),(.48,.38),(.42,.46)],
 [(-.39,.43),(-.25,.36),(-.10,.32),(.06,.30),(.22,.33),(.40,.42)],
 [(-.71,.55),(-.49,.61),(-.26,.60),(-.02,.53),(.21,.46)]
]
samples=[]
for route in routes:
    for a,b in zip(route,route[1:]):
        steps=max(2,int(math.dist(a,b)/.004))
        for i in range(steps):
            t=i/steps;x=a[0]*(1-t)+b[0]*t;z=a[1]*(1-t)+b[1]*t
            hit,normal,index,distance=bvh.ray_cast(Vector((x,-1,z)),Vector((0,1,0)),2)
            if hit is not None:samples.append(hit)
assert len(samples)>200
kd=KDTree(len(samples))
for i,p in enumerate(samples):kd.insert(p,i)
kd.balance();depths=[]
for ve in finished.data.vertices:
    co,index,dist=kd.find(ve.co)
    influence=max(0,1-dist/.046)
    incision=.026*influence*influence
    # Signed recess along the front ray; cannot bridge the void between roots.
    ve.co.y+=incision;depths.append(incision)
finished.data.update()
colour=finished.data.color_attributes.new(name='ScarWeights',type='FLOAT_COLOR',domain='POINT')
for i,d in enumerate(depths):colour.data[i].color=(min(1,d/.008),max(0,(d-.018)/.008)**2,0,1)
finished.data.color_attributes.active_color=colour
living=finished.data.materials[0].copy();living.name='Thrumroot layered wound surface';finished.data.materials[0]=living
n=living.node_tree.nodes;l=living.node_tree.links;p=n.get('Principled BSDF')
tex=next(o for o in n if o.type=='TEX_IMAGE')
attrib=n.new('ShaderNodeVertexColor');attrib.layer_name='ScarWeights';sep=n.new('ShaderNodeSeparateColor');l.new(attrib.outputs['Color'],sep.inputs[0])
mix=n.new('ShaderNodeMixRGB');mix.inputs[2].default_value=(.018,.012,.006,1);l.new(sep.outputs['Red'],mix.inputs[0]);l.new(tex.outputs['Color'],mix.inputs[1])
inner=n.new('ShaderNodeMixRGB');inner.inputs[2].default_value=(.07,.11,.05,1);l.new(sep.outputs['Green'],inner.inputs[0]);l.new(mix.outputs[0],inner.inputs[1]);l.new(inner.outputs[0],p.inputs['Base Color'])
p.inputs['Emission Color'].default_value=(.18,.26,.12,1);l.new(sep.outputs['Green'],p.inputs['Emission Strength'])
emission_gain=n.new('ShaderNodeMath');emission_gain.operation='MULTIPLY';emission_gain.inputs[1].default_value=.25;l.new(sep.outputs['Green'],emission_gain.inputs[0]);l.new(emission_gain.outputs[0],p.inputs['Emission Strength'])
finished.data.update()
assert sum(d>.018 for d in depths)>100
report={'raw_inspection':str(inspection),'initial_uniform_width_m':2.14,'finishing_depth_scale':depth_scale,'finishing_reason':'Generated roots were 1.323m deep; fitting only depth preserves 2.14m length and .792m height inside original 2.2 x .9 x .75 native body.','groove_radius_m':.046,'requested_depth_m':.026,'measured_max_vertex_recession_m':max(depths),'vertices_deeper_than_18mm':sum(d>.018 for d in depths),'surface_samples':len(samples),'routes_xz':routes,'levels':{}}
# Compare before/after same-ray surfaces at central samples, not shader values.
after_bvh=BVHTree.FromPolygons([ve.co for ve in finished.data.vertices],[list(p.vertices) for p in finished.data.polygons])
ray_depths=[]
for p in samples:
    hit,_,_,_=after_bvh.ray_cast(Vector((p.x,-1,p.z)),Vector((0,1,0)),2)
    if hit is not None and 0<hit.y-p.y<.05:ray_depths.append(hit.y-p.y)
ray_depths.sort();report['same_ray_depth_m']={'count':len(ray_depths),'median':ray_depths[len(ray_depths)//2],'max':max(ray_depths)}
assert report['same_ray_depth_m']['median']>.012
finished.hide_render=True;finished.hide_set(True)
levels=[]
for name,target in [('near',64000),('middle',26000),('far',9000)]:
    o=finished.copy();o.data=finished.data.copy();bpy.context.collection.objects.link(o);o.hide_set(False);o.hide_render=False;o.name='Thrumroot_'+name
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
    o.data.calc_loop_triangles();mod=o.modifiers.new('Silhouette and scar reduction '+name,'DECIMATE');mod.ratio=min(1,target/len(o.data.loop_triangles));mod.use_collapse_triangulate=True;bpy.ops.object.modifier_apply(modifier=mod.name)
    o.data.calc_loop_triangles();stats={'triangles':len(o.data.loop_triangles),'surfaces':len(set(f.material_index for f in o.data.polygons)),'degenerate_triangles':sum(t.area<1e-12 for t in o.data.loop_triangles),'nonfinite_vertices':sum(not all(math.isfinite(c) for c in ve.co) for ve in o.data.vertices)}
    assert stats['degenerate_triangles']==0 and stats['nonfinite_vertices']==0
    report['levels'][name]=stats
    colour_args={}
    props=bpy.ops.export_scene.gltf.get_rna_type().properties
    if 'export_vertex_color' in props:colour_args['export_vertex_color']='ACTIVE'
    if 'export_all_vertex_colors' in props:colour_args['export_all_vertex_colors']=True
    bpy.ops.export_scene.gltf(filepath=str(out/('thrumroot-'+name+'.glb')),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,**colour_args)
    levels.append(o);o.hide_render=True
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(out/'f2-thrumroot.blend'))
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.device='CPU';s.cycles.samples=24;s.render.resolution_x=1440;s.render.resolution_y=900;s.render.resolution_percentage=100;s.world.color=(.20,.20,.20)
for at,power,size in [((2,-3,5),1000,4),((-3,1,2),750,3)]:
    bpy.ops.object.light_add(type='AREA',location=at);o=bpy.context.object;o.data.energy=power;o.data.size=size;o.rotation_euler=(Vector((0,0,.4))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();s.camera=bpy.context.object;s.camera.data.type='ORTHO';s.camera.data.ortho_scale=2.6
for level in levels:
    level.hide_render=False
    for view,at in [('front',(0,-4,1)),('back',(0,4,1)),('side',(4,0,1)),('three-quarter',(2.5,-4,2)),('top',(0,0,5)),('underside',(1,-3,-2))]:
        if level!=levels[0] and view!='three-quarter':continue
        s.camera.location=at;s.camera.rotation_euler=(Vector((0,0,.40))-s.camera.location).to_track_quat('-Z','Y').to_euler()
        s.render.filepath=str(out/(level.name+'-'+view+'.png'));bpy.ops.render.render(write_still=True)
    if level==levels[0]:
        for on in [False,True]:
            emission_gain.inputs[1].default_value=.8 if on else 0
            s.camera.location=(0,-3,.85);s.camera.rotation_euler=(Vector((0,0,.40))-s.camera.location).to_track_quat('-Z','Y').to_euler();s.render.filepath=str(out/('scar-'+('peak' if on else 'off')+'.png'));bpy.ops.render.render(write_still=True)
    level.hide_render=True
shutil.copy2(ROOT/'build/art07/f2/v01/generated/source_base.png',out/'thrumroot-albedo.png')
(out/'geometry.json').write_text(json.dumps(report,indent=2)+'\n');print('F2_SOURCE_FINISHED',report)
