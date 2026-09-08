class_name ContraptionPanel
extends RefCounted
## A small set of familiar work-panel actions. Rows describe real placed
## endpoints and native contents; opening or refreshing never performs work.

var site: ContraptionSite
var player: WroughtwildPlayer
var _title := ""
var _feeder_page := "main"
var _link_port := 1


func open_at(fixture: ContraptionSite, user: WroughtwildPlayer) -> void:
	site = fixture
	player = user
	_title = String(ContraptionSite.LABELS.get(site.kind, site.kind))
	_feeder_page = "main"
	_link_port = 1
	_refresh()


func refresh_if_open(message_text: String = "") -> void:
	if not is_instance_valid(player) or not is_instance_valid(site): return
	var own_page := player.work_panel._custom_title == _title
	if site.kind == "pressure_feeder": own_page = player.work_panel._custom_context == _feeder_context()
	if player.work_panel.is_open() and player.work_panel._mode == "custom" and own_page and player.work_panel.get_meta("contraption_key", "") == site.machine_key:
		_refresh(message_text)


func _action(label: String, detail: String, callback: Callable, enabled: bool = true, explanation: String = "") -> Dictionary:
	return {"text": detail, "button": label, "callback": callback, "enabled": enabled, "details": explanation}


func _refresh(message_text: String = "") -> void:
	if not is_instance_valid(site) or not is_instance_valid(player): return
	var state: Dictionary = site.sim.contraption_state(site.machine_key)
	if state.is_empty(): return
	var config: Dictionary = site.sim.contraption_config()
	if site.kind == "pressure_feeder":
		_refresh_feeder(state, config, message_text)
		return
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
			rows.append(_action("Choose receiver", _link_description(state, "Link a White connection or an existing local receiver."), _choose_link))
			rows.append(_action("Strike the lever", _signal_description(state),
				_operate.bind("pulse"), not String(state.get("link", "")).is_empty()))
		"white_connection":
			rows.append(_action("Choose receiver", _link_description(state, "Disconnected. Choose a receiver, Blue delay or Green junction."), _choose_link))
			rows.append(_action("Signal only", "A linked lever requests work. Each drum or feeder needs its own winding and supplies.", Callable(), false,
				"Each signal span must be clear and supported. White stores no energy or pending requests. White can forward to Blue or Green; the ordered links cannot loop."))
		"blue_delay":
			rows.append(_action("Choose receiver",_link_description(state,"Disconnected. Choose a receiver or Green junction."),_choose_link))
			var pending := bool(state.pending_request)
			var held := "Paused" if bool(state.delay_paused) or not site.span_clear() else "Holding"
			rows.append(_action("One held request", "%s · %.1f / %.1f seconds remain." % [held,float(config.delay_seconds)-float(state.delay_seconds),float(config.delay_seconds)] if pending else "Ready · a lever request waits %.1f seconds before each receiver pays its own work." % float(config.delay_seconds),Callable(),false,
				"One pending request only. Pause, trials, blocked output support/span and leaving the local area preserve its exact delay. Rewiring any part of this route cancels it. At release, an unwound, unfuelled or blocked receiver refuses and the request is spent. No offline work."))
			rows.append(_action("Resume" if bool(state.delay_paused) else "Pause","Hold or resume the exact remaining delay.",_operate.bind("resume" if bool(state.delay_paused) else "pause"),pending))
			rows.append(_action("Cancel request","Clear the held request without spending receiver work.",_operate.bind("cancel"),pending))
		"green_junction":
			rows.append(_action("Choose first receiver",_link_description(state,"First port disconnected."),_choose_link.bind(1)))
			rows.append(_action("Choose second receiver",_link_description(state,"Second port disconnected.",2),_choose_link.bind(2)))
			rows.append(_action("One request · two receivers","Each clear branch attempts one operation. Each receiver pays its own winding, materials and heat.",Callable(),false,"Only two distinct drums or feeders. One refusal leaves the other branch usable. No queue, component loops or repeated execution."))
			if not String(state.second_link).is_empty(): rows.append(_action("Disconnect second signal","Cancel pending Blue requests on this route.",_disconnect.bind(2)))
		"red_heat_buffer":
			var receiver: Dictionary = site.sim.contraption_state(String(state.link))
			var reserved := int(receiver.get("escrow_heat",0))
			var room := int(state.heat)+reserved<int(config.heat_capacity)
			var affordable := true
			for item: String in config.heat_input:
				if site.sim.material_count(item)<int(config.heat_input[item]): affordable=false
			rows.append(_action("Thermal store","Heat: %d available + %d held / %d total. Winding is separate." % [int(state.heat),reserved,int(config.heat_capacity)],Callable(),false))
			rows.append(_action("Pay for 1 heat",WorkPanel.amounts_text(config.heat_input)+" → 1 stored heat.",_operate.bind("heat"),room and affordable,"Charge while supported. Held heat keeps its return slot; cancelling a firing returns it once. No raw salt returns from spent heat."))
			rows.append(_action("Choose heat receiver",_link_description(state,"Choose one nearby pressure feeder."),_choose_link,not bool(receiver.get("escrow_drive",0))))
			if not String(state.link).is_empty(): rows.append(_action("Disconnect heat","Return to ordinary feeder fuel. Finish or cancel its firing first.",_disconnect.bind(1),int(receiver.get("escrow_drive",0))==0))
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
	if site.kind in ["stormglass_lever","white_connection","blue_delay","green_junction"] and not String(state.link).is_empty():
		rows.append(_action("Disconnect signal", "Cancel pending Blue requests on this route. A basket already travelling keeps its paid trip and cargo.", _disconnect.bind(1)))
	rows.append(_action("Dismantle and recover", "Recover intact rare cores, stored ingredients and completed output. Ordinary frame materials use the existing building refund."+(" Unused heat vents; spent charge salt never returns. Finish or cancel the firing first." if site.kind=="red_heat_buffer" else " Unused drive vents; the pocket stays spent." if site.kind=="pressure_feeder" else ""), _dismantle))
	player.open_custom_panel(_title, rows, message_text)
	player.work_panel.set_meta("contraption_key", site.machine_key)


