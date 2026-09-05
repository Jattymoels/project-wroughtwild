class_name ResourceNode
extends StaticBody3D
## A harvestable world resource (wood or iron in the slice). Depletes and
## frees itself; a respawn policy is a later design question, not spiked.

## Material family granted per harvest, matching data/tuning ids
## (e.g. "wood", "iron_ore").
@export var material_family: StringName = &"wood"
@export var remaining_units: int = 20
@export var units_per_harvest: int = 2
## Gathering site in data/tuning/world.json this node belongs to; drives
## ambush chance and which enemies arrive. Empty means never ambushed.
@export var gather_site_id: StringName = &""
## Greybox look from worldgen.json's node visual key: tree | boulder |
## iron_vein. Empty keeps the scene's default cylinder.
@export var visual: StringName = &""
## Fire-setting (D-020): the fire heat this node must be soaked in and then
## quenched before E works it (0 = hands). Once cracked it stays cracked.
@export var heat_to_work: int = 0
## Seams (D-021): the item a split spends ("" for hands' work) and how many
## E presses drive it. wedge_set/drive_progress are the seam's state. Since
## the world-made-whole pass (4 Sep 2026) any node may want drive_presses
## of E per harvest: a tree is chopped six times and falls whole, a
## boulder cracks a chunk off every three. One press is the plain gather.
@export var tool_item: StringName = &""
@export var drive_presses: int = 1
var wedge_set := false
var drive_progress := 0
var cracked := false
var hot_level := 0
var _hot_until := 0
var _wedge_mesh: MeshInstance3D


## Yield when the node first appeared, so the visual shrink tracks the
## fraction actually taken (feel: you can SEE a node is nearly spent).
var _initial_units := 0
## Materials created for this node's own meshes; safe to tint for the
## look-at highlight because they are never shared between nodes.
var _own_materials: Array = []


func _ready() -> void:
	_initial_units = maxi(remaining_units, 1)
	_apply_visual()


## Crosshair-hover feedback: a soft glow on the node you would harvest.
func set_highlight(on: bool) -> void:
	for material in _own_materials:
		material.emission_enabled = on or hot_level > 0


## Deterministic per position and kind, so a rebuilt (or loaded) world
## grows the exact same crooked tree in the exact same place.
func _visual_seed() -> int:
	return hash(Vector3i((position * 4.0).round())) + hash(String(visual))


