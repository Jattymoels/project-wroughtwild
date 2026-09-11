"""C5 derivative of B3's inspected rock fitting/cutting workflow. All outputs fresh."""
import bpy,bmesh,json,sys,math
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
out=Path(sys.argv[sys.argv.index('--')+1]).resolve();assert not out.exists();out.mkdir(parents=True)
cfg=json.loads(Path(__file__).with_name('kit.json').read_text())
source=Path('C:/Users/Matty/Dev/project-wroughtwild/build/art07/b3/worktree/build/art07/b3/v01/handoff-v02/models/b3-master.blend')
bpy.ops.wm.open_mainfile(filepath=str(source))
original=bpy.data.objects['SOURCE approved reduced quiet rock']
closed=bpy.data.objects['FINISHED repaired closed host']
raw=bpy.data.objects['SOURCE untouched normalized ART02 rock']
host=bpy.data.objects['boulder-full']
for o in list(bpy.data.objects):
    if o not in [original,closed,raw,host]:bpy.data.objects.remove(o,do_unlink=True)
scene=bpy.context.scene;cols={}
for c in list(bpy.data.collections):
    if c.name not in ['SOURCE']:bpy.data.collections.remove(c)
cols['SOURCE']=bpy.data.collections.get('SOURCE')
for o in [original,closed,raw,host]:
    if o.name not in cols['SOURCE'].objects:cols['SOURCE'].objects.link(o)
    o.hide_render=True;o.hide_set(True)
for name in ['FINISHED','RUNTIME','REVIEW']:
    c=bpy.data.collections.new(name);scene.collection.children.link(c);cols[name]=c
def active(o):
    bpy.ops.object.select_all(action='DESELECT');o.hide_set(False);o.select_set(True);bpy.context.view_layer.objects.active=o
def clone(o,name,col='FINISHED'):
    n=o.copy();n.data=o.data.copy();n.name=name;n.location=(0,0,0);n.rotation_euler=(0,0,0);n.scale=(1,1,1);cols[col].objects.link(n);n.hide_set(False);n.hide_render=False;return n
def clean(o):
    bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6);bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=1e-7);bmesh.ops.triangulate(bm,faces=list(bm.faces))
    bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.calc_area()<1e-10],context='FACES')
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free();o.data.update()
def decimate(o,target):
    o.data.calc_loop_triangles();count=len(o.data.loop_triangles)
    for attempt in range(5):
        if count<=target:break
        active(o);m=o.modifiers.new('Retain mineral silhouette','DECIMATE');m.ratio=(target-24)/count*(.94 if attempt else 1);m.use_collapse_triangulate=True;bpy.ops.object.modifier_apply(modifier=m.name)
        clean(o);o.data.calc_loop_triangles();count=len(o.data.loop_triangles)
    for v in o.data.vertices:
        v.co.x=max(-1.25,min(1.25,v.co.x));v.co.y=max(-.4,min(.4,v.co.y));v.co.z=max(0,min(.52,v.co.z))
    clean(o);o.data.calc_loop_triangles();count=len(o.data.loop_triangles)
    assert count<=target,(o.name,count,target)
def cut(o,x,keep_left=True,axis=0):
    bm=bmesh.new();bm.from_mesh(o.data);normal=Vector((0,0,0));normal[axis]=1
    bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=normal*x,plane_no=normal,clear_outer=keep_left,clear_inner=not keep_left,dist=1e-7)
    edges=[e for e in bm.edges if e.is_boundary and all(abs(v.co[axis]-x)<1e-5 for v in e.verts)]
    faces=bmesh.ops.holes_fill(bm,edges=edges,sides=0).get('faces',[]) if edges else []
    uv=bm.loops.layers.uv.verify();other=[i for i in range(3) if i!=axis]
    for f in faces:
        f.material_index=1
        for l in f.loops:l[uv].uv=(l.vert.co[other[0]]*.65+.5,l.vert.co[other[1]]*.65+.5)
    bmesh.ops.triangulate(bm,faces=list(bm.faces));bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free();clean(o)
    return len(faces)
# One shared immutable surface pair. Source maps remain packed at original dimensions.
textures=[]
for n in original.data.materials[0].node_tree.nodes:
    if n.type=='TEX_IMAGE' and n.image:
        im=n.image.copy();im.name='C5 shared '+n.image.name;im.scale(1024,1024);im.pack();textures.append(im)
# A single new tileable procedural stone material avoids interpolating unrelated
# atlas charts during LOD collapse. Original albedo/ORM remain packed on SOURCE.
# This is a Blender material recipe, with seeded periodic grain, not edited evidence.
size=1024;rng=np.random.default_rng(cfg['seed']);yy,xx=np.mgrid[0:size,0:size]/size
grain=np.zeros((size,size))
for octave in range(6):
    for k in range(10):
        fx,fy=rng.integers(1,5,2)*(2**octave);phase=rng.uniform(0,2*math.pi)
        grain+=np.sin(2*math.pi*(xx*fx+yy*fy)+phase)*(.5**octave)