func _feeder_context() -> String:
	return "feeder:%s:%s" % [site.machine_key, _feeder_page]


func _feeder_row(id: String, text: String, button: String = "", callback: Callable = Callable(), enabled: bool = true, details: String = "") -> Dictionary:
	return {"id": id, "text": text, "button": button, "callback": callback, "enabled": enabled, "details": details}


func _show_feeder_page(page: String) -> void:
	_feeder_page = page
	_refresh()


func _feeder_action(view: Dictionary, action: String, label: String, text: String) -> Dictionary:
	var accepted := FeederReadout.action_ready(view, action)
	var reason := String(view.native.get("actions", {}).get(action, {}).get("message", ""))
	if not accepted and action in ["start", "charge", "resume"] and not bool(view.geometry.get("ready", false)):
		reason = String(view.geometry.get("message", reason))
	return _feeder_row("action:" + action, text if accepted else reason, label, _operate.bind(action), accepted)


func _refresh_feeder(state: Dictionary, config: Dictionary, message_text: String) -> void:
	if _feeder_page == "attach":
		_choose_feeder_connection(message_text)
		return
	var view := FeederReadout.inspect(site, state)
	var rows: Array = []
	var active := bool(view.active)
	var available := bool(view.native.get("available", false))
	var held: Dictionary = state.get("escrow_inputs", {}).duplicate()
	for item in state.get("escrow_fuel", {}):
		held[item] = int(held.get(item, 0)) + int(state.escrow_fuel[item])
	var hopper: Dictionary = state.get("input", {})
	var output: Dictionary = state.get("output", {})
	var energy := int(state.get("energy", 0))
	var reserved := int(state.get("escrow_drive", 0))
	var capacity := int(config.get("energy_capacity", 4))
	var heading := _title
	match _feeder_page:
		"main":
			rows.append(_feeder_row("status", "%s · %s" % [view.headline, view.hint], "", Callable(), false, String(view.summary)))
			if output.is_empty(): rows.append(_feeder_row("output:empty", "Completed bricks · tray empty"))
			else: _feeder_withdrawals(rows, "output", output, available)
			if active:
				rows.append(_feeder_action(view, "resume" if view.paused else "pause", "Resume" if view.paused else "Pause", String(view.summary)))
			else:
				var start := _feeder_action(view, "start", "Start up to %d firings" % int(config.get("feeder_batch_cycles", 4)), "")
				# The current blocker is already above; retain the recipe beside Start.
				start.text = FeederReadout.recipe_text(config,state)
				rows.append(start)
			rows.append(_feeder_row("page:hopper", "Hopper · " + FeederReadout.stock_text(hopper), "Load / return supplies", _show_feeder_page.bind("hopper"), true,
				"Held for the current firing: " + FeederReadout.stock_text(held) + ". Loading takes only the selected ingredients from your pack."))
			rows.append(_feeder_row("page:drive", "Drive · %d stored + %d held / %d total" % [energy, reserved, capacity], "Drive / connections", _show_feeder_page.bind("drive"), true, FeederReadout.source_text(view)))
			rows.append(_feeder_row("page:help", "Recipe, work limits and recovery", "Workshop details", _show_feeder_page.bind("help")))
		"hopper":
			heading += " · supplies"
			var occupied := ContraptionSite._inventory_units(hopper) + ContraptionSite._inventory_units(held)
			rows.append(_feeder_row("hopper:stock", "Hopper · %s · %d / %d items including held supplies" % [FeederReadout.stock_text(hopper), occupied, int(config.get("feeder_input_units", 64))], "", Callable(), false,
				"Held for this firing: %s. Held supplies are protected until completion or cancellation." % FeederReadout.stock_text(held)))
			var loads: Array = view.native.get("loads", [])
			if loads.is_empty(): rows.append(_feeder_row("loads:empty", "No raw clay or forge fuel in your pack to load." if available else String(view.native.message)))
			for load: Dictionary in loads:
				var item := String(load.item)
				if not String(state.get("heat_key","")).is_empty() and config.feeder_fuels.has(item): continue
				var moved := int(load.moved)
				rows.append(_feeder_row("load:" + item, "In pack: %d · hopper: %d" % [int(site.sim.inventory().get(item, 0)), int(hopper.get(item, 0))] if load.ok else String(load.message),
					"Load %d %s" % [moved, Hud.pretty(item)] if load.ok else "Load " + Hud.pretty(item), _deposit.bind(item, int(load.requested)), bool(load.ok),
					"Moves only this ingredient, up to one requested batch's share. The amount shown fits alongside held supplies."))
			_feeder_withdrawals(rows, "input", hopper, available)
		"drive":
			heading += " · drive and connections"
			rows.append(_feeder_row("drive:stock", "Drive · %d stored + %d held / %d total" % [energy, reserved, capacity], "", Callable(), false,
				"One stroke moves the feeder for one firing. Its selected thermal source pays for heat separately."))
			rows.append(_feeder_row("heat:stock",FeederReadout.heat_text(view)))
			rows.append(_feeder_row("source:stock", FeederReadout.source_text(view)))
			rows.append(_feeder_action(view, "charge", "Draw pocket pressure", "Transfer available pocket strokes into free drive space; the pocket stays spent."))
			rows.append(_feeder_action(view, "wind", "Wind by hand", "Store one stroke by hand."))
			rows.append(_feeder_row("page:attach", String(view.geometry.message), "Choose forge / pocket", _show_feeder_page.bind("attach"), available and not active,
				"Use your own placed forge. The struck old hearth is a ruined source, not a working station. Finish or cancel the current firing before changing connections."))
		"help":
			heading += " · details"
			rows.append(_feeder_row("recipe", FeederReadout.recipe_text(config,state), "", Callable(), false,
				"Start requests up to %d firings. Each reserves its own ingredients, thermal payment, tray space and drive once. If the next firing lacks anything, the batch stops. Charcoal is consumed per firing; excess fuel heat is not stored. Machinery awards no personal mastery XP." % int(config.get("feeder_batch_cycles", 4))))
			rows.append(_feeder_row("ownership", "Held supplies · " + FeederReadout.stock_text(held), "", Callable(), false,
				"Tray: %d / %d completed items. An active firing also holds room for its output. Work waits when you leave the area or enter a trial. Saving keeps the exact firing; there is no offline progress." % [ContraptionSite._inventory_units(output), int(config.get("feeder_output_units", 32))]))
			rows.append(_feeder_action(view, "cancel", "Cancel requested firings", "Return this firing's exact held ingredients and drive; completed bricks stay in the tray."))
			rows.append(_feeder_row("dismantle", "Recover cores, stored supplies and completed bricks; unused drive vents.", "Dismantle and recover", _dismantle, available,
				"The ordinary frame uses the existing building refund. Held ingredients and any reserved Red heat return once to their owners. Spent pocket stock is never refilled."))
	if _feeder_page != "main": rows.append(_feeder_row("page:main", "Return to the feeder overview.", "Back", _show_feeder_page.bind("main")))
	player.open_custom_panel(heading, rows, message_text, _feeder_context())
	player.work_panel.set_meta("contraption_key", site.machine_key)


