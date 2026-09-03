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
## E presses drive it. wedge_set/drive_progress are the seam's state.
@export var tool_item: StringName = &""
@export var drive_presses: int = 4
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
	_own_materials.append(material)
	mesh_instance.material_override = material
	mesh_instance.position = Vector3.ZERO
	mesh_instance.rotation.y = float(_visual_seed() % 628) / 100.0
	var shape := BoxShape3D.new()
	match visual:
		&"tree":
			mesh_instance.mesh = PropMesh.build_tree(_visual_seed())
			# Collision stays the trunk only: you can stand under the canopy.
			shape.size = Vector3(0.7, 3.0, 0.7)
			collider.position = Vector3(0, 1.5, 0)
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
		&"seam":
			mesh_instance.mesh = PropMesh.build_seam(_visual_seed())
			shape.size = Vector3(2.0, 0.9, 1.3)
			collider.position = Vector3(0, 0.45, 0)
	collider.shape = shape
	_refresh_wedge_look()


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
	return "%s ×%d — E to gather" % [name, remaining_units]


## E on the node: the BASELINE route, always available (D-021). Returns
## {granted} when units came out, {text} for a step, {refusal} when not.
func work(sim: WroughtwildSim) -> Dictionary:
	if remaining_units <= 0:
		return {"refusal": "nothing left here"}
	if not workable():
		return {"refusal": work_refusal()}
	if not is_seam():
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
	if whole and remaining_units > 0:
		granted += harvest()
	wedge_set = false
	drive_progress = 0
	_refresh_wedge_look()
	return granted


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
	_wedge_mesh.position = Vector3(0.0, 0.62, 0.42)
	_wedge_mesh.rotation.x = -0.35
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
	var target := _scale_for_remaining()
	scale = target * 0.86
	var tween := create_tween()
	tween.tween_property(self, "scale", target, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _scale_for_remaining() -> Vector3:
	var fraction := float(remaining_units) / float(maxi(_initial_units, 1))
	return Vector3.ONE * lerpf(0.6, 1.0, fraction)


## The last harvest shrinks the node away instead of blinking it out.
## Collision goes immediately so the space is usable at once.
func _deplete() -> void:
	if not is_inside_tree():
		queue_free()
		return
	var collider: CollisionShape3D = get_node_or_null("CollisionShape3D")
	if collider != null:
		collider.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * 0.02, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
