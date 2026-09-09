"""Blender: bake attached fracture/core/travel data on the finished stag host.
-- FINISHED.blend NEW_OUTPUT. Uses ART-01's tested surface-ray/position-atlas method.
"""
import bpy,json,sys,hashlib,struct
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
source_file,output=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]]
repo=Path(__file__).resolve().parents[2]
cfg=json.loads(Path(__file__).with_name('stag.json').read_text(encoding='utf-8'))
scar=cfg['scar'];raw=repo/cfg['source']
assert hashlib.sha256(raw.read_bytes()).hexdigest()==cfg['source_sha256']
assert not output.exists();output.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(source_file))
host=bpy.data.objects['Vaultcrown - host'];mesh=host.data
bpy.context.view_layer.objects.active=host
points=np.array([v.co for v in mesh.vertices])
# Rays follow the actual outer coat/plates. No floating ribbon or tube is added.
bvh = BVHTree.FromPolygons([Vector(p) for p in points], [tuple(p.vertices) for p in mesh.polygons])
starts, ends, widths, flow0, flow1, sides = [], [], [], [], [], []
paths = []
for path in scar['paths']:
    controls = np.array(path['points'], dtype=float)
    projected = []
    for a,b in zip(controls[:-1],controls[1:]):
        steps = max(2, int(np.linalg.norm(b-a)/scar['projection_step_metres'])+1)
        for t in np.linspace(0,1,steps,endpoint=False):
            y,z = a*(1-t)+b*t
            hit, normal, index, distance = bvh.ray_cast(Vector((path['side']*2,y,z)),Vector((-path['side'],0,0)),4)
            assert hit is not None, ('Scar outside host',path['name'],y,z)
            assert hit.x*path['side'] > 0, ('Ray crossed to the wrong flank',path['name'])
            projected.append(np.array(hit))
    y,z = controls[-1]
    hit,_,_,_ = bvh.ray_cast(Vector((path['side']*2,y,z)),Vector((-path['side'],0,0)),4)
    assert hit is not None
    projected.append(np.array(hit))
    p = np.array(projected)
    lengths = np.linalg.norm(np.diff(p,axis=0),axis=1)
    travel = np.concatenate(([0.0],np.cumsum(lengths)))
    travel = path['offset'] + travel * .92
    for i,(a,b) in enumerate(zip(p[:-1],p[1:])):
        if np.linalg.norm(b-a)<1e-8:continue
        taper = 1.0 - .75*max(0,(i/max(1,len(p)-2)-.72)/.28)
        starts.append(a); ends.append(b); widths.append(path['width']*taper)
        flow0.append(travel[i]);flow1.append(travel[i+1]);sides.append(path['side'])
    paths.append({'name':path['name'],'side':path['side'],'projected_points':p.tolist()})

a,b=np.array(starts),np.array(ends)
ab=b-a; lengths2=(ab*ab).sum(1)
width=np.array(widths); f0,f1=np.array(flow0),np.array(flow1)
attributes=np.zeros((len(points),4),np.float32); attributes[:,3]=1
new_points=points.copy()
def smooth(value):
    value=np.clip(value,0,1)
    return value*value*(3-2*value)
for offset in range(0,len(points),4096):
    p=points[offset:offset+4096]
    ap=p[:,None,:]-a[None,:,:]
    t=np.clip(np.einsum('ijk,jk->ij',ap,ab)/lengths2,0,1)
    distances=np.linalg.norm(ap-t[:,:,None]*ab,axis=2)
    score=distances/width
    index=score.argmin(1); rows=np.arange(len(p))
    d=distances[rows,index]; w=width[index]
    damage=1-smooth((d/(scar['half_width_metres']*w)-.42)/.58)
    core=1-smooth((d/(scar['core_half_width_metres']*w)-.20)/.80)
    flow=f0[index]+t[rows,index]*(f1[index]-f0[index])
    attributes[offset:offset+len(p),0]=core
    attributes[offset:offset+len(p),1]=damage
    attributes[offset:offset+len(p),2]=np.clip(flow,0,1)
    incision=1-smooth(d/(scar['half_width_metres']*.70*w))
    new_points[offset:offset+len(p),0] -= np.array(sides)[index]*scar['recess_metres']*incision
mesh.vertices.foreach_set('co',new_points.astype(np.float32).ravel())
mesh.update()
# Bake linear object position first, then evaluate the authored curves per texel.
# Sparse vertices on broad plates cannot represent a millimetre-wide core:
# interpolating a vertex mask produced visibly triangular luminous patches.
attribute=mesh.color_attributes.new(name='Surface position - authoring data',type='FLOAT_COLOR',domain='POINT')
position_colours=np.ones((len(points),4),np.float32)
position_lo=points.min(0);position_span=points.max(0)-position_lo
position_colours[:,:3]=(points-position_lo)/position_span
attribute.data.foreach_set('color',position_colours.ravel())
assert np.isfinite(attributes).all() and attributes[:,0].max()>.9
assert np.max(np.linalg.norm(new_points-points,axis=1))<=scar['recess_metres']+1e-6

# Extract textures by their actual glTF roles; retain the exact original PNGs.
data=raw.read_bytes();length=struct.unpack_from('<I',data,12)[0]
doc=json.loads(data[20:20+length]);binary=data[28+length:]
pbr=doc['materials'][0]['pbrMetallicRoughness']
for name,role in [('base.png','baseColorTexture'),('orm.png','metallicRoughnessTexture')]:
    im=doc['images'][doc['textures'][pbr[role]['index']]['source']]
    assert im['mimeType']=='image/png'
    view=doc['bufferViews'][im['bufferView']];offset=view.get('byteOffset',0)
    (output/name).write_bytes(binary[offset:offset+view['byteLength']])
