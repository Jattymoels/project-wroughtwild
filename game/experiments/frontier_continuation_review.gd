extends Node3D
## Real sandpit + UI captures. Paused camera inspections, never a generated mockup.
var output := ""
var world: Sandpit
var player: WroughtwildPlayer
var checks := 0
var failures := 0

func _ready() -> void:
	get_window().size = Vector2i(1280,720)
	output = ProjectSettings.globalize_path("res://../build/codex-aesthetic/continuation")
	DirAccess.make_dir_recursive_absolute(output)
	world = preload("res://scenes/sandpit.tscn").instantiate()
	add_child(world)
	player = world.player
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	world.set_process(false)
	world.mob_packs.set_process(false)
	world.mob_packs.set_physics_process(false)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	player.position = Vector3(154.5,world.terrain.height_at(154,165)+1.05,165.5)
	player.rotation.y = -PI/2.0
	player.spring_arm.rotation.x = -0.08
	var hands := player.camera.get_node("FirstPersonHands") as FirstPersonHands
	await capture("first-person")
	player.combat.use_slot(1)
	hands.set_process(false)
	hands.sample(0.025)
	await capture("strike")
	# Show a real generated habitat patch, selected by instance count.
	hands.hide()
	player.hud.hide()
	var camera := Camera3D.new()
	add_child(camera)
	camera.make_current()
	var best: Node3D
	var count := -1
	var total := 0
	var totals := {}
	for chunk in world.terrain.chunks.values():
		var n := int(chunk.get_meta("habitat_count",0))
		total += n
		if n>count:
			best = chunk
			count = n
		for child in chunk.get_children():
			if String(child.name).begins_with("Habitat_"):
				totals[child.name] = int(totals.get(child.name,0))+child.multimesh.instance_count
	if best!=null and count>0:
		var target := Vector3.ZERO
		for child in best.get_children():
			if String(child.name).begins_with("Habitat_"):
				target = child.position
				break
		camera.position = target+Vector3(4,2.5,5)
		camera.look_at(target+Vector3(0,0.5,0))
		await capture("habitat")
	else:
		failures += 1
		printerr("FAIL: no habitat patch in generated world")
	for landmark in get_tree().get_nodes_in_group("landmarks"):
		var target: Vector3 = landmark.global_position
		camera.position = target+(Vector3(3.5,2.5,4.5) if landmark.look=="altar" else Vector3(5,3.2,7))
		camera.look_at(target+Vector3(0,0.7 if landmark.look=="altar" else 1.1,0))
		await capture("landmark-"+landmark.look)
	# Use actual pack actions and read-only comparison, with fixture gear only.
	player.camera.make_current()
	player.hud.show()
	var sim := player.inventory.get_sim()
	sim.add_material("iron_mace",1)
	sim.equip_from_inventory("iron_mace")
	var index := sim.roll_item_into_pack("frost_sceptre","wrought",2,117)
	player.inventory_panel.open_panel()
	await capture("equipment-pack")
	player.inventory_panel.compare_item(index)
	await capture("equipment-compare")
	get_window().size = Vector2i(1920,1080)
	await capture("equipment-compare-1080")
	print("CODEX_CONTINUATION_REVIEW ",JSON.stringify({"captures":checks,"failures":failures,"habitat_total":total,"habitat_kinds":totals,"densest_chunk":count,"terrain_build":world.terrain.build_profile}))
	get_tree().quit(0 if failures==0 else 1)

func capture(id: String) -> void:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(output.path_join(id+".png"))
	checks += 1
	if error!=OK:
		failures += 1
		printerr("FAIL: capture ",id)