func _apply_visual() -> void:
	var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D")
	var collider: CollisionShape3D = get_node_or_null("CollisionShape3D")
	if mesh_instance == null or collider == null:
		return
	if not (visual in [&"tree", &"boulder", &"iron_vein", &"copper_vein", &"tin_vein", &"ember_vein", &"silver_vein", &"seam"]):
		return

	# Chunky low-poly props (D-013): flat-shaded facets, palette vertex
	# colours, crooked silhouettes - not Minecraft boxes.
	var material := PropMesh.material()
	if _terrain() != null and _terrain().weathered:
		material.vertex_color_is_srgb = true
		var look: Resource = _terrain().frontier_look
		mesh_instance.visibility_range_end = look.tree_distance if visual==&"tree" else look.detail_distance
		mesh_instance.visibility_range_end_margin = 8.0
		mesh_instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	_own_materials.append(material)
	mesh_instance.material_override = material
	mesh_instance.position = Vector3.ZERO
	mesh_instance.rotation.y = float(_visual_seed() % 628) / 100.0
	var shape := BoxShape3D.new()
	# A seam or a vein is a line through the stone (4 Sep 2026): it runs
	# along a row or a column of cells and follows their surface heights, so
	# it lies flush on the blocks it crosses. The collider is the line.
	if visual == &"seam" or String(visual).ends_with("_vein"):
		var along_x: bool = _visual_seed() % 2 == 0
		mesh_instance.rotation.y = 0.0 if along_x else PI * 0.5
		var rises := _rises(along_x)
		match visual:
			&"seam":
				mesh_instance.mesh = PropMesh.build_seam(_visual_seed(), rises)
			&"iron_vein":
				mesh_instance.mesh = PropMesh.build_vein(_visual_seed(), PropMesh.IRON_RUST, rises)
			&"copper_vein":
				mesh_instance.mesh = PropMesh.build_vein(_visual_seed(), PropMesh.COPPER, rises)
			&"tin_vein":
				mesh_instance.mesh = PropMesh.build_vein(_visual_seed(), PropMesh.TIN, rises)
			&"ember_vein":
				mesh_instance.mesh = PropMesh.build_vein(_visual_seed(), PropMesh.EMBER_ORE, rises)
			&"silver_vein":
				mesh_instance.mesh = PropMesh.build_vein(_visual_seed(), PropMesh.SILVER, rises)
		shape.size = Vector3(2.6, 0.6, 0.9) if along_x else Vector3(0.9, 0.6, 2.6)
		collider.position = Vector3(0, 0.3, 0)
		collider.shape = shape
		refresh_surface()
		_refresh_wedge_look()
		return
	match visual:
		&"tree":
			# The silhouette is the biome's (Wave 6 slice 4): a pine in the
			# forest, a snag in the wastes, the broadleaf elsewhere.
			match _biome_id():
				"forest":
					mesh_instance.mesh = PropMesh.build_pine(_visual_seed())
					shape.size = Vector3(0.7, 3.6, 0.7)
					collider.position = Vector3(0, 1.8, 0)
				"ember_wastes":
					mesh_instance.mesh = PropMesh.build_snag(_visual_seed())
					shape.size = Vector3(0.6, 2.6, 0.6)
					collider.position = Vector3(0, 1.3, 0)
				_:
					mesh_instance.mesh = PropMesh.build_tree(_visual_seed())
					# Collision stays the trunk only: you can stand under the canopy.
					shape.size = Vector3(0.7, 3.0, 0.7)
					collider.position = Vector3(0, 1.5, 0)
			if OS.get_cmdline_user_args().has("--crafted-look"):
				mesh_instance.mesh = preload("res://art/woodland_look.tres").build_tree(_biome_id(), _visual_seed())
			if _terrain() != null and _terrain().weathered:
				mesh_instance.mesh = preload("res://art/weathered_woodland.tres").build_tree(_biome_id(), _visual_seed())
		&"boulder":
			mesh_instance.mesh = PropMesh.build_boulder(_visual_seed())
			shape.size = Vector3(1.4, 1.0, 1.2)
			collider.position = Vector3(0, 0.5, 0)
		&"iron_vein":
			mesh_instance.mesh = PropMesh.build_iron_vein(_visual_seed())
			shape.size = Vector3(1.2, 0.9, 1.2)
			collider.position = Vector3(0, 0.45, 0)
		&"copper_vein":
			mesh_instance.mesh = PropMesh.build_vein(_visual_seed(), PropMesh.COPPER)
			shape.size = Vector3(1.2, 0.9, 1.2)
			collider.position = Vector3(0, 0.45, 0)
		&"tin_vein":
			mesh_instance.mesh = PropMesh.build_vein(_visual_seed(), PropMesh.TIN)
			shape.size = Vector3(1.2, 0.9, 1.2)
			collider.position = Vector3(0, 0.45, 0)
		&"ember_vein":
			mesh_instance.mesh = PropMesh.build_vein(_visual_seed(), PropMesh.EMBER_ORE)
			shape.size = Vector3(1.2, 0.9, 1.2)
			collider.position = Vector3(0, 0.45, 0)
		&"silver_vein":
			mesh_instance.mesh = PropMesh.build_vein(_visual_seed(), PropMesh.SILVER)
			shape.size = Vector3(1.2, 0.9, 1.2)
			collider.position = Vector3(0, 0.45, 0)
	collider.shape = shape
	refresh_surface()
	_refresh_wedge_look()