grain=(grain-grain.mean())/grain.std();grey=np.clip(.19+grain*.035,.07,.32)
albedo=bpy.data.images.new('C5 shared periodic stone albedo',width=size,height=size)
rgba=np.empty((size,size,4),dtype=np.float32);rgba[:,:,:3]=grey[:,:,None];rgba[:,:,3]=1;albedo.pixels.foreach_set(rgba.ravel());albedo.pack()
orm=bpy.data.images.new('C5 shared periodic stone ORM',width=size,height=size);orm.colorspace_settings.name='Non-Color';rgba[:,:,0]=1;rgba[:,:,1]=np.clip(.88+grain*.025,.75,1);rgba[:,:,2]=0;orm.pixels.foreach_set(rgba.ravel());orm.pack()
def material(row,cap=False):
    m=bpy.data.materials.new(row['id']+(' cut interior' if cap else ' mineral host'));m.use_nodes=True
    nt=m.node_tree;bs=nt.nodes.get('Principled BSDF');tex=nt.nodes.new('ShaderNodeTexImage');tex.image=albedo;tex.projection='BOX';tex.projection_blend=.25
    coord=nt.nodes.new('ShaderNodeTexCoord');scale=nt.nodes.new('ShaderNodeVectorMath');scale.operation='SCALE';scale.inputs[3].default_value=1.7;nt.links.new(coord.outputs['Object'],scale.inputs[0]);nt.links.new(scale.outputs[0],tex.inputs['Vector'])
    attr=nt.nodes.new('ShaderNodeVertexColor');attr.layer_name='C5';sep=nt.nodes.new('ShaderNodeSeparateColor');nt.links.new(attr.outputs['Color'],sep.inputs[0])
    tint=nt.nodes.new('ShaderNodeMixRGB');tint.blend_type='MULTIPLY';tint.inputs[0].default_value=1;tint.inputs[2].default_value=(*row['host_tint'],1);nt.links.new(tex.outputs['Color'],tint.inputs[1])
    mix=nt.nodes.new('ShaderNodeMixRGB');nt.links.new(sep.outputs['Red'],mix.inputs[0]);nt.links.new(tint.outputs[0],mix.inputs[1]);mix.inputs[2].default_value=(*row['colour'],1);nt.links.new(mix.outputs[0],bs.inputs['Base Color'])
    bs.inputs['Roughness'].default_value=row['roughness'];bs.inputs['Metallic'].default_value=row['metallic']
    # Explicit glTF-friendly textures are also recorded in custom properties; runtime shader reconstructs field shading.
    m['c5_ore']=row['id'];m['cap']=cap
    return m
def weights(p,index):
    x,y,z=p.T
    rng=np.random.default_rng(cfg['seed']+index)
    if index==0:
        field=np.zeros(len(p))
        for k in range(22):
            cx,cy,cz=rng.uniform([-1.2,-.38,.04],[1.2,.38,.49]);rx,ry,rz=rng.uniform([.045,.02,.025],[.22,.09,.09])
            field=np.maximum(field,np.exp(-((x-cx)/rx)**2-((y-cy)/ry)**2-((z-cz)/rz)**2))
        field+=.22*np.exp(-((z-.24-.065*np.sin(x*3)-y*.18)/.035)**2)
    elif index==1:
        layer=z+.065*np.sin(x*3+.7)+y*.18
        field=np.exp(-((layer-.16)/.028)**2)+.8*np.exp(-((layer-.34)/.019)**2)
        field*=.45+.55*(.5+.5*np.sin(x*8+y*14)*np.cos(z*17))
    elif index==2:
        field=np.zeros(len(p))
        for k in range(38):
            cx,cy,cz=rng.uniform([-1.2,-.38,.02],[1.2,.38,.49]);rx,ry,rz=rng.uniform([.025,.015,.025],[.12,.12,.08])
            field=np.maximum(field,np.exp(-((x-cx)/rx)**2-((y-cy)/ry)**2-((z-cz)/rz)**2))
        field*=.5+.5*np.sin(x*83+y*109+z*59)**2
    elif index==3:field=np.exp(-((y-.10*np.sin(x*5)-.04)/.055)**2)
    else:field=np.exp(-((z-.22-.06*np.sin(x*5)-y*.25)/.017)**2)
    return np.clip(field*1.4,0,1)
