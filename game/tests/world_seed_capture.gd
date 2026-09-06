extends SceneTree
## Render the actual normal startup path without clicking, generating terrain,
## or writing a save. Use only the review project with an isolated user directory.
class PreparingWorld extends Sandpit:
	func start_chosen_world(_seed_value: int) -> bool: return false

func _initialize() -> void:
	_capture.call_deferred()

func _capture() -> void:
	root.size = Vector2i(1280,720)
	var world := preload("res://scenes/sandpit.tscn").instantiate() as Sandpit
	var preparing_view := OS.get_cmdline_user_args().has("--preparing-view")
	if preparing_view: world.set_script(PreparingWorld)
	root.add_child(world)
	current_scene = world
	for frame in 20: await process_frame
	if not world.player.class_panel.is_open() or not world.terrain.map.is_empty() or world.seed_controls==null:
		printerr("FAIL: normal rendered launch did not reach the pre-generation chooser")
		quit(1)
		return
	if preparing_view:
		# Register first: capture the actual feedback frame before the startup
		# coroutine can call this probe's controlled generation refusal.
		RenderingServer.frame_post_draw.connect(_capture_preparing.bind(world),CONNECT_ONE_SHOT)
		world.player.class_panel.choose("warden")
		return
	await RenderingServer.frame_post_draw
	var output := "res://../../seed-chooser.png"
	var result := root.get_texture().get_image().save_png(output)
	print("WORLD_SEED_CAPTURE: chooser visible, terrain empty, save untouched; image error=",result)
	quit(0 if result==OK else 1)

func _capture_preparing(world: Sandpit) -> void:
	if not world.seed_controls.loading or not world.seed_controls._preparing.is_visible_in_tree() or not world.terrain.map.is_empty():
		printerr("FAIL: Preparing feedback was not rendered before generation")
		quit(1)
		return
	var result := root.get_texture().get_image().save_png("res://../../seed-preparing.png")
	print("WORLD_SEED_CAPTURE: Preparing frame rendered before controlled generation, save untouched; image error=",result)
	quit(0 if result==OK else 1)
