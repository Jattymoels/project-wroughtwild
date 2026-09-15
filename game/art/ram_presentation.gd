class_name RamPresentation
extends FinishedFauna
## Approved ram skin on the native Stone Husk. Poses never grant guard or damage.
const RAM_ROOT := "res://assets/authored/roster/stone_husk/"
const RAM_SHADER = preload("res://art/porcupine.gdshader")
static var _descriptor: Dictionary = {}
static var _ram_scene: PackedScene
static var _ram_material: ShaderMaterial
var _rest_pose := ""
var _rest_from: Array[Transform3D] = []
var _blend_age := 0.0

func setup(mesh: MeshInstance3D, owner_actor: Enemy, _config: Dictionary) -> void:
	actor = owner_actor
	if _descriptor.is_empty():
		_descriptor = JSON.parse_string(FileAccess.get_file_as_string(RAM_ROOT + "asset.json"))
	if _ram_scene == null: _ram_scene = load(_descriptor.model)
	model = _ram_scene.instantiate()
	add_child(model)
	rig = model.get_node(NodePath(_descriptor.nodes_relative_to_model_root.skeleton))
	player = model.get_node(NodePath(_descriptor.nodes_relative_to_model_root.animation_player))
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip: String in _descriptor.clips:
		player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR if _descriptor.clips[clip].loop else Animation.LOOP_NONE
	# Enemy has already applied its legacy humanoid reduction. Undo it only in
	# presentation, leaving native collider and subsequent family/elite size intact.
	var legacy_scale: float = float(_descriptor.integration.legacy_mesh_scale)
	fit_scale = float(_descriptor.fit.uniform_metres_per_source_unit) / legacy_scale
	model.scale = Vector3.ONE * fit_scale
	model.rotation_degrees.y = float(_descriptor.fit.rotation_y_degrees)
	var offset: Array = _descriptor.fit.ground_offset_metres
	model.position = Vector3(offset[0], offset[1], offset[2]) / legacy_scale
	settings = {"stride_m": float(_descriptor.integration.suggested_cosmetic_stride_metres_before_family_scale) / legacy_scale}
	if _ram_material == null:
		_ram_material = ShaderMaterial.new()
		_ram_material.shader = RAM_SHADER
		for kind: String in _descriptor.maps:
			_ram_material.set_shader_parameter(kind + "_texture", load(_descriptor.maps[kind]))
		for field: String in ["peak_emission", "minimum_light", "period_seconds", "crest_width", "pulse_mode"]:
			_ram_material.set_shader_parameter(field, _descriptor.material[field])
		var colour: Array = _descriptor.material.core_colour_godot_Color
		_ram_material.set_shader_parameter("core_colour", Color(colour[0], colour[1], colour[2]))
		var tint: Array = _descriptor.material.damage_tint_linear
		_ram_material.set_shader_parameter("damage_tint", Vector3(tint[0], tint[1], tint[2]))
	material = _ram_material.duplicate()
	var part: MeshInstance3D = model.get_node(NodePath(_descriptor.nodes_relative_to_model_root.mesh))
	part.material_override = material
	part.extra_cull_margin = float(_descriptor.fit.extra_cull_margin_source_units)
	part.set_instance_shader_parameter("phase_offset", fposmod(actor.global_position.x * 2.17 + actor.global_position.z * .73, 1.0))
	mesh.layers = 0
	mesh.material_overlay = null
	mesh.skin = null
	_seek("idle", 0.0)
	refresh_status()
	add_to_group("transient_actor_presentations")

func reset_transient_pose() -> void:
	(get_parent() as CreatureMotion).release_left = 0.0
	_rest_pose = ""
	_rest_from.clear()
	_seek("idle", 0.0)

func sample(delta: float, travel: float, windup: float, frozen: bool, stagger: bool, release_left: float) -> void:
	if actor.life <= 0.0 or actor.is_queued_for_deletion(): return
	clock += delta
	material.set_shader_parameter("scar_clock", clock)
	refresh_status()
	if frozen: return
	if stagger:
		_rest_pose = ""
		_rest_from.clear()
		_seek("idle", 0.0)
		return
	if actor.state in ["windup", "release_warning"]:
		_seek("windup", 1.0 if actor.state == "release_warning" else windup)
	elif actor.state == "release":
		_seek("release", 1.0 - actor._release_left / maxf(actor.release_seconds, .001))
	elif release_left > 0.0:
		# Fit the authored recovery into the existing cosmetic release window.
		_seek("release", 1.0 - release_left / preload("res://art/creature_motion.tres").release_seconds)
	elif travel > .0001:
		stride += travel / maxf(actor._mesh.scale.x * float(settings.stride_m), .001)
		_seek("walk", fposmod(stride, 1.0))
	else:
		_rest("guard" if actor.state == "chase" else "idle", delta)
		return
	_rest_pose = ""
	_rest_from.clear()

func _rest(clip: String, delta: float) -> void:
	if clip != _rest_pose:
		_rest_from.clear()
		if _rest_pose != "":
			for i in rig.get_bone_count(): _rest_from.append(rig.get_bone_pose(i))
		_rest_pose = clip
		_blend_age = 0.0
	_seek(clip, fposmod(clock / player.get_animation(clip).length, 1.0))
	_blend_age += delta
	var amount := clampf(_blend_age / float(_descriptor.integration.guard_blend_seconds), 0.0, 1.0)
	for i in _rest_from.size():
		var blended := _rest_from[i].interpolate_with(rig.get_bone_pose(i), amount)
		rig.set_bone_pose_position(i, blended.origin)
		rig.set_bone_pose_rotation(i, blended.basis.get_rotation_quaternion())
		rig.set_bone_pose_scale(i, blended.basis.get_scale())
	if amount >= 1.0: _rest_from.clear()
