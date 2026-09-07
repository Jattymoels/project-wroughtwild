class_name TrialHazard
extends Node3D
## A committed, visible floor hazard. Its numbers come from trial rules;
## contact and elapsed time are the engine's responsibility.
var controller: Node
var tell_left := 0.0
var active_left := 0.0
var tick_left := 0.0
var tick_seconds := 1.0
var raw_damage := 0.0
var damage_type := "fire"
var radius := 1.0
var lane_size := Vector2.ZERO
var source_name := "Furnace vent"
var spent := false
var mesh: MeshInstance3D
var material: StandardMaterial3D
var boundary: ForgeTell
var _warning_seconds := 0.0

func configure(owner_controller: Node, at: Vector3, rules: Dictionary, lane := Vector2.ZERO, title := "Furnace vent") -> void:
	controller=owner_controller
	global_position=at+Vector3.UP*.045
	tell_left=float(rules.get("hazard_telegraph_seconds",1.5))
	_warning_seconds=tell_left
	active_left=float(rules.get("hazard_active_seconds",3.0))
	tick_seconds=float(rules.get("hazard_tick_seconds",.8))
	raw_damage=float(rules.get("hazard_damage_per_tick",8.0))
	damage_type=String(rules.get("hazard_damage_type","fire"))
	radius=float(rules.get("hazard_radius_m",2.8))
	lane_size=lane
	source_name=title
	mesh=MeshInstance3D.new()
	if lane==Vector2.ZERO:
		var disc:=CylinderMesh.new()
		disc.top_radius=radius
		disc.bottom_radius=radius
		disc.height=.03
		disc.radial_segments=32
		mesh.mesh=disc
	else:
		var box:=BoxMesh.new()
		box.size=Vector3(lane.x,.035,lane.y)
		mesh.mesh=box
	material=ForgeTell.LOOK.fill()
	mesh.material_override=material
	mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	boundary=ForgeTell.attach(mesh,ForgeTell.disc(radius) if lane==Vector2.ZERO else ForgeTell.lane(lane))
	boundary.set_warning(tell_left,_warning_seconds)
	if tell_left<=0:
		material.albedo_color=ForgeTell.LOOK.active_fill
		boundary.set_active()
	add_to_group("trial_hazards")

func contains_point(point: Vector3) -> bool:
	var p:=to_local(point)
	if absf(p.y)>2.5: return false
	if lane_size!=Vector2.ZERO:
		return absf(p.x)<=lane_size.x*.5 and absf(p.z)<=lane_size.y*.5
	return Vector2(p.x,p.z).length()<=radius

func _physics_process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if spent: return
	if not is_instance_valid(controller) or not controller.active():
		cancel(); return
	if tell_left>0:
		var warning_step:=minf(tell_left,delta)
		tell_left-=warning_step
		delta-=warning_step
		boundary.set_warning(tell_left,_warning_seconds)
		if tell_left>0: return
		material.albedo_color=ForgeTell.LOOK.active_fill
		boundary.set_active()
	if delta<=0: return
	active_left-=delta
	tick_left-=delta
	if tick_left<=0:
		tick_left=tick_seconds
		if contains_point(controller.player.global_position):
			controller.player.combat.take_hit(raw_damage,damage_type,source_name,self)
	if active_left<=0: cancel()

func cancel() -> void:
	spent=true
	if is_instance_valid(mesh): mesh.hide()
	remove_from_group("trial_hazards")
	queue_free()
