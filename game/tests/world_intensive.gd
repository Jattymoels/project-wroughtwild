extends "res://scripts/sandpit.gd"
## Actual default-world persistence and player-height habitat review. Test saves
## and optional rendered captures live under build/, never the player's save.
var checks := 0
var failures := 0
var report: Dictionary = {}
var review_camera: Camera3D
var output := ""

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL WORLD: ", label)

func _ready() -> void:
	super._ready()
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	mob_packs.set_physics_process(false)
	mob_packs.set_process(false)
	output = ProjectSettings.globalize_path("res://../build/intensives/world")
	DirAccess.make_dir_recursive_absolute(output)
	check(world_profile == "frontier_v2" and terrain.world_profile() == world_profile, "new game chooses frontier_v2")
	check(terrain.map.get("habitats", []).size() == 3, "new game has all three habitats")
	var fen_art := get_node_or_null("HabitatSites/fen_hollow")
	check(fen_art != null and fen_art.get_node_or_null("ShallowPool") != null, "fen composition contains shallow moving water")
	report["frontier_startup"] = terrain.build_profile.duplicate()
	var resources: Array[ResourceNode] = []
	var identities := {}
	for node: ResourceNode in terrain.nodes_root.get_children():
		check(not identities.has(node.resource_id), "stable resource identity is unique")
		identities[node.resource_id] = true
		if not node.habitat_id.is_empty(): resources.append(node)
	check(resources.size() == 48, "six finite sources with eight deposits each")
	for node in resources:
		check(not node.presentation_label.is_empty(), "deposit label is separate from raw ingredient")
		check(node.heat_to_work == 0 and node.tool_item == &"", "contextual work needs no extra unlock")
		var y := terrain.rendered_height(node.position.x, node.position.z, node.position.y)
		check(is_finite(y) and absf(y-node.position.y) <= 0.6, "resource supported by rendered collision surface")
	var worked := {}
	for node in resources:
		if worked.has(node.material_family): continue
		worked[node.material_family] = true
		var units_before := node.remaining_units
		var result: Dictionary = {}
		for press in node.drive_presses: result = node.work(_sim())
		check(int(result.get("granted", 0)) == mini(node.units_per_harvest, units_before), "contextual work completes the source without a tool or class gate")
	var partial: ResourceNode = resources[0]
	var partial_id := String(partial.name)
	var partial_position := partial.global_position
	partial.remaining_units = 11
	partial.drive_progress = 2
	partial.cracked = true
	var depleted_id := String(resources[1].name)
	resources[1].free()
	var excavation := Vector3i(int(terrain.map.spawn_x)+2, int(terrain.height_at(int(terrain.map.spawn_x)+2, int(terrain.map.spawn_z)))-1, int(terrain.map.spawn_z))
	check(terrain.break_block(excavation.x, excavation.y, excavation.z) != "", "test excavates an ordinary soil block")
	var placement_cell := Vector3i((player.spawn_position+Vector3(4,-1.2,0))/player.placement.registry_grid)
	var piece := player.placement.place_piece({"kind":"volume", "axis":0, "cell":placement_cell}, &"cube", &"shellstone")
	check(piece != null, "finished habitat material places through ordinary construction")
	var manager := SaveManager.new()
	var saved := manager.capture(player)
	check(manager.write(output.path_join("checkpoint.json"), player), "atomic world save succeeds")
	var rejected := saved.duplicate(true)
	rejected.world_profile = "future_unknown"
	var before := _sim().export_json()
	check(not manager.apply(player, rejected), "unknown generation profile rejects")
	check(before == _sim().export_json() and world_profile == "frontier_v2", "rejection does not mutate economy or world")
	var original_position:=player.global_position
	var original_node_count:=terrain.nodes_root.get_child_count()
	for malformed in [
		{"blocks":[{}]}, {"resource_nodes":{}}, {"resource_nodes":[{"name":"incomplete"}]},
		{"stations":[{"position":[1,2,3]}]}, {"player":{"position":[1,2],"yaw":0,"pitch":0}},
		{"world_seed":[]}, {"broken_blocks":[[0,"invalid",0]]},
		{"trial_boundary":{"version":1,"built_floor":0,"checkpoint":"","return_position":[0,0,0],"combat":[]}},
		{"trial_boundary":{"version":[],"built_floor":0,"checkpoint":"","return_position":[0,0,0],"combat":{}}},
	]:
		var damaged:=saved.duplicate(true)
		for key in malformed: damaged[key]=malformed[key]
		check(not manager.apply(player,damaged),"malformed world/checkpoint payload rejects cleanly")
		check(_sim().export_json()==before and player.global_position==original_position and terrain.nodes_root.get_child_count()==original_node_count and world_profile=="frontier_v2","malformed restore leaves economy, pose and resources unchanged")
	check(apply_world_identity(world_seed, "legacy_v1"), "same seed selects frozen legacy identity")
	check(terrain.map.habitats.is_empty(), "legacy world does not acquire habitat content")
	report["legacy_startup"] = terrain.build_profile.duplicate()
	var legacy_blocks: PackedByteArray = terrain.map.blocks.duplicate()
	var old_save := manager.capture(player)
	old_save.erase("world_profile")
	check(manager.apply(player, old_save), "pre-profile save restores as legacy_v1")
	check(world_profile == "legacy_v1" and legacy_blocks == terrain.map.blocks, "old save keeps exact terrain")
	check(manager.apply(player, saved), "frontier save restores profile and seed together")
	var restored := terrain.nodes_root.get_node_or_null(partial_id) as ResourceNode
	check(restored != null, "partially harvested node restores by stable identity")
	if restored != null:
		check(restored.remaining_units == 11 and restored.drive_progress == 2 and restored.cracked, "partial work, units and crack state survive")
		check(restored.global_position == partial_position, "restored node keeps anchor")
	check(terrain.nodes_root.get_node_or_null(depleted_id) == null, "depleted source does not regenerate on profile rebuild")
	check(terrain.broken.has(excavation) and terrain.block_at(excavation.x, excavation.y, excavation.z) == 0, "excavation survives rebuild")
	check(manager.capture(player).blocks == saved.blocks, "building palette and lattice anchors survive rebuild")
	check(manager.read(output.path_join("checkpoint.json"), player), "normal disk load restores world snapshot")
	for i in 3: await get_tree().physics_frame
	if DisplayServer.get_name() != "headless": await _review()
	report["checks"] = checks
	report["failures"] = failures
	var manifest_name := "checks.json" if DisplayServer.get_name() == "headless" else "manifest.json"
	var file := FileAccess.open(output.path_join(manifest_name), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("WORLD_ENGINE_INTENSIVE %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func _physics_process(_delta: float) -> void:
	pass # Match review lighting and stop simulation time during persistence assertions.

func _review() -> void:
	player.hud.notify("")
	review_camera = Camera3D.new()
	review_camera.fov = 75
	add_child(review_camera)
	review_camera.make_current()
	var captures: Array = []
	var grove_view := Transform3D.IDENTITY
	for site: Dictionary in terrain.map.habitats:
		var approach: PackedVector3Array = site.approach
		var start := maxi(0, approach.size()-23)
		var composed := _habitat_view(site)
		review_camera.global_position = composed.from
		review_camera.look_at(composed.toward)
		var sun: DirectionalLight3D = $Sun
		var energy := sun.light_energy
		var colour := sun.light_color
		for phase in ["day", "dusk"]:
			sun.light_energy = energy if phase == "day" else energy*0.52
			sun.light_color = colour if phase == "day" else Color("eab58a")
			await _capture(String(site.id)+"-"+phase)
			sun.light_energy = energy
			sun.light_color = colour
		var shown := {}
		for node: ResourceNode in terrain.nodes_root.get_children():
			if node.habitat_id != site.id or shown.has(node.material_family): continue
			shown[node.material_family] = true
			var close_view := _habitat_view(site, node)
			review_camera.global_position = close_view.from
			review_camera.look_at(close_view.toward)
			await _capture("source-"+String(node.material_family))
		if site.id == "fen_hollow":
			var pool := get_node_or_null("HabitatSites/fen_hollow/ShallowPool") as Node3D
			if pool != null:
				var pool_view := _habitat_view(site, pool)
				review_camera.global_position = pool_view.from
				review_camera.look_at(pool_view.toward)
				await _capture("fen-water-detail")
		for step in 12:
			var index := mini(approach.size()-2, start+step*2)
			var at: Vector3 = approach[index]
			at.y = terrain.rendered_height(at.x,at.z,at.y)+1.65
			check(at.is_finite(), "player-height approach supported in renderer")
			review_camera.global_position = at
			var ahead: Vector3 = approach[mini(index+4,approach.size()-1)]+Vector3.UP*1.65
			if at.distance_to(ahead)>0.1: review_camera.look_at(ahead)
			await _capture("walk-"+String(site.id)+"-%02d"%step)
		captures.append({"id":site.id, "position":[site.x,site.y,site.z], "approach_steps":approach.size()})
		if site.id == "oldgrowth_grove": grove_view = review_camera.global_transform
	review_camera.global_transform = grove_view
	report["dense_grove_frame_ms"] = await _frame_sample()
	check(apply_world_identity(world_seed, "legacy_v1"), "matched performance route selects legacy profile")
	review_camera.global_transform = grove_view
	report["legacy_dense_grove_frame_ms"] = await _frame_sample()
	report["dense_grove_change_percent"] = {
		"median":100.0*(float(report.dense_grove_frame_ms.median)/float(report.legacy_dense_grove_frame_ms.median)-1.0),
		"p95":100.0*(float(report.dense_grove_frame_ms.p95)/float(report.legacy_dense_grove_frame_ms.p95)-1.0)}
	report["captures"] = captures

func _frame_sample() -> Dictionary:
	var frame_times: Array[float] = []
	for i in 180:
		var begin := Time.get_ticks_usec()
		await get_tree().process_frame
		if i>=30: frame_times.append(float(Time.get_ticks_usec()-begin)/1000.0)
	frame_times.sort()
	return {"median":frame_times[75],"p95":frame_times[142],"samples":150,
		"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)}

## Select a supported player-height position on the actual guaranteed path.
## Prefer a clear view of both sources over an accidental foreground trunk.
func _habitat_view(site: Dictionary, focus: Node3D = null) -> Dictionary:
	var nodes: Array[ResourceNode] = []
	var centre := Vector3.ZERO
	for node: ResourceNode in terrain.nodes_root.get_children():
		if node.habitat_id == site.id:
			nodes.append(node)
			centre += node.global_position
	centre /= maxi(nodes.size(),1)
	var toward := centre+Vector3.UP*1.3
	var desired_distance := 11.0
	if focus != null:
		var is_tree: bool = focus is ResourceNode and (focus as ResourceNode).visual == &"resinheart_tree"
		toward = focus.global_position+Vector3.UP*(3.5 if is_tree else 0.35)
		desired_distance = 12.0 if is_tree else 5.0
	var approach: PackedVector3Array = site.approach
	var chosen: Vector3 = approach[maxi(0,approach.size()-15)]+Vector3.UP*1.65
	var best := -INF
	var space := get_world_3d().direct_space_state
	for index in range(maxi(0,approach.size()-36),approach.size(),2):
		var at: Vector3 = approach[index]
		at.y = terrain.rendered_height(at.x,at.z,at.y)+1.65
		if not at.is_finite(): continue
		var score := -absf(at.distance_to(toward)-desired_distance)*0.6
		for node in nodes:
			var end := node.global_position+Vector3.UP*0.45
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at,end))
			if hit.is_empty() or hit.get("collider") == node:
				score += 1.0 if focus == null or node != focus else 12.0
		if score > best:
			best = score
			chosen = at
	return {"from":chosen,"toward":toward}

func _capture(id: String) -> void:
	for i in 3: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(output.path_join(id+".png")) == OK, "capture "+id)
