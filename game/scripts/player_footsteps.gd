class_name PlayerFootsteps
extends Node
## Reads completed grounded motion; never supplies motion or gameplay noise.
## The player calls this after move_and_slide so pushing a wall is silent.
signal stepped(surface: String, at: Vector3)
const LOOK = preload("res://art/footstep_sound_look.tres")

var player: WroughtwildPlayer
## Diagnostic counters describe actual emitted contacts, not requested input.
var step_count := 0
var last_surface := ""
var last_position := Vector3.ZERO
var _distance := 0.0
var _elapsed := 0.0
var _previous_position := Vector3.ZERO
var _previous_frame := -1


func setup(in_player: WroughtwildPlayer) -> void:
	player = in_player
	reset_context()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		reset_context()


func reset_context() -> void:
	_distance = 0.0
	_elapsed = 0.0
	_previous_frame = -1
	if is_instance_valid(player): _previous_position = player.global_position
	# These voices belong to this walker, so world replacement, respawn or a
	# trial transition cannot leave an old contact sounding in the new context.
	for child in get_children():
		if child is AudioStreamPlayer3D:
			child.stop()
			child.remove_from_group(FootstepSound.VOICE_GROUP)
			child.queue_free()


func _blocked() -> bool:
	if player.combat.life <= 0.0 or not player.can_process(): return true
	for panel in [player.build_palette, player.work_panel, player.inventory_panel,
		player.foundry_panel, player.class_panel, player.chest_panel]:
		if is_instance_valid(panel) and panel.is_open(): return true
	return is_instance_valid(player.hud) and player.hud.help_visible()


func after_motion(before: Vector3, grounded_before: bool, dashing: bool, delta: float) -> void:
	var frame := Engine.get_physics_frames()
	var motion := player.global_position - before
	var horizontal := Vector2(motion.x, motion.z).length()
	var discontinuous := _previous_frame < 0 or frame != _previous_frame + 1 or before.distance_to(_previous_position) > LOOK.discontinuity_m
	_previous_position = player.global_position
	_previous_frame = frame
	if discontinuous or _blocked() or dashing or not grounded_before or not player.is_on_floor() \
		or delta <= 0.0 or delta > LOOK.maximum_tick_seconds \
		or horizontal > LOOK.maximum_tick_motion_m or absf(motion.y) > LOOK.maximum_ground_rise_m:
		_distance = 0.0
		_elapsed = 0.0
		return
	if horizontal < LOOK.minimum_motion_m:
		_distance = 0.0
		_elapsed = 0.0
		return
	_distance += horizontal
	_elapsed += delta
	if _distance < LOOK.step_distance_m or _elapsed < LOOK.minimum_interval_s: return
	var support := _support_hit()
	if support.is_empty():
		_distance = 0.0
		return
	var surface := _surface_for(support)
	var at: Vector3 = support.position
	if FootstepSound.play(self, at, surface, step_count) == null: return
	_distance = fmod(_distance, LOOK.step_distance_m)
	_elapsed = 0.0
	last_surface = surface
	last_position = at
	step_count += 1
	stepped.emit(surface, at)


func _support_hit() -> Dictionary:
	var shape := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape == null or not shape.shape is CapsuleShape3D: return {}
	var capsule := shape.shape as CapsuleShape3D
	var foot := shape.global_position - Vector3.UP * capsule.height * 0.5
	var probes: Array[Vector3] = [foot]
	# A capsule can rest on a narrow floor edge while its centre is over empty
	# space. Probe its actual walkable contacts as well, retaining face_index
	# for exact edited/faceted terrain instead of guessing from a sloped normal.
	for i in player.get_slide_collision_count():
		var collision := player.get_slide_collision(i)
		if collision.get_normal().dot(Vector3.UP) >= cos(player.floor_max_angle):
			var point := collision.get_position()
			var outward := collision.get_normal()
			outward.y = 0.0
			if not outward.is_zero_approx():
				point -= outward.normalized() * LOOK.contact_inset_m
			point.y = foot.y
			probes.append(point)
	var highest: Dictionary = {}
	for point in probes:
		var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * LOOK.probe_above_m,
			point - Vector3.UP * LOOK.probe_below_m)
		query.exclude = [player]
		query.collision_mask = player.collision_mask
		var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or (hit.normal as Vector3).dot(Vector3.UP) < cos(player.floor_max_angle): continue
		if highest.is_empty() or hit.position.y > highest.position.y:
			highest = hit
	return highest


func _surface_for(hit: Dictionary) -> String:
	var body: Object = hit.get("collider")
	if body is PlacedBlock:
		return FootstepSound.material_surface(player.inventory.get_sim().build_material(String(body.material_family)))
	var terrain := player._find_terrain()
	if is_instance_valid(terrain) and terrain.is_terrain_body(body):
		var cell := terrain.block_from_surface_hit(hit)
		var kind := terrain.kind_at(cell.x, cell.y, cell.z)
		if kind == "surface":
			var width := int(terrain.map.get("width", 0))
			var height := int(terrain.map.get("height", 0))
			var biomes: PackedInt32Array = terrain.map.get("biomes", PackedInt32Array())
			var definitions: Array = terrain.map.get("biome_defs", [])
			if cell.x >= 0 and cell.z >= 0 and cell.x < width and cell.z < height and cell.z * width + cell.x < biomes.size():
				var index := biomes[cell.z * width + cell.x]
				if index >= 0 and index < definitions.size(): kind = String(definitions[index].get("surface", "rock"))
		return FootstepSound.terrain_surface(kind)
	# Authored trial floors and unlabelled stone scenery have real support but
	# no construction family. They use a restrained scuff, never inferred water.
	return "stone"
