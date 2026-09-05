extends Node3D
## Native palette blending must not change collision, digging or chunk joins.
var checks := 0
var failures := 0
var sim: WroughtwildSim
var palette: Dictionary

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)

func _ready() -> void:
	sim = load("res://scripts/sim.gd").shared()
	palette = preload("res://art/weathered_look.tres").top_colours
	var originals := _review(PackedInt32Array())
	var map: Dictionary = sim.world_map(1)
	var y: int = map.heights[159*int(map.width)+159]-1
	_review(PackedInt32Array([159,y,159]))
	var restored := _review(PackedInt32Array())
	check(originals==restored,"restoration exactly reproduces all blended colours")
	var look := preload("res://art/weathered_look.tres")
	var stone_meshes: Array = []
	for variant in 3:
		var mesh: ArrayMesh = look.cover_mesh(look.scree_entry(variant))
		var arrays := mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var outward := true
		for i in range(0,vertices.size(),3):
			outward = outward and (vertices[i+2]-vertices[i]).cross(vertices[i+1]-vertices[i]).dot(normals[i])>0.0
		check(outward,"stone variant has outward nondegenerate faces")
		check(mesh.get_aabb().size.y<mesh.get_aabb().size.x*0.4,"stone is a low slab, not a pyramid")
		stone_meshes.append(vertices)
	check(stone_meshes[0]!=stone_meshes[1] and stone_meshes[1]!=stone_meshes[2],"three distinct deterministic stone outlines")
	print("CODEX_MATERIAL_TRANSITIONS %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func _review(removed: PackedInt32Array) -> Dictionary:
	var colours_at: Dictionary = {}
	var output: Dictionary = {}
	var joins := 0
	var mixed := 0
	var continuous := true
	for x in [144,160]:
		for z in [144,160]:
			var bare := sim.world_mesh_chunk(1,16,x,z,removed,true)
			var blended := sim.world_mesh_chunk(1,16,x,z,removed,true,palette)
			check(bare.faces==blended.faces and bare.source_cells==blended.source_cells,"palette leaves collision and source cells unchanged")
			output[Vector2i(x,z)] = blended.blend_colours
			for kind in blended.surfaces:
				var vertices: PackedVector3Array = blended.surfaces[kind]
				var colours: PackedColorArray = blended.blend_colours[kind]
				check(vertices.size()==colours.size(),"every rendered vertex has material colour")
				for i in vertices.size():
					var colour := colours[i]
					continuous = continuous and is_finite(colour.r) and colour.a>=0.0 and colour.a<=1.00001
					if colour.a>0.01 and colour.a<0.99:
						mixed += 1
					# Face centres retain their own material core; corners are shared.
					if i%3==0:
						continue
					var key := Vector3i((vertices[i]*4096.0).round())
					if colours_at.has(key):
						continuous = continuous and (colours_at[key] as Color).is_equal_approx(colour)
						joins += 1
					else:
						colours_at[key] = colour
	check(joins>100 and continuous,"shared vertices agree across material/chunk joins, including excavation")
	check(mixed>100,"rock/earth transitions contain mixed weights")
	return output
