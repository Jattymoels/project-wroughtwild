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
		print("CODEX_WEATHERED_SAVE %d checks, %d failures" % [checks,failures])
		get_tree().quit(0 if failures==0 else 1)
