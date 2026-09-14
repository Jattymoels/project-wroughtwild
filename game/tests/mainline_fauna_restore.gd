extends Sandpit
## One native finite-host sleep/save/restore check, with private test ownership.
var checks := 0
var failures := 0
const SAVE := "user://a2-finite-host.json"
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL A2 RESTORE: ",label)
func _ready() -> void:
	world_seed = 77
	world_profile = "living_frontier_wave3"
	_build_world(world_seed)
	player.class_panel.choose("warden")
	quiet()
	_run.call_deferred()
func quiet() -> void:
	for node in [self,player,player.combat,player.placement,player.spring_arm,mob_packs]: node.set_physics_process(false)
	for enemy in get_tree().get_nodes_in_group("enemies"): enemy.set_physics_process(false)
func host_pack() -> Dictionary:
	for pack: Dictionary in mob_packs.packs:
		if pack.get("frontier_host_id", "") == "lf3_red_rooting": return pack
	return {}
func _run() -> void:
	var pack := host_pack()
	check(not pack.is_empty(), "actual generated finite Red habitat exists")
	var point := mob_packs.pack_position(pack)
	terrain.ensure_area(point, 8)
	player.global_position = point + Vector3(0,1,24)
	mob_packs._spawn_pack(pack,point)
	check(pack.members.size() == 1, "one current actor per finite owner")
	var host: Enemy = pack.members[0]
	host.set_physics_process(false)
	check((host._mesh.get_node("Motion") as CreatureMotion).finished != null, "native pack uses finished binding")
	var owned := _sim().export_json()
	host.since_hurt = mob_packs.sleep_after_seconds + 1
	check(mob_packs.sleep_far_packs(point + Vector3(0,0,200)) == 1, "calm finite host streams out")
	await get_tree().process_frame
	mob_packs._spawn_pack(pack,point)
	host = pack.members[0]
	host.set_physics_process(false)
	check(pack.members.size() == 1 and host._mesh.get_child_count() == 1 and (host._mesh.get_node("Motion") as CreatureMotion).finished != null, "streamed return has one finished visual")
	check(_sim().export_json() == owned and mob_packs.loot_kill_counter() == 0, "sleep and return pay no rewards")
	host.take_damage(host.max_life*2)
	var once := WorldDrops.capture(self)
	mob_packs._on_enemy_died(host)
	check(WorldDrops.capture(self) == once and mob_packs.loot_kill_counter() == 1, "duplicate death cannot pay twice")
	await get_tree().process_frame
	var manager := SaveManager.new()
	check(manager.write(SAVE,player), "write actual whole-game checkpoint: " + manager.last_error)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	# Compare every field at the same JSON precision on both sides. SaveManager
	# writes full-precision doubles; restored spatial fields are Godot float32.
	var saved_drops: Dictionary = JSON.parse_string(JSON.stringify(saved.world_drops))
	check(manager.read(SAVE,player), "restore via Continue save manager: " + manager.last_error)
	quiet()
	check(world_seed == 77 and world_profile == "living_frontier_wave3", "saved world identity restored")
	check(_sim().export_json() == saved.sim and _sim().leyline_save() == saved.leylines, "exact progression, materials and finite source ownership restored")
	check(JSON.parse_string(JSON.stringify(WorldDrops.capture(self))) == saved_drops and mob_packs.loot_kill_counter() == 1, "loose rewards and kill stream restored once")
	pack = host_pack()
	mob_packs._spawn_pack(pack,mob_packs.pack_position(pack))
	check(pack.members.is_empty() and _sim().world_effect_active("host_defeated:lf3_red_rooting"), "saved finite death forbids respawn")
	check(JSON.parse_string(JSON.stringify(WorldDrops.capture(self))) == saved_drops, "respawn refusal adds no rewards")
	print("A2_RESTORE %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
