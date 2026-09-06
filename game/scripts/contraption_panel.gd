class_name ContraptionPanel
extends RefCounted
## A small set of familiar work-panel actions. Rows describe real placed
## endpoints and native contents; opening or refreshing never performs work.

var site: ContraptionSite
var player: WroughtwildPlayer
var _title := ""


func open_at(fixture: ContraptionSite, user: WroughtwildPlayer) -> void:
	site = fixture
	player = user
	_title = String(ContraptionSite.LABELS.get(site.kind, site.kind))
	_refresh()


func refresh_if_open(message_text: String = "") -> void:
	if not is_instance_valid(player) or not is_instance_valid(site): return
	if player.work_panel.is_open() and player.work_panel._mode == "custom" and player.work_panel._custom_title == _title and player.work_panel.get_meta("contraption_key", "") == site.machine_key:
		_refresh(message_text)


func _action(label: String, detail: String, callback: Callable, enabled: bool = true, explanation: String = "") -> Dictionary:
	return {"text": detail, "button": label, "callback": callback, "enabled": enabled, "details": explanation}


func _refresh(message_text: String = "") -> void:
	if not is_instance_valid(site) or not is_instance_valid(player): return
	var state: Dictionary = site.sim.contraption_state(site.machine_key)
	if state.is_empty(): return
	var config: Dictionary = site.sim.contraption_config()
	var rows: Array = []
	var energy: int = int(state.get("energy", 0))
	var capacity: int = int(config.get("energy_capacity", 4))
	match site.kind:
		"lantern_lamp":
			rows.append(_action("Shutter" if bool(state.get("lamp_on", true)) else "Open the lamp",
				"Lamp open." if bool(state.get("lamp_on", true)) else "Lamp shuttered.", _operate.bind("toggle"), true,
				"A linked Stormglass lever can switch the lamp remotely."))
		"cargo_winch":
			rows.append(_action("Wind the drum", "Stored winding: %d / %d. Each trip spends winding once." % [energy, capacity],
				_operate.bind("wind"), energy < capacity and not bool(state.get("moving", false))))
			rows.append(_action("Choose landing", _link_description(state, "Choose a fixed landing across a clear span."), _choose_link))
			var basket_location := "travelling" if bool(state.get("moving", false)) else "at the landing" if bool(state.get("at_landing", false)) else "at this drum"
			rows.append(_action("Crank a trip", "Basket: %s. Load ingredients below." % basket_location,
				_operate.bind("start"), not bool(state.get("moving", false)) and not String(state.get("link", "")).is_empty(),
				"Use this crank or a linked Stormglass lever to depart. Loading and collecting require the basket at your end."))
			_add_cargo(rows, state)
		"winch_landing":
			var owner: Dictionary = _landing_owner()
			if owner.is_empty():
				rows.append(_action("Waiting for a drum", "Place a Thrumroot cargo drum, then choose this landing from its work panel.", func(): pass, false))
			else:
				var status := "The basket is here." if bool(owner.get("at_landing", false)) and not bool(owner.get("moving", false)) else "The basket must arrive before loading or collecting."
				rows.append(_action("Fixed landing", status + " Use a Stormglass lever linked to its drum to request the return trip.", func(): pass, false))
				_add_cargo(rows, owner)
		"stormglass_lever":
			rows.append(_action("Choose receiver", _link_description(state, "Link a nearby cargo drum, pressure feeder or Lanternheart lamp."), _choose_link))
			rows.append(_action("Strike the lever", "Drums and feeders need stored drive; lamps switch directly.",
				_operate.bind("pulse"), not String(state.get("link", "")).is_empty()))
		"magnetic_sorter":
			rows.append(_action("Tip one batch", "Load a batch below. Iron ingredients and other stock go to separate trays.", _operate.bind("sort")))
			_add_deposits(rows)
			_add_withdrawals(rows, "input", state.get("input", {}))
			_add_withdrawals(rows, "ferrous", state.get("ferrous", {}))
			_add_withdrawals(rows, "remainder", state.get("remainder", {}))
		"ventlung_bellows":
			rows.append(_action("Prime by hand", "Stored pressure: %d / %d." % [energy, capacity],
				_operate.bind("prime"), energy < capacity, "Priming stores your work; the membrane creates no power."))
			var target := site.bellows_target()
			var target_name := "a nearby set wedge or responsive seam" if target == null else Hud.pretty(String(target.material_family))
			rows.append(_action("Release pressure", "Target: %s. Set a wedge first if required." % target_name,
				_release, energy > 0 and target != null))
		"pressure_feeder":
			_add_feeder(rows,state,config)
	rows.append(_action("Dismantle and recover", "Recover intact rare cores, stored ingredients and completed output. Ordinary frame materials use the existing building refund."+(" Unused drive vents; the pocket stays spent." if site.kind=="pressure_feeder" else ""), _dismantle))
	player.open_custom_panel(_title, rows, message_text)
	player.work_panel.set_meta("contraption_key", site.machine_key)


