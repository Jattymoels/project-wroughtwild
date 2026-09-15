extends Node
var failures := 0
var checks := 0
var rows: Array = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL RF02 ASSET: ", label)
func _ready() -> void:
	var look = preload("res://rf02/ground.tres")
	var map := {"width":3, "height":1, "cell_size":1.0, "biome_defs":[{"id":"meadow"},{"id":"forest"},{"id":"fen"}], "biomes":PackedInt32Array([0,1,2])}
	for profile in ["frontier_v6","living_frontier_wave1","living_frontier_wave3"]:
		check(look.mask_for(map,profile)!=null, "eligible geography selects materials: "+profile)
	for profile in ["legacy_v1","frontier_v2","frontier_v3","frontier_v4","frontier_v5"]:
		check(look.mask_for(map,profile)==null, "earlier geography retains materials: "+profile)
	var mask: ImageTexture = look.mask_for(map,"frontier_v6")
	var im := mask.get_image()
	check(im.get_pixel(0,0).r==1 and im.get_pixel(0,0).g==0 and im.get_pixel(1,0).g==1 and im.get_pixel(2,0).r==0, "meadow/woodland are distinct and other biomes are excluded")
	for kind in ["grass","forest_floor","dirt","rock","marsh","ash","bedrock"]:
		var mat: ShaderMaterial = preload("res://art/wildland_look.tres").terrain_material(kind,1)
		look.bind(mat,kind,mask,map)
		check(mat.has_meta("rf02_ground")== (kind in ["grass","forest_floor","dirt"]), "surface binding: "+kind)
	for texture in [look.meadow_albedo,look.meadow_detail,look.woodland_albedo,look.woodland_detail]:
		var data: Image = texture.get_image()
		check(data!=null and data.get_width()==1024 and data.get_height()==1024 and data.has_mipmaps(), "1024 map has mip chain: "+texture.resource_path)
	var settings = preload("res://rf01/low_cover.tres")
	for role in ["grass-meadow","grass-edge"]:
		var mesh: ArrayMesh = settings.mesh_for(role)
		var bounds: AABB = mesh.get_meta("rf01_clearance")
		var vertices_ok := true
		var max_radius := 0.0
		var peak: float = settings.grass_height_m * (0.66 if role=="grass-edge" else 1.0)
		var sway: float = peak * float(R7Cover.settings.wind_bend_per_m)
		var support_radius: float = settings.grass_width_m*.5 + settings.fern_height_m*float(R7Cover.settings.wind_bend_per_m)*1.06
		var triangles := 0
		for surface in mesh.get_surface_count():
			var arrays := mesh.surface_get_arrays(surface)
			triangles += (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size()/3 if arrays[Mesh.ARRAY_INDEX]!=null else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()/3
			for v: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
				var radial := Vector2(v.x,v.z).length()
				max_radius = maxf(max_radius,radial)
				vertices_ok = vertices_ok and v.is_finite() and radial<=settings.grass_width_m*.5+.0001 and v.y>=-.0001 and v.y<=peak+.0001 and bounds.grow(.0001).has_point(v)
			check(mesh.surface_get_material(surface).has_meta("rf02_grass"), "original grass uses pause-aware production material: "+role)
		check(vertices_ok, "all vertices keep the RF01 rooted radius and height: "+role)
		check(max_radius+sway*sqrt(1+.35*.35)<=support_radius and support_radius<.495, "analytic maximum wind remains inside RF01 support footprint: "+role)
		check(mesh.get_surface_count()==1 and triangles>0, "one opaque material surface: "+role)
		rows.append({"role":role,"triangles":triangles,"radius_m":max_radius,"height_m":peak,"sway_m":sway,"support_radius_m":support_radius})
	var fern: ArrayMesh = settings.mesh_for("fern-sparse")
	check(not fern.surface_get_material(0).has_meta("rf02_grass"), "adopted fern retains R7 materials")
	var output := OS.get_environment("WROUGHTWILD_RF02_OUTPUT")
	FileAccess.open(output.path_join("assets-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"meshes":rows},"\t"))
	print("RF02_ASSETS checks=",checks," failures=",failures)
	get_tree().quit(0 if failures==0 else 1)
