"""C6 direct surface finishing at measured native dimensions, retaining approved B3 roots.

Existing geometry remains the aperture/envelope source. All new wear moves inward.
Organic source reuse avoids unnecessary imagegen/TRELLIS generation.
"""
import bpy, bmesh, json, sys, math, hashlib
import subprocess
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree

depot,out=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]]
assert not out.exists(); out.mkdir(parents=True); (out/'models').mkdir(); (out/'textures').mkdir()
cfg=json.loads(Path(__file__).with_name('kit.json').read_text())
b3=depot/'build/art07/b3/worktree/build/art07/b3/v01/handoff-v02/models'
sys.path.insert(0,str(Path(__file__).parent))
from prerequisites import sha, REVISION, PACKAGES
assert sha(b3.parent/'manifest.json')==PACKAGES['b3'][1]
assert sha(b3/'b3-master.blend')==json.loads((b3.parent/'manifest.json').read_text())['models/b3-master.blend']['sha256']
bpy.ops.wm.open_mainfile(filepath=str(b3/'b3-master.blend'))
source_root=bpy.data.objects['river-bank roots']
source_rock=bpy.data.objects['rock-shelf']
for o in list(bpy.data.objects):
    if o not in [source_root,source_rock]: bpy.data.objects.remove(o,do_unlink=True)
scene=bpy.context.scene
collections={}
for c in list(bpy.data.collections): bpy.data.collections.remove(c)
for name in ['SOURCE','FINISHED','RUNTIME','REVIEW']:
    c=bpy.data.collections.new(name); scene.collection.children.link(c); collections[name]=c
for o in [source_root,source_rock]: collections['SOURCE'].objects.link(o); o.hide_render=True; o.hide_set(True); o.location=(0,0,0)
source_root.name='SOURCE B3 attached root bank'; source_rock.name='SOURCE B3 quiet stone'

def active(o):
    bpy.ops.object.select_all(action='DESELECT'); o.hide_set(False); o.select_set(True); bpy.context.view_layer.objects.active=o
def move(o,col):
    for c in list(o.users_collection): c.objects.unlink(o)
    collections[col].objects.link(o)
def clone(o,name,col='FINISHED'):
    n=o.copy(); n.data=o.data.copy(); n.name=name; collections[col].objects.link(n); n.hide_render=False; n.hide_set(False); return n
def bounds(objects):
    p=np.array([o.matrix_world@v.co for o in objects for v in o.data.vertices]); return p.min(0),p.max(0)
def tri_count(o): o.data.calc_loop_triangles(); return len(o.data.loop_triangles)
def bvh(o): return BVHTree.FromPolygons([v.co for v in o.data.vertices],[tuple(f.vertices) for f in o.data.polygons])
def clean(o):
    bm=bmesh.new(); bm.from_mesh(o.data); bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
    bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=1e-7)
    bmesh.ops.triangulate(bm,faces=list(bm.faces))
    bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.calc_area()<1e-10],context='FACES')
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces)); bm.to_mesh(o.data); bm.free(); o.data.update()

# Authored periodic surfaces: deterministic seamless functions, no lighting baked in.
side=cfg['texture_side']; axis=np.linspace(0,2*np.pi,side,endpoint=False); u,v=np.meshgrid(axis,axis)
rng=np.random.default_rng(cfg['seed'])
noise=np.zeros((side,side)); micro=np.zeros_like(noise)
for _ in range(40):
    fx,fy=rng.integers(1,18,2); phase=rng.random()*2*np.pi
    noise+=np.sin(u*fx+v*fy+phase)/math.sqrt(fx*fx+fy*fy)
for _ in range(24):
    fx,fy=rng.integers(20,100,2); micro+=np.sin(u*fx+v*fy+rng.random()*6.28)/24
