extends Sandpit
func _ready() -> void:
 set_physics_process(false)
 var output:=OS.get_environment("WROUGHTWILD_RF03_OUTPUT")
 var path:=output.path_join("old-v6.json")
 if not FileAccess.file_exists(path):
  world_profile="frontier_v6"
  _build_world(77)
  player.offer_class()
  player.class_panel.choose("warden")
  assert(SaveManager.new().write(path,player))
  print("RF03_V6 private seed-77 fixture written")
 else:
  assert(world_profile=="frontier_v7")
  seed_controls=SEED_CONTROLS.new()
  add_child(seed_controls)
  seed_controls.configure(self,"904",path)
  assert(seed_controls.continue_saved())
  assert(world_profile=="frontier_v6" and world_seed==77 and terrain.world_profile()=="frontier_v6")
  var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
  assert(_sim().export_json()==saved.sim)
  print("RF03_V6_CONTINUE saved frontier_v6/77 and native ownership retained under default V7")
 get_tree().quit()
