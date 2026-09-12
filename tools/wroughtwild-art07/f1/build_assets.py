"""F1 organic recovery, measured incisions, fitted cages and tapping mechanism.
Blender --background --threads 8 --python-exit-code 1 --python ... -- HEART TUBE OUT
geometry.py is a bounded derivative of the inspected F3 geometry helpers.
"""
import sys, json, math
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from geometry import *
import numpy as np

def scar(o, kind):
    me=o.data; me.update()
    axis=2 if kind=='lanternheart' else 0
    lo=min(v.co[axis] for v in me.vertices); hi=max(v.co[axis] for v in me.vertices)
    cross=0 if axis==2 else 2
    center=(min(v.co[cross] for v in me.vertices)+max(v.co[cross] for v in me.vertices))/2
    depth=CFG['scar_depth_m'][kind]; width=CFG['scar_half_width_m'][kind]
    def path(t): return center+width*.8*math.sin(t*9.0)
    before=BVHTree.FromPolygons([v.co.copy() for v in me.vertices],[tuple(p.vertices) for p in me.polygons])
    colors=me.color_attributes.new(name='F1_SCAR',type='FLOAT_COLOR',domain='POINT')
    for v in me.vertices:
        t=(v.co[axis]-lo)/(hi-lo); d=min(abs(v.co[cross]-path(t)),abs(v.co[cross]-path(t)-width*2.5*(t-.35)) if .35<t<.72 else 100)
        fade=max(0,min(1,(t-.10)/.10,(.90-t)/.10)); front=max(0,min(1,-v.co.y/(width*.7)))
        w=math.exp(-(d/width)**2)*fade*front
        v.co.y+=depth*w
        colors.data[v.index].color=(math.exp(-(d/(width*1.9))**2)*fade*front,w**3,t,1)
    me.update(); after=BVHTree.FromPolygons([v.co.copy() for v in me.vertices],[tuple(p.vertices) for p in me.polygons]); samples=[]
    for t in [.2,.3,.4,.5,.6,.7,.8]:
        p=Vector((0,-3,0));p[axis]=lo+t*(hi-lo);p[cross]=path(t)
        a=before.ray_cast(p,Vector((0,1,0)))[0];b=after.ray_cast(p,Vector((0,1,0)))[0]
        if a is not None and b is not None:samples.append({'t':t,'inward_m':b.y-a.y})
    assert samples and max(x['inward_m'] for x in samples)>depth*.6,(kind,samples)
    for mat in me.materials:
        ns=mat.node_tree.nodes;ls=mat.node_tree.links;p=ns.get('Principled BSDF')
        vc=ns.new('ShaderNodeVertexColor');vc.layer_name='F1_SCAR';s=ns.new('ShaderNodeSeparateColor');ls.new(vc.outputs['Color'],s.inputs[0])
        mix=ns.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[2].default_value=(.10,.075,.055,1)
        old=p.inputs['Base Color'].links[0].from_socket if p.inputs['Base Color'].is_linked else None
        if old:
            ls.new(old,mix.inputs[1])
            if old.node.type=='TEX_IMAGE':mat['f1_original_albedo_node']=old.node.name
        else:mix.inputs[1].default_value=p.inputs['Base Color'].default_value
        ls.new(s.outputs['Red'],mix.inputs[0]);ls.new(mix.outputs[0],p.inputs['Base Color'])
        p.inputs['Emission Color'].default_value=(1,.56,.16,1) if kind=='lanternheart' else (.72,.84,1,1)
        gate=ns.new('ShaderNodeMath');gate.operation='MULTIPLY';gate.name='F1_WORK';gate.inputs[1].default_value=0
        ls.new(s.outputs['Green'],gate.inputs[0]);ls.new(gate.outputs[0],p.inputs['Emission Strength'])
        mat.name='f1_'+kind+'_skin'
    return {'depth_m':depth,'half_width_m':width,'before_after_bvh':samples}

