extends "res://g1/paid.gd"
## Fresh-process read-only presentation/ownership fingerprint on the final hooks.
func execute():
	var manager:=SaveManager.new()
	check(manager.read("res://g1/paid-home.json",player),"retained paid home restores")
	freeze_fixtures();refresh_stations();terrain.set_process(false)
	var before:=manager.capture(player)
	var geography:=JSON.stringify(terrain.map).sha256_text()
	for frame in 15:await get_tree().process_frame
	var after:=manager.capture(player)
	for key in ["sim","leylines","contraptions","blocks","stations","resource_nodes"]:
		check(before[key]==after[key],"presentation frames retain exact "+key)
	check(geography==JSON.stringify(terrain.map).sha256_text(),"presentation retains geography")
	check(player.placement.enclosure_at(player.position).enclosed,"retained paid room remains sheltered")
	var path:="res://../evidence/probe-"+("art" if G1Art.enabled() else "baseline")+".json"
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"geography_sha256":geography,"snapshot":after},"  "))
	print("G1_PROBE ",checks," checks, ",failures," failures / map ",geography)
	get_tree().quit(1 if failures else 0)
