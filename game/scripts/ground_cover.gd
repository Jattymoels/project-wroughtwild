class_name GroundCover
extends RefCounted
## Ground cover per biome (Wave 6 slice 4, the expansive pass; the owner,
## 4 Sep 2026: "make the colours and feel just more expansive"): tufts and
## flowers on the meadow, ferns on the forest floor, reeds in the fen, dead
## grass on the ash, a rare tuft in the hills. Every piece is a cross of two
## quads in a MultiMesh per chunk and kind, placed by a hash of its cell so a
## rebuilt chunk grows the same cover. Colours come from the master palette
## (docs/art/art-direction.md); keep this table in sync with biome_mood.gd.

## Per biome id: the cover kinds it grows, each with the chance a surface
## cell of a listed block kind carries one, its size, and its colours.
const COVER := {
	"meadow": [
		{"kind": "tuft", "on": ["grass"], "density": 0.3, "height": 0.26, "width": 0.3,
			"colour": Color(0.5, 0.72, 0.32), "dark": Color(0.36, 0.56, 0.24)},
		{"kind": "flower", "on": ["grass"], "density": 0.05, "height": 0.24, "width": 0.18,
			"colour": Color(0.95, 0.85, 0.45), "dark": Color(0.85, 0.5, 0.45)},
	],
	"forest": [
		{"kind": "fern", "on": ["forest_floor", "grass"], "density": 0.3, "height": 0.42, "width": 0.52,
			"colour": Color(0.24, 0.46, 0.22), "dark": Color(0.16, 0.34, 0.16)},
	],
	"fen": [
		{"kind": "reed", "on": ["marsh", "grass"], "density": 0.32, "height": 0.9, "width": 0.3,
			"colour": Color(0.5, 0.6, 0.36), "dark": Color(0.34, 0.44, 0.3)},
	],
	"ember_wastes": [
		{"kind": "dead_grass", "on": ["ash", "rock"], "density": 0.14, "height": 0.24, "width": 0.28,
			"colour": Color(0.5, 0.42, 0.3), "dark": Color(0.36, 0.28, 0.22)},
	],
	"rocky_hills": [
		{"kind": "tuft", "on": ["rock", "grass"], "density": 0.05, "height": 0.26, "width": 0.3,
			"colour": Color(0.55, 0.6, 0.42), "dark": Color(0.42, 0.46, 0.34)},
	],
}

static var _meshes := {}
static var _material: StandardMaterial3D


## The cover kinds a biome grows (tests, and the art-direction contract).
static func kinds_for(biome_id: String) -> Array:
	var out: Array = []
	for entry in COVER.get(biome_id, []):
		out.append(String(entry["kind"]))
	return out


static func _shared_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.roughness = 1.0
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _material


## A cross of two quads, base at the origin, in the entry's colours: the
## lower half darker so it roots into the ground.
static func _mesh_for(entry: Dictionary) -> ArrayMesh:
	var key := String(entry["kind"])
	if _meshes.has(key):
		return _meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h: float = entry["height"]
	var w: float = float(entry["width"]) * 0.5
	var top: Color = entry["colour"]
	var bottom: Color = entry["dark"]
	for quad in [[Vector3(-w, 0, 0), Vector3(w, 0, 0)], [Vector3(0, 0, -w), Vector3(0, 0, w)]]:
		var a: Vector3 = quad[0]
		var b: Vector3 = quad[1]
		st.set_color(bottom); st.add_vertex(a)
		st.set_color(bottom); st.add_vertex(b)
		st.set_color(top); st.add_vertex(b + Vector3(0, h, 0))
		st.set_color(bottom); st.add_vertex(a)
		st.set_color(top); st.add_vertex(b + Vector3(0, h, 0))
		st.set_color(top); st.add_vertex(a + Vector3(0, h, 0))
	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, _shared_material())
	_meshes[key] = mesh
	return mesh


## Deterministic per cell and kind, so a rebuilt chunk grows the same cover.
static func _roll(x: int, z: int, kind: String, salt: int) -> float:
	var h := hash(Vector3i(x, salt, z)) ^ hash(kind)
	return float(absi(h) % 10007) / 10007.0