func _add_feeder(rows: Array, state: Dictionary, config: Dictionary) -> void:
	var active:=int(state.get("escrow_drive",0))>0
	var energy:=int(state.get("energy",0))
	var capacity:=int(config.get("energy_capacity",4))
	var status:=site.feeder_status(state)
	var paused:=bool(state.get("feeder_paused",false))
	var source_id:=String(state.get("source_id",""))
	var source: Dictionary={}
	for candidate: Dictionary in site.sim.contraption_pressure_sources():
		if String(candidate.id)==source_id:source=candidate
	var attachment:="Choose your placed basic forge and an optional pressure pocket, each within %.0f m." % float(config.get("feeder_attachment_range",8))
	if not String(state.get("forge_key","")).is_empty():attachment="Forge attached. "+("Pocket: %d / %d strokes remaining. " % [int(source.get("remaining",0)),int(source.get("capacity",0))] if not source.is_empty() else "Hand-wound drive; no pocket attached. ")+String(status.message)
	rows.append(_action("Choose forge and pocket",attachment,_choose_feeder_connection,not active))
	rows.append(_action("Draw pocket pressure","Drive: %d / %d stored; %d reserved. Drawing permanently spends pocket stock." % [energy,capacity,int(state.get("escrow_drive",0))],_operate.bind("charge"),bool(status.ready) and not source.is_empty() and int(source.get("remaining",0))>0 and energy+int(state.get("escrow_drive",0))<capacity))
	rows.append(_action("Wind by hand","Add one stroke; also works with an exhausted pocket.",_operate.bind("wind"),energy+int(state.get("escrow_drive",0))<capacity))
	var inputs: Dictionary=config.get("feeder_inputs",{})
	var outputs: Dictionary=config.get("feeder_outputs",{})
	var recipe_text:="Per cycle: %s + %d fuel heat → %s." % [WorkPanel.amounts_text(inputs),int(config.get("feeder_fuel_cost",1)),WorkPanel.amounts_text(outputs)]
	rows.append(_action("Start %d cycles" % int(config.get("feeder_batch_cycles",4)),recipe_text+" %.0f seconds; no personal mastery XP." % float(config.get("feeder_cycle_seconds",8)),_operate.bind("start"),not active and bool(status.ready),
		"Pressure drives the feeder; ordinary fuel heats your forge. Load ingredients and fuel into the hopper below."))
	if active:
		var seconds:=float(state.get("cycle_seconds",0))
		var detail:="Firing: %.1f / %.0f seconds · %d cycles left, including this one. Inputs and drive reserved." % [seconds,float(config.get("feeder_cycle_seconds",8)),int(state.get("queued_cycles",0))]
		if not bool(status.ready):detail+=" "+String(status.message)
		rows.append(_action("Resume" if paused else "Pause",detail,_operate.bind("resume" if paused else "pause"),bool(status.ready) if paused else true))
		rows.append(_action("Cancel batch","Return this firing's exact reserved ingredients and drive. Completed bricks stay in the tray; the source pocket is not refilled.",_operate.bind("cancel")))
	rows.append(_action("Hopper and output","Hopper: %d / %d items, plus reserved inputs. Output: %d / %d bricks. Work pauses when you leave the area or enter a trial; there is no offline progress." % [ContraptionSite._inventory_units(state.get("input",{})),int(config.get("feeder_input_units",64)),ContraptionSite._inventory_units(state.get("output",{})),int(config.get("feeder_output_units",32))],func():pass,false))
	_add_deposits(rows)
	_add_withdrawals(rows,"input",state.get("input",{}))
	_add_withdrawals(rows,"output",state.get("output",{}))


