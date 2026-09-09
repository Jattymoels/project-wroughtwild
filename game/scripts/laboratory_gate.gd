extends "res://scripts/trial_gate.gd"
## Interaction on the existing Annex front body; no relocated entry marker.
func interact(player: WroughtwildPlayer) -> void:
	if player.inventory.get_sim().campaign_policy()!="living_frontier_wave4": return
	if player.trial.active(): player.trial.reopen(); return
	if String(get_meta("run_id","forge_tyrant"))=="deep_forge":
		var available:=false
		for run: Dictionary in player.inventory.get_sim().trial_story_runs():
			if String(run.id)=="deep_forge": available=bool(run.available)
		player.open_custom_panel("Pairing Hall",[
			{"text":"Blue holds a marked charge; Red warns, then releases it. Follow the imposed feed paths through two floors to the pairing warden. Recover materials and equipment, and learn who ordered the experiments. Its unstable return line reaches Excited Uplands.","button":"Enter pairing Trial" if available else "Await the Annex return","enabled":available,"callback":_enter.bind(player)}
		],"Leave the ring or interrupt the host, then attack during recovery. Equipment enters intact; ordinary possessions wait in the lockers.")
		return
	if preload("res://scripts/resonance_event.gd").phase(player.inventory.get_sim())=="pending":
		player.open_custom_panel("The failsafe is waiting",[
			{"text":"The first victory is recorded. Let the return circuit settle into the unoccupied Retained Fen ground.","button":"Retry resonance","callback":_retry.bind(player)}
		],"Your first victory is recorded; retrying keeps the same reward.")
		return
	if preload("res://scripts/resonance_event.gd").phase(player.inventory.get_sim())=="applied":
		player.open_custom_panel("Collection Annex",[
			{"text":"The Annex remains dangerous. Its failsafe has changed Retained Fen; another clear yields the ordinary Trial haul.","button":"Re-enter containment Trial","callback":_enter.bind(player)}
		],"Retained Fen holds its new shape.")
		return
	player.open_custom_panel("Collection Annex",[
		{"text":"Follow the collection apparatus through two floors. Red and Blue specimens are held separately; a later human operator has altered the emergency return circuit.","button":"Enter containment Trial","callback":_enter.bind(player)}
	],"Equipment enters intact. Ordinary possessions wait in the entrance lockers; unbanked Trial loot is at risk.")

func _enter(player: WroughtwildPlayer) -> void:
	if player.global_position.distance_to(global_position)>player.interact_range+2: return
	player.work_panel.close_panel()
	if not player.trial.begin_run(String(get_meta("run_id","forge_tyrant"))): player.hud.notify("The laboratory entrance could not open.")

func _retry(player: WroughtwildPlayer) -> void:
	player.work_panel.close_panel()
	if player.world_root().has_method("settle_resonance"): player.world_root().call_deferred("settle_resonance")
