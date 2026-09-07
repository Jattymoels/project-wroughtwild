extends Node3D
## INT-04A: compare paid manual crafting with the unchanged native transaction.
## Inspection stock is deliberate; no owner save or pacing claim belongs here.
const CHECKPOINT := "res://../captures/interaction-feedback/workshop-checkpoint.json"
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var sim: WroughtwildSim
var work: WorkPanel
var sites: Array[StationSite] = []
var manager := SaveManager.new()


func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL WORKSHOP FEEDBACK: ", label)
	return ok


func _ready() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.position = Vector3(-8, 1, 0)
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.spring_arm.set_physics_process(false)
	player.placement.set_physics_process(false)
	sim = player.inventory.get_sim()
	work = player.work_panel
	for index in 3:
		var site := preload("res://scenes/station_site.tscn").instantiate() as StationSite
		site.name = "ReviewStation%d" % index
		site.station_id = [&"workbench", &"mason_yard", &"forge_basic"][index]
		site.upgrade_station_id = &"forge_improved" if index == 2 else &""
		site.position = Vector3(index * 4, 0, 0)
		site.rotation.y = float(index) * PI / 2
		site.player_built = true
		site.station_key = StationSite.key_at(String(site.station_id), site.position)
		sim.add_station(site.station_id)
		add_child(site)
		sites.append(site)
	_run.call_deferred()


