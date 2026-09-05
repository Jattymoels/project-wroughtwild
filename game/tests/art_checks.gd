extends SceneTree
## Codex regression checks for prop surface orientation and opt-in art.
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func _initialize() -> void:
	for seed_value in [1, 3, 7, 29]:
		var mesh := PropMesh.build_boulder(seed_value)
		var arrays := mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var outward := true
		for i in vertices.size():
			outward = outward and normals[i].dot(vertices[i] - Vector3(0, 0.45, 0)) > 0.0
		check(outward, "boulder normals point out of the rock (seed %d)" % seed_value)
	# The trunk's first 72 vertices form its two hexagonal bands.
	var tree := PropMesh.build_tree(7).surface_get_arrays(0)
	var tv: PackedVector3Array = tree[Mesh.ARRAY_VERTEX]
	var tn: PackedVector3Array = tree[Mesh.ARRAY_NORMAL]
	var trunk_outward := true
	for i in 36:
		if is_zero_approx(tv[i].y):
			trunk_outward = trunk_outward and tn[i].dot(Vector3(tv[i].x, 0, tv[i].z)) > 0.0
	check(trunk_outward, "trunk base faces outward")
	var profile: Resource = preload("res://art/frontier_look.tres")
	var terrain := Terrain.new()
	check(terrain.frontier_look == null, "bare terrain fixture stays neutral; the sandpit selects its look")
	terrain.free()
	var broadleaf: Dictionary = GroundCover.COVER["meadow"][0]
	var hills: Dictionary = GroundCover.COVER["rocky_hills"][0]
	check(profile.cover_mesh(broadleaf) != profile.cover_mesh(hills), "shared plant kinds retain each biome's palette")
	check(profile.cover_mesh(broadleaf) == profile.cover_mesh(broadleaf), "plant meshes are reused")
	var rebuilt: Resource = load("res://art/frontier_look.tres").duplicate()
	for point in [Vector2i(0, 0), Vector2i(16, 16), Vector2i(32, 15)]:
		check(is_equal_approx(profile.cover_density(point.x, point.y), rebuilt.cover_density(point.x, point.y)),
			"cover placement is repeatable across resource instances")
	print("Codex art: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
