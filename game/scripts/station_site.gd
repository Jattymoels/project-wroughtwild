class_name StationSite
extends StaticBody3D
## A place in the valley where a crafting station is built and then used.
## Building pays the station's cost through the sim; the mesh grows with the
## station's tier so progress is visible from across the valley. A station
## fits the one build cell its kit was placed in (owner playtest, 3 Sep: a
## two-metre bench engulfed the post standing beside it).

## Shared with the placed scene: preview fit must keep the existing physical
## body, including the deliberately unchanged air above low work surfaces.
const BODY = preload("res://scenes/station_body.tres")
const WORK_LOOK = preload("res://art/workshop_feedback_look.tres")

static func kit_mesh(sim: WroughtwildSim, kit_id: StringName) -> Mesh:
	var id := StringName(sim.kit_station(kit_id))
	# Station upgrades are existing global knowledge. A newly placed basic
	# forge therefore shows the same upgraded silhouette its site will use.
	for other in sim.station_ids():
		if sim.station(other).get("upgrade_from", "") == String(id) and sim.has_station(other):
			return preload("res://art/station_look.tres").mesh_for(StringName(other))
	return preload("res://art/station_look.tres").mesh_for(id)

@export var station_id: StringName = &"forge_basic"
## Station that upgrades this one (empty for none).
@export var upgrade_station_id: StringName = &"forge_improved"
## Physical ownership is separate from the globally unlocked station recipe.
## Generated ruins and old saves without this evidence cannot power a feeder.
@export var player_built := false
@export var station_key := ""

@onready var _mesh: MeshInstance3D = $Mesh


func _ready() -> void:
	add_to_group("crafting_stations")
	refresh_visual(load("res://scripts/sim.gd").shared())


func is_built(sim: WroughtwildSim) -> bool:
	return sim.has_station(station_id)


## The highest tier the player has built here, or the base id when unbuilt.
func current_station_id(sim: WroughtwildSim) -> StringName:
	if upgrade_station_id != &"" and sim.has_station(upgrade_station_id):
		return upgrade_station_id
	return station_id


## Player interaction: build when unbuilt (if affordable), otherwise work here.
func interact(player: WroughtwildPlayer) -> void:
	var sim := player.inventory.get_sim()
	if not is_built(sim):
		var info: Dictionary = sim.station(station_id)
		if sim.build_station(station_id):
			player_built = true
			if station_key.is_empty(): station_key = key_at(String(station_id), global_position)
			refresh_visual(sim)
			player.hud.notify("Built the %s." % info.get("display_name", station_id))
		else:
			player.hud.notify("Building the %s needs %s." % [
				info.get("display_name", station_id), WorkPanel.cost_text(info.get("build_cost", {}), sim)])
		return
	player.open_crafting(self)


static func key_at(id: String, at: Vector3) -> String:
	# Millimetre coordinates remain stable through JSON round trips and allow
	# stations placed on the existing half-grid without colliding identities.
	return "station_%s_%d_%d_%d" % [id,roundi(at.x*1000),roundi(at.y*1000),roundi(at.z*1000)]


func feeder_eligible(rules: WroughtwildSim) -> bool:
	return player_built and not station_key.is_empty() and station_id == &"forge_basic" and is_built(rules)


## Called only after the active panel's successful manual craft. This response
## cannot consume fuel, move station collision or stand in for feeder progress.
func craft_completed(sim: WroughtwildSim) -> void:
	if not is_built(sim) or not is_inside_tree() or is_queued_for_deletion(): return
	var id := current_station_id(sim)
	var cue := InteractionSound.craft_cue(String(id))
	if cue.is_empty(): return
	var mount: Vector3 = WORK_LOOK.mount_for(id)
	var scene := get_parent()
	if scene != null: InteractionSound.play(scene, to_global(mount), cue)
	# At most one response per local station, even when batches are clicked fast.
	var previous := get_node_or_null("CraftWorkResponse")
	if previous != null:
		previous.remove_from_group("workshop_feedback")
		remove_child(previous)
		previous.queue_free()
	var response := Node3D.new()
	response.name = "CraftWorkResponse"
	response.position = mount
	response.set_meta("cue", cue)
	add_child(response)
	response.add_to_group("workshop_feedback")
	var finish := StandardMaterial3D.new()
	finish.albedo_color = WORK_LOOK.colour_for(id)
	finish.roughness = 1.0
	var chip := BoxMesh.new()
	chip.size = WORK_LOOK.fleck_size
	chip.material = finish
	var animation := response.create_tween().set_parallel(true)
	for index in WORK_LOOK.fleck_count:
		var fleck := MeshInstance3D.new()
		fleck.mesh = chip
		fleck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var angle := TAU * float(index) / float(WORK_LOOK.fleck_count)
		fleck.rotation = Vector3(angle, angle, 0)
		response.add_child(fleck)
		var destination := Vector3(cos(angle) * WORK_LOOK.spread, WORK_LOOK.rise, sin(angle) * WORK_LOOK.spread)
		animation.tween_property(fleck, "position", destination, WORK_LOOK.duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		animation.tween_property(fleck, "scale", Vector3.ZERO, WORK_LOOK.duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	animation.chain().tween_callback(response.queue_free)


func refresh_visual(sim: WroughtwildSim) -> void:
	if _mesh == null:
		return
	var look := preload("res://art/station_look.tres")
	var light := get_node_or_null("HearthLight") as OmniLight3D
	if sim.has_station(station_id):
		_mesh.mesh = look.mesh_for(current_station_id(sim))
		_mesh.material_override = null if AuthoredAssets.mesh_for(String(current_station_id(sim))) != null else ArtGeometry.material()
		_mesh.position = Vector3.ZERO
		if String(station_id).begins_with("forge_"):
			if light==null:
				light = OmniLight3D.new()
				light.name = "HearthLight"
				light.position = Vector3(0,1.05,-0.3)
				add_child(light)
			light.light_color = look.ember
			light.light_energy = look.hearth_energy
			light.omni_range = look.hearth_range
			light.show()
		return
	if light!=null:
		light.hide()
	var box := BoxMesh.new()
	var material := StandardMaterial3D.new()
	box.size = Vector3(0.96, 0.2, 0.96)
	material.albedo_color = Color(0.55, 0.5, 0.4)
	_mesh.mesh = box
	_mesh.material_override = material
	_mesh.position.y = box.size.y / 2.0
