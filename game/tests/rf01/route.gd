extends Node
## One seed's native records select a representative route; no renderer search.
func _ready() -> void:
 var sim = load("res://scripts/sim.gd").shared()
 assert(sim.set_world_profile("frontier_v6"))
 var map: Dictionary = sim.world_map(77)
 var report: Dictionary = {}
 for key in ["seed","width","height","cell_size","spawn_x","spawn_z","home_sites","impacts","ruins","regions","landmarks","habitats"]:
  report[key] = map.get(key)
 var ground: Array = []
 var sx: int = map.spawn_x
 var sz: int = map.spawn_z
 # A small map overview, not extra generated worlds or camera candidates.
 for z in range(sz-180, sz+181, 8):
  var row: Array = []
  for x in range(sx-180, sx+181, 8):
   if x<0 or z<0 or x>=int(map.width) or z>=int(map.height):
    row.append([])
   else:
    var i: int = z*int(map.width)+x
    row.append([x,z,int(map.heights[i]),map.biome_defs[map.biomes[i]].id])
  ground.append(row)
 report["local_ground"] = ground
 var path := OS.get_environment("WROUGHTWILD_RF01_OUTPUT").path_join("route-native.json")
 FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("RF01 native route records: ",path)
 get_tree().quit()