extends "res://tests/rf07/placement.gd"
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF09_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"904",output.path_join("fixtures/rf07/checked-world.json"))
 restore_highland.call_deferred()
func restore_highland() -> void:
 var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("fixtures/rf07/checked-world.json")))
 var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("fixtures/rf07/expected.json")))
 if not check(seed_controls.continue_saved(),"fresh-process ordinary Continue"):return finish_rf("continue")
 quiet()
 read_bench()
 set_origins()
 await tick()
 quiet()
 var restored: Dictionary=JSON.parse_string(JSON.stringify(SaveManager.new().capture(player),"",true,true))
 check(world_seed==77 and world_profile=="frontier_v8","saved seed/profile override new seed")
 check(_sim().export_json()==saved.sim,"exact native possessions/progression")
 for key in ["blocks","stations","contraptions","leylines","resource_nodes","world_drops","broken_blocks","cracked_blocks"]:
  check(restored.get(key,[])==saved.get(key,[]),"exact restored "+key)
 check(hash(terrain.map.heights)==int(expected.height_digest) and hash(terrain.map.lakes)==int(expected.water_digest),"exact native terrain and lake")
 check(hash(snapshot())==int(expected.cover_digest) and hidden_count()==int(expected.hidden),"Continue repeats recovery and paid clearing exactly")
 ready_at(bench+Vector3(0,1.1,0))
 terrain.set_process(true)
 for i in 20:await tick()
 check(player.is_on_floor(),"restored bench is physically supported")
 var before:=player.position
 player.test_walk=Vector2(1,0)
 for i in 18:await tick()
 player.test_walk=Vector2.ZERO
 check(player.position.distance_to(before)>.3,"ordinary movement after Continue")
 check(SaveManager.new().write(output.path_join("resaved-world.json"),player),"ordinary private resave")
 finish_rf("continue")
func read_bench() -> void:
 var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("fixtures/rf07/expected.json")))
 bench=Vector3(expected.bench[0],expected.bench[1],expected.bench[2])