func _run() -> void:
	await get_tree().physics_frame
	await _operation("timber_wedge", 1, null, "craft_field")
	await _operation("timber_frame", 1, sites[0], "craft_bench")
	await _operation("dress_stone", 1, sites[1], "craft_yard")
	await _operation("refine_rustclay_brick", 1, sites[2], "craft_forge")
	await _operation("refine_rustclay_brick", 3, sites[2], "craft_forge")
	await _operation("smelt_iron", 1, sites[2], "craft_forge")
	await _operation("wooden_cudgel", 1, sites[0], "craft_bench")
	# Hand recipes remain hand-available at real benches; the active surface is
	# the location of the sound, not a remotely chosen globally unlocked forge.
	await _operation("timber_wedge", 1, sites[0], "craft_bench")
	sim.add_station("forge_improved")
	sites[2].refresh_visual(sim)
	await _operation("refine_rustclay_brick", 1, sites[2], "craft_forge")
	var experienced: Dictionary = JSON.parse_string(sim.export_json())
	experienced.economy.skill_xp.blacksmithing = 1000
	check(sim.import_json(JSON.stringify(experienced)), "inspection fixture provides experienced smith for existing Sound and Stable crafts")
	await _operation("wooden_cudgel", 1, sites[2], "craft_forge", 2)
	await _operation("charred_brand", 1, sites[2], "craft_forge", 1, "stable_ember_catalyst")
	await _refusals()
	await _no_remote_response()
	if "--feedback-review" in OS.get_cmdline_user_args(): await _captures()
	await _save_and_expiry()
	print("WORKSHOP_FEEDBACK %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)


func _nodes(group: String) -> Array[Node]:
	var found: Array[Node] = []
	for node: Node in get_tree().get_nodes_in_group(group):
		if not node.is_queued_for_deletion(): found.append(node)
	return found


func _clear_feedback() -> void:
	for group in ["interaction_sounds", "workshop_feedback"]:
		for node: Node in _nodes(group):
			node.get_parent().remove_child(node)
			node.queue_free()
	await get_tree().process_frame


func _stock(recipe_id: String, quantity := 1, with_fuel := true, quality := 1, aim_kind := "") -> void:
	sim.drop_inventory()
	var recipe: Dictionary = sim.recipe(recipe_id)
	var preview: Dictionary = sim.craft_preview(recipe_id, aim_kind, quality, quantity)
	for cost: Dictionary in preview.costs:
		sim.add_material(String(cost.id), int(cost.need))
	if with_fuel and int(recipe.get("fuel_cost", 0)) > 0:
		sim.add_material("wood", int(recipe.fuel_cost) * quantity)


func _open(site: StationSite) -> void:
	if site == null: work.open_hand_crafting()
	else: site.interact(player)


func _poses() -> Array[Dictionary]:
	var poses: Array[Dictionary] = []
	for site in sites:
		var collision := site.get_node("CollisionShape3D") as CollisionShape3D
		poses.append({"body":site.transform, "mesh":site._mesh.mesh,
			"mesh_pose":site._mesh.transform, "collision":collision.shape,
			"collision_pose":collision.transform, "disabled":collision.disabled})
	return poses


func _unchanged(poses: Array[Dictionary], label: String) -> void:
	for index in sites.size():
		var site := sites[index]
		var collision := site.get_node("CollisionShape3D") as CollisionShape3D
		var original := poses[index]
		check(site.transform == original.body and site._mesh.transform == original.mesh_pose and site._mesh.mesh == original.mesh,
			label + ": existing station body and authored mesh stay fixed " + String(site.station_id))
		check(collision.shape == original.collision and collision.transform == original.collision_pose and collision.disabled == original.disabled,
			label + ": existing physical station stays fixed " + String(site.station_id))


func _operation(recipe_id: String, quantity: int, site: StationSite, cue: String, quality := 1, aim_kind := "") -> void:
	await _clear_feedback()
	_stock(recipe_id, quantity, true, quality, aim_kind)
	_open(site)
	var native := WroughtwildSim.new()
	check(native.load_tuning(load("res://scripts/sim.gd").get_tuning_directory()), "native comparison loads existing definitions")
	check(native.import_json(sim.export_json()), "native comparison starts from exact saved economy")
	var expected: Dictionary = native.craft(recipe_id, native.recipe_feeds_open_order(recipe_id), aim_kind, quality, quantity)
	var before := _poses()
	var before_sites: Array = manager.capture(player).stations
	var result := work.craft(recipe_id, aim_kind, quality, quantity)
	check(result.get("crafted", false), "normal manual craft succeeds: %s x%d" % [recipe_id, quantity])
	check(result == expected and sim.export_json() == native.export_json(), "cost, fuel, XP, quality and RNG exactly match native craft: " + recipe_id)
	var sounds := _nodes("interaction_sounds")
	check(sounds.size() == 1, "one sound for the entire operation: %s x%d" % [recipe_id, quantity])
	if sounds.size() == 1:
		check(String(sounds[0].get_meta("cue", "")) == cue, "correct local craft sound: " + recipe_id)
		var at := player.global_position if site == null else site.to_global(StationSite.WORK_LOOK.mount_for(site.current_station_id(sim)))
		check((sounds[0] as Node3D).global_position.is_equal_approx(at), "sound is located at the actual hands or turned station surface")
	var responses := _nodes("workshop_feedback")
	check(responses.size() == (0 if site == null else 1), "only the active physical station responds")
	if site != null and responses.size() == 1:
		var response := responses[0] as Node3D
		check(response.get_parent() == site, "the response belongs to the active local station")
		check(response.get_child_count() == StationSite.WORK_LOOK.fleck_count, "batch quantity does not multiply work flecks")
		for child in response.get_children():
			check(child is MeshInstance3D and child.get_child_count() == 0, "work flecks have no collision, light or collectible child")
	_unchanged(before, "craft completion")
	check(manager.capture(player).stations == before_sites, "craft response adds no saved station state")
	var sound_ids: Array[int] = []
	for sound in sounds: sound_ids.append(sound.get_instance_id())
	for repeat in 4: work.refresh()
	work.catalogue.select_recipe(recipe_id)
	for other in sites: other.refresh_visual(sim)
	var after_ids: Array[int] = []
	for sound in _nodes("interaction_sounds"): after_ids.append(sound.get_instance_id())
	check(after_ids == sound_ids, "browsing and visual refresh never replay a success sound")
	_unchanged(before, "refresh after completion")
	work.close_panel()


func _refusals() -> void:
	await _clear_feedback()
	_stock("refine_rustclay_brick", 3, false)
	_open(sites[2])
	var before := sim.export_json()
	var result := work.craft("refine_rustclay_brick", "", 1, 3)
	check(not result.crafted and result.get("failure", "") == "missing_fuel", "native three-batch craft refuses missing fuel")
	check(sim.export_json() == before, "refused batch spends no clay or partial payment")
	check(_nodes("interaction_sounds").is_empty() and _nodes("workshop_feedback").is_empty(), "cold forge refusal stays silent and idle")
	sim.drop_inventory()
	_open(sites[0])
	result = work.craft("timber_frame")
	check(not result.crafted and result.get("failure", "") == "missing_inputs", "native bench craft refuses absent wood")
	check(_nodes("interaction_sounds").is_empty() and _nodes("workshop_feedback").is_empty(), "missing-input refusal stays silent and idle")
	work.close_panel()


func _no_remote_response() -> void:
	await _clear_feedback()
	_stock("refine_rustclay_brick")
	work.open_hand_crafting()
	var result := work.craft("refine_rustclay_brick")
	check(result.crafted, "direct-call fixture keeps native globally-known station rules unchanged")
	check(_nodes("interaction_sounds").is_empty() and _nodes("workshop_feedback").is_empty(), "field panel cannot animate a remote known forge")
	_stock("refine_rustclay_brick")
	_open(sites[0])
	result = work.craft("refine_rustclay_brick")
	check(result.crafted, "direct-call fixture does not add a new station rule")
	check(_nodes("interaction_sounds").is_empty() and _nodes("workshop_feedback").is_empty(), "unrelated local bench cannot pretend the forge worked")
	work.close_panel()
	_stock("timber_wedge")
	check(work.craft("timber_wedge").crafted, "closed-panel native regression call remains valid")
	check(_nodes("interaction_sounds").is_empty() and _nodes("workshop_feedback").is_empty(), "noninteractive native caller does not start manual presentation")


func _save_and_expiry() -> void:
	await _clear_feedback()
	_stock("refine_rustclay_brick", 3)
	_open(sites[2])
	check(work.craft("refine_rustclay_brick").crafted, "first rapid operation succeeds")
	check(work.craft("refine_rustclay_brick").crafted, "second rapid operation succeeds")
	check(_nodes("workshop_feedback").size() == 1, "rapid operations retain at most one visual response per station")
	var before := _poses()
	await get_tree().process_frame
	_unchanged(before, "during animated response")
	var original := manager.capture(player)
	check(not JSON.stringify(original.stations).contains("CraftWorkResponse"), "saved station records exclude cosmetic response")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CHECKPOINT).get_base_dir())
	check(manager.write_data(CHECKPOINT, original), "normal atomic writer accepts save during manual feedback")
	work.close_panel()
	var old_sounds: Array[int] = []
	for node in _nodes("interaction_sounds"): old_sounds.append(node.get_instance_id())
	check(manager.read(CHECKPOINT, player), "normal save restoration accepts active-feedback capture: " + manager.last_error)
	await get_tree().physics_frame
	for node in _nodes("interaction_sounds"):
		check(old_sounds.has(node.get_instance_id()), "restore cannot create another completion sound")
	check(_nodes("workshop_feedback").is_empty(), "restored stations do not replay a saved completion")
	check(manager.capture(player).stations == original.stations, "save restores exact station records without another craft")
	check(sim.export_json() == String(original.sim), "save restores exact native ownership without another craft")
	sites.clear()
	for child in get_children():
		if child is StationSite: sites.append(child)
	# Restored stations can respond to a genuinely new successful craft.
	var forge: StationSite
	for site in sites:
		if site.station_id == &"forge_basic": forge = site
	if check(forge != null, "local forge survives restoration"):
		_open(forge)
		check(work.craft("refine_rustclay_brick").crafted, "remaining saved ingredients fund one actual new craft")
		check(_nodes("workshop_feedback").size() == 1, "new paid craft alone produces a fresh response")
		work.close_panel()
	await get_tree().create_timer(StationSite.WORK_LOOK.duration + 0.5).timeout
	check(_nodes("workshop_feedback").is_empty(), "local visual response expires without idle station processing")
	await get_tree().create_timer(2.0).timeout
	check(_nodes("interaction_sounds").is_empty(), "completion audio releases its node after the short cue")
	check(manager.apply(player, JSON.parse_string(JSON.stringify(original))), "repeated checkpoint apply remains valid")
	check(_nodes("workshop_feedback").is_empty() and _nodes("interaction_sounds").is_empty(), "repeated restoration stays silent and idle")


