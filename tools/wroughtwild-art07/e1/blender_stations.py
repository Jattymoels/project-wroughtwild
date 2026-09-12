"""E1 direct metric stations. Utility lineage: published E2 Blender recipe.
No organic generation; original sources and D4/D5 maps remain unchanged.
"""
import bpy, bmesh, hashlib, json, math, random, sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[3]
CFG=json.loads(Path(__file__).with_name('stations.json').read_text())
ARGS=sys.argv[sys.argv.index('--')+1:]
def clean():
    # Selection operators skip hidden LOD collections. Independent import audits
    # must remove every prior object, including hidden/unlinked source objects.
    for obj in list(bpy.data.objects):bpy.data.objects.remove(obj,do_unlink=True)
    for c in list(bpy.data.collections):
        if c.name!='Collection': bpy.data.collections.remove(c)

def collection(name):
    c=bpy.data.collections.new(name); bpy.context.scene.collection.children.link(c); return c

def put(obj,c):
    for old in list(obj.users_collection): old.objects.unlink(obj)
    c.objects.link(obj); return obj

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

def material(name,stem=None,colour=(.18,.16,.12,1),metal=0):
    m=bpy.data.materials.new(name);m.use_nodes=True
    n=m.node_tree.nodes;l=m.node_tree.links;p=n.get('Principled BSDF')
    p.inputs['Base Color'].default_value=colour;p.inputs['Roughness'].default_value=.85;p.inputs['Metallic'].default_value=metal
    if stem:
        for channel in ['albedo','normal','orm']:
            im=bpy.data.images.load(str(TEXTURES/f'{stem}_{channel}.png'),check_existing=True)
            if channel!='albedo':im.colorspace_settings.name='Non-Color'
            t=n.new('ShaderNodeTexImage');t.image=im
            if channel=='albedo':l.new(t.outputs['Color'],p.inputs['Base Color'])
            elif channel=='normal':
                norm=n.new('ShaderNodeNormalMap');norm.inputs['Strength'].default_value=CFG['normal_strength'];l.new(t.outputs[0],norm.inputs['Color']);l.new(norm.outputs[0],p.inputs['Normal'])
            else:
                split=n.new('ShaderNodeSeparateColor');l.new(t.outputs[0],split.inputs[0]);l.new(split.outputs['Green'],p.inputs['Roughness'])
    return m

def map_uv(obj,grain=2,phase=0):
    me=obj.data
    if not me.uv_layers:me.uv_layers.new(name='MetricUV')
    uv=me.uv_layers.active
    wood=me.materials[0].name in ['Wood','End']
    lo=[min(v.co[a] for v in me.vertices) for a in range(3)]
    hi=[max(v.co[a] for v in me.vertices) for a in range(3)]
    for face in me.polygons:
        axis=max(range(3),key=lambda a:abs(face.normal[a]));sgn=1 if face.normal[axis]>0 else -1
        end=wood and axis==grain
        if wood:face.material_index=1 if end else 0
        other=[a for a in range(3) if a!=axis]
        if wood and not end:other=[next(a for a in other if a!=grain),grain]
        for li in face.loop_indices:
            v=me.vertices[me.loops[li].vertex_index].co
            u,w=v[other[0]]*sgn,v[other[1]]
            if wood:uv.data[li].uv=(u/.5+phase,w/(.5 if end else 2)+phase*.3)
            else:
                # A single D5 rock interior, without miniature masonry courses.
                if me.materials[0].name=='Stone':
                    a,b=[(v[d]-lo[d])/max(.0001,hi[d]-lo[d]) for d in other]
                    uv.data[li].uv=(.12+a*.16,.40+b*.15)
                else:uv.data[li].uv=(.13+u*.15,.16+w*.15)

def finish(o,name,c,m,grain=2,bevel=.007,phase=0):
    o.name=name;put(o,c);o.data.materials.append(m)
    if m.name=='Wood':o.data.materials.append(MATS['End'])
    bpy.context.view_layer.objects.active=o;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    if bevel:
        mod=o.modifiers.new('Worked edge','BEVEL');mod.width=bevel;mod.segments=2 if LEVEL=='near' else 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    map_uv(o,grain,phase);o.select_set(False);return o

def box(name,loc,size,c,m,grain=2,bevel=.007,phase=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.scale=size
    return finish(o,name,c,m,grain,bevel,phase)

def rod(name,a,b,r,c,m,vertices=10):
    a,b=Vector(a),Vector(b);d=b-a
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=d.length,location=(a+b)/2)
    o=bpy.context.object;o.rotation_euler=d.to_track_quat('Z','Y').to_euler()
    return finish(o,name,c,m,bevel=.001)

def notch(host,at,size,c,angle=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=at);cut=bpy.context.object;cut.scale=size;cut.rotation_euler.z=angle
    bpy.context.view_layer.objects.active=cut;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    mod=host.modifiers.new('Real tool incision','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cut
    bpy.context.view_layer.objects.active=host;bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cut,do_unlink=True)
    map_uv(host,0,.2)

