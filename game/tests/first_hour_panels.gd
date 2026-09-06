extends Node3D
## Matched presentation fixture; supplied stock is for panel review, never
## evidence of the empty-inventory journey in first_hour_journey.gd.
var player: WroughtwildPlayer
var output: String
var failures := 0
var captures := 0

func snap(label: String) -> void:
	for i in 12: await get_tree().process_frame
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var path := output.path_join(label+".png")
	if get_viewport().get_texture().get_image().save_png(path) != OK: failures += 1
	captures += 1
	print("CODEX_FIRST_HOUR_CAPTURE ",path)

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	output = ProjectSettings.globalize_path("res://../captures")
	DirAccess.make_dir_recursive_absolute(output)
	var world: Sandpit = preload("res://scenes/sandpit.tscn").instantiate()
	world.world_seed = 77
	add_child(world)
	player = world.player
	player.class_panel.choose("warden")
	world.set_physics_process(false)
	world.mob_packs.set_physics_process(false)
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.combat.set_physics_process(false)
	var sim := player.inventory.get_sim()
	sim.add_materials({"wood":35,"fieldstone":6,"split_stone":4,"stone":2,"iron_ore":8,"iron_ingot":2,"timber_frame":1,"hide":8,"workbench_kit":1})
	sim.add_station("workbench")
	var bench: StationSite = preload("res://scenes/station_site.tscn").instantiate()
	bench.station_id = &"workbench"
	bench.upgrade_station_id = &""
	add_child(bench)
	bench.global_position = player.global_position+Vector3(2,-1.2,-2)
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		get_window().size = resolution
		var suffix := "-%d" % resolution.y
		player.work_panel.open_crafting(bench)
		player.work_panel.catalogue.select_recipe("forge_kit")
		await snap("forge-kit"+suffix)
		player.work_panel.catalogue.select_recipe("simple_bow")
		await snap("equipment"+suffix)
		player.work_panel.close_panel()
		player.inventory_panel.open_panel()
		player.inventory_panel.show_guide(false)
		await snap("pack"+suffix)
		player.inventory_panel.show_guide(true)
		await snap("guide"+suffix)
		player.inventory_panel.close_panel()
		player.placement.set_build_mode_enabled(true)
		player.build_palette.open_panel()
		player.build_palette.select_entry(&"floor_slab")
		await snap("building"+suffix)
		player.build_palette.close_panel()
		player.placement.set_build_mode_enabled(false)
		player.foundry_panel.open_panel()
		await snap("foundry"+suffix)
		player.foundry_panel.close_panel()
	print("CODEX_FIRST_HOUR_PANELS %d captures, %d failures" % [captures,failures])
	get_tree().quit(0 if failures == 0 else 1)
