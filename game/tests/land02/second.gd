extends "res://tests/rf05/water.gd"
var place_data: Dictionary
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_LAND02_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new();add_child(seed_controls)
 seed_controls.configure(self,"78",output.path_join("private-world.json"))
 player.class_panel.choose("warden")
 early.call_deferred()
func face_at(at: Vector3) -> void:
 var delta:=at-player.camera.global_position
 player.rotation.y=atan2(-delta.x,-delta.z)
 player.spring_arm.rotation.x=atan2(delta.y,Vector2(delta.x,delta.z).length())
func early() -> void:
 while not seed_controls.finished:await get_tree().process_frame
 if terrain.map.is_empty():get_tree().quit(1);return
 place_data=terrain.map.scarwater[0]
 setup_lake()
 var gallery_nodes:=0
 var loaded_gallery:=0
 for n: Dictionary in terrain.map.nodes:
  if terrain.map.biome_defs[terrain.map.biomes[int(n.z)*int(terrain.map.width)+int(n.x)]].id=="gallery_woodland":gallery_nodes+=1
 for n in terrain.nodes_root.get_children():
  if n is ResourceNode and n._biome_id()=="gallery_woodland":loaded_gallery+=1
 print("LAND02_GALLERY native=",gallery_nodes," initial loaded=",loaded_gallery)
 check(world_profile=="frontier_v9","normal New World chooses V9")
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"desktop comfort opt-out active")
 var at: Vector3=place_data.reveal
 ready_at(at+Vector3(0,1.1,0))
 terrain.set_process(true);set_physics_process(true)
 face_at(place_data.centre+place_data.direction*(float(place_data.ridge_offset_m)+5)+Vector3(0,float(place_data.relief_m)*.15,0))
 for i in 100:await tick()
 check(player.is_on_floor(),"early reveal at grounded player height")
 await still("second-reveal.png")
 print("LAND02_REVEAL feet=",player.position," target=",at)
 var scar_at: Vector3=place_data.scar
 var side: Vector3=place_data.direction
 var view_at:=scar_at-side*4
 view_at.y=terrain.height_at(floori(view_at.x),floori(view_at.z))+1.1
 ready_at(view_at)
 for i in 45:await tick()
 face_at(scar_at+Vector3(0,.4,0))
 await still("second-scar.png")
 print("LAND02_SCAR feet=",player.position," view=",view_at," floor=",scar_at)
 var rows: Dictionary={"place":place_data,"home_sites":terrain.map.home_sites,"lake":lake,"checks":checks,"failures":failures,"tree_assets_ready":preload("res://land02/kit.gd").ready}
 rows.lake=lake.duplicate();rows.lake.erase("beds")
 FileAccess.open(output.path_join("second.json"),FileAccess.WRITE).store_string(JSON.stringify(rows,"\t"))
 print("LAND02_EARLY ",checks," checks, ",failures," failures")
 get_tree().quit(0 if failures==0 else 1)