## Reproject presentation after a nearby dig without moving the saved resource
## anchor, changing its visual seed or resetting harvest/fire-setting state.
func refresh_surface() -> void:
	var terrain := _terrain()
	if terrain == null or not terrain.faceted_surface:
		return
	var mesh: MeshInstance3D = get_node("MeshInstance3D")
	var collider: CollisionShape3D = get_node("CollisionShape3D")
	if visual==&"seam" or String(visual).ends_with("_vein"):
		var colours := {&"seam":Color("2e3036"),&"iron_vein":PropMesh.IRON_RUST,&"copper_vein":PropMesh.COPPER,
			&"tin_vein":PropMesh.TIN,&"ember_vein":PropMesh.EMBER_ORE,&"silver_vein":PropMesh.SILVER}
		var grounded := GroundedSeam.build(self,terrain,_visual_seed()%2==0,colours.get(visual,PropMesh.IRON_RUST))
		mesh.rotation = Vector3.ZERO
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.mesh = grounded
		mesh.visible = grounded != null
		# Picking follows the visible ribbon instead of a floating three-cell box.
		collider.set_deferred("disabled",grounded==null)
		if grounded != null:
			collider.position = Vector3.ZERO
			collider.shape = grounded.create_trimesh_shape()
	else:
		var y := terrain.rendered_height(position.x,position.z,position.y)
		if is_finite(y):
			mesh.position.y = y-position.y-0.025


## The biome under this node ("" when a harness placed it by hand).
func _biome_id() -> String:
	var terrain := _terrain()
	if terrain == null or terrain.map.is_empty():
		return ""
	var cell: float = terrain.map["cell_size"]
	var cx := int(floor(position.x / cell))
	var cz := int(floor(position.z / cell))
	var width := int(terrain.map["width"])
	if cx < 0 or cz < 0 or cx >= width or cz >= int(terrain.map["height"]):
		return ""
	var index: int = (terrain.map["biomes"] as PackedInt32Array)[cz * width + cx]
	var defs: Array = terrain.map.get("biome_defs", [])
	return String(defs[index].get("id", "")) if index >= 0 and index < defs.size() else ""


## The terrain this node lies on (a child of its node root), or null when
## a harness placed the node by hand.
func _terrain() -> Terrain:
	var root := get_parent()
	return root.get_parent() as Terrain if root != null and root.get_parent() is Terrain else null


## The surface height of the cell before, the node's own, and the cell
## after, along a row (x) or a column (z), relative to the node's - what a
## line through the stone has to step over. Flat when there is no terrain.
func _rises(along_x: bool) -> Array:
	var terrain := _terrain()
	if terrain == null or terrain.map.is_empty():
		return [0.0, 0.0, 0.0]
	var cell: float = terrain.map["cell_size"]
	var cx := int(floor(position.x / cell))
	var cz := int(floor(position.z / cell))
	var own := terrain.height_at(cx, cz)
	var rises: Array = []
	for d in [-1, 0, 1]:
		var h := terrain.height_at(cx + d, cz) if along_x else terrain.height_at(cx, cz + d)
		# A step of more than one block is a cliff, not a line: clamp so the
		# band never floats or dives.
		rises.append(float(clampi(h - own, -1, 1)))
	return rises


## A fire beside the node soaks it: hot at `heat` for `seconds`.
func soak(heat: int, seconds: float) -> void:
	# Ores that want heat, and seams (a hot seam splits whole under a blow).
	if (heat_to_work <= 0 and not is_seam()) or cracked:
		return
	hot_level = maxi(hot_level, heat)
	_hot_until = Time.get_ticks_msec() + int(seconds * 1000.0)
	_refresh_state_look()


## Cold on a hot node cracks it when the heat met its need. Returns true
## when it cracked just now.
func quench() -> bool:
	if cracked or hot_level <= 0 or hot_level < heat_to_work:
		return false
	cracked = true
	hot_level = 0
	_refresh_state_look()
	return true


## True when the material itself is ready for hands: no heat asked, or hot
## right now (softened), or cracked for good.
func workable() -> bool:
	return heat_to_work <= 0 or cracked or hot_level >= heat_to_work


func is_seam() -> bool:
	return tool_item != &""


