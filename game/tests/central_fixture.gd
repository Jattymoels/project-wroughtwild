extends RefCounted
## Build only campaign prerequisites from the frozen published LF5B receipt.
## Empty character data stays empty: no lucky Catalyst or gear is supplied.
static func ready_rules(sim: WroughtwildSim, empty_character: String) -> String:
	var packed:=FileAccess.get_file_as_bytes("res://tests/fixtures/lf5b-published-clear.json.gz")
	var old: Dictionary=JSON.parse_string(packed.decompress_dynamic(16000000,FileAccess.COMPRESSION_GZIP).get_string_from_utf8())
	if not sim.import_json(old.sim) or not sim.set_world_profile("living_frontier_wave3") or not sim.resonance_prepare(77,[]): return ""
	var campaign: Dictionary=JSON.parse_string(sim.export_json()).economy
	var fresh: Dictionary=JSON.parse_string(empty_character)
	for key in ["campaign_policy","resonance","resonance_second"]: fresh.economy[key]=campaign[key]
	fresh.economy.world_effects=["lf4_annex_victory","stonecut_blocks","lf5_pairing_victory","ash_tide"]
	return JSON.stringify(fresh)
