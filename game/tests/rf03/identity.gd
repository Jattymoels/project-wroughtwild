extends Node
func _ready() -> void:
 var sim = load("res://scripts/sim.gd").shared()
 var output := OS.get_environment("WROUGHTWILD_RF03_OUTPUT")
 var records := {}
 for profile in ["frontier_v6","living_frontier_wave3"]:
  assert(sim.set_world_profile(profile))
  var map: Dictionary=sim.world_map(77)
  assert(not map.is_empty())
  var digest := HashingContext.new()
  digest.start(HashingContext.HASH_SHA256)
  digest.update(var_to_bytes(map))
  records[profile]=digest.finish().hex_encode()
  print("RF03_IDENTITY ",profile," ",records[profile])
 var path := output.path_join("old-identity.json")
 if FileAccess.file_exists(path):
  assert(JSON.parse_string(FileAccess.get_file_as_string(path))==records,"old V6/LF3 map records changed")
 else: FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(records,"\t"))
 get_tree().quit()
