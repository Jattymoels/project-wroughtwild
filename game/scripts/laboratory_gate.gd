extends "res://scripts/trial_gate.gd"
## Interaction on the existing Annex front body; no relocated entry marker.
func interact(player: WroughtwildPlayer) -> void:
	if player.inventory.get_sim().campaign_policy()!="living_frontier_wave4": return
	if player.trial.active(): player.trial.reopen(); return
	player.open_custom_panel("Collection Annex",[
		{"text":"Follow the collection apparatus through two floors. Red and Blue specimens are held separately; a later human operator has altered the emergency return circuit.","button":"Enter containment Trial","callback":_enter.bind(player)}
	],"Equipment enters intact. Ordinary possessions wait in the entrance lockers; unbanked Trial loot is at risk.")

func _enter(player: WroughtwildPlayer) -> void:
	if player.global_position.distance_to(global_position)>player.interact_range+2: return
	player.work_panel.close_panel()
	if not player.trial.begin_run("forge_tyrant"): player.hud.notify("The containment entrance could not open.")
