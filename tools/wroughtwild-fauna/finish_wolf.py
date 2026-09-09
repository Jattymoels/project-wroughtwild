"""Blender: bounded face/jaw repair of the existing wolf, no source replacement.

-- NEW_OUTPUT. The cut follows the actual closed lip; accessory anatomy is
authored geometry with independent local attachments for later rigging.
"""
import bpy, bmesh, json, sys, math, hashlib
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
repo=Path(__file__).resolve().parents[2]
cfg=json.loads(Path(__file__).with_name('wolf.json').read_text(encoding='utf-8'))
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
assert not out.exists();out.mkdir(parents=True)
assert hashlib.sha256((repo/cfg['source']).read_bytes()).hexdigest()==cfg['source_sha256']
assert hashlib.sha256((repo/cfg['normalized_source']).read_bytes()).hexdigest()==cfg['normalized_source_sha256']
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(repo/cfg['normalized_source']))
body=next(o for o in bpy.context.scene.objects if o.type=='MESH')
bpy.context.view_layer.objects.active=body
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
body.name='Rimejaw - host'
source=body.copy();source.data=body.data.copy();bpy.context.collection.objects.link(source)
source.name='SOURCE - preserved normalized wolf';source.hide_set(True);source.hide_render=True
source.select_set(False)
points=np.array([v.co for v in body.data.vertices]);original=points.copy()

# Local flattening embeds the generated raised shoulder channels into the coat.
# Keep the source UVs and broad fans. No geometry is regenerated or replaced.
for side in [-1,1]:
    y,z=points[:,1],points[:,2]
    centre=.30-.12*(z-.45)
    band=np.exp(-((y-centre)/.026)**4)*np.clip((z-.40)/.09,0,1)*np.clip((1.01-z)/.1,0,1)
    band*=np.clip((points[:,0]*side-.14)/.04,0,1)
    points[:,0]-=side*.030*band
body.data.vertices.foreach_set('co',points.astype(np.float32).ravel());body.data.update()

# Weld duplicated UV seam positions before a real cut; per-loop UVs remain.
bpy.ops.object.select_all(action='DESELECT');body.select_set(True);bpy.context.view_layer.objects.active=body
weld=body.modifiers.new('Join identical positions for mouth surgery','WELD');weld.merge_threshold=1e-6
bpy.ops.object.modifier_apply(modifier=weld.name)
bm=bmesh.new();bm.from_mesh(body.data)
# Split at the back of the movable muzzle and along its sloping lip.
for co,no in [((0,.525,0),(0,1,0)),((0,.525,.470),(0,.34,1)),((.235+.145,0,0),(1,.41+.14,0)),((.235-.145,0,0),(1,.41-.14,0))]:
    bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=1e-7,plane_co=co,plane_no=no,clear_inner=False,clear_outer=False)
bm.to_mesh(body.data);bm.free();body.data.update()
jaw=body.copy();jaw.data=body.data.copy();jaw.name='Rimejaw - jaw';bpy.context.collection.objects.link(jaw)
def is_jaw(p):return p.y>.525-1e-6 and p.z<.470-.34*(p.y-.525)+1e-6 and p.z>.29 and abs(p.x-(.235-.41*p.y)) < .145-.14*p.y+1e-6
for obj,keep in [(body,False),(jaw,True)]:
    bm=bmesh.new();bm.from_mesh(obj.data)
    remove=[f for f in bm.faces if is_jaw(f.calc_center_median())!=keep]
    bmesh.ops.delete(bm,geom=remove,context='FACES')
    bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
    bm.to_mesh(obj.data);bm.free();obj.data.update()
    obj['attachment']='jaw' if keep else 'skin'

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

