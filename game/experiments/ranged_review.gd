extends Node3D
## Frozen samples of normal enemy shot presentation in the generated world.
var output := ""

func _ready() -> void:
	get_window().size = Vector2i(1280,720)
	output = ProjectSettings.globalize_path("res://../build/codex-aesthetic/combat")
	DirAccess.make_dir_recursive_absolute(output)
	var world: Sandpit = preload("res://scenes/sandpit.tscn").instantiate()
	add_child(world)
	var player := world.player
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	world.set_process(false)
	world.mob_packs.set_process(false)
	world.mob_packs.set_physics_process(false)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	var origin := player.global_position
	var archer := Enemy.spawn(world, &"cinder_archer", origin + Vector3(-1,-0.9,-6))
	var wisp := Enemy.spawn(world, &"marsh_wisp", origin + Vector3(2,-0.9,-5))
	for enemy in [archer,wisp]:
		enemy.set_physics_process(false)
		enemy.state = "windup"
		enemy._windup_left = enemy.windup_seconds * 0.2
		enemy._shot_aim = player.global_position
		enemy.look_at(Vector3(origin.x,enemy.global_position.y,origin.z))
		enemy._update_shot_tell()
	player.rotation.y = 0
	player.spring_arm.rotation.x = -0.08
	player.hud.notify("Ranged attacks: sidestep the charge or the travelling shot; solid cover blocks it.")
	await capture("charge")
	for enemy in [archer,wisp]:
		enemy.state = "chase"
		enemy._update_shot_tell()
		var shot := EnemyProjectile.launch(enemy, player.global_position, enemy.projectile_rules)
		shot.set_physics_process(false)
		shot.advance(0.3)
	await capture("flight")
	print("CODEX_RANGED_REVIEW 2 captures")
	get_tree().quit()

func capture(id: String) -> void:
	for i in 5:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if get_viewport().get_texture().get_image().save_png(output.path_join(id+".png")) != OK:
		printerr("FAIL: screenshot ",id)
		get_tree().quit(1)