## Grows the cover for one chunk from the sim's chunk data (block centres
## by kind) and the map (heights and biomes per cell). Only a block whose
## top is the surface carries cover. Returns the instances placed.
static func build_for_chunk(chunk: Node3D, chunk_data: Dictionary, map: Dictionary, cell: float,
		frontier_look: Resource = null) -> int:
	if map.is_empty() or not map.has("heights") or not map.has("biomes"):
		return 0
	var width := int(map["width"])
	var height_cells := int(map["height"])
	var heights: PackedInt32Array = map["heights"]
	var biomes: PackedInt32Array = map["biomes"]
	var defs: Array = map.get("biome_defs", [])
	var kinds: Dictionary = chunk_data.get("kinds", {})
	var placed := 0
	# Gather instances per cover kind, then one MultiMesh each.
	var batches := {}
	for kind in kinds:
		var centres: PackedVector3Array = kinds[kind]
		for centre in centres:
			var cx := int(floor(centre.x / cell))
			var cz := int(floor(centre.z / cell))
			if cx < 0 or cz < 0 or cx >= width or cz >= height_cells:
				continue
			var surface := heights[cz * width + cx]
			# The surface block's centre sits half a block under the surface height.
			if absf(centre.y + cell * 0.5 - float(surface)) > 0.01:
				continue
			var biome_index := biomes[cz * width + cx]
			if biome_index < 0 or biome_index >= defs.size():
				continue
			var biome_id := String(defs[biome_index].get("id", ""))
			for entry in COVER.get(biome_id, []):
				if not (String(kind) in entry["on"]):
					continue
				var salt := 11
				var density := float(entry["density"])
				if frontier_look != null:
					density *= float(frontier_look.cover_density(cx, cz))
				if _roll(cx, cz, String(entry["kind"]), salt) >= density:
					continue
				var yaw := _roll(cx, cz, String(entry["kind"]), 23) * TAU
				var size := 0.75 + _roll(cx, cz, String(entry["kind"]), 37) * 0.5
				if frontier_look != null:
					size *= float(frontier_look.cover_scale)
				var offset := Vector3((_roll(cx, cz, String(entry["kind"]), 41) - 0.5) * 0.5, 0.0, (_roll(cx, cz, String(entry["kind"]), 43) - 0.5) * 0.5)
				var at := Vector3(centre.x, float(surface), centre.z) + offset
				if chunk.has_meta("surface_sampler"):
					var grounded: float = chunk.get_meta("surface_sampler").height_at(at.x,at.z,float(surface))
					if not is_finite(grounded):
						continue
					at.y = grounded - 0.015
				var basis := Basis(Vector3.UP, yaw).scaled(Vector3(size, size, size))
				if not batches.has(entry["kind"]):
					batches[entry["kind"]] = {"entry": entry, "transforms": []}
				(batches[entry["kind"]]["transforms"] as Array).append(Transform3D(basis, at))
	for kind in batches:
		var transforms: Array = batches[kind]["transforms"]
		var entry: Dictionary = batches[kind]["entry"]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		# A MultiMesh carries colour per instance, not per vertex: each card
		# is tinted somewhere between the kind's two colours by its cell.
		multimesh.use_colors = true
		multimesh.mesh = _mesh_for(entry) if frontier_look == null else frontier_look.cover_mesh(entry)
		multimesh.instance_count = transforms.size()
		for i in transforms.size():
			multimesh.set_instance_transform(i, transforms[i])
			var origin: Vector3 = (transforms[i] as Transform3D).origin
			var blend := _roll(int(floor(origin.x)), int(floor(origin.z)), String(entry["kind"]), 53)
			var tint := (entry["dark"] as Color).lerp(entry["colour"], 0.35 + 0.65 * blend)
			if frontier_look != null:
				tint = Color.WHITE.darkened(blend * 0.15)
			multimesh.set_instance_color(i, tint)
		var instance := MultiMeshInstance3D.new()
		instance.name = "Cover_%s" % kind
		instance.multimesh = multimesh
		instance.material_override = _shared_material() if frontier_look == null else frontier_look.cover_material()
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if frontier_look != null and frontier_look.cover_distance>0:
			instance.visibility_range_end = frontier_look.cover_distance
			instance.visibility_range_end_margin = 8.0
			instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		chunk.add_child(instance)
		placed += transforms.size()
	return placed