func _captures() -> void:
	if not check(DisplayServer.get_name() != "headless", "--feedback-review uses a rendered process"): return
	get_window().size = Vector2i(1280, 720)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("aebdbb")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("d5d9cf")
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_color = Color("fff0d7")
	light.light_energy = 1.3
	add_child(light)
	var ground := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(24, 0.1, 12)
	var floor_finish := StandardMaterial3D.new()
	floor_finish.albedo_color = Color("53574a")
	floor_finish.roughness = 1.0
	floor_mesh.material = floor_finish
	ground.mesh = floor_mesh
	ground.position = Vector3(4, -0.05, 0)
	add_child(ground)
	player.camera.make_current()
	for index in sites.size():
		await _clear_feedback()
		var site := sites[index]
		var recipe_id: String = ["timber_frame", "dress_stone", "refine_rustclay_brick"][index]
		_stock(recipe_id)
		player.position = site.to_global(Vector3(0, 1.0, 1.6))
		player.rotation = Vector3(0, site.rotation.y, 0)
		player.spring_arm.rotation = Vector3.ZERO
		player.camera.transform = Transform3D.IDENTITY
		var mount: Vector3 = StationSite.WORK_LOOK.mount_for(site.current_station_id(sim))
		player.camera.look_at(site.to_global(mount), Vector3.UP)
		# The camera and hands are the ordinary player rig, with a fixed pose so
		# the three stations can be compared under the same local lighting.
		for frame in 6: await get_tree().physics_frame
		player.interact()
		if not check(work.is_open() and work._station == site, "rendered real E opens the visible local station"): continue
		work.catalogue.select_recipe(recipe_id)
		for frame in 6: await get_tree().process_frame
		check(not work.catalogue._action.disabled, "rendered existing recipe is ready at its real station")
		work.catalogue._action.pressed.emit()
		check(_nodes("workshop_feedback").size() == 1 and work.message().begins_with("Crafted"), "rendered action creates one truthful completion")
		# A craft rebuilds the catalogue. Its normal layout takes two deferred
		# frames before centring the settled minimum size; capture that visible
		# result rather than the transient zero-size container's first draw.
		for frame in 4: await get_tree().process_frame
		check(_inside_viewport(work._root), "settled completed craft panel fits the review viewport")
		check(_inside_viewport(work._title), "settled completed craft title is visible")
		var close := work._title.get_parent().get_child(1) as Button
		check(close != null and close.text.begins_with("Close") and _inside_viewport(close), "settled completed craft keeps its Close button visible")
		await _screenshot(String(site.station_id) + "-completed")
		work.close_panel()
		await get_tree().physics_frame
		check(site.get_node_or_null("CraftWorkResponse") != null, "closed-panel surface capture retains the short live work response")
		await _screenshot(String(site.station_id) + "-surface")


func _inside_viewport(control: Control) -> bool:
	var bounds := get_viewport().get_visible_rect()
	var rect := control.get_global_rect()
	return control.is_visible_in_tree() and rect.position.x >= bounds.position.x - 1 and rect.position.y >= bounds.position.y - 1 and rect.end.x <= bounds.end.x + 1 and rect.end.y <= bounds.end.y + 1


func _screenshot(id: String) -> void:
	await RenderingServer.frame_post_draw
	var directory := ProjectSettings.globalize_path("res://../captures/interaction-feedback")
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join("workshop-" + id + ".png")
	check(get_viewport().get_texture().get_image().save_png(path) == OK, "captured actual station interaction: " + id)
	print("WORKSHOP_FEEDBACK_CAPTURE ", path)