assets={};incisions=[]
for index,row in enumerate(cfg['ores']):
    base=clone(closed,'intact-reference-'+row['id'])
    p=np.array([v.co for v in base.data.vertices]);lo=p.min(0);hi=p.max(0);p=(p-lo)/(hi-lo)*cfg['size_blender_m'];p[:,:2]-=np.array(cfg['size_blender_m'][:2])/2
    for v,q in zip(base.data.vertices,p):v.co=q
    base.data.materials.clear();base.data.materials.append(material(row));base.data.materials.append(material(row,True));clean(base)
    cut(base,.012,False,2)
    for v in base.data.vertices:v.co.z-=.012
    # Source-corresponding intact/cracked meshes allow independent physical incision measurements.
    base.data.update();base.hide_render=True;base.hide_set(True)
    for crack in ([False] if index==0 else [False,True]):
        full=clone(base,row['id']+('-cracked' if crack else '-cold'))
        p=np.array([v.co for v in full.data.vertices]);field=weights(p,index);norm=np.array([v.normal for v in full.data.vertices])
        # Mineral weight deforms the existing real rock, never an added crystal-spike primitive.
        bump=(.007 if index==1 else .012)*field
        q=p+norm*bump[:,None]
        scar=np.zeros(len(p))
        if index==3 or crack:
            bvh=BVHTree.FromPolygons([Vector(v) for v in p],[tuple(f.vertices) for f in full.data.polygons]);dist=np.full(len(p),10.)
            for x in np.linspace(-1.13,1.13,220):
                y=.10*math.sin(x*5)+.04;hit,normal,fi,d=bvh.ray_cast(Vector((x,y,2)),Vector((0,0,-1)))
                if hit is not None:dist=np.minimum(dist,np.linalg.norm(p-np.array(hit),axis=1))
            scar=np.clip(1-dist/cfg['scar_half_width_m'],0,1);scar=scar*scar*(3-2*scar)
            q-=norm*(scar*cfg['scar_depth_m'])[:,None]
        # Bounds stay inside measured fallback body; bottom plane remains grounded.
        q[:,0]=np.clip(q[:,0],-1.25,1.25);q[:,1]=np.clip(q[:,1],-.4,.4);q[:,2]=np.clip(q[:,2],0,.52)
        for v,co in zip(full.data.vertices,q):v.co=co
        col=full.data.color_attributes.get('C5') or full.data.color_attributes.new(name='C5',type='FLOAT_COLOR',domain='POINT')
        for i,c in enumerate(col.data):c.color=(float(field[i]),float(scar[i]),float((p[i,0]+1.25)/2.5),1)
        full.data.color_attributes.active_color=col;full.data.update()
        incisions.append({'object':full.name,'reference':base.name,'max_measured_delta_m':float(np.max(np.linalg.norm(q-p,axis=1))),'max_inward_m':float(np.max(np.sum((p-q)*norm,axis=1))),'displaced_vertices':int(np.count_nonzero(scar))})
        for units in range(row['units'],0,-2):
            name=f"{row['id']}-u{units}-{'cracked' if crack else 'cold'}";part=clone(full,name)
            faces=0
            if units<row['units']:
                coordinate=-1.22+2.44*units/row['units'];faces=cut(part,coordinate)
                # Re-evaluate mineral continuity on new vertices/cap, using the same spatial geological field.
                cp=np.array([v.co for v in part.data.vertices]);cf=weights(cp,index);colour=part.data.color_attributes['C5']
                for i,c in enumerate(colour.data):c.color[0]=float(cf[i])
            assets[name]=part;part['units']=units;part['cap_count']=faces;part['ore']=row['id'];part['cracked']=crack
            part.hide_render=True;part.hide_set(True)
        full.hide_render=True;full.hide_set(True)
report={'assets':{},'incisions':incisions,'source':str(source),'mapping':'Blender (x,y,z) to Godot (x,z,-y), metres, bottom center origin'}
for name,part in assets.items():
    report['assets'][name]=[]
    for lod,target in enumerate(cfg['lod_triangles']):
        n=clone(part,name+'-lod'+str(lod),'RUNTIME');decimate(n,target);active(n)
        bpy.ops.export_scene.gltf(filepath=str(out/(name+f'-lod{lod}.glb')),export_format='GLB',use_selection=True,export_animations=False,export_attributes=True,export_vertex_color='NAME',export_vertex_color_name='C5')
        n.data.calc_loop_triangles();report['assets'][name].append({'lod':lod,'triangles':len(n.data.loop_triangles),'surfaces':len(n.data.materials)})
        n.hide_render=True;n.hide_set(True)
# Save a rearrangeable 5-column, three-state source comparison.
for i,row in enumerate(cfg['ores']):
    for j,(units,crack) in enumerate([(row['units'],False),(row['units']-2,False),(2,i>0)]):
        name=f"{row['id']}-u{units}-{'cracked' if crack else 'cold'}";n=clone(assets[name],'REVIEW '+name,'REVIEW');n.location=((i-2)*2.85,j*1.45,0)
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=20;scene.cycles.use_denoising=True
scene.render.resolution_x=1600;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Neutral mineral studio');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.32,.37,.43,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.8
sun=bpy.data.objects.new('Review sun',bpy.data.lights.new('Review sun','SUN'));cols['REVIEW'].objects.link(sun);sun.rotation_euler=(.3,-.7,-.4);sun.data.energy=2.2
cam=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));cols['REVIEW'].objects.link(cam);scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=15;cam.location=(6,9,11);cam.rotation_euler=(Vector((0,1.2,0))-cam.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(out/'c5-master.blend'),compress=True)
(out/'model-report.json').write_text(json.dumps(report,indent=2)+'\n')
# Runtime textures are authored by the source, not regenerated or painted screenshots.
for im,name in [(albedo,'rock-albedo.png'),(orm,'rock-orm.png')]:
    im.filepath_raw=str(out/name);im.file_format='PNG';im.save()
print('C5_MODEL_BUILD_OK',len(assets)*3)
