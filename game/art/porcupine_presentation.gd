class_name PorcupinePresentation
extends FinishedFauna
## Only the ART-06C Cinder Archer. Native clocks and A2's sampler are reused.
const PORCUPINE_ROOT := "res://assets/authored/porcupine/"
const PORCUPINE_SHADER = preload("res://art/porcupine.gdshader")
static var _porcupine_scene: PackedScene
static var _porcupine_material: ShaderMaterial
var face_materials: Array[StandardMaterial3D] = []
var face_colours: Array[Color] = []

func setup(mesh: MeshInstance3D, owner_actor: Enemy, config: Dictionary) -> void:
	actor = owner_actor
	settings = config
	if _porcupine_scene == null:
		_porcupine_scene = load(PORCUPINE_ROOT + "porcupine.glb")
	model = _porcupine_scene.instantiate()
	add_child(model)
	rig = model.find_children("*", "Skeleton3D", true, false)[0]
	player = model.find_children("*", "AnimationPlayer", true, false)[0]
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	# Explicit uniform studio conversion: never fit a quadruped into the old capsule.
	fit_scale = float(config.uniform_scale)
	model.scale = Vector3.ONE * fit_scale
	model.rotation_degrees.y = float(config.yaw_degrees)
	model.position = Vector3(0, float(config.ground_offset), float(config.forward_offset))
	if _porcupine_material == null:
		_porcupine_material = ShaderMaterial.new()
		_porcupine_material.shader = PORCUPINE_SHADER
		var entry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PORCUPINE_ROOT + "manifest.json"))
		for kind in entry.maps:
			_porcupine_material.set_shader_parameter(kind + "_texture", load(PORCUPINE_ROOT + entry.maps[kind]))
		for field in ["peak_emission", "minimum_light", "period_seconds", "crest_width"]:
			_porcupine_material.set_shader_parameter(field, entry.scar[field])
		var c: Array = entry.scar.colour
		_porcupine_material.set_shader_parameter("core_colour", Color(c[0],c[1],c[2]).linear_to_srgb())
	material = _porcupine_material.duplicate()
	var phase := fposmod(actor.global_position.x * 2.17 + actor.global_position.z * 0.73, 1.0)
	for part: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		part.extra_cull_margin = float(config.cull_margin_m)
		if "runtime_host" in String(part.name) or "runtime host" in String(part.name):
			part.material_override = material
			part.set_instance_shader_parameter("phase_offset", phase)
		else:
			# Eye/whisker surfaces have no scar atlas and never emit light.
			var face := part.mesh.surface_get_material(0).duplicate() as StandardMaterial3D
			face.emission_enabled = false
			face_materials.append(face)
			face_colours.append(face.albedo_color)
			part.material_override = face
	mesh.layers = 0
	mesh.material_overlay = null
	mesh.skin = null
	_seek("idle", 0.0)
	refresh_status()

func refresh_status() -> void:
	super.refresh_status()
	var priority := actor.is_frozen() or actor._flash_left > 0.0 or actor.burning_left > 0.0 or actor.bleeding_left > 0.0
	for i in face_materials.size():
		face_materials[i].albedo_color = face_colours[i].lerp(actor._material.albedo_color, 0.65) if priority else face_colours[i]
