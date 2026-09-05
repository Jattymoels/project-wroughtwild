class_name FoundryPuff
extends Node3D
## Small cosmetic pressure releases. One shared limit, no lights or child procs.
var elapsed := 0.0
var cloud := false
var radius := 1.0
var pieces: Array[MeshInstance3D] = []
var material: ShaderMaterial

static func spawn(combat: PlayerCombat, at: Vector3, size: float, steam: bool) -> void:
	if combat.get_tree().get_nodes_in_group("foundry_puffs").size() >= int(SkillBurst.LOOK.max_cast_effects): return
	var puff := FoundryPuff.new()
	puff.cloud = steam
	puff.radius = size
	combat.player.world_root().add_child(puff)
	puff.global_position = at
	combat.died.connect(puff.queue_free)

func _ready() -> void:
	add_to_group("foundry_puffs")
	material = ShaderMaterial.new()
	material.shader = preload("res://art/foundry_vapour.gdshader")
	material.set_shader_parameter("tint", Color("a8bdb8") if cloud else Color("ed782e"))
	var mesh := SphereMesh.new()
	mesh.radial_segments = 16
	mesh.rings = 8
	for i in 7:
		var part := MeshInstance3D.new()
		part.mesh = mesh
		part.material_override = material
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pieces.append(part)
		add_child(part)
	_sample()

func _process(delta: float) -> void:
	elapsed += maxf(delta, 0)
	if elapsed >= 0.65:
		queue_free()
		return
	_sample()

func _sample() -> void:
	var progress := elapsed / 0.65
	material.set_shader_parameter("opacity", (0.22 if cloud else 0.7) * (1.0 - progress))
	for i in pieces.size():
		var angle := TAU * i / pieces.size()
		var spread := radius * (0.12 + progress * (0.25 if cloud else 0.65))
		pieces[i].position = Vector3(cos(angle) * spread, progress * (1.4 if cloud else 0.2) + (i % 3) * 0.11, sin(angle) * spread)
		pieces[i].scale = Vector3(0.65,1.3,0.65) * radius * (0.2 + progress * 0.5) if cloud else Vector3.ONE * radius * (0.12 - progress * 0.1)