def worn_edge(host,loc,size,c,angle):
    # Side-on missing chips expose real cut-end surfaces. No glowing mask.
    notch(host,loc,size,c,angle)

def wedge(c,wood,top):
    vertices=[(-.23,.13,top),(-.10,.13,top),(-.10,.18,top),(-.23,.18,top),(-.23,.13,top+.035),(-.23,.18,top+.035)]
    me=bpy.data.meshes.new('TimberWedge');me.from_pydata(vertices,[],[(3,2,1,0),(0,1,4),(1,2,5,4),(2,3,5),(3,0,4,5)])
    me.update();o=bpy.data.objects.new('RestingTimberWedge',me);c.objects.link(o)
    return finish(o,'RestingTimberWedge',c,wood,0,.002)

def build(id,level):
    global LEVEL
    LEVEL=level;rng=random.Random(CFG['seed']);c=collection('FINISHED_'+id+'_'+level)
    wood=MATS['Wood'];stone=MATS['Fieldstone'];metal=MATS['Tool'];top=CFG['worktop_m'] if id=='workbench' else .92
    # Pegged upright frames with tenons and open negative space under workface.
    for x in [-.335,.335]:
        for y in [-.30,.30]:
            box('TenonedLeg',(x,y,(top-.12)/2),(.13,.13,top-.12),c,wood,2,phase=.14+x+y)
        for z in [.23,top-.20]:box('SideRail',(x,0,z),(.095,.60,.105),c,wood,1,phase=.4+x)
    for z in [.23,top-.20]:
        for y in [-.30,.30]:box('CrossRail',(0,y,z),(.67,.085,.105),c,wood,0,phase=.7+y)
    if level!='far':
        for x in [-.335,.335]:
            for y in [-.372,.372]:
                for z in [.23,top-.20]:rod('OakPeg',(x,y,z),(x,y+(.012 if y>0 else -.012),z),.015,c,wood,8)
    scars=[]
    if id=='workbench':
        for i in range(5):
            y=-.32+i*.16
            plank=box('ThickWorkPlank',(0,y,top-.065),(.90,.155,.13),c,wood,0,phase=i*.173)
            if level=='near':
                x=-.20+i*.065;notch(plank,(x,y,top-CFG['wear_depth_m']/2),(.20,.008,CFG['wear_depth_m']+.003),c,.3-i*.13)
                hit,p,n,idx=plank.ray_cast(Vector((x,y,top+.05)),Vector((0,0,-1)))
                assert hit and top-p.z>=CFG['wear_depth_m']-.002
                scars.append(top-p.z)
                worn_edge(plank,((-.447 if i%2 else .447),y+.018,top-.02),(.021,.039,.025),c,.2+i*.17)
                if i==0:
                    for j in range(3):worn_edge(plank,(-.31+j*.225,-.394,top-.012),(.040,.020,.028),c,.3-j*.21)
        # Captive front jaw and wooden screw sit entirely inside the 0.96m box.
        box('ClampJaw',(.20,-.414,top-.13),(.30,.062,.17),c,wood,0)
        rod('ClampScrew',(.20,-.36,top-.13),(.20,-.472,top-.13),.027,c,wood,12 if level=='near' else 8)
        rod('CaptiveHandle',(.20,-.456,top-.23),(.20,-.456,top-.03),.012,c,wood,8)
        for x in [-.28,.29]:box('BenchStop',(x,.27,top+.018),(.055,.06,.065),c,wood)
        if level!='far':
            wedge(c,wood,top)
    else:
        box('DustBed',(0,0,top-.055),(.76,.69,.09),c,MATS['Dust'],bevel=.008)
        for x in [-.407,.407]:box('BedSide',(x,0,top),(.08,.86,.13),c,wood,1)
        for y in [-.389,.389]:box('BedEnd',(0,y,top),(.74,.08,.13),c,wood,0)
        host=box('ContainedDressingStone',(0,.02,top+.070),(.39,.33,.19),c,MATS['Stone'],bevel=.024)
        if level!='far':
            notch(host,(.04,-.115,top+.171),(.14,.018,.045),c,.35)
            if level=='near':
                for x,y in [(-.187,-.124),(.181,.152),(.176,-.13)]:
                    worn_edge(host,(x,y,top+.145),(.053,.060,.068),c,x*3)
        # Six fixed bed stones refer to the native ingredient, not collectables.
        for i in range(6):
            angle=i*math.tau/6;x=math.cos(angle)*.275;y=math.sin(angle)*.24
            box('BedFieldstone',(x,y,top+.003),(.13+rng.random()*.02,.12,.085),c,stone,bevel=.025,phase=i*.1)
        box('ChiselRest',(0,-.421,top-.13),(.48,.067,.06),c,wood,0)
        for x in [-.16,0,.16]:
            rod('StoneChisel',(x,-.425,top-.36),(x,-.425,top-.045),.012,c,metal,8)
            box('ChiselBlade',(x,-.425,top-.36),(.026,.014,.06),c,metal,bevel=.002)
        if level!='far':
            rod('MalletHandle',(.26,.24,top+.09),(.34,.05,top+.09),.015,c,wood,8)
            box('StoneMallet',(.255,.25,top+.095),(.14,.09,.09),c,stone,bevel=.012)
        if level=='near':
            for i in range(22):
                x=rng.uniform(-.33,.33);y=rng.uniform(-.29,.29)
                if abs(x)<.21 and abs(y-.02)<.18:continue
                box('FixedCuttingChip',(x,y,top+.012),(.018+rng.random()*.015,.017,.012),c,MATS['Stone'],bevel=.003)
    return c,scars

