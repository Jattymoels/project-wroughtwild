extends "res://tests/rf05/water.gd"
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF08_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("scout-world.json"))
 player.class_panel.choose("warden")
 scout.call_deferred()
func scout() -> void:
 while not seed_controls.finished:await get_tree().process_frame
 quiet()
 var candidates: Array=[]
 for impact: Dictionary in terrain.map.impacts:
  print("RF08_IMPACT ",impact.id," centre ",Vector3(impact.x,impact.y,impact.z)," radius ",impact.radius_m)
  if impact.get("kind","")=="blacksmith_strike":continue
  var centre:=Vector3(impact.x+.5,impact.y,impact.z+.5)
  for line: Dictionary in terrain.map.leylines:
   var points: PackedVector3Array=line.points
   for i in range(points.size()-1):
    if line.exposure[i]!=2:continue
    var mid: Vector3=(points[i]+points[i+1])*.5
    var dist:=Vector2(mid.x-centre.x,mid.z-centre.z).length()
    if dist>float(impact.radius_m)*1.6:continue
    var idx:=floori(mid.z)*int(terrain.map.width)+floori(mid.x)
    var biome: String=terrain.map.biome_defs[terrain.map.biomes[idx]].id
    if biome not in ["meadow","forest"]:continue
    candidates.append({"impact":impact.id,"centre":[centre.x,centre.y,centre.z],"radius":impact.radius_m,"line":line.id,"segment":i,"at":[mid.x,terrain.height_at(floori(mid.x),floori(mid.z)),mid.z],"a":[points[i].x,points[i].y,points[i].z],"b":[points[i+1].x,points[i+1].y,points[i+1].z],"distance":dist,"biome":biome})
 candidates.sort_custom(func(a,b):return absf(a.distance-a.radius*.55)<absf(b.distance-b.radius*.55))
 var result:={"candidates":candidates}
 FileAccess.open(output.path_join("scout.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
 print("RF08_SCOUT ",JSON.stringify(result))
 print("RF08_FRAGMENT ",AuthoredAssets.mesh_for("cataclysm_impact_fragment").get_aabb()," scale ",CataclysmSites.LOOK.impact_scale)
 get_tree().quit()
