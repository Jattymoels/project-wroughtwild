class_name BurningGround
extends Node3D
## An era mechanic (eras.json mob_mechanics.burning_ground): where such a
## mob dies, the ground burns for a while and a player standing in it takes
## fire through the sim's mitigation. Numbers come from the sim; this owns
## the clock, the patch and the look.

const TICK_SECONDS := 0.5

var damage_per_round := 0.0
var seconds := 0.0
var radius := 1.0
var round_seconds := 1.0
var _left := 0.0
var _tick_left := 0.0
var _mesh: MeshInstance3D


static func spawn(root: Node, at: Vector3, params: Dictionary, in_round_seconds: float) -> BurningGround:
	var patch := BurningGround.new()
	patch.damage_per_round = float(params.get("damage_per_round", 0.0))
	patch.seconds = float(params.get("seconds", 0.0))
	patch.radius = float(params.get("radius_m", 1.0))
	patch.round_seconds = maxf(in_round_seconds, 0.01)
	root.add_child(patch)
	patch.global_position = at
	patch.add_to_group("burning_ground")
	return patch


func _ready() -> void:
	_left = seconds
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.08
	disc.radial_segments = 12
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.45, 0.1, ForgeTell.LOOK.burning_ground_initial_alpha)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(1.0, 0.4, 0.05)
	material.emission_energy_multiplier = 2.5
	_mesh = MeshInstance3D.new()
	_mesh.mesh = disc
	_mesh.material_override = material
	_mesh.position = Vector3(0, 0.06, 0)
	add_child(_mesh)


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	if _mesh != null and seconds > 0.0:
		# The full radius still burns (or heals through Ashen Step) until expiry.
		# Fade the existing surface instead of advertising a smaller safe boundary.
		(_mesh.material_override as StandardMaterial3D).albedo_color.a = ForgeTell.LOOK.burning_ground_initial_alpha * clampf(_left / seconds, 0.0, 1.0)
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left = TICK_SECONDS
	var player := get_tree().get_first_node_in_group("player") as WroughtwildPlayer
	if player == null:
		return
	var to := player.global_position - global_position
	if absf(to.y) > 2.0:
		return
	to.y = 0.0
	if to.length() <= radius:
		# Ashen Step (a rail, D-023 slice 9): the ground is yours - it heals
		# by the sheet's number a second and never burns you.
		var heal: float = float(player.combat.sim.derived_stats().get("burning_ground_heal", 0.0))
		if heal > 0.0:
			player.combat.heal(heal * TICK_SECONDS)
		else:
			player.combat.take_hit(damage_per_round * TICK_SECONDS / round_seconds, "fire", "burning ground")
