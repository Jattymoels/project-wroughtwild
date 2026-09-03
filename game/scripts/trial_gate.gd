class_name TrialGate
extends StaticBody3D
## The sealed gate east of camp. Interacting stows ordinary goods (the sim's
## TrialSession deposits them) and starts a run; the TrialController owns
## everything after that.


func interact(player: WroughtwildPlayer) -> void:
	if player.trial.active():
		player.trial.reopen()
		return
	# Deeper floors the gate can offer (D-019): choose, or take the first.
	var sim: WroughtwildSim = player.inventory.get_sim()
	var floors: Array = sim.trial_floors()
	var offered: Array = []
	for floor in floors:
		if floor["available"]:
			offered.append(floor)
	if offered.is_empty():
		if not player.trial.begin_run():
			player.hud.notify("The gate does not open.")
		return
	var rows: Array = [{"text": "[b]The Tyrant's Forge[/b]  —  the first floor: three rooms and the Forge Tyrant.",
		"button": "Enter", "enabled": true, "callback": _descend.bind(player, "")}]
	for floor in offered:
		rows.append({"text": "[b]%s[/b]  —  a deeper run with the wastes' new families and a warden at the end.%s" % [
			floor["display_name"], "  (cleared)" if floor["done"] else ""],
			"button": "Descend", "enabled": true, "callback": _descend.bind(player, String(floor["id"]))})
	player.open_custom_panel("The Trial Gate", rows, "The lockers take your ordinary goods either way.")


func _descend(player: WroughtwildPlayer, floor_id: String) -> void:
	player.work_panel.close_panel()
	if not player.trial.begin_run(floor_id):
		player.hud.notify("The gate does not open.")
