"""Blender: fit shallow eyes to the inspected stag without replacing its anatomy.
-- SOURCE.blend NEW_OUTPUT
"""
import bpy,json,sys,math,hashlib
import numpy as np
from pathlib import Path
from mathutils import Vector
repo=Path(__file__).resolve().parents[2]
cfg=json.loads(Path(__file__).with_name('stag.json').read_text(encoding='utf-8'))
source,out=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]]
assert not out.exists();out.mkdir(parents=True)
assert hashlib.sha256((repo/cfg['source']).read_bytes()).hexdigest()==cfg['source_sha256']
bpy.ops.wm.open_mainfile(filepath=str(source))
def mat(name,colour,rough=.65,metal=0):
    m=bpy.data.materials.new(name);m.use_nodes=True
    bs=m.node_tree.nodes['Principled BSDF'];bs.inputs['Base Color'].default_value=(*colour,1)
    bs.inputs['Roughness'].default_value=rough;bs.inputs['Metallic'].default_value=metal
    return m
gum=mat('Mouth interior - dark living tissue',(.006,.003,.002),.9)
tooth=mat('Worn dentine',(.46,.40,.29),.4)
lidmat=mat('Dark fitted eyelid',(.012,.009,.007),.78)
eyemat=mat('Amber iris',(.10,.055,.015),.24)
pupilmat=mat('Pupil',(.002,.0015,.001),.12)

def ellipsoid(name,at,scale,material,attachment):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,location=at)
    obj=bpy.context.object;obj.name=name;obj.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    obj.data.materials.append(material)
    for f in obj.data.polygons:f.use_smooth=True
    obj['attachment']=attachment
    return obj

# Lens and lid geometry fit the actual front-facing sockets, not the cheek fan.
eyes=[]
for index,target in enumerate(cfg['eye_targets']):
    hit=Vector(target['position']);normal=Vector(target['normal']).normalized()
    up=Vector((0,0,1));horizontal=up.cross(normal).normalized();vertical=normal.cross(horizontal).normalized()
    from mathutils import Matrix
    basis=Matrix((horizontal,vertical,normal)).transposed().to_4x4()
    centre=hit-normal*.001;eyes.append(list(centre))
    eye=ellipsoid('Vaultcrown - iris '+str(index),centre,(.020,.011,.0035),eyemat,'head')
    eye.rotation_euler=basis.to_euler()
    pupil=ellipsoid('Vaultcrown - pupil '+str(index),centre+normal*.0028,(.012,.0048,.0009),pupilmat,'head');pupil.rotation_euler=basis.to_euler()
    for upper in [True,False]:
        coords=[]
        for t in np.linspace(0,math.pi,19):
            coords.append(centre+horizontal*(math.cos(t)*.021)+vertical*(math.sin(t)*(.0115 if upper else -.009))+normal*.001)
        curve=bpy.data.curves.new('Fitted lid','CURVE');curve.dimensions='3D';curve.resolution_u=1;curve.bevel_depth=.0018 if upper else .0012;curve.bevel_resolution=2
        spline=curve.splines.new('POLY');spline.points.add(len(coords)-1)
        for pt,p in zip(spline.points,coords):pt.co=(*p,1)
        o=bpy.data.objects.new('Vaultcrown - eyelid',curve);bpy.context.collection.objects.link(o);o.data.materials.append(lidmat);o['attachment']='head'
        bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o;bpy.ops.object.convert(target='MESH')

for o in bpy.context.scene.objects:
    if o.type=='MESH' and not o.name.startswith('SOURCE'):
        bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        o.data.validate(verbose=True)
for image in bpy.data.images:
    if image.has_data and image.source=='FILE':image.pack()
(out/'finish-report.json').write_text(json.dumps({'source_sha256':cfg['source_sha256'],'eye_centres':eyes,'note':'Body and open crown are retained; shallow eyes follow measured sockets. No body or world adoption.'},indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'stag-finished.blend'),compress=True)
print('STAG_FINISH_OK')