def organic(src,kind,source,finished,runtime,out):
    bpy.ops.import_scene.gltf(filepath=str(src));meshes=[o for o in bpy.context.selected_objects if o.type=='MESH']
    raw=join(meshes,'Raw_'+kind,source);active(raw);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    rawstats=stats(raw);master=clone(raw,'Finished_'+kind,finished)
    pts=np.array([list(v.co) for v in raw.data.vertices]);basis=np.eye(3)
    if kind=='stormglass':
        values,vectors=np.linalg.eigh(np.cov(pts.T));long=vectors[:,-1]
        if long[0]<0:long=-long
        up=np.array([0.,0.,1.]);up-=long*np.dot(up,long);up/=np.linalg.norm(up)
        basis=np.array([long,np.cross(up,long),up]);pts=pts@basis.T
    axis=2 if kind=='lanternheart' else 0;lo=pts.min(axis=0);hi=pts.max(axis=0)
    center=(lo+hi)/2;center[2]=lo[2] if kind=='lanternheart' else center[2]
    scale=CFG['core_length_m'][kind]/(hi[axis]-lo[axis])
    for v,p in zip(master.data.vertices,pts):v.co=(p-center)*scale
    for i,m in enumerate(master.data.materials):master.data.materials[i]=m.copy()
    seal(master,kind)
    bore=None
    if kind=='stormglass':
        # Recover the real through-opening if single-image reconstruction occludes it.
        bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=.020,depth=.7,rotation=(0,math.pi/2,0))
        cutter=bpy.context.object;active(master);mod=master.modifiers.new('Open resonator bore','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cutter
        bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cutter,do_unlink=True)
        # Newly exposed bore has its own cylindrical chart and quiet mineral material.
        mat=solid('f1_stormglass_bore',(.25,.24,.20));master.data.materials.append(mat);uvs=master.data.uv_layers.active.data
        for p in master.data.polygons:
            if abs(math.hypot(p.center.y,p.center.z)-.020)<.002:
                p.material_index=len(master.data.materials)-1
                for li in p.loop_indices:
                    v=master.data.vertices[master.data.loops[li].vertex_index].co
                    uvs[li].uv=(v.x/.44,math.atan2(v.z,v.y)/math.tau)
        bore={'radius_m':.020,'axis':'Blender X','new_surface_uv':'longitudinal/circumferential bore chart'}
        seal(master,kind)
        tree=BVHTree.FromPolygons([v.co.copy() for v in master.data.vertices],[tuple(p.vertices) for p in master.data.polygons])
        assert tree.ray_cast(Vector((-1,0,0)),Vector((1,0,0)))[0] is None,'Recovered tube bore is obstructed'
    injury=scar(master,kind);report={'source':str(src),'sha256':sha(src),'raw':rawstats,'basis_rows':basis.tolist(),'center_after_basis':center.tolist(),'uniform_scale':float(scale),'scar':injury,'bore':bore,'lods':{}}
    raw.hide_render=True;raw.hide_set(True)
    for level,target in zip(['near','middle','far'],CFG['lod_triangles'][kind]):
        obj=clone(master,kind+'_'+level,runtime);simplify(obj,target);report['lods'][level]=stats(obj)
        assert report['lods'][level]['degenerate']==0
        assert report['lods'][level]['welded_boundary_edges']==0 and report['lods'][level]['welded_nonmanifold_edges']==0,(kind,level,report['lods'][level])
        export([obj],out/(kind+'_'+level+'.glb'));obj.hide_render=True;obj.hide_set(True)
    master.hide_render=True;master.hide_set(True)
    return next(o for o in runtime.objects if o.name==kind+'_near'),report

