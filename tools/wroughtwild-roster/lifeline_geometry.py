"""Physical ART-06C geometry. Kept separate from the unchanged ART-06B recipe."""
import numpy as np
import bmesh
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

# One 512-pixel strip preserves every original albedo/ORM pixel above it.
# The strip gives the repaired muzzle unique UVs without stretching old islands.
FACE_ATLAS_ROWS = 512
_face_source = None


def smooth(value):
    x = np.clip(value,0,1)
    return x*x*(3-2*x)


def network_travel(a,b,sides,join_radius):
    """Continuous distance from each connected network's highest living root."""
    import heapq
    points=np.concatenate([a,b]);side=np.concatenate([sides,sides]);n=len(a)
    distances=np.linalg.norm(points[:,None,:]-points[None,:,:],axis=2)
    joined=(distances<=join_radius)&(side[:,None]==side[None,:])
    graph=[[(int(j),float(distances[i,j])) for j in np.flatnonzero(joined[i]) if j!=i] for i in range(len(points))]
    for i in range(n):
        length=float(np.linalg.norm(a[i]-b[i]));graph[i].append((i+n,length));graph[i+n].append((i,length))
    unseen=set(range(len(points)));travel=np.zeros(len(points));components=[]
    while unseen:
        root=max(unseen,key=lambda i:(points[i,2],-i));queue=[(0.,root)];cost={root:0.}
        while queue:
            d,i=heapq.heappop(queue)
            if d>cost[i]: continue
            for j,w in graph[i]:
                if d+w<cost.get(j,float('inf')):
                    cost[j]=d+w;heapq.heappush(queue,(d+w,j))
        for i,d in cost.items(): travel[i]=d
        unseen.difference_update(cost);components.append(dict(nodes=len(cost),length=max(cost.values())))
    # A common distance scale keeps speed consistent across separate exposed roots.
    travel=travel/max(float(travel.max()),1e-8)*.9
    return travel[:n],travel[n:],components


def carve(points,faces,a,b,width,sides,config,routes):
    ab = b-a
    length2 = np.einsum('ij,ij->i',ab,ab)
    delta = np.zeros_like(points)
    for offset in range(0,len(points),2048):
        p = points[offset:offset+2048]
        ap = p[:,None,:]-a[None,:,:]
        t = np.clip(np.einsum('ijk,jk->ij',ap,ab)/length2,0,1)
        distance = np.linalg.norm(ap-t[:,:,None]*ab,axis=2)
        field = 1-smooth(distance/(config['channel_half_width_units']*width))
        # A consistent flank direction avoids collapse from noisy source normals.
        # Both sides are independently authored; overlapping fields cancel smoothly.
        positive = field[:,sides>0].max(1)
        negative = field[:,sides<0].max(1)
        delta[offset:offset+len(p),0] = config['recess_units']*(negative-positive)
    before = np.cross(points[faces[:,1]]-points[faces[:,0]],points[faces[:,2]]-points[faces[:,0]])
    assert (np.linalg.norm(before,axis=1)>2e-12).all(), ('Pre-incision degenerate faces',int((np.linalg.norm(before,axis=1)<=2e-12).sum()))
    factor = np.ones(len(points),np.float32)
    protected = set()
    for attempt in range(30):
        new = (points+delta*factor[:,None]).astype(np.float32)
        after = np.cross(new[faces[:,1]]-new[faces[:,0]],new[faces[:,2]]-new[faces[:,0]])
        invalid = np.flatnonzero(np.einsum('ij,ij->i',before,after)<=0)
        if not len(invalid): break
        affected = np.unique(faces[invalid])
        protected.update(affected.tolist())
        factor[affected] *= .5 if attempt<22 else 0
    assert not len(invalid), 'Channel introduced collapsed or reversed faces'
    assert np.isfinite(new).all()
    new_bvh = BVHTree.FromPolygons(new.tolist(),faces.tolist(),all_triangles=True)
    old_bvh = BVHTree.FromPolygons(points.tolist(),faces.tolist(),all_triangles=True)
    samples=[]
    for route in routes:
        side = 1 if route['view']=='material-az0' else -1
        depths=[]
        for point in route['points'][2:-2]:
            # Same ray before/after, including any overlying source plate.
            start = Vector(point)+Vector((side*.15,0,0))
            direction = Vector((-side,0,0))
            old,_,_,_ = old_bvh.ray_cast(start,direction,.4)
            hit,_,_,_ = new_bvh.ray_cast(start,direction,.4)
            if old is not None and hit is not None and (old-Vector(point)).length<.015:
                depths.append(float((hit-old).dot(direction)))
        assert len(depths)>=2, ('Insufficient visible incision samples',route['name'])
        samples.append(dict(name=route['name'],count=len(depths),median=float(np.median(depths)),minimum=float(min(depths)),maximum=float(max(depths)),depths=depths))
    result=dict(method='Fixed flank-direction smooth geometric incision; same-ray before/after BVH measurement',
                protected_vertices=len(protected),routes=samples,
                median_depth=float(np.median([d for s in samples for d in s['depths']])),
                zero_or_reversed_faces=0)
    print('LIFELINE_DEPTH',result['median_depth'],'protected',len(protected),flush=True)
    assert result['median_depth'] >= config['minimum_median_depth_units'], result
    assert all(s['median']>=config['minimum_route_depth_units'] for s in samples), result
    return new,result


