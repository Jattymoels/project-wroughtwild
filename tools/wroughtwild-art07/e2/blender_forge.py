"""E2 direct metric modelling, original inspection, packed reopen and GLB audit.

No external geometry or generation. D5/D6 maps stay byte-identical. Each tier
uses the same Common collection, with an additive Improved collection. Blender
front -Y deliberately matches the existing Godot +Z workface and feedback mount.
"""
import bpy, hashlib, json, math, random, sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[3]
CFG=json.loads((Path(__file__).with_name('forge.json')).read_text())
ARGS=sys.argv[sys.argv.index('--')+1:]

def clean():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    for c in list(bpy.data.collections):
        if c.name!='Collection': bpy.data.collections.remove(c)

def collection(name):
    c=bpy.data.collections.new(name); bpy.context.scene.collection.children.link(c); return c

def put(obj,c):
    for old in list(obj.users_collection): old.objects.unlink(obj)
    c.objects.link(obj); return obj

def mat(name,stem=None,tint=(1,1,1,1),metal=0,rough=.8):
    m=bpy.data.materials.new(name);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=tint
    p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
    if stem:
        n=m.node_tree.nodes;l=m.node_tree.links
        for channel in ['albedo','normal','orm']:
            im=bpy.data.images.load(str(TEXTURES/f'{stem}_{channel}.png'),check_existing=True)
            if channel!='albedo':im.colorspace_settings.name='Non-Color'
            tex=n.new('ShaderNodeTexImage');tex.image=im
            if channel=='albedo':
                mix=n.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=tint
                l.new(tex.outputs['Color'],mix.inputs[1]);l.new(mix.outputs[0],p.inputs['Base Color'])
            elif channel=='normal':
                norm=n.new('ShaderNodeNormalMap');norm.inputs['Strength'].default_value=.35;l.new(tex.outputs[0],norm.inputs['Color']);l.new(norm.outputs[0],p.inputs['Normal'])
            else:
                split=n.new('ShaderNodeSeparateColor');l.new(tex.outputs[0],split.inputs[0]);l.new(split.outputs['Green'],p.inputs['Roughness'])
    return m

def uv(obj,repeat=.5):
    # Metric dominant-face projection; one UV set, stable map orientation.
    me=obj.data
    while me.uv_layers: me.uv_layers.remove(me.uv_layers[0])
    layer=me.uv_layers.new(name='MetricUV')
    for face in me.polygons:
        normal=face.normal;axis=max(range(3),key=lambda a:abs(normal[a]));sign=1 if normal[axis]>0 else -1
        for li in face.loop_indices:
            v=me.vertices[me.loops[li].vertex_index].co
            a,b=((v.y*sign,v.z) if axis==0 else ((-v.x*sign,v.z) if axis==1 else (v.x,v.y*sign)))
            layer.data[li].uv=(a/repeat,b/repeat)
    if me.materials and me.materials[0].name=='Stone':
        # Map one existing D5 block interior onto each authored stone. Physical
        # joints own the courses; never paint a second miniature wall on a jamb.
        axis_lo=[min(v.co[a] for v in me.vertices) for a in range(3)]
        axis_hi=[max(v.co[a] for v in me.vertices) for a in range(3)]
        for face in me.polygons:
            axis=max(range(3),key=lambda a:abs(face.normal[a]));axes=[a for a in range(3) if a!=axis]
            for li in face.loop_indices:
                p=me.vertices[me.loops[li].vertex_index].co
                a,b=[(p[d]-axis_lo[d])/max(.001,axis_hi[d]-axis_lo[d]) for d in axes]
                layer.data[li].uv=(.105+a*.195,.145+b*.19)

def finish(obj,name,c,m,bevel=0,segments=1):
    obj.name=name;put(obj,c);obj.data.materials.append(m)
    bpy.context.view_layer.objects.active=obj;obj.select_set(True)
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    if bevel:
        mod=obj.modifiers.new('Worked edges','BEVEL');mod.width=bevel;mod.segments=segments
        bpy.ops.object.modifier_apply(modifier=mod.name)
    uv(obj,1 if m.name=='Stone' else .5)
    obj.select_set(False);return obj