# Fit internal backing to the actual cut border rather than a generic oval.
lip_points=[]
for obj,attachment in [(body,'head'),(jaw,'jaw')]:
    bm=bmesh.new();bm.from_mesh(obj.data)
    edges=[e for e in bm.edges if e.is_boundary and all(abs(v.co.z-(.470-.34*(v.co.y-.525)))<2e-5 for v in e.verts) and all(abs(v.co.x-(.235-.41*v.co.y))<.145-.14*v.co.y+.00003 for v in e.verts)]
    assert len(edges)>10
    verts=list({v for e in edges for v in e.verts})
    # One ordered convex inner membrane avoids overlapping per-edge fans in
    # generated lips with several coplanar cut contours.
    xy=sorted(set((round(v.co.x,7),round(v.co.y,7)) for v in verts))
    def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
    lower=[];upper=[]
    for p in xy:
        while len(lower)>1 and cross(lower[-2],lower[-1],p)<=0:lower.pop()
        lower.append(p)
    for p in reversed(xy):
        while len(upper)>1 and cross(upper[-2],upper[-1],p)<=0:upper.pop()
        upper.append(p)
    hull=lower[:-1]+upper[:-1]
    centre=sum((Vector((x,y,.470-.34*(y-.525))) for x,y in hull),Vector())/len(hull)
    points_cap=[centre+(Vector((x,y,.470-.34*(y-.525)))-centre)*.985 for x,y in hull]
    # A shallow concave palate gives the mouth depth instead of a flat lid.
    centre.z += .014 if attachment=='head' else -.014
    points_cap.append(centre)
    faces=[(i,(i+1)%len(hull),len(hull)) for i in range(len(hull))]
    mesh=bpy.data.meshes.new('Fitted mouth backing');mesh.from_pydata(points_cap,[],faces);mesh.update()
    o=bpy.data.objects.new('Rimejaw - fitted '+attachment+' palate',mesh);bpy.context.collection.objects.link(o);o.data.materials.append(gum);o['attachment']=attachment
    # Explicit two-sided interior is a thin membrane, with real lip backing.
    solid=o.modifiers.new('Interior thickness','SOLIDIFY');solid.thickness=.002
    bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=solid.name)
    if attachment=='head':lip_points=[v.co.copy() for v in verts]
    bm.free()
# Place opposing teeth inside the measured lip widths, behind the nose.
for upper in [True,False]:
    for i,y in enumerate([.58,.615,.65,.688,.73]):
        ring=[v.x for v in lip_points if abs(v.y-y)<.014]
        if len(ring)<2:continue
        lo,hi=min(ring),max(ring)
        for fraction in [.2,.8]:
            x=lo+(hi-lo)*fraction;z=.470-.34*(y-.525)
            length=.022 if i==3 else .009
            bpy.ops.mesh.primitive_cone_add(vertices=12,radius1=.0008 if upper else .0045,radius2=.0045 if upper else .0008,depth=length,location=(x,y,z+(-length*.45 if upper else length*.45)))
            o=bpy.context.object;o.name='Rimejaw - '+('upper' if upper else 'lower')+' tooth';o.data.materials.append(tooth);o['attachment']='head' if upper else 'jaw'
            for f in o.data.polygons:f.use_smooth=True

# Lens and lid geometry fit the actual front-facing sockets, not the cheek fan.
eyes=[]
for index,target in enumerate(cfg['eye_targets']):
    hit=Vector(target['position']);normal=Vector(target['normal']).normalized()
    up=Vector((0,0,1));horizontal=up.cross(normal).normalized();vertical=normal.cross(horizontal).normalized()
    from mathutils import Matrix
    basis=Matrix((horizontal,vertical,normal)).transposed().to_4x4()
    centre=hit-normal*.001;eyes.append(list(centre))
    eye=ellipsoid('Rimejaw - iris '+str(index),centre,(.013,.0075,.003),eyemat,'head')
    eye.rotation_euler=basis.to_euler()
    pupil=ellipsoid('Rimejaw - pupil '+str(index),centre+normal*.0028,(.005,.0058,.0009),pupilmat,'head');pupil.rotation_euler=basis.to_euler()
    for upper in [True,False]:
        coords=[]
        for t in np.linspace(0,math.pi,19):
            coords.append(centre+horizontal*(math.cos(t)*.014)+vertical*(math.sin(t)*(.008 if upper else -.0065))+normal*.001)
        curve=bpy.data.curves.new('Fitted lid','CURVE');curve.dimensions='3D';curve.resolution_u=1;curve.bevel_depth=.0018 if upper else .0012;curve.bevel_resolution=2
        spline=curve.splines.new('POLY');spline.points.add(len(coords)-1)
        for pt,p in zip(spline.points,coords):pt.co=(*p,1)
        o=bpy.data.objects.new('Rimejaw - eyelid',curve);bpy.context.collection.objects.link(o);o.data.materials.append(lidmat);o['attachment']='head'
        bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o;bpy.ops.object.convert(target='MESH')

for o in bpy.context.scene.objects:
    if o.type=='MESH' and not o.name.startswith('SOURCE'):
        bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        o.data.validate(verbose=True)
for image in bpy.data.images:
    if image.has_data and image.source=='FILE':image.pack()
(out/'finish-report.json').write_text(json.dumps({'source_sha256':cfg['source_sha256'],'eyes':eyes,'jaw_faces':len(jaw.data.polygons),'host_faces':len(body.data.polygons),'max_channel_recession':float(np.linalg.norm(points-original,axis=1).max()),'jaw_hinge':cfg['jaw_hinge'],'note':'Generated source preserved. Real separated lower muzzle plus inner backing, teeth and fitted eyes; shape/clearance still needs rendered and deformed review.'},indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'wolf-finished.blend'),compress=True)
print('WOLF_FINISH_OK')