def petal(name,a,mat,c,open_amount=0):
    verts=[];faces=[];rows=32;cols=10
    # A thick, curled papery lobe: closed perimeter and bottom, no alpha overdraw.
    for layer in [0,1]:
        for i in range(rows+1):
            t=i/rows;w=.095*math.sin(math.pi*t)**.7+.004
            radius=.10+.15*math.sin(math.pi*t)+open_amount*t*t
            for j in range(cols+1):
                q=2*j/cols-1;rr=radius+.015*math.cos(q*math.pi)+.006*math.sin(t*31+q*7)
                z=.04+t*.62-.018*q*q+layer*.003
                x=rr*math.cos(a)-q*w*math.sin(a);y=rr*math.sin(a)+q*w*math.cos(a)
                verts.append((x,y,z))
    n=(rows+1)*(cols+1)
    for layer in [0,1]:
        for i in range(rows):
            for j in range(cols):
                x=layer*n+i*(cols+1)+j;f=(x,x+1,x+cols+2,x+cols+1);faces.append(f if layer else tuple(reversed(f)))
    ring=list(range(cols+1))+[i*(cols+1)+cols for i in range(1,rows+1)]+[rows*(cols+1)+j for j in range(cols-1,-1,-1)]+[i*(cols+1) for i in range(rows-1,0,-1)]
    for k,x in enumerate(ring):y=ring[(k+1)%len(ring)];faces.append((x,y,y+n,x+n))
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(name,me);c.objects.link(o);me.materials.append(mat);uv(o)
    for p in me.polygons:p.use_smooth=True
    return o

def lamp(wood,reed,paper,c,core):
    parts=[]
    for x in [-.19,.19]:parts.append(box('Wide ground foot',(x,0,.045),(.12,.42,.09),wood))
    parts.append(box('Heart seat',(0,0,.17),(.32,.31,.075),wood))
    for k in range(6):
        a=k*math.tau/6;points=[]
        for i in range(25):
            t=i/24;r=.13+.075*math.sin(t*math.pi);points.append((r*math.cos(a),r*math.sin(a),.20+t*.69))
        parts.append(tube('Bent timber cage rib',points,[.011]*25,wood[0],10))
    for z,r in [(.24,.154),(.46,.211),(.76,.18),(.89,.13)]:
        for dz in [-.005,.005]:parts.append(tube('Reed bound hoop',[(r*math.cos(j*math.tau/48),r*math.sin(j*math.tau/48),z+dz) for j in range(49)],[.006]*49,reed,8))
    parts.append(box('Crown block',(0,0,.926),(.26,.23,.056),wood))
    parts.append(tube('Reed carry loop',[(-.07,0,.948),(-.07,0,1.01),(0,0,1.035),(.07,0,1.01),(.07,0,.948)],[.010]*5,reed,10))
    housing=join(parts,'Housing',c);heart=clone(core,'Heart',c);heart.location=(0,0,.23);heart.hide_render=False;heart.hide_set(False)
    return [housing,heart]

def lever(wood,iron,c,core):
    parts=[]
    for y in [-.17,.17]:parts.append(box('Sill',(0,y,.045),(.62,.11,.09),wood))
    for x in [-.195,.195]:
        parts.append(box('Cross bearer',(x,0,.11),(.095,.43,.065),wood))
        parts.append(box('Upright',(x,.06,.275),(.065,.07,.30),wood))
        parts.append(beam('Splayed foot brace',(x,-.17,.12),(x,.06,.34),.04,wood))
        # Open metal clamping rings retain the continuous tube bore.
        local_radius=max(math.hypot(v.co.y,v.co.z) for v in core.data.vertices if abs(v.co.x-x)<.012)
        clamp_radius=local_radius+.008
        for dx in [-.014,.014]:
            parts.append(tube('Split resonator clamp',[(x+dx,clamp_radius*math.cos(j*math.tau/40),.40+clamp_radius*math.sin(j*math.tau/40)) for j in range(41)],[.009]*41,iron,10))
        for a in [0,math.pi*.65,math.pi*1.35]:
            parts.append(beam('Clamping seat',(x,local_radius*math.cos(a),.40+local_radius*math.sin(a)),(x,(local_radius+.012)*math.cos(a),.40+(local_radius+.012)*math.sin(a)),.022,iron))
        for z in [.20,.31]:parts.append(pin((x,-.018,z),iron))
    parts.append(box('Lever fulcrum',(0,.07,.54),(.105,.08,.10),iron,.003))
    parts.append(beam('Fulcrum back support',(0,.07,.15),(0,.07,.55),.065,wood))
    # Socket remains the established native signal endpoint (0,.95,0).
    parts.append(beam('Request socket post',(-.27,.13,.12),(-.27,.13,.87),.040,wood))
    parts.append(beam('Request socket head',(-.27,.13,.87),(0,0,.939),.025,iron))
    parts.append(tube('Request ferrule',[(.030*math.cos(j*math.tau/32),.030*math.sin(j*math.tau/32),.939) for j in range(33)],[.008]*33,iron,8))
    housing=join(parts,'Housing',c)
    moving=[beam('Tapping lever',(0,0,0),(0,-.16,.26),.026,iron),box('Hand grip',(0,-.16,.26),(.19,.052,.055),wood),beam('Tapping tongue',(0,-.018,-.01),(0,-.025,-.065),.023,iron)]
    arm=join(moving,'Lever',c);arm.location=(0,0,.54)
    resonator=clone(core,'Resonator',c);resonator.location=(0,0,.40);resonator.hide_render=False;resonator.hide_set(False)
    return [housing,arm,resonator]

