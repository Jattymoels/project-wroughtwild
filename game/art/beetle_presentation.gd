class_name BeetlePresentation
extends FinishedFauna
## ART-06C Gloom Crawler. Native swarm, contact and clocks own the action.
const BEETLE_ROOT := "res://assets/authored/roster/gloom_crawler/"
const BEETLE_SHADER = preload("res://art/porcupine.gdshader")
static var _descriptor: Dictionary = {}
static var _beetle_scene: PackedScene
static var _beetle_material: ShaderMaterial

static func prepare_resources() -> void:
	_prepare_scene()
	_prepare_material()

static func _prepare_scene() -> void:
	if _descriptor.is_empty():
		_descriptor = JSON.parse_string(FileAccess.get_file_as_string(BEETLE_ROOT + "asset.json"))
	if _beetle_scene == null: _beetle_scene = load(_descriptor.model)

static func _prepare_material() -> void:
	if _beetle_material == null:
		_beetle_material = ShaderMaterial.new()
		_beetle_material.shader = BEETLE_SHADER
		for kind: String in _descriptor.maps:
			_beetle_material.set_shader_parameter(kind + "_texture", load(_descriptor.maps[kind]))
		for field: String in ["peak_emission", "minimum_light", "period_seconds", "crest_width", "pulse_mode"]:
			_beetle_material.set_shader_parameter(field, _descriptor.material[field])
		var colour: Array = _descriptor.material.core_colour_godot_Color
		_beetle_material.set_shader_parameter("core_colour", Color(colour[0], colour[1], colour[2]))
		var tint: Array = _descriptor.material.damage_tint_linear
		_beetle_material.set_shader_parameter("damage_tint", Vector3(tint[0], tint[1], tint[2]))

func setup(mesh: MeshInstance3D, owner_actor: Enemy, _config: Dictionary) -> void:
	actor = owner_actor
	var resource_began := Time.get_ticks_usec() if actor._arrival_tracing() else 0
	_prepare_scene()
	actor._note_arrival("adapter_scene",resource_began)
	var instance_began := Time.get_ticks_usec() if actor._arrival_tracing() else 0
	model = _beetle_scene.instantiate()
	add_child(model)
	rig = model.get_node(NodePath(_descriptor.nodes_relative_to_model_root.skeleton))
	player = model.get_node(NodePath(_descriptor.nodes_relative_to_model_root.animation_player))
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip: String in _descriptor.clips:
		player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR if _descriptor.clips[clip].loop else Animation.LOOP_NONE
	# Swarm has no legacy humanoid reduction; parent family/elite size applies once.
	fit_scale = float(_descriptor.fit.uniform_metres_per_source_unit)
	model.scale = Vector3.ONE * fit_scale
	model.rotation_degrees.y = float(_descriptor.fit.rotation_y_degrees)
	var offset: Array = _descriptor.fit.ground_offset_metres
	model.position = Vector3(offset[0], offset[1], offset[2])
	settings = {"stride_m": float(_descriptor.integration.cosmetic_stride_metres), "idle_clip": "idle"}
	actor._note_arrival("adapter_instance_rig_fit",instance_began)
	var material_began := Time.get_ticks_usec() if actor._arrival_tracing() else 0
	_prepare_material()
	actor._note_arrival("adapter_material",material_began)
	material = _beetle_material.duplicate()
	var part: MeshInstance3D = model.get_node(NodePath(_descriptor.nodes_relative_to_model_root.mesh))
	part.material_override = material
	part.extra_cull_margin = float(_descriptor.fit.extra_cull_margin_source_units)
	var phase := fposmod(actor.global_position.x * 2.17 + actor.global_position.z * .73, 1.0)
	part.set_instance_shader_parameter("phase_offset", phase)
	stride = phase
	clock = phase * float(_descriptor.clips.idle.duration_seconds)
	mesh.layers = 0
	mesh.material_overlay = null
	mesh.skin = null
	_seek("idle", phase)
	refresh_status()
	add_to_group("transient_actor_presentations")

func reset_transient_pose() -> void:
	(get_parent() as CreatureMotion).release_left = 0.0
	_seek("idle", 0.0)
