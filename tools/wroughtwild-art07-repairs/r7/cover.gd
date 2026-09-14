class_name R7Cover
extends RefCounted
## Bounded source groupings at existing roots. This class never creates anchors.
static var settings:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://r7/settings.json"))
static var meshes:Dictionary={}
static var source_meshes:Dictionary={}
static var materials:Array[ShaderMaterial]=[]
static func enabled()->bool:
    return G1Art.enabled() and not "--r7-before" in OS.get_cmdline_user_args()
static func ground(entry:Dictionary)->ArrayMesh:
    var group:String={"tuft":"ground_tuft","fern":"ground_fern","dead_grass":"ground_dry"}.get(String(entry.kind),"")
    if group.is_empty():return null
    # Reconstruct exactly G1's selected-source envelope. The table width/height
    # is only a cap, and must not silently enlarge its narrower delivered mesh.
    var role:String={"tuft":"grass-meadow","fern":"fern-sparse","dead_grass":"grass-edge"}[String(entry.kind)]
    var base:=source(role);var b:=base.get_aabb()
    var fit:=minf(float(entry.width)/maxf(b.size.x,b.size.z),float(entry.height)/b.size.y)
    var origin:=-Vector3(b.get_center().x,b.position.y,b.get_center().z)*fit
    var box:=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*fit),origin)*b
    return compose("ground/"+str(entry),group,box)
static func habitat(kind:String,variant:int,base:Mesh)->Mesh:
    if not enabled() or base==null:return base
    var group:="shrub"+str(variant%2) if kind=="shrub" else "fern"+str(variant%2) if kind=="fern_bed" else ""
    return base if group.is_empty() else compose("habitat/"+kind+str(variant),group,base.get_aabb())
static func regional(kind:String,base:Mesh)->Mesh:
    if not enabled() or base==null:return base
    var group:="shrub1" if kind=="shrub" else "fern0" if kind=="fern" else ""
    return base if group.is_empty() else compose("regional/"+kind,group,base.get_aabb())
static func source(role:String)->ArrayMesh:
    if source_meshes.has(role):return source_meshes[role]
    var root:Node3D=load("res://b2/assets/"+role+"-lod%d.glb"%int(settings.lod)).instantiate()
    var out:=ArrayMesh.new();AuthoredAssets._collect(root,Transform3D.IDENTITY,out);root.free()
    source_meshes[role]=out
    return out
static func compose(key:String,group:String,envelope:AABB)->ArrayMesh:
    if meshes.has(key):return meshes[key]
    var out:=ArrayMesh.new();var parts:Array=[]
    var margin:float=settings.envelope_inset_fraction
    var available_x:=minf(-envelope.position.x,envelope.end.x)*(1.0-margin)
    var available_z:=minf(-envelope.position.z,envelope.end.z)*(1.0-margin)
    var base_y:=maxf(0.0,envelope.position.y)
    var available_y:=envelope.end.y-base_y
    assert(available_x>0 and available_z>0 and available_y>0,"R7 requires an existing rooted positive envelope")
    for item:Array in settings.groups[group]:
        var role:=String(item[0]);var input:=source(role)
        var yaw:=Basis(Vector3.UP,float(item[3]));var rotated:=Transform3D(yaw,Vector3.ZERO)*input.get_aabb()
        var extent_x:=maxf(absf(rotated.position.x),absf(rotated.end.x))
        var extent_z:=maxf(absf(rotated.position.z),absf(rotated.end.z))
        var gain:=minf(available_x*float(item[1])/extent_x,available_z*float(item[1])/extent_z)
        gain=minf(gain,available_y*float(item[2])/rotated.size.y)
        # Include inherited sway in the clearance bound before fitting.
        var sway:float=settings.wind_bend_per_m*rotated.size.y
        gain=minf(gain,available_x/(extent_x+sway))
        gain=minf(gain,available_z/(extent_z+sway*.35))
        var pose:=Transform3D(yaw.scaled(Vector3.ONE*gain),Vector3(0,base_y-rotated.position.y*gain,0))
        for i in input.get_surface_count():
            var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
            tool.append_from(input,i,pose)
            var mat:=material_for(input.surface_get_material(i),base_y)
            tool.set_material(mat);tool.commit(out)
        parts.append({"role":role,"scale":gain,"yaw":item[3],"root_y":base_y,"source_bounds":str(input.get_aabb())})
    out.set_meta("r7_composition",group);out.set_meta("r7_parts",parts);out.set_meta("r7_envelope",envelope)
    out.set_meta("g1_role",group)
    assert(envelope.grow(.0001).encloses(out.get_aabb()),"R7 composition must remain inside original envelope")
    meshes[key]=out
    return out
static func material_for(old:Material,root_y:float)->ShaderMaterial:
    var mat:=ShaderMaterial.new();mat.shader=load("res://r7/surface.gdshader")
    mat.set_shader_parameter("leaf_normal_up_mix",float(settings.leaf_normal_up_mix))
    mat.set_shader_parameter("leaf_backlight",float(settings.leaf_backlight))
    mat.set_shader_parameter("root_base_y",root_y)
    mat.set_shader_parameter("role",3);mat.set_shader_parameter("altered",false)
    mat.set_shader_parameter("ground_conform",false)
    mat.set_shader_parameter("plant_bend",float(settings.wind_bend_per_m))
    mat.set_shader_parameter("wind_period_s",float(settings.wind_period_s))
    var textured:bool=old is StandardMaterial3D and old.albedo_texture!=null
    mat.set_shader_parameter("textured",textured)
    if textured:
        mat.set_shader_parameter("albedo_map",old.albedo_texture)
        if old.roughness_texture!=null:
            mat.set_shader_parameter("has_orm",true);mat.set_shader_parameter("orm_map",old.roughness_texture)
    var gain:Array=settings.leaf_colour_gain
    mat.set_shader_parameter("leaf_colour_gain",Vector3(gain[0],gain[1],gain[2]))
    materials.append(mat)
    return mat
static func tick(time:float)->void:
    for mat in materials:mat.set_shader_parameter("clock_seconds",time)
