extends "res://tests/wide_terrain_stream.gd"
## Common before/after oracle: real finite nodes, supported meshes, collider
## poses and effective materials through cold, hover, heat and cracked states.
var rows: Array[Dictionary] = []
var assembly_ms: Array[float] = []
var output := ""

func _exercise() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--review-output="): output = arg.trim_prefix("--review-output=")
	terrain.chunk_stream._finish_job()
	terrain.chunk_stream._pending.clear()
	terrain.current_era = 5 # Include existing late-era source presentations.
	var original := terrain.resource_stream.capture()
	var selected := {}
	for id: String in terrain.resource_stream.records.keys():
		var record: Dictionary = terrain.resource_stream.records[id]
		var p: Array = record.position
		var x := floori(float(p[0]))
		var z := floori(float(p[2]))
		var biome: int = terrain.map.biomes[z*int(terrain.map.width)+x]
		var key := String(record.visual)+":"+str(biome)
		if int(selected.get(key,0)) >= 2: continue
		selected[key] = int(selected.get(key,0))+1
		var origin := Vector2i(x/16*16,z/16*16)
		for offset in [Vector2i.ZERO,Vector2i(-16,0),Vector2i(16,0),Vector2i(0,-16),Vector2i(0,16)]:
			var at: Vector2i = origin+offset
			if at.x>=0 and at.y>=0 and at.x<int(terrain.map.width) and at.y<int(terrain.map.height):
				terrain.chunk_stream._build(at)
		# Recreate an already resident scene too, so the timing includes its
		# actual ready/material/collider work, with the same authoritative ID.
		if terrain.resource_stream.active.has(id):
			var previous: ResourceNode = terrain.resource_stream.active[id]
			previous.get_parent().remove_child(previous)
			previous.free()
		var began := Time.get_ticks_usec()
		var node := terrain.resource_stream.materialise(id)
		assembly_ms.append((Time.get_ticks_usec()-began)/1000.0)
		if node == null:
			check(false, "native resource materialises: " + id)
			continue
		var result := {"id": id, "category": key, "states": {}}
		result.states["initial"] = _presentation_signature(node)
		var initial_cracked := node.cracked
		node.set_highlight(true)
		result.states["hover"] = _presentation_signature(node)
		node.hot_level = 2
		node._refresh_state_look()
		result.states["hot"] = _presentation_signature(node)
		node.hot_level = 0
		node.cracked = true
		node._refresh_state_look()
		result.states["cracked_hover"] = _presentation_signature(node)
		node.cracked = initial_cracked
		node.set_highlight(false)
		result.states["cold_again"] = _presentation_signature(node)
		rows.append(result)
	check(rows.size()>30, "multiple native presentations and biomes exercised")
	var after := terrain.resource_stream.capture()
	# Materialisation turns the tool ID String into the node's StringName.
	# Compare the actual save representation, including every field and value.
	check(JSON.stringify(after)==JSON.stringify(original), "presentation changes preserve every serialised finite resource record")

func _material(material: Material) -> Variant:
	if material == null: return null
	if material is BaseMaterial3D:
		var values: Dictionary = {}
		for property in ["albedo_color","metallic","roughness","vertex_color_use_as_albedo","vertex_color_is_srgb","transparency","shading_mode","cull_mode","emission_operator"]:
			values[property] = material.get(property)
		# Enabled with zero energy is visually equivalent to a disabled feature.
		values["effective_emission"] = material.emission*material.emission_energy_multiplier if material.emission_enabled else Color(0,0,0,0)
		if not material.emission_enabled or is_zero_approx(material.emission_energy_multiplier): values["effective_emission"] = Color(0,0,0,0)
		return values
	if material is ShaderMaterial:
		var values := {"shader": material.shader.resource_path, "uniforms": {}}
		for uniform in material.shader.get_shader_uniform_list():
			var value: Variant = material.get_shader_parameter(uniform.name)
			values.uniforms[uniform.name] = value.resource_path if value is Resource else value
		return values
	return material.resource_path

func _snapshot(node: Node) -> Array:
	var parts: Array = [node.get_class()]
	if node is Node3D: parts.append([node.transform,node.visible])
	if node is MeshInstance3D:
		parts.append([node.visibility_range_end,node.visibility_range_end_margin,node.visibility_range_fade_mode,node.cast_shadow])
		if node.mesh != null:
			for surface in node.mesh.get_surface_count(): parts.append([node.mesh.surface_get_arrays(surface),_material(node.get_active_material(surface))])
	if node is CollisionShape3D:
		parts.append([node.disabled,node.shape.get_faces() if node.shape is ConcavePolygonShape3D else node.shape.size if node.shape is BoxShape3D else str(node.shape.get_class())])
	if node is CollisionObject3D: parts.append([node.collision_layer,node.collision_mask])
	for child in node.get_children(): parts.append(_snapshot(child))
	return parts

func _presentation_signature(node: Node) -> String:
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(var_to_bytes(_snapshot(node)))
	return digest.finish().hex_encode()

func _finish() -> void:
	assembly_ms.sort()
	var result := {"profile":profile,"checks":checks,"failures":failures,"rows":rows,"assembly_ms":assembly_ms}
	if not output.is_empty():
		var file := FileAccess.open(output.path_join("resource-presentation.json"),FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify(result,"\t"))
	if is_instance_valid(terrain): terrain.free()
	print("RESOURCE_PRESENTATION %d checks, %d failures; %d native nodes, five states each" % [checks,failures,rows.size()])
	get_tree().quit(0 if failures==0 else 1)
