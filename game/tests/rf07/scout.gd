extends "res://tests/rf05/water.gd"
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF07_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("scout-world.json"))
 player.class_panel.choose("warden")
 scout.call_deferred()
func scout() -> void:
 while not seed_controls.finished:await get_tree().process_frame
 quiet()
 var region: Dictionary={}
 for item: Dictionary in terrain.map.regions:
  if item.id=="glasswind_uplands":region=item
 print("RF07_REGION ",region)
 var candidates: Array=[]
 for z in range(int(region.z)-50,int(region.z)+50,2):
  for x in range(int(region.x)-50,int(region.x)+50,2):
   var idx:=z*int(terrain.map.width)+x
   if terrain.map.biome_defs[terrain.map.biomes[idx]].id!="rocky_hills":continue
   var y:=terrain.height_at(x,z)
   var at:=Vector3(x+.5,y,z+.5)
   if not terrain.reclaimed_cover.clear(at,4.0):continue
   var flat:=true
   for dz in range(-3,4):
    for dx in range(-3,4):
     if absf(terrain.height_at(x+dx,z+dz)-y)>.5:flat=false
   if not flat:continue
   var near:=INF
   for part in get_node("StrangeSites/glasswind_uplands").get_children():
    if not part is MultiMeshInstance3D or part.get_meta("mesh_kind","") not in ["low_outcrop","stone_rib"]:continue
    for pose: Transform3D in part.get_meta("world_transforms",[]):near=minf(near,at.distance_to(pose.origin))
   candidates.append({"at":[at.x,at.y,at.z],"rock_distance":near,"height":y})
 candidates.sort_custom(func(a,b):return absf(a.rock_distance-8)<absf(b.rock_distance-8))
 if candidates.size()>12:candidates.resize(12)
 var report:={"candidates":candidates,"region_x":region.x,"region_z":region.z,"region_radius":region.radius_m}
 FileAccess.open(output.path_join("scout.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("RF07_SCOUT ",JSON.stringify(report))
 for role in ["stone_rib","low_outcrop","scree"]:print(role," ",StrangeSites._mesh_for(role).get_aabb())
 get_tree().quit()
