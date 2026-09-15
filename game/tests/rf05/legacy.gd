extends "res://tests/rf05/water.gd"
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF05_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"904",output.path_join("legacy-v7.json"))
 legacy_run.call_deferred()
func legacy_run() -> void:
 var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("legacy-v7.json")))
 if not check(seed_controls.continue_saved(),"retained RF04 V7 save loads through ordinary Continue"):return finish_water("legacy")
 quiet()
 check(world_profile=="frontier_v7" and world_seed==77 and terrain.map.lakes.is_empty(),"old identity has no lake retrofit")
 check(_sim().export_json()==saved.sim,"old native possessions/progression unchanged")
 var restored: Dictionary=JSON.parse_string(JSON.stringify(SaveManager.new().capture(player),"",true,true))
 for key in ["blocks","stations","contraptions","leylines","resource_nodes","world_drops","broken_blocks"]:
  check(restored.get(key,[])==saved.get(key,[]),"old saved ownership "+key)
 player.set_physics_process(true)
 for i in 20:await tick()
 check(not player.swimming and player.is_on_floor(),"retained paid home supplies dry collision")
 finish_water("legacy")