func _feeder_withdrawals(rows: Array, port: String, contents: Dictionary, enabled: bool) -> void:
	var ids: Array = contents.keys()
	ids.sort()
	for item in ids:
		var count := int(contents[item])
		rows.append(_feeder_row("take:%s:%s" % [port, item], "%s · %d %s" % ["Completed tray" if port == "output" else "Available hopper", count, Hud.pretty(String(item))],
			("Collect %d %s" if port == "output" else "Return %d %s") % [count, Hud.pretty(String(item))], _withdraw.bind(port, String(item), count), enabled))


func _choose_feeder_connection(message_text: String = "") -> void:
	if not is_instance_valid(site): return
	var range_m := float(site.sim.contraption_config().get("feeder_attachment_range", 8))
	var state: Dictionary = site.sim.contraption_state(site.machine_key)
	var can_attach := int(state.get("escrow_drive", 0)) == 0 and not bool(site.sim.trial_active())
	var rows: Array = []
	for node in site.get_tree().get_nodes_in_group("crafting_stations"):
		if not node is StationSite or not site.get_parent().is_ancestor_of(node): continue
		var forge := node as StationSite
		if not forge.feeder_eligible(site.sim) or forge.global_position.distance_to(site.global_position) > range_m: continue
		var status := site.feeder_connection_status(forge)
		var prefix := "Your forge %.1f m %s" % [forge.global_position.distance_to(site.global_position), _relative_direction(forge)]
		rows.append(_feeder_row("attach:" + forge.station_key + ":hand", prefix + ". " + String(status.message), "Attach forge · hand-wound", _attach_feeder.bind(forge.station_key, ""), can_attach and bool(status.ready)))
		for source_node in site.get_tree().get_nodes_in_group("pressure_pockets"):
			if not source_node is PressurePocket or not site.get_parent().is_ancestor_of(source_node): continue
			var pocket := source_node as PressurePocket
			if pocket.global_position.distance_to(site.global_position) > range_m: continue
			var source := pocket.source_state()
			status = site.feeder_connection_status(forge, pocket)
			rows.append(_feeder_row("attach:" + forge.station_key + ":" + pocket.source_id, prefix + ". Pocket %.1f m away, %d strokes remain. %s" % [pocket.global_position.distance_to(site.global_position), int(source.get("remaining", 0)), String(status.message)], "Attach forge and pocket", _attach_feeder.bind(forge.station_key, pocket.source_id), can_attach and bool(status.ready)))
	if rows.is_empty(): rows.append(_feeder_row("attach:empty", "Place your own basic forge within %.0f metres; the old hearth is a ruined source." % range_m))
	rows.append(_feeder_row("page:drive", "Return to drive and connections.", "Back", _show_feeder_page.bind("drive")))
	player.open_custom_panel(_title + " · attach", rows, message_text, _feeder_context())
	player.work_panel.set_meta("contraption_key", site.machine_key)