def repair_face(host,config):
    global _face_source
    mesh=host.data
    p=np.array([v.co[:] for v in mesh.vertices])
    # Source-specific muzzle envelope measured in the retained front/side probes.
    # Only the projecting coarse whiskers outside the blunt muzzle are trimmed.
    radius=config['muzzle_half_width']+np.maximum(0,p[:,1]+.99)*config['muzzle_flare']
    remove=(p[:,1]<config['whisker_back_limit'])&(p[:,2]<.765)&(p[:,2]>.48)&(np.abs(p[:,0])>radius)
    source_faces=np.array([f.vertices[:] for f in mesh.polygons],np.int32)
    source_uv=np.array([[mesh.uv_layers.active.data[i].uv[:] for i in f.loop_indices] for f in mesh.polygons])
    clean=~remove[source_faces].any(1)
    _face_source=(p,source_faces[clean],source_uv[clean],BVHTree.FromPolygons(p.tolist(),source_faces[clean].tolist(),all_triangles=True))
    before=len(mesh.polygons)
    bm=bmesh.new();bm.from_mesh(mesh)
    # Join coincident UV-border positions; UVs remain per-loop, not per-vertex.
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
    old_boundary={e for e in bm.edges if e.is_boundary}
    victims=[v for v in bm.verts if v.co.y<config['whisker_back_limit'] and .48<v.co.z<.765 and abs(v.co.x)>config['muzzle_half_width']+max(0,v.co.y+.99)*config['muzzle_flare']]
    assert victims and all(v.co.y<-.8 for v in victims)
    removed=len(victims)
    bmesh.ops.delete(bm,geom=victims,context='VERTS')
    fresh=[e for e in bm.edges if e.is_boundary and e not in old_boundary]
    filled=bmesh.ops.holes_fill(bm,edges=fresh,sides=0)['faces'] if fresh else []
    if filled: bmesh.ops.triangulate(bm,faces=filled)
    # Cropping a curved strand can leave a detached tip beyond its root. Remove
    # only small detached components wholly inside the measured face work region.
    visited=set();islands=[]
    for seed in bm.verts:
        if seed in visited: continue
        stack=[seed];visited.add(seed);component=[]
        while stack:
            v=stack.pop();component.append(v)
            for e in v.link_edges:
                other=e.other_vert(v)
                if other not in visited: visited.add(other);stack.append(other)
        if len(component)<300 and all(v.co.y<-.79 and .47<v.co.z<.77 for v in component): islands.extend(component)
    if islands: bmesh.ops.delete(bm,geom=islands,context='VERTS')
    soften=[v for v in bm.verts if v.co.y<-.81 and .58<v.co.z<.765 and abs(v.co.x)>.043]
    for _ in range(config['muzzle_smooth_iterations']):
        bmesh.ops.smooth_vert(bm,verts=soften,factor=.45,use_axis_x=True,use_axis_y=True,use_axis_z=True)
    face_edges=[e for e in bm.edges if all(v.co.y<-.79 and .47<v.co.z<.77 for v in e.verts)]
    bmesh.ops.dissolve_degenerate(bm,edges=face_edges,dist=.000005)
    bmesh.ops.triangulate(bm,faces=[f for f in bm.faces if len(f.verts)>3])
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(mesh);bm.free();mesh.update()
    # Unwrap the whole repaired region into its own strip. A front projection
    # overlaps upper/lower muzzle folds and is not an acceptable texture bake.
    bpy.context.view_layer.objects.active=host
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_mode(type='FACE');bpy.ops.mesh.select_all(action='DESELECT');bpy.ops.object.mode_set(mode='OBJECT')
    repaired=[]
    for face in mesh.polygons:
        centre=face.center
        face.select=centre.y<-.78 and .54<centre.z<.79
        if face.select: repaired.append(face.index);face.use_smooth=True
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.uv.smart_project(angle_limit=1.15,island_margin=.035)
    bpy.ops.object.mode_set(mode='OBJECT')
    selected=set(repaired)
    for face in mesh.polygons:
        for i in face.loop_indices:
            point=mesh.uv_layers.active.data[i].uv
            point.y=.02+.16*point.y if face.index in selected else .2+.8*point.y
    repaired_faces=len(repaired)
    return {'status':'coarse projecting whiskers removed at measured muzzle envelope',
            'removed_vertices':removed,'before_triangles':before,'after_triangles':len(mesh.polygons),
            'new_boundary_edges_filled':len(fresh),'capped_loops':len(filled),'detached_tip_vertices_removed':len(islands),
            'repaired_uv_faces':repaired_faces,'atlas_patch_rows':FACE_ATLAS_ROWS,
            'texture_transfer':'Unique muzzle strip; nearest clean original surface colour; original atlas pixels retained above it.'}


