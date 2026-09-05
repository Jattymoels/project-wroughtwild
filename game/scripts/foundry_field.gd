class_name FoundryField
extends Node3D
## A committed patch of space. Damage fields, cast seals and recovery beds
## share cover checks and a bounded clock; none can create child mutations.
var combat: PlayerCombat
var skill_id: StringName
var mode := "impact"
var rules: Dictionary
var radius := 1.0
var remaining := 0.0
var pulse_left := 0.0
var fraction := 0.0
var heal_per_pulse := 0.0
var charges := 0
var armour := 0.0
var tint: StandardMaterial3D
var ring: MeshInstance3D

static func spawn(owner_combat: PlayerCombat, skill: StringName, at: Vector3, kind: String, mutation: Dictionary) -> FoundryField:
	var limits: Dictionary = mutation.get("limits", {})
	var live: Array = []
	for node in owner_combat.get_tree().get_nodes_in_group("foundry_fields"):
		if not node.is_queued_for_deletion() and node.combat == owner_combat: live.append(node)
	if live.size() >= int(limits.get("max_fields", 12)): live.front().cancel()
	var field := FoundryField.new()
	field.combat = owner_combat
	field.skill_id = skill
	field.mode = kind
	field.rules = mutation.duplicate(true)
	field.radius = owner_combat.mutation_radius(skill, float(mutation.get("field_radius", 1.8)))
	field.pulse_left = float(limits.get("pulse_interval", 0.8))
	field.remaining = float(mutation.get("field_seconds", 0)) if kind in ["impact", "trail"] else float(limits.get("zone_seconds", 3.2))
	if kind == "steam":
		field.remaining = float(limits.steam_plume_seconds)
		field.radius = owner_combat.mutation_radius(skill, float(limits.steam_plume_radius))
	field.fraction = float(mutation.get("trail_fraction" if kind == "trail" else "field_fraction", 0)) if kind in ["impact", "trail"] else 0.0
	if kind == "recovery":
		field.heal_per_pulse = float(mutation.get("recovery_on_kill", 0)) / maxf(1, floorf(field.remaining / field.pulse_left))
	if kind == "guard":
		field.armour = float(mutation.get("zone_armour", 0))
		field.charges = int(mutation.get("ward_charges", 0))
	owner_combat.player.world_root().add_child(field)
	field.global_position = at
	var floor_hit := SkillBurst.solid_ray(owner_combat, at + Vector3.UP * 0.25, at + Vector3.DOWN * 3.0)
	if not floor_hit.is_empty() and floor_hit.normal.y > 0.45:
		field.global_position = floor_hit.position + floor_hit.normal * 0.08
		field.quaternion = Quaternion(Vector3.UP, floor_hit.normal)
	field._make_visual()
	return field

func _ready() -> void:
	add_to_group("foundry_fields")
	combat.died.connect(cancel)

func cancel() -> void:
	remaining = 0
	charges = 0
	queue_free()

func covers(at: Vector3) -> bool:
	return not is_queued_for_deletion() and remaining > 0 and global_position.distance_to(at) <= radius and SkillBurst.solid_ray(combat, global_position + Vector3.UP * 0.15, at).is_empty()

func _physics_process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if is_queued_for_deletion(): return
	if not is_instance_valid(combat) or not is_instance_valid(combat.player) or combat.life <= 0:
		cancel()
		return
	# Integrate every due pulse even on a long frame, but never beyond expiry.
	var elapsed := minf(maxf(delta, 0), remaining)
	remaining = maxf(0, remaining - elapsed)
	pulse_left -= elapsed
	while pulse_left <= 0.00001:
		pulse_left += float(rules.limits.get("pulse_interval", 0.8))
		if mode == "steam": _steam_pulse()
		if fraction > 0:
			SkillBurst.hit_area(combat, skill_id, global_position + Vector3.UP * 0.15, radius, fraction, [], false, true)
		if heal_per_pulse > 0 and global_position.distance_to(combat.player.global_position) <= radius and SkillBurst.solid_ray(combat, global_position + Vector3.UP * 0.15, combat.player.global_position + Vector3.UP * 0.5).is_empty(): combat.heal(heal_per_pulse)
	if tint != null:
		tint.albedo_color.a = minf(0.26, remaining * 0.26) if mode == "steam" else minf(0.7, remaining * 0.7)
		ring.scale.y = 0.7 + 0.3 * sin(pulse_left * TAU)
	if remaining <= 0: cancel()

