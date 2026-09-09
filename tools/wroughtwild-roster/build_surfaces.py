"""Blender: authored surface scars on one of the six retained ART-06 sources.

-- ASSET NEW_OUTPUT [--probe]. Probe projects routes without changing geometry.
All image inputs are existing raw textures; the new map is a geometry/UV bake.
"""
import hashlib
import json
import struct
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

args = sys.argv[sys.argv.index('--')+1:]
asset, output = args[0], Path(args[1]).resolve()
probe = '--probe' in args
repo = Path(__file__).resolve().parents[2]
recipe = Path(__file__).parent
config_path = recipe/(args[args.index('--config')+1] if '--config' in args else 'surface-study.json')
config = json.loads(config_path.read_text(encoding='utf-8'))
row = next(x for x in config['assets'] if x['id'] == asset)
source_row = next(x for x in json.loads((recipe/'roster.json').read_text(encoding='utf-8'))['assets'] if x['id'] == asset)
source = repo/'build/roster-art06'/f"{asset}-source-{source_row['version']}"/(asset+'.glb')
evidence = repo/'docs/art/leyline-studies/2026-09-09/roster-art06'/asset
inspection = json.loads((evidence/'inspection.json').read_text(encoding='utf-8'))
digest = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
assert digest(source) == inspection['source_sha256']
assert output.is_relative_to(repo/'build') and not output.exists()
output.mkdir(parents=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))
hosts = [o for o in bpy.context.scene.objects if o.type == 'MESH']
assert len(hosts) == 1
host = hosts[0]
host.name = asset+' - surface host'
mesh = host.data
bpy.context.view_layer.objects.active = host
raw_points = np.array([v.co for v in mesh.vertices])
raw_faces = np.array([p.vertices[:] for p in mesh.polygons])
raw_area = np.linalg.norm(np.cross(raw_points[raw_faces[:,1]]-raw_points[raw_faces[:,0]], raw_points[raw_faces[:,2]]-raw_points[raw_faces[:,0]]),axis=1)/2
bad = np.flatnonzero(raw_area <= config['zero_area_threshold_units_squared'])
assert len(bad) == inspection['meshes'][0]['zero_area_triangles']
if len(bad):
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[bm.faces[int(i)] for i in bad], context='FACES_ONLY')
    bm.to_mesh(mesh)
    bm.free()
lo, hi = map(Vector, inspection['raw_bounds'])
centre = Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
transform = Matrix.Scale(inspection['review_uniform_scale'],4)@Matrix.Translation(-centre)
host.matrix_world = transform@host.matrix_world
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
face_report = None
if config.get('porcupine_face') and asset == 'cinder_archer':
    sys.path.insert(0,str(recipe))
    from lifeline_geometry import repair_face
    face_report = repair_face(host,config['porcupine_face'])
points = np.array([v.co[:] for v in mesh.vertices],dtype=np.float32)
faces = np.array([p.vertices[:] for p in mesh.polygons],dtype=np.int32)
bvh = BVHTree.FromPolygons(points.tolist(),faces.tolist(),all_triangles=True)
starts,ends,widths,flows0,flows1 = [],[],[],[],[]
routes = []
segment_sides = []
for path in row['paths']:
    view = next(v for v in inspection['views'] if v['name'] == path['view'])
    camera, target = Vector(view['camera']),Vector(view['target'])
    rotation = (target-camera).to_track_quat('-Z','Y').to_matrix()
    right,up,direction = rotation@Vector((1,0,0)),rotation@Vector((0,1,0)),rotation@Vector((0,0,-1))
    controls = np.array(path['pixels'],dtype=float)
    pixels = []
    for a,b in zip(controls[:-1],controls[1:]):
        count = max(2,int(np.linalg.norm(b-a)/config['projection_step_pixels'])+1)
        pixels.extend(a*(1-t)+b*t for t in np.linspace(0,1,count,endpoint=False))
    pixels.append(controls[-1])
    projected = []
    for pixel in pixels:
        origin = camera+right*((pixel[0]/1024-.5)*view['ortho_scale'])+up*((.5-pixel[1]/1024)*view['ortho_scale'])
        hit,normal,face,distance = bvh.ray_cast(origin,direction,12)
        assert hit is not None, ('Scar misses host',asset,path['name'],pixel.tolist())
        projected.append(np.array(hit))
    p = np.array(projected)
    lengths = np.linalg.norm(np.diff(p,axis=0),axis=1)
    assert lengths.max() < config['max_surface_step_units'], ('Scar jumps a cavity',asset,path['name'],float(lengths.max()))
    distance = np.r_[0,np.cumsum(lengths)]
    travel = path['offset']+distance*.72
    assert travel.max() <= 1.0, ('Travel exceeds atlas range',path['name'],travel.max())
    for i,(a,b) in enumerate(zip(p[:-1],p[1:])):
        if lengths[i] < 1e-8: continue
        taper = 1-.7*max(0,(i/max(1,len(p)-2)-.7)/.3)
        starts.append(a);ends.append(b);widths.append(path['width']*taper)
        flows0.append(travel[i]);flows1.append(travel[i+1])
        segment_sides.append(1 if camera.x>0 else -1)
    routes.append({'name':path['name'],'view':path['view'],'points':p.tolist(),'max_step_units':float(lengths.max())})
