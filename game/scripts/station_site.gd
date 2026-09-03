class_name StationSite
extends StaticBody3D
## A place in the valley where a crafting station is built and then used.
## Building pays the station's cost through the sim; the mesh grows with the
## station's tier so progress is visible from across the valley. A station
## fits the one build cell its kit was placed in (owner playtest, 3 Sep: a
## two-metre bench engulfed the post standing beside it).

@export var station_id: StringName = &"forge_basic"
## Station that upgrades this one (empty for none).
@export var upgrade_station_id: StringName = &"forge_improved"

@onready var _mesh: MeshInstance3D = $Mesh


func _ready() -> void:
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
			refresh_visual(sim)
			player.hud.notify("Built the %s." % info.get("display_name", station_id))
		else:
			player.hud.notify("Building the %s needs %s." % [
				info.get("display_name", station_id), WorkPanel.cost_text(info.get("build_cost", {}), sim)])
		return
	player.open_crafting(self)


func refresh_visual(sim: WroughtwildSim) -> void:
	if _mesh == null:
		return
	var box := BoxMesh.new()
	var material := StandardMaterial3D.new()
	if upgrade_station_id != &"" and sim.has_station(upgrade_station_id):
		box.size = Vector3(0.96, 2.0, 0.96)
		material.albedo_color = Color(0.35, 0.2, 0.15)
		material.emission_enabled = true
		material.emission = Color(1.0, 0.45, 0.1)
		material.emission_energy_multiplier = 1.5
	elif sim.has_station(station_id):
		box.size = Vector3(0.96, 1.4, 0.96)
		material.albedo_color = Color(0.3, 0.3, 0.32)
	else:
		box.size = Vector3(0.96, 0.2, 0.96)
		material.albedo_color = Color(0.55, 0.5, 0.4)
	_mesh.mesh = box
	_mesh.material_override = material
	_mesh.position.y = box.size.y / 2.0