func _steam_pulse() -> void:
	var at := global_position + Vector3.UP * 0.15
	var total := 0.0
	var kills := 0
	for enemy in combat.alive_enemies():
		var centre: Vector3 = enemy.global_position + Vector3.UP * 0.5
		if at.distance_to(centre) > radius or not SkillBurst.solid_ray(combat, at, centre).is_empty(): continue
		var fraction := 1.0
		if enemy.guards_against(global_position): fraction *= 1.0 - enemy.verb_strength
		var warden: Enemy = enemy.warded_by()
		if warden != null: fraction *= 1.0 - warden.verb_strength
		# Snapshot typed sim damage. Steam cannot ignite, shatter, siphon, link
		# or make another plume; its damage investment is bounded by three pulses.
		for type in ["fire", "cold"]:
			total += enemy.take_typed(float(rules.get("steam_" + type + "_damage", 0)) * fraction, type)
		if enemy.life <= 0: kills += 1
	if total > 0: combat.hit_landed.emit(total, kills, PackedStringArray(["fire", "cold"]))
	FoundryPuff.spawn(combat, at, radius, true)

## Find the earliest ward along the already cover-limited projectile sweep.
## Checking the full segment keeps a fast shot from tunnelling through a veil.
static func intercept(tree: SceneTree, from: Vector3, to: Vector3) -> bool:
	var nearest: FoundryField
	var distance := INF
	var segment := to - from
	for node in tree.get_nodes_in_group("foundry_fields"):
		if not node is FoundryField or node.charges <= 0 or node.remaining <= 0 or node.is_queued_for_deletion(): continue
		var field := node as FoundryField
		var centre := field.global_position + Vector3.UP * 0.65
		var closest := from + segment * clampf((centre - from).dot(segment) / maxf(segment.length_squared(), 0.00001), 0, 1)
		if closest.distance_to(centre) > field.radius: continue
		var offset := from - centre
		var a := segment.length_squared()
		var b := offset.dot(segment)
		var c := offset.length_squared() - field.radius * field.radius
		var t := 0.0 if c <= 0 else (-b - sqrt(maxf(0, b * b - a * c))) / maxf(a, 0.00001)
		var contact := from + segment * clampf(t, 0, 1)
		if not SkillBurst.solid_ray(field.combat, centre, contact).is_empty(): continue
		if t < distance:
			distance = t
			nearest = field
	if nearest == null: return false
	nearest.charges -= 1
	SkillBurst.flash(nearest.combat, nearest.skill_id, from + segment * clampf(distance, 0, 1), 0.65)
	return true

func _make_visual() -> void:
	var colour := Color("df8449")
	if mode == "steam": colour = Color("b4cbc3")
	elif float(rules.get("smoulder_slow", 0)) > 0: colour = Color("a6c1bd")
	elif mode == "guard": colour = Color("d4bc7a") if charges == 0 else Color("90becd")
	elif mode == "recovery": colour = Color("9cad76")
	elif mode == "trail": colour = Color("b4a8cb")
	elif (rules.get("tags", []) as PackedStringArray).has("cold"): colour = Color("87afbd")
	var st := ArtGeometry.begin()
	for i in 48:
		var p := Vector3(cos(TAU * i / 48.0), 0, sin(TAU * i / 48.0)) * radius
		var q := Vector3(cos(TAU * (i + 1) / 48.0), 0, sin(TAU * (i + 1) / 48.0)) * radius
		ArtGeometry.triangle(st, p, q, p * 0.965, colour)
		ArtGeometry.triangle(st, q, q * 0.965, p * 0.965, colour)
		if i % 4 == 0:
			ArtGeometry.triangle(st, p * 0.94, q * 0.94, p * 0.94 + Vector3.UP * (0.6 if mode == "guard" else 0.22), colour)
	ring = MeshInstance3D.new()
	ring.mesh = st.commit()
	tint = ArtGeometry.material()
	tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tint.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = tint
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
