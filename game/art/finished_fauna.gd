class_name FinishedFauna
extends Node3D
## ART-01/03 presentation adapter. Actor state remains authoritative.
const ROOT := "res://assets/authored/fauna/"
const SHADER = preload("res://art/finished_fauna.gdshader")
static var _assets: Dictionary = {}
static var _scenes: Dictionary = {}
static var _materials: Dictionary = {}
var actor: Enemy
var rig: Skeleton3D
var player: AnimationPlayer
var material: ShaderMaterial
var model: Node3D
var settings: Dictionary
var pose := ""
var clock := 0.0
var stride := 0.0
var fit_scale := 1.0

## Run inside the real synchronous New World / Continue build, before the
## player can move. Retain only the three already shared fitted-fauna families.
## Standalone/test actors retain lazy setup through these same resource helpers.
static func prepare_world(trace: Node = null) -> void:
	var began := Time.get_ticks_usec() if is_instance_valid(trace) and trace.active else 0
	for definition: Dictionary in RecoveredActorArt.definitions().values():
		if not definition.has("finished"): continue
		var family: String = definition.finished.family
		var step := Time.get_ticks_usec() if began > 0 else 0
		_scene_for(family)
		if began > 0: trace.note_arrival("fauna_prepare_model",step,{"family":family})
		step = Time.get_ticks_usec() if began > 0 else 0
		_material_for(family,trace)
		if began > 0: trace.note_arrival("fauna_prepare_material",step,{"family":family})
		step = Time.get_ticks_usec() if began > 0 else 0
		# Enemy.configure still uses this shared fallback before attaching the
		# finished model. Prepare its first-use construction in loading too.
		preload("res://art/character_look.tres").build(String(definition.role))
		if began > 0: trace.note_arrival("fauna_prepare_fallback",step,{"family":family})
	if began > 0: trace.note_arrival("fauna_world_preparation",began)

static func resources_ready() -> bool:
	for definition: Dictionary in RecoveredActorArt.definitions().values():
		if definition.has("finished"):
			var family: String = definition.finished.family
			if not _scenes.has(family) or not _materials.has(family): return false
	return true

static func _scene_for(family: String) -> PackedScene:
	if not _scenes.has(family): _scenes[family] = load(ROOT + family + ".glb")
	return _scenes[family]

static func _material_for(family: String, trace: Node = null) -> ShaderMaterial:
	if _assets.is_empty():
		_assets = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "manifest.json")).models
	if not _materials.has(family):
		var source := ShaderMaterial.new()
		source.shader = SHADER
		var entry: Dictionary = _assets[family]
		for kind in entry.maps:
			var began := Time.get_ticks_usec() if is_instance_valid(trace) and trace.active else 0
			source.set_shader_parameter(kind + "_texture", load(ROOT + entry.maps[kind]))
			if began > 0: trace.note_arrival("fauna_prepare_texture",began,{"family":family,"map":kind})
		for field in ["peak_emission", "minimum_light", "period_seconds", "crest_width"]:
			source.set_shader_parameter(field, entry.scar[field])
		var colour: Array = entry.scar.colour
		source.set_shader_parameter("core_colour", Color(colour[0], colour[1], colour[2]).linear_to_srgb())
		source.set_shader_parameter("use_normal_map", true)
		source.set_shader_parameter("normal_strength", 1.0 if family == "boar" else 0.65)
		_materials[family] = source
	return _materials[family]