def face_atlas(output,positions,valid,width,height,materials):
    """Bake the repaired muzzle from clean source colour into its unique UV strip."""
    p,faces,uv,bvh=_face_source
    rows=FACE_ATLAS_ROWS
    count=width*rows
    indices=np.flatnonzero(valid[:count])
    projected=[];tri=[]
    for i in indices:
        hit,normal,face,distance=bvh.find_nearest(Vector(positions[i]))
        assert hit is not None
        projected.append(hit);tri.append(face)
    projected=np.array(projected);tri=np.array(tri)
    triangle=p[faces[tri]]
    v0=triangle[:,1]-triangle[:,0];v1=triangle[:,2]-triangle[:,0];v2=projected-triangle[:,0]
    dot=lambda a,b:np.einsum('ij,ij->i',a,b)
    d00,d01,d11,d20,d21=dot(v0,v0),dot(v0,v1),dot(v1,v1),dot(v2,v0),dot(v2,v1)
    denominator=d00*d11-d01*d01
    u=(d11*d20-d01*d21)/denominator;v=(d00*d21-d01*d20)/denominator
    coords=uv[tri,0]*(1-u-v)[:,None]+uv[tri,1]*u[:,None]+uv[tri,2]*v[:,None]
    original=materials[0]
    base_node=original.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].links[0].from_node
    old_base=base_node.image
    old_orm=next(n.image for n in original.node_tree.nodes if n.type=='TEX_IMAGE' and n.image!=old_base)
    for filename,old_image,is_colour in [('base.png',old_base,True),('orm.png',old_orm,False)]:
        (output/('source-'+filename)).write_bytes((output/filename).read_bytes())
        source=bpy.data.images.load(str(output/('source-'+filename)),check_existing=False)
        if not is_colour: source.colorspace_settings.name='Non-Color'
        assert list(source.size)==[width,width]
        raw=np.array(source.pixels[:],np.float32).reshape(width,width,4)
        atlas=np.ones((height,width,4),np.float32);atlas[rows:]=raw
        x=np.clip(coords[:,0]*width-.5,0,width-1);y=np.clip(coords[:,1]*width-.5,0,width-1)
        x0=x.astype(int);y0=y.astype(int);x1=np.minimum(x0+1,width-1);y1=np.minimum(y0+1,width-1)
        tx=(x-x0)[:,None];ty=(y-y0)[:,None]
        sampled=(raw[y0,x0]*(1-tx)+raw[y0,x1]*tx)*(1-ty)+(raw[y1,x0]*(1-tx)+raw[y1,x1]*tx)*ty
        atlas.reshape(-1,4)[indices]=sampled
        # Dilate the patch's border for mip filtering; no changes to original rows.
        patch=atlas[:rows];coverage=valid[:count].reshape(rows,width).copy()
        for _ in range(8):
            for axis,shift in [(0,1),(0,-1),(1,1),(1,-1)]:
                neighbor=np.roll(coverage,shift,axis=axis);take=(~coverage)&neighbor
                patch[take]=np.roll(patch,shift,axis=axis)[take];coverage|=take
        image=bpy.data.images.new('Repaired '+filename,width=width,height=height,alpha=True)
        if not is_colour: image.colorspace_settings.name='Non-Color'
        image.pixels.foreach_set(atlas.ravel());image.update();image.filepath_raw=str(output/filename);image.file_format='PNG';image.save();image.pack()
        for material in materials:
            for node in material.node_tree.nodes:
                if node.type=='TEX_IMAGE' and node.image==(old_base if is_colour else old_orm): node.image=image
        # Float-space equality confirms that no source region was resampled.
        assert np.array_equal(atlas[rows:],raw)
    return {'muzzle_texels':len(indices),'original_rows_preserved':width,'dimensions':[width,height]}