func _attach_feeder(forge_key: String, source_id: String) -> void:
	if not is_instance_valid(site):return
	var result:=site.attach_feeder(forge_key,source_id)
	_feeder_page = "drive"
	_refresh(String(result.get("message","")))


func _link_description(state: Dictionary, empty_text: String, port: int = 1) -> String:
	var target_key := String(state.get("link" if port==1 else "second_link", ""))
	if target_key.is_empty(): return empty_text
	var target: Dictionary = site.sim.contraption_state(target_key)
	return "Linked to %s, %.1f m away. %s" % [ContraptionSite.LABELS.get(String(target.get("kind", "")), "receiver"),
		float(state.get("span_length" if port==1 else "second_span_length", 0)), "The connection is clear." if site.link_clear(ContraptionSite.find_site(site.get_tree(),target_key)) else "The connection or its support is obstructed."]


func _signal_description(state: Dictionary) -> String:
	var connection := ContraptionSite.find_site(site.get_tree(),String(state.get("link","")))
	if connection == null: return "Signal disconnected. Choose a local receiver."
	if not site.span_clear(): return "Clear and support the signal span before requesting a trip."
	for step in 2:
		if connection.kind not in ["white_connection","blue_delay"]: break
		var relay: Dictionary = site.sim.contraption_state(connection.machine_key)
		if connection.kind=="blue_delay" and bool(relay.pending_request): return "Blue already holds one request · %.1f seconds remain. Pause or cancel it at the Blue post." % [float(site.sim.contraption_config().delay_seconds)-float(relay.delay_seconds)]
		if String(relay.link).is_empty(): return "Connection output disconnected. Choose its receiver at the post."
		if not connection.span_clear(): return "Clear and support the signal spans before requesting a trip."
		connection = ContraptionSite.find_site(site.get_tree(),String(relay.link))
		if connection==null: return "Connection output disconnected."
	if connection.kind=="green_junction": return "Green requests both selected receivers once. Wind each receiver and load its own supplies; a blocked branch refuses independently."
	var drum := connection
	if drum.kind!="cargo_winch": return "Drums and feeders need their own stored drive and supplies; lamps switch directly."
	var drive: Dictionary = site.sim.contraption_state(drum.machine_key)
	if String(drive.link).is_empty(): return "Choose the drum's fixed landing first."
	if not drum.span_clear(): return "Clear the cargo span and support both endpoints."
	if bool(drive.moving): return "Basket travelling. Another request cannot start a second trip."
	var cost := int(site.sim.contraption_config().trip_energy)
	if int(drive.energy)<cost: return "White route ready; drum unwound. Wind it before requesting a trip."
	return "Signal route ready. Drum: %d stored work; next trip spends %d. Blue, if selected, holds the request briefly." % [int(drive.energy),cost]


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
	if site.kind != "pressure_feeder" and action in ["start", "pulse", "sort"] and (bool(result.get("ok", false)) or action == "pulse"):
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
	site.refresh_from_sim()
	_refresh("%s (%d moved.)" % [String(result.get("message", "")), int(result.get("moved", 0))])


