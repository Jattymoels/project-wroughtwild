extends Sandpit
## One actual generated Cinder Archer pack through sleep, whole-game Continue and death.
var checks := 0
var failures := 0
const SAVE := "user://mob01-continue.json"
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL MOB01 RESTORE: ",label)
func _ready() -> void:
	world_seed = 77
	world_profile = "frontier_v6"
	_build_world(world_seed)
	player.class_panel.choose("warden")
	quiet()
	_run.call_deferred()
func quiet() -> void:
	for node in [self,player,player.combat,player.placement,player.spring_arm,mob_packs]: node.set_physics_process(false)
	for node in get_tree().get_nodes_in_group("enemies"): node.set_physics_process(false)
func archer_pack() -> Dictionary:
	for pack: Dictionary in mob_packs.packs:
		if "cinder_archer" in pack.enemies: return pack
	return {}
func archer(pack: Dictionary) -> Enemy:
	for member in pack.members:
		if is_instance_valid(member) and member.enemy_id == &"cinder_archer": return member
	return null
func _run() -> void:
	var pack := archer_pack()
	check(not pack.is_empty(),"ordinary V6 generation contains existing Cinder Archer")
	if pack.is_empty(): get_tree().quit(1); return
	var point := mob_packs.pack_position(pack)
	terrain.ensure_area(point,8)
	player.global_position = point + Vector3(0,1,24)
	mob_packs._spawn_pack(pack,point)
	quiet()
	var enemy := archer(pack)
	check(enemy != null and (enemy._mesh.get_node("Motion") as CreatureMotion).finished is PorcupinePresentation,"ordinary generated pack selects the rig")
	var count: int = pack.members.size()
	var owned := _sim().export_json()
	var kill_count := mob_packs.loot_kill_counter()
	for member: Enemy in pack.members:
		member.state = "idle"
		member.since_hurt = mob_packs.sleep_after_seconds + 1
	mob_packs.sleep_far_packs(point + Vector3(0,0,200))
	check(pack.members.is_empty() and not pack.spawned,"calm native pack streams out")
	await get_tree().process_frame
	mob_packs._spawn_pack(pack,point)
	quiet()
	enemy = archer(pack)
	check(pack.members.size() == count and enemy != null and enemy._mesh.get_child_count() == 1 and (enemy._mesh.get_node("Motion") as CreatureMotion).finished is PorcupinePresentation,"streamed return has one porcupine per original actor")
	check(_sim().export_json() == owned and mob_packs.loot_kill_counter() == kill_count,"streaming changes no rewards or ownership")
	var manager := SaveManager.new()
	check(manager.write(SAVE,player),"write normal SaveManager checkpoint: " + manager.last_error)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	check(manager.read(SAVE,player),"read through normal Continue path: " + manager.last_error)
	quiet()
	check(world_seed == 77 and world_profile == "frontier_v6","Continue keeps world identity")
	check(_sim().export_json() == saved.sim and _sim().leyline_save() == saved.leylines,"Continue keeps progression, paid ownership and finite sources")
	check(mob_packs.loot_kill_counter() == kill_count,"Continue retains native kill stream")
	pack = archer_pack()
	point = mob_packs.pack_position(pack)
	if not pack.spawned: mob_packs._spawn_pack(pack,point)
	quiet()
	enemy = archer(pack)
	check(enemy != null and (enemy._mesh.get_node("Motion") as CreatureMotion).finished is PorcupinePresentation,"Continue-generated native identity still instantiates porcupine")
	var motion: CreatureMotion = enemy._mesh.get_node("Motion")
	var prior_clock := motion.finished.clock
	enemy.take_damage(enemy.max_life*2)
	var drops := WorldDrops.capture(self)
	enemy.take_damage(enemy.max_life*2)
	motion.sample(.1,1)
	check(motion.finished.clock == prior_clock,"death stops pose/material sampling")
	check(mob_packs.loot_kill_counter() == kill_count+1 and WorldDrops.capture(self) == drops,"second hit on dead actor cannot pay another kill or drop")
	await get_tree().process_frame
	check(not is_instance_valid(enemy),"native death removes body and rig")
	check(manager.write(SAVE,player),"write paid death rewards through normal save path")
	saved = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	check(manager.read(SAVE,player),"Continue after death: " + manager.last_error)
	quiet()
	check(_sim().export_json() == saved.sim and mob_packs.loot_kill_counter() == kill_count+1,"death rewards/progression retain their existing ownership")
	check(JSON.parse_string(JSON.stringify(WorldDrops.capture(self))) == JSON.parse_string(JSON.stringify(saved.world_drops)),"saved loose drops restore exactly at matching JSON precision")
	print("MOB01_RESTORE %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
