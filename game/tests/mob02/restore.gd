extends Sandpit
## One real generated Stone Husk pack through ordinary SaveManager/Continue.
var checks := 0
var failures := 0
const SAVE := "user://ram-continue.json"
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL RAM CONTINUE: ",label)
func _ready() -> void:
	world_seed = 77
	world_profile = "frontier_v6"
	_build_world(world_seed)
	player.class_panel.choose("warden")
	quiet()
	_run.call_deferred()
func quiet() -> void:
	for node in [self,player,player.combat,player.placement,player.spring_arm,mob_packs]: node.set_physics_process(false)
	for node in get_tree().get_nodes_in_group("enemies"):
		node.set_physics_process(false)
		node._mesh.get_node("Motion").set_physics_process(false)
func pack_for_ram() -> Dictionary:
	for pack: Dictionary in mob_packs.packs:
		if "stone_husk" in pack.enemies: return pack
	return {}
func ram_for(pack: Dictionary) -> Enemy:
	for member in pack.members:
		if is_instance_valid(member) and member.enemy_id == &"stone_husk": return member
	return null
func _run() -> void:
	var pack := pack_for_ram()
	check(not pack.is_empty(),"ordinary seed 77 contains native Stone Husk")
	if pack.is_empty(): get_tree().quit(1); return
	var point := mob_packs.pack_position(pack)
	terrain.ensure_area(point,8)
	player.global_position = point + Vector3(0,1,24)
	if not pack.spawned: mob_packs._spawn_pack(pack,point)
	quiet()
	var enemy := ram_for(pack)
	check(enemy != null and (enemy._mesh.get_node("Motion") as CreatureMotion).finished is RamPresentation,"generated native identity selects ram")
	if enemy == null: get_tree().quit(1); return
	var motion := enemy._mesh.get_node("Motion") as CreatureMotion
	enemy.attack_released.emit("strike")
	motion.sample(.1,0)
	check(motion.release_left > 0 and motion.finished.pose == "release","generated actor has a transient strike before save")
	var manager := SaveManager.new()
	check(manager.write(SAVE,player),"write ordinary checkpoint: " + manager.last_error)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	check(manager.read(SAVE,player),"normal Continue read: " + manager.last_error)
	quiet()
	check(world_seed == 77 and world_profile == "frontier_v6","Continue retains native world identity")
	check(_sim().export_json() == saved.sim and _sim().leyline_save() == saved.leylines,"Continue retains progression and finite-source ownership")
	pack = pack_for_ram()
	point = mob_packs.pack_position(pack)
	if not pack.spawned: mob_packs._spawn_pack(pack,point)
	quiet()
	enemy = ram_for(pack)
	check(enemy != null and (enemy._mesh.get_node("Motion") as CreatureMotion).finished is RamPresentation,"Continue instantiates native ram")
	if enemy != null:
		motion = enemy._mesh.get_node("Motion")
		check(motion.release_left == 0 and motion.finished.pose == "idle","Continue clears the unsaved cosmetic strike")
		check(enemy._mesh.get_child_count() == 1 and enemy.attack_released.get_connections().size() == 1,"Continue has one rig and one release observer")
	print("RAM_CONTINUE %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
