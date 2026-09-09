class_name FrontierHostLook
extends Node3D
## Prototype adapter over the existing rig; no edits to concurrent source art.
const SCAR = preload("res://art/frontier_scar.gdshader")
const PALETTE = {"red": Color("f17443"), "blue": Color("77c5ed"), "blue_red": Color("77c5ed"), "white": Color("ebe4bf"), "green": Color("8ec781")}
## Ambient cycle/contrast and warning stroke are presentation tuning only.
@export var pulse_seconds := 3.5
@export var scar_low := 0.35
@export var scar_high := 0.8
@export var tell_width := 0.07
var actor: Enemy
var clock := 0.0
var tell: MeshInstance3D
var scar: ShaderMaterial
var phase_label: Label3D
var tell_material: StandardMaterial3D
## Head lowering is a quiet rooting/grazing pose over the retained authored rig.
@export var graze_radians := 0.48
@export var root_radians := 0.22

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
	tell_material = material
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	var points := PackedVector3Array()
	if actor.release_shape in ["radial", "held_burst"]:
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
	if actor.release_shape == "held_burst":
		phase_label = Label3D.new()
		phase_label.position.y = 2.0
		phase_label.font_size = 40
		phase_label.pixel_size = .006
		phase_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		phase_label.outline_size = 10
		add_child(phase_label)
		# Two mismatched imposed collars distinguish forced pairing from ambient scars.
		for i in 2:
			var collar := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(.85,.12,.14)
			collar.mesh = box
			collar.position = Vector3(0,.8,-.3 if i == 0 else .3)
			var paint := StandardMaterial3D.new()
			paint.albedo_color = PALETTE.blue if i == 0 else PALETTE.red
			collar.material_override = paint
			add_child(collar)

func _physics_process(delta: float) -> void:
	clock += delta
	if actor.life > 0 and actor.state == "idle" and not actor.is_frozen() and not actor.staggered():
		if actor.velocity.length_squared() < .1:
			var motion := actor._mesh.get_node_or_null("Motion") as CreatureMotion
			if motion != null and not motion._authored.is_empty():
				for i in range(1,motion.rig.get_bone_count()):
					if String(motion._authored.rig[i].motion) == "head":
						var angle := graze_radians if actor.influence == "white" else root_radians
						motion.rig.set_bone_pose_rotation(i,Quaternion.from_euler(Vector3(angle*(.65+.35*sin(clock)),0,0)))
	if scar != null:
		var weight := (sin(clock*TAU/pulse_seconds)+1.0)*.5
		scar.set_shader_parameter("strength", lerpf(scar_low, scar_high, weight))
	if tell != null:
		tell.visible = actor.life > 0 and not actor.is_frozen() and not actor.staggered() and actor.state == "windup"
		if actor.release_shape == "held_burst":
			tell.visible = actor.life > 0 and not actor.is_frozen() and not actor.staggered() and actor.state in ["windup","release_warning","release"]
			tell.global_position = actor._held_position
			tell_material.albedo_color = PALETTE.blue if actor.state == "windup" else PALETTE.red
			phase_label.visible = actor.life > 0 and actor.state in ["windup","release_warning","release","recover"]
			phase_label.text = {"windup":"BLUE • HOLD", "release_warning":"RED • LEAVE THE RING", "release":"RELEASE", "recover":"RECOVERING"}.get(actor.state,"")
			phase_label.modulate = tell_material.albedo_color if actor.state != "recover" else Color.WHITE