def storm_bed(c,stone):
    # Two irregular closed banks leave a real lightning split rather than a bright stripe.
    parts=[]
    for side in [-1,1]:
        verts=[];faces=[];n=32
        for layer in [0,1]:
            for edge in [0,1]:
                for j in range(n):
                    t=j/(n-1);x=(t-.5)*1.75;y=side*((.06+.018*math.sin(t*17)) if edge==0 else (.43+.07*math.sin(t*13)))
                    z=.015 if layer==0 else .07+.045*math.sin(t*8)**2+.015*math.sin(j*2.1+edge)
                    verts.append((x,y,z))
        for layer in [0,1]:
            for j in range(n-1):a=layer*2*n+j;faces.append((a,a+1,a+n+1,a+n))
        for edge in [0,1]:
            for j in range(n-1):a=edge*n+j;faces.append((a,a+1,a+1+2*n,a+2*n))
        for j in [0,n-1]:faces.append((j,j+n,j+3*n,j+2*n))
        me=bpy.data.meshes.new('Lightning bank');me.from_pydata(verts,[],faces);me.update();obj=bpy.data.objects.new('Lightning bank',me);c.objects.link(obj);me.materials.append(stone);uv(obj)
        bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free();parts.append(obj)
    parts.append(box('Supported tube bed',(-.12,0,.09),(.19,.19,.18),stone,.02))
    return join(parts,'stormglass_shell',c)

def render_and_save(out,groups):
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24;scene.cycles.use_denoising=True
    scene.render.threads_mode='FIXED';scene.render.threads=8;scene.render.resolution_x=1100;scene.render.resolution_y=1000;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX'
    review=coll('Review');ground=box('Ground',(0,0,-.06),(200,200,.1),solid('Stage',(.11,.12,.105)));move(ground,review)
    world=bpy.data.worlds.new('Neutral');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[1].default_value=.55;scene.world=world
    for name,at,power,size in [('Key',(-3,-4,6),850,4),('Fill',(4,-2,4),550,4),('Rim',(0,4,6),950,4)]:
        d=bpy.data.lights.new(name,'AREA');d.energy=power;d.size=size;o=bpy.data.objects.new(name,d);review.objects.link(o);o.location=at;aim(o,(0,0,.45))
    cam=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));review.objects.link(cam);cam.data.type='ORTHO';scene.camera=cam
    clay=solid('Inspection clay',(.32,.30,.26))
    for name,items in groups.items():
        for others in groups.values():
            for o in others:o.hide_render=True
        for o in items:o.hide_render=False
        center=Vector((0,0,.45 if name!='stormglass_source' else .20));cam.data.ortho_scale=1.35 if name!='stormglass_source' else 2.15
        for label,at in {'front':(0,-5,.65),'back':(0,5,.65),'side':(5,0,.65),'threequarter':(2,-5,2.8),'top':(0,-.01,6),'underside':(0,-.01,-5)}.items():
            cam.location=at;aim(cam,center);ground.hide_render=label=='underside'
            for mode in ['material','clay']:
                scene.view_layers[0].material_override=clay if mode=='clay' else None;scene.render.filepath=str(out/f'{name}-{mode}-{label}.png');bpy.ops.render.render(write_still=True)
        scene.view_layers[0].material_override=None;ground.hide_render=False;cam.location=(2,-5,2.8);aim(cam,center)
        for peak in [0,1]:
            for m in bpy.data.materials:
                if m.use_nodes and m.node_tree.nodes.get('F1_WORK'):m.node_tree.nodes['F1_WORK'].inputs[1].default_value=peak*1.4
            scene.render.filepath=str(out/f'{name}-emission-{peak}.png');bpy.ops.render.render(write_still=True)
    for m in bpy.data.materials:
        if m.use_nodes and m.node_tree.nodes.get('F1_WORK'):m.node_tree.nodes['F1_WORK'].inputs[1].default_value=0
    for i,(name,items) in enumerate(groups.items()):
        for o in items:o.hide_render=False;o.location.x+=(i-1.5)*1.8
    cam.location=(4,-12,5);aim(cam,(0,0,.4));cam.data.ortho_scale=8;scene.render.resolution_x=1600;scene.render.resolution_y=800
    scene.render.filepath=str(out/'blender-overview.png');bpy.ops.render.render(write_still=True);bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(out/'f1_master.blend'))