noise=noise/(np.std(noise)*3)
texture_audit={}; images={}
for name,colour in [('stone',(.30,.29,.255)),('wood',(.19,.125,.073)),('soil',(.135,.098,.06)),('metal',(.20,.24,.225))]:
    field=noise*.15+micro*.09
    if name=='wood': field+=.19*np.sin(u*34+np.sin(v)*1.4+np.sin(u*3)*.4)+.08*np.sin(u*81+np.sin(v*2)*2)
    if name=='stone': field+=np.maximum(0,noise-.1)*.19
    pixels=np.zeros((side,side,4),np.float32); pixels[:,:,:3]=np.clip(np.array(colour)[None,None,:]*(1+field[:,:,None]),.015,.8); pixels[:,:,3]=1
    if name=='stone':
        moss_weight=np.clip((noise+.18*np.sin(u*3+np.sin(v*2))-.24)*.8,0,.22)
        pixels[:,:,:3]=pixels[:,:,:3]*(1-moss_weight[:,:,None])+np.array((.07,.105,.038))*moss_weight[:,:,None]
    im=bpy.data.images.new('C6 periodic '+name,width=side,height=side); im.pixels.foreach_set(pixels.ravel()); im.filepath_raw=str(out/'textures'/(name+'.png')); im.file_format='PNG'; im.save(); im.pack(); images[name]=im
    texture_audit[name]={'path':str(im.filepath_raw),'size':[side,side],'max_horizontal_edge_delta':float(np.abs(pixels[:,0,:3]-pixels[:,-1,:3]).max()),'max_vertical_edge_delta':float(np.abs(pixels[0,:,:3]-pixels[-1,:,:3]).max()),'construction':'periodic integer-frequency cosine/sine; seam is one regular texel interval'}

materials={}
for name in images:
    mat=bpy.data.materials.new('C6 '+name); mat.use_nodes=True; nt=mat.node_tree; bs=nt.nodes.get('Principled BSDF')
    tex=nt.nodes.new('ShaderNodeTexImage'); tex.image=images[name]; nt.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
    bs.inputs['Roughness'].default_value=.93 if name!='metal' else .68; bs.inputs['Metallic'].default_value=.5 if name=='metal' else 0
    materials[name]=mat
moss=bpy.data.materials.new('C6 damp moss'); moss.use_nodes=True; moss.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.065,.10,.036,1); moss.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.98
materials['moss']=moss
light=bpy.data.materials.new('C6 old inert inlay'); light.use_nodes=True; light.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.23,.27,.245,1); materials['light']=light
scar_mat=materials['stone'].copy(); scar_mat.name='C6 recessed scar'
nt=scar_mat.node_tree; bs=nt.nodes.get('Principled BSDF'); attr=nt.nodes.new('ShaderNodeVertexColor'); attr.layer_name='Scar'; sep=nt.nodes.new('ShaderNodeSeparateColor'); nt.links.new(attr.outputs['Color'],sep.inputs[0])
power=nt.nodes.new('ShaderNodeMath'); power.operation='POWER'; power.inputs[1].default_value=5; nt.links.new(sep.outputs['Red'],power.inputs[0])
gain=nt.nodes.new('ShaderNodeMath'); gain.operation='MULTIPLY'; gain.inputs[1].default_value=cfg['pulse_peak']; nt.links.new(power.outputs[0],gain.inputs[0]); nt.links.new(gain.outputs[0],bs.inputs['Emission Strength']); bs.inputs['Emission Color'].default_value=(.68,.88,1,1)
mix=nt.nodes.new('ShaderNodeMixRGB'); mix.blend_type='MIX'; nt.links.new(sep.outputs['Red'],mix.inputs[0]); tex=next(n for n in nt.nodes if n.type=='TEX_IMAGE'); nt.links.new(tex.outputs['Color'],mix.inputs[1]); mix.inputs[2].default_value=(.008,.013,.014,1); nt.links.new(mix.outputs[0],bs.inputs['Base Color'])

def uv_project(o):
    uv=o.data.uv_layers.active or o.data.uv_layers.new(name='Surface metres')
    for f in o.data.polygons:
        normal=f.normal; axes=[i for i in range(3) if i!=max(range(3),key=lambda i:abs(normal[i]))]
        for li in f.loop_indices:
            co=o.data.vertices[o.data.loops[li].vertex_index].co
            uv.data[li].uv=(co[axes[0]]*.9+.31,co[axes[1]]*.9+.17)
