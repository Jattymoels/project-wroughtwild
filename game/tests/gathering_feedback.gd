extends Node3D
var checks := 0
var failures := 0
var player: WroughtwildPlayer

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func _ready() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.position = Vector3(0,1.1,0)
	var sim := player.inventory.get_sim()
	var tree: ResourceNode = preload("res://scenes/resource_node.tscn").instantiate()
	tree.visual = &"tree"
	tree.remaining_units = 14
	tree.units_per_harvest = 14
	tree.drive_presses = 6
	tree.position = Vector3(0,0,-2.5)
	add_child(tree)
	for i in 3:
		await get_tree().physics_frame
	check(player.aim_probe().target == tree, "normal interaction ray selects the work target")
	var start := sim.material_count("wood")
	var before := tree.work_view(sim)
	check(before.fraction == 0.0 and before.text.contains("next yield 14 wood"), "shows actual next tree payout before work")
	player.interact()
	player.hud._refresh_crosshair()
	check(tree.drive_progress == 1 and tree.remaining_units == 14 and sim.material_count("wood") == start, "work feedback grants no early materials")
	check(is_equal_approx(player.hud._work_meter.value,1.0/6.0) and player.hud._work_display.visible, "normal HUD reads partial work")
	var hands := player.camera.get_node("FirstPersonHands") as FirstPersonHands
	check(hands.active_delivery == "gather" and hands.remaining > 0, "accepted work moves the hand")
	check(get_tree().get_nodes_in_group("gathering_impacts").size() == 1, "accepted ray hit emits one impact burst")
	var saved := SaveManager.new().capture(player)
	tree.drive_progress = 4
	check(SaveManager.new().apply(player,JSON.parse_string(JSON.stringify(saved))), "partial work save round trips")
	check(tree.drive_progress == 1 and tree.work_view(sim).fraction == before.fraction + 1.0/6.0, "saved partial work restores the same progress display")
	player.inventory_panel.open_panel()
	player.hud._refresh_crosshair()
	check(not player.hud._work_display.visible, "work meter hides behind pack")
	player.inventory_panel.close_panel()
	player.placement.build_mode_enabled = true
	player.hud._refresh_crosshair()
	check(not player.hud._work_display.visible, "work meter hides in building mode")
	player.placement.build_mode_enabled = false
	player.rotation.y = PI
	player.hud._refresh_crosshair()
	check(not player.hud._work_display.visible, "looking away clears target progress")
	player.rotation.y = 0
	# Finish through the actual work dispatcher, retaining the existing pickup path.
	for i in 5:
		player._apply_work(tree,tree.work(sim))
	check(tree.remaining_units == 0 and tree.work_view(sim).is_empty(), "depletion removes the work display")
	check(sim.material_count("wood") == start and player.hud._notice.text.contains("Freed 14 wood"), "freed yield is not labelled as already carried")
	for i in 140:
		await get_tree().physics_frame
	check(sim.material_count("wood") == start+14, "absorption grants the original full yield once")
	check(player.hud._pickup_label.text.contains("+14 wood") and player.hud._pickup_label.text.contains("carried %d" % (start+14)), "collection reports actual gain and carried total")
	check(get_tree().get_nodes_in_group("gathering_impacts").is_empty(), "impact fragments expire instead of littering the ground")
	var seam := ResourceNode.new()
	seam.tool_item = &"timber_wedge"
	seam.material_family = &"split_stone"
	seam.drive_presses = 4
	seam.units_per_harvest = 3
	add_child(seam)
	check(not seam.work_view(sim).ready, "missing wedge explains the gate")
	hands.remaining = 0
	player._apply_work(seam,seam.work(sim), {"position":Vector3.ZERO,"normal":Vector3.UP})
	check(hands.remaining == 0 and get_tree().get_nodes_in_group("gathering_impacts").is_empty(), "refused work has no success gesture or fragments")
	sim.add_material("timber_wedge",1)
	player._apply_work(seam,seam.work(sim))
	check(seam.wedge_set and seam.work_view(sim).fraction == 0 and sim.material_count("timber_wedge")==0, "setting the wedge costs once and starts drive progress")
	player._apply_work(seam,seam.work(sim))
	check(seam.work_view(sim).fraction == 0.25, "wedge progress uses its own required press count")
	seam.strike()
	check(not seam.wedge_set and seam.drive_progress == 0, "heavy strike still shortcuts the remaining presses")
	for i in 15:
		GatheringImpact.spawn(self,Vector3.ZERO,Vector3.UP,true,i)
	check(get_tree().get_nodes_in_group("gathering_impacts").size() == GatheringImpact.LOOK.max_bursts, "rapid input has a bounded fragment budget")
	print("CODEX_GATHERING %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
