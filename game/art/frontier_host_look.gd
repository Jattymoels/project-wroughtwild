class_name FrontierHostLook
extends Node3D
## Prototype adapter over the existing rig; no edits to concurrent source art.
const SCAR = preload("res://art/frontier_scar.gdshader")
const PALETTE = {"red": Color("f17443"), "blue": Color("77c5ed"), "white": Color("ebe4bf"), "green": Color("8ec781")}
## Ambient cycle/contrast and warning stroke are presentation tuning only.
@export var pulse_seconds := 3.5
@export var scar_low := 0.35
@export var scar_high := 0.8
@export var tell_width := 0.07
var actor: Enemy
var clock := 0.0
var tell: MeshInstance3D
var scar: ShaderMaterial

static func attach(host: Enemy) -> void:
	var old := host.get_node_or_null("FrontierHostLook")
	if old != null: old.free()
	var look := FrontierHostLook.new()
	look.name = "FrontierHostLook"
	look.actor = host
	host.add_child(look)
	look._build()

func _build() -> void:
	var colour: Color = PALETTE[actor.influence]
	var source: StandardMaterial3D = RecoveredActorArt._materials.get(actor.visual_id)
	if source != null and source.emission_texture != null:
		scar = ShaderMaterial.new()
		scar.shader = SCAR
		scar.set_shader_parameter("scar_mask", source.emission_texture)
		scar.set_shader_parameter("scar_colour", colour)
		actor._mesh.material_overlay = scar
	if actor.release_shape.is_empty(): return
	tell = MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = colour
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = false
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	var points := PackedVector3Array()
	if actor.release_shape == "radial":
		for i in 65:
			var angle := TAU * float(i) / 64.0
			points.append(Vector3(sin(angle), 0, cos(angle)) * actor.release_radius)
	else:
		var r := actor.release_radius
		var d := actor.release_distance
		# A capsule footprint includes the actual swept contact at both ends.
		for i in 33:
			var angle := PI * float(i) / 32.0
			points.append(Vector3(cos(angle)*r, 0, -d-sin(angle)*r))
		for i in 33:
			var angle := PI * float(i) / 32.0
			points.append(Vector3(-cos(angle)*r, 0, sin(angle)*r))
		points.append(points[0])
	for i in range(points.size()-1):
		var a := points[i]
		var b := points[i+1]
		var side := (b-a).normalized().cross(Vector3.UP) * tell_width * .5
		for p in [a-side, a+side, b+side, a-side, b+side, b-side]: mesh.surface_add_vertex(p + Vector3.UP * .06)
	mesh.surface_end()
	tell.mesh = mesh
	add_child(tell)
	tell.visible = false

func _physics_process(delta: float) -> void:
	clock += delta
	if scar != null:
		var weight := (sin(clock*TAU/pulse_seconds)+1.0)*.5
		scar.set_shader_parameter("strength", lerpf(scar_low, scar_high, weight))
	if tell != null:
		tell.visible = actor.life > 0 and not actor.is_frozen() and not actor.staggered() and actor.state == "windup"