func _choose_feeder_connection() -> void:
	if not is_instance_valid(site):return
	var range_m:=float(site.sim.contraption_config().get("feeder_attachment_range",8))
	var rows: Array=[]
	for node in site.get_tree().get_nodes_in_group("crafting_stations"):
		if not node is StationSite or not site.get_parent().is_ancestor_of(node):continue
		var forge:=node as StationSite
		if not forge.feeder_eligible(site.sim) or forge.global_position.distance_to(site.global_position)>range_m:continue
		var status:=site.feeder_connection_status(forge)
		var prefix:="Your forge %.1f m %s" % [forge.global_position.distance_to(site.global_position),_relative_direction(forge)]
		rows.append(_action("Attach forge · hand-wound",prefix+". "+String(status.message),_attach_feeder.bind(forge.station_key,""),bool(status.ready)))
		for source_node in site.get_tree().get_nodes_in_group("pressure_pockets"):
			if not source_node is PressurePocket or not site.get_parent().is_ancestor_of(source_node):continue
			var pocket:=source_node as PressurePocket
			if pocket.global_position.distance_to(site.global_position)>range_m:continue
			var source:=pocket.source_state()
			status=site.feeder_connection_status(forge,pocket)
			rows.append(_action("Attach forge and pocket",prefix+". Pocket %.1f m away, %d strokes remain. %s" % [pocket.global_position.distance_to(site.global_position),int(source.get("remaining",0)),String(status.message)],_attach_feeder.bind(forge.station_key,pocket.source_id),bool(status.ready)))
	if rows.is_empty():rows.append(_action("Build your forge nearby","Place a basic forge kit within %.0f metres. The struck old hearth is a ruined source, not your crafting station." % range_m,func():pass,false))
	rows.append(_action("Back","Return to the feeder.",_refresh))
	player.open_custom_panel(_title+" · attach",rows)


func _attach_feeder(forge_key: String, source_id: String) -> void:
	if not is_instance_valid(site):return
	var result:=site.attach_feeder(forge_key,source_id)
	_refresh(String(result.get("message","")))


func _link_description(state: Dictionary, empty_text: String) -> String:
	var target_key := String(state.get("link", ""))
	if target_key.is_empty(): return empty_text
	var target: Dictionary = site.sim.contraption_state(target_key)
	return "Linked to %s, %.1f m away. %s" % [ContraptionSite.LABELS.get(String(target.get("kind", "")), "receiver"),
		float(state.get("span_length", 0)), "The connection is clear." if site.span_clear() else "The connection or its support is obstructed."]


func _landing_owner() -> Dictionary:
	for key in site.sim.contraption_ids():
		var state: Dictionary = site.sim.contraption_state(key)
		if state.get("kind", "") == "cargo_winch" and state.get("link", "") == site.machine_key: return state
	return {}


func _add_cargo(rows: Array, owner: Dictionary) -> void:
	var here: bool = not bool(owner.get("moving", false)) and (bool(owner.get("at_landing", false)) == (site.kind == "winch_landing"))
	if not here: return
	_add_deposits(rows)
	_add_withdrawals(rows, "cargo", owner.get("cargo", {}))


func _add_deposits(rows: Array) -> void:
	var inventory: Dictionary = site.sim.inventory()
	var equipment: PackedStringArray = site.sim.item_base_ids()
	var ids: Array = inventory.keys()
	ids.sort()
	for item in ids:
		var count := int(inventory[item])
		if count <= 0 or equipment.has(String(item)): continue
		if site.kind=="pressure_feeder":
			var config: Dictionary=site.sim.contraption_config()
			var inputs: Dictionary=config.get("feeder_inputs",{})
			var fuels: Dictionary=config.get("feeder_fuels",{})
			if not inputs.has(item) and not fuels.has(item):continue
			var per_cycle:=int(inputs.get(item,1)) if inputs.has(item) else maxi(1,ceili(float(config.get("feeder_fuel_cost",1))/maxf(1,float(fuels[item]))))
			var requested:=mini(count,per_cycle*int(config.get("feeder_batch_cycles",4)))
			rows.append(_action("Load %d %s" % [requested,Hud.pretty(String(item))],"In pack: %d · up to one batch's share." % count,_deposit.bind(String(item),requested)))
			continue
		rows.append(_action("Load %s" % Hud.pretty(String(item)), "In pack: %d · limited by free capacity." % count,
			_deposit.bind(String(item), count)))
		if count > 10:
			rows.append(_action("Load 10 %s" % Hud.pretty(String(item)), "Leave room for another ingredient in the mixed batch.", _deposit.bind(String(item), 10)))


