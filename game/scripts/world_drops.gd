class_name WorldDrops
extends RefCounted
## INT-07: world-local ownership snapshots. SaveManager validates the complete
## candidate against native tuning before calling restore; this helper never
## grants inventory, rolls gear, learns skills or generates a world.
const VERSION := 1
const BUNDLE_SCENE := preload("res://scenes/dropped_bundle.tscn")
## Native material inventory counts use signed int32. This is a representable
## count bound, not a new hauling cap or limit on the number of world drops.
const MAX_MATERIAL_COUNT := 2147483647

static func _vec(value: Vector3) -> Array:
	return [value.x,value.y,value.z]

static func _unvec(value: Array) -> Vector3:
	return Vector3(float(value[0]),float(value[1]),float(value[2]))

static func _collect(node: Node, pickups: Array, bundles: Array, include_queued := false) -> void:
	for child in node.get_children():
		if not include_queued and child.is_queued_for_deletion(): continue
		if child is Pickup:
			if include_queued or not child._claimed: pickups.append(child)
		elif child is DroppedBundle:
			if include_queued or not child._claimed: bundles.append(child)
		_collect(child,pickups,bundles,include_queued)

static func capture(root: Node) -> Dictionary:
	var result := {"version":VERSION,"pickups":[],"bundles":[]}
	var pickups: Array = []
	var bundles: Array = []
	_collect(root,pickups,bundles)
	for pickup: Pickup in pickups:
		var row := {
			"kind":pickup.kind,"position":_vec(pickup.global_position),
			"yaw":pickup.global_rotation.y,"velocity":_vec(pickup._velocity),
			"floor_y":pickup._floor_y,"bounces":pickup._bounces,
			"resting":pickup._resting,"age":pickup._age,"bob_phase":pickup._bob_phase,
			# The landing frame has not yet applied its first idle bob, so
			# phase alone cannot reproduce that frame's exact visible offset.
			"mesh_y":pickup._mesh.position.y if pickup._mesh != null else 0.12}
		match pickup.kind:
			"material": row.merge({"family":pickup.family,"amount":pickup.amount})
			"gear":
				# Native calls retain their current seed conversion. Decimal text
				# preserves all int64 bits through JSON's floating number parser.
				row.merge({"enemy_id":pickup.enemy_id,"gear_seed":str(pickup.gear_seed),
					"elite_id":pickup.elite_id,"display_name":pickup.display_name,"rarity":pickup.rarity})
			"page": row.merge({"page_skill":pickup.page_skill,"display_name":pickup.display_name})
		result.pickups.append(row)
	for bundle: DroppedBundle in bundles:
		if bundle.contents.is_empty(): continue
		result.bundles.append({"position":_vec(bundle.global_position),
			"rotation":_vec(bundle.global_rotation),"contents":bundle.contents.duplicate(true)})
	return result

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _integer(value: Variant) -> bool:
	return _number(value) and float(value)==floorf(float(value))

static func _vector(value: Variant) -> bool:
	if not value is Array or value.size()!=3: return false
	for component in value:
		if not _number(component): return false
	# Finite JSON doubles must also remain finite in Godot's Vector3 storage.
	return _unvec(value).is_finite()

static func _spatial_number(value: Variant) -> bool:
	return _number(value) and Vector3(float(value),0,0).is_finite()

static func _text(value: Variant) -> bool:
	return value is String or value is StringName

static func _id(value: Variant) -> bool:
	return _text(value) and not String(value).is_empty()

static func _count(value: Variant) -> bool:
	return _integer(value) and value>0 and value<=MAX_MATERIAL_COUNT

static func _seed(value: Variant) -> bool:
	if not value is String: return false
	# Check bounds as text before converting: invalid saves must not invoke
	# String.to_int's overflow diagnostic. Signed int64 has nineteen digits.
	if value.length()>20 or not value.is_valid_int(): return false
	var negative: bool = value.begins_with("-")
	var digits: String = value.substr(1) if negative else value
	if digits.begins_with("+") or digits.begins_with("-") or digits.length()>19: return false
	var bound := "9223372036854775808" if negative else "9223372036854775807"
	if digits.length()==19 and digits.casecmp_to(bound)>0: return false
	return str(value.to_int())==value

