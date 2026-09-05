extends Node3D
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func clear_pickups() -> void:
	for child in get_children():
		if child is Pickup:
			child.free()

func _ready() -> void:
	var player: WroughtwildPlayer = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	var mobs := MobPacks.new()
	mobs.name = "MobPacks"
	add_child(mobs)
	mobs.set_process(false)
	mobs.world_seed = 1
	var enemy := Enemy.spawn(self, &"ember_whelp", Vector3(0,0,10))
	enemy.set_physics_process(false)
	var sim := player.inventory.get_sim()
	# At seed 1, kill 56 is a bow. It must be the same next kill after
	# either a fresh process or an in-session load, not restart at kill 1.
	mobs.restore_loot_counter(55)
	var manager := SaveManager.new()
	var saved := manager.capture(player)
	check(int(saved.loot_kill_counter) == 55, "save captures the consumed loot sequence")
	mobs._on_enemy_died(enemy)
	var original_seed := 0
	for child in get_children():
		if child is Pickup and child.kind == "gear":
			original_seed = child.gear_seed
	check(original_seed == 1 + 56 * 7919, "normal death hook uses the next kill seed")
	clear_pickups()
	# A genuinely fresh MobPacks object reproduces restarting the process.
	mobs.free()
	mobs = MobPacks.new()
	mobs.name = "MobPacks"
	add_child(mobs)
	mobs.set_process(false)
	mobs.world_seed = 1
	check(mobs.loot_kill_counter() == 0, "fresh process starts with no in-memory history")
	check(manager.apply(player, JSON.parse_string(JSON.stringify(saved))), "new save reloads through JSON")
	check(mobs.loot_kill_counter() == 55, "fresh process resumes saved history")
	mobs._on_enemy_died(enemy)
	var resumed_seed := 0
	for child in get_children():
		if child is Pickup and child.kind == "gear":
			resumed_seed = child.gear_seed
	check(resumed_seed == original_seed, "first post-load drop matches uninterrupted play")
	clear_pickups()
	mobs.restore_loot_counter(900)
	check(manager.apply(player, saved) and mobs.loot_kill_counter() == 55, "F9 rewinds loot history with the rest of the save")
	var legacy := saved.duplicate(true)
	legacy.erase("loot_kill_counter")
	check(manager.apply(player, legacy) and mobs.loot_kill_counter() == 0, "old v2 save remains readable without guessing lost history")
	mobs.restore_loot_counter(75)
	check(manager.capture(player).loot_kill_counter == 75, "subsequent legacy-save progress is preserved")
	mobs.restore_loot_counter(-10)
	check(mobs.loot_kill_counter() == 0, "negative history is clamped")
	# Distribution check uses the actual engine binding and game's seed
	# schedule, rather than a replacement random generator or retuned table.
	var counts := {}
	var total := 0
	for kill in range(1, 50001):
		for item in sim.enemy_gear_loot("ember_whelp", 1 + kill * 7919):
			counts[item.base_id] = int(counts.get(item.base_id, 0)) + 1
			total += 1
	check(total > 1000, "audit has enough actual equipment drops to assess distribution")
	check(counts.size() == sim.item_base_ids().size(), "every equipment base appears")
	for id in sim.item_base_ids():
		var fraction := float(counts.get(id,0)) / total
		check(fraction > 0.04 and fraction < 0.105, "%s stays near equal base odds in 50,000 kills" % id)
	print("CODEX_LOOT_PERSISTENCE %d checks, %d failures; %d gear, %d bows" % [checks,failures,total,int(counts.get("hunting_bow",0))+int(counts.get("bronze_longbow",0))])
	get_tree().quit(0 if failures == 0 else 1)