def finish_face(host,config):
    """Small fitted non-emissive eyes and tapered whiskers; later head attachments."""
    import hashlib
    import math
    materials={}
    for name,colour,roughness in [('Small dark eyes',(.008,.005,.003,1),.30),('Fine whiskers',(.105,.071,.045,1),.65)]:
        material=bpy.data.materials.new(name);material.use_nodes=True
        shader=material.node_tree.nodes.get('Principled BSDF')
        shader.inputs['Base Color'].default_value=colour;shader.inputs['Roughness'].default_value=roughness
        materials[name]=material
    objects=[]
    def ellipsoid(name,at,scale,material,normal=None):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=20,location=at)
        obj=bpy.context.object;obj.name=name;obj.scale=scale
        if normal is not None: obj.rotation_euler=Vector(normal).to_track_quat('Z','Y').to_euler()
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        obj.data.materials.append(material)
        for face in obj.data.polygons: face.use_smooth=True
        mod=obj.modifiers.new('Explicit attachment triangles','TRIANGULATE')
        bpy.ops.object.modifier_apply(modifier=mod.name)
        obj['attachment']='head';objects.append(obj)
        return obj
    # Ray-probed retained sockets; the lens is embedded, with only a small cap visible.
    sockets=[((-.12681,-.81058,.81457),(-.60,-.79,.10)),((.109,-.825,.8166),(.76,-.65,.04))]
    for i,(point,normal) in enumerate(sockets):
        centre=Vector(point)-Vector(normal)*.003
        ellipsoid('Porcupine eye '+str(i),centre,(.011,.009,.006),materials['Small dark eyes'],normal)
    host_points=[v.co[:] for v in host.data.vertices]
    host_faces=[f.vertices[:] for f in host.data.polygons]
    host_bvh=BVHTree.FromPolygons(host_points,host_faces,all_triangles=True)
    anchors=[]
    for side in [-1,1]:
        for i in range(5):
            probe=Vector((side*(.071+.003*i),-1.2,.701-.009*i))
            hit,normal,_,_=host_bvh.ray_cast(probe,Vector((0,1,0)),.5)
            assert hit is not None,'Whisker root misses repaired muzzle'
            root=hit-normal*.0003
            anchors.append(list(root))
            tip=root+Vector((side*(.105+.012*(i%2)),.022+.014*i,.025-.015*i))
            middle=(root+tip)/2+Vector((side*.006,-.018,.012))
            curve=bpy.data.curves.new('Fine tapered vibrissa','CURVE');curve.dimensions='3D';curve.resolution_u=2
            curve.bevel_depth=config['whisker_root_radius'];curve.bevel_resolution=1;curve.use_fill_caps=True
            spline=curve.splines.new('POLY');spline.points.add(16)
            for j,pt in enumerate(spline.points):
                t=j/16;v=(1-t)**2*root+2*(1-t)*t*middle+t*t*tip
                pt.co=(*v,1);pt.radius=max(.08,(1-t)**.85)
            obj=bpy.data.objects.new('Porcupine fine whisker '+str(side)+' '+str(i),curve)
            bpy.context.collection.objects.link(obj);bpy.context.view_layer.objects.active=obj
            obj.select_set(True);bpy.ops.object.convert(target='MESH')
            obj=bpy.context.object;obj.data.materials.append(materials['Fine whiskers']);obj['attachment']='head'
            mod=obj.modifiers.new('Explicit attachment triangles','TRIANGULATE');bpy.ops.object.modifier_apply(modifier=mod.name)
            for face in obj.data.polygons: face.use_smooth=True
            objects.append(obj);obj.select_set(False)
    rows=[]
    for obj in objects:
        p=np.array([v.co[:] for v in obj.data.vertices],np.float32)
        f=np.array([v.vertices[:] for v in obj.data.polygons],np.int32)
        area=np.linalg.norm(np.cross(p[f[:,1]]-p[f[:,0]],p[f[:,2]]-p[f[:,0]]),axis=1)/2
        assert np.isfinite(p).all() and (area>1e-12).all()
        rows.append(dict(name=obj.name,triangles=len(f),geometry_sha256=hashlib.sha256(p.tobytes()+f.tobytes()).hexdigest(),attachment='head',emissive=False))
    for anchor in anchors:
        hit,_,_,distance=host_bvh.find_nearest(Vector(anchor))
        assert distance<.001,'Detached fine whisker root'
    return objects,rows