## The crosshair line for this node.
func interact_label(sim: WroughtwildSim) -> String:
	var name := Hud.pretty(String(material_family))
	if not workable():
		return "%s ×%d — %s" % [name, remaining_units, work_refusal()]
	if is_seam():
		if wedge_set:
			var hot := "  ·  hot: one blow takes the whole seam" if hot_level > 0 else ""
			return "%s ×%d — E drive the wedge (%d/%d), or strike it%s" % [name, remaining_units, drive_progress, drive_presses, hot]
		var held: int = sim.material_count(String(tool_item))
		if held > 0:
			return "%s ×%d — E set a wedge (%s ×%d)" % [name, remaining_units, Hud.pretty(String(tool_item)), held]
		return "%s ×%d — the seam wants a %s driven into it" % [name, remaining_units, Hud.pretty(String(tool_item))]
	if drive_presses > 1:
		var verb := "E to chop; it falls whole" if visual == &"tree" else "E to crack a chunk off"
		return "%s ×%d — %s (%d/%d)" % [name, remaining_units, verb, drive_progress, drive_presses]
	return "%s ×%d — E to gather" % [name, remaining_units]


## E on the node: the BASELINE route, always available (D-021). Returns
## {granted} when units came out, {text} for a step, {refusal} when not.
func work(sim: WroughtwildSim) -> Dictionary:
	if remaining_units <= 0:
		return {"refusal": "nothing left here"}
	if not workable():
		return {"refusal": work_refusal()}
	if not is_seam():
		# Felling and cracking (the world made whole, 4 Sep 2026): a tree or
		# a boulder wants drive_presses of E per harvest. Each press on a
		# tree leans it a little further from you; the last brings the whole
		# tree down at once. A boulder gives up a chunk per round of presses.
		if drive_presses > 1:
			drive_progress += 1
			if drive_progress < drive_presses:
				if is_inside_tree():
					_play_harvest_punch()
					if visual == &"tree":
						_lean_from_player()
				return {"text": "%s (%d/%d)." % ["Chopping" if visual == &"tree" else "Working the rock", drive_progress, drive_presses]}
			drive_progress = 0
		return {"granted": harvest()}
	if not wedge_set:
		if not sim.consume_material(String(tool_item), 1):
			return {"refusal": "the seam wants a %s driven into it (hand-craft them from timber)" % Hud.pretty(String(tool_item))}
		wedge_set = true
		drive_progress = 0
		_refresh_wedge_look()
		return {"text": "You set a wedge in the seam. Drive it with E, or strike it."}
	drive_progress += 1
	if drive_progress < drive_presses:
		_play_harvest_punch()
		_refresh_wedge_look()
		return {"text": "Driving the wedge (%d/%d)." % [drive_progress, drive_presses]}
	return {"granted": _split(false)}


## A heavy blow on the node: the EXPLOIT route. A set wedge splits at once;
## a hot seam splits twice over (the SYNERGY); a hot ore cracks. Returns
## the same shape as work(), plus "synergy" when heat doubled the split.
func strike() -> Dictionary:
	if remaining_units <= 0:
		return {}
	if is_seam():
		if not wedge_set:
			return {"refusal": "the blow rings off the rock: set a wedge first"}
		var synergy := hot_level > 0
		return {"granted": _split(synergy), "synergy": synergy, "struck": true}
	if heat_to_work > 0 and not cracked and hot_level >= heat_to_work:
		cracked = true
		hot_level = 0
		_refresh_state_look()
		return {"text": "The hot rock cracks under the blow.", "struck": true}
	return {}


func _split(whole: bool) -> int:
	var granted := harvest()
	_drop_chunk()
	if whole and remaining_units > 0:
		granted += harvest()
		_drop_chunk()
	wedge_set = false
	drive_progress = 0
	_refresh_wedge_look()
	return granted


