extends Node
func _ready():
    var rows:Dictionary={}
    for kind in ["shrub","fern_bed","deadfall","stump"]:
        rows["habitat/"+kind]=describe(AuthoredAssets.mesh_for(kind))
    for kind in ["shrub","fern","moss","sedge","dry_sedge","scree","deadfall","wildwood_tree","wildwood_sapling","fen_tree","root_arch_a","hollow_trunk","stone_rib","low_outcrop"]:
        rows["regional/"+kind]=describe(StrangeSites._mesh_for(kind))
    for biome in GroundCover.COVER:
        for entry in GroundCover.COVER[biome]:
            var mesh:=G1Environment.cover_mesh(entry)
            if mesh!=null:rows["ground/"+biome+"/"+String(entry.kind)]=describe(mesh)
    for role in ["sapling-shrub","fern-sparse","fern-lush","grass-meadow","grass-edge","bramble","climber","moss","lichen","leaf-litter","needle-litter"]:
        var root:Node3D=load("res://b2/assets/"+role+"-lod2.glb").instantiate()
        var mesh:=ArrayMesh.new();AuthoredAssets._collect(root,Transform3D.IDENTITY,mesh);root.free()
        rows["b2/"+role]=describe(mesh)
    var out:="res://../evidence/r7-source-probe.json"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
    FileAccess.open(out,FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
    print("R7_SOURCE_PROBE ",JSON.stringify(rows))
    get_tree().quit()
func describe(mesh:Mesh)->Dictionary:
    if mesh==null:return {"missing":true}
    var box:=mesh.get_aabb();var triangles:=0;var materials:Array=[]
    for s in mesh.get_surface_count():
        var a:=mesh.surface_get_arrays(s);triangles+=(a[Mesh.ARRAY_INDEX].size() if a[Mesh.ARRAY_INDEX]!=null else a[Mesh.ARRAY_VERTEX].size())/3
        var m:=mesh.surface_get_material(s)
        materials.append({"type":m.get_class() if m!=null else "null","texture":m.albedo_texture.resource_path if m is StandardMaterial3D and m.albedo_texture!=null else ""})
    return {"min":[box.position.x,box.position.y,box.position.z],"size":[box.size.x,box.size.y,box.size.z],"triangles":triangles,"materials":materials}
