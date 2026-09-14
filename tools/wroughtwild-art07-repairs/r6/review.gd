extends Node3D
## Actual generated nodes and native voxel excavation. No altered terrain rule.
const IDS = ["iron_vein", "copper_vein", "tin_vein", "ember_iron_vein", "silver_vein"]
var terrain: Terrain
var camera: Camera3D
var player: WroughtwildPlayer
var sim: WroughtwildSim
var caption: Label
var output := ""
var checks := 0
var rows: Array = []
var bench := false
var samples: Array = []
var restart_dir := ""
var motion: Array = []

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: push_error("R6_FAIL " + label)
	assert(ok, label)

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg.begins_with("--restart-dir="): restart_dir = arg.trim_prefix("--restart-dir=")
	bench = "--benchmark" in OS.get_cmdline_user_args()
	check(not output.is_empty(), "fresh explicit output directory")
	DirAccess.make_dir_recursive_absolute(output)
	get_window().size = Vector2i(1280,720)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.hud.hide()
	player.hide()
	sim = player.inventory.get_sim()
	check(sim.set_world_profile("living_frontier_wave3"), "retained LF3 profile")
	terrain = Terrain.new()
	terrain.name = "Terrain"
	add_child(terrain)
	terrain.set_process(false)
	terrain._sim = sim
	terrain._seed = 77
	terrain._world_profile = "living_frontier_wave3"
	terrain.map = sim.world_map(77)
	terrain._blocks = terrain.map.blocks.duplicate()
	terrain.block_rules = sim.block_rules()
	terrain.fire_rules = sim.fire_setting()
	terrain._overlays = Node3D.new()
	terrain.add_child(terrain._overlays)
	terrain.faceted_surface = true
	terrain.frontier_look = preload("res://art/weathered_look.tres")
	terrain.nodes_root = Node3D.new()
	terrain.nodes_root.name = "ResourceNodes"
	terrain.add_child(terrain.nodes_root)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.22,0.28,0.31)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.65,0.7,0.75)
	world.environment.ambient_light_energy = 0.8
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-25,0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	add_child(sun)
	camera = Camera3D.new()
	camera.fov = 60
	add_child(camera)
	camera.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	caption = Label.new()
	caption.position = Vector2(18,18)
	caption.add_theme_font_size_override("font_size",18)
	layer.add_child(caption)
	run.call_deferred()

func build_near(at: Vector3) -> void:
	check(sim.set_world_profile(terrain.world_profile()), "mesh query retains the declared generated world")
	var origin := Vector2i(floori(at.x/16)*16,floori(at.z/16)*16)
	for dx in [-16,0,16]:
		for dz in [-16,0,16]:
			var pos := origin+Vector2i(dx,dz)
			if pos.x < 0 or pos.y < 0 or pos.x >= int(terrain.map.width) or pos.y >= int(terrain.map.height): continue
			var key := "%d_%d" % [pos.x,pos.y]
			if not terrain.chunks.has(key):
				var payload := sim.world_mesh_chunk(77,16,pos.x,pos.y,PackedInt32Array(),true,terrain._blend_palette())
				if not payload.faces.is_empty(): terrain._build_chunk(payload,1.0)

func make_node(def: Dictionary, use_art: bool) -> ResourceNode:
	var record := ResourceStream.definition_record(def,1.0)
	var node: ResourceNode = G1Art.resource(preload("res://scenes/resource_node.tscn"),record) if use_art else preload("res://scenes/resource_node.tscn").instantiate()
	node.name = record.name
	node.resource_id = record.resource_id
	node.visual = record.visual
	node.material_family = record.family
	node.remaining_units = record.remaining_units
	node.units_per_harvest = record.units_per_harvest
	node.heat_to_work = record.heat_to_work
	node.position = Vector3(record.position[0],record.position[1],record.position[2])
	terrain.nodes_root.add_child(node)
	return node

func geometry(node: ResourceNode) -> Dictionary:
	var mesh: MeshInstance3D = node.get_node("MeshInstance3D")
	var body: CollisionShape3D = node.get_node("CollisionShape3D")
	return {"vertices": mesh.mesh.get_faces() if mesh.mesh != null else PackedVector3Array(), "faces": body.shape.get_faces(), "node_pose": node.transform, "mesh_pose": mesh.transform, "body_pose": body.transform, "layer": node.collision_layer, "mask": node.collision_mask}

