extends Node3D
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var sim: WroughtwildSim
var panel: WorkPanel
var combat: PlayerCombat
var capture := false

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)

func settle() -> void:
	for i in 8: await get_tree().process_frame

func spawn_hostile(at: Vector3) -> Enemy:
	var enemy := Enemy.spawn(self,&"ember_whelp",at)
	enemy.set_physics_process(false)
	enemy.max_life = 10000
	enemy.life = 10000
	return enemy

func screenshot(name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../build/codex-aesthetic/forge-"+name+".png")
	check(get_viewport().get_texture().get_image().save_png(path)==OK,"capture "+name)
	print("CODEX_FORGE_CAPTURE ",path)

func _ready() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	get_window().size = Vector2i(1280,720)
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	combat = player.combat
	combat.set_physics_process(false)
	sim = combat.sim
	panel = player.work_panel
	sim.add_station("workbench")
	sim.add_materials({"wood":35,"hide":8})
	var bench := StationSite.new()
	bench.station_id = &"workbench"
	bench.upgrade_station_id = &""
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	bench.add_child(mesh)
	add_child(bench)
	panel.open_crafting(bench)
	panel.catalogue.select_recipe("simple_bow")
	await settle()
	check(panel.catalogue.last_preview.ready,"bench starter preview ready from wood and hide")
	check(panel.catalogue.last_preview.grades.size()==3,"locked later grades visible from first craft")
	check(not panel.catalogue.last_preview.grades[1].available,"Sound is inspectable but not available at the bench")
	var inventory: Dictionary = sim.inventory().duplicate(true)
	panel.catalogue.quality = 2
	panel.catalogue._render_detail()
	check(not panel.catalogue.last_preview.ready and sim.inventory()==inventory,"inspecting a locked grade spends nothing")
	panel.catalogue.quality = 1
	panel.catalogue._render_detail()
	check(panel.craft("simple_bow").crafted,"first useful bow is craftable before metallurgy")
	check(sim.pack_items().back().workpiece_tier==1,"starter result reports Rough capacity")
	panel.catalogue.select_recipe("charred_brand",true)
	panel.catalogue.select_recipe("smelt_iron",true)
	check(panel.catalogue.history.back()=="charred_brand","ingredient navigation retains return path")
	panel.catalogue.select_recipe("wooden_focus")
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		get_window().size = resolution
		panel.refresh()
		await settle()
		var rect := panel._root.get_global_rect()
		check(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=resolution.x+1 and rect.end.y<=resolution.y+1,"forge catalogue fits "+str(resolution)+" "+str(rect))
		check(panel.catalogue._action.get_global_rect().end.y<=resolution.y,"primary action stays outside scrolling content")
		await screenshot("starter-"+str(resolution.y))
	panel.catalogue.pinned = "simple_bow"
	panel.close_panel()
	panel.catalogue._pin_clock = 0
	panel.catalogue._process(0.5)
	check(panel.catalogue._pin_hud.visible and panel.catalogue._pin_hud.text.contains("Simple Bow"),"pinned requirements remain visible during play")
	panel.catalogue.pinned = ""
	sim.add_station("forge_basic")
	sim.add_station("forge_improved")
	var saved: Dictionary = JSON.parse_string(sim.export_json())
	saved.economy.skill_xp.blacksmithing = 1000
	check(sim.import_json(JSON.stringify(saved)),"setup experienced smith without changing owned gear")
	sim.add_materials({"wood":100,"charcoal":20,"iron_ingot":30,"bog_iron":8,"ember_catalyst":6,"sound_iron_ingot":4})
	check(sim.craft("refine_stable_ember_catalyst").crafted,"Stable reagent recipe consumes inventory Kind and expedition material")
	bench.station_id = &"forge_basic"
	bench.upgrade_station_id = &"forge_improved"
	panel.open_crafting(bench)
	panel.catalogue.select_recipe("charred_brand")
	panel.catalogue.aim = "stable_ember_catalyst"
	panel.catalogue._render_detail()
	check(panel.catalogue.last_preview.ready,"graded reagent in purse participates in craft preview")
	check(panel.catalogue.last_preview.potency==2 and panel.catalogue.last_preview.quality==1,"preview distinguishes stored potency from weak capacity")
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		get_window().size = resolution
		panel.refresh()
		await settle()
		await screenshot("stable-"+str(resolution.y))
	check(panel.craft("charred_brand","stable_ember_catalyst").crafted,"selected Stable imprint actually crafts")
	check(sim.pack_items().back().mods.any(func(mod: Dictionary) -> bool: return bool(mod.get("held_back",false))),"actual item exposes held-back potency")
	check(sim.foundry().kinds.any(func(kind: Dictionary) -> bool: return String(kind.id)=="stable_ember_catalyst"),"Foundry tray includes grade-specific Kind stocks")
	sim.add_material("stable_ember_catalyst",1)
	sim.add_material("iron_chest_armour",1)
	check(sim.equip_from_inventory("iron_chest_armour"),"prepare worn legacy-capacity chest for specialised temper")
	check(sim.catalyst_process("ember_catalyst_tempering").catalyst_held==1,"temper preview reads Stable catalyst from the pouch")
	var temper_result: Dictionary = sim.temper_with_catalyst("ember_catalyst_tempering")
	check(temper_result.applied and sim.currency_count("stable_ember_catalyst")==0,"specialised temper spends its actual selected grade")
	sim.add_material("stable_frost_catalyst",1)
	check(sim.foundry_place_kind(2,0,"stable_frost_catalyst") and sim.currency_count("stable_frost_catalyst")==0,"placing a refined Kind invests that exact grade")
	check(sim.import_json(sim.export_json()),"a placed refined Kind survives save and reload")
	check(sim.foundry_remove(2,0) and sim.currency_count("stable_frost_catalyst")==1,"lifting returns the original refined grade")
	var snapshot: String = sim.export_json()
	check(sim.import_json(snapshot),"graded item reloads in Godot")
	check(sim.pack_items().back().mods.any(func(mod: Dictionary) -> bool: return bool(mod.get("held_back",false))),"held-back information survives reload")
	panel.close_panel()
	sim.learn_skill("prototype_bow_shot")
	sim.learn_skill("prototype_fan_shot")
	combat.cooldowns[&"prototype_bow_shot"] = 0
	var before := float(sim.combat_skill("prototype_bow_shot").practice)
	combat.use_skill(&"prototype_bow_shot")
	check(is_equal_approx(float(sim.combat_skill("prototype_bow_shot").practice),before),"firing into empty space gives no mastery")
	for node in get_tree().get_nodes_in_group("player_projectiles"): node.free()
	var hostile := spawn_hostile(Vector3(0,0,-2))
	combat._spend(&"prototype_bow_shot")
	var original: Dictionary = combat.action_context(&"prototype_bow_shot")
	combat.apply_payload(hostile,&"prototype_bow_shot",false,1,false,original)
	combat.deal(hostile,&"prototype_bow_shot",false,1,false,original)
	var first := float(sim.combat_skill("prototype_bow_shot").practice)
	combat.deal(hostile,&"prototype_bow_shot",false,1,false,original)
	check(first>before and is_equal_approx(float(sim.combat_skill("prototype_bow_shot").practice),first),"fan/fork contacts share one mastery credit")
	combat._spend(&"prototype_bow_shot")
	var newer: Dictionary = combat.action_context(&"prototype_bow_shot")
	combat.deal(hostile,&"prototype_bow_shot",false,1,false,original)
	check(is_equal_approx(float(sim.combat_skill("prototype_bow_shot").practice),first),"late old projectile cannot claim the newer input credit")
	combat.deal(hostile,&"prototype_bow_shot",false,1,false,newer)
	check(float(sim.combat_skill("prototype_bow_shot").practice)>first,"new input has its own independent credit")
	before = float(sim.combat_skill("prototype_bow_shot").practice)
	combat._link_depth = 1
	combat._spend(&"prototype_bow_shot")
	var automatic: Dictionary = combat.action_context(&"prototype_bow_shot")
	combat._link_depth = 0
	combat.deal(hostile,&"prototype_bow_shot",false,1,false,automatic)
	check(is_equal_approx(float(sim.combat_skill("prototype_bow_shot").practice),before),"automatic echo or linked projectile cannot train")
	combat._spend(&"prototype_bow_shot")
	combat.deal(hostile,&"prototype_bow_shot",false,1,true)
	check(is_equal_approx(float(sim.combat_skill("prototype_bow_shot").practice),before),"secondary ground/tick damage cannot train")
	hostile.free()
	combat.cooldowns[&"prototype_dash"] = 0
	before = float(sim.combat_skill("prototype_dash").practice)
	combat.use_dash()
	check(is_equal_approx(float(sim.combat_skill("prototype_dash").practice),before),"safe-area dash gives no mastery")
	hostile = spawn_hostile(Vector3(0,0,-3))
	hostile.state = "chase"
	combat.cooldowns[&"prototype_dash"] = 0
	combat.use_dash()
	check(float(sim.combat_skill("prototype_dash").practice)>before,"dash trains during a real hostile engagement")
	print("%d forge progression checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