def material_finish(o):
    for i,m in enumerate(o.data.materials):
        name=m.name.lower(); category='stone'
        if any(k in name for k in ['wood','reed','timber']):category='wood'
        elif any(k in name for k in ['metal','iron']):category='metal'
        elif 'light' in name:category='light'
        o.data.materials[i]=materials[category]
    # Original embedded vertex tint is preserved on SOURCE, not multiplied twice.
    for c in list(o.data.color_attributes): o.data.color_attributes.remove(c)
    uv_project(o)

assets={}; sources={}; roots_audit=[]; scar_measure={}
paths=sorted((depot/'game/assets/authored').glob('cataclysm_*.glb'))
paths=[p for p in paths if any(key in p.stem for key in ['fen_','rootvault_','upland_','forge_threshold'])]
paths += [depot/'game/assets/authored/workbench.glb']
for path in paths:
    expected=subprocess.check_output(['git','-c','safe.directory='+depot.as_posix(),'-C',str(depot),'show',REVISION+':game/assets/authored/'+path.name])
    assert hashlib.sha256(expected).hexdigest()==sha(path),path
    before=set(bpy.data.objects); bpy.ops.import_scene.gltf(filepath=str(path))
    imported=[o for o in bpy.data.objects if o not in before and o.type=='MESH']
    for o in imported: active(o); bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    active(imported[0])
    for o in imported:o.select_set(True)
    bpy.ops.object.join(); original=bpy.context.object; original.name='SOURCE '+path.stem; move(original,'SOURCE'); original.hide_render=True; original.hide_set(True)
    low,high=bounds([original]); sources[path.stem]={'path':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'bounds':[low.tolist(),high.tolist()],'triangles':tri_count(original)}
    obj=clone(original,path.stem); material_finish(obj); assets[path.stem]=[obj]
    # Fit reused low roots only on solid lower masonry; never across a portal.
    if path.stem.endswith('_wall') or path.stem.endswith('_frame') or path.stem.endswith('_threshold'):
        tree=bvh(obj)
        xzones=[(low[0]+.12,low[0]+1.02),(high[0]-1.02,high[0]-.12)] if path.stem.endswith('_wall') else [(low[0]+.045,low[0]+.50),(high[0]-.50,high[0]-.045)]
        for idx,(xmin,xmax) in enumerate(xzones):
            root=clone(source_root,path.stem+' roots '+str(idx)); root.location=(0,0,0)
            p=np.array([v.co for v in root.data.vertices]); lo=p.min(0); hi=p.max(0)
            scale=min((xmax-xmin)/(hi[0]-lo[0]),(high[1]-low[1]-.02)/(hi[1]-lo[1]),cfg['root_height_m']/(hi[2]-lo[2]))
            q=(p-lo)*scale+np.array((xmin,low[1]+.001,low[2]+.003))
            distances=[]
            for vert,co in zip(root.data.vertices,q):vert.co=co
            clean(root)
            # Cull faces that have no actual parent surface nearby (open mortar gaps).
            bm=bmesh.new();bm.from_mesh(root.data)
            remove=[]
            for f in bm.faces:
                near=tree.find_nearest(f.calc_center_median())
                if near[0] is None or near[3]>.048:remove.append(f)
            if remove:bmesh.ops.delete(bm,geom=remove,context='FACES')
            bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS');bm.to_mesh(root.data);bm.free();clean(root)
            for f in root.data.polygons:
                distance=tree.find_nearest(f.center)[3];distances.append(distance)
            roots_audit.append({'asset':path.stem,'root':root.name,'uniform_source_scale':scale,'max_face_parent_gap_m':max(distances,default=0),'faces_omitted':len(remove)})
            assets[path.stem].append(root)

        # Small authored roots follow the actual masonry face. Their branching routes
        # echo the retained B3 root bank; B3 supplies the bark, not a flattened mesh.
        # They are contact detail, wholly within the measured existing envelope.
        routes=[]
        if path.stem.endswith('_wall'):
            routes=[([(low[0]+.30,.01),(low[0]+.40,.12),(low[0]+.70,.23),(low[0]+1.12,.29)],.018),
                    ([(low[0]+.70,.23),(low[0]+.82,.39),(low[0]+.98,.46)],.011),
                    ([(high[0]-.22,.015),(high[0]-.46,.16),(high[0]-.90,.20),(high[0]-1.26,.33)],.015)]
        else:
            for side_x in [low[0]+.24,high[0]-.24]:
                routes += [([(side_x,.015),(side_x-.045,.16),(side_x+.035,.31),(side_x-.025,.47)],.013)]
        points=[];faces=[];uvs=[];contact_distances=[]
        for route,radius in routes:
            samples=[]
            for k in range(len(route)-1):
                a=Vector(route[k]);b=Vector(route[k+1])
                for t in np.linspace(0,1,14,endpoint=False):
                    x,z=a.lerp(b,float(t));z+=low[2]
                    hit,no,face,dist=tree.ray_cast(Vector((x,low[1]-1,z)),Vector((0,1,0)))
                    if hit is not None:samples.append((hit,float(k+t)/(len(route)-1)))
            if len(samples)<3:continue
            first=len(points)
            for i,(hit,travel) in enumerate(samples):
                rad=radius*(1-travel*.82)
                for j in range(8):
                    ang=j*math.pi/4
                    co=Vector((hit.x+math.cos(ang)*rad,hit.y-.003+math.sin(ang)*rad,hit.z))
                    co=Vector([max(low[d]+.0001,min(high[d]-.0001,co[d])) for d in range(3)])
                    points.append(co);uvs.append((j/8,travel*3))
                    contact_distances.append(tree.find_nearest(co)[3])
                if i:
                    for j in range(8):faces.append((first+(i-1)*8+j,first+(i-1)*8+(j+1)%8,first+i*8+(j+1)%8,first+i*8+j))
            faces.append(tuple(first+j for j in reversed(range(8))))
            faces.append(tuple(first+(len(samples)-1)*8+j for j in range(8)))
        if points:
            mesh=bpy.data.meshes.new('Masonry-fitted branching roots');mesh.from_pydata(points,[],faces)
            for material in source_root.data.materials:mesh.materials.append(material)
            mesh.uv_layers.new(name='Attached root length')
            for loop in mesh.loops:mesh.uv_layers.active.data[loop.index].uv=uvs[loop.vertex_index]
            detail=bpy.data.objects.new(path.stem+' roots attached',mesh);collections['FINISHED'].objects.link(detail);clean(detail);assets[path.stem].append(detail)
            roots_audit.append({'asset':path.stem,'root':detail.name,'construction':'direct small branching roots sampled on actual masonry; B3 bark/shape reference','max_vertex_parent_gap_m':max(contact_distances),'root_radius_m':max(r[1] for r in routes)})

    if path.stem=='cataclysm_fen_wall':
        altered=clone(obj,'cataclysm_fen_wall_struck'); active(altered)
        # Only lower stone faces receive enough interior samples to cut a wound.
        bm=bmesh.new();bm.from_mesh(altered.data)
        edges=[e for e in bm.edges if all(v.co.z<.80 for v in e.verts)]
        bmesh.ops.subdivide_edges(bm,edges=edges,cuts=6,use_grid_fill=True);bm.to_mesh(altered.data);bm.free();clean(altered)
        before_points=np.array([v.co for v in altered.data.vertices]); weights=[]
        for vtx in altered.data.vertices:
            p=vtx.co; route_x=.10+.12*math.sin(p.z*9)
            lateral=abs(p.x-route_x)
            face=max(0,min(1,(-p.y-.09)/.07))
            w=max(0,1-lateral/cfg['scar_half_width_m'])*face*(1 if .035<p.z<.72 else 0)
            w=w*w*(3-2*w); weights.append(w)
            vtx.co.y+=cfg['scar_depth_m']*w
        colour=altered.data.color_attributes.new(name='Scar',type='FLOAT_COLOR',domain='POINT')
        for item,w,p in zip(colour.data,weights,before_points):item.color=(w,0,p[2]/.8,1)
        altered.data.materials[0]=scar_mat;altered.data.update()
        depth=max((v.co-Vector(p)).length for v,p in zip(altered.data.vertices,before_points))
        assert depth>.038 and depth<=cfg['scar_depth_m']+.00001,depth
        # Identical topology comparison is saved independently of imported SOURCE triangulation.
        reference=clone(altered,'SOURCE pre-incision fen wall','SOURCE')
        for vert,co in zip(reference.data.vertices,before_points):vert.co=co
        reference.hide_set(True);reference.hide_render=True
        scar_measure={'maximum_depth_m':depth,'vertices_displaced':sum(w>0 for w in weights),'half_width_m':cfg['scar_half_width_m'],'reference':reference.name,'altered':altered.name}
        assets['cataclysm_fen_wall_struck']=[altered]+[clone(r,r.name+' struck') for r in assets[path.stem][1:]]

