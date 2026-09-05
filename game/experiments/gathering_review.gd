extends Node3D
## Real generated meadow and normal work HUD; AI paused for repeatable captures.
var player: WroughtwildPlayer
var output := ""

func _ready() -> void:
	get_window().size = Vector2i(1280,720)
	output = ProjectSettings.globalize_path("res://../build/codex-aesthetic/gathering")
	DirAccess.make_dir_recursive_absolute(output)
	var world: Sandpit = preload("res://scenes/sandpit.tscn").instantiate()
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
	var closest: ResourceNode
	var distance := INF
	for candidate in world.terrain.nodes_root.get_children():
		if candidate.visual != &"tree":
			continue
		var d: float = candidate.global_position.distance_squared_to(player.global_position)
		if d < distance:
			distance = d
			closest = candidate
	if closest == null:
		printerr("FAIL: no generated tree")
		get_tree().quit(1)
		return
	player.global_position = closest.global_position + Vector3(0,1.1,2.1)
	player.rotation.y = 0
	player.spring_arm.rotation.x = -0.12
	for i in 4:
		await get_tree().physics_frame
	if player.aim_probe().target != closest:
		printerr("FAIL: review ray must hit the actual tree")
		get_tree().quit(1)
		return
	player.interact()
	await get_tree().create_timer(0.25).timeout
	player.interact()
	await get_tree().create_timer(0.25).timeout
	player.interact()
	var hands := player.camera.get_node("FirstPersonHands") as FirstPersonHands
	hands.set_process(false)
	hands.sample(0.03)
	for burst in get_tree().get_nodes_in_group("gathering_impacts"):
		burst._process(0.07)
		burst.set_process(false)
	await capture("chopping")
	get_window().size = Vector2i(1920,1080)
	await capture("chopping-1080")
	get_window().size = Vector2i(1280,720)
	for burst in get_tree().get_nodes_in_group("gathering_impacts"):
		burst.queue_free()
	for i in range(closest.drive_progress,closest.drive_presses):
		player._apply_work(closest,closest.work(player.inventory.get_sim()))
	await get_tree().create_timer(1.4).timeout
	await capture("collected")
	print("CODEX_GATHERING_REVIEW 3 captures")
	get_tree().quit()

func capture(id: String) -> void:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if get_viewport().get_texture().get_image().save_png(output.path_join(id+".png")) != OK:
		printerr("FAIL: screenshot ", id)
		get_tree().quit(1)
