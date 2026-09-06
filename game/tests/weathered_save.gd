extends "res://scripts/sandpit.gd"
## Save/load coverage on the actual default world; disk IO stays in build/.
var checks := 0
var failures := 0
var frame := 0
var seam_name: String
var seam_vertices := PackedVector3Array()
var saved: Dictionary
var save_path := ""

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)

func _ready() -> void:
	# Preserve this historical v3 regression; cataclysm_intensive checks the new default.
	world_profile = "frontier_v3"
	super._ready()
	player.class_panel.choose("warden")
	check(terrain.weathered and terrain.faceted_surface,"ordinary game selects weathered faceted terrain")
	for node in terrain.nodes_root.get_children():
		if node.visual==&"seam" and node.get_node("MeshInstance3D").mesh != null:
			seam_name = String(node.name)
			seam_vertices = node.get_node("MeshInstance3D").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			node.cracked = true
			node.remaining_units = 7
			node.drive_progress = 2
			break
	check(not seam_name.is_empty(),"default world has a grounded seam")
	save_path = ProjectSettings.globalize_path("res://../build/codex-aesthetic/weathered-save.json")
	var manager := SaveManager.new()
	check(manager.write(save_path,player),"save default world to isolated disk file")
	saved = manager.capture(player)
	# Simulate a schema-2 save written before optional visual metadata existed.
	for entry in saved.resource_nodes:
		entry.erase("visual")
	var seam: ResourceNode = terrain.nodes_root.get_node(seam_name)
	seam.free()
	check(manager.apply(player,saved),"older schema-2 save restores a resource depleted since saving")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	frame += 1
	if frame==4:
		var seam: ResourceNode = terrain.nodes_root.get_node(seam_name)
		check(seam.visual==&"seam" and seam.cracked and seam.remaining_units==7 and seam.drive_progress==2,"resource restores appearance and harvesting state")
		check(seam.get_node("MeshInstance3D").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==seam_vertices,"restored resource uses exact grounded geometry")
		check(seam.harvest()>0,"grounded restored seam can still be harvested")
		check(seam.scale==Vector3.ONE,"harvesting does not pull the surface ribbon off the ground")
		var manager := SaveManager.new()
		check(manager.read(save_path,player),"new save reloads through normal file path")
		_check_art_lifecycle(manager)
		print("CODEX_WEATHERED_SAVE %d checks, %d failures" % [checks,failures])
		get_tree().quit(0 if failures==0 else 1)


func _check_art_lifecycle(manager: SaveManager) -> void:
	# Use actual generated saves and the same live scene in both directions:
	# a v3 world must not leave its replacement sky/material on an older save.
	var env: Environment = $WorldEnvironment.environment
	var light: DirectionalLight3D = $Sun
	var v3 := manager.capture(player)
	check(terrain.frontier_look.resource_path=="res://art/wildland_look.tres"
		and env.sky.sky_material is ShaderMaterial and env.ssao_enabled,
		"v3 starts with new terrain, shader sky and contact depth")
	check(apply_world_identity(world_seed,"frontier_v2"),"construct an authentic v2 save in the live scene")
	var v2 := manager.capture(player)
	check(manager.apply(player,v3),"load v3 over the v2 world")
	check(manager.apply(player,v2),"load v2 over the v3 world")
	var restored: bool = env.sky==mood._presentation_baseline.sky
	for property in ["ssao_enabled","ssao_radius","ssao_intensity","ssao_power","ssao_detail","fog_sky_affect"]:
		restored = restored and env.get(property)==mood._presentation_baseline[property]
	check(restored and env.sky.sky_material is ProceduralSkyMaterial,
		"v2 restores the original sky and every modified contact/fog setting")
	var old_material := terrain._material_for("grass") as ShaderMaterial
	check(terrain.atmosphere_look==null and terrain.frontier_look.resource_path=="res://art/weathered_look.tres"
		and old_material.shader.resource_path=="res://art/frontier_terrain.gdshader",
		"v2 restores its old terrain resource and clears the v3 material cache")
	check(manager.apply(player,v3),"return to the saved v3 world")
	var new_material := terrain._material_for("grass") as ShaderMaterial
	check(terrain.atmosphere_look!=null and env.ssao_enabled and env.sky.sky_material is ShaderMaterial
		and new_material.shader.resource_path=="res://art/wildland_terrain.gdshader",
		"v3 reentry restores its terrain, sky and contact depth")
	# The presentation resource follows the established clock/era rather than
	# creating a second world state, including after the resource is replaced.
	var state_before := _sim().export_json()
	mood._target = mood.active_mood("meadow")
	mood.set_day({"daylight":1.0,"fraction":0.3},_sim().day_rules())
	mood.set_era(1)
	mood._apply(1.0)
	var sky := env.sky.sky_material as ShaderMaterial
	var day_top: Color = sky.get_shader_parameter("sky_top")
	var day_energy := light.light_energy
	var day_rotation := light.rotation
	check(day_top.is_equal_approx(mood._target.sky_top),"v3 daylight keeps the selected biome sky palette")
	mood.set_day({"daylight":0.0,"fraction":0.8},_sim().day_rules())
	mood._apply(1.0)
	var night_top: Color = sky.get_shader_parameter("sky_top")
	check(night_top.r<day_top.r and night_top.b<day_top.b and light.light_energy<day_energy
		and not light.rotation.is_equal_approx(day_rotation),"v3 sky and sun still follow the ordinary night clock")
	mood.set_day({"daylight":1.0,"fraction":0.3},_sim().day_rules())
	mood.set_era(2)
	mood._apply(1.0)
	var era_top: Color = sky.get_shader_parameter("sky_top")
	check(era_top.is_equal_approx(day_top*Color(0.9,0.82,0.8)) and is_equal_approx(light.light_energy,day_energy*0.9)
		and light.rotation.is_equal_approx(day_rotation),"v3 retains the existing era tint without changing the sun clock")
	check(_sim().export_json()==state_before,"presentation sampling never changes world/player rules state")
	mood.set_day(_sim().day(),_sim().day_rules())
	mood.set_era(int(_sim().era().index))
	mood._target = mood.active_mood(mood._biome_under_player())
	mood._apply(1.0)
