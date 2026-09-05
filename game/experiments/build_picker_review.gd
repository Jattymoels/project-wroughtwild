extends "res://experiments/building_review.gd"
## Normal building inspection with the actual player catalogue over it.
func review_id() -> String:
	return "build-picker"

func _capture(id: String) -> void:
	if id == "interior":
		get_window().size = Vector2i(1280,720)
		camera.make_current()
		player.hud.hide()
		player.class_panel.choose("warden")
		player.build_palette.open_panel()
		player.build_palette.group = "Corners & roofs"
		player.build_palette.select_entry(&"codex_roof_hip")
		player.build_palette.turn(1)
		caption.hide()
		await super._capture("palette-720")
		get_window().size = Vector2i(1920,1080)
		await super._capture("palette-1080")
		get_window().size = Vector2i(1280,720)
		player.build_palette.close_panel()
	elif id == "entrance":
		get_window().size = Vector2i(1280,720)
		player.position = Vector3(7,2,-4)
		player.rotation.y = PI
		player.spring_arm.rotation.x = -0.25
		player.camera.make_current()
		player.hud.show()
		player.placement.set_build_mode_enabled(true)
		player.placement.select_shape(&"codex_roof_hip")
		for i in 3:
			await get_tree().physics_frame
		player.placement._update_preview()
		player.hud.refresh()
		player.hud._refresh_crosshair()
		caption.hide()
		await super._capture("placement")
	else:
		await super._capture(id)