# Path-edge candidate uses the existing paving bounds and top support, never new placements.
paving=assets['cataclysm_upland_paving'][0]
transition=clone(paving,'trail_transition');assets['trail_transition']=[transition]
sources['trail_transition']=dict(sources['cataclysm_upland_paving'])
sources['trail_transition']['role']='Compacted soil and thin litter on existing supported paving margins'
transition.data.materials.append(materials['soil'])
for face in transition.data.polygons:
    if face.normal.z>.7 and math.sin(face.center.x*4+face.center.y*7)>.15:face.material_index=1
leafmat=bpy.data.materials.new('C6 old leaf litter');leafmat.use_nodes=True;leafmat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.17,.105,.036,1);leafmat.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.95
tree=bvh(paving);low,high=bounds([paving]);leafpoints=[];leaffaces=[]
for idx in range(55):
    x=float(rng.uniform(low[0]+.07,high[0]-.07));y=float(rng.uniform(low[1]+.05,high[1]-.05))
    if abs(y)<.30:continue
    hit,normal,face,dist=tree.ray_cast(Vector((x,y,high[2]+1)),Vector((0,0,-1)))
    if hit is None or normal.z<.7:continue
    yaw=float(rng.uniform(0,6.28));local=[]
    for dx,dy,dz in [(-.045,0,0),(0,-.018,0),(.042,0,0),(0,.015,0),(0,0,.002)]:
        px=x+dx*math.cos(yaw)-dy*math.sin(yaw);py=y+dx*math.sin(yaw)+dy*math.cos(yaw)
        contact,n,f,d=tree.ray_cast(Vector((px,py,high[2]+1)),Vector((0,0,-1)))
        if contact is None or n.z<.7 or contact.z+.0008+dz>high[2]:local=[];break
        local.append((px,py,contact.z+.0008+dz))
    if len(local)==5:
        start=len(leafpoints);leafpoints+=local
        leaffaces += [(start+i,start+(i+1)%4,start+4) for i in range(4)]