def main():
    heart,tube_path,out=map(lambda p:Path(p).resolve(),sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=False);bpy.ops.wm.read_factory_settings(use_empty=True)
    source=coll('Immutable_raw_sources');finished=coll('Finished_organic_masters');runtime=coll('Runtime_candidates');devices=coll('Fitted_mechanisms');hosts=coll('Source_and_aftermath')
    wood=[pbr('f1_wood_face',D4,'d4_wood_face'),pbr('f1_wood_end',D4,'d4_wood_edge')];iron=pbr('f1_iron',D6,'d6_iron');reed=pbr('f1_reed',D4,'d4_woven_reed_face');paper=solid('f1_papery_husk',(.25,.17,.085));stone=solid('f1_scarred_ground',(.18,.17,.135))
    report={'base_commit':CFG['base_commit'],'sources':{},'parts':{},'textures':[]};cores={}
    for kind,src in [('lanternheart',heart),('stormglass',tube_path)]:cores[kind],report['sources'][kind]=organic(src,kind,source,finished,runtime,out)
    groups={'lantern_lamp':lamp(wood,reed,paper,devices,cores['lanternheart']),'stormglass_lever':lever(wood,iron,devices,cores['stormglass'])}
    husks=[]
    for k in range(5):
        o=petal('Husk_'+str(k),k*math.tau/5,paper,hosts,.04);o.location.z=.08;husks.append(o)
    export(husks,out/'lanternheart_shell.glb');h=clone(cores['lanternheart'],'SourceHeart',hosts);h.location.z=.12;h.hide_set(False);groups['lanternheart_source']=husks+[h]
    bed=storm_bed(hosts,stone);export([bed],out/'stormglass_shell.glb');s=clone(cores['stormglass'],'SourceTube',hosts);s.location=(0,0,.28);s.rotation_euler.y=-.7;s.hide_set(False);groups['stormglass_source']=[bed,s]
    for name,items in groups.items():
        for o in items:o.hide_render=False;o.hide_set(False)
        bpy.context.view_layer.update();report['parts'][name]=[stats(o) for o in items];size=CFG['native_bounds_m'][name.replace('_source','')]
        for r in report['parts'][name]:
            lo,hi=r['bounds_blender'];assert r['degenerate']==0,(name,r)
            assert lo[0]>=-size[0]/2-.001 and hi[0]<=size[0]/2+.001 and lo[1]>=-size[2]/2-.001 and hi[1]<=size[2]/2+.001 and lo[2]>=-.001 and hi[2]<=size[1]+.001,(name,r,size)
        export(items,out/(name+'.glb'))
    for img in bpy.data.images:
        if img.source=='FILE':img.pack();report['textures'].append({'name':img.name,'size':list(img.size),'space':img.colorspace_settings.name,'packed':bool(img.packed_file)})
    (out/'asset-audit.json').write_text(json.dumps(report,indent=2)+'\n');render_and_save(out,groups);print('F1_ASSET_BUILD_OK',out)
main()