def box(name,loc,size,c,m,bevel=0,segments=1):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.scale=size
    return finish(o,name,c,m,bevel,segments)

def mesh(name,verts,faces,c,m):
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    o=bpy.data.objects.new(name,me);c.objects.link(o);me.materials.append(m);uv(o);return o

def beam(name,a,b,width,c,m):
    a,b=Vector(a),Vector(b);d=b-a
    bpy.ops.mesh.primitive_cube_add(size=1,location=(a+b)/2);o=bpy.context.object;o.scale=(width,width,d.length)
    o.rotation_euler=d.to_track_quat('Z','Y').to_euler();return finish(o,name,c,m,.002)

def hood(name,z0,z1,low,high,y,c,m):
    vs=[(x*w/2,y+s*d/2,z) for z,w,d in [(z0,*low),(z1,*high)] for x,s in [(-1,-1),(1,-1),(1,1),(-1,1)]]
    # Open-backed thin plates: closed individually, genuine hollow throat.
    for i in range(4):
        j=(i+1)%4;a,b,d,e=vs[i],vs[j],vs[4+j],vs[4+i]
        outer=[a,b,d,e];inner=[(v[0]*.968,y+(v[1]-y)*.968,v[2]) for v in outer]
        mesh(name+str(i),outer+inner,[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],c,m)

