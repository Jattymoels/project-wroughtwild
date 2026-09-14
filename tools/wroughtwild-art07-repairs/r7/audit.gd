class_name R7Audit
extends RefCounted
static func pose(t:Transform3D)->Array:
    return [t.basis.x.x,t.basis.x.y,t.basis.x.z,t.basis.y.x,t.basis.y.y,t.basis.y.z,t.basis.z.x,t.basis.z.y,t.basis.z.z,t.origin.x,t.origin.y,t.origin.z]
static func snapshot(world:Node3D,terrain:Terrain)->Dictionary:
    var rows:Dictionary={};var counts:Dictionary={};var composed:=0;var envelope_failures:Array=[]
    for node in world.find_children("*","MultiMeshInstance3D",true,false):
        if not node.has_meta("world_transforms"):continue
        var kind:=String(node.get_meta("mesh_kind",node.name));var transforms:Array=node.get_meta("world_transforms")
        var name:=String(world.get_path_to(node));var poses:Array=[]
        for t:Transform3D in transforms:poses.append(pose(t))
        var mesh:Mesh=node.multimesh.mesh;var bounds:=mesh.get_aabb()
        var root_samples:Array=[]
        var row:={"kind":kind,"count":transforms.size(),"poses":poses,"pose_sha256":var_to_bytes(poses).hex_encode().sha256_text(),"mesh_bounds":str(bounds),"visibility_end":node.visibility_range_end,"visibility_margin":node.visibility_range_end_margin,"hidden_by_building":node.get_meta("hidden_by_building",[])}
        if mesh.has_meta("r7_composition"):
            row.composition=mesh.get_meta("r7_composition");row.parts=mesh.get_meta("r7_parts")
            var envelope:AABB=mesh.get_meta("r7_envelope")
            row.original_envelope=str(envelope);composed+=transforms.size()
            for t:Transform3D in transforms:
                var y:=terrain.rendered_height(t.origin.x,t.origin.z,t.origin.y,2.0)
                if not is_finite(y):continue
                var root_y:float=(t*Vector3(0,float(row.parts[0].root_y),0)).y
                root_samples.append({"origin":str(t.origin),"root_y":root_y,"terrain_y":y,"signed_gap_m":root_y-y})
            row.root_support=root_samples
            if not envelope.grow(.0001).encloses(bounds):envelope_failures.append(name)
            if node.material_override!=null:envelope_failures.append(name+" overrides R7 surfaces")
        rows[name]=row;counts[kind]=int(counts.get(kind,0))+transforms.size()
    var collision:Dictionary={}
    for node in world.find_children("*","CollisionShape3D",true,false):
        var shape:Shape3D=node.shape
        if shape==null:continue
        var row:={"pose":pose(node.global_transform),"disabled":node.disabled,"type":shape.get_class()}
        if shape is BoxShape3D:row.size=str(shape.size)
        if shape is CapsuleShape3D:row.size=[shape.radius,shape.height]
        if shape is ConcavePolygonShape3D:row.faces_sha256=var_to_bytes(shape.get_faces()).hex_encode().sha256_text()
        collision[String(world.get_path_to(node))]=row
    return {"anchors":rows,"counts":counts,"composed_instances":composed,"envelope_failures":envelope_failures,"geography_sha256":JSON.stringify(terrain.map).sha256_text(),"collision":collision,"scope":"Exact retained MultiMesh identities/counts/poses and physical shape state, including all regional anchors and current streamed cover. Bounds are conservative; root contact is checked separately."}
