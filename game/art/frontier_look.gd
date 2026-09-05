extends Resource
## Codex aesthetic experiment, 5 Sep 2026. Presentation only; opt in with
## --frontier-look. Values and their player-facing purposes are in the .tres.

@export var top_colours: Dictionary = {}
@export var side_colours: Dictionary = {}
@export var patch_metres := 12.0
@export var detail_metres := 0.8
@export var colour_variation := 0.28
@export var grass_edge_depth := 0.18
@export var cover_patch_metres := 9.0
@export var cover_sparse_multiplier := 0.08
@export var cover_dense_multiplier := 1.7
@export var blade_count := 5
@export var blade_width_fraction := 0.065
@export var blade_lean_fraction := 0.28
@export var cover_scale := 1.2
@export var soft_terrain := false
@export var turf_slope_start := 0.25
@export var turf_slope_end := 0.8
@export var seam_steps := 24
@export var seam_half_width := 0.24
@export var seam_surface_lift := 0.018
@export var cover_tint := Color.WHITE
@export var linear_vertex_colours := false
@export var detail_distance := 0.0
@export var tree_distance := 0.0
@export var cover_distance := 0.0
@export var surface_contrast := 0.0
@export var strata_metres := 0.32
@export var grain_metres := 0.065
@export var scree_density := 0.0
@export var scree_width := 0.34
@export var scree_height := 0.1
@export var design_purpose: Dictionary = {}

var _noise: FastNoiseLite
var _meshes: Dictionary = {}
var _cover_material: ShaderMaterial
var _scree_material: StandardMaterial3D

func scree_entry() -> Dictionary:
	return {"kind":"scree", "on":["rock","stone","dirt","grass","forest_floor","ash"],
		"density":scree_density,"height":scree_height,"width":scree_width,
		"colour":Color(0.39,0.39,0.36),"dark":Color(0.26,0.27,0.25)}

func scree_material() -> StandardMaterial3D:
	if _scree_material == null:
		_scree_material = StandardMaterial3D.new()
		_scree_material.vertex_color_use_as_albedo = true
		_scree_material.vertex_color_is_srgb = true
		_scree_material.roughness = 1.0
	return _scree_material

func terrain_material(kind: String, cell: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://art/frontier_terrain.gdshader")
	material.set_shader_parameter("top_colour", top_colours.get(kind, Color("74747A")))
	material.set_shader_parameter("side_colour", side_colours.get(kind, top_colours.get(kind, Color("565860"))))
	material.set_shader_parameter("patch_metres", patch_metres)
	material.set_shader_parameter("detail_metres", detail_metres)
	material.set_shader_parameter("colour_variation", colour_variation)
	material.set_shader_parameter("grass_edge_depth", grass_edge_depth)
	material.set_shader_parameter("cell_metres", cell)
	material.set_shader_parameter("grassy", kind in ["grass", "forest_floor", "marsh"])
	material.set_shader_parameter("soft_terrain", soft_terrain)
	material.set_shader_parameter("turf_slope_start", turf_slope_start)
	material.set_shader_parameter("turf_slope_end", turf_slope_end)
	material.set_shader_parameter("surface_contrast", surface_contrast)
	material.set_shader_parameter("strata_metres", strata_metres)
	material.set_shader_parameter("grain_metres", grain_metres)
	material.set_shader_parameter("stony", kind in ["rock", "stone", "bedrock"])
	return material

func cover_density(x: int, z: int) -> float:
	if _noise == null:
		_noise = FastNoiseLite.new()
		_noise.seed = 713
		_noise.frequency = 1.0 / cover_patch_metres
	var patch := smoothstep(-0.25, 0.25, _noise.get_noise_2d(x, z))
	return lerpf(cover_sparse_multiplier, cover_dense_multiplier, patch)

func cover_mesh(entry: Dictionary) -> ArrayMesh:
	# Include the palette: meadow and hills share a kind but not a colour.
	var key := str(entry)
	if _meshes.has(key):
		return _meshes[key]
	if entry.kind == "scree":
		var chips := SurfaceTool.new()
		chips.begin(Mesh.PRIMITIVE_TRIANGLES)
		var w := float(entry.width)*0.5
		var h := float(entry.height)
		var rim := [Vector3(-w,0,0),Vector3(0,0,-w*0.75),Vector3(w,0,0),Vector3(0,0,w)]
		for i in 4:
			for tip in [Vector3(w*0.12,h,0),Vector3(0,-h*0.4,0)]:
				var a: Vector3 = rim[i]
				var b: Vector3 = rim[(i+1)%4]
				var n: Vector3 = (tip-a).cross(b-a)
				if n.dot((a+b+tip)/3.0)<0.0:
					var swap := a
					a = b
					b = swap
				chips.set_normal((tip-a).cross(b-a).normalized())
				chips.set_color(entry.colour if tip.y>0.0 else entry.dark)
				for vertex in [a,b,tip]:
					chips.add_vertex(vertex)
		var mesh := chips.commit()
		mesh.surface_set_material(0,scree_material())
		_meshes[key] = mesh
		return mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var height := float(entry["height"])
	var width := float(entry["width"])
	var bottom: Color = entry["dark"] * cover_tint
	var top: Color = entry["colour"] * cover_tint
	if linear_vertex_colours:
		bottom = bottom.srgb_to_linear()
		top = top.srgb_to_linear()
	for i in blade_count:
		var angle := TAU * float(i) / float(blade_count)
		var across := Vector3(cos(angle), 0, sin(angle)) * width * blade_width_fraction
		var lean := Vector3(-sin(angle), 0, cos(angle)) * width * blade_lean_fraction
		var root := lean * (0.15 if i % 2 == 0 else -0.15)
		var tip := root + lean + Vector3.UP * height * (0.6 + 0.4 * float(i + 1) / float(blade_count))
		var knee := root.lerp(tip, 0.5)
		for vertex in [root - across, root + across, knee + across * 0.5,
			root - across, knee + across * 0.5, knee - across * 0.5,
			knee - across * 0.5, knee + across * 0.5, tip]:
			st.set_normal(Vector3.UP)
			st.set_color(bottom.lerp(top, clampf(vertex.y / height, 0, 1)))
			st.add_vertex(vertex)
	var mesh := st.commit()
	mesh.surface_set_material(0, cover_material())
	_meshes[key] = mesh
	return mesh

func cover_material() -> ShaderMaterial:
	if _cover_material == null:
		_cover_material = ShaderMaterial.new()
		_cover_material.shader = preload("res://art/frontier_cover.gdshader")
	return _cover_material