def scar(host,c,m):
    # Cutter and recessed energy ribbon share the same measured zigzag centre.
    path=[(-.346,.97),(-.36,1.05),(-.329,1.13),(-.352,1.22),(-.324,1.30),(-.336,1.39)]
    w=CFG['scar_width_m'];front=-.285;depth=CFG['scar_depth_m']
    outline=[(x-w/2,z) for x,z in path]+[(x+w/2,z) for x,z in reversed(path)]
    n=len(outline);v=[(x,y,z) for y in [front-.03,front+depth] for x,z in outline]
    cutter=mesh('FractureTool',v,[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)],c,m)
    mod=host.modifiers.new('Open hearth fracture','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cutter
    bpy.context.view_layer.objects.active=host;bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(cutter,do_unlink=True);uv(host,1)
    # Narrow buried floor; no strip bridges intact stone.
    verts=[];faces=[]
    for x,z in path:verts.extend([(x-w*.20,front+CFG['scar_energy_recess_m'],z),(x+w*.20,front+CFG['scar_energy_recess_m'],z)])
    for i in range(len(path)-1):faces.append((i*2,(i+1)*2,(i+1)*2+1,i*2+1))
    mesh('BuriedWorkFace',verts,faces,c,m)
    # Confirm actual cut by front-facing mesh ray at every interior centre.
    depths=[]
    for x,z in path[1:-1]:
        hit,point,normal,index=host.ray_cast(Vector((x,front-.1,z)),Vector((0,1,0)))
        assert hit
        depths.append(point.y-front)
    assert min(depths)>depth-.001,depths
    return depths

def build(level):
    rng=random.Random(CFG['seed']);c=collection('Common_'+level);add=collection('Improved_'+level)
    stone=MATS['Stone'];iron=MATS['Iron'];dark=MATS['Soot'];coal=MATS['Charcoal']
    bevel=CFG['stone_bevel_m'] if level!='far' else .01
    # Dense backing and discrete fitted courses give real joints and closed feet.
    box('MortarCore',(0,0,.39),(.856,.818,.78),c,dark,.009)
    for row in range(4):
        z=.10+row*.19
        splits=[-.447,-.21,.11,.447] if row%2==0 else [-.447,-.10,.24,.447]
        for j,(a,b) in enumerate(zip(splits,splits[1:])):
            for y in [-.405,.405]:
                box(f'Bed_{row}_{j}_{y}',((a+b)/2,y,z),(b-a-.01,.08,.181),c,stone,bevel)
        for x in [-.41,.41]:
            for j in range(3):box(f'Return_{row}_{j}_{x}',(x,-.25+j*.25,z),(.074,.244,.18),c,stone,bevel)
    box('HearthFloor',(0,0,.81),(.87,.84,.07),c,dark,.008)
    for x in [-.37,.37]:box('HearthRim',(x,0,.895),(.17,.85,.13),c,stone,.016)
    box('RearHearthRim',(0,.365,.895),(.60,.12,.13),c,stone,.016)
    # Front forging face surrounds exactly the existing (0,.94,+.35) mount.
    box('WorkingPlate',(0,-.335,.913),(.62,.25,.048),c,iron,.005,2)
    for x in [-.25,.25]:beam('PlateBracket',(x,-.405,.88),(x,-.20,.59),.035,c,iron)
    # Stone rear wall carries throat; front uprights visibly support the cowl.
    for row in range(3):
        for x in [-.21,.0,.21]:box('Fireback',(x,.337,1.02+row*.155),(.203,.15,.148),c,stone,.014)
    host=box('ScarredJamb',(-.348,-.18,1.185),(.16,.21,.46),c,stone,.012)
    depths=scar(host,c,MATS['Work'])
    box('RightJamb',(.348,-.18,1.185),(.16,.21,.46),c,stone,.012)
    for x in [-.40,.40]:beam('CowlPost',(x,-.17,.91),(x,-.17,1.47),.04,c,iron)
    for x in [-.40,.40]:beam('RearCowlPost',(x,.335,.91),(x,.335,1.47),.035,c,iron)
    hood('Cowl',1.46,1.70,(.90,.63),(.38,.32),.08,c,iron)
    for y in [-.235,.395]:box('HoodRolledEdge',(0,y,1.464),(.914,.025,.045),c,iron,.004)
    for x in [-.445,.445]:box('HoodSideEdge',(x,.08,1.464),(.026,.61,.045),c,iron,.004)
    # Short flue is hollow, capped on four supported pegs.
    for x in [-.173,.173]:box('FlueSide',(x,.08,1.77),(.035,.31,.15),c,stone,.007)
    for y in [-.06,.22]:box('FlueFace',(0,y,1.77),(.31,.035,.15),c,stone,.007)
    for x in [-.16,.16]:
        for y in [-.055,.215]:beam('CapPeg',(x,y,1.82),(x,y,1.93),.023,c,iron)
    hood('RainCap',1.915,1.96,(.49,.42),(.01,.01),.08,c,iron)
    # The black clinker is presentation, not a visible inventory of free fuel.
    count={'near':32,'middle':18,'far':9}[level]
    for i in range(count):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2 if level=='near' else 1,radius=1,location=(rng.uniform(-.24,.24),rng.uniform(-.13,.22),.863))
        o=bpy.context.object;o.scale=(rng.uniform(.027,.06),rng.uniform(.025,.06),rng.uniform(.02,.045));o.rotation_euler=(rng.random(),rng.random(),rng.random())
        finish(o,'ColdClinker',c,coal)
    # Upgrade is additive on exactly the same base; no second kit or socket.
    for x in [-.296,.296]:box('ContainmentCheek',(x,.045,1.17),(.035,.49,.43),add,dark,.004)
    box('ChamberLintel',(0,-.205,1.385),(.65,.065,.09),add,iron,.005)
    for x in [-.315,.315]:box('ChamberCollar',(x,-.245,1.19),(.060,.065,.41),add,iron,.004)
    box('RefinedWorkPlate',(0,-.334,.945),(.71,.255,.028),add,iron,.005,2)
    for z in [.18,.69]:
        box('ReinforcedFrontBand',(0,-.45,z),(.91,.027,.045),add,iron,.003)
        for x in [-.447,.447]:box('ReinforcedSideBand',(x,0,z),(.025,.87,.045),add,iron,.003)
    # Rivets/peens omitted only where invisible at far detail.
    if level!='far':
        points=[(x,-.259,1.464) for x in [-.38,-.19,0,.19,.38]]
        points += [(x,-.275,z) for x in [-.315,.315] for z in [1.04,1.19,1.34]]
        for i,(x,y,z) in enumerate(points):
            bpy.ops.mesh.primitive_uv_sphere_add(segments=10 if level=='near' else 6,ring_count=5,radius=1,location=(x,y,z));o=bpy.context.object;o.scale=(.012,.007,.012)
            finish(o,'PeenedHead',c if i<5 else add,iron)
    return c,add,depths

