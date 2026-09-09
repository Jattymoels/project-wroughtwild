extends "res://grove_base.gd"
## Compare the fauna in a copy of the approved grove. No world population or AI.
var gallery_actors: Dictionary = {}
var gallery_players: Dictionary = {}
var gallery_materials: Dictionary = {}
var placement_records: Array = []

func _build(role: String, at: Vector3, scale_value: float, yaw: float) -> void:
	var index := get_child_count()
	super._build(role, at, scale_value, yaw)
	if role == "boar": gallery_actors.boar = get_child(index)

func _ready() -> void:
	await super._ready()
	automatic = true
	for animal in ["wolf", "stag", "moth"]:
		var path: String = animal + "-mid.glb" if animal != "moth" else "moth.glb"
		var scene: PackedScene = load("res://" + path)
		var actor: Node3D = scene.instantiate()
		add_child(actor)
		gallery_actors[animal] = actor
		actor.rotation_degrees.y = -30
		var player: AnimationPlayer = actor.find_children("*", "AnimationPlayer", true, false)[0]
		gallery_players[animal] = player
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		player.play("idle")
		player.seek(0, true)
		player.advance(0)
		if animal != "moth":
			var settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://" + animal + ".json"))
			var mat := ShaderMaterial.new()
			mat.shader = load("res://fauna_scar.gdshader")
			for pair in [["base_texture","base.png"],["orm_texture","orm.png"],["normal_texture","normal.png"],["scar_texture","scar-mask.png"]]:
				mat.set_shader_parameter(pair[0], load("res://" + animal + "-" + pair[1]))
			for key in ["peak_emission","minimum_light","period_seconds","crest_width"]:
				mat.set_shader_parameter(key, settings.scar[key])
			var colour: Array = settings.scar.colour
			mat.set_shader_parameter("core_colour", Color(colour[0],colour[1],colour[2]).linear_to_srgb())
			mat.set_shader_parameter("use_normal_map", true)
			mat.set_shader_parameter("pulse_mode", 3)
			gallery_materials[animal] = mat
			for mesh in actor.find_children("*", "MeshInstance3D", true, false):
				if "candidate" in mesh.name: mesh.material_override = mat
			_place_on_flat_patch(animal, actor)
		else:
			actor.position = _ground(Vector3(2.65,0,4))
	for animal in gallery_actors: gallery_actors[animal].visible = false
	camera.fov = 50
	camera.position = _ground(Vector3(.1,0,-1)) + Vector3.UP * 1.65
	for animal in ["boar", "wolf", "stag", "moth"]:
		var actor: Node3D = gallery_actors[animal]
		actor.visible = true
		camera.look_at(actor.position + Vector3.UP * (1.35 if animal == "stag" else .72))
		for mood in ["day", "shade", "dusk"]:
			_lighting(mood)
			_time(1.6)
			for mat in gallery_materials.values(): mat.set_shader_parameter("scar_clock", 1.6)
			caption.text = "ART-03 / %s\n%s · approved grove comparison · eye height 1.65 m\nOriginal moth and boar retained · bloom off" % [animal.to_upper(), mood.capitalize()]
			await get_tree().process_frame
			await _save_frame(animal + "-" + mood)
		actor.visible = false
	_write("gallery.json", {"placements":placement_records,"views":records,"scope":"One animal at a time in a copy of ART-02. Moth GLB and materials unchanged. Flat-patch rest-pose support only; not terrain IK, native AI, world population or combat."})
	print("FAUNA_CAPTURES_OK")
	get_tree().quit()

func _place_on_flat_patch(animal: String, actor: Node3D) -> void:
	var rig: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://"+animal+"-rig-report.json"))
	var best_score := INF
	var best_at := Vector3.ZERO
	var best_spread := INF
	# Search the existing clearing; no terrain edit or collider override.
	for ix in range(-8,9):
		for iz in range(-8,9):
			var at := Vector3(2.65 + ix*.2,0,4.0 + iz*.2)
			var low := INF
			var high := -INF
			for foot in rig.feet:
				var local := Vector3(foot.foot[0],0,-foot.foot[1])
				var height := _ground(at + actor.basis * local).y
				low = minf(low,height)
				high = maxf(high,height)
			var score := high-low + Vector2(ix,iz).length()*.0005
			if score < best_score:
				best_score = score
				best_spread = high-low
				best_at = Vector3(at.x,high,at.z)
	assert(best_spread < .08, "No sufficiently level rest-pose patch")
	actor.position = best_at
	placement_records.append({"animal":animal,"position":str(best_at),"maximum_sole_gap_m":best_spread,"yaw_degrees":actor.rotation_degrees.y})
