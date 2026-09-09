class_name TrialGate
extends StaticBody3D
## Entry previews never deposit or roll anything. The simulation validates
## the chosen story/offer and only successful entry consumes an offer batch.
var selected_tier:=1


func interact(player: WroughtwildPlayer) -> void:
	if player.trial.active():
		player.trial.reopen()
		return
	var sim: WroughtwildSim = player.inventory.get_sim()
	if sim.campaign_policy()=="living_frontier_wave4":
		player.open_custom_panel("The old smithy",[],"This impact-struck smithy predates the cataclysm. Follow the collection trail to the Collection Annex and enter its containment Trial.")
		return
	var rows: Array=[]
	var stories: Array=sim.call("trial_story_runs")
	for story in stories:
		var id:=String(story["id"])
		var description: String={"forge_tyrant":"Fuel galleries, branching shrines and the Tyrant's fire.","deep_forge":"Guarded halls, cistern routes and the Ash Warden.","forge_capstone":"The furnace core. Break the ward conduits and master the Forge."}.get(id,"")
		if not bool(story["available"]):
			description+=" Set the Tyrant's heart at the hill cairn." if id=="deep_forge" else " Set the Warden's eye at the drowned altar to begin Ash Tide."
		rows.append({"text":"[b]%s[/b] · Two floors · Four boon shrines\n%s%s"%[story["display_name"],description,"  Cleared." if story["done"] else ""],
			"button":"Enter" if story["available"] else "Sealed","enabled":bool(story["available"]),"callback":_descend.bind(player,id)})
	var progress: Dictionary=sim.call("trial_map_progress")
	rows.append({"text":"[b]Repeatable Forge trials[/b]\nChoose a tier and rolled conditions. Target building materials, equipment and Kinds.","button":"Choose run" if progress["available"] else "Complete the Forge arc","enabled":bool(progress["available"]),"callback":show_maps.bind(player,selected_tier)})
	player.open_custom_panel("The Trial Gate",rows,"Your equipment enters intact. Ordinary possessions wait in the lockers; unbanked trial loot is at risk.")

func show_maps(player: WroughtwildPlayer,tier: int) -> void:
	var sim:=player.inventory.get_sim()
	var progress: Dictionary=sim.call("trial_map_progress")
	if not bool(progress.get("available",false)): return
	selected_tier=clampi(tier,1,int(progress["max_tier"]))
	var rows: Array=[]
	rows.append({"text":"Choose a lower unlocked difficulty.","button":"Tier %d"%maxi(1,selected_tier-1),"enabled":selected_tier>1,"callback":show_maps.bind(player,selected_tier-1)})
	rows.append({"text":"Clearing your highest tier opens the next.","button":"Tier %d"%(selected_tier+1),"enabled":selected_tier<int(progress["max_tier"]),"callback":show_maps.bind(player,selected_tier+1)})
	var offers: Array=sim.call("trial_map_offers",selected_tier)
	for i in offers.size():
		var offer: Dictionary=offers[i]
		var details:=PackedStringArray()
		for condition in offer.get("conditions",[]): details.append("• %s: %s"%[condition["display_name"],condition["description"]])
		var target:=String(offer.get("material_target","building materials"))
		for component in offer.get("completion_components",{}):
			details.append("Boss haul: %d %s for a new contraption." % [int(offer.completion_components[component]),Hud.pretty(String(component))])
		rows.append({"text":"[b]Run %d · %s[/b]\n%s\nBoss: %s · rewards ×%.2f\n%s"%[i+1,Hud.pretty(target),"\n".join(details),Hud.pretty(String(offer["boss_id"])),float(offer.get("reward_multiplier",1)),String(offer.get("boss_preview",""))],"button":"Enter","callback":_map.bind(player,selected_tier,i)})
	rows.append({"text":"Return to the story trials.","button":"Back","callback":interact.bind(player)})
	player.open_custom_panel("Forge trial · Tier %d"%selected_tier,rows,"One floor · Two boon shrines · Conditions and rewards stay fixed until entry.")

func _map(player: WroughtwildPlayer,tier: int,index: int) -> void:
	player.work_panel.close_panel()
	if not player.trial.begin_map(tier,index): player.hud.notify("That run could not be opened. Review the gate again.")


func _descend(player: WroughtwildPlayer, floor_id: String) -> void:
	player.work_panel.close_panel()
	if not player.trial.begin_run(floor_id):
		player.hud.notify("The gate does not open.")