def metrics(objects):
    triangles=bad=0;verts=[];dig=hashlib.sha256()
    for o in sorted(objects,key=lambda o:o.name):
        if o.type!='MESH':continue
        o.data.calc_loop_triangles()
        triangles+=len(o.data.loop_triangles)
        for t in o.data.loop_triangles:
            a,b,c=[o.matrix_world@o.data.vertices[i].co for i in t.vertices]
            if (b-a).cross(c-a).length<1e-10:bad+=1
        for v in o.data.vertices:
            p=o.matrix_world@v.co;assert all(math.isfinite(a) for a in p);verts.append(p)
            dig.update((','.join(f'{a:.7f}' for a in p)+';').encode())
    lo=[min(v[i] for v in verts) for i in range(3)];hi=[max(v[i] for v in verts) for i in range(3)]
    return dict(triangles=triangles,degenerates=bad,bounds_blender=[lo,hi],geometry_sha256=dig.hexdigest(),mesh_objects=len(objects))

def export(objects,path):
    bpy.ops.object.select_all(action='DESELECT')
    copies=[]
    for o in objects:
        n=o.copy();n.data=o.data.copy();bpy.context.scene.collection.objects.link(n);n.select_set(True);copies.append(n)
    bpy.context.view_layer.objects.active=copies[0];bpy.ops.object.join();joined=bpy.context.object
    joined.name=path.stem;bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    # Join keeps many equivalent slots; consolidate for one draw per material.
    slots=list(joined.data.materials);unique=list(dict.fromkeys(slots));mapping={i:unique.index(m) for i,m in enumerate(slots)}
    idx=[mapping[p.material_index] for p in joined.data.polygons];joined.data.materials.clear()
    for m in unique:joined.data.materials.append(m)
    for p,i in zip(joined.data.polygons,idx):p.material_index=i
    mod=joined.modifiers.new('Runtime triangles','TRIANGULATE')
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_materials='EXPORT',export_image_format='AUTO',export_tangents=True)
    bpy.data.objects.remove(joined,do_unlink=True)

def stage():
    sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=24
    sc.render.threads_mode='FIXED';sc.render.threads=8
    sc.render.resolution_x=1100;sc.render.resolution_y=1100;sc.render.resolution_percentage=100
    sc.world.color=(.2,.2,.2);sc.view_settings.view_transform='AgX'
    sc.render.image_settings.file_format='PNG'
    for name,loc,power,size in [('Key',(3,-4,5),650,4),('Fill',(-3,-2,3),420,3),('Rim',(1,3,4),850,3)]:
        data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size
        o=bpy.data.objects.new(name,data);sc.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
    data=bpy.data.cameras.new('Camera');cam=bpy.data.objects.new('Camera',data);sc.collection.objects.link(cam);sc.camera=cam;data.type='ORTHO';data.ortho_scale=2.6
    return cam

def renders(out,objects,prefix,all_angles=True):
    sc=bpy.context.scene;allowed=set(objects)
    for o in bpy.data.objects:
        if o.type=='MESH':o.hide_render=o not in allowed
    cam=sc.camera
    views={'three-quarter':(3,-5,3),'front':(0,-5,1.1),'back':(0,5,1.1),'side':(5,0,1.1),'top':(0,-.001,7),'underside':(0,-.01,-6)}
    if not all_angles:views={'three-quarter':views['three-quarter']}
    for name,loc in views.items():
        cam.location=loc;cam.rotation_euler=(Vector((0,0,.98))-cam.location).to_track_quat('-Z','Y').to_euler()
        sc.render.filepath=str(out/f'{prefix}-{name}.png');bpy.ops.render.render(write_still=True)