if leafpoints:
    mesh=bpy.data.meshes.new('Attached paper-thin litter');mesh.from_pydata(leafpoints,[],leaffaces);mesh.materials.append(leafmat)
    leaves=bpy.data.objects.new('trail_transition litter',mesh);collections['FINISHED'].objects.link(leaves);assets['trail_transition'].append(leaves)

# Native LF parts: direct bevels inside the exact box envelope.
lf={'lf_post':(.18,.18,1.3),'lf_clamp':(.75,.34,.12),'lf_stamp':(.07,.25,.30),'lf_feed':(.11,1,.11),'lf_arrow_stem':(.10,1.2,.06),'lf_arrow_tip':(.07,.55,.06)}
for name,size in lf.items():
    bpy.ops.mesh.primitive_cube_add(size=1);o=bpy.context.object;move(o,'FINISHED');o.name=name;o.scale=size;active(o);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    bevel=o.modifiers.new('Small forged edge inside native box','BEVEL');bevel.width=min(size)*.055;bevel.segments=2;bpy.ops.object.modifier_apply(modifier=bevel.name)
    o.data.materials.append(materials['metal'] if name in ['lf_post','lf_clamp','lf_feed'] else materials['stone']);uv_project(o);assets[name]=[o]
    sources[name]={'native_size_blender_m':list(size),'origin':'centre, inherited native transform','construction':'direct bevel of exact current box'}