## The accomplishment (4 Sep 2026): a split throws a fist of stone off the
## seam that tumbles and settles before it fades. Feel only; the yield is
## the chips that fly to the pack.
func _drop_chunk() -> void:
	if not is_inside_tree():
		return
	var chunk := RigidBody3D.new()
	chunk.mass = 0.6
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.26, 0.22, 0.26)
	shape.shape = box
	chunk.add_child(shape)
	var mesh := MeshInstance3D.new()
	mesh.mesh = PropMesh.build_chunk(_visual_seed() + remaining_units * 17)
	mesh.material_override = PropMesh.material()
	chunk.add_child(mesh)
	get_parent().add_child(chunk)
	chunk.global_position = global_position + Vector3(0, 0.5, 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = _visual_seed() + remaining_units
	chunk.apply_central_impulse(Vector3(rng.randf_range(-0.9, 0.9), rng.randf_range(1.4, 2.2), rng.randf_range(-0.9, 0.9)))
	chunk.apply_torque_impulse(Vector3(rng.randf_range(-0.3, 0.3), 0.0, rng.randf_range(-0.3, 0.3)))
	get_tree().create_timer(2.6).timeout.connect(chunk.queue_free)


## The wedge in the seam, sinking as it is driven (4 Sep 2026): each E
## press seats it deeper and leans it further, so the split is visible
## before it happens.
func _refresh_wedge_look() -> void:
	if _wedge_mesh != null:
		_wedge_mesh.queue_free()
		_wedge_mesh = null
	if not wedge_set:
		return
	_wedge_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.12, 0.34, 0.12)
	var material := StandardMaterial3D.new()
	material.albedo_color = PropMesh.BARK
	box.material = material
	_wedge_mesh.mesh = box
	var sunk := float(drive_progress) / float(maxi(drive_presses, 1))
	_wedge_mesh.position = Vector3(0.0, 0.3 - 0.22 * sunk, 0.0)
	_wedge_mesh.rotation.x = -0.35 - 0.4 * sunk
	add_child(_wedge_mesh)


## Why E does nothing yet ("" when it works). The words are the tutorial.
func work_refusal() -> String:
	if workable():
		return ""
	if hot_level >= heat_to_work:
		return "glows  ·  cold will crack it"
	if hot_level > 0:
		return "warm  ·  wants a hotter fire (charcoal)"
	return "needs fire against it, then cold" if heat_to_work <= 1 else "needs a charcoal fire, then cold"


func _process(_delta: float) -> void:
	if hot_level > 0 and Time.get_ticks_msec() >= _hot_until:
		hot_level = 0
		_refresh_state_look()


## Hot nodes glow ember; cracked ones sit darker. Hover highlight rides on
## top of the state colour.
func _refresh_state_look() -> void:
	for material in _own_materials:
		if hot_level > 0:
			material.emission = Color(1.0, 0.4, 0.05)
			material.emission_energy_multiplier = 1.2
			material.emission_enabled = true
		else:
			material.emission = Color(1, 1, 1)
			material.emission_energy_multiplier = 0.4
			material.emission_enabled = false
		material.albedo_color = Color(0.55, 0.5, 0.5) if cracked else Color(1, 1, 1)


## Returns the units actually granted (0 when depleted).
func harvest() -> int:
	if remaining_units <= 0 or not workable():
		return 0

	var granted: int = mini(units_per_harvest, remaining_units)
	remaining_units -= granted

	if remaining_units <= 0:
		_deplete()
	elif is_inside_tree():
		_play_harvest_punch()
	return granted