if ARGS[0]=='--original':
    out=Path(ARGS[1]).resolve();out.mkdir(parents=True,exist_ok=False);clean();records={}
    for tier in ['basic','improved']:
        clean();bpy.ops.import_scene.gltf(filepath=str(ROOT/f'game/assets/authored/forge_{tier}.glb'))
        objects=[o for o in bpy.data.objects if o.type=='MESH'];records[tier]=metrics(objects);stage();renders(out,objects,'original-'+tier,False)
    (out/'original.json').write_text(json.dumps(records,indent=2))
elif ARGS[0]=='--reopen':
    src,out=[Path(s).resolve() for s in ARGS[1:3]];out.mkdir(parents=True,exist_ok=False);bpy.ops.wm.open_mainfile(filepath=str(src))
    images=[i for i in bpy.data.images if i.type=='IMAGE'];assert len(images)==9 and all(i.packed_file for i in images)
    stage();records={}
    for tier in ['basic','improved']:
        objects=list(bpy.data.collections['Common_near'].objects)
        if tier=='improved':objects+=list(bpy.data.collections['Improved_near'].objects)
        records[tier]=metrics(objects);renders(out,objects,tier)
        clay=mat('Clay',tint=(.40,.38,.34,1));bpy.context.view_layer.material_override=clay
        renders(out,objects,tier+'-clay');bpy.context.view_layer.material_override=None
    # Fresh imports independently count output after exporter/importer triangulation.
    imports={}
    for p in sorted((src.parent.parent/'runtime').glob('*.glb')):
        clean();bpy.ops.import_scene.gltf(filepath=str(p));r=metrics([o for o in bpy.data.objects if o.type=='MESH']);assert r['degenerates']==0;imports[p.name]=r
    (out/'reopen.json').write_text(json.dumps({'packed_images':len(images),'source':records,'imports':imports},indent=2))
else:
    TEXTURES=Path(ARGS[0]).resolve();out=Path(ARGS[1]).resolve();out.mkdir(parents=True,exist_ok=False);clean()
    runtime=out.parent/'runtime';runtime.mkdir(exist_ok=False)
    MATS={'Stone':mat('Stone','d5_stone_edge',(.83,.79,.72,1)),'Iron':mat('Iron','d6_iron',(.55,.49,.42,1),metal=1),'Soot':mat('Soot','d6_iron',(.18,.16,.14,1),metal=.3),'Charcoal':mat('Charcoal','d5_charcoal_face'),'Work':mat('Work',tint=(.025,.013,.006,1))}
    reports={}
    for level in CFG['levels']:
        common,add,depths=build(level);common_stats=metrics(list(common.objects));assert common_stats['degenerates']==0
        for tier in ['basic','improved']:
            objects=list(common.objects)+(list(add.objects) if tier=='improved' else [])
            r=metrics(objects);lo,hi=r['bounds_blender'];assert min(lo[2],0)>-.0001 and max(abs(lo[0]),abs(hi[0]),abs(lo[1]),abs(hi[1]))<=.48 and hi[2]<=2
            assert r['degenerates']==0;r['shared_common_geometry_sha256']=common_stats['geometry_sha256'];r['scar_depths_m']=depths
            reports[f'forge_{tier}_{level}']=r;export(objects,runtime/f'forge_{tier}_{level}.glb')
    for i in bpy.data.images:
        if i.type=='IMAGE':i.pack()
    for c in bpy.data.collections:
        if c.name.startswith(('Common_','Improved_')):
            c.hide_render=not c.name.endswith('near')
    bpy.ops.wm.save_as_mainfile(filepath=str(out/'e2_forges.blend'))
    (out/'geometry.json').write_text(json.dumps(reports,indent=2)+'\n')
    print('E2_BLENDER_OK',reports)