static func _contents(value: Variant) -> bool:
	if not value is Dictionary: return false
	for id in value:
		# Native inventory accepts generic string IDs. Do not mistake a
		# partial building/material catalogue for an exhaustive registry.
		if not _id(id) or not _count(value[id]): return false
	return true

static func valid(payload: Variant, sim: WroughtwildSim) -> bool:
	if sim == null or not payload is Dictionary: return false
	if not _integer(payload.get("version")) or payload.version!=VERSION: return false
	if not payload.get("pickups") is Array or not payload.get("bundles") is Array: return false
	var enemies := sim.enemy_ids()
	var elites := sim.elite_modifier_ids()
	var skills := sim.combat_skill_ids()
	for row in payload.pickups:
		if not row is Dictionary or not _text(row.get("kind")): return false
		if not _vector(row.get("position")) or not _vector(row.get("velocity")): return false
		for key in ["yaw","floor_y","mesh_y"]:
			if not _spatial_number(row.get(key)): return false
		if not _number(row.get("bob_phase")): return false
		if not _number(row.get("age")) or row.age<0: return false
		if not row.get("resting") is bool: return false
		if not _integer(row.get("bounces")) or row.bounces<0: return false
		# Restored bounces are a GDScript int64. No gameplay bounce cap is
		# introduced; only reject values that cannot be represented there.
		if row.bounces is float and row.bounces>=9223372036854775808.0: return false
		match String(row.kind):
			"material":
				if not _id(row.get("family")) or not _count(row.get("amount")): return false
			"gear":
				if not _id(row.get("enemy_id")) or not enemies.has(String(row.enemy_id)): return false
				if not _text(row.get("elite_id")): return false
				if row.elite_id!="" and not elites.has(String(row.elite_id)): return false
				if not _seed(row.get("gear_seed")): return false
				if not _text(row.get("display_name")) or not _text(row.get("rarity")): return false
			"page":
				if not _id(row.get("page_skill")) or not skills.has(String(row.page_skill)): return false
				if not _text(row.get("display_name")): return false
			_: return false
	for row in payload.bundles:
		if not row is Dictionary: return false
		if not _vector(row.get("position")) or not _vector(row.get("rotation")): return false
		if not _contents(row.get("contents")): return false
	return true

## Caller has validated the complete save before importing any player state.
## Replacement is synchronous, so no abandoned drop can absorb later this frame.
static func restore(root: Node, payload: Dictionary) -> void:
	var pickups: Array = []
	var bundles: Array = []
	_collect(root,pickups,bundles,true)
	for old in pickups+bundles:
		if is_instance_valid(old) and root.is_ancestor_of(old): old.free()
	for row: Dictionary in payload.pickups:
		var pickup := Pickup.new()
		pickup.kind = String(row.kind)
		match pickup.kind:
			"material": pickup.family = String(row.family); pickup.amount = int(row.amount)
			"gear":
				pickup.enemy_id = String(row.enemy_id)
				pickup.gear_seed = String(row.gear_seed).to_int()
				pickup.elite_id = String(row.elite_id)
				pickup.display_name = String(row.display_name)
				pickup.rarity = String(row.rarity)
			"page": pickup.page_skill = String(row.page_skill); pickup.display_name = String(row.display_name)
		root.add_child(pickup)
		pickup.global_position = _unvec(row.position)
		pickup.global_rotation = Vector3(0,float(row.yaw),0)
		pickup._velocity = _unvec(row.velocity)
		pickup._floor_y = float(row.floor_y)
		pickup._bounces = int(row.bounces)
		pickup._resting = bool(row.resting)
		pickup._age = float(row.age)
		pickup._bob_phase = float(row.bob_phase)
		pickup._mesh.position.y = float(row.mesh_y)
	for row: Dictionary in payload.bundles:
		var bundle: DroppedBundle = BUNDLE_SCENE.instantiate()
		# JSON parses numeric counts as floats; native ownership uses integers.
		# Validation already proved each value is an exact positive int32.
		for id in row.contents: bundle.contents[String(id)] = int(row.contents[id])
		root.add_child(bundle)
		bundle.global_position = _unvec(row.position)
		bundle.global_rotation = _unvec(row.rotation)
