class_name DamageCompass
extends Control
## Remembers the bearing of a landed hit, never a live enemy reference.
const LOOK = preload("res://art/combat_feel.tres")
var player: WroughtwildPlayer
var bearings: Array[Dictionary] = []
var unknown_left := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	player.combat.damage_bearing.connect(receive_hit)
	player.combat.died.connect(clear)

func clear() -> void:
	bearings.clear()
	unknown_left = 0.0
	queue_redraw()

func receive_hit(damage: float, toward_source: Vector3) -> void:
	if damage <= 0.0:
		return
	var planar := Vector3(toward_source.x, 0, toward_source.z).normalized()
	if planar.is_zero_approx():
		unknown_left = LOOK.hit_seconds
	else:
		# Repeated bites from the same bearing refresh one arc, keeping a
		# pack readable rather than layering a new full-screen flash each hit.
		for entry in bearings:
			if (entry.direction as Vector3).dot(planar) > cos(deg_to_rad(LOOK.hit_arc_degrees * 0.5)):
				entry.left = LOOK.hit_seconds
				queue_redraw()
				return
		if bearings.size() >= LOOK.max_hit_directions:
			bearings.pop_front()
		bearings.append({"direction":planar, "left":LOOK.hit_seconds})
	queue_redraw()

func screen_direction(world_direction: Vector3) -> Vector2:
	# Flatten the camera basis so steep pitch does not swap front and rear.
	var right := player.camera.global_basis.x
	right.y = 0.0
	right = right.normalized()
	var forward := Vector3.UP.cross(right)
	return Vector2(world_direction.dot(right), -world_direction.dot(forward)).normalized()

func _process(delta: float) -> void:
	sample(delta)

func sample(delta: float) -> void:
	if player.combat.life <= 0.0:
		bearings.clear()
		unknown_left = 0.0
	for i in range(bearings.size()-1, -1, -1):
		bearings[i].left = maxf(0.0, float(bearings[i].left)-delta)
		if bearings[i].left <= 0.0:
			bearings.remove_at(i)
	unknown_left = maxf(0.0, unknown_left-delta)
	queue_redraw()

func _draw() -> void:
	var centre := size * 0.5
	var radius := minf(size.x,size.y) * LOOK.hit_radius_fraction
	var half_arc := deg_to_rad(LOOK.hit_arc_degrees * 0.5)
	for entry in bearings:
		var direction := screen_direction(entry.direction)
		var angle := direction.angle()
		var tint: Color = LOOK.hit_colour
		tint.a = clampf(float(entry.left)/LOOK.hit_seconds*1.8,0.0,1.0)
		draw_arc(centre,radius,angle-half_arc,angle+half_arc,24,Color(0.08,0.055,0.04,tint.a*0.75),LOOK.hit_width+4.0,true)
		draw_arc(centre,radius,angle-half_arc,angle+half_arc,24,tint,LOOK.hit_width,true)
		var tangent := Vector2(-direction.y,direction.x)
		draw_colored_polygon(PackedVector2Array([centre+direction*(radius+12),centre+direction*(radius+4)+tangent*5,centre+direction*(radius+4)-tangent*5]),tint)
	if unknown_left > 0.0:
		var tint: Color = LOOK.unknown_colour
		tint.a = unknown_left/LOOK.hit_seconds*0.6
		# A complete faint ring means damage with no known planar direction
		# (burning ground, for example); never fabricate a front-facing arrow.
		draw_arc(centre,radius-10,0,TAU,80,tint,2.0,true)
