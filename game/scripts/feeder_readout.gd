class_name FeederReadout
extends RefCounted
## Read-only presentation of the existing native work ledger and host geometry.
## Exact action/load acceptance comes from the same native transactions as use.

static func inspect(site: ContraptionSite, state: Dictionary = {}, physical: Dictionary = {}) -> Dictionary:
	if state.is_empty(): state = site.sim.contraption_state(site.machine_key)
	if physical.is_empty(): physical = site.feeder_status(state)
	var config: Dictionary = site.sim.contraption_config()
	var native: Dictionary = site.sim.contraption_feeder_inspect(site.machine_key, bool(physical.get("ready", false)))
	var source: Dictionary = {}
	for candidate: Dictionary in site.sim.contraption_pressure_sources():
		if candidate.id == state.get("source_id", ""): source = candidate; break
	var active := int(state.get("escrow_drive", 0)) > 0
	var paused := bool(state.get("feeder_paused", false))
	var seconds := float(config.get("feeder_cycle_seconds", 8))
	var headline := "Ready to fire"
	var hint := "Start requests up to %d firings, reserving supplies one firing at a time." % int(config.get("feeder_batch_cycles", 4))
	if not bool(native.get("available", false)):
		headline = "Workshop unavailable"
		hint = String(native.get("message", "Return from the trial to use this workshop."))
	elif not bool(physical.get("ready", false)):
		headline = "Firing held" if active else "Workshop stopped"
		hint = String(physical.get("message", "Check the forge connection."))
	elif active:
		headline = "Paused by you" if paused else "Firing bricks"
		hint = "Resume the same firing; its supplies are already held." if paused else "This firing already owns its clay, heat and drive."
	elif not bool(native.get("actions", {}).get("start", {}).get("ok", false)):
		headline = "Waiting to fire"
		hint = String(native.get("actions", {}).get("start", {}).get("message", "Inspect the workshop."))
	var summary := "%.1f / %.0f s · %d requested firings remain, including this one." % [float(state.get("cycle_seconds", 0)), seconds, int(state.get("queued_cycles", 0))] if active else recipe_text(config,state)
	return {"headline": headline, "summary": summary, "hint": hint,
		"progress": clampf(float(state.get("cycle_seconds", 0)) / maxf(.001, seconds), 0, 1),
		"heat":site.sim.contraption_state(String(state.get("heat_key",""))), "source": source, "geometry": physical, "native": native, "state": state, "config": config,
		"active": active, "paused": paused}

static func recipe_text(config: Dictionary, state: Dictionary = {}) -> String:
	if not String(state.get("heat_key","")).is_empty():
		return "%s + 1 stored Red heat → %s · %.0f s per firing." % [WorkPanel.amounts_text(config.get("feeder_inputs",{})),WorkPanel.amounts_text(config.get("feeder_outputs",{})),float(config.get("feeder_cycle_seconds",8))]
	return "%s + %d fuel heat → %s · %.0f s per firing." % [WorkPanel.amounts_text(config.get("feeder_inputs", {})), int(config.get("feeder_fuel_cost", 1)), WorkPanel.amounts_text(config.get("feeder_outputs", {})), float(config.get("feeder_cycle_seconds", 8))]

static func stock_text(contents: Dictionary) -> String:
	return "Empty" if contents.is_empty() else WorkPanel.amounts_text(contents)

static func source_text(view: Dictionary) -> String:
	var source: Dictionary = view.get("source", {})
	if source.is_empty():
		return "No pocket attached · hand winding available." if String(view.state.get("source_id", "")).is_empty() else "Attached pocket is not available here."
	if int(source.get("remaining", 0)) == 0: return "Pocket exhausted · stored drive and hand winding still work."
	return "Pocket: %d / %d finite strokes." % [int(source.remaining), int(source.capacity)]

static func action_ready(view: Dictionary, action: String) -> bool:
	if not bool(view.native.get("available", false)): return false
	if action in ["start", "charge", "resume"] and not bool(view.geometry.get("ready", false)): return false
	return bool(view.native.get("actions", {}).get(action, {}).get("ok", false))

static func heat_text(view: Dictionary) -> String:
	if String(view.state.get("heat_key","")).is_empty(): return "Heat · ordinary hopper fuel. Drive is paid separately."
	return "Red heat · %d available + %d held. Charge at the buffer. Hopper fuel remains unused while attached." % [int(view.heat.get("heat",0)),int(view.state.get("escrow_heat",0))]
