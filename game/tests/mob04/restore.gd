extends Sandpit
## One real generated Gloom Crawler pack through ordinary SaveManager/Continue.
var checks := 0
var failures := 0
const SAVE := "user://beetle-continue.json"
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL BEETLE CONTINUE: ",label)
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
func pack_for_beetle() -> Dictionary:
	for pack: Dictionary in mob_packs.packs:
		if "gloom_crawler" in pack.enemies: return pack
	return {}
func beetle_for(pack: Dictionary) -> Enemy:
	for member in pack.members:
		if is_instance_valid(member) and member.enemy_id == &"gloom_crawler": return member
	return null
func _run() -> void:
	var pack := pack_for_beetle()
	check(not pack.is_empty(),"ordinary seed 77 contains native Gloom Crawler")
	if pack.is_empty(): get_tree().quit(1); return
	var point := mob_packs.pack_position(pack)
	terrain.ensure_area(point,8)
	player.global_position = point + Vector3(0,1,24)
	if not pack.spawned: mob_packs._spawn_pack(pack,point)
	quiet()
	var enemy := beetle_for(pack)
	check(enemy != null and (enemy._mesh.get_node("Motion") as CreatureMotion).finished is BeetlePresentation,"generated native identity selects beetle")
	if enemy == null: get_tree().quit(1); return
	var kill_before := mob_packs.loot_kill_counter()
	var victim: Enemy = null
	for member in pack.members:
		if is_instance_valid(member) and member != enemy:
			victim = member
			break
	check(victim != null,"generated pack has a second native member for death check")
	if victim != null:
		victim.take_damage(victim.max_life*2)
		await get_tree().process_frame
		check(mob_packs.loot_kill_counter() == kill_before+1,"native generated death advances loot sequence exactly once")
	var motion := enemy._mesh.get_node("Motion") as CreatureMotion
	enemy.attack_released.emit("strike")
	motion.sample(.1,0)
	check(motion.release_left > 0 and motion.finished.pose == "release","generated actor has a transient strike before save")
	var manager := SaveManager.new()
	check(manager.write(SAVE,player),"write ordinary checkpoint: " + manager.last_error)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	check(manager.read(SAVE,player),"normal Continue read: " + manager.last_error)
	quiet()
	check(mob_packs.loot_kill_counter() == int(saved.loot_kill_counter),"Continue preserves native death/loot sequence")
	# Disk JSON numbers are floats; normalize the captured representation before
	# deep equality. This preserves every field and exact ownership assertion.
	check(JSON.parse_string(JSON.stringify(WorldDrops.capture(self))) == saved.world_drops,"Continue preserves native loose-drop snapshot including empty outcomes")
	check(world_seed == 77 and world_profile == "frontier_v6","Continue retains native world identity")
	check(_sim().export_json() == saved.sim and _sim().leyline_save() == saved.leylines,"Continue retains progression and finite-source ownership")
	pack = pack_for_beetle()
	point = mob_packs.pack_position(pack)
	if not pack.spawned: mob_packs._spawn_pack(pack,point)
	quiet()
	enemy = beetle_for(pack)
	check(enemy != null and (enemy._mesh.get_node("Motion") as CreatureMotion).finished is BeetlePresentation,"Continue instantiates native beetle")
	if enemy != null:
		motion = enemy._mesh.get_node("Motion")
		check(motion.release_left == 0 and motion.finished.pose == "idle","Continue clears the unsaved cosmetic strike")
		check(enemy._mesh.get_child_count() == 1 and enemy.attack_released.get_connections().size() == 1,"Continue has one rig and one release observer")
	var evidence := FileAccess.open(OS.get_environment("WROUGHTWILD_BEETLE_OUTPUT")+"/restore-checks.json",FileAccess.WRITE)
	evidence.store_string(JSON.stringify({"passed":checks-failures,"failed":failures,"seed":77,"world_profile":world_profile,"loot_kill_counter":mob_packs.loot_kill_counter(),"loose_pickups":saved.world_drops.pickups.size(),"pack_position":[point.x,point.y,point.z],"pack_biome":pack.biome},"\t"))
	print("BEETLE_CONTINUE %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