func _withdraw(port: String, item: String, count: int) -> void:
	if not is_instance_valid(site): return
	var result: Dictionary = site.sim.contraption_withdraw(site.machine_key, port, item, count)
	site.refresh_from_sim()
	_refresh("%s (%d moved.)" % [String(result.get("message", "")), int(result.get("moved", 0))])


func _choose_link(port: int = 1) -> void:
	_link_port = port
	if not is_instance_valid(site): return
	var config: Dictionary = site.sim.contraption_config()
	var range_m: float = float(config.get("maximum_span", 32)) if site.kind == "cargo_winch" else float(config.get("feeder_attachment_range",8)) if site.kind=="red_heat_buffer" else float(config.get("signal_range", 24))
	var rows: Array = []
	for node in site.get_tree().get_nodes_in_group("contraptions"):
		if not node is ContraptionSite or node == site: continue
		var target := node as ContraptionSite
		if site.kind=="red_heat_buffer" and target.kind!="pressure_feeder": continue
		if site.kind == "cargo_winch" and target.kind != "winch_landing": continue
		if site.kind == "stormglass_lever" and not target.kind in ["cargo_winch", "lantern_lamp","pressure_feeder","white_connection","blue_delay","green_junction"]: continue
		if site.kind == "white_connection" and target.kind not in ["cargo_winch","pressure_feeder","blue_delay","green_junction"]: continue
		if site.kind == "blue_delay" and target.kind not in ["cargo_winch","pressure_feeder","green_junction"]: continue
		if site.kind=="green_junction" and target.kind not in ["cargo_winch","pressure_feeder"]: continue
		if site.kind=="green_junction" and target.machine_key==String(site.sim.contraption_state(site.machine_key).get("second_link" if port==1 else "link","")): continue
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
	var result: Dictionary = site.sim.contraption_link_second(site.machine_key,target_key,site.link_clear(target)) if _link_port==2 else site.sim.contraption_link(site.machine_key, target_key, site.link_clear(target))
	site.refresh_from_sim()
	_refresh(String(result.get("message", "")))


func _disconnect(port: int) -> void:
	_link_port = port
	_link("")


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