func digest(value: Variant) -> String:
	var hash_context := HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)
	hash_context.update(var_to_bytes(value))
	return hash_context.finish().hex_encode()

func inspect_surface(node: ResourceNode) -> Dictionary:
	var data := geometry(node)
	var max_error := 0.0
	var min_y := INF
	var max_y := -INF
	if data.vertices.is_empty():
		check(node.get_node("CollisionShape3D").disabled, "absent native ribbon has no enabled stale target")
		return {"triangles":0,"height_range_m":0.0,"max_lift_error_m":0.0,"geometry_sha256":digest(data)}
	for vertex: Vector3 in data.vertices:
		var at: Vector3 = node.position+vertex
		var query := PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.2,at-Vector3.UP*0.3)
		query.exclude = [node.get_rid(),player.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			FileAccess.open(output+"/failed-support-ray.json",FileAccess.WRITE).store_string(JSON.stringify({"id":node.resource_id,"at":str(at),"sampler_height":terrain.rendered_height(at.x,at.z,node.position.y,1.25),"chunks":terrain.chunks.keys()},"  "))
		check(not hit.is_empty(), "ribbon vertex has retained physical support")
		var error: float = absf(at.y-hit.position.y-terrain.frontier_look.seam_surface_lift)
		max_error = maxf(max_error,error)
		min_y = minf(min_y,vertex.y)
		max_y = maxf(max_y,vertex.y)
	check(max_error < 0.002, "same native 0.018 m lift above collision")
	check(data.vertices == data.faces, "visible surface and original picking triangles match")
	return {"triangles": data.vertices.size()/3, "height_range_m": max_y-min_y, "max_lift_error_m": max_error, "geometry_sha256": digest(data)}

func capture(node: ResourceNode, label: String, kind: String) -> void:
	if bench: return
	var at := node.position
	var caption_id := node.resource_id
	var units := node.remaining_units
	var surface_y := terrain.rendered_height(at.x,at.z,at.y,1.25)
	if is_finite(surface_y): at.y = surface_y
	for view in ["player","close"]:
		camera.position = at+Vector3(1.4,1.65,2.0) if view == "player" else at+Vector3(0.8,0.7,1.1)
		var eye_ground := terrain.rendered_height(camera.position.x,camera.position.z,at.y,4.0)
		if is_finite(eye_ground): camera.position.y = eye_ground+(1.65 if view == "player" else 0.7)
		camera.look_at(at)
		caption.text = "ART-07R6 | %s | %s | %s\nNative LF3 seed 77 site | %s | remaining %d" % [kind,label,view,caption_id,units]
		await RenderingServer.frame_post_draw
		check(get_viewport().get_texture().get_image().save_png(output+"/"+kind+"-"+label+"-"+view+".png") == OK, "captured "+label+" "+view)

func run() -> void:
	var geography_before := digest(terrain.map)
	var definitions: Dictionary = {}
	var scores: Dictionary = {}
	var selection_audit: Dictionary = {}
	for def: Dictionary in terrain.map.nodes:
		var kind := String(def.type)
		if not kind in IDS: continue
		var x := int(def.x)
		var z := int(def.z)
		if not selection_audit.has(kind): selection_audit[kind] = {}
		var delta := int(def.y)-terrain.height_at(x,z)
		selection_audit[kind][str(delta)] = int(selection_audit[kind].get(str(delta),0))+1
		if x < 32 or z < 32 or x >= int(terrain.map.width)-32 or z >= int(terrain.map.height)-32: continue
		var cave := kind in ["copper_vein","tin_vein"]
		if not cave and absf(float(delta)) > 1.25: continue
		var relief := 0.0
		for offset in [Vector2i(2,0),Vector2i(-2,0),Vector2i(0,2),Vector2i(0,-2)]:
			relief = maxf(relief,absf(float(terrain.height_at(x+offset.x,z+offset.y))-float(def.y)))
		var score := relief*10.0+Vector2(x,z).distance_to(Vector2(480,480))*0.01
		if cave:
			if x%16 < 3 or x%16 > 12 or z%16 < 3 or z%16 > 12: continue
			# Copper/tin are native cave-floor populations, not relocated surface ores.
			# Prefer a roomy existing floor for the player-height inspection camera.
			score = Vector2(x,z).distance_to(Vector2(480,480))*0.001
			for dx in [-1,0,1,2]:
				for dz in [-1,0,1,2]:
					for dy in [0,1,2,3]:
						if terrain.block_at(x+dx,int(def.y)+dy,z+dz) != 0: score += 10.0
					if terrain.block_at(x+dx,int(def.y)-1,z+dz) == 0: score += 3.0
		# Include a retained gentle slope at a chunk edge when selecting iron.
		# Selection changes only the inspection site, never its native pose.
		if kind == "iron_vein":
			score = absf(relief-1.0)*20.0+Vector2(x,z).distance_to(Vector2(480,480))*0.001
			if x%16 in [0,15] or z%16 in [0,15]: score -= 5.0
		if score < float(scores.get(kind,INF)):
			scores[kind] = score
			definitions[kind] = def
	FileAccess.open(output+"/selection.json",FileAccess.WRITE).store_string(JSON.stringify({"height_deltas":selection_audit,"selected":definitions},"  "))
	check(definitions.size() == 5, "five genuine generated ore families available")
	for kind: String in IDS:
		var def: Dictionary = definitions[kind]
		var at := Vector3(float(def.x)+0.5,float(def.y),float(def.z)+0.5)
		build_near(at)
		var baseline := make_node(def,false)
		var original := geometry(baseline)
		var original_stock := baseline.remaining_units
		check(not original.vertices.is_empty(), "selected native surface exposed")
		await capture(baseline,"baseline",kind)
		baseline.free()
		var node := make_node(def,true)
		check(geometry(node) == original, "complete candidate geometry/body/pose equals baseline")
		if G1Art.enabled():
			check(node.get("ribbon_material") != null and node.get("art") == null, "faceted material installed without raised slab")
		for i in 3: await get_tree().physics_frame
		var measured := inspect_surface(node)
		measured.id = node.resource_id
		measured.kind = kind
		measured.position = [at.x,at.y,at.z]
		if not restart_dir.is_empty():
			var manager := SaveManager.new()
			check(manager.read(restart_dir+"/"+kind+"-partial.json",player), "fresh process reads native partial checkpoint")
			check(node.remaining_units == original_stock-2 and node.hot_level == 0 and node.cracked == (kind != "iron_vein"), "fresh process restores exact stock/crack/transient heat")
			if G1Art.enabled(): check(is_equal_approx(float(node.ribbon_material.get_shader_parameter("remaining_fraction")),float(original_stock-2)/original_stock), "fresh material fraction uses full definition, not remaining-at-ready")
			check(geometry(node) == original, "fresh partial restore keeps exact geometry and body")
			await capture(node,"restart-partial",kind)
			rows.append(measured)
			node.free()
			continue
		await capture(node,"full",kind)
		if bench:
			camera.position = at+Vector3(1.4,1.65,2.0)
			camera.look_at(at)
			for i in 60: await RenderingServer.frame_post_draw
			var times: Array = []
			for i in 240:
				var start := Time.get_ticks_usec()
				await RenderingServer.frame_post_draw
				times.append((Time.get_ticks_usec()-start)/1000.0)
			times.sort()
			samples.append({"kind":kind,"samples":240,"median_ms":times[120],"p95_ms":times[228],"worst_ms":times[239],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"visible_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
			node.free()
			continue
		if kind != "iron_vein":
			check(node.work(sim).has("refusal"), "cold refusal unchanged")
			node.soak(2,60)
			check(node.quench(), "native heat/quench changes saved crack state")
		var result := node.work(sim)
		player._apply_work(node,result)
		check(node.remaining_units == original_stock-2, "actual native work removes exactly two units")
		if G1Art.enabled(): check(is_equal_approx(float(node.ribbon_material.get_shader_parameter("remaining_fraction")),float(original_stock-2)/original_stock), "surface mineral boundary follows remaining native stock")
		check(geometry(node) == original, "partial work preserves full native picking/body geometry")
		await capture(node,"partial",kind)
		var save := SaveManager.new()
		var checkpoint := save.capture(player)
		check(save.write(output+"/"+kind+"-partial.json",player), "write native partial checkpoint for fresh-process replay")
		check(save.apply(player,JSON.parse_string(JSON.stringify(checkpoint))), "native save apply restores partial ore")
		check(save.capture(player).resource_nodes == checkpoint.resource_nodes, "all resource record fields survive save restoration")
		if G1Art.enabled(): check(is_equal_approx(float(node.ribbon_material.get_shader_parameter("remaining_fraction")),float(original_stock-2)/original_stock), "restored partial material synchronises before input")
		var dug := Vector3i(int(def.x),int(def.y)-1,int(def.z))
		terrain.cracked[dug] = true
		check(terrain.break_block(dug.x,dug.y,dug.z) != "", "real native voxel excavation removes support")
		for i in 3: await get_tree().physics_frame
		check(geometry(node).vertices != original.vertices, "excavation updates native surface")
		measured.excavated = inspect_surface(node)
		await capture(node,"excavated",kind)
		check(node.position == at and node.remaining_units == original_stock-2, "excavation retains anchor and finite stock")
		terrain.apply_broken_blocks([])
		for i in 3: await get_tree().physics_frame
		check(geometry(node) == original, "restored terrain reproduces every mesh/collider/pose value")
		if kind == "iron_vein": await walk_past(node)
		while node.remaining_units > 0: player._apply_work(node,node.work(sim))
		check(node.harvest() == 0, "exhaustion refuses duplicate yield")
		if G1Art.enabled(): check(not node.get_node("MeshInstance3D").visible, "exhausted ribbon hides before native shrink can detach it")
		await capture(node,"exhausted",kind)
		for i in 30: await get_tree().physics_frame
		check(not is_instance_valid(node), "native exhaustion removes target")
		rows.append(measured)
	check(digest(terrain.map) == geography_before, "complete native generated map unchanged")
	var inventory := {}
	for child in get_children():
		if child is Pickup and not child.is_queued_for_deletion(): child._absorb(player)
	for kind: String in IDS:
		inventory[kind] = sim.material_count(definitions[kind].material_family)
		if not bench and restart_dir.is_empty(): check(inventory[kind] == int(definitions[kind].units), "all finite ore paid once into native inventory")
	var report := {"checks":checks,"failures":0,"rows":rows,"inventory":inventory,"geography_sha256":geography_before,"gpu":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"viewport":str(get_viewport().size),"msaa":"4x","vsync":"off","samples":samples,"motion":motion,"art":G1Art.enabled(),"scope":"Harness-paced native generated sites, native work and voxel excavation; no inventory grants or authored terrain substitution."}
	FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("R6_CHECKS ",checks," checks, 0 failures")
	get_tree().quit()

func walk_past(node: ResourceNode) -> void:
	var at := node.position
	player.position = at+Vector3(-1.8,1.4,1.2)
	player.rotation = Vector3.ZERO
	player.velocity = Vector3.ZERO
	player.work_panel.close_panel()
	player.build_palette.close_panel()
	player.placement.set_build_mode_enabled(false)
	player.set_physics_process(true)
	for frame in 25: await get_tree().physics_frame
	var start := player.position
	Input.action_press("move_right")
	for frame in 150:
		await get_tree().physics_frame
		if player.position.x >= at.x+1.8: Input.action_release("move_right")
		camera.position = player.position+Vector3.UP*0.65
		camera.look_at(at)
		if frame%5 == 0:
			motion.append({"frame":frame,"position":[player.position.x,player.position.y,player.position.z],"grounded":player.is_on_floor()})
			caption.text = "ART-07R6 | actual native controller traversal | partial iron\nHarness presses move_right; unchanged player movement resolves terrain/body."
			await RenderingServer.frame_post_draw
			check(get_viewport().get_texture().get_image().save_png(output+"/motion-%03d.png"%(frame/5)) == OK, "native movement frame")
	check(player.position.x-start.x > 2.0, "real capsule traverses work side without phantom slab")
	Input.action_release("move_right")
	player.set_physics_process(false)
	player.position = Vector3.ZERO