func _add_withdrawals(rows: Array, port: String, contents: Dictionary) -> void:
	var ids: Array = contents.keys()
	ids.sort()
	for item in ids:
		var count := int(contents[item])
		rows.append(_action("Collect %s" % Hud.pretty(String(item)), "%s: %d %s." % [Hud.pretty(port).capitalize(), count, Hud.pretty(String(item))],
			_withdraw.bind(port, String(item), count)))


func _operate(action: String) -> void:
	if not is_instance_valid(site): return
	var result := site.perform(action)
	if action in ["start", "pulse", "sort"] and (bool(result.get("ok", false)) or action == "pulse"):
		player.work_panel.close_panel()
		player.hud.notify(String(result.get("message", "")))
		return
	_refresh(String(result.get("message", "")))


func _release() -> void:
	if not is_instance_valid(site): return
	var result := site.release_at_resource(player)
	if bool(result.get("ok", false)):
		player.work_panel.close_panel()
		player.hud.notify(String(result.get("message", "")))
		return
	_refresh(String(result.get("message", "")))


func _deposit(item: String, count: int) -> void:
	if not is_instance_valid(site): return
	var result: Dictionary = site.sim.contraption_deposit(site.machine_key, item, count)
	_refresh("%s (%d moved.)" % [String(result.get("message", "")), int(result.get("moved", 0))])


func _withdraw(port: String, item: String, count: int) -> void:
	if not is_instance_valid(site): return
	var result: Dictionary = site.sim.contraption_withdraw(site.machine_key, port, item, count)
	_refresh("%s (%d moved.)" % [String(result.get("message", "")), int(result.get("moved", 0))])


func _choose_link() -> void:
	if not is_instance_valid(site): return
	var config: Dictionary = site.sim.contraption_config()
	var range_m: float = float(config.get("maximum_span", 32)) if site.kind == "cargo_winch" else float(config.get("signal_range", 24))
	var rows: Array = []
	for node in site.get_tree().get_nodes_in_group("contraptions"):
		if not node is ContraptionSite or node == site: continue
		var target := node as ContraptionSite
		if site.kind == "cargo_winch" and target.kind != "winch_landing": continue
		if site.kind == "stormglass_lever" and not target.kind in ["cargo_winch", "lantern_lamp","pressure_feeder"]: continue
		var distance_m := site.global_position.distance_to(target.global_position)
		if distance_m > range_m: continue
		var clear := site.link_clear(target)
		rows.append(_action("Link this %s" % ContraptionSite.LABELS.get(target.kind, target.kind),
			"%.1f m · %s · %s" % [distance_m, _relative_direction(target), "clear approach" if clear else "clear its span and support both endpoints"],
			_link.bind(target.machine_key), clear))
	if rows.is_empty():
		rows.append(_action("No receiver nearby", "Place the matching landing or receiver within %.0f metres, then return here." % range_m, func(): pass, false))
	rows.append(_action("Back", "Return to the fixture.", _refresh))
	player.open_custom_panel(_title + " · choose a connection", rows)


func _relative_direction(target: Node3D) -> String:
	var relative := player.to_local(target.global_position)
	var horizontal := "to your right" if relative.x > 0 else "to your left"
	if absf(relative.z) >= absf(relative.x): horizontal = "ahead of you" if relative.z < 0 else "behind you"
	var rise := target.global_position.y - site.global_position.y
	if rise > 0.75: return horizontal + ", higher up"
	if rise < -0.75: return horizontal + ", lower down"
	return horizontal


func _link(target_key: String) -> void:
	if not is_instance_valid(site): return
	var target := ContraptionSite.find_site(site.get_tree(), target_key)
	var result: Dictionary = site.sim.contraption_link(site.machine_key, target_key, site.link_clear(target))
	site.refresh_from_sim()
	_refresh(String(result.get("message", "")))


func _dismantle() -> void:
	if not is_instance_valid(site): return
	var before: Dictionary=site.sim.contraption_state(site.machine_key)
	var result: Dictionary = site.sim.contraption_remove(site.machine_key)
	if not bool(result.get("ok", false)):
		_refresh(String(result.get("message", "")))
		return
	player.work_panel.close_panel()
	player.hud.notify(String(result.get("message", "Recovered the fixture.")))
	if site.kind=="pressure_feeder":site.vent_unused_drive(int(before.get("energy",0))+int(before.get("escrow_drive",0)))
	site.get_parent().remove_child(site)
	site.queue_free()
