class_name ResonanceEvent
extends RefCounted
## One save transaction. Candidate rules/terrain remain isolated until the
## complete checkpoint is installed; restore is also the publication path.
const POLICY := "living_frontier_wave4"

static func phase(sim: WroughtwildSim) -> String:
	if sim.campaign_policy()!=POLICY: return "legacy"
	return String(JSON.parse_string(sim.resonance_json()).phase)

static func protection(player: WroughtwildPlayer, snapshot: Dictionary) -> Array:
	var result: Array=[]
	var blocks: Array=[]; var nodes: Array=[]; var stations: Array=[]
	SaveManager._walk(player.world_root(),blocks,nodes,stations)
	for block: PlacedBlock in blocks:
		# Full oriented footprint, including a door's swept leaf and arch spans.
		var radius: float=maxf(block.size.x,block.size.z)*0.71
		var p:=block.global_position
		result.append([p.x-radius,p.z-radius,p.x+radius,p.z+radius])
	for station: StationSite in stations:
		var p:=station.global_position
		result.append([p.x-1.5,p.z-1.5,p.x+1.5,p.z+1.5])
	for key in ["broken_blocks","cracked_blocks"]:
		for cell: Array in snapshot.get(key,[]): result.append([cell[0],cell[2],cell[0]+1,cell[2]+1])
	var positions: Array=[snapshot.player.position]
	if snapshot.has("trial_boundary"): positions.append(snapshot.trial_boundary.return_position)
	for kind in ["pickups","bundles"]:
		for drop: Dictionary in snapshot.world_drops[kind]: positions.append(drop.position)
	var machines: Variant=JSON.parse_string(snapshot.get("contraptions",""))
	if machines is Dictionary:
		var by_key: Dictionary={}
		for m: Dictionary in machines.get("machines",[]): by_key[m.key]=m
		for m: Dictionary in by_key.values():
			positions.append(m.position)
			if not String(m.get("forge_key","")).is_empty(): positions.append(m.forge_position)
			for key in ["link","second_link","heat_key"]:
				var target: Dictionary=by_key.get(m.get(key,""),{})
				if target.is_empty(): continue
				var a: Array=m.position;var b: Array=target.position
				result.append([minf(a[0],b[0])-1,minf(a[2],b[2])-1,maxf(a[0],b[0])+1,maxf(a[2],b[2])+1])
	for p: Array in positions: result.append([p[0]-1,p[2]-1,p[0]+1,p[2]+1])
	return result

static func publish(player: WroughtwildPlayer, path: String) -> Dictionary:
	var sim:=player.inventory.get_sim()
	if phase(sim)!="pending": return {"ok":false,"reason":"No pending resonance."}
	if player.trial!=null and player.trial.active(): return {"ok":false,"reason":"Return safely from the Trial before resonance."}
	var rules: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(load("res://scripts/sim.gd").get_tuning_directory().path_join("resonance.json")))
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy and enemy.state not in ["idle","patrol","flee","dead"] and enemy.global_position.distance_to(player.global_position)<float(rules.safe_return_radius_m):
			return {"ok":false,"reason":"Resonance is pending. Finish the nearby fight, then retry at the Annex."}
	var manager:=SaveManager.new()
	var pending:=manager.capture(player)
	if not manager.write_data(path,pending): return {"ok":false,"reason":manager.last_error}
	var candidate:=WroughtwildSim.new()
	if not candidate.load_tuning(load("res://scripts/sim.gd").get_tuning_directory()) or not candidate.import_json(pending.sim):
		return {"ok":false,"reason":"Resonance preparation could not restore its rules."}
	if not candidate.set_world_profile(pending.world_profile) or not candidate.resonance_prepare(int(pending.world_seed),protection(player,pending)):
		return {"ok":false,"reason":candidate.last_error()}
	var committed:=pending.duplicate(true)
	committed.sim=candidate.export_json()
	var transformed:=candidate.world_map(int(pending.world_seed))
	for def: Dictionary in transformed.nodes:
		if String(def.get("resource_id","")).begins_with("lf4_fen_ore_"):
			committed.resource_nodes.append(ResourceStream.definition_record(def,float(transformed.cell_size)))
	var prepared:=manager._prepare_restore(player,committed)
	if prepared.is_empty(): return {"ok":false,"reason":manager.last_error}
	if not manager.write_data(path,committed): return {"ok":false,"reason":manager.last_error}
	if not manager._apply_prepared(player,committed,prepared):
		return {"ok":false,"reason":"Resonance is saved; reload to finish publication. "+manager.last_error}
	return {"ok":true,"reason":"Retained Fen has risen. Its bank exposes copper and tin."}
