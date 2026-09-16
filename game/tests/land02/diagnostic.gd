extends "res://tests/land02/early.gd"
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_LAND02_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new();add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("private-world.json"))
 run.call_deferred()
func run() -> void:
 if not seed_controls.continue_saved():print("RESTORE FAILED");get_tree().quit(1);return
 quiet()
 for n in get_tree().get_nodes_in_group("contraptions"):n.set_physics_process(false)
 for pair in [[Vector3(602,35,669),Vector3(603.5,34,670.5)],[Vector3(532.5,33,610),Vector3(532.5,31,613.5)]]:
  ready_at(pair[0]);terrain.set_process(true)
  for i in 10:await tick()
  var ok:=await travel(pair[1],150)
  print("DIAGNOSTIC_WALK ",pair," ok=",ok," at=",player.position)
  for i in player.get_slide_collision_count():
   var c:=player.get_slide_collision(i)
   print("CONTACT ",c.get_collider().get_path()," at=",c.get_position()," normal=",c.get_normal())
  for n in terrain.nodes_root.get_children():
   if n is ResourceNode and ((n.position-player.position)*Vector3(1,0,1)).length()<4:print("NODE ",n.name," ",n.position)
 var feeder: ContraptionSite
 var forge: StationSite
 for n in get_tree().get_nodes_in_group("contraptions"):
  if n is ContraptionSite and n.kind=="pressure_feeder":feeder=n
 for n in get_tree().get_nodes_in_group("crafting_stations"):
  if n is StationSite and n.player_built and n.station_id==&"forge_basic":forge=n
 var source:=PressurePocket.find_source(get_tree(),terrain.map.pressure_pockets[0].id)
 terrain.ensure_area(source.position,24);await tick()
 print("FEEDER ",feeder.position," forge=",forge.position," source=",source.position)
 print("CONNECTION ",feeder.feeder_connection_status(forge,source))
 print("SUPPORT ",feeder._feeder_support(feeder,ContraptionSite.LOOK.feeder_support_half_width_m)," / ",feeder._feeder_support(forge,ContraptionSite.LOOK.station_support_half_width_m))
 get_tree().quit()
