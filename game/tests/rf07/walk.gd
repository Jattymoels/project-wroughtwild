extends "res://tests/rf07/placement.gd"
var recording:=false
var record_ticks:=0
func tick() -> void:
 await super.tick()
 if recording:
  record_ticks+=1
  if record_ticks%4==0 and captured<120:
   await RenderingServer.frame_post_draw
   get_viewport().get_texture().get_image().save_jpg(output.path_join("media/walk-%03d.jpg"%captured),.92)
   captured+=1
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF07_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("checked-world.json"))
 walk_highland.call_deferred()
func face(target: Vector3) -> void:
 var offset:=target-player.camera.global_position
 player.rotation.y=atan2(-offset.x,-offset.z)
 player.spring_arm.rotation.x=atan2(offset.y,Vector2(offset.x,offset.z).length())
func walk_highland() -> void:
 if not check(seed_controls.continue_saved(),"ordinary Continue opens paid highland outlook"):return finish_rf("walk")
 read_bench()
 var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("expected.json")))
 var floor_at:=Vector3(expected.target[0],expected.target[1],expected.target[2])
 var station_at:=Vector3(expected.station[0],expected.station[1],expected.station[2])
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"capture keeps mouse/focus free")
 check(RenderingServer.get_current_rendering_method()=="forward_plus","Forward+ renderer")
 set_physics_process(true)
 # One disclosed initial staging; every subsequent position comes from walking.
 var start:=bench+Vector3(6,0,0)
 start.y=terrain.height_at(floori(start.x),floori(start.z))+1.1
 ready_at(start)
 for i in 70:await tick()
 face(bench+Vector3(-8,1,0))
 await still("01-recovered-rock.png")
 recording=true
 check(await travel(floor_at+Vector3(2.5,0,1.5),240),"ordinary approach through recovered rock/growth")
 check(await travel(floor_at,200),"ordinary walk onto paid octagonal floor")
 face(bench+Vector3(28,0,-4))
 for i in 35:await tick()
 await still("02-outlook-floor.png")
 check(player.is_on_floor(),"outlook floor physically supports player")
 check(await travel(floor_at+Vector3(2.5,0,1),180),"ordinary floor exit")
 check(await travel(station_at+Vector3(2,0,0),220),"ordinary approach to paid workbench")
 var station: StationSite
 for node in get_tree().get_nodes_in_group("crafting_stations"):
  if node.player_built:station=node
 var body: CollisionShape3D=station.get_node("CollisionShape3D")
 face(body.global_position)
 for i in 20:await tick()
 await still("03-sheltered-workbench.png")
 player.interact()
 check(player.work_panel.is_open(),"aimed ordinary interaction opens workbench")
 player.work_panel.close_panel()
 recording=false
 check(player.is_physics_processing() and is_physics_processing() and terrain.is_processing() and mob_packs.is_physics_processing(),"ordinary world systems stay active")
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"comfort flags retained")
 finish_rf("walk")