def audit(objects):
    r=metrics(objects);r['nonmanifold_edges']=0
    for o in objects:
        bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
        r['nonmanifold_edges']+=sum(not e.is_manifold for e in bm.edges);bm.free()
    lo,hi=r['bounds_blender']
    assert r['degenerates']==0 and r['nonmanifold_edges']==0,r
    assert lo[2]>=-.00001 and hi[2]<=2 and max(abs(lo[0]),abs(lo[1]),abs(hi[0]),abs(hi[1]))<=.48001,r
    return r

def renders(out,objects,prefix):
    sc=bpy.context.scene;allowed=set(objects)
    for o in bpy.data.objects:
        if o.type=='MESH':o.hide_render=o not in allowed
    for c in bpy.data.collections:c.hide_render=False
    sc.render.resolution_x=1000;sc.render.resolution_y=1000;sc.cycles.samples=20
    cam=sc.camera;cam.data.ortho_scale=1.62
    for name,loc in {'three-quarter':(2.6,-4,2.8),'back':(-2.6,4,2.4),'top':(0,-.01,5),'underside':(0,-3,-1)}.items():
        cam.location=loc;cam.rotation_euler=(Vector((0,0,.55))-cam.location).to_track_quat('-Z','Y').to_euler()
        sc.render.filepath=str(out/f'{prefix}-{name}.png');bpy.ops.render.render(write_still=True)

if ARGS[0]=='--original':
    out=Path(ARGS[1]).resolve();out.mkdir(parents=True,exist_ok=False);records={}
    for id in ['workbench','mason_yard']:
        clean();bpy.ops.import_scene.gltf(filepath=str(ROOT/f'game/assets/authored/{id}.glb'))
        objects=[o for o in bpy.data.objects if o.type=='MESH'];records[id]=metrics(objects);stage();renders(out,objects,'original-'+id)
    (out/'original.json').write_text(json.dumps(records,indent=2))
elif ARGS[0]=='--reopen':
    src,out=[Path(s).resolve() for s in ARGS[1:3]];out.mkdir(parents=True,exist_ok=False);bpy.ops.wm.open_mainfile(filepath=str(src))
    images=[i for i in bpy.data.images if i.type=='IMAGE'];assert len(images)==12 and all(i.packed_file for i in images)
    stage();records={}
    for id in ['workbench','mason_yard']:
        objects=list(bpy.data.collections['FINISHED_'+id+'_near'].objects);records[id]=audit(objects)
        renders(out,objects,id)
        clay=material('Clay',colour=(.35,.32,.27,1));bpy.context.view_layer.material_override=clay
        renders(out,objects,id+'-clay');bpy.context.view_layer.material_override=None
    imports={}
    for p in sorted((src.parent.parent/'runtime').glob('*.glb')):
        clean();bpy.ops.import_scene.gltf(filepath=str(p));imports[p.name]=audit([o for o in bpy.data.objects if o.type=='MESH'])
    (out/'reopen.json').write_text(json.dumps({'packed_images':len(images),'source':records,'imports':imports},indent=2))
else:
    TEXTURES=Path(ARGS[0]).resolve();out=Path(ARGS[1]).resolve();out.mkdir(parents=True,exist_ok=False);clean()
    runtime=out.parent/'runtime';runtime.mkdir(exist_ok=False)
    MATS={name:material(name,stem) for name,stem in [('Wood','d4_wood_face'),('End','d4_wood_edge'),('Fieldstone','d5_fieldstone_edge'),('Stone','d5_stone_edge')]}
    MATS['Dust']=material('Dust',colour=(.19,.175,.14,1));MATS['Tool']=material('Tool',colour=(.095,.10,.105,1),metal=.7)
    records={};collection('SOURCE_readonly_lineage_in_provenance');collection('RUNTIME_exports');collection('REVIEW')
    for level in CFG['levels']:
        for id in ['workbench','mason_yard']:
            c,cuts=build(id,level);r=audit(list(c.objects));r['tool_cut_depths_m']=cuts;records[id+'_'+level]=r
            export(list(c.objects),runtime/f'{id}_{level}.glb')
            c.hide_render=level!='near';c.hide_viewport=level!='near'
    for i in bpy.data.images:
        if i.type=='IMAGE':i.pack()
    bpy.ops.wm.save_as_mainfile(filepath=str(out/'e1_stations.blend'))
    (out/'geometry.json').write_text(json.dumps(records,indent=2)+'\n');print('E1_BLENDER_OK', {k:r['triangles'] for k,r in records.items()})