report = {'asset':asset,'source_sha256':digest(source),'config_sha256':digest(config_path),
          'source_version':source_row['version'],'removed_degenerate_face_indices':bad.tolist(),
          'source_triangles':len(raw_faces),'triangles':len(faces),'vertices':len(points),'projected_paths':routes,
          'stage':config['stage'],'blender':bpy.app.version_string}
if face_report: report['face_repair'] = face_report
if probe:
    (output/'projection.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('ROSTER_SURFACE_PROJECTION_OK',asset,flush=True)
    sys.exit(0)

a,b = np.array(starts),np.array(ends)
ab = b-a
lengths2 = (ab*ab).sum(1)
width = np.array(widths)
f0,f1 = np.array(flows0),np.array(flows1)
if config.get('flow_mode') == 'connected_distance':
    sys.path.insert(0,str(recipe))
    from lifeline_geometry import network_travel
    f0,f1,report['flow_components'] = network_travel(a,b,np.array(segment_sides),config['flow_join_radius_units'])
def smooth(x):
    x = np.clip(x,0,1)
    return x*x*(3-2*x)

def evaluate(positions):
    result = np.ones((len(positions),4),np.float32)
    for offset in range(0,len(positions),4096):
        p = positions[offset:offset+4096]
        ap = p[:,None,:]-a[None,:,:]
        t = np.clip(np.einsum('ijk,jk->ij',ap,ab)/lengths2,0,1)
        distances = np.linalg.norm(ap-t[:,:,None]*ab,axis=2)
        index = (distances/width).argmin(1)
        ix = np.arange(len(p))
        d,w = distances[ix,index],width[index]
        grain = p/config['edge_grain_units']
        variation = (np.sin(grain[:,0]*1.31+grain[:,1]*.77)*np.sin(grain[:,2]*1.73-grain[:,1]*.59)
                     + .35*np.sin(grain[:,0]*3.17+grain[:,2]*2.31))/1.35
        w = w*(1+config['width_variation']*variation)
        result[offset:offset+len(p),0] = 1-smooth((d/(config['core_half_width_units']*w)-.2)/.8)
        result[offset:offset+len(p),1] = 1-smooth((d/(config['damage_half_width_units']*w)-.42)/.58)
        result[offset:offset+len(p),2] = f0[index]+t[ix,index]*(f1[index]-f0[index])
    return result

vertex_marks = evaluate(points)
normals = np.array([v.normal[:] for v in mesh.vertices])
edges = np.array([e.vertices[:] for e in mesh.edges])
edge_length = np.linalg.norm(points[edges[:,1]]-points[edges[:,0]],axis=1)
local_cap = np.full(len(points),config['recess_units'])
np.minimum.at(local_cap,edges[:,0],edge_length*.12)
np.minimum.at(local_cap,edges[:,1],edge_length*.12)
before_cross = np.cross(points[faces[:,1]]-points[faces[:,0]],points[faces[:,2]]-points[faces[:,0]])
longest_edge = np.maximum.reduce([np.linalg.norm(points[faces[:,i]]-points[faces[:,(i+1)%3]],axis=1) for i in range(3)])
altitude_cap = np.linalg.norm(before_cross,axis=1)/longest_edge*.08
for i in range(3): np.minimum.at(local_cap,faces[:,i],altitude_cap)
deep = config.get('geometry_mode') == 'directional_channel'
depth_report = None
if deep:
    sys.path.insert(0,str(recipe))
    from lifeline_geometry import carve
    new_points,depth_report = carve(points,faces,a,b,width,np.array(segment_sides),config,routes)
    incision = np.linalg.norm(new_points-points,axis=1)
else:
    incision = np.minimum(config['recess_units']*vertex_marks[:,1]**2,local_cap)
protected = set()
# Check the actual float32 positions Blender/GLB retain, including skinny faces.
# A local face may retain its source position if even a tiny incision is unsafe.
for attempt in range(0 if deep else 14):
    new_points = (points-normals*incision[:,None]).astype(np.float32)
    after_cross = np.cross(new_points[faces[:,1]]-new_points[faces[:,0]],new_points[faces[:,2]]-new_points[faces[:,0]])
    flipped = np.flatnonzero(np.einsum('ij,ij->i',before_cross,after_cross)<=0)
    if not len(flipped): break
    affected = np.unique(faces[flipped])
    protected.update(int(i) for i in affected)
    incision[affected] *= .5 if attempt<10 else 0
after_cross = np.cross(new_points[faces[:,1]]-new_points[faces[:,0]],new_points[faces[:,2]]-new_points[faces[:,0]])
assert (np.einsum('ij,ij->i',before_cross,after_cross)>0).all(), 'Introduced flipped or zero-area face'
mesh.vertices.foreach_set('co',new_points.ravel())
mesh.update()
assert np.isfinite(new_points).all()
assert np.linalg.norm(new_points-points,axis=1).max() <= config['recess_units']+1e-6

# Preserve source albedo and ORM bytes by their declared glTF role.
raw = source.read_bytes()
length = struct.unpack_from('<I',raw,12)[0]
doc = json.loads(raw[20:20+length]);binary = raw[28+length:]
pbr = doc['materials'][0]['pbrMetallicRoughness']
for filename,role in [('base.png','baseColorTexture'),('orm.png','metallicRoughnessTexture')]:
    im = doc['images'][doc['textures'][pbr[role]['index']]['source']]
    assert im['mimeType'] == 'image/png'
    view = doc['bufferViews'][im['bufferView']]
    offset = view.get('byteOffset',0)
    (output/filename).write_bytes(binary[offset:offset+view['byteLength']])

original_material = mesh.materials[0]
material = original_material.copy()
mesh.materials[0] = material
material.name = asset+' - attached living scar'
nodes,links = material.node_tree.nodes,material.node_tree.links
shader = nodes.get('Principled BSDF')
out = next(n for n in nodes if n.type == 'OUTPUT_MATERIAL')
attribute = mesh.color_attributes.new(name='Source position for UV bake',type='FLOAT_COLOR',domain='POINT')
position_lo,span = points.min(0),points.max(0)-points.min(0)
colours = np.ones((len(points),4),np.float32)
colours[:,:3] = (points-position_lo)/span
attribute.data.foreach_set('color',colours.ravel())
attr = nodes.new('ShaderNodeAttribute');attr.attribute_name = attribute.name
mask_height=config['mask_size']+(512 if face_report else 0)
if face_report:
    from lifeline_geometry import FACE_ATLAS_ROWS
    mask_height=config['mask_size']+FACE_ATLAS_ROWS
mask = bpy.data.images.new(asset+' fracture data',width=config['mask_size'],height=mask_height,alpha=True,float_buffer=True)
mask.colorspace_settings.name = 'Non-Color'
target = nodes.new('ShaderNodeTexImage');target.image = mask;target.name = 'Attached scar map'
nodes.active = target;target.select = True
emitter = nodes.new('ShaderNodeEmission')
links.new(attr.outputs['Color'],emitter.inputs['Color']);links.new(emitter.outputs[0],out.inputs['Surface'])
scene = bpy.context.scene
scene.render.engine = 'CYCLES';scene.cycles.samples = 1
scene.render.threads_mode = 'FIXED';scene.render.threads = 8
scene.render.bake.use_selected_to_active = False;scene.render.bake.margin = 8
bpy.ops.object.select_all(action='DESELECT');host.select_set(True)
bpy.ops.object.bake(type='EMIT')
texels = np.empty(config['mask_size']*mask_height*4,np.float32)
mask.pixels.foreach_get(texels)
texels = texels.reshape((-1,4))
valid = texels[:,3]>.5
if face_report:
    from lifeline_geometry import face_atlas
    face_report['texture_audit']=face_atlas(output,texels[:,:3]*span+position_lo,valid,config['mask_size'],mask_height,[original_material,material])
marks = evaluate(texels[:,:3]*span+position_lo)
marks[~valid,:3] = 0
assert (marks[:,0] <= marks[:,1]+1e-6).all()
assert marks[:,0].max()>.9 and marks[:,1].max()>.9
assert np.ptp(marks[marks[:,0]>.1,2])>.2
mask.pixels.foreach_set(marks.ravel());mask.update()
mask.filepath_raw = str(output/'scar-mask.png');mask.file_format = 'PNG';mask.save();mask.pack()
nodes.remove(emitter);links.new(shader.outputs['BSDF'],out.inputs['Surface'])
split = nodes.new('ShaderNodeSeparateColor');links.new(target.outputs['Color'],split.inputs['Color'])
base = shader.inputs['Base Color'].links[0].from_socket
darken = nodes.new('ShaderNodeMixRGB');darken.blend_type = 'MULTIPLY';darken.inputs[0].default_value=1
darken.inputs[2].default_value=(*config['damage_tint'],1);links.new(base,darken.inputs[1])
mix = nodes.new('ShaderNodeMixRGB')
links.new(darken.outputs[0],mix.inputs[2]);links.new(split.outputs['Green'],mix.inputs[0]);links.new(base,mix.inputs[1]);links.new(mix.outputs[0],shader.inputs['Base Color'])
gain = nodes.new('ShaderNodeMath');gain.operation = 'MULTIPLY';gain.name = 'Review emission gain'
gain.inputs[1].default_value = config['peak_emission']
links.new(split.outputs['Red'],gain.inputs[0]);links.new(gain.outputs[0],shader.inputs['Emission Strength'])
shader.inputs['Emission Color'].default_value = (*row['colour'],1)
bump = nodes.new('ShaderNodeBump');bump.invert = True
bump.inputs['Distance'].default_value = config.get('bump_units',config['recess_units']);bump.inputs['Strength'].default_value = .65
links.new(split.outputs['Green'],bump.inputs['Height']);links.new(bump.outputs['Normal'],shader.inputs['Normal'])
for image in bpy.data.images:
    if image.source == 'FILE' and image.has_data: image.pack()
host['source_sha256'] = inspection['source_sha256']
host['stage'] = config['stage']
mesh.color_attributes.remove(attribute)
# Export exact finished geometry with original PBR; Godot binds the separate map.
attachments = []
if face_report:
    from lifeline_geometry import finish_face
    attachments,face_report['attachments'] = finish_face(host,config['porcupine_face'])
    bpy.ops.object.select_all(action='DESELECT')
    for obj in attachments: obj.select_set(True)
    host.select_set(True)
mesh.materials[0] = original_material
bpy.ops.export_scene.gltf(filepath=str(output/(asset+'-surface.glb')),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
mesh.materials[0] = material
report.update(max_displacement_units=float(np.linalg.norm(new_points-points,axis=1).max()),
              flipped_faces=0,mask_size=config['mask_size'],
              mask_dimensions=[config['mask_size'],mask_height],
              locally_protected_vertices=len(protected),
              core_texel_fraction=float((marks[:,0]>.05).mean()),damage_texel_fraction=float((marks[:,1]>.05).mean()),
              core_vertex_fraction=float((vertex_marks[:,0]>.05).mean()),
              geometry_sha256=hashlib.sha256(new_points.astype(np.float32).tobytes()+faces.tobytes()).hexdigest(),
              note='Texel/vertex fractions are diagnostics, not surface-area percentages. Topology/detail preserved except recorded degenerate faces. No rig or era anatomy.')
if face_report: report['note']='Dense source retained; only documented face repair changes host topology. New eyes/whiskers are separately counted head attachments. No rig or era anatomy.'
if depth_report: report['depth_audit'] = depth_report
assert 0 < report['core_texel_fraction'] < .04
assert report['core_texel_fraction'] < report['damage_texel_fraction'] < .12
(output/'surface-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(output/(asset+'-surface.blend')),compress=True)
assert digest(source) == inspection['source_sha256']
print('ROSTER_SURFACE_OK',asset,flush=True)