material=mesh.materials[0].copy();mesh.materials[0]=material
material.name='Vaultcrown - scar host'
nodes=material.node_tree.nodes; links=material.node_tree.links
shader=nodes.get('Principled BSDF'); out=next(n for n in nodes if n.type=='OUTPUT_MATERIAL')
attr=nodes.new('ShaderNodeAttribute');attr.attribute_name=attribute.name
mask=bpy.data.images.new('Scar mask - linear data',width=scar['mask_size'],height=scar['mask_size'],alpha=True,float_buffer=True)
mask.colorspace_settings.name='Non-Color'
target=nodes.new('ShaderNodeTexImage');target.image=mask;target.name='Scar mask UV bake'
nodes.active=target; target.select=True
emitter=nodes.new('ShaderNodeEmission');links.new(attr.outputs['Color'],emitter.inputs['Color']);links.new(emitter.outputs[0],out.inputs['Surface'])
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=1
scene.render.bake.use_selected_to_active=False;scene.render.bake.margin=8
bpy.ops.object.select_all(action='DESELECT');host.select_set(True);bpy.context.view_layer.objects.active=host
bpy.ops.object.bake(type='EMIT')
texels=np.empty(scar['mask_size']**2*4,np.float32);mask.pixels.foreach_get(texels)
texels=texels.reshape((-1,4))
positions=texels[:,:3]*position_span+position_lo
for offset in range(0,len(positions),4096):
    p=positions[offset:offset+4096]
    ap=p[:,None,:]-a[None,:,:]
    t=np.clip(np.einsum('ijk,jk->ij',ap,ab)/lengths2,0,1)
    distances=np.linalg.norm(ap-t[:,:,None]*ab,axis=2)
    index=(distances/width).argmin(1); rows=np.arange(len(p))
    d=distances[rows,index];w=width[index]
    texels[offset:offset+len(p),0]=1-smooth((d/(scar['core_half_width_metres']*w)-.20)/.80)
    texels[offset:offset+len(p),1]=1-smooth((d/(scar['half_width_metres']*w)-.42)/.58)
    texels[offset:offset+len(p),2]=np.clip(f0[index]+t[rows,index]*(f1[index]-f0[index]),0,1)
    texels[offset:offset+len(p),3]=1
mask.pixels.foreach_set(texels.ravel())
mask.update()
mask.filepath_raw=str(output/'scar-mask.png');mask.file_format='PNG';mask.save()
mask.pack()
nodes.remove(emitter);links.new(shader.outputs['BSDF'],out.inputs['Surface'])
separate=nodes.new('ShaderNodeSeparateColor');links.new(target.outputs['Color'],separate.inputs['Color'])
old_base=shader.inputs['Base Color'].links[0].from_socket
mix=nodes.new('ShaderNodeMixRGB');mix.blend_type='MIX';mix.inputs[2].default_value=(.012,.006,.004,1)
links.new(separate.outputs['Green'],mix.inputs[0]);links.new(old_base,mix.inputs[1]);links.new(mix.outputs[0],shader.inputs['Base Color'])
links.new(separate.outputs['Red'],shader.inputs['Emission Strength'])
gain=nodes.new('ShaderNodeMath');gain.operation='MULTIPLY';gain.name='Review emission gain'
gain.inputs[1].default_value=scar['peak_emission']
links.new(separate.outputs['Red'],gain.inputs[0]);links.new(gain.outputs[0],shader.inputs['Emission Strength'])
shader.inputs['Emission Color'].default_value=(*scar['colour'],1)
bump=nodes.new('ShaderNodeBump');bump.invert=True
bump.inputs['Distance'].default_value=scar['recess_metres'];bump.inputs['Strength'].default_value=.65
links.new(separate.outputs['Green'],bump.inputs['Height']);links.new(bump.outputs['Normal'],shader.inputs['Normal'])
# Existing metallic/roughness and original texture connections are retained.
for image in bpy.data.images:
    if image.source=='FILE' and image.has_data:image.pack()
report={'source_sha256':cfg['source_sha256'],'config':cfg,'vertices':len(mesh.vertices),'triangles':len(mesh.polygons),
        'original_normalized_bounds':[points.min(0).tolist(),points.max(0).tolist()],
        'scarred_bounds':[new_points.min(0).tolist(),new_points.max(0).tolist()],
        'max_scar_displacement_metres':float(np.linalg.norm(new_points-points,axis=1).max()),
        'core_vertex_fraction':float((attributes[:,0]>.05).mean()),'damage_vertex_fraction':float((attributes[:,1]>.05).mean()),
        'projected_paths':paths,'blender':bpy.app.version_string,
        'note':'Vertex fractions are diagnostic, not surface area percentages. Only a shallow side incision changes source shape.'}
(output/'surface-report.json').write_text(json.dumps(report,indent=2)+'\n')
scene['study']='ART-03 isolated stag - not adopted game art'
bpy.ops.wm.save_as_mainfile(filepath=str(output/'stag-surface.blend'),compress=True)
assert hashlib.sha256(raw.read_bytes()).hexdigest()==cfg['source_sha256']
print('STAG_SURFACE_OK '+str(output),flush=True)