report={'sources':sources,'root_contact':roots_audit,'scar':scar_measure,'assets':{},'textures':texture_audit,'mapping':'Blender (x,y,z) -> Godot (x,z,-y), once through glTF'}
for name,objects in assets.items():
    low,high=bounds(objects);report['assets'][name]={'bounds_blender_m':[low.tolist(),high.tolist()],'levels':[]}
    for level in range(3):
        copies=[]
        for src in objects:
            o=clone(src,name+' LOD'+str(level)+' '+src.name,'RUNTIME')
            active(o)
            # Boundaries/material boundaries and scar channel remain; simplify coplanar excess.
            if level>0 or 'struck' in name:
                modifier=o.modifiers.new('Retain apertures and silhouette','DECIMATE');modifier.decimate_type='DISSOLVE';modifier.angle_limit=math.radians(.15 if level==0 else 1 if level==1 else 5);modifier.delimit={'MATERIAL','UV'};bpy.ops.object.modifier_apply(modifier=modifier.name)
                if level>0 and src is not objects[0] and tri_count(o)>700:
                    modifier=o.modifiers.new('Distant attached roots','DECIMATE');modifier.ratio=.5 if level==1 else .22;modifier.use_collapse_triangulate=True;bpy.ops.object.modifier_apply(modifier=modifier.name)
            # Collapse can overshoot a boundary: restore the measured native envelope.
            for vert in o.data.vertices:
                for axis in range(3):vert.co[axis]=max(low[axis],min(high[axis],vert.co[axis]))
            clean(o);copies.append(o)
        bpy.ops.object.select_all(action='DESELECT')
        for o in copies:o.hide_set(False);o.select_set(True)
        export=out/'models'/(name+'-lod'+str(level)+'.glb')
        bpy.ops.export_scene.gltf(filepath=str(export),export_format='GLB',use_selection=True,export_animations=False,export_materials='EXPORT',export_attributes=True,export_vertex_color='NAME',export_vertex_color_name='Scar')
        report['assets'][name]['levels'].append({'level':level,'triangles':sum(tri_count(o) for o in copies),'surfaces':sum(len(o.data.materials) for o in copies),'bytes':export.stat().st_size})
        for o in copies:o.hide_render=True;o.hide_set(True)
    for o in objects:o.hide_render=True;o.hide_set(True)
for o in collections['SOURCE'].objects:o.hide_render=True;o.hide_set(True)
# Review collection arranges actual sources, not a new in-game composition.
for index,name in enumerate(assets):
    for src in assets[name]:
        o=clone(src,'REVIEW '+name,'REVIEW');o.location.x+=(index%6)*4.0;o.location.y+=(index//6)*4.2
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24
scene.render.resolution_x=1600;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('C6 neutral review');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.25,.28,.30,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.7
bpy.ops.object.light_add(type='AREA',location=(4,-5,12));key=bpy.context.object;move(key,'REVIEW');key.data.energy=2600;key.data.size=9
bpy.ops.object.camera_add(location=(20,-23,20));cam=bpy.context.object;move(cam,'REVIEW');scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=28;cam.rotation_euler=(Vector((10,4,0))-cam.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(out/'c6-master.blend'),compress=True)
(out/'model-report.json').write_text(json.dumps(report,indent=2)+'\n')
print('C6_BUILD_OK',len(assets),'scar',scar_measure)