func setup(mesh: MeshInstance3D, owner_actor: Enemy, config: Dictionary) -> void:
	actor = owner_actor
	settings = config
	var began := Time.get_ticks_usec() if actor._arrival_tracing() else 0
	var family: String = config.family
	_scene_for(family)
	actor._note_arrival("fauna_model_acquire",began)
	began = Time.get_ticks_usec() if began > 0 else 0
	model = _scenes[family].instantiate()
	actor._note_arrival("fauna_instantiate",began)
	began = Time.get_ticks_usec() if began > 0 else 0
	add_child(model)
	actor._note_arrival("fauna_register",began)
	began = Time.get_ticks_usec() if began > 0 else 0
	rig = model.find_children("*", "Skeleton3D", true, false)[0]
	player = model.find_children("*", "AnimationPlayer", true, false)[0]
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	# Same uniform, grounded envelope fit as ART-05, in pre-family/elite space.
	var bounds := AABB()
	var first := true
	for part: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var local: Transform3D = model.global_transform.affine_inverse() * part.global_transform
		var box: AABB = local * part.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	var target := mesh.get_aabb()
	fit_scale = minf(target.size.x / bounds.size.x, minf(target.size.y / bounds.size.y, target.size.z / bounds.size.z))
	model.scale = Vector3.ONE * fit_scale
	model.position = Vector3(target.get_center().x - bounds.get_center().x * fit_scale,
		-bounds.position.y * fit_scale, target.get_center().z - bounds.get_center().z * fit_scale)
	actor._note_arrival("fauna_rig_bounds_fit",began)
	began = Time.get_ticks_usec() if began > 0 else 0
	_material_for(family)
	actor._note_arrival("fauna_material_acquire",began)
	began = Time.get_ticks_usec() if began > 0 else 0
	material = _materials[family].duplicate()
	# Existing hosts retain their channel identity and native tell colours.
	if not actor.influence.is_empty():
		material.set_shader_parameter("core_colour", FrontierHostLook.PALETTE[actor.influence])
	var phase := fposmod(actor.global_position.x * 2.17 + actor.global_position.z * 0.73, 1.0)
	for part: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		part.material_override = material
		part.set_instance_shader_parameter("phase_offset", phase)
		part.extra_cull_margin = float(config.cull_margin_m)
	# Hide only the old surface, keeping its envelope/scale and label contract.
	# Children remain visible. No second Skeleton or procedural pose driver runs.
	mesh.layers = 0
	mesh.material_overlay = null
	mesh.skin = null
	actor._note_arrival("fauna_material_assign",began)
	began = Time.get_ticks_usec() if began > 0 else 0
	_seek("idle", 0.0)
	refresh_status()
	actor._note_arrival("fauna_initial_seek",began)

func _seek(clip: String, fraction: float) -> void:
	if pose != clip:
		player.play(clip)
		pose = clip
	player.seek(clampf(fraction, 0.0, 1.0) * player.get_animation(clip).length, true)
	player.advance(0.0)

func sample(delta: float, travel: float, windup: float, frozen: bool, stagger: bool, release_left: float) -> void:
	if actor.life <= 0.0 or actor.is_queued_for_deletion(): return
	clock += delta
	material.set_shader_parameter("scar_clock", clock)
	refresh_status()
	if frozen: return
	if stagger:
		_seek("idle", 0.0)
		return
	if actor.state in ["windup", "release_warning"] and player.has_animation("windup"):
		_seek("windup", 1.0 if actor.state == "release_warning" else windup)
	elif actor.state == "release" and player.has_animation("release"):
		_seek("release", 1.0 - actor._release_left / maxf(actor.release_seconds, 0.001))
	elif release_left > 0.0 and player.has_animation("release"):
		_seek("release", 1.0 - release_left / preload("res://art/creature_motion.tres").release_seconds)
	elif travel > 0.0001:
		# Family/elite scaling changes leg length once, without changing movement.
		stride += travel / maxf(actor._mesh.scale.x * float(settings.stride_m), 0.001)
		_seek("walk", fposmod(stride, 1.0))
	else:
		var idle_clip: String = settings.idle_clip if actor.state == "idle" else "idle"
		_seek(idle_clip, fposmod(clock / player.get_animation(idle_clip).length, 1.0))

func refresh_status() -> void:
	var priority := actor.is_frozen() or actor._flash_left > 0.0 or actor.burning_left > 0.0 or actor.bleeding_left > 0.0
	var tint := actor._material.albedo_color
	material.set_shader_parameter("status_tint", Color(tint.r, tint.g, tint.b, 0.65 if priority else 0.0))
	material.set_shader_parameter("status_active", priority)
	material.set_shader_parameter("status_emission", actor._material.emission * actor._material.emission_energy_multiplier if priority and actor._material.emission_enabled else Color.BLACK)
