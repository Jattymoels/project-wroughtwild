class_name CranePresentation
extends FinishedFauna
## The native recruiter owns all effects; these clocks only pose its approved skin.
const CRANE_ROOT := "res://assets/authored/roster/shrieker/"
# Same ART-06C texture-preserving scar math, with native status priority added.
const CRANE_SHADER = preload("res://art/porcupine.gdshader")
static var _descriptor: Dictionary = {}
static var _crane_scene: PackedScene
static var _crane_material: ShaderMaterial
var call_age := -1.0
var peck_age := -1.0
var call_visible := false
var _call_bones: Array[int] = []

static func prepare_resources() -> void:
	_prepare_scene()
	_prepare_material()

static func _prepare_scene() -> void:
	if _descriptor.is_empty():
		_descriptor = JSON.parse_string(FileAccess.get_file_as_string(CRANE_ROOT + "asset.json"))
	if _crane_scene == null:
		_crane_scene = load(CRANE_ROOT + _descriptor.model)

static func _prepare_material() -> void:
	if _crane_material == null:
		_crane_material = ShaderMaterial.new()
		_crane_material.shader = CRANE_SHADER
		for kind: String in _descriptor.maps:
			_crane_material.set_shader_parameter(kind + "_texture", load(CRANE_ROOT + _descriptor.maps[kind]))
		for field: String in ["peak_emission", "minimum_light", "period_seconds", "crest_width", "pulse_mode"]:
			_crane_material.set_shader_parameter(field, _descriptor.material[field])
		var colour: Array = _descriptor.material.core_colour
		_crane_material.set_shader_parameter("core_colour", Color(colour[0], colour[1], colour[2]))
		var tint: Array = _descriptor.material.damage_tint
		_crane_material.set_shader_parameter("damage_tint", Vector3(tint[0], tint[1], tint[2]))

func setup(mesh: MeshInstance3D, owner_actor: Enemy, config: Dictionary) -> void:
	actor = owner_actor
	var resource_began := Time.get_ticks_usec() if actor._arrival_tracing() else 0
	_prepare_scene()
	actor._note_arrival("adapter_scene",resource_began)
	var instance_began := Time.get_ticks_usec() if actor._arrival_tracing() else 0
	model = _crane_scene.instantiate()
	add_child(model)
	rig = model.get_node(NodePath(_descriptor.skeleton_path))
	player = model.get_node(NodePath(_descriptor.animation_player_path))
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip: String in _descriptor.clips:
		player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR if _descriptor.clips[clip].loop else Animation.LOOP_NONE
	fit_scale = float(_descriptor.fit.uniform_scale)
	model.scale = Vector3.ONE * fit_scale
	var rotation: Array = _descriptor.fit.rotation_degrees
	var offset: Array = _descriptor.fit.ground_offset
	model.rotation_degrees = Vector3(rotation[0], rotation[1], rotation[2])
	model.position = Vector3(offset[0], offset[1], offset[2])
	settings = {"stride_m": float(_descriptor.walk_cycle_travel_source_units) * fit_scale, "idle_clip": "idle"}
	actor._note_arrival("adapter_instance_rig_fit",instance_began)
	var material_began := Time.get_ticks_usec() if actor._arrival_tracing() else 0
	_prepare_material()
	actor._note_arrival("adapter_material",material_began)
	material = _crane_material.duplicate()
	var phase := fposmod(actor.global_position.x * 2.17 + actor.global_position.z * 0.73, 1.0)
	for part: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		part.material_override = material
		part.set_instance_shader_parameter("phase_offset", phase)
		part.extra_cull_margin = float(config.cull_margin_m)
	for bone: String in _descriptor.playback.call_upper_body_bones:
		_call_bones.append(rig.find_bone(bone))
	mesh.layers = 0
	mesh.material_overlay = null
	mesh.skin = null
	actor.recruitment_called.connect(_called)
	actor.attack_released.connect(_struck)
	_seek("idle", 0.0)
	refresh_status()
	add_to_group("transient_actor_presentations")

func reset_transient_pose() -> void:
	call_age = -1.0
	peck_age = -1.0
	call_visible = false
	_seek("idle", 0.0)

func _called() -> void:
	if actor.life > 0.0 and not actor.is_queued_for_deletion(): call_age = 0.0

func _struck(kind: String) -> void:
	if kind == "strike" and actor.life > 0.0: peck_age = 0.0

func sample(delta: float, travel: float, windup: float, frozen: bool, stagger: bool, _release_left: float) -> void:
	call_visible = false
	if actor.life <= 0.0 or actor.is_queued_for_deletion():
		call_age = -1.0
		peck_age = -1.0
		return
	clock += delta
	material.set_shader_parameter("scar_clock", clock)
	refresh_status()
	if call_age >= 0.0:
		call_age += delta
		if call_age >= player.get_animation("call").length: call_age = -1.0
	if peck_age >= 0.0:
		peck_age += delta
		if peck_age >= player.get_animation("release").length: peck_age = -1.0
	if frozen:
		peck_age = -1.0
		return # Hold exact bones; an obscured call expires rather than queuing.
	if stagger:
		call_age = -1.0
		peck_age = -1.0
		_seek("idle", 0.0)
		return
	if actor.state == "windup":
		_seek("windup", windup)
		return
	if peck_age >= 0.0:
		_seek("release", peck_age / player.get_animation("release").length)
		return
	# Sample the exported call on this skeleton, then retain only its five upper
	# body local poses. The complete idle/walk clip restores all other bones.
	var upper: Array[Transform3D] = []
	if call_age >= 0.0:
		_seek("call", call_age / player.get_animation("call").length)
		for bone: int in _call_bones: upper.append(rig.get_bone_pose(bone))
	if travel > 0.0001:
		stride += travel / maxf(actor._mesh.scale.x * float(settings.stride_m), 0.001)
		_seek("walk", fposmod(stride, 1.0))
	else:
		_seek("idle", fposmod(clock / player.get_animation("idle").length, 1.0))
	for i in upper.size():
		var bone := _call_bones[i]
		rig.set_bone_pose_position(bone, upper[i].origin)
		rig.set_bone_pose_rotation(bone, upper[i].basis.get_rotation_quaternion())
		rig.set_bone_pose_scale(bone, upper[i].basis.get_scale())
	call_visible = not upper.is_empty()