## Feel: each harvest gives the node a quick squash-and-settle, landing on a
## scale that tracks how much yield is left - a half-spent tree looks it.
func _play_harvest_punch() -> void:
	if _terrain() != null and _terrain().faceted_surface and (visual==&"seam" or String(visual).ends_with("_vein")):
		# A fracture belongs to the ground. Scaling its node would detach the
		# sampled vertices; driving the wedge/remaining-unit readout gives feedback.
		return
	var target := _scale_for_remaining()
	scale = target * 0.86
	var tween := create_tween()
	tween.tween_property(self, "scale", target, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _scale_for_remaining() -> Vector3:
	var fraction := float(remaining_units) / float(maxi(_initial_units, 1))
	return Vector3.ONE * lerpf(0.6, 1.0, fraction)


## Which way a tree falls or a boulder rolls: away from the player, or
## along +X when no one is there to have struck it.
func _fall_direction() -> Vector3:
	var player := get_tree().get_first_node_in_group("player") as Node3D if is_inside_tree() else null
	if player == null:
		return Vector3.RIGHT
	var away: Vector3 = global_position - player.global_position
	away.y = 0.0
	return away.normalized() if away.length_squared() > 0.0001 else Vector3.RIGHT


## The trunk's own yaw, kept so the lean and the fall compose with it.
var _lean := 0.0
var _yaw := 0.0


## Each chop leans the tree a little further from the one chopping it: the
## fall is announced before it happens.
func _lean_from_player() -> void:
	var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")
	if mesh == null:
		return
	var axis := Vector3.UP.cross(_fall_direction()).normalized()
	if axis.length_squared() < 0.5:
		return
	if _lean == 0.0:
		_yaw = mesh.rotation.y
	_lean += deg_to_rad(2.5)
	mesh.transform.basis = Basis(axis, _lean) * Basis(Vector3.UP, _yaw)


## The tree comes down whole: the trunk swings over from the base, away
## from the chopper, and a stump is left where it stood. The yield is the
## chips the player scatters; this is the event.
func _fell() -> void:
	var collider: CollisionShape3D = get_node_or_null("CollisionShape3D")
	if collider != null:
		collider.set_deferred("disabled", true)
	var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")
	var axis := Vector3.UP.cross(_fall_direction()).normalized()
	if mesh == null or axis.length_squared() < 0.5:
		queue_free()
		return
	if _lean == 0.0:
		_yaw = mesh.rotation.y
	var yaw := _yaw
	var tween := create_tween()
	tween.tween_method(func(angle: float) -> void:
		mesh.transform.basis = Basis(axis, angle) * Basis(Vector3.UP, yaw), _lean, deg_to_rad(88.0), 0.9) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_interval(0.25)
	tween.tween_callback(_leave_stump)
	tween.tween_callback(queue_free)


## A stump where the tree stood, for the session (nodes are saved by their
## remaining units; a felled tree is simply gone on load).
func _leave_stump() -> void:
	if get_parent() == null:
		return
	var stump := MeshInstance3D.new()
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.22
	trunk.bottom_radius = 0.3
	trunk.height = 0.42
	trunk.radial_segments = 7
	var material := StandardMaterial3D.new()
	material.albedo_color = PropMesh.BARK_DARK
	material.roughness = 1.0
	stump.mesh = trunk
	stump.material_override = material
	get_parent().add_child(stump)
	stump.global_position = global_position + Vector3(0, 0.21, 0)


## The boulder's last chunk rolls it over: a quarter turn and a settle
## into the ground, then gone.
func _roll_over() -> void:
	var collider: CollisionShape3D = get_node_or_null("CollisionShape3D")
	if collider != null:
		collider.set_deferred("disabled", true)
	var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")
	var axis := Vector3.UP.cross(_fall_direction()).normalized()
	if mesh == null or axis.length_squared() < 0.5:
		queue_free()
		return
	var yaw: float = mesh.rotation.y
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(func(angle: float) -> void:
		mesh.transform.basis = Basis(axis, angle) * Basis(Vector3.UP, yaw), 0.0, deg_to_rad(90.0), 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh, "position:y", -0.45, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)


## The last harvest shrinks the node away instead of blinking it out.
## Collision goes immediately so the space is usable at once. A tree falls
## whole and a boulder rolls over instead (the world made whole).
func _deplete() -> void:
	if not is_inside_tree():
		queue_free()
		return
	if visual == &"tree":
		_fell()
		return
	if visual == &"boulder":
		_roll_over()
		return
	var collider: CollisionShape3D = get_node_or_null("CollisionShape3D")
	if collider != null:
		collider.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * 0.02, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
